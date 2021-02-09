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
## @deftypefn {} {} create_prototypes (@var{textinfo_path}, @var{output_path})
##
## Create prototypes of functions present in texinfo files.
##
## @var{textinfo_path} is the directory that contains all the *.texi files.
## For each .texi file, a corresponding .h file will be created in the
## @var{output_path} directory. The .h file will contain the C function prototypes.
## @seealso{process_texi}
## @end deftypefn

function create_prototypes (textinfo_path, output_path)
  mkdir (output_path);
  
  texi_list = ls ([textinfo_path filesep "*.texi"]);
  if (numel (texi_list) <= 0)
    error (["Could not find texi files in: " textinfo_path]);
  end
  
  [nr, nc] = size (texi_list);
  
  for i = 1 : nr
    filename = strtrim (texi_list(i, :));
    
    if (numel (filename) <= 0) % the last line may be empty
      continue;
    end
    
    [directory, basename, ext] = fileparts (filename);
    
    % Here we have the .texi file. Extract the function definition lines.
    pattern = "^@deftypefun";
    matching_lines = grep_file (filename, pattern);
    
    last_semicolon = "";
    if (numel (matching_lines) > 0)
      last_semicolon = ";";
    endif
    
    % Remove the word "@deftypefun" and "@deftypefunx"
    % Examples:
    % @deftypefun {gsl_multifit_linear_workspace *} gsl_multifit_linear_alloc (const size_t @var{n}, const size_t @var{p})
    % @deftypefunx int gsl_multifit_linear_wstdform1 (const gsl_vector * @var{L}, const gsl_matrix * @var{X}, const gsl_vector * @var{w}, const gsl_vector * @var{y}, gsl_matrix * @var{Xs}, gsl_vector * @var{ys}, gsl_multifit_linear_workspace * @var{work})
    % @deftypefun int gsl_multifit_linear_stdform1 (const gsl_vector * @var{L}, const gsl_matrix * @var{X}, const gsl_vector * @var{y}, gsl_matrix * @var{Xs}, gsl_vector * @var{ys}, gsl_multifit_linear_workspace * @var{work})
    [tok, rem] = strtok (matching_lines); % rem contains the function definitions
    
    % Remove leading and trailing whitespace
    newcstr = strtrim (rem);
    
    % NEWSTR = strrep (matching_lines, "@deftypefun ", "")
    % replace '@var{'
    newcstr = strrep (newcstr, "@var{", "");
    
    % replace '}'
    newcstr = strrep (newcstr, "}", "");
    
    % replace '{'
    newcstr = strrep (newcstr, "{", "");
    
    str = "";
    if (numel (matching_lines) > 0)
      str = strjoin (newcstr, ";\n");
    endif
    
    % save function definitions to out_file
    out_file = [output_path filesep basename ".h"];
    
    fid_out = fopen (out_file, "w");
    fputs (fid_out, [str last_semicolon]);
    fclose (fid_out);
  end
endfunction
