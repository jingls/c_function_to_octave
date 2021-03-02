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
## Gs.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn  {} {@var{retval} =} generate_c_file (@var{return_info}, @var{file_out}, @var{args}, @var{doc}, @var{code}, @var{prepend_name}, @var{category})
##
## Generate wrapper templates for C functions to be called within Octave.
##
## Use this if you have a C function that needs to be called within Octave. It
## creates C/C++ code that can be compiled with mkoctfile. See
## @uref{https://octave.org/doc/v6.1.0/Getting-Started-with-Oct_002dFiles.html, Getting Started with Oct-Files}.
##
## The general procedure of this function is:
## @table @asis
## @item Pre-processing
## Check that the inputs have the correct type, correct
## dimensions, and that the inputs are within the limits. Convert from Octave's
## variable representation to C representation. Allocate memory for pointers
## if necessary.
##
## @item C function call
## Call the C function.
##
## @item Post-processing
## Convert results from C back to Octave's representation; deallocate
## memory when necessary.
## Return: sometimes the result is returned by the C function, other times
## the result is in a pointer, or muliple results in multiple pointers.
## @end table
##
## The arguments to @code{generate_c_file} are:
##
## @table @asis
## @item @var{return_info}
## Indicates the type of return of the C function and if
## that return is sent back to Octave or not.
## The argument is a struct with two fields. The first field, called type,
## indicates the type of return. For example: void, int, double.
## The second field, called do_return, indicates if that return goes back to
## Octave or not. It can be 1 or 0.
## For example: return_info.type = "void"; return_info.do_return = 0;
## "double" and 0 will not send the return to Octave (disregard).
## "double" and 1 will send the return to Octave.
##
## @item @var{file_out}
## The template file name.
##
## @item @var{args}
## @var{args} is a struct array with elements T0, T1, T2, ... T(N-1),
## which are the input arguments to the C function.
## Tx is a struct composed of the following fields: type, output,
## real, scalar, const, and nelements.
##
## The field @code{type} indicates the type, for example: int, double, struct_name
## (for a struct), class_name (for a class), enum. If the field is struct, class,
## or enum, the calling input should be a string, which will be sent over to the
## C function.
## 
## The field @code{is_pointer} indicates if the argument is a pointer. It can be 1 or 0.
## 
## The field @code{output} indicates if the argument should be used as an output.
## That is useful if the argument is a pointer and the C function stores
## its output on this pointer. It can be 1 or 0.
##
## The field @code{real} indicates if the argument should be real. It can be 1
## or 0. If 1, a check will be performed on the argument and if it is not real,
## the function will show an error and return.
##
## The field @code{scalar} indicates if the argument should be scalar. It can be 1
## or 0. If 1, a check will be performed on the argument and if it is not scalar,
## the function will show an error and return.
##
## The field @code{nelements} (string) indicates the number of elements that the argument
## will contain, or zero if not applicable. It should be greater than zero if the
## argument is a pointer and needs to be returned to Octave. If it is zero, then
## the contents of the allocated memory will not be returned to Octave.
## @code{nelements} indicates the number of elements to be allocated in the case
## of a pointer, or zero if it is not applicable.
## If the number is above zero, memory will be allocated with malloc, used, and
## deallocated before returning. For example, 0, 1, 10. This parameter
## can be a number or a valid C expression indicating how the number of bytes should
## be computed. One possible C expression could be to use the value from
## another input. In the template, inputs are named args(0), args(1), ..., args(N-1).
## For example, if we have a C function like:
## int compute (double input[], size_t input_len, double *result, size_t result_len)
## Then the size of @code{result} should be @code{result_len} * sizeof (double),
## so the argument for result would be:
## @qcode{"double, pointer, 1 and 'args(3).scalar_value () * sizeof (double)'"},
## where 'args(3).scalar_value ()' is result_len.
## If result_len is not available, for example:
## int compute (double input[], size_t input_len, double *result)
## Then the size of result could be the same size as the input array, so the
## argument for result would be: @qcode{"double, pointer, 1, sizeof(arg0)"} or
## @qcode{"double, pointer, 1, arg1"}.
##
## @item @var{doc}
## Documentation for the function.
##
## @item @var{code}
## Struct containing a field @code{pre} to be executed at the beginning, and a
## field @code{post} to be performed before returning. They should be valid C/C++
## expressions or empty strings if not applicable.
##
## @item @var{prepend_name}
## A name to prepended to the export strings or an empty string.
## @end table
## 
## Behavior of pointer arguments:
## If the argument is a pointer (char * str), the assumption is that it is not
## an input. For the argument to be an input, it needs to be an array (char str[]).
## Behavior 1: int func (char * str); and nelements != "0" then:
## Array<char> str (dim_vector (nelements, 1));
## char *arg0 = str.fortran_vec ();
## The lines above allow the C function to access the pointer.
##
## @seealso{}
## @end deftypefn

