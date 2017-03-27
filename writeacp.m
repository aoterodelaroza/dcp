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

function writeacp(acp,file="",atlist={})
  %% function writeacp(acp,file="")
  %%
  %% Write the acp cell array to a Gaussian-style ACP file for use in
  %% calculations. If no file is given, write all the stuff to the stdout. 
  %% If file is a number instead of a string, use that as the file
  %% handle and do not close it at the end. If the cell array atlist 
  %% is given, only the atomic symbols matching those on the list
  %% will be printed.

  ## Try to open the file for output. If that fails, dump the information
  ## to stdout and crash.
  fid = stdout();
  docrash = 0;
  if (ischar(file))
    if (length(file) > 0)
      fid = fopen(file,"w");
      if (fid < 0)
        printf("Error: could not open output file.\n");
        printf("Dumping ACP info RIGHT HERE!\n");
        fid = stdout();
        docrash = 1;
      endif
    endif
  else
    fid = file;
  endif

  ## tolower the atlist
  for i = 1:length(atlist)
    atlist{i} = tolower(atlist{i});
  endfor

  ## Write the ACP
  for i = 1:length(acp)
    if (isempty(atlist) || any(ismember(atlist,tolower(acp{i}.atom))))
      fprintf(fid,"%s 0\n",acp{i}.atom);
      fprintf(fid,"%s %d %d\n",acp{i}.name,acp{i}.nblock-1,acp{i}.nelec);
      for j = 1:acp{i}.nblock
        fprintf(fid,"%s\n",acp{i}.block{j}.name);
        fprintf(fid,"%d\n",acp{i}.block{j}.nterm);
        for k = 1:acp{i}.block{j}.nterm
          fprintf(fid,"  %d   %.9f   %.9f\n",acp{i}.block{j}.n(k),...
                  acp{i}.block{j}.exp(k),acp{i}.block{j}.coef(k));
        endfor
      endfor
    endif
  endfor

  ## Wrap up
  if (docrash)
    error(sprintf("Could not open file for ACP output: %s",file));
  elseif (ischar(file) && fid != stdout())
    fclose(fid);
  endif

endfunction
