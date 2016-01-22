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
global dcp basis db prefix nstep verbose run_inputs ycur...
       dcpfin costmin iload stime0 astep savetarbz2

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
basis="aug-cc-pvtz";

## Extra bits for gaussian (do not include pseudo=read here)
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";
extragau="SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files to use in DCP optimization
## [s out] = system("ls db/*.db");
## listdb = strfields(out);
listdb = {"atz_blyp/bde_p-p.db"};
weightdb=[];

## List of DCP files to evaluate (you can use a cell array of files
## here, like {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini={"empty.dcp"};

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Name of the Gaussian input runner routine
run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.
## run_inputs = @run_inputs_plonk; ## Submit inputs to a private queue, plonk version.
## run_inputs = @run_inputs_nint_trasgu; ## Submit inputs to a private queue on the NINT cluster.
## run_inputs = @run_inputs_elcap3; ## Submit inputs to elcap3.

## Save a compressed tar.bz2 with the inputs/outputs/wfxs?
## savetarbz2="";
savetarbz2=1;

## To use XDM, put the damping function coefficients here.
## [a1 a2], with a2 in angstrom. xdmfun is the functional keyword
## passed to postg.
## xdmcoef = [0.7647 0.8457];
## xdmfun = "blyp";

#### No touching past this point. ####

## Header
printf("### DCP evaluation started on %s ###\n",strtrim(ctime(time())));
printf("### PID: %d ###\n",getpid());
[s out] = system("hostname");
printf("### hostname: %s ###\n",strrep(out,"\n",""));

## Read the basis set
basis = parsebasis(basis);

## Read the parametrization database 
db = parsedb(listdb);
db = filldb(db,[],method,extragau,ncpu,mem);

## Initialization
verbose = 0;
if (!iscell(dcpini))
  dcpini = {dcpini};
endif

## Read and evaluate the DCPs one by one, prepare all input files
for idcp = 1:length(dcpini)
  ilist = {};
  dcp = parsedcp(dcpini{idcp});
  nstep = idcp;

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## Set up the Gaussian input files
  for i = 1:length(db)
    anew = setup_input_one(db{i},dcp);
    ilist = {ilist{:}, anew{:}};
  endfor

  ## Run all inputs
  if (!exist("xdmcoef","var") || isempty(xdmcoef))
    srun = run_inputs(ilist,1);
  else
    if (!exist("xdmfun","var") || isempty(xdmfun))
      xdmfun = method;
    endif
    srun = run_inputs(ilist,1,xdmcoef,xdmfun);
  endif

  ## Collect the results and compare to the reference data
  dy = ycalc = yref = ycalcnd = zeros(length(db),1);
  for i = 1:length(db)
    [dy(i) ycalc(i) yref(i) xdum ycalcnd(i)] = process_output_one(db{i},exist("xdmcoef","var") && !isempty(xdmcoef),0);
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
      wrms = sqrt(sum(weightdb' .* dyr.^2) / sum(weightdb));
    else
      cost = sum(dyr.^2);
      wrms = sqrt(mean(dyr.^2));
    endif
  endif

  ## Write the results at the minimum
  printf("# DCP %d (%s) | Cost = %.10f | wRMS = %.4f | MAE = %.4f | MAPE = %.4f | RMS = %.4f | Time = %.1f |\n",...
         idcp,dcpini{idcp},cost,wrms,mae,mape,rms,sum(iload));
  
  if (!exist("xdmcoef","var") || isempty(xdmcoef))
    printf("| Id|           Name       |       yref   |      ycalc   |       dy     |\n");
    for i = 1:length(db)
      printf("| %d | %20s | %12.4f | %12.4f | %12.4f |\n",...
             i,db{i}.name,yref(i),ycalc(i),dy(i));
    endfor
  else
    printf("| Id|           Name       |       yref   |      ycalc   |  ycalc(scf)  |       dy     |\n");
    for i = 1:length(db)
      printf("| %d | %20s | %12.4f | %12.4f | %12.4f | %12.4f |\n",...
             i,db{i}.name,yref(i),ycalc(i),ycalcnd(i),dy(i));
    endfor
  endif
  printf("\n");

  ## Clean up
  stash_inputs_outputs(ilist);
endfor

printf("### DCP evaluation finished on %s ###\n",strtrim(ctime(time())));
