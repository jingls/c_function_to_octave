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
## @deftypefn {} {@var{retval} =} add_documentation (@var{prototype_info}, @var{documentations})
## 
## Add documentation from @var{documentations} to a set of C function prototypes
## given in @var{prototype_info}.
## 
## @var{prototype_info}: struct returned by @code{extract_prototype_info_from_h_file}.
## 
## @var{documentations}: struct returned by @code{extract_documentation}.
##
## @seealso{extract_prototype_info_from_h_file, extract_documentation}
## @end deftypefn

function retval = add_documentation (prototype_info, documentations)
  
  retval = prototype_info;
  
  for i = 1:numel (prototype_info) % for each function name to override
    retval(i).documentation = "";
    for j = 1:numel (documentations) % go through each function name
      
      % if found the function to add the documentation to
      if (strcmp (prototype_info(i).function_name, documentations(j).function_name) == 1)
        retval(i).documentation = documentations(j).documentation;
        break;
      endif
    endfor
  endfor
endfunction
