#! /usr/bin/octave -q

format long
global dcp basis db prefix nstep verbose run_inputs ycur dcpfin...
       costmin iload usechk stime0 astep dcpeval

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
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=5, MaxCycle=40) Symm=Loose";
extragau="SCF=(Conver=5, MaxCycle=40) Symm=Loose";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=4;
mem=2;

## List of database files to use in DCP optimization
listdb={...
        "db/bde_c-h.db","db/bde_ch-h.db","db/bde_ch2-h.db","db/bde_ch3-ch3.db","db/bde_c2h5-h.db",...
        "db/pes_c6h6s-09.db","db/pes_c6h6t-09.db","db/pes_c3h8-40.db","db/pes_c2h6-35.db","db/pes_ch4g-325.db","db/pes_ch4c-375.db",...
        "db/pes_c6h6s-10.db","db/pes_c6h6t-10.db","db/pes_c3h8-42.db","db/pes_c2h6-39.db","db/pes_ch4g-350.db","db/pes_ch4c-385.db",...
        "db/pes_c6h6s-12.db","db/pes_c6h6t-12.db","db/pes_c3h8-44.db","db/pes_c2h6-41.db","db/pes_ch4g-365.db","db/pes_ch4c-410.db",...
        "db/pes_c6h6s-15.db","db/pes_c6h6t-15.db","db/pes_c3h8-46.db","db/pes_c2h6-43.db","db/pes_ch4g-425.db","db/pes_ch4c-450.db",...
        "db/pes_c6h6s-20.db","db/pes_c6h6t-20.db","db/pes_c3h8-60.db","db/pes_c2h6-50.db","db/pes_ch4g-500.db","db/pes_ch4c-500.db",...
        };
weightdb=[];
##      "db/bde_cyclobutene-perits.db","db/bde_cyclopentadiene-perits.db","db/bde_darc-ethine-butadiene.db","db/bde_dim-13cyclopentadiene.db",...
##      "db/pes_c3h8-100.db","db/pes_c2h6-100.db","db/pes_ch4g-1000.db","db/pes_ch4c-1000.db",...

## Initial DCP file (you can use a cell array of files here, like
## {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini="dcp.ini";

## Final DCP file (can be the same as the initial file). While 
## the script is running, dcpfin contains the DCP for the evaluation
## with lowest cost function.
dcpfin="dcp.fin";

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
funeval = "fbasic";

## Name of the Gaussian input runner routine
run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.

## Tolerance criteria for the minimization (maximum simplex size)
ptol = 1d-3; ## parameter change tolerance, default 1e-6

## Initial simplex size parameter. If dcp.ini is x, then the points in
## the initial simplex are:  
## [x(1) * (1+isz), x(2), x(3), ... x(n)]
## [x(1), x(2) * (1+isz), x(3), ... x(n)]
## [x(1), x(2), x(3) * (1+isz), ... x(n)]
## ...
## [x(1), x(2), x(3), ... x(n) * (1+isz)]
isz = 10;

## Save the amoeba internal variables to this restart file. If the
## restart file is present, use it. Be sure to remove stale
## restart files.
## asave = "" ## do not use a restart file
asave = sprintf("%s.who",prefix);

## Carry over Gaussian checkpoint files from one iteration to the next.
## Use them as the initial guess in Gaussian.
## usechk = "" ## do not use checkpoint files
usechk = 1;

#### No touching past this point. ####

## Header
printf("### DCP optimization started on %s ###\n",strtrim(ctime(time())));

## Read the basis set
basis = parsebasis(basis);

## Read the initial DCP
dcp = parsedcp(dcpini);
if (verbose) 
  printf("### Initial DCP ###\n");
  writedcp(dcp);
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
costmin = Inf;
iload = [];
stime0 = time();
xini = packdcp(dcp);

## Minimize
[xmin ymin] = amoeba_dcp(funeval,{xini},struct('crit',2,'tol',ptol,'isz',isz,'asave',asave));
dcp = unpackdcp(xmin,dcp);

## Delete the checkpoint files
clear_checkpoints()

## Write the final DCP
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
printf("# MAE = %.4f\n",mean(abs(yref-ycur)));
printf("# MAPE = %.4f\n",mean(abs((yref-ycur)./yref))*100);
printf("# RMS = %.4f\n",sqrt(mean((yref-ycur).^2)));
printf("# Cost function minimum: %.10f\n",ymin)
printf("# Final DCP written to: %s\n",dcpfin)
printf("### DCP optimization finished on %s ###\n",strtrim(ctime(time())));

