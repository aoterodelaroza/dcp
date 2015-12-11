#! /usr/bin/octave -q
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


format long
## global dcp basis db prefix nstep verbose run_inputs ycur dcpfin...
##        costmin iload stime0 astep dcpeval maxnorm fixnorm muk dcp0...
##        savetarbz2

#### Modify this to change the input behavior ####

## List of database files to use in DCP optimization
listdb={...
         "atz_blyp/s_tsoh_h2s_090.db","atz_blyp/s_tsoh_h2s_095.db","atz_blyp/s_tsoh_h2s_100.db","atz_blyp/s_tsoh_h2s_105.db",...
         "atz_blyp/s_tsoh_h2s_110.db","atz_blyp/s_tsoh_h2s_125.db","atz_blyp/s_tsoh_h2s_150.db","atz_blyp/s_tsoh_h2s_200.db",...
};

## print reference energies to the output
printref=1;
## printref="";

#### No touching past this point. ####

## Read the parametrization database and print the reference energies
db = parsedb(listdb);
db = filldb(db,[],"blyp","",1,4);

if (exist("printref","var") && !isempty(printref))
  printf("### Reference energies ###\n");
  printf("| Filename | Type | Reference |\n");
  for i = 1:length(db)
    printf("| %s | %s | %.5f |\n",db{i}.file,db{i}.type,db{i}.ref);
  endfor
endif
