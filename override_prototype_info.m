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
## @deftypefn {} {@var{retval} =} override_prototype_info (@var{prototype_info}, @var{override})
## 
## Override prototype information created by @code{extract_prototype_info_from_h_file}.
## 
## @var{prototype_info}: struct returned by @code{extract_prototype_info_from_h_file}.
##
## @var{override}: struct array containing the fields to override. Some times the
## function @code{extract_prototype_info_from_h_file} will create an argument that
## does not correspond with the C function's use of that argument. For example:
## for an argument @code{double result[]}, this function will create an input argument
## to the C function. However, the argument might be a pointer to a previously-allocated
## array of doubles. In that case, one should override the fields of this argument.
## See @code{create_prototypes} for more details.
##
## @seealso{create_prototypes, extract_prototype_info_from_h_file}
## @end deftypefn

function retval = override_prototype_info (prototype_info, override)
  
  for i = 1:numel (override) % for each function name to override
    for j = 1:numel (prototype_info) % go through each function name
      
      % if found the function to override
      if (strcmp (override(i).function_name, prototype_info(j).function_name) == 1)
        
        % for each argument to override in this function
        for k = 1:numel (override(i).args)
          arg_number = override(i).arg_number(k).arg_number;
          
          prototype_info(j).args(arg_number) = override(i).args(k);
        endfor
      endif
    endfor
  endfor
  retval = prototype_info;
endfunction
