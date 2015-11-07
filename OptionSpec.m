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
        name_validator = @(x) ischar(x) && ...
            ~(length(x) == 1 && x(1) == '-') && ...
            ~(length(x) == 2 && x(1) == '-' && x(2) == '-');
        option_validator = @(x) name_validator(x) && x(1) == '-';
        positional_validator = @(x) ischar(x) && x(1) ~= '-';
        p.addRequired('name', @(x) name_validator(x) || ...
            (iscell(x) && ...
            (all(cellfun(@(y) option_validator(y), x)) || ...
            all(cellfun(@(y) positional_validator(y), x)) )));
        p.addParamValue('nargs', [1], @(x) isnumeric(x) || ...
            (ischar(x) && (x == '?' || x == '+' || x == '*')));
        p.addParamValue('default',[]);
        p.addParamValue('required', false, @(x) islogical(x));
        p.addParamValue('help','');
        p.addParamValue('metavar','');
        p.addParamValue('dest','');
        p.addParamValue('validator', @() true, @(x) isa(x, ...
            'function_handle'));
        p.addParamValue('action', @() true, @(x) isa(x, ...
            'function_handle'));
        p.parse(name, varargin{:});
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
        if length(obj.dest) == 0
            names = cellfun(@(x) {obj.strip_preceding(x)}, obj.name);
            obj.dest = names{ ...
                cellfun(@length, names) - max(cellfun(@length, names)) + 1 > 0};
        end
        if length(obj.metavar) == 0
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
            if length(name) > 3 && name(2) == '-'
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
