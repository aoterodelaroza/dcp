## Copyright (C) 2014 Olaf Till <i7tiol@t-online.de>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn{Function File} {[@var{stop}, @var{info}] =} __do_user_interaction__ (@var{user_funcs}, @var{p}, @var{hook}, @var{state})
## Undocumented internal function.
## @end deftypefn

function [stop, ret_info] = __do_user_interaction__ ...
      (user_funcs, p, hook, state)

  n = numel (user_funcs);

### current cellfun chokes on this for anonymous functions with two
### outputs:
###
###  idx = num2cell ((1:n).');
###
###  [stop_cell, info_cell] = ...
###      cellfun (@ (id, p, hook, state) user_funcs{id} (p, hook, state),
###               idx, {p}, {hook}, {state}, "UniformOutput", false);
###
###  stop_vec = cell2mat (stop_cell);
###
### so use this loop instead:

  stop_vec = false (n, 1);
  info_cell = cell (n, 1);

  for id = 1 : n

    [stop_vec(id), info_cell{id}] = user_funcs{id} (p, hook, state);

  endfor

###

  stop = any (stop_vec);

  ret_info.stop = stop_vec;
  ret_info.info = info_cell;

endfunction
