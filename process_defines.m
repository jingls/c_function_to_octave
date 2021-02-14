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
## @deftypefn {} {@var{str_out} =} process_defines (@var{header_file_path}, @var{category}, @var{category_name}, @var{out_file_path}, @var{append})
##
## Convert @code{#define} constants in header files to Octave functions.
##
## Look into the C/C++ header file @var{header_file_path} for lines beginning with
## @code{#define}. Extract the name of the define and the number. Convert the number
## to a double type. If the define's expression cannot be converted to double, disregard.
## 
## @var{out_file_path}: output .m file. The contents processed by this function
## will be appended to @var{out_file_path}.
##
## @var{append}: (1 or 0). If 1, append the functions converted from defines.
## If 0, also add a function at the beginning which has the same name of the file
## (for loaded functions).
## See @uref{https://octave.org/doc/v6.1.0/Getting-Started-with-Oct_002dFiles.html, Getting Started with Oct-Files}
##
## @seealso{}
## @end deftypefn

function str_out = process_defines (header_file_path, category, category_name, out_file_path, append)
  
  [h_directory, h_basename, h_ext] = fileparts (header_file_path);
  
  % keep in cell_str the definitions already present in out_file_path
  cell_str = {};
  if (exist (out_file_path, "file") == 2)
    cell_str = file_into_cellstr (out_file_path);
  endif
  
  % put into names, doubles the definitions. For example, #define MY_CONST 10
  pattern = "^#define";
  matching_lines = grep_file (header_file_path, pattern);
  [defines, rem] = strtok (strtrim (matching_lines), " ");
  [names, rem] = strtok (strtrim (rem), " ");
  doubles = str2double (rem);
  
  % the first function has to have the same name as the file
  [directory, basename, ext] = fileparts (out_file_path);
  func_name = tolower (basename);
  str_out = "\n";
  
  if (append == 0)
    str_out = [str_out "DEFUN_DLD (" func_name ", args, nargout, \"\\"];
    str_out = [str_out "  -*- texinfo -*-\n\\"];
    str_out = [str_out "  @deftypefn {Loadable Function} " func_name " ()\n"];
    str_out = [str_out "  " func_name " documentation.\n"];
    str_out = [str_out "  @end deftypefn\n\")\n"];
    str_out = [str_out "{\n"];
    str_out = [str_out "  return octave_value ();\n"];
    str_out = [str_out "}\n"];
  endif
  
  for i = 1:numel(doubles)
    if (!isnan (doubles(i)))
      
      pattern = ["function retval = " names{i}];
      matching_lines = grep_cell (cell_str, pattern);
      
      if (numel (matching_lines) > 0) % found the define
        continue;
      endif
      func_name = tolower (names{i});
      
      str_out = [str_out "\n// PKG_ADD: autoload (\"" func_name "\", which (\"" category "\"));\n\
DEFUN_DLD(" func_name ", args, nargout, \"\\\n\
  -*- texinfo -*-\\n\\\n\
@deftypefn {Loadable Function} {@var{z} =} " func_name " ()\\n\\\n\
\\n\\\n\
" func_name " is a constant with the value of " num2str(doubles(i)) ",\\n\\\n\
 defined in " h_basename h_ext ".\\n\\\n\
\\n\\\n\
@end deftypefn\\n\\\n\
\")\n\
{\n\
  return octave_value (" num2str(doubles(i)) ");\n\
}\n"];
    endif
  endfor
  
  mode = "w";
  if (append == 1)
    mode = "a";
  endif
  
  fid_out = fopen (out_file_path, mode);
  fputs (fid_out, str_out);
  fclose(fid_out);
endfunction
