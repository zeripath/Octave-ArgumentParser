# Argument Parser for Octave/Matlab

This is a very basic and incomplete implementation of python's argparse and
ArgumentParser in the m-language of octave and matlab.

# How-to use
    p = ArgumentParser('prog', 'argparse', ...
      'description', 'A simple argument parser');
    p.add_argument('integers', 'metavar', 'N', 'nargs','+', ...
    'help', 'an integer for the accumulator')
    opts = p.parse(arg_list{:});


Parameters to ArgumentParser are in Matlab format i.e. (..., 'param', 'value', ...)

The folowing parameters are available:
* `prog`: Set the program name for the help documentation. This cannot be easily
set automatically
* `description`: Set the program description for the automatically generated help

To add an Argument to the parser, use the `add_argument` method, the first argument
of which is the name of the option. Use cell list for multiple names eg.
`{'-o', '--option'}`. The following parameters are available:
* `nargs`: The number of arguments expected, either: `'+'`, `'?'`, `'*'` or an integer.
* `default`: A default value for the argument.
* `required`: Whether the option is required.
* `help`: A help string for the option.
* `metavar`: The variable name to use in the help file.
* `dest`: The destination name in the options struct returned by `parse`.
* `validator`: A function taking a potential value for the option and returning `true`
if acceptable.
* `action`: A function taking the `OptionSpec` object representing the option with its
value set as the `value` field.

The parsed values will be placed in the `dest` fields of the struct returned by `parse`.
Values will be placed in cell lists.
