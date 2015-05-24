function y = fbasic(x)
  %% function y = fbasic(x)
  %%
  %% Evaluation function for the minimization routine. This function is meant
  %% to be used as argument for one of the optim routines (like bfgsmin,
  %% minimize, or nonlin_min). The argument are the DCP coefficients
  %% and exponents, packed into a convenient array. The appropriate Gaussian
  %% calculations are carried out, and the cost function for the DCP
  %% given by x is calculated, and returned as y.
  
  global dcp db prefix nstep verbose run_inputs ycur dcpfin ...
         costmin usechk stime0 astep dcpeval
  
  ## Yet another function evaluation.
  nstep++;
  
  if (verbose)
    printf("### Iteration %d ### [ %s ]\n",nstep,strtrim(ctime(time())));
  endif

  ## Crash if any of the parameters is a nan
  if (any(isnan(x)))
    error(sprintf("Optimization procedure tried to use a NaN parameter in step %d\n",nstep));
  endif

  ## Unpack the DCP coefficients and exponents
  dcp = unpackdcp(x,dcp);

  ## Write the DCP to the output (if verbose)
  if (verbose)
    printf("# DCP for this iteration\n");
    writedcp(dcp);
  endif

  ## Create the prefix directory if it doesn't exist yet
  if (!exist(prefix,"dir"))
    [s out] = system(sprintf("mkdir %s",prefix));
    if (s != 0)
      error(sprintf("Could not create directory %s",prefix));
    endif
  endif

  ## If any of the exponents is positive, return Inf
  if (any(x(1:2:end) < 0))
    y = Inf;
    printf("#xx# | %2d | %5d | %15.7f | %7.4f | %7.4f | %7.4f | %d |\n",astep,nstep,y,Inf,Inf,Inf,time()-stime0);
    stime0 = time();
  else
    ## Set up the Gaussian input files
    ilist = {};
    for i = 1:length(db)
      ilist = [ilist, setup_input_one(db{i},dcp)];
    endfor
    if (verbose)
      printf("# Running the %d input files: \n",length(ilist));
    endif

    ## Prune the list to eliminate those inputs that are exactly the same
    ilist0 = ilist;
    ipoint = zeros(1,length(ilist0));
    ilist = {};
    for i = 1:length(ilist0)
      found = 0;
      for j = 1:i-1
        [s out] = system(sprintf("diff -q -I '^%%chk=' %s.gjf %s.gjf",ilist0{i},ilist0{j}));
        if (s == 0)
          found = 1;
          ipoint(i) = j;
          break
        endif
      endfor
      if (!found)
        ilist = {ilist{:} ilist0{i}};
      endif
    endfor

    ## Prepare the checkpoint files
    unstash_checkpoints(ilist)

    ## Run all inputs
    srun = run_inputs(ilist);

    ## Propagate outputs, unprune
    for i = 1:length(ilist0)
      if (ipoint(i))
        [s1 out] = system(sprintf("cp -f %s.log %s.log",ilist0{ipoint(i)},ilist0{i}));
        if (s != 0)
          error(sprintf("Could not propagate outputs %s.log -> %s.log",ilist0{ipoint(i)},ilist0{i}));
        endif
        if (usechk && exist(sprintf("%s.chk",ilist0{ipoint(i)}),"file"))
          [s out] = system(sprintf("cp -f %s.chk %s.chk",ilist0{ipoint(i)},ilist0{i}));
          if (s != 0)
            error(sprintf("Could not propagate outputs %s.log -> %s.log",ilist0{ipoint(i)},ilist0{i}));
          endif
        endif
      endif
    endfor
    ilist = ilist0;

    ## If any of the Gaussian outputs are wrong, return Inf to the caller
    if (srun != 0)
      y = Inf;
      stash_inputs_outputs(ilist);
      clear_checkpoints(ilist);
      printf("#xx# | %2d | %5d | %15.7f | %7.4f | %7.4f | %7.4f | %d |\n",astep,nstep,y,Inf,Inf,Inf,time()-stime0);
      stime0 = time();
      return
    endif

    ## Send checkpoint files to the stash
    stash_checkpoints(ilist)

    ## Collect the results and compare to the reference data
    dy = ycalc = yref = zeros(length(db),1);
    for i = 1:length(db)
      [dy(i) ycalc(i) yref(i)] = process_output_one(db{i});
    endfor
    ycur = ycalc;

    ## Send the inputs and outputs to the stash
    stash_inputs_outputs(ilist);

    ## Calculate the cost function, use the weights
    wei = zeros(length(db),1);
    for i = 1:length(db)
      wei(i) = db{i}.wei;
    endfor
    y = sum(wei .* dy.^2);

    ## Print summary to output
    printf("#xx# | %2d | %5d | %15.7f | %7.4f | %7.4f | %7.4f | %d |\n",astep,nstep,...
           y,sqrt(y/sum(wei)),sqrt(mean((yref-ycalc).^2)),mean(abs(yref-ycalc)),...
           time()-stime0);
    stime0 = time();
    if (verbose)
      printf("| Id | Name | weig | yref | ycalc | dy |\n")
      for i = 1:length(db)
        printf("| %d | %s | %.4f | %.4f | %.4f | %.4f |\n",...
               i,db{i}.name,wei(i),yref(i),ycalc(i),dy(i))
      endfor
    endif
    
    ## Save this DCP to the stash
    writedcp(dcp,sprintf("%s/%s_%4.4d.dcp",prefix,prefix,nstep));

    ## Write the DCP if this is the best we have
    if (y < costmin)
      if (length(dcpfin) > 0)
        writedcp(dcp,dcpfin);
      endif
      costmin = y;
      if (length(dcpeval) > 0)
        fid = fopen(dcpeval,"w");
        fprintf(fid,"| Id | Name | weig | yref | ycalc | dy |\n")
        for i = 1:length(db)
          fprintf(fid,"| %d | %s | %.4f | %.4f | %.4f | %.4f |\n",...
                  i,db{i}.name,wei(i),yref(i),ycalc(i),dy(i))
        endfor
        fprintf(fid,"# MAE = %.4f\n",mean(abs(yref-ycalc)));
        fprintf(fid,"# MAPE = %.4f\n",mean(abs((yref-ycalc)./yref))*100);
        fprintf(fid,"# RMS = %.4f\n",sqrt(mean((yref-ycalc).^2)));
        fprintf(fid,"# wRMS = %.4f\n",sqrt(sum(wei .* (yref-ycalc).^2)/sum(wei)));
        fprintf(fid,"# Cost function minimum: %.10f\n",costmin);
        fclose(fid);
      endif
    endif
  endif

endfunction
