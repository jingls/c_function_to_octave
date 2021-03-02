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
## @deftypefn {} {@var{template_filename} =} build_template_filename (@var{prototype_info})
##
## @seealso{}
## @end deftypefn

function template_filename = build_template_filename (prototype_info)
  
  % start with the output of the function
  fname = strrep (prototype_info.return_type, " ", "_");
  fname = [fname "_" prototype_info.function_name]; % function name
  
  for j = 1:numel (prototype_info.args)
    arg_type = strrep (prototype_info.args(j).type, " ", "_");
    
    array = "";
    if (prototype_info.args(j).is_array)
      array = "_arr";
    endif
    
    const = "";
    if (prototype_info.args(j).const)
      const = "_cst";
    endif
    
    pointer = "";
    if (prototype_info.args(j).is_pointer)
      pointer = "_ptr";
    endif
    
    real = ""; % check for real
    if (prototype_info.args(j).real)
      real = "_real";
    endif
    
    fname = [fname "_" arg_type array const pointer real];
  endfor
  template_filename = fname;
endfunction
