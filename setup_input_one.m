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

  global prefix nstep basis dcp0 ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# setup_input_one (%s) - %s\n",ent.name,strtrim(ctime(time())));
    fflush(ferr);
  endif

  ilist = {};
  if (strcmp(ent.type,"reaction_frozen"))
    ## Write a gjf for every molecule
    for j = 1:ent.nmol
      chk = sprintf("%s_%4.4d_%s_mol%d.chk",prefix,nstep,ent.name,j);
      wfx = sprintf("%s_%4.4d_%s_mol%d.wfx",prefix,nstep,ent.name,j);
      file = sprintf("%s_%4.4d_%s_mol%d.gjf",prefix,nstep,ent.name,j);
      filexyz = sprintf("%s_%4.4d_%s_mol%d.xyz",prefix,nstep,ent.name,j);
      if (isfield(ent.molc{j},"extragau"))
        extragau = ent.molc{j}.extragau;
      else
        extragau = "";
      endif
      writegjf(file,dcp,dcp0,basis,ent.molc{j}.at,ent.molc{j}.x,ent.molc{j}.q,ent.molc{j}.mult,ent,extragau,chk,wfx,derivs);
      writexyz(filexyz,ent.molc{j}.at,ent.molc{j}.x,ent.molc{j}.q,ent.molc{j}.mult);
      ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol%d",prefix,nstep,ent.name,j)};
    endfor
  elseif (strcmp(ent.type,"total_energy"))
    ## A total energy calculation
    chk = sprintf("%s_%4.4d_%s_mol.chk",prefix,nstep,ent.name);
    wfx = sprintf("%s_%4.4d_%s_mol.wfx",prefix,nstep,ent.name);
    file = sprintf("%s_%4.4d_%s_mol.gjf",prefix,nstep,ent.name);
    filexyz = sprintf("%s_%4.4d_%s_mol.xyz",prefix,nstep,ent.name);
    if (isfield(ent.mol,"extragau"))
      extragau = ent.mol.extragau;
    else
      extragau = "";
    endif
    writegjf(file,dcp,dcp0,basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,extragau,chk,wfx,derivs);
    writexyz(filexyz,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult);
    ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};
  elseif (strcmp(ent.type,"intramol_geometry") || strcmp(ent.type,"intermol_geometry"))
    ## A geometry relaxation; append "opt" to extragau
    file = sprintf("%s_%4.4d_%s_mol.gjf",prefix,nstep,ent.name);
    filexyz = sprintf("%s_%4.4d_%s_mol.xyz",prefix,nstep,ent.name);
    ent.extragau = sprintf("%s opt=(nomicro)",ent.extragau);
    if (isfield(ent.mol,"extragau"))
      extragau = ent.mol.extragau;
    else
      extragau = "";
    endif
    writegjf(file,dcp,dcp0,basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,extragau,:,:,0);
    writexyz(filexyz,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult);
    ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};
  elseif (strcmp(ent.type,"dipole"))
    ## A dipole calculation
    file = sprintf("%s_%4.4d_%s_mol.gjf",prefix,nstep,ent.name);
    filexyz = sprintf("%s_%4.4d_%s_mol.xyz",prefix,nstep,ent.name);
    if (isfield(ent.mol,"extragau"))
      extragau = ent.mol.extragau;
    else
      extragau = "";
    endif
    writegjf(file,dcp,dcp0,basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,extragau,:,:,0);
    writexyz(filexyz,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult);
    ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};
  elseif (strcmp(ent.type,"multipoles"))
    ## A multipole calculation. They usually come in bunches, so if the input
    ## file already exists, skip it.
    file = sprintf("%s_%4.4d_%s_mol.gjf",prefix,nstep,ent.name);
    filexyz = sprintf("%s_%4.4d_%s_mol.xyz",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      if (isfield(ent.mol,"extragau"))
        extragau = ent.mol.extragau;
      else
        extragau = "";
      endif
      writegjf(file,dcp,dcp0,basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,extragau,:,:,0);
      writexyz(filexyz,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult);
      ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};
    endif
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
