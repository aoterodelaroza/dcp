function dcp = parsedcp(alist)
  %% function dcp = parsedcp(alist)
  %%
  %% Read the alist file containing a DCP specification in Gaussian
  %% format for one or more atom.  alist can be either a string or a
  %% cell structure of strings. All strings should correspond to a
  %% file. The parsedcp routine returns the DCPs in a cell array of
  %% structures.

  ## Accept a string instead of a cell array
  if (ischar(alist))
    alist = {alist};
  endif
  
  ## Run over all files and read the DCPs
  ndcp = 0;
  dcp = cell();
  for i = 1:length(alist)
    ## Check that the file exists
    if (!exist(alist{i},"file"))
      error(sprintf("Initial DCP file not found: %s\n",alist{i}));
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
      anew = strfields(line);
      if (length(anew) != 2)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      endif
      ## Add the new DCP
      ndcp++;
      dcp{ndcp}.atom = anew{1};
      ## Read the second line
      line = strtrim(fgetl(fid));
      if (!ischar(line) || length(line) == 0)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      end
      anew = strfields(line);
      if (length(anew) != 3)
        error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
      endif
      dcp{ndcp}.name = anew{1};
      dcp{ndcp}.nblock = str2num(anew{2})+1;
      dcp{ndcp}.block = cell(1,dcp{ndcp}.nblock);
      dcp{ndcp}.nelec = str2num(anew{3});
      dcp{ndcp}.nparam = 0;
      ## Read all the blocks
      for i = 1:dcp{ndcp}.nblock
        ## Title of the block
        line = strtrim(fgetl(fid));
        if (!ischar(line) || length(line) == 0)
          error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
        end
        dcp{ndcp}.block{i}.name = line;

        ## Number of terms in the DCP
        line = strtrim(fgetl(fid));
        if (!ischar(line) || length(line) == 0)
          error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
        end
        dcp{ndcp}.block{i}.nterm = sscanf(line,"%d","C");
        dcp{ndcp}.block{i}.n = zeros(dcp{ndcp}.block{i}.nterm,1);
        dcp{ndcp}.block{i}.exp = zeros(dcp{ndcp}.block{i}.nterm,1);
        dcp{ndcp}.block{i}.coef = zeros(dcp{ndcp}.block{i}.nterm,1);
        for j = 1:dcp{ndcp}.block{i}.nterm
          line = strtrim(fgetl(fid));
          if (length(line) == 0)
            error(sprintf("Incorrect Gaussian ECP format in file %s, line '%s'",alist{i},line));
          end
          [a1 a2 a3] = sscanf(line,"%f %f %f","C");
          dcp{ndcp}.block{i}.n(j) = a1;
          dcp{ndcp}.block{i}.exp(j) = a2;
          dcp{ndcp}.block{i}.coef(j) = a3;
          dcp{ndcp}.nparam += 2;
        endfor
      endfor
    endwhile
    fclose(fid);
  endfor
end
