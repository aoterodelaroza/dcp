function writegjf(file,dcp,at,x,q,mult,ent);
  %% function writegjf(file,dcp,at,x,q,mult,ent);
  %%
  %% Write a Gaussian input file (gjf) in filename file. Use the 
  %% DCP information contained in the dcp argument, the geometry
  %% in at (cell array of atomic symbols), x (array of atomic
  %% coordinates), q (charge), mult (multiplicity), and the method,
  %% basis, route section, etc. contained in the database entry ent. 
  
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
  fprintf(fid,"%%mem=%dGB\n",ent.mem);
  fprintf(fid,"%%nproc=%d\n",ent.ncpu);
  fprintf(fid,"#p %s gen pseudo=read %s\n",ent.method,ent.extragau);
  fprintf(fid,"\n");
  fprintf(fid,"title\n");
  fprintf(fid,"\n");
  fprintf(fid,"%d %d\n",q,mult);
  for i = 1:length(at)
    fprintf(fid,"%s %.10f %.10f %.10f\n",at{i},x(i,:));
  endfor
  fprintf(fid,"\n");
  for i = 1:length(atlist)
    fprintf(fid,"%s ",atlist{i});
  endfor
  fprintf(fid,"0\n");
  fprintf(fid,"%s\n",ent.basis);
  fprintf(fid,"****\n");
  fprintf(fid,"\n");
  writedcp(dcp,fid,at);
  fprintf(fid,"\n");

  fclose(fid);

endfunction
