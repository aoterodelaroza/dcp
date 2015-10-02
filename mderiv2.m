% Copyright (C) 2015 Alberto Otero-de-la-Roza <alberto@fluor.quimica.uniovi.es>
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

function ypp = mderiv2(f,x0,h,verbose=0)

  if (verbose)
    printf("Step: %f \n",h);
    printf("Derivative at: ");
    printf("%.4e ",x0)
    printf("\n");
  endif

  ypp = zeros(length(x0));
  for icomp = 2:2:length(x0)
    npts = 5;
    ider = 2;
    coefs = [-1/12, 4/3, -5/2, 4/3, -1/12];

    ## evaluate
    f0 = zeros(1,npts);
    for i = -(npts-1)/2:(npts-1)/2
      x = x0;
      x(icomp) += i * h;
      f0(i+(npts+1)/2) = feval(f,x);
    endfor

    ## derivative
    ypp(icomp,icomp) = sum(coefs * f0') / h^2;
    if (verbose)
      printf("Comp %d, yp = %.8f f0 = ",icomp,ypp(icomp,icomp));
      printf("%.8f ",f0);
      printf("\n");
    endif
  endfor

endfunction
