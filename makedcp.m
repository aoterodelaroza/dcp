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

function dcp = makedcp(atom,l,exp,coef)
  %% function dcp = makedcp(atom,l,exp,coef)
  %%
  %% Make a DCP with a single term for a given atom, channel
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

  dcp = cell();
  dcp{1} = struct();
  dcp{1}.atom = atom;
  dcp{1}.name = atom;
  dcp{1}.nblock = il;
  dcp{1}.block = cell(1,il);
  for i = 1:il
    dcp{1}.block{i}.name = llabel{i};
    if (i == il)
      dcp{1}.block{i}.nterm = 1;
      dcp{1}.block{i}.n = [2];
      dcp{1}.block{i}.exp = [exp];
      dcp{1}.block{i}.coef = [coef];
    else
      dcp{1}.block{i}.nterm = 0;
      dcp{1}.block{i}.n = [];
      dcp{1}.block{i}.exp = [];
      dcp{1}.block{i}.coef = [];
    endif
  endfor
  dcp{1}.nelec = 0;
  dcp{1}.nparam = 2;

end
