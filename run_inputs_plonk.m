function s = run_inputs_plonk(ilist,cont=0)
  %% function run_inputs_plonk(ilist,cont=0)
  %% 
  %% Run all the inputs in the job list (ilist). The jobs should be  
  %% in the current working directory, with extension gjf. This
  %% routine handles the environment details: where Gaussian is, 
  %% talking to the queue system, etc. The (expected) behavior of 
  %% this routine is that, after completion, the log files for
  %% all the inputs in ilist will also be in the CWD. Optionally,
  %% all checkpoint files (with the same name) should also be
  %% in the CWD.
  %%
  %% If cont is true, continue with the calculations even
  %% if one of the Gaussian input fails. Then return the 
  %% success/failure state in ifail
  %%
  %% This version of run_inputs creates submission scripts for all
  %% inputs in the list and submits them to a private queue. After
  %% that, the routine enters a waiting loop and checks periodically
  %% for the calc results. When all jobs are done, control is given
  %% back to the caller.
  
  global verbose iload
  
  ## Parameters for the run
  sleeptime = 5; ## time in seconds between job completion checks
  maxtime = Inf; ## maximum sleep time in seconds. Crash if the script sleeps
                 ## for longer than this number without a new Gaussian output
                 ## being written.
  jobfile = "~/plonk.jobs"; 

  ## Create submission scripts for all inputs on the list
  fid = -1;
  jobname = {};
  for i = 1:length(ilist)
    name = ilist{i};
    fid = fopen(sprintf("%s.sub",name),"w");
    if (fid < 0) 
      error("Could not create submission script: %s.sub",name);
    endif
    fprintf(fid,"cd %s\n",pwd());
    fprintf(fid,"g09 %s.gjf\n",name);
    fprintf(fid,"touch %s.done\n",name);
    fclose(fid);
    jobname = {jobname{:} sprintf("%s.sub",name)};
  endfor

  ## Submit all the scripts to the queue
  fid = fopen(jobfile,"a");
  for i = 1:length(jobname)
    fprintf(fid,sprintf("%s/%s\n",pwd(),jobname{i}));
  endfor
  fclose(fid);

  ## Wait until all the calcs and jobs are done
  done = zeros(1,length(ilist));
  nslept = 0;
  nslept0 = 0;
  do 
     sleep(sleeptime);
     nslept0 += sleeptime;
     nslept += sleeptime;
     ## Check we didn't exceed the sleeptime
     if (nslept > maxtime)
       error(sprintf("Maximum sleep time %f exceeded: no more done files.",maxtime));
     endif
     ## See if calcs are done
     for i = find(!done)
       if (exist(sprintf("%s.done",ilist{i}),"file"))
         done(i) = 1;
         nslept = 0;
       endif
     endfor
  until(all(done))
  if (verbose)
    printf("All Gaussian outputs are ready after %d seconds\n",nslept0);
  endif

  ## Clean up the done and the err files
  for i = 1:length(ilist)
    [s out] = system(sprintf("rm -f %s.done %s.err %s.sub",ilist{i},ilist{i},ilist{i}));
  endfor

  ## Calculate the load for subsequent runs
  iload = read_jobload(ilist,iload);
  if (verbose)
    printf("# Job load\n")
    printf("| Id | Name | Load (s) |\n")
    for i = 1:length(ilist)
      printf("| %d | %s | %.1f |\n",...
             i,ilist{i},iload(i));
    endfor
    printf("#\n");
  endif

  ## Check that we have a normal termination. If not, pass the error 
  ## back to the caller.
  for i = 1:length(ilist)
    if (!exist(sprintf("%s.log",ilist{i}),"file"))
      s = 1;
      if (cont)
        continue
      else
        return
      endif
    endif
    [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
    if (str2num(out) == 0)
      s = 1;
      if (cont)
        continue
      else
        return
      endif
    endif
  endfor  

endfunction
