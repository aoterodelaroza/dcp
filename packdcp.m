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
