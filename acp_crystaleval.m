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
global acp basis db prefix nstep run_inputs ycur...
       acpfin costmin stime0 astep savetar ncpu mem...
       ferr crysopt

#### Modify this to change the input behavior ####

## Functional (for now, only HF)
method="hf";

## Basis set or basis file or files. You can use a single string or a
## cell array. If you use a string, then the script will look for a
## file by that name. If a file is found, it is parsed and the
## basis-set information read, then information for the relevant atoms
## passed to the inputs.  Several basis set files can be used
## (e.g. {"basis1","basis2"}).
basis="minis.gbs";

## List of database files to use in ACP optimization
## [listdb weightdb] = training_set(1,1,1,1,1);
listdb = {
          "db_crys/x23_co2.db",...
};

## List of ACP files to evaluate (you can use a cell array of files
## here, like {"C.acp","H.acp"}, or a single string "bleh.acp")
acpini={"csp-20.acp"};

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the ACP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Name of the error file (timing, debug, etc.)
errfile = "eval.err";

## Additional options for the crystal calculations
crysopt = struct();
crysopt.toldee = 7;
crysopt.d3 = 1;
crysopt.opt = 1;
crysopt.opt_toldee = 7;
crysopt.opt_toldeg = 0.0003;
crysopt.opt_toldex = 0.0012;

#### No touching past this point. ####

## Open error file
ferr = -1;
if (exist("errfile","var"))
  ferr = fopen(errfile,"w");
endif

## Header
printf("### ACP evaluation (crystal version) started on %s ###\n",strtrim(ctime(time())));
printf("### PID: %d ###\n",getpid());
[s out] = system("hostname");
printf("### hostname: %s ###\n",strrep(out,"\n",""));
if (ferr > 0) 
  fprintf(ferr,"# Started on %s with PID %d (%s)\n",strtrim(ctime(time())),getpid(),strrep(out,"\n",""));
  fflush(ferr);
endif

## Read the basis set
basis = parsebasis(basis);

## Read the parametrization database 
db = parsedb(listdb,"");
db = filldb(db,[],method,"");

## Initialization
if (!iscell(acpini))
  acpini = {acpini};
endif

## Read and evaluate the ACPs one by one, prepare all input files
for iacp = 1:length(acpini)
  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start ACP %d (%s) - %s\n",iacp,acpini{iacp},strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Initialize
  ilist = {};
  acp = parseacp(acpini{iacp});
  nstep = iacp;

  ## Set up the Gaussian input files
  if (ferr > 0) 
    fprintf(ferr,"# Setting up input files - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Make the d12 inputs
  for i = 1:length(db)
    setup_input_one(db{i},acp);
  endfor
endfor

## Close error file
if (ferr > 0) 
  fprintf(ferr,"# Finished on %s\n",strtrim(ctime(time())));
  fflush(ferr);
endif
fclose(ferr);

## Termination
printf("### ACP evaluation (crystal version) finished on %s ###\n",strtrim(ctime(time())));
