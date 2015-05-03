function s = run_inputs_serial(ilist)
  %% function run_inputs_serial(ilist)
  %% 
  %% Run all the inputs in the job list (ilist). The jobs should be  
  %% in the current working directory, with extension gjf. This
  %% routine handles the environment details: where Gaussian is, 
  %% talking to the queue system, etc. The (expected) behavior of 
  %% this routine is that, after completion, the log files for
  %% all the inputs in ilist will also be in the CWD.
  %%
  %% This version of run_inputs runs all input files sequentially
  %% on the same node in which the octave script is running.
  
  global verbose

  ## Run all the jobs in the current working directory
  for i = 1:length(ilist)
    if (verbose)
      printf("%d ",i);
      if (mod(i,10) == 0)
        printf("\n");
      endif
    endif
    [s out] = system(sprintf("g09 %s.gjf",ilist{i}));
    ## Check that Gaussian didn't crap out
    if (s != 0)
      # printf("There was an error from Gaussian running one of the inputs.\n");
      # printf("Input file: %s.gjf\n",ilist{i});
      # printf("Output file: %s.log\n",ilist{i});
      # printf("The system says: %s\n",out);
      # error(sprintf("Gaussian error!"))
      return
    endif
    ## Check that we have a normal termination
    [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
    if (str2num(out) == 0)
      s = 1;
      return
      # printf("There was an error from Gaussian running one of the inputs.\n");
      # printf("I could not see the 'Normal termination' line at the end.\n");
      # printf("Input file: %s.gjf\n",ilist{i});
      # printf("Output file: %s.log\n",ilist{i});
      # error(sprintf("Gaussian error!"))
    endif
  endfor
  if (verbose)
    printf("\n# All gaussian calcs done\n");
  endif

  ## Clean-up everything that is not log or gjf

endfunction
