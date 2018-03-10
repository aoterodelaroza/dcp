!% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
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

function sout = run_inputs_pass(ilist,xdmcoef=[],xdmfun="",extrad3="")
  %% function run_inputs_pass(ilist,xdmcoef=[],xdmfun="",extrad3="")
  %% 
  %% Run all the inputs in the job list (ilist). The jobs should be  
  %% in the current working directory, with extension gjf. 
  %% If xdmcoef is non-empty, run postg on the resulting wfx with
  %% the indicated parameters and the functional in xdmfun.
  %%
  %% This version does NOT run the inputs - it creates empty files.
  
  global ferr nstep prefix
  
  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# Start run_inputs_pass - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Create the empty files with zeros in them
  if (ferr > 0) 
    fprintf(ferr,"# Creating empty files - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif
  fid = -1;
  jobname = {};
  for i = 1:length(ilist)
    name = ilist{i};
    if (ferr > 0) 
      fprintf(ferr,"# file %d (%s) - %s\n",i,name,strtrim(ctime(time())));
      fflush(ferr);
    endif
    fid = fopen(sprintf("%s.log",name),"w");
    fprintf(fid," Charge=              0.0000 electrons\n");
    fprintf(fid," Dipole moment (field-independent basis, Debye):\n");
    fprintf(fid,"    X=              0.0000    Y=              0.0000    Z=              0.0000  Tot=              0.0000\n");
    fprintf(fid," Quadrupole moment (field-independent basis, Debye-Ang):\n");
    fprintf(fid,"   XX=              0.0000   YY=              0.0000   ZZ=              0.0000\n");
    fprintf(fid,"   XY=              0.0000   XZ=              0.0000   YZ=              0.0000\n");
    fprintf(fid," Traceless Quadrupole moment (field-independent basis, Debye-Ang):\n");
    fprintf(fid,"   XX=              0.0000   YY=              0.0000   ZZ=              0.0000\n");
    fprintf(fid,"   XY=              0.0000   XZ=              0.0000   YZ=              0.0000\n");
    fprintf(fid," Octapole moment (field-independent basis, Debye-Ang**2):\n");
    fprintf(fid,"  XXX=              0.0000  YYY=              0.0000  ZZZ=              0.0000  XYY=              0.0000\n");
    fprintf(fid,"  XXY=              0.0000  XXZ=              0.0000  XZZ=              0.0000  YZZ=              0.0000\n");
    fprintf(fid,"  YYZ=              0.0000  XYZ=              0.0000\n");
    fprintf(fid," Hexadecapole moment (field-independent basis, Debye-Ang**3):\n");
    fprintf(fid," XXXX=              0.0000 YYYY=              0.0000 ZZZZ=              0.0000 XXXY=              0.0000\n");
    fprintf(fid," XXXZ=              0.0000 YYYX=              0.0000 YYYZ=              0.0000 ZZZX=              0.0000\n");
    fprintf(fid," ZZZY=              0.0000 XXYY=              0.0000 XXZZ=              0.0000 YYZZ=              0.0000\n");
    fprintf(fid," XXYZ=              0.0000 YYXZ=              0.0000 ZZXY=              0.0000\n");
    fprintf(fid,"SCF Done:  E(HF) = 0.0     A.U. after    1 cycles\n");
    fprintf(fid,"Normal termination of Gaussian 09 at Tue Jan  1 00:00:01 1901.\n")
    fclose(fid);
    if (!isempty(xdmcoef))
      fid = fopen(sprintf("%s.pgout",name),"w");
      fprintf(fid,"dispersion energy   0.000000000000E+00\n");
      fprintf(fid,"scf energy   0.000000000000E+00\n");
      fprintf(fid,"total energy   0.000000000000E+00\n");
      fclose(fid);
    elseif (!isempty(extrad3))
      fid = fopen(sprintf("%s.d3out",name),"w");
      fprintf(fid," Edisp /kcal,au:    -0.0000 -0.00000000\n");
      fclose(fid);
    endif
  endfor

  ## Make a copy of the input files in the prefix_name directory
  [s out] = system(sprintf("mkdir %s_%4.4d",prefix,nstep));
  for i = 1:length(ilist)
    name = ilist{i};
    [s out] = system(sprintf("cp -f %s.gjf %s_%4.4d/",name,prefix,nstep));
  endfor

  ## No errors
  sout = [];

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# End run_inputs_elcap3 - %s\n",strtrim(ctime(time())));
    fflush(ferr);
  endif

endfunction
