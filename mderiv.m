#! /usr/bin/octave -q

function yp = mderiv(f,x0,hodd,heven,verbose=0)

  if (verbose)
    printf("Steps: odd - %f even - %f\n",hodd,heven);
    printf("Derivative at: ");
    printf("%.4e ",x0)
    printf("\n");
  endif

  yp = zeros(size(x0));
  for icomp = 2:2:length(x0)
    npts = 5;
    ider = 1;
    coefs = [1/12, -2/3, 0, 2/3, -1/12];

    if (mod(icomp,2) == 0)
      h = heven;
    else
      h = hodd;
    endif

    ## evaluate
    f0 = zeros(1,npts);
    for i = -(npts-1)/2:(npts-1)/2
      x = x0;
      x(icomp) += i * h;
      f0(i+(npts+1)/2) = feval(f,x);
    endfor

    ## derivative
    yp(icomp) = sum(coefs * f0') / h;
    if (verbose)
      printf("Comp %d, yp = %.8f f0 = ",icomp,yp(icomp));
      printf("%.8f ",f0);
      printf("\n");
    endif
  endfor
  if (verbose)
  endif
endfunction
