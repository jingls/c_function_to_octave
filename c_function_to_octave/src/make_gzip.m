## Copyright (C) 2021 Tallis Huther da Costa <tallis.hcosta@gmail.com>
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {} {@var{retval} =} make_gzip (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

function retval = make_gzip (input1, input2)
  % This script must executed inside the folder c_function_to_octave/src
  version = "1.0.0";
  package = "c_function_to_octave";
  new_dir = [package "-" version];
  copyfile (["../../" package], ["../../" new_dir]);
  tarfile = ["../../" package "-" version ".tar"];
  files = ["../../" package "-" version];

  tar (tarfile, files);
  gzip (tarfile);

  delete (tarfile);
  confirm_recursive_rmdir (false);
  rmdir (["../../" new_dir], "s");

endfunction
