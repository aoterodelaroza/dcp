% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
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

function sout = run_inputs_plonk(ilist,xdmcoef=[],xdmfun="",extrad3="")
  %% function run_inputs_plonk(ilist,xdmcoef=[],xdmfun="",extrad3="")
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
  %% If xdmcoef is non-empty, run postg on the resulting wfx with the
  %% indicated parameters and the functional in xdmfun.
  %%
  %% This version of run_inputs creates submission scripts for all
  %% inputs in the list and submits them to a private queue. After
  %% that, the routine enters a waiting loop and checks periodically
  %% for the calc results. When all jobs are done, control is given
  %% back to the caller.
  
  global verbose iload ferr
  
  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start run_inputs_plonk - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Parameters for the run
  sleeptime = 5; ## time in seconds between job completion checks
  maxtime = Inf; ## maximum sleep time in seconds. Crash if the script sleeps
                 ## for longer than this number without a new Gaussian output
                 ## being written.
  jobfile = "~/plonk.jobs"; 
  lockdir = "~/plonk.lock";

  ## Check the necessary programs are in the path
  if (!isempty(xdmcoef)) 
    [s out] = system("which postg");
    if (s != 0) 
      error("program postg not found")
    endif
  elseif (!isempty(extrad3))
    [s out] = system("which dftd3");
    if (s != 0) 
      error("program dftd3 not found")
    endif
  endif
  
  ## Create submission scripts for all inputs on the list
  if (ferr > 0) 
    fprintf(ferr,"# Creating submission scripts - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  fid = -1;
  jobname = {};
  for i = 1:length(ilist)
    name = ilist{i};
    if (ferr > 0) 
      fprintf(ferr,"# script %d (%s) - %s\n",i,name,strtrim(ctime(time())));
      fflush(ferr);
    endif
    fid = fopen(sprintf("%s.sub",name),"w");
    if (fid < 0) 
      error("Could not create submission script: %s.sub",name);
    endif
    fprintf(fid,"cd %s\n",pwd());
    fprintf(fid,"g09 %s.gjf\n",name);
    if (!isempty(xdmcoef))
      fprintf(fid,"postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdmcoef(1),xdmcoef(2),name,xdmfun,name);
    elseif (!isempty(extrad3))
      fprintf(fid,"dftd3 %s.xyz %s > %s.d3out\n",name,extrad3,name);
    endif
    fprintf(fid,"rm -f %s.chk\n",name);
    fprintf(fid,"touch %s.done\n",name);
    fclose(fid);
    jobname = {jobname{:} sprintf("%s.sub",name)};
  endfor

  ## Grab the lock
  while (exist(lockdir,"dir") || system(sprintf("mkdir %s",lockdir)))
    sleep(1)
  endwhile

  ## Submit all the scripts to the queue
  if (ferr > 0) 
    fprintf(ferr,"# Appending scripts to the plonk queue - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  fid = fopen(jobfile,"a");
  for i = 1:length(jobname)
    fprintf(fid,sprintf("%s/%s\n",pwd(),jobname{i}));
  endfor
  fclose(fid);

  ## Release the lock
  system(sprintf("rm -rf %s",lockdir));

  ## Wait until all the calcs and jobs are done
  if (ferr > 0) 
    fprintf(ferr,"# Waiting for calcs to finish - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  done = zeros(1,length(ilist));
  nslept = 0;
  nslept0 = 0;
  do 
     if (ferr > 0) 
       fprintf(ferr,"# waiting... (%d/%d done) %s\n",sum(done),length(done),strtrim(ctime(time())));
       fflush(ferr);
     endif
     sleep(sleeptime);
     nslept0 += sleeptime;
     nslept += sleeptime;
     ## Check we didn't exceed the sleeptime
     if (nslept > maxtime)
       error(sprintf("Maximum sleep time %f exceeded: no more done files.",maxtime));
     endif
     ## See if calcs are done
     for i = find(!done)
       if (exist(sprintf("%s.done",ilist{i}),"file") && exist(sprintf("%s.log",ilist{i}),"file"))
	 [s1 out] = system(sprintf("tail -n 3 %s.log | grep -q 'Error termination'",ilist{i}));
         [s2 out] = system(sprintf("tail -n 1 %s.log | grep -q 'Normal termination'",ilist{i}));
         if (s1 == 0 || s2 == 0) 
           done(i) = 1;
           nslept = 0;
         endif
       endif
     endfor
  until(all(done))
  if (ferr > 0) 
    fprintf(ferr,"# All calcs finished - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  if (verbose)
    printf("All Gaussian outputs are ready after %d seconds\n",nslept0);
  endif

  ## Give time to sync the NFS
  sleep(sleeptime);

  ## Clean up the done and the err files
  if (ferr > 0) 
    fprintf(ferr,"# Cleaning up the done/err/sub files - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  for i = 1:length(ilist)
    if (ferr > 0) 
      fprintf(ferr,"# deleting entry %d (%s) - %s\n",i,ilist{i},strtrim(ctime(time())));
      fflush(ferr);
    endif
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
  if (ferr > 0) 
    fprintf(ferr,"# Check for normal/error termination - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  sout = [];
  for i = 1:length(ilist)
    if (ferr > 0) 
      fprintf(ferr,"# normal/error termination %d (%s) - %s\n",i,ilist{i},strtrim(ctime(time())));
      fflush(ferr);
    endif
    if (!exist(sprintf("%s.log",ilist{i}),"file"))
      sout = [sout i];
      continue
    endif
    [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
    if (str2num(out) == 0)
      sout = [sout i];
    endif
  endfor  

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# End run_inputs_plonk - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

endfunction
