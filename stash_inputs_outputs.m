function stash_inputs_outputs(ilist)
  %% function stash_inputs_outputs(ilist)
  %% 
  %% Move the gjf and the log files given by the names in cell
  %% array ilist to the stash directory (prefix).
  
  global nstep prefix

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## Tar all the inputs and outputs and move to the stash
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

endfunction