function retval = generate_c_file (return_info, file_out, args, doc, code, prepend_name, category)
  
  str_out = ["\n\
// DO NOT EDIT! Created by generate_c_file.m\n\
// Input to this script:\n\
// return_info.type: " return_info.type "\n\
// return_info.do_return: " num2str(return_info.do_return) "\n\
// return_info.function_name: " return_info.function_name "\n\
"];

  for i = 1:numel (args)
    str_out = [str_out "\
// args(" num2str(i) ").name          : " args(i).name "\n\
// args(" num2str(i) ").type          : " args(i).type "\n\
// args(" num2str(i) ").const         : " num2str(args(i).const) "\n\
// args(" num2str(i) ").is_pointer    : " num2str(args(i).is_pointer) "\n\
// args(" num2str(i) ").output        : " num2str(args(i).output) "\n\
// args(" num2str(i) ").real          : " num2str(args(i).real) "\n\
// args(" num2str(i) ").scalar        : " num2str(args(i).scalar) "\n\
// args(" num2str(i) ").nelements     : " args(i).nelements "\n\n\
"];
  endfor
  
  str_out = [str_out "\
// PKG_ADD: autoload (\"" return_info.function_name "\", which (\"" category "\"));\n\
DEFUN_DLD (" return_info.function_name ", args, nargout, \n\
  \"-*- texinfo -*-\\n\\\n"];
  
  nargs = numel (args); % number of arguments
  
  outputs_mat = [];
  scalar_mat = [];
  real_mat = [];
  noutputs = 0;
  
  if (nargs > 0)
    _fieldnames = fieldnames (args(i));
    args_cell = struct2cell (args); % args_cell = {11x1x3 Cell Array} (rows, cols, arg#)
    output_row = find (strcmp(_fieldnames, "output")); % position of the output field
    outputs_mat = cell2mat (args_cell (output_row, :));
    noutputs = sum (outputs_mat);
    
    scalar_row = find (strcmp(_fieldnames, "scalar")); % position of the scalar field
    scalar_mat = cell2mat (args_cell (scalar_row, :));
    real_row = find (strcmp(_fieldnames, "real")); % position of the real field
    real_mat = cell2mat (args_cell (real_row, :));
  endif
  
  ## Build the list of output variables
  ## the output of this section is either:
  ## "" , "@var{z} =", or "[@var{z1}, @var{z2}, @var{z3}, ...] ="
  return_var = "y";
  outvars = "";
  if (return_info.do_return == 0 && noutputs == 0) % no return
    outvars = "";
    
  elseif (return_info.do_return == 1 && noutputs == 0) % function return
    outvars = ["@var{" return_var "} ="];
    
  elseif (return_info.do_return == 0 && noutputs == 1) % one return
    for i = 1:numel (args)
      if (args(i).output == 1)
        arg_name = args(i).name;
        outvars = ["@var{" arg_name "} ="];
        break;
      endif
    endfor
    
  else  % multiple returns
    outvars = [outvars "["];
    count = 0;
    if (return_info.do_return == 1)
      count = count + 1;
      outvars = [outvars "@var{" return_var "}"];
    endif
    comma = "";
    
    for i = 1:numel (args)
      if (count > 0)
        comma = ", ";
      endif
      if (args(i).output == 1)
        count = count + 1;
        arg_name = args(i).name;
        outvars = [outvars comma "@var{" arg_name "}"];
      endif
    endfor
    outvars = [outvars "] ="];
  endif
  
  str_out = [str_out "@deftypefn {Loadable Function} {" outvars "} " return_info.function_name " ("];
  
  args_str = "";
  for i = 1:nargs
    if (i > 1)
      args_str = [args_str ", "];
    endif
    arg_name = args(i).name;
    args_str = [args_str "@var{" arg_name "}"];
  endfor
  

  ## Add documentation specific for this function
  str_out = [str_out args_str "\
)\\n\\\n\
\\n\\\n\
" return_info.documentation "\\n\\\n\
\\n\\\n"];

  ## Add documentation related to the category or the whole package
  str_out = [str_out doc "\\n\\\n"];

  str_out = [str_out "\
@end deftypefn\\n\\\n\
\")\n\
{\n\
//#ifdef HAVE_" prepend_name "FUNC\n\
\n"];

  ## Add pre code
  str_out = [str_out code.pre];
  
  str_out = [str_out "\
\n\
  // Expected number of input arguments\n\
  const int nargs = " num2str(nargs) "; // number of arguments\n\
\n\
  // Check the actual number of input arguments\n\
  if (args.length () != nargs)\n\
    {\n\
      print_usage ();\n\
      return octave_value ();\n\
    }\n\
\n\
"];

  ## check for real inputs. This code is exactly the same as scalar
  real_str = "";
  if any (real_mat(:)) % if any of the inputs is real
    % get the first argument that is real
    first_real_idx = find (real_mat(:), 1);
    
    real_str = ["\
  // Check that the required arguments are real\n\
  for (int i = 0; i < nargs; i++)\n\
    {\n\
      if (i == " num2str(first_real_idx - 1) ];
      
    for i = (first_real_idx + 1):nargs
      
      if (real_mat(i) == 1)
        real_str = [real_str " || i == " num2str(i - 1) ];
      endif
    endfor
    real_str = [real_str ")\n\
      {\n\
        if (! ISREAL(args(i)))\n\
          {\n\
            error (\"Input argument #%d is not real.\", i + 1);\n\
            print_usage ();\n\
            return octave_value ();\n\
          }\n\
      }\n\
    }\n\n"];
  endif
    
  str_out = [str_out real_str];

  % check for scalar inputs
  scalar_str = "";
  if any (scalar_mat(:)) % if any of the inputs is scalar
    % get the first argument that is scalar
    first_scalar_idx = find (scalar_mat(:), 1);
    
    scalar_str = ["\
  // Check that the required arguments are scalar\n\
  for (int i = 0; i < nargs; i++)\n\
    {\n\
      if (i == " num2str(first_scalar_idx - 1) ];
      
    for i = (first_scalar_idx + 1):nargs
      
      if (scalar_mat(i) == 1)
        scalar_str = [scalar_str " || i == " num2str(i - 1) ];
      endif
    endfor
    scalar_str = [scalar_str ")\n\
      {\n\
        if (! args(i).is_scalar_type ())\n\
          {\n\
            error (\"Input argument #%d is not scalar.\", i + 1);\n\
            print_usage ();\n\
            return octave_value ();\n\
          }\n\
      }\n\
    }\n"];
  endif
    
  str_out = [str_out scalar_str];
  
  % Convert parameters from Octave's representation to C function's representation
  str_inputs = "";
  str_free = "";
  
  % when there is an argument type that is not primitive, there needs to be a conversion
  % from that type back to one of Octave's types.
  set_call_convert = zeros (1, numel(args)); % set call convert function for arg(i)
  
  convertible_types = {"int", "double", "float", "bool", "char", "std::string", "Complex", "size_t"};
    
  for i = 1:numel(args)
    str_inputs = [str_inputs "\n\n\
    // Get the value of input argument #" num2str(i)];
    
    nelements = args(i).nelements;
    scalar = args(i).scalar;
    i_str = num2str(i);
      
    % if the arg type is composed of multiple words, for example, unsigned int,
    % we check only the last word which is the type minus the modifier
    arg_type_cstr = strsplit (args(i).type, " ");
    arg_type = arg_type_cstr{end};
    
    if (scalar == 1 && !args(i).is_pointer)
      
      str_inputs = [str_inputs "\n\
    // i: " num2str(i) ". args(i).type: " args(i).type ". arg_type: " arg_type];
      
      % if this arg type is not in the list of convertible types
      if (!in (arg_type, convertible_types))
        % create an object of the type and convert
        str_inputs = [str_inputs "\n\
    " args(i).type " arg" i_str ";\n\
    convert_from_octave (args(" num2str(i - 1) "), arg" i_str ");"];
      else % if it is in the list of convertible types
        str_inputs = [str_inputs "\n\
    double arg" i_str "_dbl = args(" num2str(i - 1) ").scalar_value ();"]; % double arg5_dbl = args(4).scalar_value ();
      endif
    
      % is 'type' in this list of types? Check for overflow
      if (any (strcmp (arg_type, {"int", "unsigned int", "size_t"})))
        str = check_overflow_upp (i, args(i).type, fmt (args(i).type));
        str_inputs = [str_inputs str];
      endif
      
      % is 'type' in this list of types? Check for positivity
      if (any (strcmp (args(i).type, {"unsigned long", "unsigned int", "size_t"})))
        str = check_positivity (i);
        str_inputs = [str_inputs str];
      endif
      
      % if this arg type is not in the list of convertible types
      if (!in (arg_type, convertible_types))
        % do nothing
      else % if it is anything else then do static_cast
        str_inputs = [str_inputs "\n\
    " args(i).type " arg" i_str " = static_cast<" args(i).type "> (arg" i_str "_dbl);"]; % size_t arg5 = static_cast<size_t> (arg5_dbl);
      endif
      
      % is 'type' in this list of types? Check for integrity
      if (any (strcmp (args(i).type, {"int", "unsigned int", "size_t"})))
        str = check_integer (i);
        str_inputs = [str_inputs str];
      endif
    
    % if the argument is an array, but not pointer, and not output, then we use data ()
    % or if the argument is a const pointer, and not output, then we use data (). For example, 'const double * data',
    % meaning that the array or pointer is an array of input provided by the user to
    % the Octave function, which can be accessed by using the method 'data ()'
    elseif ((!scalar) && !args(i).is_pointer && args(i).output == 0
      || args(i).const && args(i).is_pointer && args(i).output == 0)
      
      % if the type is one of the convertible types, simply call the 'data ()' method,
      % otherwise, convert the array. In that case, there should be a conversion function
      % in the respective header file.
      if (in (arg_type, convertible_types))
        str_inputs = [str_inputs "\n\    // case malloc1 a\n"];
        str_inputs = [str_inputs "\n\
    const " args(i).type " * arg" i_str " = args(" num2str(i - 1) ").array_value ().data();"];
      else
        str_inputs = [str_inputs "\n\    // case malloc1 b\n"];
        str_inputs = [str_inputs "\n\
    size_t arg" i_str "_nelements = args(" num2str(i - 1) ").numel (); // newww\n\
    size_t arg" i_str "_size = args(" num2str(i - 1) ").numel () * sizeof (" args(i).type "); // newww\n\
    " args(i).type " * arg" i_str " = (" args(i).type " *) malloc (arg" i_str "_size); // newww\n\
    convert_from_octave (args(" num2str(i - 1) "), arg" i_str ", arg" i_str "_nelements);"];
    % function free will be called before returning
    str_free = [str_free "\n\
  free (arg" i_str ");\n"];
      
      endif
    
    % if the argument is a pointer and nelements is not zero and it is not an output then do malloc
    elseif (args(i).is_pointer == 1 && strcmp (nelements, "0") == 0 && args(i).output == 0)
      str_inputs = [str_inputs "\n\    // case malloc2\n"];
      str_inputs = [str_inputs "\n\
    size_t arg" i_str "_size = " nelements " * sizeof (" args(i).type ");\n\
    size_t arg" i_str "_nelements = " nelements ";\n\
    " args(i).type " * arg" i_str " = (" args(i).type " *) malloc (arg" i_str "_size);"];
    
      % function free will be called before returning
      str_free = [str_free "\n\
  free (arg" i_str ");\n"];
    
    % if the argument is a pointer and nelements is not zero and it is an output
    elseif (args(i).is_pointer == 1 && strcmp (nelements, "0") == 0 && args(i).output == 1)
      str_inputs = [str_inputs "\n\    // case malloc3\n"];
      str_inputs = [str_inputs "\n\
    size_t arg" i_str "_size = " nelements " * sizeof (" args(i).type ");\n\
    size_t arg" i_str "_nelements = " nelements ";\n\
    " args(i).type " * arg" i_str " = (" args(i).type " *) malloc (arg" i_str "_size);"];
    
      % function free will be called before returning
      str_free = [str_free "\n\
  free (arg" i_str ");\n"];
      
      % later we need to convert from 'args(i).type' back to Octave's representation
      set_call_convert(i) = 1;
    
    % if the argument is a pointer and nelements is zero, and there is special
    % pre-processing or post-processing of this argument. For example, if the argument
    % is 'myclass * myclass_ptr' and (args(i).pre != "" or args(i).post != "")
    % then, for example, the field 'pre' can instantiate an object, call any initiallization
    % procedure, or perform any preprocessing on that object.
    elseif (args(i).is_pointer == 1 && strcmp (nelements, "0") == 1 &&
      (numel (args(i).pre) > 0 || numel (args(i).post) > 0))
      str_inputs = [str_inputs "\n\
    " args(i).pre "\n"];
    
    % if the argument is a pointer and nelements is zero,
    % then create a single object of that type and pass its pointer to the C function
    elseif (args(i).is_pointer == 1 && strcmp (nelements, "0") == 1)
      str_inputs = [str_inputs "\n\
    " args(i).type " arg" i_str "_obj;\n\
    " args(i).type " * arg" i_str " = &arg" i_str "_obj;\n"];
      
    else
      str_inputs = [str_inputs "\n\
      Error!!!! Cannot proceed. Check generate_c_file.m\n"];
      
    endif
  endfor
    
  str_out = [str_out str_inputs];
  
  % Declare result array
  str_results = "";
  str_results = [str_results "\n\n\
  // Declare the variable where the results are stored\n"];
  
  if (return_info.do_return == 1 && strcmp (return_info.type, "void") == 0) % return from the C function
    str_results = [str_results "\
  " return_info.type " y;\n"];
  else
    str_results = [str_results "\n\
  "];
  endif
  
  str_out = [str_out str_results];

  % C function call
  str_call = "";
  if (return_info.do_return == 1 && strcmp (return_info.type, "void") == 0) % return from the C function
    str_call = [str_call "\n\
  y = "];
  endif

  str_call = [str_call return_info.function_name " ("];
  
  for i = 1:numel (args)
    str_call = [str_call "arg" num2str(i)];
    if (i < numel(args))
      str_call = [str_call ", "];
    endif
  endfor
  
  str_call = [str_call ");\n"];
  
  str_out = [str_out str_call];
  
  % Post-processing and Return
  str_post = "";
  
  str_out = [str_out str_post];
  
  str_return = "";
  
  % always return, even if it is an empty list
  str_return = [str_return "\n\
  octave_value_list retval;\n"];
  retval_pos = 0;
  
  if (return_info.do_return == 1 && strcmp (return_info.type, "void") == 0) % if there is a return from the C function
    
    % If the return of the C function is of a type that cannot be directly used by
    % one of the octave_value constructors, then there needs to be a conversion
    % function defined in the header file. We call this conversion function here.
    % Look at ov.h for all octave_value constructors.
    if (!in (return_info.type, convertible_types))
      % call the conversion function
      str_return = [str_return "\n\
  retval(" num2str(retval_pos) ") = convert_to_octave (y);\n"];
    else
      str_return = [str_return "\n\
  retval(" num2str(retval_pos) ") = octave_value (y);\n"];
    endif
    retval_pos = retval_pos + 1;
  endif

  if (noutputs > 0) % if there is a pointer-type of output
  
    for i = 1:numel (args)
      if (args(i).output == 1) % if this argument is an output
        
        % for types that are accepted in octave_value's constructors, we can simply
        % use the constructor. But for classes, enums, structs, we can't create an
        % octave_value from that. So, there needs to be a conversion from that type
        % to one of Octave's representation. Either a struct or a class.
        % So if argi is not of a convertible type, we call its convertor function,
        % which should be defined by the user.
        
        % if it is not a pointer, for example, double arg1; then simply create an octave_value for it
        if (args(i).is_pointer == 0)
          str_return = [str_return "\n\
  retval(" num2str(retval_pos) ") = octave_value (arg" num2str(i) ");\n"];
          retval_pos = retval_pos + 1;
          
        % if it is a pointer and number of elements == 0
        % it is a pointer of a single object that has been created before
        % if it is an output, then add to the output list
        elseif (args(i).is_pointer == 1 && strcmp (args(i).nelements, "0") == 1 && args(i).output == 1) % args(i).output is checked in the previous if.
  
          if (!in (args(i).type, convertible_types))
            % call the conversion function
            str_return = [str_return "\n\
  retval(" num2str(retval_pos) ") = convert_to_octave (arg" num2str(i) "_obj);\n"];
          else
            str_return = [str_return "\n\
  retval(" num2str(retval_pos) ") = octave_value (arg" num2str(i) "_obj);\n"];
          endif
          retval_pos = retval_pos + 1;
          
        % if it is a pointer and number of elements != 0
        elseif (args(i).is_pointer == 1 && strcmp (args(i).nelements, "0") == 0)
          str_return = [str_return "\n\
  dim_vector dim_" num2str(i) " (1, arg" num2str(i) "_nelements);\n\
  NDArray y" num2str(i) "_NDArray (dim_" num2str(i) ");\n\
  \n\
  // Copy vector from argi to NDArray. Is there a better/faster way?\n\
  // Maybe use fortran_vec with memcpy. But that will only work for double.\n\
  for (octave_idx_type i = 0; i < arg" num2str(i) "_nelements; i++)\n\
    {\n\
      y" num2str(i) "_NDArray(i) = arg" num2str(i) "[i];\n\
    }\n\
  retval(" num2str(retval_pos) ") = octave_value (y" num2str(i) "_NDArray);\n"];
          retval_pos = retval_pos + 1;
        else
          str_return = [str_return "\n\
      Error!!!! Trying to convert type \"" args(i).type "\" to Octave's representation. Unkown conversion. Cannot proceed. Check generate_c_file.m\n"];
          
        endif
        
      endif
    endfor
  endif

  % free any allocated memory just before returning
  str_return = [str_return str_free];
  
  % for arguments that have post-processing, do post-processing just before returning
  for i = 1:numel (args)
    if (numel (args(i).post) > 0)
      str_return = [str_return "\n\
  " args(i).post "\n"];
    endif
  endfor
  
  str_return = [str_return "\n\
  return retval;\n"];
  
  str_out = [str_out str_return];
  
  str_out = [str_out "\n\
//#else // HAVE_" prepend_name "FUNC undefined\n\
//\n\
//  error (\"'" prepend_name "FUNC_NAME' was missing when \"\n\
//         \"the package was compiled.\");\n\
//  return octave_value ();\n\
//\n\
//#endif // HAVE_" prepend_name "FUNC\n\
}\n"];

  fid_out = fopen (file_out, "w");

  fputs(fid_out, str_out);
  
  fclose(fid_out);
  
  retval = 1;
  
endfunction

function str_fmt = fmt (type)
  switch (type)
    case "int"
      str_fmt = "%d";
    case "unsigned int"
      str_fmt = "%u";
    case "size_t"
      str_fmt = "%lu";
    otherwise
##      str_fmt = "%s"; % unknown type
      str_fmt = "unknown type. Please add format to function 'str_fmt' in file 'generate_c_file.m'. \""; % unknown type. Give an error
  endswitch
endfunction

## Check upper overflow
## fmt is the printf format specifier
function str = check_overflow_upp (i, type, fmt)
  str = ["\n\n\
    if (arg" num2str(i) "_dbl > std::numeric_limits<" type ">::max ())\n\
      {\n\
        error (\"Input argument #" num2str(i) " exceeds the upper limit \"\n\
               \"for type " type ": " fmt ".\", std::numeric_limits<" type ">::max ());\n\
        print_usage ();\n\
        return octave_value ();\n\
      }"];
endfunction

## Check positivity
function str = check_positivity (i)
  str = ["\n\n\
    if (arg" num2str(i) "_dbl < 0)\n\
      {\n\
        error (\"Input argument #" num2str(i) " has a negative value. \"\n\
           \"A non-negative value was expected.\");\n\
        print_usage ();\n\
        return octave_value ();\n\
      }"];
endfunction

## Check integrity
function str = check_integer (i)
  str = ["\n\n\
    if ((static_cast<double> (arg" num2str(i) ")) != arg" num2str(i) "_dbl)\n\
      {\n\
        error (\"Input argument #" num2str(i) " has a non-integer value. \"\n\
          \"An integer value was expected.\");\n\
        print_usage ();\n\
        return octave_value ();\n\
      }"];
endfunction
