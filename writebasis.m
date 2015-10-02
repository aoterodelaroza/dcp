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

function writebasis(basis,file="",atlist={})
  %% function writebasis(basis,file="",atlist={})
  %%
  %% Write the basis set cell array to a Gaussian-style basis set file
  %% for use in calculations. If no file is given, write all the stuff
  %% to the stdout. If file is a number instead of a string, use that
  %% as the file handle and do not close it at the end. If the cell
  %% array atlist is given, only the atomic symbols matching those on
  %% the list will be printed.

  ## Try to open the file for output. If that fails, dump the information
  ## to stdout and crash.
  fid = stdout();
  docrash = 0;
  if (ischar(file))
    if (length(file) > 0)
      fid = fopen(file,"w");
      if (fid < 0)
        printf("Error: could not open output file.\n");
        printf("Dumping basis-set info RIGHT HERE!\n");
        fid = stdout();
        docrash = 1;
      endif
    endif
  else
    fid = file;
  endif

  ## If it is not a cell array, then it must be a string, and we do not 
  ## need a gen block
  if (!iscell(basis))
    return
  endif

  ## Write the basis
  for i = 1:length(basis)
    if (isempty(atlist) || any(ismember(tolower(atlist),tolower(basis{i}.atom))))
      fprintf(fid,"%s 0\n",basis{i}.atom);
      if (basis{i}.nblock == 0)
        fprintf(fid,"%s\n",basis{i}.bstring);
      else
        for j = 1:basis{i}.nblock
          fprintf(fid,"%s %d %.2f\n",basis{i}.block{j}.type,...
                  basis{i}.block{j}.nprim,basis{i}.block{j}.bit1);
          for k = 1:basis{i}.block{j}.nprim
            fprintf(fid,"%.7f %.7f",basis{i}.block{j}.exp(k),...
                    basis{i}.block{j}.coef1(k));
            if (isnan(basis{i}.block{j}.coef2(k)))
              fprintf(fid,"\n");
            else
              fprintf(fid," %.7f\n",basis{i}.block{j}.coef2(k));
            endif
          endfor
        endfor
      endif
      fprintf(fid,"****\n");
    endif
  endfor

  ## Wrap up
  if (docrash)
    error(sprintf("Could not open file for basis set output: %s",file));
  elseif (ischar(file) && fid != stdout())
    fclose(fid);
  endif

endfunction
