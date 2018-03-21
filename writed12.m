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

function writed12(file,acp,basis,ent)
  %% function writed12(file,acp,basis,ent,crysopt)
  %%
  
  global crysopt

  if (!exist("crysopt","var") || isempty(crysopt))
    crysopt_ = struct();
  else
    crysopt_ = crysopt;
  endif

  [symb Z] = getsymbols();

  ## Check which atoms are available in the ACP
  zused = zacp = zeros(1,103);
  for i = 1:length(acp)
    zacp(getfield(Z,toupper(acp{i}.atom))) = i;
  endfor

  ## Open the input file for writing
  fid = fopen(file,"w");
  if (fid <= 0) 
    error(sprintf("Could not open Gaussian input file for writing: %s",file));
  endif

  if (isfield(ent,"crys"))
    fprintf(fid,"Title\n");
    fprintf(fid,"CRYSTAL\n");
    fprintf(fid,"0 0 0\n");
    fprintf(fid,"1\n");
    fprintf(fid,"%.10f %.10f %.10f %.10f %.10f %.10f\n",ent.crys.aa,ent.crys.bb);
    fprintf(fid,"%d\n",ent.crys.nat);
    for i = 1:ent.crys.nat
      iz = getfield(Z,toupper(ent.crys.at{i}));
      
      found = 0;
      for j = 1:length(basis)
        if (strcmpi(basis{j}.atom,ent.crys.at{i}))
          found = j;
          break
        endif
      endfor
      if (!found)
        ent
        error("Atom not found in basis")
      endif

      zused(iz) = found;
      if (zacp(iz))
        iz = iz + 200;
      endif
      fprintf(fid,"%d %.10f %.10f %.10f\n",iz,ent.crys.x(i,:));
    endfor
  else
    fprintf(fid,"Title\n");
    fprintf(fid,"MOLECULE\n");
    fprintf(fid,"1\n");
    fprintf(fid,"%d\n",ent.mol.nat);
    for i = 1:ent.mol.nat
      iz = getfield(Z,toupper(ent.mol.at{i}));
      
      found = 0;
      for j = 1:length(basis)
        if (strcmpi(basis{j}.atom,ent.mol.at{i}))
          found = j;
          break
        endif
      endfor
      if (!found)
        ent
        error("Atom not found in basis")
      endif

      zused(iz) = found;
      if (zacp(iz))
        iz = iz + 200;
      endif
      fprintf(fid,"%d %.10f %.10f %.10f\n",iz,ent.mol.x(i,:));
    endfor
  endif

  fprintf(fid,"SETPRINT\n");
  fprintf(fid,"1\n");
  fprintf(fid,"72 1\n");

  if (isfield(crysopt,"opt"))
    fprintf(fid,"OPTGEOM\n");
    fprintf(fid,"FULLOPTG\n");
    if (isfield(crysopt,"opt_toldee"))
      fprintf(fid,"TOLDEE\n");
      fprintf(fid,"%d\n",crysopt.opt_toldee);
    endif
    if (isfield(crysopt,"opt_toldeg"))
      fprintf(fid,"TOLDEG\n");
      fprintf(fid,"%.10f\n",crysopt.opt_toldeg);
    endif
    if (isfield(crysopt,"opt_toldex"))
      fprintf(fid,"TOLDEX\n");
      fprintf(fid,"%.10f\n",crysopt.opt_toldex);
    endif
    fprintf(fid,"ENDOPT\n");
  endif
  fprintf(fid,"END\n");

  for iz = 1:length(zused)
    if (!zused(iz))
      continue
    endif
    bas = basis{zused(iz)};

    nelec = iz;
    if (zacp(iz))
      izo = iz + 200;
    else
      izo = iz;
    endif
    fprintf(fid,"%d %d\n",izo,bas.nblock);

    if (zacp(iz))
      ac = acp{zacp(iz)};

      nterm = zeros(1,6);
      ccoef = eexp = zeros(10,6);
      for l = 1:ac.nblock
        if (strcmpi(ac.block{l}.name,"l") || strcmpi(ac.block{l}.name,"local"))
          il = 1;
        elseif (strcmpi(ac.block{l}.name,"s"))
          il = 2;
        elseif (strcmpi(ac.block{l}.name,"p"))
          il = 3;
        elseif (strcmpi(ac.block{l}.name,"d"))
          il = 4;
        elseif (strcmpi(ac.block{l}.name,"f"))
          il = 5;
        elseif (strcmpi(ac.block{l}.name,"g"))
          il = 6;
        endif
        for m = 1:ac.block{l}.nterm
          nterm(il) = nterm(il) + 1;
          ccoef(nterm(il),il) = ac.block{l}.coef(m);
          eexp(nterm(il),il) = ac.block{l}.exp(m);
        endfor
      endfor

      fprintf(fid,"INPUT\n");
      fprintf(fid,"%d. %d %d %d %d %d %d\n",iz,nterm);
      for k = 1:6
        for l = 1:nterm(k)
          fprintf(fid,"%.10f %.10f 0\n",eexp(l,k),ccoef(l,k));
        endfor
      endfor
    endif

    for i  = 1:bas.nblock
      bl = bas.block{i};
      if (strcmpi(bl.type,"s"))
        itype = 0;
        nuse = min(nelec,2);
        nelec = nelec - nuse;
      elseif (strcmpi(bl.type,"sp"))
        itype = 1;
        nuse = min(nelec,8);
        nelec = nelec - nuse;
      elseif (strcmpi(bl.type,"p"))
        itype = 2;
        nuse = min(nelec,6);
        nelec = nelec - nuse;
      elseif (strcmpi(bl.type,"d"))
        itype = 3;
        nuse = min(nelec,10);
        nelec = nelec - nuse;
      elseif (strcmpi(bl.type,"f"))
        itype = 4;
        nuse = min(nelec,14);
        nelec = nelec - nuse;
      endif
      fprintf(fid,"0 %d %d %d. 0.\n",itype,bl.nprim,nuse);
      for j = 1:bl.nprim
        if (itype != 1)
          fprintf(fid,"%.10f %.10f\n",bl.exp(j),bl.coef1(j));
        else
          fprintf(fid,"%.10f %.10f %.10f\n",bl.exp(j),bl.coef1(j),bl.coef2(j));
        endif
      endfor
    endfor
  endfor
  fprintf(fid,"99 0\n");
  fprintf(fid,"END\n");

  if (isfield(crysopt,"d3"))
    fprintf(fid,"DFTD3\n");
    fprintf(fid,"VERSION\n");
    fprintf(fid,"4\n");
    fprintf(fid,"END\n");
  endif
  if (isfield(ent,"crys"))
    fprintf(fid,"SHRINK\n");
    fprintf(fid,"%d %d\n",ent.kpts,ent.kpts);
  endif
  if (isfield(crysopt,"toldee"))
    fprintf(fid,"TOLDEE\n");
    fprintf(fid,"%d\n",crysopt.toldee);
  endif
  fprintf(fid,"END\n");
  fclose(fid);

