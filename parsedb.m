function db = parsedb(files)
  %% function db = parsedb(files)
  %%
  %% Reads a list of files containing the description of the calculations
  %% with which the DCPs will be optimized and builds the internal database
  %% for the calculation. 
  
  ## Accept a string instead of a cell array
  if (ischar(files))
    files = {files};
  endif

  ## Go over the files and read the db entries
  db = {};
  ndb = 0;
  for i = 1:length(files)
    ## Check that the file exists
    if (!exist(files{i},"file"))
      aux = strcat(strtrim(files{i}),".db");
      if (!exist(aux,"file"))
        error(sprintf("Initial DB file not found: %s or %s\n",files{i},aux));
      endif
      files{i} = aux;
    endif
    ## Open it
    fid = fopen(files{i},"r");
    if (fid < 0)
      error(sprintf("Error opening file: %s",files{i}));
    endif
    ## Create a new entry in the database for it
    ndb++;
    db{ndb}.file = files{i};
    ## Parse all the keywords
    while (!feof(fid))
      ## Read the next line
      line = strtrim(fgetl(fid));
      if (!ischar(line) || length(line) == 0 || line(1:1) == "#")
        continue
      end
      ## Parse the keyword
      anew = strsplit(line," ");
      keyw = lower(anew{1});
      if (strcmp(keyw,"type"))
        db{ndb}.type = lower(anew{2});
      elseif (strcmp(keyw,"name"))
        db{ndb}.name = anew{2};
      elseif (strcmp(keyw,"ref"))
        db{ndb}.ref = str2num(anew{2});
      elseif (strcmp(keyw,"mol"))
        if (length(anew) == 3)
          db{ndb}.mol.q = str2num(anew{2});
          db{ndb}.mol.mult = str2num(anew{3});
        endif
        n = 0;
        db{ndb}.mol.at = {};
        db{ndb}.mol.x = [];
        do 
          line = strtrim(fgetl(fid));
          if (length(line) == 0 || line(1:1) == "#")
            continue
          end
          if (strcmp(tolower(line),"end"))
            break
          endif
          n++;
          [at x y z] = sscanf(line,"%s %f %f %f","C");
          db{ndb}.mol.at{n} = at;
          db{ndb}.mol.x(n,:) = [x y z];
        until (!ischar(line))
        db{ndb}.mol.nat = n;
      elseif (strcmp(keyw,"mon1"))
        if (length(anew) == 3)
          db{ndb}.mon1.q = str2num(anew{2});
          db{ndb}.mon1.mult = str2num(anew{3});
        elseif (length(anew) == 2 && strcmp(tolower(anew{2}),"void"))
          db{ndb}.mon1.nat = 0;
          continue
        endif 
        n = 0;
        db{ndb}.mon1.at = {};
        db{ndb}.mon1.x = [];
        do 
           line = strtrim(fgetl(fid));
           if (length(line) == 0 || line(1:1) == "#")
             continue
           end
           if (strcmp(tolower(line),"end"))
             break
           endif
           n++;
           [at x y z] = sscanf(line,"%s %f %f %f","C");
           db{ndb}.mon1.at{n} = at;
           db{ndb}.mon1.x(n,:) = [x y z];
        until (!ischar(line))
        db{ndb}.mon1.nat = n;
      elseif (strcmp(keyw,"mon2"))
        if (length(anew) == 3)
          db{ndb}.mon2.q = str2num(anew{2});
          db{ndb}.mon2.mult = str2num(anew{3});
        elseif (length(anew) == 2 && strcmp(tolower(anew{2}),"void"))
          db{ndb}.mon2.nat = 0;
          continue
        endif
        n = 0;
        db{ndb}.mon2.at = {};
        db{ndb}.mon2.x = [];
        do 
           line = strtrim(fgetl(fid));
           if (length(line) == 0 || line(1:1) == "#")
             continue
           end
           if (strcmp(tolower(line),"end"))
             break
           endif
           n++;
           [at x y z] = sscanf(line,"%s %f %f %f","C");
           db{ndb}.mon2.at{n} = at;
           db{ndb}.mon2.x(n,:) = [x y z];
        until (!ischar(line))
        db{ndb}.mon2.nat = n;
      endif
    endwhile
    ## Wrap up
    fclose(fid);
  endfor

end

