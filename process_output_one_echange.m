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

function ade = process_output_one_echange(ent)
  %% function ade = process_output_one_echange(ent)
  %%
  %% Read the Gaussian output for the dimer in the database entry
  %% ent. The output file should have been generated by Gaussian after
  %% a call to run_inputs, and should contain at least the dimer
  %% calculation with the DCP and the post-SCF calculation without
  %% the DCP, as normally done when the calculation of the derivatives
  %% is activated. 

  h2k = 627.50947;
  global prefix nstep

  if (strcmp(ent.type,"be_frozen_monomer"))
    ## Read the energy for the dimer and calculate the total energy effect of the DCP
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      ade = Inf;
      return
    endif
    [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
    e2 = str2num(out);
    if (s != 0 || isempty(e2) || length(e2) < 2) 
      ade = Inf;
      return
    endif

    ade = abs(e2(2) - e2(1));
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
