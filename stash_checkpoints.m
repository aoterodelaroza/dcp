function stash_checkpoints(ilist)
  %% function stash_checkpoints(ilist)
  %% 
  %% Send all checkpoint files to the stash.
  
  global nstep prefix usechk

  if (!usechk)
    return
  endif

  for i = 1:length(ilist)
    name = strrep(ilist{i},sprintf("%s_%4.4d",prefix,nstep),prefix);
    if (exist(sprintf("%s.chk",ilist{i}),"file"))
      [s out] = system(sprintf("mv %s.chk %s/%s.chk",ilist{i},prefix,name));
      if (s != 0)
        error(sprintf("Could not move checkpoint file %s.chk -> %s/%s.chk",ilist{i},prefix,name))
      endif
    endif
  endfor

endfunction
