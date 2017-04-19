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
global acp basis db prefix nstep ycur...
       acpfin costmin stime0 astep savetar ncpu mem...
       ferr

#### Modify this to change the input behavior ####

## Functional
method="blyp";

## Basis set or basis file or files. You can use a single string
## or a cell array. If you use a string, then the script will look
## for a file by that name. If the file does not exist, then the string
## will be assumed to be a Gaussian keyword and passed to the input
## If a file is found, it is parsed and the basis-set information read,
## then information for the relevant atoms passed to the inputs. 
## Several basis set files can be used (e.g. {"basis1","basis2"}).
basis="sto-3g";

## Extra bits for gaussian (do not include pseudo=read here)
extragau="SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=2;
mem=2;

## List of database files to use in ACP optimization
## [listdb weightdb] = training_set(1,1,1,1,1);
listdb = {
          "temp/bleh1.db",...
          "temp/bleh2.db",...
          "temp/bleh3.db",...
          "temp/bleh4.db",...
          "temp/bleh5.db",...
};

## List of ACP files to evaluate (you can use a cell array of files
## here, like {"C.acp","H.acp"}, or a single string "bleh.acp")
acpini={"empty.bsip"};

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the ACP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Save a compressed tar file with the inputs/outputs/wfxs?
## savetar="";
## savetar="tar";
## savetar="gz";
## savetar="bz2";
savetar="xz";

## To use XDM, put the damping function coefficients here.
## [a1 a2], with a2 in angstrom. xdmfun is the functional keyword
## passed to postg.
## xdmcoef = [0.7647 0.8457];
## xdmfun = "blyp";

## To use D3, put the arguments for the command line call to the
## dftd3 program here. 
## extrad3 = "-func hf -bj";

## Name of the error file (timing, debug, etc.)
errfile = "eval.err";

#### No touching past this point. ####

## Open error file
ferr = -1;
if (exist("errfile","var"))
  ferr = fopen(errfile,"w");
endif

## Header
printf("### ACP repacking started on %s ###\n",strtrim(ctime(time())));
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
db = parsedb(listdb);
db = filldb(db,[],method,extragau);

## Initialization
if (!iscell(acpini))
  acpini = {acpini};
endif

## Create the prefix directory if it doesn't exist yet
if (!exist(prefix,"dir"))
  [s out] = system(sprintf("mkdir %s",prefix));
  if (s != 0)
    error(sprintf("Could not create directory %s",prefix));
  endif
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
    fprintf(ferr,"# Setting up Gaussian input files - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  for i = 1:length(db)
    anew = setup_input_one(db{i},acp);
    ilist = {ilist{:}, anew{:}};
  endfor
  if (ferr > 0)
    fprintf(ferr,"# List of inputs has %d entries\n",length(ilist));
    fflush(ferr);
  endif

  ## Default values for XDM and D3, if applicable
  if (!exist("xdmcoef","var"))
    xdmcoef = [];
    xdmfun = "";
  endif
  if (!exist("extrad3","var"))
    extrad3 = "";
  endif
  if (!isempty(xdmcoef) && !isempty(extrad3))
    error("Can not run XDM and D3 at the same time")
  endif

  ## Unpack the results
  file = "";
  if (exist("savetar","var") && exist(sprintf("%s/%s_%4.4d.tar.%s",prefix,prefix,nstep,savetar),"file"))
    file = sprintf("%s/%s_%4.4d.tar.%s",prefix,prefix,nstep,savetar);
  else
    alist = {"xz","bz2","gz",""};
    for i = 1:length(alist)
      if (exist(sprintf("%s/%s_%4.4d.tar.%s",prefix,prefix,nstep,alist{i}),"file"))
        file = sprintf("%s/%s_%4.4d.tar.%s",prefix,prefix,nstep,alist{i});
        break
      endif
    endfor
  endif
  if (isempty(file))
    error("File not found for this ACP")
  endif
  [s out] = system(sprintf("cp -f %s .",file));
  if (s != 0)
    error(sprintf("Failed to copy file: %s",file))
  endif
  [s out] = system(sprintf("tar xf %s",file));
  if (s != 0)
    error(sprintf("Failed to uncompress file: %s",file))
  endif
  [s out] = system(sprintf("rm -f %s",file));

  ## Copy the results in the fail directory, if they exist
  if (exist(sprintf("%s_fail",prefix),"dir"))
    if (ferr > 0)
      fprintf(ferr,"# Copying the calculations from the fail directory - %s\n",strtrim(ctime(time())));
      fflush(ferr);
    endif
    [s out] = system(sprintf("cp -f %s_fail/%s_%4.4d_* .",prefix,prefix,nstep));
  endif

  ## Collect the results and compare to the reference data
  if (ferr > 0)
    fprintf(ferr,"# Collecting the results and calculating errors - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  dy = ycalc = yref = ycalcnd = zeros(length(db),1);
  for i = 1:length(db)
    [dy(i) ycalc(i) yref(i) xdum ycalcnd(i)] = process_output_one(db{i},xdmcoef,extrad3,0);
  endfor
  if (any(ycalc == Inf))
    mae = Inf;
    mape = Inf;
    rms = Inf;
    cost = Inf;
    wrms = Inf;
  else
    dyr = dy(find(dy != Inf));
    yrefr = yref(find(yref != Inf));
    mae = mean(abs(dyr));
    mape = mean(abs(dyr./yrefr))*100;
    rms = sqrt(mean(dyr.^2));
    if (exist("weightdb","var") && !isempty(weightdb))
      cost = sum(weightdb' .* dyr.^2);
      wrms = sqrt(sum(weightdb' .* dyr.^2));
    else
      cost = sum(dyr.^2);
      wrms = sqrt(mean(dyr.^2));
    endif
  endif

  ## Write the results at the minimum
  printf("# ACP %d (%s) | Cost = %.10f | wRMS = %.4f | MAE = %.4f | MAPE = %.4f | RMS = %.4f |\n",...
         iacp,acpini{iacp},cost,wrms,mae,mape,rms);
  
  if (isempty(xdmcoef) && isempty(extrad3))
    printf("| Id|           Name       |       yref   |      ycalc   |       dy     |\n");
    for i = 1:length(db)
      printf("| %d | %20s | %14.8f | %14.8f | %14.8f |\n",...
             i,db{i}.outname,yref(i),ycalc(i),dy(i));
    endfor
  else
    printf("| Id|           Name       |       yref   |      ycalc   |  ycalc(scf)  |       dy     |\n");
    for i = 1:length(db)
      printf("| %d | %20s | %14.8f | %14.8f | %14.8f | %14.8f |\n",...
             i,db{i}.outname,yref(i),ycalc(i),ycalcnd(i),dy(i));
    endfor
  endif
  printf("\n");

  ## Clean up
  stash_inputs_outputs([]);
endfor

## Close error file
if (ferr > 0)
  fprintf(ferr,"# Finished on %s\n",strtrim(ctime(time())));
  fflush(ferr);
endif
fclose(ferr);

## Termination
printf("### ACP repacking finished on %s ###\n",strtrim(ctime(time())));
