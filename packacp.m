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

function x = packacp(acp)
  %% function x = packacp(acp)
  %%
  %% Pack the ACP coefficients into an array for the minimization 
  %% routine.

  x = [];
  for i = 1:length(acp)
    for j = 1:acp{i}.nblock
      for k = 1:acp{i}.block{j}.nterm
        x = [x acp{i}.block{j}.exp(k) acp{i}.block{j}.coef(k)];
      endfor
    endfor
  endfor

endfunction
