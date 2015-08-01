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
  for i = 1:length(ilist)
    str = sprintf("%s %s.gjf %s.log %s.err",str,ilist{i},ilist{i});
  endfor
  [s out] = system(sprintf("tar cjvf %s_%4.4d.tar.bz2 %s",prefix,nstep,str));
  if (s != 0)
    error(sprintf("Could not tar inputs/outputs for iteration %d",nstep));
  endif
  [s out] = system(sprintf("mv %s_%4.4d.tar.bz2 %s",prefix,nstep,prefix));
  if (s != 0)
    error(sprintf("Could not move compressed inputs/outputs for iteration %d",nstep));
  endif
  [s out] = system(sprintf("rm -f %s %s_*.chk",str,prefix));

endfunction
