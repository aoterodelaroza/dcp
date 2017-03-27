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

function acp = makeacp(atom,l,exp,coef)
  %% function acp = makeacp(atom,l,exp,coef)
  %%
  %% Make a ACP with a single term for a given atom, channel
  %% (l, s, p, d), exponent, and coefficient.

  global ferr

  llabel = {"local","s","p","d"};

  if (strcmpi(l,"l"))
    il = 1;
  elseif (strcmpi(l,"s"))
    il = 2;
  elseif (strcmpi(l,"p"))
    il = 3;
  elseif (strcmpi(l,"d"))
    il = 4;
  endif

  acp = cell();
  acp{1} = struct();
  acp{1}.atom = atom;
  acp{1}.name = atom;
  acp{1}.nblock = il;
  acp{1}.block = cell(1,il);
  for i = 1:il
    acp{1}.block{i}.name = llabel{i};
    if (i == il)
      acp{1}.block{i}.nterm = 1;
      acp{1}.block{i}.n = [2];
      acp{1}.block{i}.exp = [exp];
      acp{1}.block{i}.coef = [coef];
    else
      acp{1}.block{i}.nterm = 0;
      acp{1}.block{i}.n = [];
      acp{1}.block{i}.exp = [];
      acp{1}.block{i}.coef = [];
    endif
  endfor
  acp{1}.nelec = 0;
  acp{1}.nparam = 2;

end
