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
## @deftypefn {} {@var{retval} =} single_function_to_octave (@var{str_call}, @var{c_file}, @var{documentation})
##
## @seealso{}
## @end deftypefn

function retval = single_function_to_octave (str_call, c_file, documentation)
  
  defaults.is_pointer.output = 1;
  [return_type, function_name, args] = extract_c_call (str_call, defaults);

  prototype_info.return_type = return_type;
  prototype_info.function_name = function_name;
  prototype_info.args = args;
  prototype_info.documentation = documentation;

  category = [function_name "_category"];

  doc = 'Category documentation.';
  code.pre = '// Code that goes before calling the C function';
  code.post = '// Code that goes after calling the C function';
  prepend_name = '';
  retval = call_generate_c_files (prototype_info, doc, code, prepend_name, category);
  
  template_filename = build_template_filename (prototype_info);
  file_out = [template_filename "_oct.cc"];
  
  oct_file = [category ".cc"];
  copyfile ("header.cc", oct_file);
  
  fid_out = fopen (oct_file, "a");
  
  % we need to add the function declaration before calling it
  cell_str = file_into_cellstr (c_file);
  fputs (fid_out, strjoin (cell_str, ""));
  
  % add the newly created code that calls the C function
  cell_str = file_into_cellstr (file_out);
  fputs (fid_out, strjoin (cell_str, ""));
  fclose (fid_out);
  
  category_oct = [category ".oct"];
  autoload (function_name, category_oct, "remove");
  
  [output, status] = mkoctfile (oct_file);
  
  % needed when loading from an oct file
  autoload (function_name, category_oct);

endfunction

%!test
%! c_file = "perform_calculation.c";
%! fid_out = fopen (c_file, "w");
%! str_function = ["double perform_calculation (double a, double b) { return a + b; }"];
%! fputs (fid_out, str_function);
%! fclose(fid_out);
%! output_file = "double_perform_calculation_double_real_double_real_oct.cc";
%! delete (output_file);
%! addpath ("../../../../octavetools/inst");
%! str_call = 'double perform_calculation (double a, double b);';
%! documentation = "Return the sum of a and b.";
%! retval = single_function_to_octave (str_call, c_file, documentation);
%! observed = perform_calculation (1, 2);
%! expected = 3;
%! assert (observed, expected);
