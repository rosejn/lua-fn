# A collection of functional programming tools for Lua and Torch

Originally started with functional.lua, but slowly expanding as needed.

## Usage

    require 'fn'
    function mul(x, y) return x * y end
    double = fn.partial(mul, 2)
    double(10)  --> 20

    fn.map(double, {1,2,3}) --> {2, 4, 6}
~
