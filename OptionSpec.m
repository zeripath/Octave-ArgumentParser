% OPTIONSPEC is a handle class to represent an option for the
% ArgumentParser
%
% This class is inspired by python argparse. An OptionSpec is
% created by the add_argument call, and parameters passed to that
% function are passed to the constructor of this.
%
% Arguments:
%
% [1] name: This should be a string or cell array of strings
% preceded by '-' or '--' for an option or not preceded by these
% for a positional option. Options should either be positional or
% not.
%
% Parameters:
%
% Parameters are passed in in usual Matlab style,
% i.e. "'ParamName', Value" not "ParamName=Value".
%
% 'nargs': The number of arguments needed, either numeric or one of
% {'?', '*', '+'}
%
% 'default': A default value for the option if it is not set.
%
% 'required': Whether the option is required to be set. Values can
% be true or false. It is not recommended to set this option for
% non-positional options.
%
% 'help': A help string to describe the option.
%
% 'metavar': A name for the argument in usage messages. (Defaults to
% the 'dest' value.)
%
% 'dest': The name of the option on the output structure
% representing the parsed arguments. (Defaults to the longest name
% of the option, slightly munged to be an acceptable field name for
% matlab.)
%
% 'validator': A validator function to run on each value set for
% this option returning true or false. (This is run once all
% potential values for all options have been set.)
%
% 'action': A function run after a value has been set to an
% option. This function takes the OptionSpec as a argument. No
% return is expected.
classdef OptionSpec < handle
  properties
    name;
    nargs = 1;
    default;
    default_is_set = 0;
    required=0;
    positional=0;
    help;
    metavar;
    dest;
    validator;
    value;
    is_set = 0;
    action;
  end
  methods
    function obj = OptionSpec(name, varargin)
        p = inputParser;
        % Basic validation functions
        %
        % A valid MATLAB identifier is a string of alphanumerics
        % (A–Z, a–z, 0–9) and underscores, such that the first
        % character is a letter and the length of the string is
        % less than or equal to namelengthmax.
        is_valid_first = @(x) ~isempty(findstr(upper(x), ...
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
        is_valid_other = @(x) ~isempty(findstr(upper(x), ...
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'));
        is_valid_name_other = @(x) ~isempty(findstr(upper(x), ...
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'));
        if exist('namelengthmax', 'builtin') == 5
            is_valid_field = @(x) is_valid_first(x(1)) && ...
                all(arrayfun(is_valid_other, x)) && length(x) <= ...
                namelengthmax;
        else
            is_valid_field = @(x) is_valid_first(x(1)) && ...
                all(arrayfun(is_valid_other, x));
        end
        name_validator = @(x) ...
            (is_valid_first(x(1)) && all(arrayfun(is_valid_name_other, x))) || ...
            (x(1) == '-' && length(x) > 1 && is_valid_first(x(2)) && ...
            all(arrayfun(is_valid_name_other, x))) || ...
            (length(x) > 2 && x(1) == '-' && x(2) == '-' && ...
            is_valid_first(x(3)) && all(arrayfun(is_valid_name_other, ...
            x)));
        option_validator = @(x) name_validator(x) && x(1) == '-';
        positional_validator = @(x) ischar(x) && x(1) ~= '-';
        % Add the name parameter
        p.addRequired('name', @(x) (ischar(x) && name_validator(x)) || ...
            (iscell(x) && ...
            (all(cellfun(@(y) option_validator(y), x)) || ...
            all(cellfun(@(y) positional_validator(y), x)) )));
        % Add the other optional parameters
        p.addParamValue('nargs', [1], @(x) isnumeric(x) || ...
            (ischar(x) && (x == '?' || x == '+' || x == '*')));
        p.addParamValue('default',[]);
        p.addParamValue('required', false, @(x) islogical(x));
        p.addParamValue('help','');
        p.addParamValue('metavar','');
        p.addParamValue('dest','', @(x) isempty(x) || is_valid_field(x));
        p.addParamValue('validator', @() true, @(x) isa(x, ...
            'function_handle'));
        p.addParamValue('action', @() true, @(x) isa(x, ...
            'function_handle'));
        p.parse(name, varargin{:});
        %
        obj.name = p.Results.name;
        if ischar(obj.name)
            obj.name = {p.Results.name};
        end
        obj.positional = positional_validator(obj.name{1});
        obj.nargs = p.Results.nargs;
        obj.default = p.Results.default;
        if ~any(strcmp(p.UsingDefaults, 'default'))
            obj.default_is_set = 1;
        end
        obj.required = p.Results.required;
        if ischar(obj.nargs)
        end
        obj.help = p.Results.help;
        obj.metavar = p.Results.metavar;
        obj.dest = p.Results.dest;
        obj.action = p.Results.action;
        if isempty(obj.dest)
            names = cellfun(@(x) {obj.strip_preceding(x)}, obj.name);
            obj.dest = names{ ...
                cellfun(@length, names) - max(cellfun(@length, names)) ...
                + 1 > 0};
            if ~is_valid_field(obj.dest)
                if ~is_alpha(obj.dest(1))
                    obj.dest = ['x' obj.dest];
                end
                obj.dest(~arrayfun(is_valid_other, obj.dest)) = ...
                    '_';
                if exist('namelengthmax', 'builtin') == 5 && ...
                        length(obj.dest) > namelengthmax
                    obj.dest = obj.dest(1:namelengthmax);
                end
            end
        end
        if isempty(obj.metavar)
            if obj.positional
                obj.metavar = obj.dest;
            else
                obj.metavar = upper(obj.dest);
            end
        end

        obj.validator = p.Results.validator;
    end
    function str = strip_preceding(obj, name)
        if name(1) == '-'
            if length(name) > 2 && name(2) == '-'
                str = name(3:end);
            else
                str = name(2:end);
            end
        else
            str = name;
        end
    end
    function out = is_ok(obj, prog)
        if obj.required && ~obj.is_set
            out = 0;
            disp([prog ': error: argument ' obj.dest ' is required.']);
            return;
        elseif ~obj.positional && ~obj.is_set
            out = 1;
            return;
        end
        switch obj.nargs
          case {'?', '*'}
            out = 1;
          case {'+'}
            out = length(obj.value) > 0;
            if ~out
                disp([prog ': error: argument ' obj.dest ' is required.']);
            end
        end
        if isnumeric(obj.nargs)
            out = obj.nargs <= length(obj.value);
            if ~out
                disp([prog ': error: ' num2str(obj.nargs) ' ' obj.dest ...
                    ' required.']);
            end
        end
    end
    function str = usage_option(obj)
        if ~obj.required && ~obj.positional
            str = [ '[' obj.string_option() ']' ];
        else
            str = obj.string_option();
        end
    end
    function str = options_option(obj)
        str = obj.string_option(1);
        for i=2:length(obj.name)
            str = [str ', ' obj.string_option(i)];
        end
    end
    function str = string_option(obj, index)
        if ~exist('index', 'var')
            index = 1;
        end

        str = '';
        if ~obj.positional
            str = [obj.name{index} ' '];
        end

        if ischar(obj.nargs)
            switch obj.nargs
              case {'?'}
                str = [ str '[' obj.metavar ']'];
              case {'+'}
                str = [ str obj.metavar ' [' obj.metavar ' ...]'];
              case {'*'}
                str = [ str '[' obj.metavar ' [' obj.metavar ' ...]]'];
            end
        elseif obj.nargs > 0
            str = [ str obj.metavar];
            for i=2:obj.nargs
                str = [ str ' ' obj.metavar];
            end
        end
    end
  end
end
