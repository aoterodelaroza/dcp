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

function db = parsedb(files)
  %% function db = parsedb(files)
  %%
  %% Reads a list of files containing the description of the calculations
  %% with which the DCPs will be optimized and builds the internal database
  %% for the calculation. 
  
  global ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start parsedb - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Accept a string instead of a cell array
  if (ischar(files))
    files = {files};
  endif

  ## Go over the files and read the db entries
  db = {};
  ndb = 0;
  for i = 1:length(files)
    ## Debug
    if (ferr > 0)
      fprintf(ferr,"# Reading file %d (%s) at %s\n",i,files{i},strtrim(ctime(time())));
      fflush(ferr);
    endif
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
    ismp = zeros(1,34);
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
        if (length(anew) > 2) 
          mp = lower(anew{2});
          if (strcmp(mp,"x"))
            db{ndb}.ref(1) = str2num(anew{3});
            ismp(1) = 1;
          elseif (strcmp(mp,"y"))
            db{ndb}.ref(2) = str2num(anew{3});
            ismp(2) = 1;
          elseif (strcmp(mp,"z"))
            db{ndb}.ref(3) = str2num(anew{3});
            ismp(3) = 1;
          elseif (strcmp(mp,"xx"))
            db{ndb}.ref(4) = str2num(anew{3});
            ismp(4) = 1;
          elseif (strcmp(mp,"yy"))
            db{ndb}.ref(5) = str2num(anew{3});
            ismp(5) = 1;
          elseif (strcmp(mp,"zz"))
            db{ndb}.ref(6) = str2num(anew{3});
            ismp(6) = 1;
          elseif (strcmp(mp,"xy"))
            db{ndb}.ref(7) = str2num(anew{3});
            ismp(7) = 1;
          elseif (strcmp(mp,"xz"))
            db{ndb}.ref(8) = str2num(anew{3});
            ismp(8) = 1;
          elseif (strcmp(mp,"yz"))
            db{ndb}.ref(9) = str2num(anew{3});
            ismp(9) = 1;
          elseif (strcmp(mp,"xxx"))
            db{ndb}.ref(10) = str2num(anew{3});
            ismp(10) = 1;
          elseif (strcmp(mp,"yyy"))
            db{ndb}.ref(11) = str2num(anew{3});
            ismp(11) = 1;
          elseif (strcmp(mp,"zzz"))
            db{ndb}.ref(12) = str2num(anew{3});
            ismp(12) = 1;
          elseif (strcmp(mp,"xyy"))
            db{ndb}.ref(13) = str2num(anew{3});
            ismp(13) = 1;
          elseif (strcmp(mp,"xxy"))
            db{ndb}.ref(14) = str2num(anew{3});
            ismp(14) = 1;
          elseif (strcmp(mp,"xxz"))
            db{ndb}.ref(15) = str2num(anew{3});
            ismp(15) = 1;
          elseif (strcmp(mp,"xzz"))
            db{ndb}.ref(16) = str2num(anew{3});
            ismp(16) = 1;
          elseif (strcmp(mp,"yzz"))
            db{ndb}.ref(17) = str2num(anew{3});
            ismp(17) = 1;
          elseif (strcmp(mp,"yyz"))
            db{ndb}.ref(18) = str2num(anew{3});
            ismp(18) = 1;
          elseif (strcmp(mp,"xyz"))
            db{ndb}.ref(19) = str2num(anew{3});
            ismp(19) = 1;
          elseif (strcmp(mp,"xxxx"))
            db{ndb}.ref(20) = str2num(anew{3});
            ismp(20) = 1;
          elseif (strcmp(mp,"yyyy"))
            db{ndb}.ref(21) = str2num(anew{3});
            ismp(21) = 1;
          elseif (strcmp(mp,"zzzz"))
            db{ndb}.ref(22) = str2num(anew{3});
            ismp(22) = 1;
          elseif (strcmp(mp,"xxxy"))
            db{ndb}.ref(23) = str2num(anew{3});
            ismp(23) = 1;
          elseif (strcmp(mp,"xxxz"))
            db{ndb}.ref(24) = str2num(anew{3});
            ismp(24) = 1;
          elseif (strcmp(mp,"yyyx"))
            db{ndb}.ref(25) = str2num(anew{3});
            ismp(25) = 1;
          elseif (strcmp(mp,"yyyz"))
            db{ndb}.ref(26) = str2num(anew{3});
            ismp(26) = 1;
          elseif (strcmp(mp,"zzzx"))
            db{ndb}.ref(27) = str2num(anew{3});
            ismp(27) = 1;
          elseif (strcmp(mp,"zzzy"))
            db{ndb}.ref(28) = str2num(anew{3});
            ismp(28) = 1;
          elseif (strcmp(mp,"xxyy"))
            db{ndb}.ref(29) = str2num(anew{3});
            ismp(29) = 1;
          elseif (strcmp(mp,"xxzz"))
            db{ndb}.ref(30) = str2num(anew{3});
            ismp(30) = 1;
          elseif (strcmp(mp,"yyzz"))
            db{ndb}.ref(31) = str2num(anew{3});
            ismp(31) = 1;
          elseif (strcmp(mp,"xxyz"))
            db{ndb}.ref(32) = str2num(anew{3});
            ismp(32) = 1;
          elseif (strcmp(mp,"yyxz"))
            db{ndb}.ref(33) = str2num(anew{3});
            ismp(33) = 1;
          elseif (strcmp(mp,"zzxy"))
            db{ndb}.ref(34) = str2num(anew{3});
            ismp(34) = 1;
          endif
        else
          db{ndb}.ref = str2num(anew{2});
        endif
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
          anew = strfields(line);
          keyw = lower(anew{1});
          rest = strrep(line,anew{1},"");

          if (length(line) == 0 || line(1:1) == "#")
            continue
          elseif(strcmp(tolower(keyw),"extragau"))
            db{ndb}.molc{im}.extragau = rest;
            continue
          elseif (strcmp(tolower(keyw),"end"))
            break
          endif
          [at x y z] = sscanf(line,"%s %f %f %f","C");
          n++;
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
          anew = strfields(line);
          keyw = lower(anew{1});
          rest = strrep(line,anew{1},"");

          if (length(line) == 0 || line(1:1) == "#")
            continue
          elseif(strcmp(tolower(keyw),"extragau"))
            db{ndb}.mol.extragau = rest;
            continue
          elseif (strcmp(tolower(keyw),"end"))
            break
          endif
          [at x y z] = sscanf(line,"%s %f %f %f","C");
          n++;
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
           anew = strfields(line);
           keyw = lower(anew{1});
           rest = strrep(line,anew{1},"");

           if (length(line) == 0 || line(1:1) == "#")
             continue
           elseif(strcmp(tolower(keyw),"extragau"))
             db{ndb}.mon1.extragau = rest;
             continue
           elseif (strcmp(tolower(keyw),"end"))
             break
           endif
           [at x y z] = sscanf(line,"%s %f %f %f","C");
           n++;
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
           anew = strfields(line);
           keyw = lower(anew{1});
           rest = strrep(line,anew{1},"");

           if (length(line) == 0 || line(1:1) == "#")
             continue
           elseif(strcmp(tolower(keyw),"extragau"))
             db{ndb}.mon2.extragau = rest;
             continue
           elseif (strcmp(tolower(keyw),"end"))
             break
           endif
           [at x y z] = sscanf(line,"%s %f %f %f","C");
           n++;
           db{ndb}.mon2.at{n} = at;
           db{ndb}.mon2.x(n,:) = [x y z];
        until (!ischar(line))
        db{ndb}.mon2.nat = n;
      endif
    endwhile

    ## Wrap up
    fclose(fid);

    ## post-process if this is a "multipoles" entry
    if (strcmp(db{ndb}.type,"multipoles"))
      eref = db{ndb}.ref;
      db0 = db{ndb};
      for j = 1:length(eref)
        if (ismp(j))
          db{ndb} = db0;
          db{ndb}.ref = eref(j);
          db{ndb}.reftype = j; ## save the component for later
          ndb++;
        endif
      endfor
      ndb--;
    endif

  endfor

  if (ferr > 0) 
    fprintf(ferr,"# End parsedb - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

end

