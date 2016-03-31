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
      anew = strfields(line);
      keyw = lower(anew{1});
      rest = strrep(line,anew{1},"");
      if (strcmp(keyw,"type"))
        db{ndb}.type = lower(anew{2});
      elseif (strcmp(keyw,"name"))
        db{ndb}.name = rest;
      elseif (strcmp(keyw,"extragau"))
        db{ndb}.extragau = rest;
      elseif (strcmp(keyw,"ref"))
        db{ndb}.ref = str2num(anew{2});
      elseif (strcmp(keyw,"molc"))
        if (!isfield(db{ndb},"nmol"))
          db{ndb}.nmol = 0;
          db{ndb}.molc = {};
        endif
        db{ndb}.nmol++;
        im = db{ndb}.nmol;
        if (length(anew) == 4)
          db{ndb}.molc{im}.coef = str2num(anew{2});
          db{ndb}.molc{im}.q = str2num(anew{3});
          db{ndb}.molc{im}.mult = str2num(anew{4});
        else
          error("missing charge, multiplicity, or coefficient.")
        endif
        n = 0;
        db{ndb}.molc{im}.at = {};
        db{ndb}.molc{im}.x = [];
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
          db{ndb}.molc{im}.at{n} = at;
          db{ndb}.molc{im}.x(n,:) = [x y z];
        until (!ischar(line))
        db{ndb}.molc{im}.nat = n;
      elseif (strcmp(keyw,"mol"))
        db{ndb}.mol = struct();
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
        db{ndb}.mon1 = struct();
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
        db{ndb}.mon2 = struct();
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

