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
    str = "";
    if (exist(sprintf("%s.gjf",ilist{1}),"file"))
      str = sprintf("%s %s_*.gjf",str,prefix);
    endif
    if (exist(sprintf("%s.log",ilist{1}),"file"))
      str = sprintf("%s %s_*.log",str,prefix);
    endif
    if (exist(sprintf("%s.wfx",ilist{1}),"file"))
      str = sprintf("%s %s_*.wfx",str,prefix);
    endif
    if (exist(sprintf("%s.pgout",ilist{1}),"file"))
      str = sprintf("%s %s_*.pgout",str,prefix);
    endif
    [s out] = system(sprintf("tar cjvf %s_%4.4d.tar.bz2 %s",prefix,nstep,str));
    if (!exist(sprintf("%s_%4.4d.tar.bz2",prefix,nstep),"file"))
      error(sprintf("Could not tar inputs/outputs for iteration %d",nstep));
    endif
    [s out] = system(sprintf("mv %s_%4.4d.tar.bz2 %s",prefix,nstep,prefix));
    if (s != 0)
      error(sprintf("Could not move compressed inputs/outputs for iteration %d",nstep));
    endif
    [s out] = system(sprintf("rm -f %s %s_*.chk",str,prefix));
  else
    [s out] = system(sprintf("rm -f %s_*.gjf",prefix));
    [s out] = system(sprintf("rm -f %s_*.log",prefix));
    [s out] = system(sprintf("rm -f %s_*.wfx",prefix));
    [s out] = system(sprintf("rm -f %s_*.pgout",prefix));
    [s out] = system(sprintf("rm -f %s_*.chk",prefix));
  endif

endfunction
