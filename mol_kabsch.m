% Copyright (C) 2011 Victor Lua~na and Alberto Otero-de-la-Roza
%
% This octave routine is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or (at
% your option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

function rmsd = mol_kabsch(x0, x1, allow_inversion=0)
% function rmsd = mol_align_kabsch(mol0, mol1, allow_inversion=0)
%
% mol_kabsch - rotate the first molecule in order to minimize the rmsd
% of the atomic distances to the second molecule. The two molecules
% must have the same number of atoms and the atoms must be ordered in
% the same way. Uses Kabsch algorithm. Returns the RMSD of the atomic
% positions. x0 and x1 have 3 rows and nat columns.
%
% Input variables:
% mol0: molecule to be rotated.
% mol1: target molecule
% allow_inversion: if 1, permit the application of an inversion operation
% to match the two molecules. Warning: if mol0 is chiral, it is
% converted to its enantiomer.
%
% Output variables:
% rmsd: the RMS betwen the two molecules.

  n0 = columns(x0);
  if (rows(x0) != rows(x1) || columns(x0) != columns(x1))
    error("inconsistent number of atoms in mol0 and mol1")
  endif

  a = x0 * x1';
  [v,s,w] = svd(a);
  d = sign(det(w * v'));
  mat = [1 0 0; 0 1 0; 0 0 d];
  u = w * mat * v';
  rmsd = sum(sum((u * x0 - x1).^2)) / 3 / n0;

  if (allow_inversion)
    mat = [1 0 0; 0 1 0; 0 0 -d];
    u2 = w * mat * v';
    rmsd2 = sum(sum((u * x0 - x1).^2)) / 3 / n0;
    if (rmsd2 < rmsd)
      rmsd = rmsd2
      u = u2
    endif
  endif

  rmsd = sqrt(rmsd);

endfunction
