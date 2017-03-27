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

function writedb(db,file="")
  %% function writedb(db,file="")
  %%
  %% Write the database to the stdout. If no file is given, write
  %% it to the stdout.
  
  ## Try to open the file for output. If that fails, dump the information
  ## to stdout and crash.
  fid = stdout();
  docrash = 0;
  if (length(file) > 0)
    fid = fopen(file,"w");
    if (fid < 0)
      printf("Error: could not open output file.\n");
      printf("Dumping ACP info RIGHT HERE!\n");
      fid = stdout();
      docrash = 1;
    endif
  endif

  for i = 1:length(db)
    fprintf(fid,"## Database entry number %d\n",i);
    ## file
    if (isfield(db{i},"file"))
      fprintf(fid,"## Read from file: %s\n",db{i}.file);
    endif
    ## name
    if (isfield(db{i},"name"))
      fprintf(fid,"name %s\n",db{i}.name);
    endif
    ## type
    if (isfield(db{i},"type"))
      fprintf(fid,"type %s\n",db{i}.type);
    endif
    ## ref
    if (isfield(db{i},"ref"))
      fprintf(fid,"ref %.10f\n",db{i}.ref);
    endif
    ## method
    if (isfield(db{i},"method"))
      fprintf(fid,"method %s\n",db{i}.method);
    endif
    ## extragau
    if (isfield(db{i},"extragau"))
      fprintf(fid,"extragau %s\n",db{i}.extragau);
    endif
    ## mol
    if (isfield(db{i},"mol"))
      fprintf(fid,"mol %d %d\n",db{i}.mol.q,db{i}.mol.mult);
      if (isfield(db{i}.mol,"extragau"))
        fprintf(fid,"extragau %s\n",db{i}.mol.extragau);
      endif
      for j = 1:db{i}.mol.nat
        fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mol.at{j},db{i}.mol.x(j,:));
      endfor
      fprintf(fid,"end\n");
    endif
    ## mon1
    if (isfield(db{i},"mon1"))
      if (db{i}.mon1.nat == 0)
        fprintf(fid,"mon1 void\n");
      else
        fprintf(fid,"mon1 %d %d\n",db{i}.mon1.q,db{i}.mon1.mult);
        if (isfield(db{i}.mon1,"extragau"))
          fprintf(fid,"extragau %s\n",db{i}.mon1.extragau);
        endif
        for j = 1:db{i}.mon1.nat
          fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mon1.at{j},db{i}.mon1.x(j,:));
        endfor
        fprintf(fid,"end\n");
      endif
    endif
    ## mon2
    if (isfield(db{i},"mon2"))
      if (db{i}.mon2.nat == 0) 
        fprintf(fid,"mon2 void");
      else
        fprintf(fid,"mon2 %d %d\n",db{i}.mon2.q,db{i}.mon2.mult); 
        if (isfield(db{i}.mon2,"extragau"))
          fprintf(fid,"extragau %s\n",db{i}.mon2.extragau);
        endif
        for j = 1:db{i}.mon2.nat
          fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mon2.at{j},db{i}.mon2.x(j,:));
        endfor
        fprintf(fid,"end\n");
      endif
    endif
    ## molc
    if (isfield(db{i},"molc"))
      for j = 1:length(db{i}.molc)
        fprintf(fid,"molc %.10f %d %d\n",db{i}.molc{j}.coef,db{i}.molc{j}.q,db{i}.molc{j}.mult);
        if (isfield(db{i}.molc{j},"extragau"))
          fprintf(fid,"extragau %s\n",db{i}.molc{j}.extragau);
        endif
        for k = 1:db{i}.molc{j}.nat
          fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.molc{j}.at{k},db{i}.molc{j}.x(k,:));
        endfor
        fprintf(fid,"end\n");
      endfor
    endif
  endfor

  ## Wrap up
  if (docrash)
    error(sprintf("Could not open file for final ACP output: %s",file));
  elseif (fid != stdout())
    fclose(fid);
  endif

end

