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

function basis = parsebasis(alist)
  %% function basis = parsebasis(alist)
  %%
  %% Read the alist file containing a basis-set specification in
  %% Gaussian format for one or more atom. alist can be either a
  %% string or a cell structure of strings. The strings can point to a
  %% file, in which case parsebasis will read them and return the
  %% corresponding cell array of structures. If alist is a string that
  %% does not correspond to a file, then the string itself is returned
  %% inside a simple cell array. This signals writebasis to use it as
  %% a Gaussian basis set keyword.

  ## Accept a string instead of a cell array
  if (ischar(alist))
    if (!exist(alist,"file"))
      basis = alist;
      return
    else
      alist = {alist};
    endif
  endif
  
  ## Run over all files and read the basis files
  nbas = 0;
  basis = cell();
  for i = 1:length(alist)
    ## Check that the file exists
    if (!exist(alist{i},"file"))
      error(sprintf("Initial basis file not found: %s\n",alist{i}));
    endif
    ## Open and read the file
    fid = fopen(alist{i},"r");
    if (fid < 0)
      error(sprintf("Error opening file: %s",files{i}));
    endif
    while (!feof(fid))
      ## Skip blank lines and four-star lines
      line = strtrim(fgetl(fid));
      if (!ischar(line) || length(line) == 0)
        continue
      end
      if (strcmp(line,"****"))
        continue
      endif
      ## This is the 'Atom 0' line at the beginning
      curatoms = {};
      anew = strfields(line);
      if (anew{end} != "0")
        error(sprintf("Incorrect Gaussian basis format in file %s, line '%s'",alist{i},line));
      endif
      curatoms = anew(1:end-1);
      ## Add the new basis set for this atom
      nbas++;
      basis{nbas}.atom = curatoms{1};
      basis{nbas}.name = curatoms{1};
      basis{nbas}.nblock = 0;
      basis{nbas}.block = cell();
      line = strtrim(fgetl(fid));
      if (!ischar(line) || length(line) == 0)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      end
      while (!strcmp(line,"****"))
        basis{nbas}.nblock++;
        [ityp inum rdum] = sscanf(line,"%s %d %f","C");
        if (isempty(inum))
          basis{nbas}.bstring = ityp;
          basis{nbas}.nblock = 0;
          break
        else
          basis{nbas}.bstring = [];
          basis{nbas}.block{basis{nbas}.nblock}.type = ityp;
          basis{nbas}.block{basis{nbas}.nblock}.bit1 = rdum;
          basis{nbas}.block{basis{nbas}.nblock}.nprim = inum;
          basis{nbas}.block{basis{nbas}.nblock}.exp = zeros(1,inum);
          basis{nbas}.block{basis{nbas}.nblock}.coef1 = zeros(1,inum);
          basis{nbas}.block{basis{nbas}.nblock}.coef2 = zeros(1,inum);
        endif
        for k = 1:inum
          line = strtrim(fgetl(fid));
          if (!ischar(line) || length(line) == 0)
            error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
          end
          [rexp rcoef rcoef2] = sscanf(line,"%f %f %f","C");
          basis{nbas}.block{basis{nbas}.nblock}.exp(k) = rexp;
          basis{nbas}.block{basis{nbas}.nblock}.coef1(k) = rcoef;
          if (isempty(rcoef2))
            basis{nbas}.block{basis{nbas}.nblock}.coef2(k) = NaN;
          else
            basis{nbas}.block{basis{nbas}.nblock}.coef2(k) = rcoef2;
          endif
        endfor
        line = strtrim(fgetl(fid));
        if (!ischar(line) || length(line) == 0)
          error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
        end
      endwhile

      nbas0 = nbas;
      for k = 2:length(curatoms)
        nbas++;
        basis{nbas} = basis{nbas0};
        basis{nbas}.atom = curatoms{k};
        basis{nbas}.name = curatoms{k};
      endfor
    endwhile
    fclose(fid);
  endfor
end
