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
global acp basis db prefix nstep run_inputs ycur acpfin...
       costmin stime0 astep savetar acpeval muk acp0...
       savetar errcontinue ncpu mem ferr

#### Modify this to change the input behavior ####

## Functional
method="hf";

## Basis set or basis file or files. You can use a single string
## or a cell array. If you use a string, then the script will look
## for a file by that name. If the file does not exist, then the string
## will be assumed to be a Gaussian keyword and passed to the input
## If a file is found, it is parsed and the basis-set information read,
## then information for the relevant atoms passed to the inputs. 
## Several basis set files can be used (e.g. {"basis1","basis2"}).
basis="sto-3g";

## Extra bits for gaussian (do not include pseudo=read here)
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";
extragau="SCF=(Conver=6, MaxCycle=40) Symm=none int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files to use in ACP optimization
listdb={...
          "db/s22_h2o_h2o.db",...
          "db/s22_nh3_nh3.db",...
};

## Use this keyword to select a particular reference energy. Empty
## usually means high-level reference data. Other options are, for 
## instance, blyp/aqz or lcwpbe/atz.
reftype="";

## Weights. Must be the same length as listdb, or empty.
weightdb=[];

## Initial ACP file
acpini="e4.bsip";

## Final ACP file (can be the same as the initial file). While 
## the script is running, acpfin contains the ACP for the evaluation
## with lowest cost function.
acpfin="acp.fin";

## This ACP will be included in all the calculations but it will not 
## be optimized. 
## acpfix="acp.fix";

## Final evaluation file. Contains the evaluation of the best ACP
## found on hte parametrization set. While the script is running,
## acpeval contains the ACP for the evaluation with the lowest cost
## function. 
acpeval="acp.eval";

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the ACP optimization evaluation number. The archive
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
## run_inputs = @run_inputs_plonk_priority; ## plonk version, high priority.
## run_inputs = @run_inputs_plonk_packed; ## plonk version, pack the inputs.
## run_inputs = @run_inputs_nint; ## Submit inputs to a private queue on the NINT cluster.
## run_inputs = @run_inputs_nint_gino; ## Submit inputs to a private queue on the NINT cluster (gino).
## run_inputs = @run_inputs_elcap3; ## Submit inputs to elcap3.
## run_inputs = @run_inputs_pass; ## Create the inputs and do not run anything.

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

## Continue with the calculation, even if one of the calculations fails.
errcontinue = 1;
## errcontinue = "";

## Save a compressed tar.bz2 with the inputs/outputs/wfxs?
## savetar="";
## savetar="tar";
## savetar="gz";
savetar="bz2";
## savetar="xz";

## Name of the error file (timing, debug, etc.)
errfile = "eval.err";

#### No touching past this point. ####

## Open error file
ferr = -1;
if (exist("errfile","var"))
  ferr = fopen(errfile,"w");
endif

## Header
printf("### ACP optimization started on %s ###\n",strtrim(ctime(time())));
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
db = parsedb(listdb,reftype);
db = filldb(db,weightdb,method,extragau);

## Read the initial ACP
acp = parseacp(acpini);

## Read the fixed ACP
if (exist("acpfix","var") && !isempty(acpfix))
  acp0 = parseacp(acpfix);
  ## Check that the atoms in acp and acp0 do not clash
  for i = 1:length(acp)
    for j = 1:length(acp0)
      if (strcmp(tolower(acp{i}.atom),tolower(acp0{j}.atom)))
        error("Same atom in acpini and acpfix")
      endif
    endfor
  endfor
else
  acp0 = {};
endif

## Run the minimization, initialize global variables
nstep = 0;
astep = 0;
costmin = Inf;
stime0 = time();
x = packacp(acp);

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
  if (ferr > 0) 
    fprintf(ferr,"# Minimization step number %d - %s\n",nopt,strtrim(ctime(time())));
    fflush(ferr);
  endif
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

## Message to the error file
if (ferr > 0) 
  fprintf(ferr,"# Writing final results - %s\n",strtrim(ctime(time())));
  fflush(ferr);
endif

## Write the final ACP
acp = unpackacp(xmin,acp);
writeacp(acp,acpfin)

## Write the results at the minimum
printf("### Statistics for the parametrization set at the optimal ACP###\n");
printf("| Id | Name | yref | ycalc | dy |\n")
dy = yref = zeros(length(db),1);
for i = 1:length(db)
  yref(i) = db{i}.ref;
  dy(i) = ycur(i) - yref(i);
  printf("| %d | %s | %.8f | %.8f | %.8f |\n",...
         i,db{i}.outname,yref(i),ycur(i),dy(i));
endfor
printf("# Norm of the coeffs = %.4e\n",sqrt(sum(xmin(2:2:end).^2)));
printf("# MAE = %.4f\n",mean(abs(yref-ycur)));
printf("# MAPE = %.4f\n",mean(abs((yref-ycur)./yref))*100);
printf("# RMS = %.4f\n",sqrt(mean((yref-ycur).^2)));
printf("# Penalty function minimum: %.10f\n",ymin)
printf("# Final ACP written to: %s\n",acpfin)

## Close error file
if (ferr > 0) 
  fprintf(ferr,"# Finished on %s\n",strtrim(ctime(time())));
  fflush(ferr);
endif
fclose(ferr);

printf("### ACP optimization finished on %s ###\n",strtrim(ctime(time())));

