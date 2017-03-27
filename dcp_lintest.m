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
global dcp basis db prefix nstep run_inputs iload savetar ncpu mem ferr

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
extragau="SCF=(Conver=8, MaxCycle=80) Symm=none int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files to use in DCP linearity test
## [listdb weightdb] = training_set(1,1,1,1,1);
listdb = {...
           "h2o_shields/water2Cs.db",...
           "h2o_shields/water3UUD.db",...
           "h2o_shields/water3UUU.db",...
           "atz_b3lyp/bdex_oh-h-04.db",...
};
listdb = {...
           "h2o_shields/water2Cs.db",...
           "h2o_shields/water3UUD.db",...
           "h2o_shields/water3UUU.db",...
           "atz_b3lyp/bdex_oh-h-04.db",...
};

## Atom/channel/exponent list for which the non-linearity test will be
## run.
atom="O";
channel="l";
explist=[0.01 0.1];

## Base coefficient for the linearity range exploration
c0=0.1;

## Maximum and minimum coefficient values
cmax = 2.1;

## Scaling factor for the coefficient exploration
cfactor = 2;

## Threshold for the precision (Hartree) and minimum effect on the binding 
## energies (kcal/mol).
precthr = 1e-5;

## Threshold for the non-linearity error (kcal/mol)
nonlinthr = 1e-3;

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix0="bleh";

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
## run_inputs = @run_inputs_read; ## Read the outputs in the directories generated by run_inputs_pass

## Save a compressed tar file with the inputs/outputs/wfxs?
## savetar="";
## savetar="tar";
## savetar="gz";
## savetar="bz2";
savetar="xz";

## Name of the error file (timing, debug, etc.)
errfile = "eval.err";

#### No touching past this point. ####

## Open error file
ferr = -1;
if (exist("errfile","var"))
  ferr = fopen(errfile,"w");
endif

## Header
printf("### DCP non-linearity and precision tests started on %s ###\n",strtrim(ctime(time())));
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

## Discard the elements that do not contain the current atom
iuse = ones(1,length(listdb));
for i = 1:length(db)
  found = 0;
  for j = 1:db{i}.nmol
    for k = 1:db{i}.molc{j}.nat
      if (strcmpi(db{i}.molc{j}.at{k},atom)) 
        found = 1;
        break
      endif
    endfor
    if (found)
      break
    endif
  endfor
  iuse(i) = found;
endfor
printf("### Using %d out of the original %d db entries ###\n",sum(iuse),length(db));
db = db(find(iuse));

