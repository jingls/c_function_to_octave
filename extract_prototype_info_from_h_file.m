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
## @deftypefn {} {@var{retval} =} extract_prototype_info_from_h_file (@var{input_file}, @var{defaults})
##
## Extract C function prototypes from an .h file.
## 
## @var{input_file}: file path of the .h file created by @code{create_prototypes}.
## 
## @var{defaults} (scalar structure) Contains default values for certain behaviors.
## See @code{extract_c_call} for more information.
## 
## Example of usage:
##
## @example
## @group
## input_file = ["." filesep "functions.h"];
## fid_out = fopen (input_file, "w");
## str_call = 'double gsl_stats_mean (const double data[], size_t stride, size_t n);';
## fputs (fid_out, str_call);
## fclose (fid_out);
## defaults.is_pointer.output = 1;
## prototype_info = extract_prototype_info_from_h_file (input_file, defaults);
## numel (prototype_info.args)
##       @result{} '3'
## @end group
## @end example
##
## @seealso{create_prototypes, extract_c_call}
## @end deftypefn

function retval = extract_prototype_info_from_h_file (input_file, defaults)
  
  if (nargin != 2)
    print_usage ();
  endif
  
  fid_in = fopen (input_file);
  if (fid_in == -1)
    error (["extract_prototype_info_from_h_file: unable to open \"" input_file "\""]);
  endif
  
  retval = []; % return empty matrix if nothing found. struct () will have one element
    
  % for each line containing a function prototype
  i = 1;
  while (i)
    
    fcn_prototype = fgets (fid_in); % read function prototype line
    if (fcn_prototype == -1) % -1 if end of file
      break;
    end
    fcn_prototype = strtrim (fcn_prototype);
    
    if (numel (fcn_prototype) <= 0) % empty line
      continue;
    endif
    
    % find information about the function based on its prototype
    [return_type, function_name, args] = extract_c_call (fcn_prototype, defaults);
    retval(i).return_type = return_type;
    retval(i).function_name = function_name;
    retval(i).args = args;
    
    i = i + 1;
  endwhile
  
  fclose(fid_in);
endfunction