endfunction

function [symb Z] = getsymbols()
  symb = {...
           "H" , "HE", "LI", "BE", "B" , "C" , "N" , "O" , "F" , "NE", ...
           "NA", "MG", "AL", "SI", "P" , "S" , "CL", "AR", "K" , "CA", ...
           "SC", "TI", "V" , "CR", "MN", "FE", "CO", "NI", "CU", "ZN", ...
           "GA", "GE", "AS", "SE", "BR", "KR", "RB", "SR", "Y" , "ZR", ...
           "NB", "MO", "TC", "RU", "RH", "PD", "AG", "CD", "IN", "SN", ...
           "SB", "TE", "I" , "XE", "CS", "BA", "LA", "CE", "PR", "ND", ...
           "PM", "SM", "EU", "GD", "TB", "DY", "HO", "ER", "TM", "YB", ...
           "LU", "HF", "TA", "W" , "RE", "OS", "IR", "PT", "AU", "HG", ...
           "TL", "PB", "BI", "PO", "AT", "RN", "FR", "RA", "AC", "TH", ...
           "PA", "U" , "NP", "PU", "AM", "CM", "BK", "CF", "ES", "FM", ...
           "MD", "NO", "LR", ...
         };
  Z = struct();
  for i = 1:length(symb)
    Z = setfield(Z,symb{i},i);
  endfor
endfunction
