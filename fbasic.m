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

function y = fbasic(x)
  %% function y = fbasic(x)
  %%
  %% Evaluation function for the minimization routine. This function is meant
  %% to be used as argument for one of the optim routines (like bfgsmin,
  %% minimize, or nonlin_min). The argument are the DCP coefficients
  %% and exponents, packed into a convenient array. The appropriate Gaussian
  %% calculations are carried out, and the cost function for the DCP
  %% given by x is calculated, and returned as y.
  
  global dcp db prefix nstep run_inputs ycur dcpfin ...
         costmin stime0 astep dcpeval maxnorm fixnorm muk errcontinue
  
  ## Yet another function evaluation.
  nstep++;
  
  ## Crash if any of the parameters is a nan
  if (any(isnan(x)))
    error(sprintf("Optimization procedure tried to use a NaN parameter in step %d\n",nstep));
  endif

  ## If the maxnorm is exceeded, return Inf
  if (exist("maxnorm","var") && norm(x(2:2:end)) > maxnorm)
    y = Inf;
    printf("#x0# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
           astep,nstep,y,...
           Inf,Inf,Inf,Inf,norm(x(2:2:end)),0,time()-stime0);
    stime0 = time();
    return
  endif

  ## Unpack the DCP coefficients and exponents
  dcp = unpackdcp(x,dcp);

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
    anew = setup_input_one(db{i},dcp,0);
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
    printf("#x0# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
           astep,nstep,y,...
           Inf,Inf,Inf,Inf,norm(x(2:2:end)),0,time()-stime0);
    stime0 = time();
    return
  endif

  ## Collect the results and compare to the reference data
  nerr = 0;
  dy = ycalc = yref = zeros(length(db),1);
  for i = 1:length(db)
    ## Was this an error? (errcontinue is true if srun is not empty)
    if (!isempty(srun) && any(srun == i))
      dy(i) = 0;
      ycalc(i) = db{i}.ref;
      yref(i) = db{i}.ref;
      nerr++;
      continue
    endif
    [dy(i) ycalc(i) yref(i)] = process_output_one(db{i},:,:,0);
  endfor

  ## Continue on error?
  if (exist("errcontinue","var") && errcontinue)
    idx = find(isinf(ycalc));
    if (!isempty(idx))
      for i = idx
        yref(i) = db{i}.ref;
        ycalc(i) = db{i}.ref;
        dy(i) = 0;
        srun = [srun i];
      endfor
      nerr += length(idx);
    endif
  endif

  ## Save the result of this calculation into the global variable
  ycur = ycalc;

  ## Send the inputs and outputs to the stash
  stash_inputs_outputs(ycalc);

  ## Calculate the cost function, use the weights
  wei = zeros(length(db),1);
  for i = 1:length(db)
    wei(i) = db{i}.wei;
  endfor
  y = sum(wei .* dy.^2);

  ## Print summary to output
  if (exist("fixnorm","var") && fixnorm > 0)
    py = y + muk * (sum(x(2:2:end).^2) / fixnorm^2 - 1)^2;
  else
    py = y;
  endif
  printf("#x0# | %2d | %5d | %15.7f | %15.7f | %7.4f | %7.4f | %7.4f | %7.4e | %d | %d |\n",...
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

  ## Save this DCP to the stash
  writedcp(dcp,sprintf("%s/%s_%4.4d.dcp",prefix,prefix,nstep));

  ## Write the DCP if this is the best we have
  if (py < costmin)
    if (length(dcpfin) > 0)
      writedcp(dcp,dcpfin);
    endif
    costmin = py;
    if (length(dcpeval) > 0)
      fid = fopen(dcpeval,"w");
      fprintf(fid,"| Id | Name | weig | yref | ycalc | dy |\n")
      for i = 1:length(db)
        fprintf(fid,"| %d | %s | %.4f | %14.8f | %14.8f | %.4f |\n",...
                i,db{i}.outname,wei(i),yref(i),ycalc(i),dy(i))
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
