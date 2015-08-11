#! /usr/bin/octave -q

format long
global dcp basis db prefix nstep verbose run_inputs ycur dcpfin...
       costmin iload stime0 astep dcpeval maxnorm

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
basis="sto-3g";

## Extra bits for gaussian (do not include pseudo=read here)
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=9, MaxCycle=40) Symm=Loose";
extragau="SCF=(Conver=9, MaxCycle=40) Symm=Loose";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files to use in DCP optimization
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
weightdb=[1 1 1 5 1 1 1 1 1,... ## bdes
          1 1 1 1 1 1,... ## c2h6
          1 1 1 1 1 1,... ## c3h8
          3 5 2 1 1,... ## c6h6s 
          1 3 2 1 1,... ## c6h6t
          1 1 3 1 1 1,... ## ch4c
          1 2 10 2 1 1,... ## ch4g
         ];

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
funeval   = "fbasic";
funevald1 = "fbasicd1";
funevald2 = "fbasicd2";

## Name of the Gaussian input runner routine
run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.
## run_inputs = @run_inputs_plonk; ## Submit inputs to a private queue, plonk version.
## run_inputs = @run_inputs_nint_trasgu; ##

## Tolerance criteria for the minimization (function difference between successive steps)
ftol = 1d-4; ## function change tolerance

## Maximum norm
maxnorm = 1d-1;

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
astep = 0;
costmin = Inf;
iload = [];
stime0 = time();
xini = packdcp(dcp);

## Minimize
[xmin, ymin] = d2_min(funeval,funevald2,xini,ftol);
dcp = unpackdcp(xmin,dcp);

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

