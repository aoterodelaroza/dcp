function clear_checkpoints(ilist=[])
  %% function clear_checkpoints(ilist)
  %% 
  %% Delete all checkpoint files from the CWD. If ilist is empty,
  %% clear the checkpoint files in the stash.
  
  global db prefix usechk
  if (!usechk)
    return
  endif

  if (!isempty(ilist))
    for i = 1:length(ilist)
      if (exist(sprintf("%s.chk",ilist{i}),"file"))
        [s out] = system(sprintf("rm -f %s.chk",ilist{i}));
        if (s != 0)
          error(sprintf("Could not delete checkpoint file %s.chk",ilist{i}))
        endif
      endif
    endfor
  else
    for i = 1:length(db)
      [s out] = system(sprintf("rm -f %s/%s_%s_*.chk",prefix,prefix,db{i}.name));
    endfor
  endif

endfunction
