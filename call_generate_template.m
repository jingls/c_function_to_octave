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
## @deftypefn {} {@var{retval} =} call_generate_template (@var{prototype_info}, @var{doc}@var{code}, @var{prepend_name})
##
## @seealso{generate_template}
## @end deftypefn

function retval = call_generate_template (prototype_info, doc, code, prepend_name)

  for i = 1:numel (prototype_info)
    
    return_info.function_name = prototype_info(i).function_name;
    return_info.type = prototype_info(i).return_type;
    return_info.do_return = 1;
    if (strcmp (return_info.type, "void") == 1)
      return_info.do_return = 0;
    endif
    
    template_filename = build_template_filename (prototype_info (i));
    file_out = [template_filename ".template.cc"];
    
    if (exist (file_out, "file") == 2)
      disp(["Skipping template file " file_out]);
      continue;
    endif
    
    args = prototype_info(i).args;
    
    retval = generate_template (return_info, file_out, args, doc, code, prepend_name);
  endfor
endfunction
