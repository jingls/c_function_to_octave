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
## @deftypefn {} {@var{retval} =} extract_documentation (@var{texinfo_path})
## 
## Extract documentation contained between @code{@@deftypefun} and
## @code{@@end deftypefun}
## from all the .texi files present in the directory @var{texinfo_path}.
##
## @seealso{}
## @end deftypefn

function retval = extract_documentation (texinfo_path)
   
  texi_list = ls ([texinfo_path filesep "*.texi"]);
  if (numel (texi_list) <= 0)
    error(["Could not find texi files in: " texinfo_path]);
  end
  
  [nr, nc] = size (texi_list);
  
  count = 1; % function count
  
  for i = 1 : nr
    filename = strtrim(texi_list(i, :));
    
    if (numel (filename) <= 0) % the last line may be empty
      continue;
    end
    
    % filename is the name of the .texi file. Extract the documentation that
    % is contained between '@deftypefun' and '@end deftypefun'.
    cell_str = file_into_cellstr (filename);
    
    [ncr, ncc] = size (cell_str);
    
    pattern = "^@deftypefun";
    pattern_end = "^@end deftypefun";
    line = 1;
    while (line < ncc)
      line = line + 1;
    
      line_begin = 0;
      line_end = 0;
      
      % check if this line starts with '@deftypefun'
      strline = cell_str{line};
      [regexp_idx] = regexp (strline, pattern);
      
      if (numel (regexp_idx) > 0) % found the beginning of a function declaration
        line_begin = line;
        j = line;
        do
          j = j + 1; % go to the next line
          if (j > ncc)
            continue;
          endif
          
          strline = cell_str{j}; % get the next line
          [regexp_idx] = regexp (strline, pattern_end); % see if it starts with the pattern
          if (numel (regexp_idx) > 0) % found the end of a function declaration
            line_end = j;
          endif
        until (numel (regexp_idx) > 0)
      endif
      
      if (line_begin > 0 && line_end > 0)
        line = line_end;
        fcn_lines = [line_begin]; % save all the lines that have a function declaration
        
        % skip the multiple function declarations for the same documentation
        % similar functions may share the same documentation. For example:
        % @deftypefun int gsl_sf_mathieu_Mc (int @var{j}, int @var{n}, double @var{q}, double @var{x})
        % @deftypefunx int gsl_sf_mathieu_Mc_e (int @var{j}, int @var{n}, double @var{q}, double @var{x}, gsl_sf_result * @var{result})
        i = line_begin + 1;
        do
          fcn_lines = [fcn_lines i];
          
          strline = cell_str{i};
          [regexp_idx] = regexp (strline, pattern);
          i = i + 1;
        until (numel (regexp_idx) == 0) % skip until there is not a '@deftypefun'
      
        begin_doc = i - 1; % i is one line advanced
        documentation = cstrcat (cell_str{begin_doc:line_end - 1});
        
        % for each line in fcn_lines
        for i = fcn_lines(1:end-1)
          % split between function name and the rest
          [tok, rem] = strtok (cell_str{i}, "("); % split between '@deftypefun', return, function name and arguments
          [tok, rem] = strtok (tok, " "); % split between '@deftypefun' and return, function name
          [tok, rem] = strtok (strtrim (rem), " "); % split between return and function name
          retval(count).function_name = strtrim (rem);
          retval(count).documentation = documentation;
          count = count + 1;
        endfor
      endif
    endwhile
  endfor
endfunction
