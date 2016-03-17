% Copyright (C) 2015 Alberto Otero-de-la-Roza <alberto@fluor.quimica.uniovi.es>
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

function sout = run_inputs_serial(ilist,xdm=[],xdmfun="")
  %% function run_inputs_serial(ilist,xdm=[],xdmfun="")
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
  %% This version of run_inputs runs all input files sequentially
  %% on the same node in which the octave script is running.
  
  global verbose

  sout = [];
  
  ## Run all the jobs in the current working directory
  for i = 1:length(ilist)
    if (verbose)
      printf("%d ",i);
      if (mod(i,10) == 0)
        printf("\n");
      endif
    endif
    [s out] = system(sprintf("g09 %s.gjf 2>&1",ilist{i}));
    if (!isempty(xdm))
      [s2 out] = system(sprintf("postg %.10f %.10f %s.wfx %s > %s.pgout\n",xdm(1),xdm(2),ilist{i},xdmfun,ilist{i}));
    endif
    ## Check that Gaussian didn't crap out
    if (s != 0)
      if (exist(sprintf("%s.log",ilist{i}),"file"))
        sout = [sout i];
        continue
      else
        error("Fatal error from Gaussian, could not generate the log file.")
      endif
    endif
    ## Check that we have a normal termination
    [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
    if (str2num(out) == 0)
      sout = [sout i];
    endif
  endfor
  if (verbose)
    printf("# All gaussian calcs done\n");
  endif

  ## Clean-up everything that is not log or gjf

endfunction
