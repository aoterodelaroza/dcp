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

function stash_inputs_outputs(ilist)
  %% function stash_inputs_outputs(ilist)
  %% 
  %% Move the gjf and the log files given by the names in cell
  %% array ilist to the stash directory (prefix).
  
  global nstep prefix savetarbz2

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## Tar all the inputs and outputs and move to the stash
  if (exist("savetarbz2","var") && savetarbz2)
    [s out] = system(sprintf("find . -name '%s_*.chk' -delete",prefix));
    [s out] = system(sprintf("find . -name '%s_*.*' > filelist.tmp",prefix));
    [s out] = system(sprintf("tar cjvf %s_%4.4d.tar.bz2 -T filelist.tmp",prefix,nstep));
    [s out] = system(sprintf("rm -f filelist.tmp"));
    [s out] = system(sprintf("mv %s_%4.4d.tar.bz2 %s",prefix,nstep,prefix));
  endif
  [s out] = system(sprintf("find . -name '%s_*.gjf' -delete",prefix));
  [s out] = system(sprintf("find . -name '%s_*.log' -delete",prefix));
  [s out] = system(sprintf("find . -name '%s_*.wfx' -delete",prefix));
  [s out] = system(sprintf("find . -name '%s_*.pgout' -delete",prefix));
  [s out] = system(sprintf("find . -name '%s_*.chk' -delete",prefix));

endfunction
