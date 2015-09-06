#! /usr/bin/octave -q

format long
global dcp basis db prefix nstep verbose run_inputs ycur dcpfin...
       costmin iload stime0 astep dcpeval maxnorm fixnorm muk dcp0

#### Modify this to change the input behavior ####

## Do you want lots of stuff in the output?
verbose = 0;

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
ncpu=8;
mem=2;

## List of database files to use in DCP optimization
listdb={...
};
weightdb=[];

## Initial DCP file (you can use a cell array of files here, like
## {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini="dcp.ini";

## Final DCP file (can be the same as the initial file). While 
## the script is running, dcpfin contains the DCP for the evaluation
## with lowest cost function.
dcpfin="dcp.fin";

## This DCP will be included in all the calculations but it will not 
## be optimized. 
dcpfix="dcp.fix";

## Final evaluation file. Contains the evaluation of the best DCP
## found on hte parametrization set. While the script is running,
## dcpeval contains the DCP for the evaluation with the lowest cost
## function. 
dcpeval="dcp.eval";

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Name of the function to be minimized 
funeval   = "fbasic";
funevald2 = "fbasicd2";

## Name of the Gaussian input runner routine
run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.
## run_inputs = @run_inputs_plonk; ## Submit inputs to a private queue, plonk version.
## run_inputs = @run_inputs_nint_trasgu; ## Submit inputs to a private queue on the NINT cluster.
## run_inputs = @run_inputs_elcap3; ## Submit inputs to elcap3.

## Tolerance criteria for the minimization (function difference between successive steps)
ftol = 1d-2; ## function change tolerance

## Maximum norm: when the norm of the coefficients (square root of the
## sum of the squares), the cost function is Inf. This limits the
## minimizer search to a ball of radius maxnorm around zero.
## maxnorm = 1d-3;

## Norm constraint: the norm of the coefficients is constrained to
## this value. Stop the minimzation if the relative deviation from
## fixnorm is less than normtol.
## fixnorm = 7.0711e-04;
## normtol = 1d-2;

#### No touching past this point. ####

## Header
printf("### DCP optimization started on %s ###\n",strtrim(ctime(time())));
printf("### PID: %d ###\n",getpid());

## Read the basis set
basis = parsebasis(basis);

## Read the initial DCP
dcp = parsedcp(dcpini);
if (verbose) 
  printf("### Initial DCP ###\n");
  writedcp(dcp);
endif

## Read the fixed DCP
if (exist("dcpfix","var") && !isempty(dcpfix))
  dcp0 = parsedcp(dcpfix);
  ## Check that the atoms in dcp and dcp0 do not clash
  for i = 1:length(dcp)
    for j = 1:length(dcp0)
      if (strcmp(tolower(dcp{i}.atom),tolower(dcp0{j}.atom)))
        error("Clashing atom in dcpini and dcpfix")
      endif
    endfor
  endfor
else
  dcp0 = {};
endif

## Read the parametrization database 
db = parsedb(listdb);
db = filldb(db,weightdb,method,extragau,ncpu,mem);
if (verbose) 
  printf("### Database for the parametrization ###\n");
  writedb(db);
endif

## Crash if some of the DCP atoms are not used in any of the
## db files
for i = 1:length(dcp)
  atom = dcp{i}.atom;
  ifound = 0;
  for j = 1:length(db)
    for k = 1:db{j}.mol.nat
      if (tolower(atom) == tolower(db{j}.mol.at{k}))
        ifound = 1;
        break
      endif
    endfor
    if (ifound)
      break
    endif
  endfor
  if (!ifound)
    error(sprintf("Atom %s is present in the inital DCP file (%s) but is not present in any of the DB files.",atom,dcpini))
  endif
endfor

## Run the minimization, initialize global variables
nstep = 0;
astep = 0;
costmin = Inf;
iload = [];
stime0 = time();
x = packdcp(dcp);

## Set initial penalty coefficient
muk = 0;
if (exist("fixnorm","var") && fixnorm > 0)
  v = feval(funeval,x);
  ssq = sum(x(2:2:end).^2);
  px = ssq/fixnorm^2 - 1;
  printf("### Initial cost: %.10f\n",v);
  printf("### Initial norm: %.10f\n",sqrt(ssq));
  printf("### Target norm: %.10f\n",fixnorm);
  if (abs(px) > 1d-3)
    muk0 = 0.01 * v / px^2;
  else
    muk0 = v;
  endif
endif

## Run the minimization
nopt = 0;
muk = 0;
while true
  costmin = Inf;
  nopt = nopt + 1;
  if (exist("fixnorm","var") && fixnorm > 0)
    printf("### Minimization number %d\n",nopt);
    printf("### Penalty mu: %.4e\n",muk);
  endif
  ## Minimize
  [xmin, ymin] = d2_min(funeval,funevald2,x,ftol);

  if (exist("fixnorm","var") && fixnorm > 0)
    x = xmin;
    if (nopt == 1)
      muk = muk0 / 10;
    endif
    muk = muk * 10;
    cn = sqrt(sum(x(2:2:end).^2));
    printf("### Minimization done\n");
    printf("### Coefficient norm: %.10f\n",cn);
    printf("### Target norm: %.10f\n",fixnorm);
    if (abs(cn - fixnorm)/fixnorm <= normtol)
      break
    else
      printf("### Penalty mu: %.4e\n",muk);
    endif
  else
    break
  endif
endwhile

## Write the final DCP
dcp = unpackdcp(xmin,dcp);
writedcp(dcp,dcpfin)

## Write the results at the minimum
printf("### Statistics for the parametrization set at the optimal DCP###\n");
printf("| Id | Name | yref | ycalc | dy |\n")
dy = yref = zeros(length(db),1);
for i = 1:length(db)
  yref(i) = db{i}.ref;
  dy(i) = ycur(i) - yref(i);
  printf("| %d | %s | %.4f | %.4f | %.4f |\n",...
         i,db{i}.name,yref(i),ycur(i),dy(i));
endfor
printf("# Norm of the coeffs = %.4e\n",sqrt(sum(xmin(2:2:end).^2)));
printf("# MAE = %.4f\n",mean(abs(yref-ycur)));
printf("# MAPE = %.4f\n",mean(abs((yref-ycur)./yref))*100);
printf("# RMS = %.4f\n",sqrt(mean((yref-ycur).^2)));
printf("# Penalty function minimum: %.10f\n",ymin)
printf("# Final DCP written to: %s\n",dcpfin)
printf("### DCP optimization finished on %s ###\n",strtrim(ctime(time())));

