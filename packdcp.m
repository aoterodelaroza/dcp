function x = packdcp(dcp)
  %% function x = packdcp(dcp)
  %%
  %% Pack the DCP coefficients into an array for the minimization 
  %% routine.

  x = [];
  for i = 1:length(dcp)
    for j = 1:dcp{i}.nblock
      for k = 1:dcp{i}.block{j}.nterm
        x = [x dcp{i}.block{j}.exp(k) dcp{i}.block{j}.coef(k)];
      endfor
    endfor
  endfor

endfunction
