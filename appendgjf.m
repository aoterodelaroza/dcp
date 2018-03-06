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

function appendgjf(file,basis,at,q,mult,ent,extragau="",chk="",atoms,lchan,lexp,c0,onlyonel)
  %% function appendgjf(file,basis,at,q,mult,ent,extragau="",chk="",atoms,lchan,lexp,c0,onlyonel)
  %%
  %% Append to a Gaussian input file (gjf) with filename file. For
  %% each combination of atom (atoms), angular momentum channel
  %% (maximum l in lchan) and exponent (lexp), add a Link1 to the end
  %% of the gjf file.  The geometry and guess is read from the
  %% checkpoint file (chk).  The basis set (basis), atom list (at),
  %% charge (q), multiplicity (mult), method (ent.method), extra
  %% keywords (ent.extragau and extragau) are read from the arguments.
  %% onlyonel: calculate only lchan, and not up to lchan.
  
  global ncpu mem

  llabel = {"l","s","p","d"};
  l2num = struct();
  l2num.l = 1;
  l2num.s = 2;
  l2num.p = 3;
  l2num.d = 4;

  ## Open the input file for appending
  fid = fopen(file,"a");
  if (fid <= 0) 
    error(sprintf("Could not open Gaussian input file for appending: %s",file));
  endif

  for iatom = 1:length(atoms)
    if (!isfield(l2num,lower(lchan{iatom})))
      error(sprintf("Unknown angular momentum channel: %s",lchan{iatom}));
    else
      lmax = getfield(l2num,(lower(lchan{iatom})));
    endif
    if (onlyonel) 
      lini = lmax;
    else
      lini = 1;
    endif
    for il = lini:lmax
      for iexp = 1:length(lexp)

        ## Link1
        fprintf(fid,"--Link1--\n");

        ## Checkpoint file bit
        if (length(chk) > 0 || derivs) 
          fprintf(fid,"%%chk=%s\n",chk);
          chkstr = "geom=check guess=(read,tcheck)";
        else
          error("No checkpoint file passed to appendgjf")
        endif

        ## Basis set bit
        if (iscell(basis))
          basisstr = "gen";
        else
          basisstr = basis;
        endif

        ## Write the mem and proc
        fprintf(fid,"%%mem=%dGB\n",mem);
        fprintf(fid,"%%nproc=%d\n",ncpu);

        ## The route line
        fprintf(fid,"#t %s %s iop(5/13=1,5/36=2,99/5=2) pseudo=read %s %s %s scf=(maxcycle=1)\n",...
                ent.method,basisstr,extragau,chkstr);

        ## Title and multiplicity
        fprintf(fid,"\n");
        fprintf(fid,"title\n");
        fprintf(fid,"\n");
        fprintf(fid,"%d %d\n",q,mult);
        fprintf(fid,"\n");

        ## Basis set (if gen)
        if (iscell(basis))
          writebasis(basis,fid,at);
          fprintf(fid,"\n");
        endif

        ## ACP block
        acp = makeacp(atoms{iatom},llabel{il},lexp(iexp),c0);
        writeacp(acp,fid);
        fprintf(fid,"\n");
      endfor
    endfor
  endfor
  fclose(fid);

endfunction
