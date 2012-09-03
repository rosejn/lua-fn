require 'torch'
require 'fn'

function tests.test_count()
    local coll = {1, 2, 3, 4}

    tester:asserteq(0, fn.count({}), "count empty {}")
    tester:asserteq(4, fn.count(coll), "count coll")
end

function tests.test_is_empty()
    local coll = {1, 2, 3, 4}

    tester:asserteq(true, fn.is_empty({}), "is_empty of {}")
    tester:asserteq(false, fn.is_empty(coll), "is_empty of coll")
end

function tests.test_accessors()
    local coll = {1, 2, 3, 4}
    local nested = {{2, 3}, {4, 5}, 6}

    tester:asserteq(1, fn.first(coll), "first of coll")
    tester:asserteq(2, fn.second(coll), "second of coll")
    tester:asserteq(4, fn.last(coll), "last of coll")
end

