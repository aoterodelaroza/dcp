#! /usr/bin/octave -q
% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
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
       dcpfin costmin iload stime0 astep 

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
basis="basis.ini";

## Extra bits for gaussian (do not include pseudo=read here)
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";
extragau="SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=6;
mem=2;

## List of database files to use in the DCP evaluation
listdb={...
        "db/bde_c-h.db","db/bde_ch-h.db","db/bde_ch2-h.db","db/bde_ch3-ch3.db","db/bde_c2h5-h.db",... ## bdes
        "db/bde_cyclobutene-perits.db","db/bde_cyclopentadiene-perits.db","db/bde_darc-ethine-butadiene.db","db/bde_dim-13cyclopentadiene.db",... ## bdes
        "db/pes_c2h6-35.db","db/pes_c2h6-39.db","db/pes_c2h6-41.db","db/pes_c2h6-43.db","db/pes_c2h6-50.db","db/pes_c2h6-100.db",... ## c2h6
        "db/pes_c3h8-40.db","db/pes_c3h8-42.db","db/pes_c3h8-44.db","db/pes_c3h8-46.db","db/pes_c3h8-60.db","db/pes_c3h8-100.db",... ## c3h8
        "db/pes_c6h6s-09.db","db/pes_c6h6s-10.db","db/pes_c6h6s-12.db","db/pes_c6h6s-15.db","db/pes_c6h6s-20.db",... ## c6h6s
        "db/pes_c6h6t-09.db","db/pes_c6h6t-10.db","db/pes_c6h6t-12.db","db/pes_c6h6t-15.db","db/pes_c6h6t-20.db",... ## c6h6t
        "db/pes_ch4c-375.db","db/pes_ch4c-385.db","db/pes_ch4c-410.db","db/pes_ch4c-450.db","db/pes_ch4c-500.db","db/pes_ch4c-1000.db",... ## ch4c
        "db/pes_ch4g-325.db","db/pes_ch4g-350.db","db/pes_ch4g-365.db","db/pes_ch4g-425.db","db/pes_ch4g-500.db","db/pes_ch4g-1000.db",... ## ch4g
        };

## List of DCP files to evaluate (you can use a cell array of files
## here, like {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini="dcp.ini";

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Name of the Gaussian input runner routine
## run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.
## run_inputs = @run_inputs_plonk; ## Submit inputs to a private queue, plonk version.
## run_inputs = @run_inputs_nint_trasgu; ## Submit inputs to a private queue on the NINT cluster.
run_inputs = @run_inputs_elcap3; ## Submit inputs to elcap3.

#### No touching past this point. ####

## Header
printf("### DCP terms started on %s ###\n",strtrim(ctime(time())));
printf("### PID: %d ###\n",getpid());

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
ilist = {};
for idcp = 1:length(dcpini)
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
    anew = setup_input_one(db{i},dcp,-1);
    ilist = {ilist{:}, anew{:}};
  endfor
endfor

## Run all inputs
srun = run_inputs(ilist,1);

## Collect the results and compare to the reference data
for idcp = 1:length(dcpini)
  printf("## DCP = %s\n",dcpini{idcp});
  ymean = [];
  yamean = [];
  yade = zeros(length(db),1);
  for i = 1:length(db)
    [dy ycalc yref ay] = process_output_one(db{i},0,-1);
    yade(i) = process_output_one_echange(db{i});
    if (isempty(ymean))
         ymean = zeros(size(ay(:)));
         yamean = zeros(size(abs(ay(:))));
    endif
    yamean = yamean + abs(ay(:));
    ymean = ymean + ay(:);
  endfor
  yamean = yamean / length(db);
  ymean = ymean / length(db);

  dcp = parsedcp(dcpini{idcp});
  n = 0;
  printf("## DCP average total contributions per channel (kcal/mol) \n");
  printf("| term | at | channel | exponent | coefficient | sign | abs |\n");
  for i = 1:length(dcp)
    at = dcp{i}.atom;
    for j = 1:dcp{i}.nblock
      name = dcp{i}.block{j}.name;
      for k = 1:dcp{i}.block{j}.nterm
        n++;
        printf("| %d | %s | %s | %.10f | %.10f | %.3f | %.3f |\n",n,at,name,...
               dcp{i}.block{j}.exp(k),dcp{i}.block{j}.coef(k),ymean(n),yamean(n));
      endfor
    endfor
  endfor
  printf("\n");
  printf("## Total absolute energy changes for the dimers (Hartree) \n");
  for i = 1:length(db)
    printf("| %d | %s | %.10f |\n",i,db{i}.name,yade(i));
  endfor
  printf("\n");
endfor

## Clean up
stash_inputs_outputs(ilist);
printf("### DCP evaluation finished on %s ###\n",strtrim(ctime(time())));
