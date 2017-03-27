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

function acp = parseacp(alist)
  %% function acp = parseacp(alist)
  %%
  %% Read the alist file containing a ACP specification in Gaussian
  %% format for one or more atom.  alist can be either a string or a
  %% cell structure of strings. All strings should correspond to a
  %% file. The parseacp routine returns the ACPs in a cell array of
  %% structures.

  global ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start parseacp - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Accept a string instead of a cell array
  if (ischar(alist))
    alist = {alist};
  endif
  
  ## Run over all files and read the ACPs
  nacp = 0;
  acp = cell();
  for i = 1:length(alist)
    ## Check that the file exists
    if (!exist(alist{i},"file"))
      error(sprintf("Initial ACP file not found: %s\n",alist{i}));
    endif
    ## Open and read the file
    fid = fopen(alist{i},"r");
    if (fid < 0)
      error(sprintf("Error opening file: %s",files{i}));
    endif
    while (!feof(fid))
      line = fgetl(fid);
      if (feof(fid))
        break
      endif
      ## Skip blank lines and four-star lines
      line = strtrim(line);
      if (!ischar(line) || length(line) == 0)
        continue
      end
      if (strcmp(line,"****"))
        continue
      endif
      ## This is the 'Atom 0' line at the beginning. Add the new ACP
      anew = strfields(line);
      nacp++;
      acp{nacp}.atom = strrep(anew{1},"-","");
      ## Read the second line
      line = strtrim(fgetl(fid));
      if (!ischar(line) || length(line) == 0)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      end
      anew = strfields(line);
      if (length(anew) != 3)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      endif
      acp{nacp}.name = anew{1};
      acp{nacp}.nblock = str2num(anew{2})+1;
      acp{nacp}.block = cell(1,acp{nacp}.nblock);
      acp{nacp}.nelec = str2num(anew{3});
      acp{nacp}.nparam = 0;
      ## Read all the blocks
      for i = 1:acp{nacp}.nblock
        ## Title of the block
        line = strtrim(fgetl(fid));
        if (!ischar(line) || length(line) == 0)
          error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
        end
        acp{nacp}.block{i}.name = line;

        ## Number of terms in the ACP
        line = strtrim(fgetl(fid));
        if (!ischar(line) || length(line) == 0)
          error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
        end
        acp{nacp}.block{i}.nterm = sscanf(line,"%d","C");
        acp{nacp}.block{i}.n = zeros(acp{nacp}.block{i}.nterm,1);
        acp{nacp}.block{i}.exp = zeros(acp{nacp}.block{i}.nterm,1);
        acp{nacp}.block{i}.coef = zeros(acp{nacp}.block{i}.nterm,1);
        for j = 1:acp{nacp}.block{i}.nterm
          line = strtrim(fgetl(fid));
          if (length(line) == 0)
            error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
          end
          [a1 a2 a3] = sscanf(line,"%f %f %f","C");
          acp{nacp}.block{i}.n(j) = a1;
          acp{nacp}.block{i}.exp(j) = a2;
          acp{nacp}.block{i}.coef(j) = a3;
          acp{nacp}.nparam += 2;
        endfor
      endfor
    endwhile
    fclose(fid);
  endfor

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# End parseacp - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
end
