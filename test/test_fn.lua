require 'torch'
require 'fn'


function tests.test_count()
    local coll = {1, 2, 3, 4}

    tester:asserteq(fn.count({}), 0, "count empty {}")
    tester:asserteq(fn.count(coll), 4, "count coll")
end


function tests.test_is_empty()
    local coll = {1, 2, 3, 4}

    tester:asserteq(fn.is_empty({}), true, "is_empty of {}")
    tester:asserteq(fn.is_empty(coll), false, "is_empty of coll")
end


function tests.test_accessors()
    local coll = {1, 2, 3, 4}
    local nested = {{2, 3}, {4, 5}, 6}

    tester:asserteq(fn.first(coll), 1, "first of coll")
    tester:asserteq(fn.second(coll), 2, "second of coll")
    tester:asserteq(fn.last(coll), 4, "last of coll")

    tester:assertTableEq(fn.take(3, coll), {1,2,3}, "take 3 of coll")
    tester:assertTableEq(fn.drop(2, coll), {3, 4}, "drop 2 of coll")
end


function tests.test_fns()
    local foo = function(a, b, c) return a + b + c end
    local twox = function(v) return v * 2 end

    local comped = fn.comp(twox, foo)
    tester:asserteq(12, comped(1, 2, 3), "compose two functions")

    local adder = fn.partial(foo, 1, 2)
    tester:asserteq(6, adder(3), "partial application of arguments")

    tester:asserteq(6, fn.apply(foo, {1, 2, 3}), "apply a fn to a table of args")
    tester:asserteq(6, fn.apply(foo, 1, 2, {3}), "apply a fn to a table of args")
    tester:asserteq(6, fn.apply(foo, 1, {2, 3}), "apply a fn to a table of args")
end


function tests.seq_fns()
    local coll = {1,2,3,4,5}
    local twox = function(v) return v * 2 end

    local mapped = fn.map(twox, coll)
    tester:assertTableEq(mapped, {2, 4, 6, 8, 10}, "map a function over a table")

    local filtered = fn.filter(fn.partial(fn.gt, 3), coll)
    tester:assertTableEq(filtered, {4, 5}, "filter a table")

    local reduced = fn.reduce(fn.add, 0, coll)
    tester:asserteq(reduced, 15, "reduce a table by addition")
end



