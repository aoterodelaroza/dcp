function [dy ycalc yref dery] = process_output_one(ent,derivs=0)
  %% function [dy ycalc yref dery] = process_output_one(ent,derivs=0)
  %%
  %% Read the Gaussian output for database entry ent. The
  %% output file should have been generated by Gaussian after 
  %% a call to run_inputs. Depending on the type of entry, evaluate
  %% the result (ycalc, e.g. calculate the energy) and compare to the 
  %% reference in the database (yref, e.g. the reference energy). 
  %% dy = ycalc - yref. The derivs parameter indicates the order
  %% of the derivatives to calculate.


  h2k = 627.50947;
  global prefix nstep

  if (strcmp(ent.type,"be_frozen_monomer"))
    ## Read the energy for the dimer
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      dy = ycalc = yref = Inf;
      return
    endif
    [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
    e2 = str2num(out);
    if (s != 0 || isempty(e2)) 
      dy = ycalc = yref = Inf;
      return
    endif

    ## Then the monomer 1
    if (ent.mon1.nat > 0)
      file = sprintf("%s_%4.4d_%s_mon1.log",prefix,nstep,ent.name);
      if (!exist(file,"file"))
        dy = ycalc = yref = Inf;
        return
      endif
      [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
      e1a = str2num(out);
      if (s != 0 || isempty(e1a)) 
        dy = ycalc = yref = Inf;
        return
      endif
    else 
      e1a = 0;
    endif

    ## Then the monomer 2
    if (ent.mon2.nat > 0)
      file = sprintf("%s_%4.4d_%s_mon2.log",prefix,nstep,ent.name);
      if (!exist(file,"file"))
        dy = ycalc = yref = Inf;
        return
      endif
      [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
      e1b = str2num(out);
      if (s != 0 || isempty(e1b)) 
        dy = ycalc = yref = Inf;
        return
      endif
    else
      e1b = 0;
    endif

    if (derivs == 0)
      ## Scalar calculation
      ycalc = (e2 - e1a - e1b) * h2k;
      yref = ent.ref;
      dy = ycalc - yref;
      dery = 0;
    else
      ## Derivatives calculation
      n = length(e2);
      if (length(e1a) != n)
        e1a = zeros(size(e2));
      endif
      if (length(e1b) != n)
        e1b = zeros(size(e2));
      endif

      ## The scalar value
      ycalc = (e2(1) - e1a(1) - e1b(1)) * h2k;
      yref = ent.ref;
      dy = ycalc - yref;

      ## Prepare for derivatives 
      n = length(e2)-2;
      if (abs(n-round(n)) > 1d-10)
        error("Length of the output array is not consistent. (2n+2, 2n+4)");
      endif
      e2_c = e2(3:n+2) - e2(2);
      e1a_c = e1a(3:n+2) - e1a(2);
      e1b_c = e1b(3:n+2) - e1b(2);
      be_c = (e2_c - e1a_c - e1b_c) * h2k;

      ## First derivatives
      dery = zeros(1,n);
      dery = be_c';
    endif
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
