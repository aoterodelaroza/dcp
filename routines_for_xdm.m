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

## emacs: stop pestering me, FFS!!
function routines_for_xdm()
endfunction

## Convert an atomic symbol to the atomic number
function z = atom2z(symbol)
  ## atomic symbols
  atdb.symbols = ...
  {"H" , "HE", "LI", "BE", "B" , "C" , "N" , "O" , "F" , "NE", ...
   "NA", "MG", "AL", "SI", "P" , "S" , "CL", "AR", "K" , "CA", ...
   "SC", "TI", "V" , "CR", "MN", "FE", "CO", "NI", "CU", "ZN", ...
   "GA", "GE", "AS", "SE", "BR", "KR", "RB", "SR", "Y" , "ZR", ...
   "NB", "MO", "TC", "RU", "RH", "PD", "AG", "CD", "IN", "SN", ...
   "SB", "TE", "I" , "XE", "CS", "BA", "LA", "CE", "PR", "ND", ...
   "PM", "SM", "EU", "GD", "TB", "DY", "HO", "ER", "TM", "YB", ...
   "LU", "HF", "TA", "W" , "RE", "OS", "IR", "PT", "AU", "HG", ...
   "TL", "PB", "BI", "PO", "AT", "RN", "FR", "RA", "AC", "TH", ...
   "PA", "U" , "NP", "PU", "AM", "CM", "BK", "CF", "ES", "FM", ...
   "MD", "NO", "LR", "X", ...
   "N@", "B@", "R@", "C@" ...
  };

  [err,iz] = ismember(upper(symbol),atdb.symbols);
  if (err == 0)
    ssymbol = substr(upper(symbol),1,2);
    [err,iz] = ismember(ssymbol,atdb.symbols);
  endif
  if (err == 0)
    ssymbol = substr(ssymbol,1,1);
    [err,iz] = ismember(ssymbol,atdb.symbols);
  endif
  if (err == 0)
    error(strcat("mol_dbatom: atomic symbol ->", symbol, "<- not found!"));
  endif
  z = iz;
endfunction

## Give the name of the pgout file
function file = namefile(tag)
  file = sprintf("%s.pgout",tag);
endfunction

## Read the geometry from a pgout file
function [x,z,n] = readxyz(file)
  fid = fopen(file,"r");
  for i = 1:6
    str = fgetl(fid);
  endfor
  [str n] = fscanf(fid,"%s %d","C");
  str = fgetl(fid); str = fgetl(fid);

  x = zeros(3,n); z = zeros(1,n);
  for i = 1:n
    [idum1,ss,x1,x2,x3,idum2,idum3] = fscanf(fid,"%d %s %f %f %f %d %d","C");
    x(:,i) = [x1 x2 x3];
    z(i) = atom2z(ss);
  endfor
  fclose(fid);
endfunction

## Read the dispersion coefficients from the pgout
function [c6,c8,c10,rc] = readcij(file,n)

  c6 = zeros(n); c8 = zeros(n); c10 = zeros(n); rc = zeros(n);

  fid = fopen(file,"r");
  line = fgetl(fid);
  do 
    if(regexp(line,"coefficients and distances"));
      line = fgetl(fid);
      do
	[ii,jj,ddum,c6dum,c8dum,c10dum,rcdum,rvdw] = sscanf(line,"%d %d %f %f %f %f %f %f","C");
	c6(jj,ii) = c6(ii,jj) = c6dum; 
	c8(jj,ii) = c8(ii,jj) = c8dum; 
	c10(jj,ii) = c10(ii,jj) = c10dum; 
	rc(jj,ii) = rc(ii,jj) = rcdum;
	line = fgetl(fid);
      until (strcmp(deblank(line),"#"));
    endif
    line = fgetl(fid);
  until (!ischar(line) && (line == -1))
  fclose(fid);
endfunction

