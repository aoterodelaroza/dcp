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

function writegjf(file,dcp,dcp0,basis,at,x,q,mult,ent,chk="",wfx="",derivs=0)
  %% function writegjf(file,dcp,dcp0,at,x,q,mult,ent,chk="");
  %%
  %% Write a Gaussian input file (gjf) in filename file. Use the DCP
  %% information contained in the dcp argument, the geometry in at
  %% (cell array of atomic symbols), x (array of atomic coordinates),
  %% q (charge), mult (multiplicity), and the method, basis, route
  %% section, etc. contained in the database entry ent.  chk is the
  %% (optional) checkpoint file. If derivs is not zero and positive,
  %% generate the gjfs for the derivatives calculation up to derivs
  %% order. If derivs is negative, prepare the inputs for
  %% theevaluation of the DCP terms. The dcp0 argument contains 
  %% DCP specifications for some atoms; derivatives are not taken wrt
  %% the coefficients in dcp0.
  
  ## Build the atom list
  atlist = {};
  for i = 1:length(at)
    if (!any(ismember(at{i},atlist)))
      atlist = {atlist{:}, at{i}};
    endif
  endfor

  ## Open the input file for writing
  fid = fopen(file,"w");
  if (fid <= 0) 
    error(sprintf("Could not open Gaussian input file for writing: %s",file));
  endif

  ## Checkpoint file bit
  if (length(chk) > 0 || derivs) 
    fprintf(fid,"%%chk=%s\n",chk);
    chkstr = "guess=(read,tcheck)";
  else
    chkstr = "";
  endif

  ## Wfx file bit
  if (length(wfx) > 0)
    wfxstr = "output=wfx";
  else
    wfxstr = "";
  endif
  
  ## Pseudo=read bit
  if (!isempty(dcp) || !isempty(dcp0))
    pseudostr = "pseudo=read";
  else
    pseudostr = "";
  endif

  ## Basis bit
  if (iscell(basis))
    basisstr = "gen";
  else
    basisstr = basis;
  endif

  ## Write the mem and proc
  fprintf(fid,"%%mem=%dGB\n",ent.mem);
  fprintf(fid,"%%nproc=%d\n",ent.ncpu);

  ## The route line
  fprintf(fid,"#p %s %s %s %s %s %s\n",ent.method,basisstr,pseudostr,ent.extragau,chkstr,wfxstr);

  ## Title and multiplicity
  fprintf(fid,"\n");
  fprintf(fid,"title\n");
  fprintf(fid,"\n");
  fprintf(fid,"%d %d\n",q,mult);

  ## Molecular geometry
  for i = 1:length(at)
    fprintf(fid,"%s %.10f %.10f %.10f\n",at{i},x(i,:));
  endfor
  fprintf(fid,"\n");
  
  ## Basis set (if gen)
  if (iscell(basis))
    writebasis(basis,fid,at);
    fprintf(fid,"\n");
  endif

  ## DCP block
  if (!isempty(dcp) || !isempty(dcp0))
    writedcp(dcp,fid,at);
    writedcp(dcp0,fid,at);
    fprintf(fid,"\n");
  endif

  ## Wfx block
  if (length(wfx) > 0)
    fprintf(fid,"%s\n",wfx);
    fprintf(fid,"\n");
  endif

  if (derivs)
    ## The same calculation without any DCP
    fprintf(fid,"--Link1--\n");
    fprintf(fid,"%%chk=%s\n",chk);
    fprintf(fid,"%%mem=%dGB\n",ent.mem);
    fprintf(fid,"%%nproc=%d\n",ent.ncpu);
    fprintf(fid,"#p %s %s %s\n",ent.method,basisstr,ent.extragau);
    fprintf(fid,"   scf=(maxcycle=1) guess=(read) geom=(check) iop(5/13=1,99/5=2,3/53=10)\n");
    fprintf(fid,"\n");
    fprintf(fid,"title\n");
    fprintf(fid,"\n");
    fprintf(fid,"%d %d\n",q,mult);
    fprintf(fid,"\n");
    if (iscell(basis))
      writebasis(basis,fid,at);
      fprintf(fid,"\n");
    endif

    ## Pack and count the number of DCP coefficients/exponents
    x0 = packdcp(dcp);
    n = length(x0) / 2;

    ## First derivatives wrt the coefficients/term evaluation
    for i = 1:n
      xtmp = x0;
      xtmp(2:2:2*n) = 0;
      if (derivs > 0)
        ## Calculation of the first derivatives
        xtmp(2*i) = 1;
      else
        ## Keep the original coefficient to evaluate this term
        xtmp(2*i) = x0(2*i);
      endif
      dcptmp = unpackdcp(xtmp,dcp);
      fprintf(fid,"--Link1--\n");
      fprintf(fid,"%%chk=%s\n",chk);
      fprintf(fid,"%%mem=%dGB\n",ent.mem);
      fprintf(fid,"%%nproc=%d\n",ent.ncpu);
      fprintf(fid,"#p %s %s %s\n",ent.method,basisstr,ent.extragau);
      fprintf(fid,"   pseudo=read scf=(maxcycle=1) guess=(read) geom=(check) iop(5/13=1,99/5=2,3/53=10)\n");
      fprintf(fid,"\n");
      fprintf(fid,"title\n");
      fprintf(fid,"\n");
      fprintf(fid,"%d %d\n",q,mult);
      fprintf(fid,"\n");
      if (iscell(basis))
        writebasis(basis,fid,at);
        fprintf(fid,"\n");
      endif
      writedcp(dcptmp,fid,at);
      writedcp(dcp0,fid,at);
      fprintf(fid,"\n");
    endfor
  endif
  fclose(fid);

endfunction
