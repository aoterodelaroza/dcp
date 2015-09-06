function ilist = setup_input_one(ent,dcp,derivs=0)
  %% function ilist = setup_input_one(ent,dcp,derivs=0)
  %%
  %% Set up all the inputs necessary to perform the calculation
  %% indicated in database entry ent for the given DCP. Returns the
  %% list of input names (without the gjf) and writes those same
  %% inputs to the current working directory. If derivs is not zero
  %% and positive, generate the gjfs for the derivatives calculation
  %% up to derivs order. If derivs is negative, prepare the inputs for
  %% theevaluation of the DCP terms.

  global prefix nstep basis dcp0

  ilist = {};
  if (strcmp(ent.type,"be_frozen_monomer"))
    ## First the dimer
    chk = sprintf("%s_%4.4d_%s_mol.chk",prefix,nstep,ent.name);
    wfx = sprintf("%s_%4.4d_%s_mol.wfx",prefix,nstep,ent.name);
    file = sprintf("%s_%4.4d_%s_mol.gjf",prefix,nstep,ent.name);
    writegjf(file,dcp,dcp0,basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,chk,wfx,derivs);
    ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};

    ## Then the monomer 1
    if (ent.mon1.nat > 0)
      chk = sprintf("%s_%4.4d_%s_mon1.chk",prefix,nstep,ent.name);
      wfx = sprintf("%s_%4.4d_%s_mon1.wfx",prefix,nstep,ent.name);
      file = sprintf("%s_%4.4d_%s_mon1.gjf",prefix,nstep,ent.name);
      writegjf(file,dcp,dcp0,basis,ent.mon1.at,ent.mon1.x,ent.mon1.q,ent.mon1.mult,ent,chk,wfx,derivs);
      ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mon1",prefix,nstep,ent.name)};
    endif

    ## Then the monomer 2
    if (ent.mon2.nat > 0)
      chk = sprintf("%s_%4.4d_%s_mon2.chk",prefix,nstep,ent.name);
      wfx = sprintf("%s_%4.4d_%s_mon2.wfx",prefix,nstep,ent.name);
      file = sprintf("%s_%4.4d_%s_mon2.gjf",prefix,nstep,ent.name);
      writegjf(file,dcp,dcp0,basis,ent.mon2.at,ent.mon2.x,ent.mon2.q,ent.mon2.mult,ent,chk,wfx,derivs);
      ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mon2",prefix,nstep,ent.name)};
    endif
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
