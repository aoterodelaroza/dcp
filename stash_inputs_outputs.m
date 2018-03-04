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

function stash_inputs_outputs(ycalc)
  %% function stash_inputs_outputs(ycalc)
  %% 
  %% Move the gjf, the xyz, and the log files given by the names in
  %% cell array ilist to the stash directory (prefix). If a calculated
  %% energy is Inf, move all the information to the <prefix>_failed/
  %% directory.
  
  global nstep prefix db savetar ferr run_inputs

  ## debug
  if (ferr > 0) 
    fprintf(ferr,"# Start stash_inputs_outputs - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Clean up checkpoint files
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.chk' -delete",prefix));

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## Create and populate the failed directory
  if (any(isinf(ycalc)) && !strcmp(func2str(run_inputs),"run_inputs_pass"))
    if (ferr > 0) 
      fprintf(ferr,"# Some calcs failed; moving them to failed directory - %s\n",strtrim(ctime(time())));
      fflush(ferr);
    endif

    ## Create directory
    [s out] = system(sprintf("mkdir %s_fail",prefix));

    ## Make a copy of the failed calcs
    idx = find(isinf(ycalc));
    for i = 1:length(idx)
      [s out] = system(sprintf("cp -f %s_%4.4d_%s_mol* %s_fail",prefix,nstep,db{idx(i)}.name,prefix));
    endfor
  endif

  ## Tar all the inputs and outputs and move to the stash
  if (exist("savetar","var") && !isempty(savetar))
    [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.gjf' -or -name '%s_*.log' -or -name '%s_*.xyz' -or -name '%s_*.wfx' -or -name '%s_*.pgout' -or -name '%s_*.d3out' > filelist.tmp",...
                             prefix,prefix,prefix,prefix,prefix,prefix));
    if (strcmp(tolower(savetar),"bz2"))
      [s out] = system(sprintf("tar cjvf %s_%4.4d.tar.bz2 -T filelist.tmp",prefix,nstep));
    elseif (strcmp(tolower(savetar),"gz"))
      [s out] = system(sprintf("tar czvf %s_%4.4d.tar.gz -T filelist.tmp",prefix,nstep));
    elseif (strcmp(tolower(savetar),"xz"))
      [s out] = system(sprintf("tar cJvf %s_%4.4d.tar.xz -T filelist.tmp",prefix,nstep));
    else
      [s out] = system(sprintf("tar cvf %s_%4.4d.tar -T filelist.tmp",prefix,nstep));
    endif
    [s out] = system(sprintf("rm -f filelist.tmp"));
    [s out] = system(sprintf("mv %s_%4.4d.tar* %s",prefix,nstep,prefix));
  endif
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.gjf' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.xyz' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.log' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.wfx' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.pgout' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.d3out' -delete",prefix));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.chk' -delete",prefix));

  ## debug
  if (ferr > 0) 
    fprintf(ferr,"# End stash_inputs_outputs - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

endfunction
