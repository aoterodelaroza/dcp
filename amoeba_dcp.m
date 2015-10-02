## Copyright (C) 2002-2008 Etienne Grossmann <etienne@egdn.net>
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

## [x0,v] = nelder_mead_min (f,args,ctl) - Nelder-Mead minimization
##
## Minimize 'f' using the Nelder-Mead algorithm. This function is inspired
## from the that found in the book "Numerical Recipes".
##
## ARGUMENTS
## ---------
## f     : string : Name of function. Must return a real value
## args  : list   : Arguments passed to f.
##      or matrix : f's only argument
## ctl   : vector : (Optional) Control variables, described below
##      or struct
##
## RETURNED VALUES
## ---------------
## x0  : matrix   : Local minimum of f
## v   : real     : Value of f in x0
## 
## CONTROL VARIABLE : (optional) may be named arguments (i.e. "name",value
## ------------------ pairs), a struct, or a vector of length <= 6, where
##                    NaN's are ignored. Default values are written <value>.
##  OPT.   VECTOR
##  NAME    POS
## ftol,f  N/A    : Stopping criterion : stop search when values at simplex
##                  vertices are all alike, as tested by 
##
##                   f > (max_i (f_i) - min_i (f_i)) /max(max(|f_i|),1)
##
##                  where f_i are the values of f at the vertices.  <10*eps>
##
## rtol,r  N/A    : Stop search when biggest radius of simplex, using
##                  infinity-norm, is small, as tested by :
##
##              ctl(2) > Radius                                     <10*eps>
##
## vtol,v  N/A    : Stop search when volume of simplex is small, tested by
##            
##              ctl(2) > Vol
##
## crit,c ctl(1)  : Set one stopping criterion, 'ftol' (c=1), 'rtol' (c=2)
##                  or 'vtol' (c=3) to the value of the 'tol' option.    <1>
##
## tol, t ctl(2)  : Threshold in termination test chosen by 'crit'  <10*eps>
##
## narg  ctl(3)  : Position of the minimized argument in args            <1>
## maxev ctl(4)  : Maximum number of function evaluations. This number <inf>
##                 may be slightly exceeded.
## isz   ctl(5)  : Size of initial simplex, which is :                   <1>
##
##                { x + e_i | i in 0..N } 
## 
##                Where x == args{narg} is the initial value 
##                 e_0    == zeros (size (x)), 
##                 e_i(j) == 0 if j != i and e_i(i) == ctl(5)
##                 e_i    has same size as x
##
##                Set ctl(5) to the distance you expect between the starting
##                point and the minimum.
##

% This is a somewhat-modified version of octave's amoeba routine

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

function [x,v] = amoeba_dcp(f, args, varargin)

  global astep nstep
				# Default control variables
ftol = rtol = 10*eps;		# Stop either by likeness of values or
vtol = nan;                     # radius, but don't care about volume.
crit = 0;			# Stopping criterion            ctl(1)
tol = 10*eps;			# Stopping test's threshold     ctl(2)
narg = 1;			# Position of minimized arg     ctl(3)
maxev = inf;			# Max num of func evaluations   ctl(4)
isz = 1;			# Initial size                  ctl(5)
asave = "";                   


if nargin >= 3,			# Read control arguments
  va_arg_cnt = 1;
  if nargin > 3, 
          ctl = struct (varargin{:}); 
  else 
          ctl = varargin{va_arg_cnt++}; 
  end
  if isfield (ctl, "crit") && ! isnan (ctl.crit ), crit  = ctl.crit ; end
  if isfield (ctl,  "tol") && ! isnan (ctl.tol  ), tol   = ctl.tol  ; end
  if isfield (ctl, "ftol") && ! isnan (ctl.ftol ), ftol  = ctl.ftol ; end
  if isfield (ctl, "rtol") && ! isnan (ctl.rtol ), rtol  = ctl.rtol ; end
  if isfield (ctl, "vtol") && ! isnan (ctl.vtol ), vtol  = ctl.vtol ; end
  if isfield (ctl, "narg") && ! isnan (ctl.narg ), narg  = ctl.narg ; end
  if isfield (ctl,"maxev") && ! isnan (ctl.maxev), maxev = ctl.maxev; end
  if isfield (ctl,  "isz") && ! isnan (ctl.isz  ), isz   = ctl.isz  ; end
  if isfield (ctl,"asave") && ! isnan (ctl.asave), asave = ctl.asave; end
end


if     crit == 1, ftol = tol; 
elseif crit == 2, rtol = tol; 
elseif crit == 3, vtol = tol;
elseif crit, error ("crit is %i. Should be 1,2 or 3.\n");
end

if iscell (args)
  x = args{1};
else				# Single argument
  x = args;
  args = {args};
endif

printf("#### Amoeba started with tol = %.5f and isz = %f \n",rtol,isz);

## Simplex dimension
[R0,C0] = size (x);
N0 = R0*C0;			
x = x(:);
usesave = 0;
if (length(asave) > 0 && exist(asave,"file"))
  load(asave,"N","R","C");
  if (N == N0 && R == R0 && C == C0)
    usesave = 1;
  endif
endif
N = N0; R = R0; C = C0;

