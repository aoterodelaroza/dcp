#! /usr/bin/octave -q

format long
global dcp basis db prefix nstep verbose run_inputs ycur...
       dcpfin costmin iload usechk stime0 astep 

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
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=5, MaxCycle=40) Symm=Loose";
extragau="SCF=(Conver=5, MaxCycle=40) Symm=Loose";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=4;
mem=2;

## List of database files to use in DCP optimization
listdb={...
        "db/bde_c-h.db","db/bde_ch-h.db","db/bde_ch2-h.db","db/bde_ch3-ch3.db","db/bde_c2h5-h.db",...
        };
##      "db/bde_cyclobutene-perits.db","db/bde_cyclopentadiene-perits.db","db/bde_darc-ethine-butadiene.db","db/bde_dim-13cyclopentadiene.db",...
##      "db/pes_c3h8-100.db","db/pes_c2h6-100.db","db/pes_ch4g-1000.db","db/pes_ch4c-1000.db",...

## List of DCP files to evaluate (you can use a cell array of files
## here, like {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini={"bleh/bleh_0012.dcp","bleh/bleh_0006.dcp","bleh/bleh_0009.dcp"};

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="test";

## Name for the the minimization procedure driver.
funeval = "fbasic";

## Name of the Gaussian input runner routine
run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.

## Carry over Gaussian checkpoint files from one iteration to the next.
## Use them as the initial guess in Gaussian.
## usechk = "" ## do not use checkpoint files
usechk = 1;

#### No touching past this point. ####

## Header
printf("### DCP evaluation started on %s ###\n",strtrim(ctime(time())));
## Read the basis set
basis = parsebasis(basis);

## Read the parametrization database 
db = parsedb(listdb);
db = filldb(db,[],method,extragau,ncpu,mem);

## Initialization
verbose = 0;

## Read and evaluate the DCPs one by one
if (!iscell(dcpini))
  dcpini = {dcpini};
endif
for idcp = 1:length(dcpini)
  dcp = parsedcp(dcpini{idcp});

  ## Run the minimization, initialize global variables
  nstep = idcp-1;
  costmin = Inf;
  iload = [];
  stime0 = time();
  dcpeval = dcpfin = "";
  x = packdcp(dcp);
  y = feval(funeval,x,1);

  ## Reference energies and errores
  dy = yref = zeros(length(db),1);
  for i = 1:length(db)
    yref(i) = db{i}.ref;
    dy(i) = ycur(i) - yref(i);
  endfor

  ## Write the results at the minimum
  printf("# DCP %d (%s) | MAE = %.4f | MAPE = %.4f | RMS = %.4f | time = %d |\n",idcp,dcpini{idcp},...
         mean(abs(y-yref)),mean(abs((yref-y)./yref))*100,sqrt(mean((yref-ycur).^2)),time()-stime0);

  printf("| Id|           Name       |       yref   |      ycalc   |       dy     |\n");
  for i = 1:length(db)
    printf("| %d | %20s | %12.4f | %12.4f | %12.4f |\n",...
           i,db{i}.name,yref(i),ycur(i),dy(i));
  endfor
  printf("\n");
endfor

## DELETE the checkpoint files from the stasch
clear_checkpoints()

## Clean up
printf("### DCP evaluation finished on %s ###\n",strtrim(ctime(time())));
