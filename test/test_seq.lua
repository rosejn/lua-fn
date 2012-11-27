require 'fn'
require 'fn/seq'


function tests.test_realizers()
    local coll = {a = 1, b = 2, c = 3}
    local res = seq.table(seq.keys(coll))
    table.sort(res)
    tester:assertTableEq(res, {'a', 'b', 'c'}, "test seq.table")
    -- TODO: can't really test seq.tensor like this because we can't guarantee
    -- the order that seq.vals will produce values...
    --tester:assertTensorEq(seq.tensor(coll), torch.Tensor({1, 2, 3}), 0,
    --                      "create a tensor from a seq")
end


function tests.test_map_fns()
    local coll = {a = 1, b = 2, c = 3}

    local keys = seq.keys(coll)
    local res = seq.table(keys)
    table.sort(res)
    tester:assertTableEq(res, {'a', 'b', 'c'}, "test keys")

    local vals = seq.vals(coll)
    local res = seq.table(vals)
    table.sort(res)
    tester:assertTableEq(res, {1, 2, 3}, "test keys")
end


function tests.test_takedrop()
    local coll = {1,2,3,4,5,6}

    local taken = seq.take(3, coll)
    tester:assertTableEq(seq.table(taken), {1,2,3}, "take 3")

    local dropped = seq.drop(3, coll)
    tester:assertTableEq(seq.table(dropped), {4,5,6}, "drop 3")

    taken = seq.take_while(fn.partial(fn.lt, 4), coll)
    tester:assertTableEq(seq.table(taken), {1,2,3}, "take_while v < 4")

    dropped = seq.drop_while(fn.partial(fn.lt, 4), coll)
    tester:assertTableEq(seq.table(dropped), {4,5,6}, "drop_while v < 4")
end


function tests.test_iteration()
    local coll = {1,2,3,4,5,6,7}
    local a = {a = 10, b = 20, c = 30}
    local b = {'a', 'b', 'c'}
    local c = {10, 20, 30}

    local j = 1
    for i, v in seq.indexed(c) do
        tester:asserteq(i, j, "indexed")
        j = j + 1
    end

    local parted = seq.table(seq.partition(2, coll))
    tester:assertTableEq(parted[1], {1,2}, "partition 2")
    tester:assertTableEq(parted[2], {3,4}, "partition 2")
    tester:assertTableEq(parted[3], {5,6}, "partition 2")
    tester:assertTableEq(parted[4], {7}, "partition 2")
end

function tests.test_infinite()
    local ranged = seq.range(5)
    tester:assertTableEq(seq.table(ranged), {1,2,3,4,5}, "range(5)")

    local cycled = seq.cycle({1,2})
    local taken = seq.table(seq.take(5, cycled))
    tester:assertTableEq(taken, {1,2,1,2,1}, "cycle over {1,2}")

    local repeated = seq.take(3, seq.repeat_val(42))
    tester:assertTableEq(seq.table(repeated), {42,42,42}, "repeat_val 42")

    local foo = function() return 42 end
    local repeatedly = seq.take(3, seq.repeatedly(foo))
    tester:assertTableEq(seq.table(repeatedly), {42,42,42}, "repeatedly call fn")

    local geometric = function(ratio, v) return ratio * v end
    local dubla = fn.partial(geometric, 2)
    local geom_seq = seq.take(4, seq.iterate(dubla, 1))
    tester:assertTableEq(seq.table(geom_seq), {2,4,8,16}, "iterate with 2 x v")
end

function tests.test_flattening()
    local nested = {1, 2, 3, {4, 5, {6, 7}}}
    tester:assertTableEq(seq.table(seq.flatten(nested)), {1,2,3,4,3,6}, "flatten a nested sequence")
end

function tests.test_mapping()
    local dubla = function(v) return 2 * v end
    local mapped = seq.map(dubla, seq.range(4))
    tester:assertTableEq(seq.table(mapped), {2,4,6,8}, "map with 2 x v")

    local mapcatted = seq.mapcat(function(v) return {v, 2} end, seq.range(4))
    tester:assertTableEq(seq.table(mapcatted), {1,2,2,2,3,2,4,2}, "mapcat over indexed range")
end

function tests.filter()
    local filtered = seq.filter(function(v) return (v % 2) == 0 end, seq.range(10))
    tester:assertTableEq(seq.table(filtered), {2,4,6,8,10}, "filtering out odds")
end


function tests.reduce()
    local coll = {1,2,3,4,5}
    local reduced = seq.reduce(fn.add, 0, coll)
    tester:asserteq(reduced, 15, "reduce a by addition")
end

function tests.weave()
    local woven = seq.interleave({1,1,1,1}, {2,2,2,2})
    tester:assertTableEq(seq.table(woven), {1,2,1,2,1,2,1,2}, "interleave 1's and 2's")

    local leaved = seq.interpose(",", {"foo", "bar", "baz"})
    tester:assertTableEq(seq.table(leaved), {"foo", ",", "bar", ",", "baz"}, "interpose commas")
end


