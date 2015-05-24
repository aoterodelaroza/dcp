function writegjf(file,dcp,basis,at,x,q,mult,ent,chk="");
  %% function writegjf(file,dcp,at,x,q,mult,ent,chk="");
  %%
  %% Write a Gaussian input file (gjf) in filename file. Use the 
  %% DCP information contained in the dcp argument, the geometry
  %% in at (cell array of atomic symbols), x (array of atomic
  %% coordinates), q (charge), mult (multiplicity), and the method,
  %% basis, route section, etc. contained in the database entry ent. 
  %% chk is the (optional) checkpoint file.
  
  atlist = {};
  for i = 1:length(at)
    if (!any(ismember(at{i},atlist)))
      atlist = [atlist, at{i}];
    endif
  endfor

  fid = fopen(file,"w");
  if (fid <= 0) 
    error(sprintf("Could not open Gaussian input file for writing: %s",file));
  endif
  if (length(chk) > 0) 
    fprintf(fid,"%%chk=%s\n",chk);
    chkstr = "guess=(read,tcheck)";
  else
    chkstr = "";
  endif
  fprintf(fid,"%%mem=%dGB\n",ent.mem);
  fprintf(fid,"%%nproc=%d\n",ent.ncpu);
  if (iscell(basis))
    fprintf(fid,"#p %s gen pseudo=read %s %s\n",ent.method,ent.extragau,chkstr);
  else
    fprintf(fid,"#p %s %s pseudo=read %s %s\n",ent.method,basis,ent.extragau,chkstr);
  endif
  fprintf(fid,"\n");
  fprintf(fid,"title\n");
  fprintf(fid,"\n");
  fprintf(fid,"%d %d\n",q,mult);
  for i = 1:length(at)
    fprintf(fid,"%s %.10f %.10f %.10f\n",at{i},x(i,:));
  endfor
  fprintf(fid,"\n");
  if (iscell(basis))
    writebasis(basis,fid,at);
    fprintf(fid,"\n");
  endif
  writedcp(dcp,fid,at);
  fprintf(fid,"\n");

  fclose(fid);

endfunction
