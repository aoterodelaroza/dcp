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

function sout = run_inputs_plonk_packed(ilist,xdm=[],xdmfun="")
  %% function run_inputs_plonk_packed(ilist,xdm=[],xdmfun="")
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
  %% If xdm is non-empty, run postg on the resulting wfx with
  %% the indicated parameters and the functional in xdmfun.
  %%
  %% This version of run_inputs packs all the inputs in the list, 
  %% and moves them to ~/run/, then creates submission scripts
  %% to run all the inputs in each archive file and pack the log
  %% files. The packed outputs are brought back to the ~/run
  %% directory. When all archives are done, control is given 
  %% back to the caller.
  
  global verbose iload prefix
  
  ## Parameters for the run
  sleeptime = 5; ## time in seconds between job completion checks
  maxtime = Inf; ## maximum sleep time in seconds. Crash if the script sleeps
                 ## for longer than this number without a new Gaussian output
                 ## being written.
  jobfile = "~/plonk.jobs"; 
  lockdir = "~/plonk.lock";
  dirname = sprintf("%s_%d",prefix,getpid());
  npack = 200;

  ## randomize ilist
  iperm = randperm(length(ilist));
  ilistr = ilist(iperm);

  ## pack
  ngjf = ceil(length(ilist) / npack);
  npack = ceil(length(ilist) / ngjf);
  k = 0;
  for i = 1:npack
    str = "";
    for j = 1:ngjf
      k++;
      if (k > length(ilist))
        break
      endif
      str = sprintf("%s %s.gjf",str,ilistr{k});
    endfor
    system(sprintf("echo %s | xargs tar cjf %s_%4.4d.tar.bz2",str,prefix,i));
  endfor

  ## Create submission scripts for all inputs on the list
  fid = -1;
  jobname = {};
  for i = 1:npack
    name = sprintf("%s_%4.4d",prefix,i);
    fid = fopen(sprintf("%s.sub",name),"w");
    if (fid < 0) 
      error("Could not create submission script: %s.sub",name);
    endif
    fprintf(fid,"mkdir -p /home/alberto/run/%s\n",dirname);
    fprintf(fid,"cd /home/alberto/run/%s\n",dirname);
    fprintf(fid,"mkdir -p $TMPDIR\n");
    fprintf(fid,"cp -f %s.tar.bz2 $TMPDIR\n",name);
    fprintf(fid,"cd $TMPDIR\n");
    fprintf(fid,"tar xjf %s.tar.bz2\n",name);
    fprintf(fid,"for j in *.gjf ; do\n");
    fprintf(fid,"  g09 $j\n");
    fprintf(fid,"done\n");
    fprintf(fid,"tar cjf %s.tar.bz2 *.log\n",name);
    fprintf(fid,"mv %s.tar.bz2 /home/alberto/run/%s\n",name,dirname);
    fprintf(fid,"cd /home/alberto/run/%s\n",dirname);
    fprintf(fid,"rm -rf $TMPDIR\n");
    fprintf(fid,"mkdir -p $TMPDIR\n");
    fprintf(fid,"touch %s.done\n",name);
    fclose(fid);
    jobname = {jobname{:} sprintf("/home/alberto/run/%s/%s.sub",dirname,name)};
  endfor

  ## Move all the files to the run directory
  [s out] = system(sprintf("mkdir -p /home/alberto/run/%s",dirname));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.tar.bz2' | xargs mv -t /home/alberto/run/%s",prefix,dirname));
  [s out] = system(sprintf("find . -maxdepth 1 -name '%s_*.sub' | xargs mv -t /home/alberto/run/%s",prefix,dirname));

  ## Grab the lock
  while (exist(lockdir,"dir") || system(sprintf("mkdir %s",lockdir)))
    sleep(1)
  endwhile

  ## Submit all the scripts to the queue
  fid = fopen(jobfile,"a");
  for i = 1:length(jobname)
    fprintf(fid,sprintf("%s\n",jobname{i}));
  endfor
  fclose(fid);

  ## Release the lock
  system(sprintf("rm -rf %s",lockdir));

  ## Wait until all the calcs and jobs are done
  done = zeros(1,npack);
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
       if (exist(sprintf("/home/alberto/run/%s/%s_%4.4d.done",dirname,prefix,i),"file") && ...
           exist(sprintf("/home/alberto/run/%s/%s_%4.4d.tar.bz2",dirname,prefix,i),"file"))
         done(i) = 1;
         nslept = 0;
       endif
     endfor
  until(all(done))
  if (verbose)
    printf("All Gaussian outputs are ready after %d seconds\n",nslept0);
  endif

  ## Clean up the done and the err files
  [s out] = system(sprintf("rm -f /home/alberto/run/%s/*.done /home/alberto/run/%s/*sub",dirname,dirname));
  [s out] = system(sprintf("find /home/alberto/run/%s/ -maxdepth 1 -name '*.tar.bz2' | xargs mv -t .",dirname));
  for i = 1:npack
    system(sprintf("tar xjf %s_%4.4d.tar.bz2",prefix,i));
    system(sprintf("rm -f %s_%4.4d.tar.bz2",prefix,i));
  endfor

  ## ## Calculate the load for subsequent runs
  ## iload = read_jobload(ilist,iload);
  ## if (verbose)
  ##   printf("# Job load\n")
  ##   printf("| Id | Name | Load (s) |\n")
  ##   for i = 1:length(ilist)
  ##     printf("| %d | %s | %.1f |\n",...
  ##            i,ilist{i},iload(i));
  ##   endfor
  ##   printf("#\n");
  ## endif
  iload = ones(size(ilist));

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
