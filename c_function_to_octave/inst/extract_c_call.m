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
## @deftypefn {} {[@var{return_type}, @var{function_name}, @var{args}] =} extract_c_call (@var{str_call}, @var{defaults})
##
## Extract information from a function prototype.
##
## @var{str_call} (string) the calling string of the C function prototype.
##
## @var{defaults} (scalar structure) Contains default values. For example, if a
## pointer is found by the script, the default behavior is to assign that argument
## as not output. That behavior can be overriden by specifying a default variable
## containing a field 'is_pointer', and the field 'is_pointer' containing a field
## output = 1.
## For example: @code{defaults = struct (); defaults.is_pointer.output = 1;}
## @code{defaults = struct ();} is still necessary even if no defaults are specified.
##
## @var{return_type} (string) return type of the C function.
## If the return type of the C function is composed of multiple words, for example,
## @code{unsigned int}, then @var{return_type} will be a string containing all those words.
##
## @var{function_name} (string) the name of the C function.
##
## @var{args} (struct array) the arguments of the C function. See
## @code{generate_template} for more information.
##
## Each struct has the fields:
## 
## type: string with the type of argument, for example: "double", "size_t".
## 
## is_pointer: (1 or 0) indicating if the argument is a pointer (1) or not (0).
## If the argument is a pointer and not marked const, and the C function has no
## return (void), then set the argument's output field as 1.
## 
## name: string with the name of the argument, for example: n, data, stride.
## 
## pre: indicates pre-processing of this argument. This field is empty after
## returning from this function. It should be overriden if necessary.
## 
## post: indicates post-processing of this argument. This field is empty after
## returning from this function. It should be overriden if necessary.
## 
## Example of usage:
##
## @example
## @group
## defaults.is_pointer.output = 1;
## str_call = 'double perform_calculation(double a, double b);';
## [return_type, function_name, args] = extract_c_call (str_call, defaults);
## disp (args(1).name);
##       @result{} 'data'
## @end group
## @end example
##
## @seealso{generate_template}
## @end deftypefn