## enter main loop
c0final = [];
for iexp = 1:length(explist)
  exponent = explist(iexp);

  ## Create the prefix directory if it doesn't exist yet
  prefix = sprintf("%s-%2.2d",prefix0,iexp);
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## Explore the coefficient limits of this exponent
  nstep = 0;
  coef = c0;
  dir = -1; 
  irunup = ones(1,length(db));
  coefup = zeros(1,length(db));
  ysave = cell();
  ysaveidx = [];
  while true 
    nstep++;

    ## build the next run
    if (nstep == 1)
      ## the empty
      c = 0;
    elseif (nstep == 2)
      ## the c0
      cprev = c0;
      c = c0;
    else
      ## the other coefficients
      if (dir == -1) 
        cprev = c;
      endif
      if (dir == -1) 
        c = c / cfactor;
      else
        c = c * cfactor;
      endif
    endif
    dcp = makedcp(atom,channel,exponent,c);

    ## Debug
    if (ferr > 0) 
      fprintf(ferr,"# Step %d - Coefficient %.10f - %s\n",nstep,c,strtrim(ctime(time())));
      fflush(ferr);
    endif

    if (nstep > 1)
      idx = log(c / c0) / log(cfactor);
    else
      idx = Inf;
    endif

    if (!ismember(idx,ysaveidx))
      ## Set up the Gaussian input files
      if (ferr > 0) 
        fprintf(ferr,"# Setting up Gaussian input files - %s\n",strtrim(ctime(time())));
        fflush(ferr);
      endif
      ilist = {};
      for i = 1:length(db)
        if (irunup(i))
          anew = setup_input_one(db{i},dcp);
          ilist = {ilist{:}, anew{:}};
        endif
      endfor
      if (ferr > 0) 
        fprintf(ferr,"# List of inputs has %d entries\n",length(ilist));
        fflush(ferr);
      endif

      ## Run all inputs
      srun = run_inputs(ilist);

      ## Collect the results 
      if (ferr > 0) 
        fprintf(ferr,"# Collecting the results and calculating errors - %s\n",strtrim(ctime(time())));
        fflush(ferr);
      endif
      ycalc = yref = ycalcnd = zeros(length(db),1);
      for i = 1:length(db)
        if (irunup(i))
          [~, ycalc(i), ~, ~, ~] = process_output_one(db{i});
        else
          ycalc(i) = 0;
        endif
      endfor
      if (nstep > 1)
        ysaveidx = [ysaveidx idx];
        ysave{100 + idx} = ycalc;
      endif
    else
      ycalc = ysave{100 + idx};
    endif

    ## Save and write the results
    printf("# Direction: %d\n",dir);
    printf("# Index: %d\n",idx);
    if (nstep == 1)
      yempty = ycalc;
      printf("# Step %d - empty\n",nstep);
      printf("| Id|           Name       |       ycalc   |\n");
      for i = 1:length(db)
        printf("| %d | %20s | %14.8f |\n",i,db{i}.outname,ycalc(i));
      endfor
      printf("\n");
    elseif (nstep == 2) 
      ycur = ycalc - yempty;
      yprev = ycur;
      printf("# Step %d - c0 coefficient = %.10f\n",nstep,c);
      printf("| Id|        Name       |       dycalc   |\n");
      for i = 1:length(db)
        printf("| %d | %20s | %14.8f |\n",i,db{i}.outname,ycur(i));
      endfor
      printf("\n");
    else
      if (dir == -1)
        yprev = ycur;
      endif
      ycur = ycalc - yempty;
      nonlin = abs(ycur-yprev*c/cprev);
      printf("# Step %d - coefficient = %.10f\n",nstep,c);
      printf("| Id|        Name       |       dyprev     |     dycalc   |   non-lin (%f/%f) |\n",c,cprev);
      for i = 1:length(db)
        if (irunup(i))
          printf("| %d | %20s | %14.8f | %14.8f | %14.8f |\n",i,db{i}.outname,yprev(i),ycur(i),nonlin(i));
        else
          printf("| %d | %20s | c0=%.10f | xxdonexx | xxdonexx |\n",i,db{i}.outname,coefup(i));
        endif
      endfor
      printf("\n");
    endif

    ## Clean up
    stash_inputs_outputs(ycalc);

    ## Check there are no inf in the ycalc
    if (any(ycalc == Inf))
      error("Some of the outputs were Inf")
    endif

    ## Finish the downstroke
    if (dir == -1 && nstep > 2)
      if (all(nonlin < precthr)) 
        ## accept the current coefficient
        dir = 1;
        cprev = c;
        yprev = ycur;
      endif
    elseif (dir == 1 && nstep > 2) 
      irunup = irunup & (nonlin' <= nonlinthr);
      coefup(find(nonlin' <= nonlinthr)) = c;
    endif

    ## Exit conditions
    if (c > cmax) 
      printf("# c (%f) > cmax (%f) condition met\n\n",c,cmax);
      coefup(find(irunup)) = cmax;
      break
    endif
    if (all(!irunup))
      printf("# found maximum coefficients for all systems\n\n",c,cmax);
      break
    endif
  endwhile

  ## Print the final coefficients
  printf("#### Coefficients for exponent %.10f ####\n",exponent);
  printf("c0   = %.10f\n",cprev);
  printf("cmax = %.10f\n",min(coefup));
  printf("| Id|        Name       |       cmax     |\n");
  for i = 1:length(db)
    printf("| %d | %20s | %.10f |\n",i,db{i}.outname,coefup(i));
  endfor
  printf("\n");
  c0final(iexp,1) = cprev;
  c0final(iexp,2) = min(coefup);
endfor

## Close error file
if (ferr > 0) 
  fprintf(ferr,"# Finished on %s\n",strtrim(ctime(time())));
  fflush(ferr);
endif
fclose(ferr);

## Print the final coefficients
printf("#### Final list of coefficients ####\n",exponent);
printf("| Id| Exponent | c0 | cmax |\n");
for i = 1:length(explist)
  printf("| %d | %.10f | %.10f | %.10f |\n",i,explist(i),c0final(i,1),c0final(i,2));
endfor
printf("\n");

## Termination
printf("### DCP non-linearity and precision tests finished on %s ###\n",strtrim(ctime(time())));
