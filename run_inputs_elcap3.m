function s = run_inputs_elcap3(ilist,cont=0,xdm=[],xdmfun="")
  %% function run_inputs_elcap3(ilist,cont=0,xdm=[],xdmfun="")
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
  %% If xdm is non-empty, run postg on the resulting wfx with
  %% the indicated parameters and the functional in xdmfun.
  %%
  %% This version of run_inputs creates submission scripts for all
  %% inputs in the list and submits them to elcap3. After that,
  %% the routine enters a waiting loop and checks periodically for
  %% the calc results. When all jobs are done, control is given back
  %% to the caller.
  
  global verbose iload
  
  ## Parameters for the run
  hours = 2; ## walltime hours
  ncpu = 4; ## number of cores
  mem = 4; ## memory in GB
  sleeptime = 5; ## time in seconds between job completion checks
  usenodes = 6; ## pack all available jobs so that only usenodes number of nodes 
                ## are used. If usenodes = -1, submit one job per Gaussian input.
  maxtime = Inf; ## maximum sleep time in seconds. Crash if the script sleeps
                 ## for longer than this number without a new Gaussian output
                 ## being written.

  if (usenodes > 0) 
    every = ceil(length(ilist) / usenodes);
  else
    every = 1;
  endif

  if (isempty(iload)) 
    ## No information: randomize the input list
    idx = randperm(length(ilist));
  else
    [idum idx] = sort(iload);
    n = length(ilist);
    k = usenodes;
    idx = [idx zeros(1,k*ceil(n/k)-n)];
    idx = reshape(idx,k,ceil(n/k));
    idx = idx';
    idx = reshape(idx,1,k*ceil(n/k));
  endif

  ## Create submission scripts for all inputs on the list
  fid = -1;
  jobname = {};
  for i = 1:length(idx)
    if (idx(i) == 0)
      continue
    endif
    name = ilist{idx(i)};
    if (mod(i-1,every) == 0)
      if (fid > 0)
        fclose(fid);
      endif
      fid = fopen(sprintf("%s.sub",name),"w");
      if (fid < 0) 
        error("Could not create submission script: %s.sub",name);
      endif
      fprintf(fid,"#! /bin/bash\n");
      fprintf(fid,"#$ -S /bin/bash\n");
      fprintf(fid,"#$ -q ethernet.q\n");
      fprintf(fid,"#$ -P ejohnson29_project\n");
      fprintf(fid,"#$ -o %s/%s.err \n",pwd(),name);
      fprintf(fid,"#$ -pe ompi_4slot 4\n");
      fprintf(fid,"#$ -N g09_%s\n",name);
      fprintf(fid,"#$ -cwd\n");
      fprintf(fid,"#$ -V\n");
      fprintf(fid,"\n");
      fprintf(fid,"# env vars, machine dependent\n");
      fprintf(fid,"PATH=./:/usr/local/bin:/usr/bin:/bin:/usr/games:/sbin:/usr/sbin:/usr/local/sbin\n");
      fprintf(fid,"PATH=${PATH}:~/bin\n");
      fprintf(fid,"PATH=${PATH}:~/cvs/octave_scripts\n");
      fprintf(fid,"export PATH\n");
      fprintf(fid,"\n");
      fprintf(fid,"LD_LIBRARY_PATH=.:/home/alberto/lib:/usr/lib:/usr/lib64:/lib\n");
      fprintf(fid,"export LD_LIBRARY_PATH\n");
      fprintf(fid,"\n");
      fprintf(fid,"# sge\n");
      fprintf(fid,"export PATH=${PATH}:/opt/sge/bin/linux-x64/\n");
      fprintf(fid,"\n");
      fprintf(fid,"# intel fortran compiler\n");
      fprintf(fid,". /opt/apps/intel/composer_xe_2011_sp1.6.233/bin/compilervars.sh intel64\n");
      fprintf(fid,". /opt/apps/intel/composer_xe_2011_sp1.6.233/mkl/bin/mklvars.sh intel64\n");
      fprintf(fid,"\n");
      fprintf(fid,"# bashlib\n");
      fprintf(fid,"export PATH=${PATH}:~/cvs/bashlib/awk\n");
      fprintf(fid,"\n");
      fprintf(fid,"# g09\n");
      fprintf(fid,"export g09root="/opt/apps"\n");
      fprintf(fid,"export GAUSS_SCRDIR=$TMP\n");
      fprintf(fid,". $g09root/g09/bsd/g09.profile\n");
      fprintf(fid,"\n");
      fprintf(fid,"# postg\n");
      fprintf(fid,"export POSTG_HOME=/opt/apps/postg\n");
      fprintf(fid,"export PATH=${PATH}:/opt/apps/postg\n");
      fprintf(fid,"export OMP_NUM_THREADS=4\n");
      fprintf(fid,"\n");
      fprintf(fid,"cd %s\n",pwd());
      fprintf(fid,"g09 %s.gjf\n",name);
      if (!isempty(xdm))
        fprintf(fid,"postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdm(1),xdm(2),name,xdmfun,name);
      endif
      fprintf(fid,"touch %s.done\n",name);
      jobname = {jobname{:} sprintf("%s.sub",name)};
    else
      fprintf(fid,"g09 %s.gjf\n",name);
      if (!isempty(xdm))
        fprintf(fid,"postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdm(1),xdm(2),name,xdmfun,name);
      endif
      fprintf(fid,"touch %s.done\n",name);
    endif
  endfor
  if (fid > 0)
    fclose(fid);
  endif

  ## Give time to sync the NFS
  sleep(sleeptime);

  ## Submit all the scripts to the queue
  jobstr = "";
  for i = 1:length(jobname)
    [s out] = system(sprintf("qsub %s",jobname{i}));
    if (s != 0)
      error("Could not submit script: %s",jobname{i});
    endif
    aux = strsplit(strtrim(out),".");
    if (verbose)
      printf("Job %s submitted for %s\n",aux{1},jobname{i});
    endif
    jobstr = sprintf("%s %s",jobstr,aux{1});
  endfor

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
       error(sprintf("Maximum sleep time %f exceeded: no qstat available.",maxtime));
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