function [return_type, function_name, args] = extract_c_call (str_call, defaults)
  
  if (nargin != 2)
    print_usage ();
  endif
  
  return_type = "";
  function_name = "";
  args = []; % empty matrix means zero elements. 'struct ()' will have one element.
  
  % split between return type and the rest
  [tok, rem] = strtok (str_call, "(");
  cstr = strsplit (strtrim (tok)); % split the return type, function name by whitespace
  function_name = cstr{end}; % function name is the last element
  if (numel (cstr) == 2)
    return_type = cstr{1};
  else
    return_type = strjoin (cstr(1:end-1), " ");
  endif
  
  rem = regexprep (strtrim (rem), "^\\(", ""); % replace the first occurence of '('
  rem = regexprep (strtrim (rem), ";$", ""); % replace the last occurence of ';'
  rem = regexprep (strtrim (rem), "\\)$", ""); % replace the last occurence of ')'
  rem = strtrim (rem);
  
  if (numel (rem) == 0 || (strcmp (rem, "void") == 1)) % function has no arguments
    return;
  endif
  
  args_cstr = strsplit (strtrim (rem), ","); % split between arguments
  
  args_cstr = strtrim (args_cstr); % remove leading and trailing spaces
  
  for i = 1 : numel (args_cstr)
    
    args(i).pre = "";
    args(i).post = "";
    args(i).real = 1;
    args(i).nelements = "0";
    args(i).scalar = 1;
    
    [cstr] = strsplit (args_cstr{i}, " ");

    % test if argument is const
    pos = 1;
    args(i).const = 0;
    if (strcmp (cstr{pos}, "const"))
      args(i).const = 1;
      pos = pos + 1;
    endif
    
    % test if argument has a modifier
    % modifiers can contain up to three words. For example, 'unsigned long long int'
    % https://gcc.gnu.org/onlinedocs/gcc/Long-Long.html#Long-Long
    modifiers = {"signed", "unsigned", "long", "short"};
    modifier = "";
    while (pos <= numel (cstr) && in (cstr{pos}, modifiers))
      modifier = [modifier cstr{pos} " "];
      pos = pos + 1;
    endwhile
    
    args(i).type = cstr{pos};
    pos = pos + 1;
    
    % test if argument is a pointer
    args(i).is_pointer = 0;
    if (numel (cstr) >= pos)
      if (strcmp (cstr{pos}, "*"))
        args(i).is_pointer = 1;
        pos = pos + 1;
      endif
    end
    
    % There is no meaning in testing if the argument is real when the argument type
    % is a struct, class or enum.
    % Here is the list of types that can be tested for realness.
    real_types = {"double", "float", "int", "size_t"};
    if (!in (args(i).type, real_types))
      args(i).real = 0;
    endif
    
    args(i).type = [modifier args(i).type];
    
    args(i).output = 0;
    
    % if the argument is a pointer we can't check if it is scalar or real
    if (args(i).is_pointer == 1)
        args(i).scalar = 0;
        args(i).real = 0;
    endif
    
    % if there is a pointer argument and the C function doesn't return anything,
    % it is probable that the pointer is one of the outputs of the C function
    if (args(i).is_pointer == 1 && strcmp (return_type, "void") == 1)
      args(i).output = 1;
      
      % if this argument is a pointer and an output, we don't know if it is real
      % or scalar, so don't assume, set to 0.
      args(i).real = 0;
      args(i).scalar = 0;
      
      % if this argument is a pointer and an output, we don't know what is the
      % memory size that needs to be allocated. The nelements field should be
      % overriden, so for now set it to 1.
      args(i).nelements = "1";
    endif
    
    % if this argument is marked const and pointer, do not change the output field
    % if this argument is not marked const and is a pointer and there is a default,
    % then change the output field
    if (args(i).const == 0 && args(i).is_pointer == 1 && isfield (defaults, "is_pointer")
      && isfield (defaults.is_pointer, "output"))
      args(i).output = defaults.is_pointer.output;
    endif
    
    % at this point we need to check for variadic function, in which the last
    % argument is '...'. If that is the case, then the name of the argument will
    % be '...'.
    if (numel (cstr) == 1 && strcmp (cstr, "..."))
      args(i).name = "...";
      args(i).is_array = 0;
      continue;
    endif
    
    % take the name of the argument, put it in name, take the rest put it in rest
    % data[]
    [name, rem] = strtok (cstr{pos}, "[");
    
    args(i).name = name;
    
    % if find the brakets, it means the argument is an array
    isarray = 0;
    if (strfind (rem, "[]") > 0)
      isarray = 1;
    end
    args(i).is_array = isarray;
    
    if (isarray == 1)
      args(i).scalar = 0;
    endif
  endfor
endfunction

% Examples of C calls:
% double gsl_stats_mean (const double data[], size_t stride, size_t n);
% gsl_rstat_workspace * gsl_rstat_alloc (void);
% gsl_multifit_linear_workspace * gsl_multifit_linear_alloc (const size_t n, const size_t p);
% int gsl_sf_airy_zero_Ai_e (unsigned int s, gsl_sf_result * result);

%!test
%! defaults.is_pointer.output = 1
%! str_call = 'void gsl_stats_minmax (double * min, double * max, const double data[], size_t stride, size_t n);'
%! [return_type, function_name, args] = extract_c_call (str_call, defaults)
%! assert (return_type, 'void')
%! assert (function_name, 'gsl_stats_minmax')
%! assert (args(1).name, '_min')
%! assert (args(1).type, 'double')
%! assert (args(1).is_pointer, 1)
%! assert (args(1).const, 0)
%! assert (args(1).output, 1)
%! assert (args(1).real, 0)
%! assert (args(1).is_array, 0)
%! assert (strcmp (args(1).nelements, "1") == 1)
%! assert (args(3).name, 'data')
%! assert (args(3).type, 'double')
%! assert (args(3).is_pointer, 0)
%! assert (args(3).const, 1)
%! assert (args(3).output, 0)
%! assert (args(3).real, 1)
%! assert (args(3).is_array, 1)
%! assert (strcmp (args(3).nelements, "0") == 1)
