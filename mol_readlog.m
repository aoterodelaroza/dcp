% Adapted from escher.

% Copyright (C) 2011 Victor Lua~na and Alberto Otero-de-la-Roza
%
% This octave routine is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or (at
% your option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

function [mol] = mol_readlog(filename)
% function [mol] = mol_readlog(filename)
%
% mol_readlog - read a molecule from a gaussian output.
%
% Required input variables:
% filename: name of the data file.
%

  [fid,msg] = fopen(filename,"r");
  if (fid < 0 || ferror(fid)) 
    disp(msg)
    error("mol_readlog: Could not find -- %s",filename);
  endif

  ## get the last geometry
  while (!feof(fid))
    line = fgetl(fid);
    if (strfind(line,"orientation:"))
      ipos = ftell(fid);
    endif
  endwhile

  if (!exist("ipos","var")) 
    error("Valid geometry not found!")
  endif

  ## read the orientation block
  mol = struct();
  fseek(fid,ipos);
  for i = 1:4
    line = fgetl(fid);
  endfor
  while (1)
    line = fgetl(fid);
    if (strfind(line,"-----"))
      break
    endif
    [n atnum zero x y z] = sscanf(line,"%d %d %d %f %f %f","C");
    mol.atnumber(n) = atnum;
    mol.atxyz(:,n) = [x y z]';
  endwhile
  mol.nat = n;

endfunction