astep = 0;
if (!usesave)
  ## Build the initial simplex
  u = isz * eye (N+1,N) .* (ones(N+1,1)*x') + ones(N+1,1)*x';

  printf("#xx# |Step|  Iter |  Cost function  |   wRMS  |   RMS   |   MAE   | time(s) |\n")
  y = zeros (N+1,1);
  for i = 1:N+1,
    y(i) = feval (f, args{1:narg-1},reshape(u(i,:),R,C),args{narg+1:end});
  end ;

  [ymin,imin] = min(y);
  ymin0 = ymin;
  v = nan;
  str = "initialization";
  nev = 1;
else
  printf("#### Amoeba found restart file %s \n",asave);
  printf("#xx# |Step|  Iter |  Cost function  |   wRMS   |    RMS   |    MAE   | time(s) |\n")
  nev = 0;
endif

while(true)
  if (astep == 0 && usesave)
    load(asave)
  elseif (length(asave) > 0)
    save(asave,"u","y","astep","nstep","v","N","R","C","str");
  endif
  astep++;

  ## ymin, ymax, ymx2 : lowest, highest and 2nd highest function values
  ## imin, imax, imx2 : indices of vertices with these values
  [ymin,imin] = min(y);  [ymax,imax] = max(y) ;
  y(imax) = ymin ;  
  [ymx2,imx2] = max(y) ;  
  y(imax) = ymax ;
  
  ## Compute stopping criterion
  done = 0;
  if ! isnan (ftol), 
     done |= ((max(y)-min(y)) / max(1,max(abs(y))) < ftol); 
  end
  if ! isnan (rtol), 
     done |= (2*max (max (u) - min (u)) < rtol); 
  end
  if ! isnan (vtol)
    done |= (abs (det (u(1:N,:)-ones(N,1)*u(N+1,:)))/factorial(N) < vtol);
  end
  
  printf("#### Amoeba: step %d | rsize %.5f (tol %.5f)| fsize %.5f | vsize %.5f | cost %.5f | step %s | %s \n",...
        astep,2*max (max (u) - min (u)), rtol, (max(y)-min(y)) / max(1,max(abs(y))),...
        abs (det (u(1:N,:)-ones(N,1)*u(N+1,:)))/factorial(N), ymin, str, strtrim(ctime(time())));

  if (done)
    if isnan (v),
      x = reshape (u(imin,:), R, C) ;
      v = ymin ;
    end
    if (nev == 0) 
      v = feval(f, args{1:narg-1},reshape(x,R,C),args{narg+1:length(args)});
    endif
    printf("#### Amoeba converged\n");
    return
  endif
  ##   [ y' u ]

  ## Look for a new point
  ## Consider reflection of worst vertice around centroid.
  xsum = sum(u) ;		
				
  ## f1 = (1-(-1))/N = 2/N;
  ## f2 = f1 - (-1)  = 2/N + 1 = (N+2)/N
  xnew = (2*xsum - (N+2)*u(imax,:)) / N;
  ## xnew = (2*xsum - N*u(imax,:)) / N;
  ynew = feval (f, args{1:narg-1},reshape(xnew,R,C),args{narg+1:length(args)});
  
  if (ynew <= ymin)
    ## Reflection is good    
    y(imax) = ynew; u(imax,:) = xnew ;
    xsum = sum(u) ;
    
    ## f1 = (1-2)/N = -1/N
    ## f2 = f1 - 2  = -1/N - 2 = -(2*N+1)/N
    xnew = ( -xsum + (2*N+1)*u(imax,:) ) / N;
    ynew = feval (f, args{1:narg-1},reshape(xnew,R,C),args{narg+1:length(args)});
      
    if ynew <= ymin ,		
      y(imax) = ynew ; u(imax,:) = xnew ;
      xsum = sum(u) ;
      str = "good reflection (expand)";
    else
      str = "good reflection (plain)";
    end

  elseif (ynew >= ymax)
    ## Bring worst point closer to centroid
    ## f1 = (1-0.5)/N = 0.5/N
    ## f2 = f1 - 0.5  = 0.5*(1 - N)/N
    xnew = 0.5*(xsum + (N-1)*u(imax,:)) / N;
    ynew = feval (f, args{1:narg-1},reshape(xnew,R,C),args{narg+1:length(args)});

    if (ynew >= ymax)
      ## New point is even worse. Contract whole
      ## simplex
      ## u0 = u;
      u = (u + ones(N+1,1)*u(imin,:)) / 2;
      ## keyboard

      ## Code that doesn't care about value of empty_list_elements_ok
      if     imin == 1  , ii = 2:N+1; 
      elseif imin == N+1, ii = 1:N;
      else                ii = [1:imin-1,imin+1:N+1]; end
      for i = ii
	y(i) = ...
	    ynew = feval (f, args{1:narg-1},reshape(u(i,:),R,C),args{narg+1:length(args)});
      end
      str = "contraction";
    else				# Replace highest point
      y(imax) = ynew ; u(imax,:) = xnew ;
      xsum = sum(u) ; 
      str = "intermediate";
    end
  else				
    ## Reflection is neither good nor bad
    y(imax) = ynew ; u(imax,:) = xnew ;
    xsum = sum(u) ; 
    str = "keep reflection (plain)";
  end
  nev++;
end

