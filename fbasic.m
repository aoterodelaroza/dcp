function y = fbasic(x)
  %% function y = fbasic(x)
  %%
  %% Evaluation function for the minimization routine. This function is meant
  %% to be used as argument for one of the optim routines (like bfgsmin,
  %% minimize, or nonlin_min). The argument are the DCP coefficients
  %% and exponents, packed into a convenient array. The appropriate Gaussian
  %% calculations are carried out, and the cost function for the DCP
  %% given by x is calculated, and returned as y.
  
  global dcp db prefix nstep verbose run_inputs ycur
  
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

  if (verbose)
    printf("# DCP for this iteration\n");
    writedcp(dcp);
  endif

  ## If any of the exponents is positive, return Inf
  if (any(x(1:2:end) < 0))
    y = Inf;
    if (verbose)
      printf("# Cost function: %.10f\n",y)
    endif
  else
    ## Set up the Gaussian input files
    ilist = {};
    for i = 1:length(db)
      ilist = [ilist, setup_input_one(db{i},dcp)];
    endfor
    if (verbose)
      printf("# Running the %d input files: \n",length(ilist));
    endif

    ## Run all inputs
    s = run_inputs(ilist);
    if (s != 0)
      y = Inf;
      stash_inputs_outputs(ilist);
      if (verbose)
        printf("# Cost function: %.10f\n",y)
      endif
      return
    endif

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
    y = sum(wei .* abs(dy));

    ## Print summary to output
    if (verbose)
      printf("| Id | Name | weig | yref | ycalc | dy |\n")
      for i = 1:length(db)
        printf("| %d | %s | %.4f | %.4f | %.4f | %.4f |\n",...
               i,db{i}.name,wei(i),yref(i),ycalc(i),dy(i))
      endfor
      printf("# Cost function: %.10f\n",y)
    endif
  endif

endfunction
