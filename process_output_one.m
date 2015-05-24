function [dy ycalc yref] = process_output_one(ent)
  %% function [dy ycalc yref] = process_output_one(ent,dcp)
  %%
  %% Read the Gaussian output for database entry ent. The
  %% output file should have been generated by Gaussian after 
  %% a call to run_inputs. Depending on the type of entry, evaluate
  %% the result (ycalc, e.g. calculate the energy) and compare to the 
  %% reference in the database (yref, e.g. the reference energy). 
  %% dy = ycalc - yref.

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

    ycalc = (e2 - e1a - e1b) * h2k;
    yref = ent.ref;
    dy = ycalc - yref;
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction


