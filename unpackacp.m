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

function acp = unpackacp(x,acp0)
  %% function acp = unpackacp(x,acp0)
  %%
  %% Unpack the ACP coefficients from array x using template acp0.
  %% Return the ACP structure with the x coefficients and exponents.

  n = 0;
  acp = acp0;
  for i = 1:length(acp)
    for j = 1:acp{i}.nblock
      for k = 1:acp{i}.block{j}.nterm
        n++;
        acp{i}.block{j}.exp(k) = x(n);
        n++;
        acp{i}.block{j}.coef(k) = x(n);
      endfor
    endfor
  endfor

endfunction
