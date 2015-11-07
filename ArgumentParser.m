classdef ArgumentParser < handle
% Command-line parsing library
%
% This class is inspired by python argparse:
% * handles both optional and positional arguments
% * produces highly informative usage messages
% * supports parsers that dispatch to sub-parsers
%
% The following is a simple usage example that sums integers from
% the command-line and writes the result to a file:
%
% parser = ArgumentParser('description','sum the integers at the command line');
% parser.add_argument(
%    'integers', metavar='int', nargs='+', type=int, help=['an integer ' ...
%        'to be summed']);
    properties
        prog;
        description;
        options = {};
        positional_options = {};
    end
    methods
        function obj = ArgumentParser(varargin)
            p = inputParser;
            p.addParamValue('description', '', @ischar);
            if exist('program_name', 'builtin')
                p.addParamValue('prog', program_name(), @ischar);
            else
                p.addParamValue('prog', '', @ischar);
            end

            p.parse(varargin{:});
            obj.description = p.Results.description;
            obj.prog = p.Results.prog;
            obj.add_argument({'-h', '--help'}, 'nargs', 0, 'help', ...
                'Show help documentation', 'action', @() obj.print_help_and_exit());
        end

        function obj = add_argument(obj, varargin)
            o = OptionSpec(varargin{:});
            if (o.positional)
                obj.positional_options(length(obj.positional_options) + 1) = o;
            else
                obj.options(length(obj.options) + 1) = o;
            end
        end

        function print_help(obj)
            fprintf(1, '%s', obj.usage());
            fprintf(1,'\npositional arguments:\n');
            cellfun(@(x) fprintf(1, '  %s\t\t%s\n', x.dest, x.help), ...
                obj.positional_options);
            fprintf(1,'\noptional arguments:\n');
            cellfun(@(x) fprintf(1, '  %s\t\t%s\n', x.options_option, x.help), ...
                obj.options);
        end

        function print_help_and_exit(obj)
            obj.print_help();
            exit();
        end

        function str = concatenate_strings(obj, cells)
            str = strcat(cells{:});
        end

        function str = usage(obj)
            str = sprintf('usage: %s', obj.prog);
            str = [str obj.concatenate_strings(cellfun(@(x) {sprintf(' %s', x.usage_option())}, ...
                obj.options))];
            str = [str obj.concatenate_strings(cellfun(@(x) {sprintf(' %s', x.usage_option())}, ...
                obj.positional_options))];
            str = [str sprintf('\n')];
        end

        function out = parse(obj, varargin)
            out = {};
            i = 1;
            if length(obj.options) > 0
                while i <= length(varargin)
                    next = varargin{i};
                    if ischar(next)
                        if strcmp(next, '--')
                            i = i +1;
                            % munch and end options
                            break;
                        elseif next(1) ~= '-'
                            % end of options
                            break;
                        else
                            option_cell = obj.options( ...
                                cellfun(@(x) any(strcmp(next, x.name)), obj.options) ...
                                );
                            if ~isempty(option_cell)
                                option = option_cell{1};
                                option.is_set = 1;
                                switch option.nargs
                                  case {'?'}
                                    if i + 1 <= length(varargin)
                                        next = varargin{i + 1};
                                        if next(1) ~= '-'
                                            option.value = {next};
                                            i = i + 1;
                                        end
                                    end
                                  case {'+', '*'}
                                    option.value = {};
                                    while i + 1 <= length(varargin)
                                        next = varargin{i + 1};
                                        if (next(1)) ~= '-'
                                            option.value{ ...
                                                length(option.value) ...
                                                + 1} = next;
                                            i = i + 1;
                                        else
                                            break;
                                        end
                                    end
                                end
                                if isnumeric(option.nargs) && ...
                                        option.nargs > 0
                                    value = {};
                                    j = 1;
                                    while i + j <= length(varargin) && ...
                                            j <= option.nargs
                                        next = varargin{i + j};
                                        if (next(1)) ~= '-'
                                            value{ ...
                                                length(option.value) ...
                                                + 1} = next;
                                            j = j + 1;
                                        else
                                            break;
                                        end
                                    end
                                    option.value = value;
                                    i = i + j - 1;
                                end
                                option.action(option);
                            end
                        end
                    else
                        % end of options
                        break;
                    end
                    i = i + 1;
                end
            end

            if length(obj.positional_options) > 0
                p = 1;
                while i <= length(varargin) && p <= length(obj.positional_options)
                    option = obj.positional_options{p};
                    switch option.nargs
                      case {'?'}
                        option.is_set = 1;
                        if i <= length(varargin)
                            next = varargin{i};
                            option.value = {next};
                            i = i + 1;
                        end
                      case {'+', '*'}
                        option.is_set = 1;
                        option.value = {};
                        while i <= length(varargin)
                            next = varargin{i};
                            option.is_set = 1;
                            option.value{ ...
                                length(option.value) ...
                                + 1} = next;
                            i = i + 1;
                        end
                    end
                    if isnumeric(option.nargs) && ...
                            option.nargs > 0
                        option.value = {};
                        option.is_set = 1;
                        j = 1;
                        while i <= length(varargin) && ...
                                j <= option.nargs
                            next = varargin{i};
                            option.value{ ...
                                length(option.value) ...
                                + 1} = next;
                            j = j + 1; i = i + 1;
                        end
                    elseif isnumeric(option.nargs) && option.nargs == 0
                        option.is_set = 1;
                        option.value = {};
                    end
                    if option.is_set
                        option.action(option);
                    end
                    p = p + 1;
                end
            end
            % Shortcut help at this point
            if obj.options{1}
            end
            % Now check whether the options have got the correct
            % settings
            all_ok = all(cellfun(@(x) x.is_ok(obj.prog), obj.options) && ...
                all(cellfun(@(x) x.is_ok(obj.prog), ...
                obj.positional_options)));
            for i=1:length(obj.options)
                option = obj.options{i};
                if option.is_set
                    out.(option.dest) = option.value;
                    for j = 1:length(option.value)
                        if ~option.validator(option.value{j})
                            fprintf(2, 'Invalid value for %s: %s\n', ...
                                option.dest, ...
                                option.value{j});
                            all_ok = 0;
                        end
                    end
                elseif option.default_is_set
                    out.(option.dest) = {option.default};
                end
            end

            for i = 1:length(obj.positional_options)
                option = obj.positional_options{i};
                if option.is_set
                    out.(option.dest) = option.value;
                    for j = 1:length(option.value)
                        if ~option.validator(option.value{j})
                            fprintf(2, 'Invalid value for %s: %s\n', ...
                                option.dest, ...
                                option.value{j});
                            all_ok = 0;
                        end
                    end
                elseif option.default_is_set
                    out.(option.dest) = {option.default};
                end
            end

            if ~all_ok
                error(obj.usage());
            end
        end
    end
end