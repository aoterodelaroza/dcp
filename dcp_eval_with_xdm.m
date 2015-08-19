#! /usr/bin/octave -q

format long

## Globals for DCP
global dcp basis db prefix nstep verbose run_inputs ycur...
       dcpfin costmin iload stime0 astep

## Globals for XDM
global hy2kcal e n xc z c6 c8 c10 rc dimers mol1 mol2 be_ref
hy2kcal=627.51;

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
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=6) Symm=Loose int=(grid=ultrafine)";
extragau="SCF=(Conver=6) Symm=Loose int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files for the evaluation
[s out] = system("ls db/s22_*.db db/s66_*.db db/s668_*.db db/s225_*.db db/hsg_*.db \
db/s12l_2*.db db/s12l_3*.db db/s12l_4*.db db/s12l_5*.db db/s12l_6*.db");
listdb = strfields(out);

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
run_inputs = @run_inputs_nint_trasgu; ##

## Run the XDM parametrizations: prefix (xdmprefix), functionals (xdmfuns), and db
## for the parametrization (xdmdb).
xdmprefix = "xdm";
xdmfuns = {"blyp","b3lyp","bhahlyp","lcwpbe","pbe","pbe0","pw86pbe"};
[s out] = system("ls db/s22_*.db");
xdmdb = strfields(out);

#### No touching past this point. ####

## Header
printf("### DCP evaluation (with XDM) started on %s ###\n",strtrim(ctime(time())));

## Prepare for XDM 
funname = struct("blyp","blyp","b3lyp","b3lyp","bhahlyp","bhandhlyp",...
                 "bhandhlyp","bhandhlyp","bhah","bhandhlyp","lcwpbe","lc-wpbe",...
                 "pbe","pbepbe","pbepbe","pbepbe",...
                 "pbe0","pbe1pbe","pbe1pbe","pbe1pbe","pw86","iop(3/74=809)",...
                 "pw86pbe","iop(3/74=809)");
for i = 1:length(xdmfuns)
  if (!isfield(funname,xdmfuns{i}))
    error(sprintf("Functional %s not known.",xdmfuns{i}));
  endif
endfor
source("routines_for_xdm.m");
addpath("leasqr/");

## Read the basis set
basis = parsebasis(basis);

## Initialization
verbose = 0;
if (!iscell(dcpini))
  dcpini = {dcpini};
endif

## Read the XDM database
db = parsedb(xdmdb);

## Save the oldprefix for the evaluation
prefix0 = prefix;
xdmsave = [];

## Prepare all input files for this DCP and all the functionals
printf("### XDM parametrization ###\n");
for idcp = 1:length(dcpini)
  dcp = parsedcp(dcpini{idcp});
  nstep = idcp;
  printf("### For DCP: %s ###\n",dcpini{idcp});
  printf("| functional | a1 | a2 (ang) | MAE | MAPE |\n");

  ## Run over functionals
  for ifun = 1:length(xdmfuns)
    ilist = {};

    ## Get the functional line
    fun = xdmfuns{ifun};
    if (!isfield(funname,fun))
      error(sprintf("Unknown functional: %s",fun));
    endif
    funline = getfield(funname,fun);

    ## Set up the method in the db
    db = filldb(db,[],funline,extragau,ncpu,mem);

    ## The new prefix is xdmprefix_funid
    prefix = sprintf("%s_%s%d",prefix0,xdmprefix,ifun);

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
    srun = run_inputs(ilist,1,[1.0 1.0],fun);
    
    ## Fit XDM to the results
    ## Build the din file
    n = length(db);
    rr = cell(1,n);
    for i = 1:n
      rr{i} = cell(1,7);
      rr{i}{1} = 1;
      rr{i}{2} = sprintf("%s_%4.4d_%s_mol",prefix,nstep,db{i}.name);
      rr{i}{3} = -1;
      rr{i}{4} = sprintf("%s_%4.4d_%s_mon1",prefix,nstep,db{i}.name);
      rr{i}{5} = -1;
      rr{i}{6} = sprintf("%s_%4.4d_%s_mon2",prefix,nstep,db{i}.name);
      rr{i}{7} = db{i}.ref;
    endfor
    
    ## Build the dimer list
    mol1 = mol2 = dimers = {};
    be_ref = struct();
    for i = 1:length(rr)
      dimers(end+1) = rr{i}{2};
      mol1(end+1) = rr{i}{4};
      mol2(end+1) = rr{i}{6};
      be_ref = setfield(be_ref,rr{i}{2},abs(rr{i}{7}));
    endfor
    
    ## Collect the structures, energies, etc.
    collect_for_fit()
    
    ## Fit
    pin=[0.7564 1.4545];
    xin = (1:length(dimers))';
    yin = zeros(length(dimers),1);
    for i = 1:length(dimers)
      yin(i) = getfield(be_ref,dimers{i});
    endfor
    ywt = 1./yin;
    [yout pout cvg iter corp covp covr stdresid Z r2] = leasqr(xin,yin,pin,@fxdm,1e-11,2000,ywt);
    
    ## Print the results
    printf("| %s | %.4f | %.4f | %5.2f | %5.2f |\n",fun,...
           pout(1),pout(2),mean(abs(yin-yout)),mean(abs(yin-yout)./abs(yin))*100);
    
    if (strcmp(method,funline))
      xdmsave = pout;
    endif
    
    ## Stash the result
    stash_inputs_outputs(ilist);
  endfor
endfor

printf("\n");
printf("### Evaluation ###\n");

## Put back the prefix
prefix = prefix0;

## Read the evaluation database
db = parsedb(listdb);
db = filldb(db,[],method,extragau,ncpu,mem);

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
    anew = setup_input_one(db{i},dcp);
    ilist = {ilist{:}, anew{:}};
  endfor
endfor

## Run all inputs
if (isempty(xdmsave))
  srun = run_inputs(ilist,1);
else
  srun = run_inputs(ilist,1,xdmsave,method);
endif

## Collect the results and compare to the reference data
for idcp = 1:length(dcpini)
  nstep = idcp;

  dy = ycalc = yref = zeros(length(db),1);
  for i = 1:length(db)
    [dy(i) ycalc(i) yref(i)] = process_output_one(db{i},0);
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
  printf("### DCP %d (%s) | MAE = %.4f | MAPE = %.4f | RMS = %.4f |\n",idcp,dcpini{idcp},...
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
