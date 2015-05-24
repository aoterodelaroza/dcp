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
extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=5, MaxCycle=40) Symm=Loose";
# extragau="SCF=(Conver=5, MaxCycle=40) Symm=Loose";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=6;
mem=2;

## List of database files to use in DCP optimization
[s out] = system("ls db/s66_*.db");
listdb = strsplit(out,"\n");
listdb = listdb(1:end-1);

## List of DCP files to evaluate (you can use a cell array of files
## here, like {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini={"dcp3.fin","dcp3bis.fin"};

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
## run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.

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
usechk = 0;
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
    ilist = [ilist, setup_input_one(db{i},dcp)];
  endfor
endfor

## Run all inputs
srun = run_inputs(ilist,1);

## Collect the results and compare to the reference data
for idcp = 1:length(dcpini)
  nstep = idcp;

  dy = ycalc = yref = zeros(length(db),1);
  for i = 1:length(db)
    [dy(i) ycalc(i) yref(i)] = process_output_one(db{i});
  endfor
  if (any(ycalc == Inf))
    mae = Inf;
    mape = Inf;
    rms = Inf;
  else
    dyr = dy(find(dy != Inf));
    yrefr = yref(find(yref != Inf));
    mae = mean(abs(dyr));
   mape = mean(abs(dyr./yrefr))*100;
   rms = sqrt(mean(dyr.^2));
  endif

  ## Write the results at the minimum
  printf("# DCP %d (%s) | MAE = %.4f | MAPE = %.4f | RMS = %.4f |\n",idcp,dcpini{idcp},...
         mae,mape,rms);
  
  printf("| Id|           Name       |       yref   |      ycalc   |       dy     |\n");
  for i = 1:length(db)
    printf("| %d | %20s | %12.4f | %12.4f | %12.4f |\n",...
           i,db{i}.name,yref(i),ycalc(i),dy(i));
  endfor
  printf("\n");
endfor

## Clean up
stash_inputs_outputs(ilist);
printf("### DCP evaluation finished on %s ###\n",strtrim(ctime(time())));
