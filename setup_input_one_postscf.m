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

function ilist = setup_input_one_postscf(ent,atoms,lchan,lexp,c0)
  %% function ilist = setup_input_one(ent,atoms,lchan,lexp,c0)
  %%
  %% Set up all the inputs necessary to perform the calculation
  %% indicated in database entry ent for the given ACP. Returns the
  %% list of input names (without the gjf) and writes those same
  %% inputs to the current working directory. In each input, a single
  %% SCF is run without any ACP, and a number of post-SCF calculations
  %% are performed using the converged wavefunction. The post-SCF
  %% calculations involve all atoms in atoms with maximum
  %% angular momentum channel lchan and all exponents in lexp.
  %% The post-SCF ACP terms are calculated using coefficient c0.

  global prefix nstep basis ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# setup_input_one_postscf (%s) - %s\n",ent.name,strtrim(ctime(time())));
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
      writegjf(file,{},{},basis,ent.molc{j}.at,ent.molc{j}.x,ent.molc{j}.q,ent.molc{j}.mult,ent,extragau,chk,wfx,0);
      writexyz(filexyz,ent.molc{j}.at,ent.molc{j}.x,ent.molc{j}.q,ent.molc{j}.mult);
      appendgjf(file,basis,ent.molc{j}.at,ent.molc{j}.q,ent.molc{j}.mult,ent,extragau,chk,atoms,lchan,lexp,c0);
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
    writegjf(file,{},{},basis,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult,ent,extragau,chk,wfx,0);
    writexyz(filexyz,ent.mol.at,ent.mol.x,ent.mol.q,ent.mol.mult);
    appendgjf(file,basis,ent.mol.at,ent.mol.q,ent.mol.mult,ent,extragau,chk,atoms,lchan,lexp,c0);
    ilist = {ilist{:}, sprintf("%s_%4.4d_%s_mol",prefix,nstep,ent.name)};

  elseif (strcmp(ent.type,"intramol_geometry") || strcmp(ent.type,"intermol_geometry"))
    error(sprintf("Geometries not implemented in setup_input_one_postscf"))

  elseif (strcmp(ent.type,"dipole"))
    error(sprintf("Dipoles not implemented in setup_input_one_postscf"))

  elseif (strcmp(ent.type,"multipoles"))
    error(sprintf("Multipoles not implemented in setup_input_one_postscf"))

  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
