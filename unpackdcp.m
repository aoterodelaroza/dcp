function dcp = unpackdcp(x,dcp0)
  %% function dcp = unpackdcp(x,dcp0)
  %%
  %% Unpack the DCP coefficients from array x using template dcp0.
  %% Return the DCP structure with the x coefficients and exponents.

  n = 0;
  dcp = dcp0;
  for i = 1:length(dcp)
    for j = 1:dcp{i}.nblock
      for k = 1:dcp{i}.block{j}.nterm
        n++;
        dcp{i}.block{j}.exp(k) = x(n);
        n++;
        dcp{i}.block{j}.coef(k) = x(n);
      endfor
    endfor
  endfor

endfunction
