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

function [y dy d2y] = fbasicd2(x)
  %% function [y dy d2y] = fbasicd2(x)
  %%
  %% Evaluation function for the minimization routine; calculates
  %% first and second derivatives of the cost function. This function
  %% is meant to be used as argument for one of the optim routines
  %% (like bfgsmin, minimize, or nonlin_min). The argument are the ACP
  %% coefficients and exponents, packed into a convenient array. The
  %% appropriate Gaussian calculations are carried out, and the cost
  %% function for the ACP given by x is calculated, and returned as y.
  
  global acp db prefix nstep run_inputs ycur acpfin ...
         costmin stime0 astep acpeval maxnorm muk fixnorm errcontinue
  
  ## Yet another function evaluation.
  nstep++;
  
  ## Crash if any of the parameters is a nan
  if (any(isnan(x)))
    error(sprintf("Optimization procedure tried to use a NaN parameter in step %d\n",nstep));
  endif

  ## If the maxnorm is exceeded, return Inf
  if (exist("maxnorm","var") && norm(x(2:2:end)) > maxnorm)
    norm(x(2:2:end))
    y = Inf;
    printf("#x2# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
           astep,nstep,y,...
           Inf,Inf,Inf,Inf,norm(x(2:2:end)),0,time()-stime0);
    stime0 = time();
    return
  endif

  ## Unpack the ACP coefficients and exponents
  acp = unpackacp(x,acp);

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## If any of the exponents is positive, return Inf
  ## Set up the Gaussian input files
  ilist = {};
  sidx = [];
  n = 0;
  for i = 1:length(db)
    anew = setup_input_one(db{i},acp,2);
    ilist = {ilist{:}, anew{:}};
    for j = 1:length(anew)
      sidx(++n) = i;
    endfor
  endfor

  ## Run all inputs
  srun = run_inputs(ilist);
  srun = unique(sidx(srun));

  ## If any of the Gaussian outputs are wrong, return Inf to the caller
  if (!isempty(srun) && (!exist("errcontinue","var") || !errcontinue))
    y = Inf;
    stash_inputs_outputs(y);
    printf("#x2# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
           astep,nstep,y,...
           Inf,Inf,Inf,Inf,norm(x(2:2:end)),0,time()-stime0);
    stime0 = time();
    return
  endif

  ## Collect the results, compare to the reference data, calculate the cost function
  erry = ycalc = yref = zeros(length(db),1);
  wei = zeros(length(db),1);
  y = 0;
  dy = zeros(size(x));
  d2y = eye(length(x));
  for j = 2:2:length(x)
    d2y(j) = 0;
  endfor
  nerr = 0;
  for i = 1:length(db)
    ## Was this an error? (errcontinue is true if srun is not empty)
    if (!isempty(srun) && any(srun == i))
      erry(i) = 0;
      ycalc(i) = db{i}.ref;
      yref(i) = db{i}.ref;
      nerr++;
      continue
    endif

    ## Process this output
    wei(i) = db{i}.wei;
    [erry(i) ycalc(i) yref(i) ay] = process_output_one(db{i},:,:,1);

    ## Continue on error?
    if (exist("errcontinue","var") && errcontinue && isinf(ycalc(i)))
      erry(i) = 0;
      ycalc(i) = db{i}.ref;
      yref(i) = db{i}.ref;
      srun = [srun i];
      nerr++;
      continue
    endif

    ## Accumulate the error and derivatives.
    y += wei(i) * erry(i)^2;
    for j = 1:length(ay)
      dy(2*j) += 2 * wei(i) * erry(i) * ay(j);
      for k = 1:length(ay)
        d2y(2*j,2*k) += 2 * wei(i) * ay(j) * ay(k);
      endfor
    endfor
  endfor

  ## Save the result of this calculation into the global variable
  ycur = ycalc;

  ## Send the inputs and outputs to the stash
  stash_inputs_outputs(ycalc);

  ## Print summary to output
  if (exist("fixnorm","var") && fixnorm > 0)
    py = y + muk * (sum(x(2:2:end).^2) / fixnorm^2 - 1)^2;
  else
    py = y;
  endif
  printf("#x2# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
         astep,nstep,...
         y,py,sqrt(y/sum(wei)),sqrt(mean((yref-ycalc).^2)),mean(abs(yref-ycalc)),...
         norm(x(2:2:end)),nerr,time()-stime0);
  stime0 = time();

  ## Output errors, if there are any
  if (!isempty(srun))
    printf("# List of errors for this step\n")
    for i = srun
      printf("| %d | %s | %.4f | %14.8f |\n",i,db{i}.outname,db{i}.wei,yref(i));
    endfor
  endif

  ## Save this ACP to the stash
  writeacp(acp,sprintf("%s/%s_%4.4d.acp",prefix,prefix,nstep));

  ## Write the ACP if this is the best we have
  if (py < costmin)
    if (length(acpfin) > 0)
      writeacp(acp,acpfin);
    endif
    costmin = py;
    if (length(acpeval) > 0)
      fid = fopen(acpeval,"w");
      fprintf(fid,"| Id | Name | weig | yref | ycalc | dy |\n")
      for i = 1:length(db)
        fprintf(fid,"| %d | %s | %.4f | %14.8f | %14.8f | %14.8f |\n",...
                i,db{i}.outname,wei(i),yref(i),ycalc(i),erry(i))
      endfor
      fprintf(fid,"# MAE = %.4f\n",mean(abs(yref-ycalc)));
      fprintf(fid,"# MAPE = %.4f\n",mean(abs((yref-ycalc)./yref))*100);
      fprintf(fid,"# RMS = %.4f\n",sqrt(mean((yref-ycalc).^2)));
      fprintf(fid,"# wRMS = %.4f\n",sqrt(sum(wei .* (yref-ycalc).^2)));
      fprintf(fid,"# Cost function : %.10f\n",y);
      fprintf(fid,"# Penalty function : %.10f\n",costmin);
      fclose(fid);
    endif
  endif

endfunction
