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

function writexyz(file,at,x,q,mult)
  %% function writexyz(file,x,q,mult)
  %%
  %% Write a coordinate file (xyz) in filename file. Use the geometry
  %% in at (cell array of atomic symbols), x (array of atomic
  %% coordinates), q (charge), and mult (multiplicity).
  
  ## Open the input file for writing
  fid = fopen(file,"w");
  if (fid <= 0) 
    error(sprintf("Could not open xyz file for writing: %s",file));
  endif

  ## Header of the xyz file
  fprintf(fid,"%d\n",length(at));
  fprintf(fid,"%d %d\n",q,mult);

  ## Molecular geometry
  for i = 1:length(at)
    fprintf(fid,"%s %.10f %.10f %.10f\n",at{i},x(i,:));
  endfor

  ## Close the file
  fclose(fid);

endfunction
