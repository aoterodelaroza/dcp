% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
%
% dcp is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your
% option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

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
