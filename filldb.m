function db = filldb(db,weis=[],method=[],basis,extragau,ncpu,mem);
  %% function db = filldb(db,weis,method,basis,extragau,ncpu,mem);
  %% 
  %% Fill the missing information in the database with default values.
  %% If a non-optional parameter is missing from the database,
  %% stop the calculation. The input options are:
  %%
  %% weis: an array containing the weight of every reference calculation.
  %% method: functional string for Gaussian.
  %% basis: either the basis set string for Gaussian or the name of an external
  %%        input file to be used with the gen keyword.
  %% extragau: extra bits to use in Gaussian's route section.
  %% ncpu: number of CPUs for the calcs.
  %% mem: amount of memory (in GB) for the calcs.
  %%
  %% and only apply if the same fields were not found in the database.

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
      idx = index(db{i}.file,".");
      if (idx > 0) 
        db{i}.name = substr(db{i}.file,1,idx-1);
      endif
      idx = index(db{i}.name,"/","last");
      if (idx > 0) 
        db{i}.name = substr(db{i}.name,idx+1);
      endif
    endif

    ## Specific checks and fills for frozen monomer binding energy calculations
    if (strcmp(db{i}.type,"be_frozen_monomer"))
      ## Sanity checks for the frozen-monomer BE calculations
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
        error(sprintf("Entry %s has no dimer structure",db{i}.file))
      endif
      if (!isfield(db{i}.mon1,"nat") || db{i}.mon1.nat < 0)
        error(sprintf("Dimer in entry %s has no atoms",db{i}.file))
      endif
      if (db{i}.mon1.nat > 0)
        if (!isfield(db{i}.mon1,"q"))
          db{i}.mon1.q = 0;
        endif
        if (!isfield(db{i}.mon1,"mult"))
          db{i}.mon1.mult = 1;
        endif
        if (!isfield(db{i}.mon1,"at") || !isfield(db{i}.mon1,"x"))
          error(sprintf("Dimer in entry %s is not sane",db{i}.file))
        endif
      endif
      ## Monomer 2
      if (!isfield(db{i},"mon2"))
        error(sprintf("Entry %s has no dimer structure",db{i}.file))
      endif
      if (!isfield(db{i}.mon2,"nat") || db{i}.mon2.nat < 0)
        error(sprintf("Dimer in entry %s has no atoms",db{i}.file))
      endif
      if (db{i}.mon2.nat > 0) 
        if (!isfield(db{i}.mon2,"q"))
          db{i}.mon2.q = 0;
        endif
        if (!isfield(db{i}.mon2,"mult"))
          db{i}.mon2.mult = 1;
        endif
        if (!isfield(db{i}.mon2,"at") || !isfield(db{i}.mon2,"x"))
          error(sprintf("Dimer in entry %s is not sane",db{i}.file))
        endif
      endif
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
      if (!isfield(db{i},"basis"))
        if (isempty(basis))
          error(sprintf("No basis specified and no default available in entry %s",db{i}.file))
        endif
        db{i}.basis = basis;
      endif
      if (!isfield(db{i},"extragau"))
        if (isempty(extragau))
          db{i}.extragau = "";
        else
          db{i}.extragau = extragau;
        endif
      endif
      if (!isfield(db{i},"ncpu"))
        if (isempty(ncpu))
          error(sprintf("No ncpu specified and no default available in entry %s",db{i}.file))
        endif
        db{i}.ncpu = ncpu;
      endif
      if (!isfield(db{i},"mem"))
        if (isempty(mem))
          error(sprintf("No mem specified and no default available in entry %s",db{i}.file))
        endif
        db{i}.mem = mem;
      endif
    else
      ## I don't know what that type is
      error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
    endif
  endfor
  
endfunction

