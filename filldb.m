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

function db = filldb(db,weis=[],method=[],extragau);
  %% function db = filldb(db,weis,method,extragau);
  %% 
  %% Fill the missing information in the database with default values.
  %% If a non-optional parameter is missing from the database,
  %% stop the calculation. The input options are:
  %%
  %% weis: an array containing the weight of every reference calculation.
  %% method: functional string for Gaussian.
  %% extragau: extra bits to use in Gaussian's route section.
  %%
  %% and only apply if the same fields were not found in the database.

  global ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start filldb - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  mpoletr = {"x","y","z","xx","yy","zz","xy","xz","yz","xxx","yyy","zzz",...
             "xyy","xxy","xxz","xzz","yzz","yyz","xyz","xxxx","yyyy",...
             "zzzz","xxxy","xxxz","yyyx","yyyz","zzzx","zzzy","xxyy",...
             "xxzz","yyzz","xxyz","yyxz","zzxy"};
          
  ## Check that the weights are sane and normalize
  if (!isempty(weis))
    if (length(weis) != length(db))
      error(sprintf("Error in the length of the weight array (%d instead of %d)",...
                    length(weis),length(db)));
    endif
  else
    weis = ones(length(db),1);
  endif

  ## Run over all entries in the database
  for i = 1:length(db)
    ## Debug
    if (ferr > 0)
      fprintf(ferr,"# Db entry %d (%s) at %s\n",i,db{i}.file,strtrim(ctime(time())));
      fflush(ferr);
    endif

    ## Check that the entry is associated to a file
    if (!isfield(db{i},"file"))
      error(sprintf("Entry number %d has no associated file",i))
    endif
    ## Check that the type exists
    if (!isfield(db{i},"type"))
      error(sprintf("Entry for file %s has no type",db{i}.file))
    endif
    ## Check that the entry is associated to a file
    if (!isfield(db{i},"name"))
      idx = index(db{i}.file,".","last");
      if (idx > 0) 
        db{i}.name = substr(db{i}.file,1,idx-1);
      endif
      idx = index(db{i}.name,"/","last");
      if (idx > 0) 
        db{i}.name = substr(db{i}.name,idx+1);
      endif
    endif
    ## Output name is the same as name (see multipoles below)
    db{i}.outname = db{i}.name;

    ## Fill missing fields in the database with default values
    if (!isfield(db{i},"wei"))
      db{i}.wei = weis(i);
    endif
    if (!isfield(db{i},"method"))
      if (isempty(method))
        error(sprintf("No method specified and no default available in entry %s",db{i}.file))
      endif
      db{i}.method = method;
    endif
    if (!isfield(db{i},"extragau"))
      if (isempty(extragau))
        db{i}.extragau = "";
      else
        db{i}.extragau = extragau;
      endif
    else
      if (!isempty(extragau))
        db{i}.extragau = sprintf("%s %s",db{i}.extragau,extragau);
      endif
    endif
  
    ## Specific checks and fills for frozen monomer binding energy calculations
    ## and intermolecular geometries.
    if (strcmp(db{i}.type,"intermol_geometry") )
      ## Fill charge and multiplicity with default values
      if (!isfield(db{i},"ref"))
        error(sprintf("Entry %s has no reference energy",db{i}.file))
      endif
      if (!isfield(db{i},"mol"))
        error(sprintf("Entry %s has no dimer structure",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"q"))
        db{i}.mol.q = 0;
      endif
      if (!isfield(db{i}.mol,"mult"))
        db{i}.mol.mult = 1;
      endif
      if (!isfield(db{i}.mol,"nat") || db{i}.mol.nat <= 0)
        error(sprintf("Dimer in entry %s has no atoms",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"at") || !isfield(db{i}.mol,"x"))
        error(sprintf("Dimer in entry %s is not sane",db{i}.file))
      endif
      ## Monomer 1
      if (!isfield(db{i},"mon1"))
        error(sprintf("Entry %s has no monomer 1 structure",db{i}.file))
      endif
      if (!isfield(db{i}.mon1,"nat") || db{i}.mon1.nat < 0)
        error(sprintf("Monomer 1 in entry %s has no atoms",db{i}.file))
      endif
      if (db{i}.mon1.nat > 0)
        if (!isfield(db{i}.mon1,"q"))
          db{i}.mon1.q = 0;
        endif
        if (!isfield(db{i}.mon1,"mult"))
          db{i}.mon1.mult = 1;
        endif
        if (!isfield(db{i}.mon1,"at") || !isfield(db{i}.mon1,"x"))
          error(sprintf("Monomer 1 in entry %s is not sane",db{i}.file))
        endif
      endif
      ## Monomer 2
      if (!isfield(db{i},"mon2"))
        error(sprintf("Entry %s has no monomer 2 structure",db{i}.file))
      endif
      if (!isfield(db{i}.mon2,"nat") || db{i}.mon2.nat < 0)
        error(sprintf("Monomer 2 in entry %s has no atoms",db{i}.file))
      endif
      if (db{i}.mon2.nat > 0) 
        if (!isfield(db{i}.mon2,"q"))
          db{i}.mon2.q = 0;
        endif
        if (!isfield(db{i}.mon2,"mult"))
          db{i}.mon2.mult = 1;
        endif
        if (!isfield(db{i}.mon2,"at") || !isfield(db{i}.mon2,"x"))
          error(sprintf("Monomer 2 in entry %s is not sane",db{i}.file))
        endif
      endif
    elseif (strcmp(db{i}.type,"reaction_frozen"))
      ## Fill charge and multiplicity with default values
      if (!isfield(db{i},"ref"))
        error(sprintf("Entry %s has no reference energy",db{i}.file))
      endif
      if (!isfield(db{i},"molc") || !isfield(db{i},"nmol"))
        error(sprintf("Entry %s has no molecules",db{i}.file))
      endif
      for j = 1:db{i}.nmol
        if (!isfield(db{i}.molc{j},"q"))
          db{i}.molc{j}.q = 0;
        endif
        if (!isfield(db{i}.molc{j},"mult"))
          db{i}.molc{j}.mult = 1;
        endif
        if (!isfield(db{i}.molc{j},"nat") || db{i}.molc{j}.nat <= 0)
          error(sprintf("Dimer in entry %s has no atoms",db{i}.file))
        endif
        if (!isfield(db{i}.molc{j},"at") || !isfield(db{i}.molc{j},"x"))
          error(sprintf("Dimer in entry %s is not sane",db{i}.file))
        endif
      endfor
    elseif (strcmp(db{i}.type,"intramol_geometry") || strcmp(db{i}.type,"total_energy") || strcmp(db{i}.type,"dipole"))
      ## Sanity checks for the intramolecular geometry/total energy/dipole calculations
      if (!isfield(db{i},"mol"))
        error(sprintf("Entry %s has no molecular structure",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"q"))
        db{i}.mol.q = 0;
      endif
      if (!isfield(db{i}.mol,"mult"))
        db{i}.mol.mult = 1;
      endif
      if (!isfield(db{i}.mol,"nat") || db{i}.mol.nat <= 0)
        error(sprintf("Molecule entry %s has no atoms",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"at") || !isfield(db{i}.mol,"x"))
        error(sprintf("Molecule entry %s is not sane",db{i}.file))
      endif
    elseif (strcmp(db{i}.type,"crystal_energy"))
      if (isfield(db{i},"crys"))
        if (!isfield(db{i}.crys,"nat") || db{i}.crys.nat <= 0)
          error(sprintf("Crystal entry %s has no atoms",db{i}.file))
        endif
        if (!isfield(db{i}.crys,"at") || !isfield(db{i}.crys,"x"))
          error(sprintf("Crystal entry %s is not sane",db{i}.file))
        endif
        if (!isfield(db{i},"kpts"))
          error(sprintf("Crystal needs k-points",db{i}.file))
        endif
      elseif (isfield(db{i},"mol"))
        if (!isfield(db{i},"mol"))
          error(sprintf("Entry %s has no molecular structure",db{i}.file))
        endif
        if (!isfield(db{i}.mol,"q"))
          db{i}.mol.q = 0;
        endif
        if (!isfield(db{i}.mol,"mult"))
          db{i}.mol.mult = 1;
        endif
        if (!isfield(db{i}.mol,"nat") || db{i}.mol.nat <= 0)
          error(sprintf("Molecule entry %s has no atoms",db{i}.file))
        endif
        if (!isfield(db{i}.mol,"at") || !isfield(db{i}.mol,"x"))
          error(sprintf("Molecule entry %s is not sane",db{i}.file))
        endif
      else
          error(sprintf("crystal_energy type must have either crys or mol"));
      endif
    elseif (strcmp(db{i}.type,"multipoles"))
      ## Sanity checks for the multipole calculations
      if (!isfield(db{i},"mol"))
        error(sprintf("Entry %s has no molecular structure",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"q"))
        db{i}.mol.q = 0;
      endif
      if (!isfield(db{i}.mol,"mult"))
        db{i}.mol.mult = 1;
      endif
      if (!isfield(db{i}.mol,"nat") || db{i}.mol.nat <= 0)
        error(sprintf("Molecule entry %s has no atoms",db{i}.file))
      endif
      if (!isfield(db{i}.mol,"at") || !isfield(db{i}.mol,"x"))
        error(sprintf("Molecule entry %s is not sane",db{i}.file))
      endif
      if (!isfield(db{i},"reftype"))
        error(sprintf("multipole/reftype entry in %s is missing",db{i}.file))
      endif

      ## Include the multipole type in the name 
      db{i}.outname = sprintf("%s (%s)",db{i}.name,mpoletr{db{i}.reftype});
      
    else
      ## I don't know what that type is
      error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
    endif
  endfor

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# End filldb - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

endfunction

