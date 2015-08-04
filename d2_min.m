## Copyright (C) 2002 Etienne Grossmann <etienne@egdn.net>
## (see octave for licence notice)

function [xbest,vbest] = d2_min (f,d2f,x0,tol)

  global astep

  ## Initialize and header
  astep = 0;
  printf("#### Levenberg-Marquardt started ####\n");
  printf("#xx# |Step|  Iter |  Cost function  |   wRMS  |   RMS   |   MAE   | time(s) |\n")

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
  x = x0;
  sz = size (x); 
  N = prod (sz);
  xbest = x = x(:);

  ## Initial evaluation
  v = vold = vbest = nan ;		

  ## Outer loop
  while true
    ## Next step, calculate the derivatives
    astep += 1;
    [v,d,h] = feval(d2f,reshape(x,sz));

    ## Invert the Hessian and get the gradient
    h = pinv(h);
    d = d(:);

    ## Write down the first step as best
    xold = xbest = x ;
    vold = vbest = v ;

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
        return
      endif

      ## Evaluate the new point
      vnew = feval(f,reshape(xnew,sz));

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
    vnew = feval(f,reshape(xnew,sz));

    ## Stash best values
    while (vnew < vbest)
      vbest = vnew;		
      wbest = wn;
      xbest = xnew; 
      wn = wn*ocoeff ;
      xnew = x+wn*dbest;
      vnew = feval(f,reshape(xnew,sz));
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

  xbest = reshape (xbest, sz);

endfunction
