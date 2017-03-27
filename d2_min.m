## Copyright (C) 2002 Etienne Grossmann <etienne@egdn.net>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

% This is a heavily-modified version of d2_min from the octave/optim package.

% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
%
% acp is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your
% option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

function [xbest,vbest] = d2_min (f,d2f,x0,tol)

  global astep fixnorm muk

  ## Initialize and header
  x0 = x0(:); ## to column vector
  astep = 0;
  printf("#### Levenberg-Marquardt started ####\n");
  printf("#xx# |Step|  Iter |  Cost function  | Penalty functn  |   wRMS  |   RMS   |   MAE   |  norm  | time(s) |\n")

  ## Maximum norm for the displacement
  maxnorm_grad = 1d-6;
  maxnorm_newton = 1d-4;

  tcoeff = 0.5; ## Discount on total weight
  ncoeff = 0.5; ## Discount on weight of newton
  ocoeff = 1.5; ## Factor for outwards searching

  if (!ischar (d2f) || !ischar (f))
    printf ("d2_min : f and d2f should be strings!\n");
  end

  ## Initial parameters
  x = x0(:);
  xbest = x;

  ## Initial evaluation
  v = vold = vbest = nan ;		

  ## Outer loop
  while true

    ## Next step, calculate the derivatives
    astep += 1;
    [v,d,h] = feval(d2f,x);
    d = d(:);

    ## fixnorm: derivatives wrt lagrange multiplier
    if (exist("fixnorm","var") && fixnorm > 0)
      n = length(x);

      ## lagrange multiplier and sum of squares
      ssq = sum(x(2:2:end).^2);
      fn2 = fixnorm^2;
      px = ssq/fn2 - 1;

      ## transform the first derivatives 
      for j = 2:2:n
        d(j) = d(j) + 4 * muk * px * x(j) / fn2;
      endfor

      ## transform the second derivatives
      for j = 2:2:n
        for k = j:2:n
          h(j,k) = h(j,k) + 8 * muk * x(j) * x(k) / fn2^2;
          h(k,j) = h(j,k);
        endfor
        h(j,j) = h(j,j) + 4 * muk * px / fn2;
      endfor

      ## Transform the value
      v = v + muk * px^2;
    endif

    ## Invert the Hessian and get the gradient
    h = pinv(h);

    ## Write down the first step as best
    xold = xbest = x ;
    vold = vbest = v ;
    dbest = zeros(size(x));

    dnewton = -h*d; ## Newton step

    ## Normalize to the maximum norm
    dnorm = norm(d);
    dnnorm = norm(dnewton);
    if (dnorm > maxnorm_grad)
      d = d / dnorm * maxnorm_grad;
    endif
    if (dnnorm > maxnorm_newton)
      dnewton = dnewton / dnnorm * maxnorm_newton;
    endif

    ## Weight of Newton step
    wn = 1 ;		

    ## Total weight
    wt = 1 ;			
    
    ## Initialize the inner loop
    done_inner = 0;
    
    while true
      ## Proposed step
      dx = wt*(wn*dnewton - (1-wn)*d);
      xnew = x + dx;
      xnew(1:2:end-1) = x(1:2:end-1);

      if (norm(dx) < 1e-9)
        break
      endif

      ## Evaluate the new point
      vnew = feval(f,xnew);

      ## Transform vnew
      if (exist("fixnorm","var") && fixnorm > 0)
        ssq = sum(xnew(2:2:end).^2);
        fn2 = fixnorm^2;
        px = ssq/fn2 - 1;
        vnew = vnew + muk * px^2;
      endif      

      ## Stash best values
      if (vnew < vbest)		
        dbest = dx ; 
        vbest = vnew; 
        xbest = xnew; 
        ## Will go out at next increase if the cost goes up
        done_inner = 1 ;		
      elseif (done_inner == 1)
        break;		
      end

      ## Reduce the norm by the proposed step
      wt = wt*tcoeff ;		

      ## Bring it closer to derivative
      wn = wn*ncoeff ;		
    end	## end of inner loop

    ## Best coeff for dbest
    wbest = 0; 

    ## Evaluate at the new point
    wn = ocoeff ;
    xnew = x + wn*dbest;
    xnew(1:2:end-1) = x(1:2:end-1);
    vnew = feval(f,xnew);

    ## Transform vnew
    if (exist("fixnorm","var") && fixnorm > 0)
      ssq = sum(xnew(2:2:end).^2);
      fn2 = fixnorm^2;
      px = ssq/fn2 - 1;
      vnew = vnew + muk * px^2;
    endif      

    ## Stash best values
    while (vnew < vbest)
      vbest = vnew;		
      wbest = wn;
      xbest = xnew; 
      wn = wn*ocoeff ;
      xnew = x+wn*dbest;
      ## Evaluate the new point
      vnew = feval(f,xnew);
      if (exist("fixnorm","var") && fixnorm > 0)
        ssq = sum(xnew(2:2:end).^2);
        fn2 = fixnorm^2;
        px = ssq/fn2 - 1;
        vnew = vnew + muk * px^2;
      endif      
    end

    if vbest < vold
      v = vbest; 
      x = xbest;
    end

    ## Print message
    printf("#### d2_min | step %d | cost %.10f | diff %.2e (tol %.2e)| normstep %.2e | maxstep %.2e | %s\n",...
           astep, vbest, abs(vold-vbest), tol, norm(x-xold), max(abs(x-xold)), strtrim(ctime(time())));

    if (abs(vold-vbest) < tol)
      break
    end
  end ## end of outer loop

endfunction
