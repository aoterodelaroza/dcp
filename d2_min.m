## Copyright (C) 2002 Etienne Grossmann <etienne@egdn.net>
## (see octave for licence notice)

function [xbest,vbest] = d2_min (f,d2f,x0,tol)

  global astep fixnorm

  ## Initialize and header
  astep = 0;
  printf("#### Levenberg-Marquardt started ####\n");
  printf("#xx# |Step|  Iter |  Cost function  |   wRMS  |   RMS   |   MAE   |  norm  | time(s) |\n")

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
  if (exist("fixnorm","var") && fixnorm > 0)
    x = x0(1:end-1);
  else
    x = x0;
  endif
  sz = size(x0); 
  xbest = x = x(:);

  ## Initial evaluation
  v = vold = vbest = nan ;		

  ## Outer loop
  while true

    ## Next step, calculate the derivatives
    astep += 1;
    if (exist("fixnorm","var") && fixnorm > 0)
      xex = [x(:); sqrt(fixnorm^2 - sum(x(2:2:end).^2))];
    else
      xex = x;
    endif
    [v,d,h] = feval(d2f,reshape(xex,sz));

    ## fixnorm: apply the chain rule
    if (exist("fixnorm","var") && fixnorm > 0)
      n = length(xex);
      u = xex(n);
      du = d(n);
      d2u = h(n,n);
      
      ## transform the first derivatives
      d = d(1:n-1);
      for j = 2:2:n-1
        d(j) = d(j) - du / u * xex(j);
      endfor

      ## transform the second derivatives, ii
      for j = 2:2:n-1
        h(j,j) = h(j,j) - 2 * xex(j)/u * h(j,n) + (xex(j)/u)^2 * d2u - du * (1/u + xex(j)^2 / u^3);
      endfor
      
      ## transform the second derivatives, ij
      for j = 2:2:n-1
        for k = 2:2:j-1
          h(j,k) = h(j,k) - xex(j)/u * h(j,n) - xex(k)/u * h(k,n) + (xex(j)*xex(k)/u^2) * d2u - du * xex(j)*xex(k) / u^3;
          h(k,j) = h(j,k);
        endfor
      endfor
      h = h(1:n-1,1:n-1);
    endif

    ## Invert the Hessian and get the gradient
    h = pinv(h);
    d = d(:);

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

      if (norm(dx) < 1e-9)
        break
      endif

      ## Evaluate the new point
      if (exist("fixnorm","var") && fixnorm > 0)
        xex = [xnew; sqrt(fixnorm^2 - sum(xnew(2:2:end).^2))];
      else
        xex = xnew;
      endif
      vnew = feval(f,reshape(xex,sz));

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
    if (exist("fixnorm","var") && fixnorm > 0)
      xex = [xnew; sqrt(fixnorm^2 - sum(xnew(2:2:end).^2))];
    else
      xex = xnew;
    endif
    vnew = feval(f,reshape(xex,sz));

    ## Stash best values
    while (vnew < vbest)
      vbest = vnew;		
      wbest = wn;
      xbest = xnew; 
      wn = wn*ocoeff ;
      xnew = x+wn*dbest;
      ## Evaluate the new point
      if (exist("fixnorm","var") && fixnorm > 0)
        xex = [xnew; sqrt(fixnorm^2 - sum(xnew(2:2:end).^2))];
      else
        xex = xnew;
      endif
      vnew = feval(f,reshape(xex,sz));
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

  if (exist("fixnorm","var") && fixnorm > 0)
    xbest = [xbest; sqrt(fixnorm^2 - sum(xbest(2:2:end).^2))];
  endif
  xbest = reshape(xbest,sz);

endfunction
