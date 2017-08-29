#! /usr/bin/octave -q
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


format long

#### Modify this to change the input behavior ####

## List of database files to use in ACP optimization
listdb = {...
           "db/s668_Water-Pyridine_090.db",...
           "db/s668_Water-Pyridine_095.db",...
           "db/s668_Water-Pyridine_100.db",...
           "db/s668_Water-Pyridine_105.db",...
           "db/s668_Water-Pyridine_110.db",...
           "db/s668_Water-Pyridine_125.db",...
           "db/s668_Water-Pyridine_150.db",...
           "db/s668_Water-Pyridine_200.db",...
};

## Use this keyword to select a particular reference energy. Empty
## usually means high-level reference data. Other options are, for 
## instance, blyp/aqz or lcwpbe/atz.
reftype="";

## print reference energies to the output
printref=1;
## printref="";

## print reference energies to the output
printxyz={"mol","mon1","mon2"};
## printxyz={"mol"};
## printxyz={};

#### No touching past this point. ####

## Read the parametrization database and print the reference energies
db = parsedb(listdb,reftype);
db = filldb(db,[],"blyp","",1,4);

## print the reference energies
if (exist("printref","var") && !isempty(printref))
  printf("### Reference energies ###\n");
  printf("| N | Filename | Type | Reference |\n");
  for i = 1:length(db)
    printf("| %d | %s | %s | %.5f |\n",i,db{i}.file,db{i}.type,db{i}.ref);
  endfor
endif

## write the xyz files
if (exist("printxyz","var") && !isempty(printxyz))
  for i = 1:length(db)
    if (ismember("mol",printxyz) && isfield(db{i},"mol") && isfield(db{i}.mol,"nat") && db{i}.mol.nat > 0)
      fid = fopen(sprintf("%s_mol.xyz",db{i}.name),"w");
      nat = db{i}.mol.nat;
      fprintf(fid,"%d\n\n",nat);
      for j = 1:nat
        fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mol.at{j},db{i}.mol.x(j,:));
      endfor
      fclose(fid);
    endif
    if (ismember("mon1",printxyz) && isfield(db{i},"mon1") && isfield(db{i}.mon1,"nat") && db{i}.mon1.nat > 0)
      fid = fopen(sprintf("%s_mon1.xyz",db{i}.name),"w");
      nat = db{i}.mon1.nat;
      fprintf(fid,"%d\n\n",nat);
      for j = 1:nat
        fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mon1.at{j},db{i}.mon1.x(j,:));
      endfor
      fclose(fid);
    endif
    if (ismember("mon2",printxyz) && isfield(db{i},"mon2") && isfield(db{i}.mon2,"nat") && db{i}.mon2.nat > 0)
      fid = fopen(sprintf("%s_mon2.xyz",db{i}.name),"w");
      nat = db{i}.mon2.nat;
      fprintf(fid,"%d\n\n",nat);
      for j = 1:nat
        fprintf(fid,"%s %.10f %.10f %.10f\n",db{i}.mon2.at{j},db{i}.mon2.x(j,:));
      endfor
      fclose(fid);
    endif
  endfor
endif

