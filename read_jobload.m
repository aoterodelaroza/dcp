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

function iload = read_jobload(ilist,iload0=[])
  %% function iload = read_jobload(ilist,iload0=[])
  %%
  %% Read the job cpu time for the given Gaussian outputs and
  %% return an array of the CPU seconds each input took. 
  %% iload0 is the load vector from a previous iteration. 
  %% If iload0 is present its values are used to fill in for
  %% the outputs for which Gaussian crashed.

  iload = zeros(size(ilist));
  for i = 1:length(ilist)
    isdone = 0;
    if (exist(sprintf("%s.log",ilist{i}),"file"))
      [s out] = system(sprintf("tail -n 1 %s.log | grep 'Normal termination' | wc -l",ilist{i}));
      if (str2num(out) > 0)
        isdone = 1;
      endif
    endif
    if (!isdone)
      if (!isempty(iload0))
        iload(i) = iload0(i);
      else
        ## some crazy number... god nows where this guy'll end up
        iload(i) = 1000; 
      endif
    else
      [s out] = system(sprintf("grep 'Job cpu time' %s.log | head -n 1 | awk '{print $10+60*($8+60*($6+24*($4)))}'",ilist{i}));
      if (s != 0) 
        error("Error in read_jobload: could not find 'Job cpu time' string.");
      endif
      iload(i) = str2num(out);
    endif
  endfor
endfunction