## Read the energy from a pgout file
function [e edisp etotal] = readenergy(file)
  [stat,out] = system(sprintf("grep 'scf energy' %s | tail -n 1 | awk '{print $NF}' \n",file));
  if (length(out) == 0)
    e = 0;
  else
    e = str2num(out);
  endif
  [stat,out] = system(sprintf("grep 'dispersion energy' %s | tail -n 1 | awk '{print $NF}'\n",file));
  if (length(out) == 0)
    edisp = 0;
  else
    edisp = str2num(out);
  endif
  etotal = e + edisp;
endfunction


## Calculate the vdw energy of a single molecule
function e = energy(n,z,x,c6,c8,c10,rc,coef)
  e = 0;
  for i = 1:n
    for j = i+1:n
      d = norm(x(:,i)-x(:,j));
      a1 = coef(1);
      a2 = coef(2) / .52917720859;
      rvdw = a1 * rc(i,j) + a2;
      
      e -= c6(i,j) / (rvdw^6 + d^6) + c8(i,j) / (rvdw^8 + d^8) + c10(i,j) / (rvdw^10 + d^10);
    endfor
  endfor
endfunction

## Collect all the data from the pgout files
function collect_for_fit()
  ## globals
  global hy2kcal e n xc z c6 c8 c10 rc dimers mol1 mol2 be_ref 

  ## collect the data
  c6 = struct(); c8 = struct(); c10 = struct(); rc = struct();
  xc = struct(); z = struct(); n = struct();
  e = struct();
  for i = 1:length(dimers);
    filed = namefile(dimers{i});
    file1 = namefile(mol1{i});
    file2 = namefile(mol2{i});
    if (exist(filed,"file") && exist(file1,"file") && exist(file2,"file"))

      ## Energies
      e = setfield(e,dimers{i},readenergy(namefile(dimers{i})));
      e = setfield(e,mol1{i},readenergy(namefile(mol1{i})));
      e = setfield(e,mol2{i},readenergy(namefile(mol2{i})));

      ## Geometries
      s = dimers{i};
      [xx,zz,nn] = readxyz(filed);
      xc = setfield(xc,s,xx);
      z = setfield(z,s,zz);
      n = setfield(n,s,nn);
      [cc6,cc8,cc10,rrc] = readcij(namefile(s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);

      s = mol1{i};
      [xx,zz,nn] = readxyz(file1);
      xc = setfield(xc,s,xx);
      z = setfield(z,s,zz);
      n = setfield(n,s,nn);
      [cc6,cc8,cc10,rrc] = readcij(namefile(s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);

      s = mol2{i};
      [xx,zz,nn] = readxyz(file2);
      xc = setfield(xc,s,xx);
      z = setfield(z,s,zz);
      n = setfield(n,s,nn);
      [cc6,cc8,cc10,rrc] = readcij(namefile(s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);
    endif
  endfor

endfunction

## Define the least-squares function for leasqr
function y = fxdm(x,p)

  global hy2kcal e n xc z c6 c8 c10 rc dimers mol1 mol2 

  y = zeros(size(x));
  for ii = 1:length(x)
    i = round(x(ii));
    nn = getfield(n,dimers{i});
    xx = getfield(xc,dimers{i});
    zz = getfield(z,dimers{i});
    cc6 = getfield(c6,dimers{i});
    cc8 = getfield(c8,dimers{i});
    cc10 = getfield(c10,dimers{i});
    rrc = getfield(rc,dimers{i});
    evdwd = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    nn = getfield(n,mol1{i});
    xx = getfield(xc,mol1{i});
    zz = getfield(z,mol1{i});
    cc6 = getfield(c6,mol1{i});
    cc8 = getfield(c8,mol1{i});
    cc10 = getfield(c10,mol1{i});
    rrc = getfield(rc,mol1{i});
    evdw1 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    nn = getfield(n,mol2{i});
    xx = getfield(xc,mol2{i});
    zz = getfield(z,mol2{i});
    cc6 = getfield(c6,mol2{i});
    cc8 = getfield(c8,mol2{i});
    cc10 = getfield(c10,mol2{i});
    rrc = getfield(rc,mol2{i});
    evdw2 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);

    y(i) = (getfield(e,mol1{i}) + evdw1 + getfield(e,mol2{i}) + evdw2 - getfield(e,dimers{i}) - evdwd) * hy2kcal;
  endfor
endfunction

