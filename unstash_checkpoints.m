function unstash_checkpoints(ilist)
  %% function unstash_checkpoints(ilist)
  %% 
  %% Copy checkpoint files from the stash to the CWD.
  
  global nstep prefix usechk

  if (!usechk)
    return
  endif

  for i = 1:length(ilist)
    name = strrep(ilist{i},sprintf("%s_%4.4d",prefix,nstep),prefix);
    if (exist(sprintf("%s/%s.chk",prefix,name),"file"))
      [s out] = system(sprintf("cp -f %s/%s.chk %s.chk",prefix,name,ilist{i}));
      if (s != 0)
        error(sprintf("Could not copy checkpoint file %s/%s.chk -> %s.chk",prefix,name,ilist{i}))
      endif
    endif
  endfor

endfunction
