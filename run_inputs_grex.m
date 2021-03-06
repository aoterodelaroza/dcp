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

function sout = run_inputs_grex(ilist,xdmcoef=[],xdmfun="",extrad3="")
  %% function run_inputs_grex(ilist,xdmcoef=[],xdmfun="",extrad3="")
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
  %% If xdmcoef is non-empty, run postg on the resulting wfx with
  %% the indicated parameters and the functional in xdmfun.
  %%
  %% This version of run_inputs creates submission scripts for all
  %% inputs in the list and submits them to grex. After that,
  %% the routine enters a waiting loop and checks periodically for
  %% the calc results. When all jobs are done, control is given back
  %% to the caller.
  
  ## Parameters for the run
  hours = 2; ## walltime hours
  ncpu0 = 6; ## number of cores (local)
  mem0 = 4; ## memory in GB (local)
  sleeptime = 5; ## time in seconds between job completion checks
  usenodes = 6; ## pack all available jobs so that only usenodes number of nodes 
                ## are used. If usenodes = -1, submit one job per Gaussian input.
  maxtime = Inf; ## maximum sleep time in seconds. Crash if the script sleeps
                 ## for longer than this number without a new Gaussian output
                 ## being written.

  if (!isempty(extrad3))
    error("d3 calculations not supported by this run_inputs driver")
  endif

  if (usenodes > 0) 
    every = ceil(length(ilist) / usenodes);
  else
    every = 1;
  endif

  ## randomize the input list
  idx = randperm(length(ilist));

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
      fprintf(fid,"#PBS -S /bin/bash\n");
      fprintf(fid,"#PBS -j eo\n");
      fprintf(fid,"#PBS -e %s/%s.err \n",pwd(),name);
      fprintf(fid,"#PBS -N acp_%s\n",name);
      fprintf(fid,"#PBS -l walltime=%d:00:00,mem=%dGB,nodes=1:ppn=%d\n",hours,mem0,ncpu0);
      fprintf(fid,"#PBS -m n\n");
      fprintf(fid,"\n");
      fprintf(fid,"module load gaussian/g09.d01\n");
      fprintf(fid,"export OMP_NUM_THREADS=6\n");
      fprintf(fid,"\n");
      fprintf(fid,"cd %s\n",pwd());
      fprintf(fid,"g09 %s.gjf\n",name);
      if (!isempty(xdmcoef))
        fprintf(fid,"~/git/postg/postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdmcoef(1),xdmcoef(2),name,xdmfun,name);
      endif
      fprintf(fid,"touch %s.done\n",name);
      jobname = {jobname{:} sprintf("%s.sub",name)};
    else
      fprintf(fid,"g09 %s.gjf\n",name);
      if (!isempty(xdmcoef))
        fprintf(fid,"~/git/postg/postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdmcoef(1),xdmcoef(2),name,xdmfun,name);
      endif
      fprintf(fid,"touch %s.done\n",name);
    endif
  endfor
  if (fid > 0)
    fclose(fid);
  endif

  ## Give time to sync the NFS
  pause(sleeptime);

  ## Submit all the scripts to the queue
  jobstr = "";
  for i = 1:length(jobname)
    [s out] = system(sprintf("qsub %s",jobname{i}));
    if (s != 0)
      error("Could not submit script: %s",jobname{i});
    endif
    aux = strsplit(strtrim(out),".");
    jobstr = sprintf("%s %s",jobstr,aux{1});
  endfor

  ## Wait until all the calcs and jobs are done
  done = zeros(1,length(ilist));
  nslept = 0;
  nslept0 = 0;
  do 
     pause(sleeptime);
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

  ## Clean up the done and the err files
  for i = 1:length(ilist)
    [s out] = system(sprintf("rm -f %s.done %s.err %s.sub",ilist{i},ilist{i},ilist{i}));
  endfor

  ## Check that we have a normal termination. If not, pass the error 
  ## back to the caller.
  sout = [];
  for i = 1:length(ilist)
    if (!exist(sprintf("%s.log",ilist{i}),"file"))
      sout = [sout i];
      continue
    endif
    [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
    if (str2num(out) == 0)
      sout = [sout i];
    endif
  endfor  

endfunction
