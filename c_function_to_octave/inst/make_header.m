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
## @deftypefn {} {@var{retval} =} make_header (@var{category})
##
## @seealso{}
## @end deftypefn

function retval = make_header (category)
  retval = ["\
#include <limits>\n\
#include <octave/oct.h>\n\
#include <octave/parse.h>\n\
\n\
#define ISREAL(x) ((x).isreal ())\n\
\n\
DEFUN_DLD (" category ", args, nargout,\n\
  \"-*- texinfo -*-\\n\\\n\
@deftypefn {Loadable Function} " category " ()\\n\\\n\
" category " is an oct-file containing Octave bindings \\\n\
to C functions.\\n\\\n\
@end deftypefn\\n\\\n\")\n\
{\n\
  octave::feval (\"help\", octave_value (\"" category "\"));\n\
  return octave_value();\n\
}\n\
\n\
\n\
template <typename A>\n\
bool check_arg_dim\n\
(\n\
 A arg,\n\
 dim_vector &dim,\n\
 octave_idx_type &numel,\n\
 bool &conformant\n\
)\n\
{\n\
  dim_vector arg_dim = arg.dims ();\n\
  octave_idx_type arg_numel = arg.numel ();\n\
\n\
  // If this is a scalar argument, nothing more to do.\n\
  // The return value indicates that this is a scalar argument.\n\
  if (arg_numel == 1)\n\
    return true;\n\
\n\
  if (numel == 1)\n\
  {\n\
    dim = arg_dim;\n\
    numel = arg_numel;\n\
  }\n\
  else if (arg_dim != dim)\n\
  {\n\
    conformant = false;\n\
  }\n\
  return false;\n\
}\n\
\n\
"];
endfunction

%!test
%! fid_out = fopen ("header.cc", "w");
%! fputs (fid_out, make_header ("performcalculationcategory"));
%! fclose (fid_out);
