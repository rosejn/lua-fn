require('util')

-- Short-hand operator functions for use in map, filter, reduce...
fn = {
    mod = math.mod;
    pow = math.pow;
    add = function(n,m) return n + m end;
    sub = function(n,m) return n - m end;
    mul = function(n,m) return n * m end;
    div = function(n,m) return n / m end;
    gt  = function(n,m) return m > n end;
    lt  = function(n,m) return m < n end;
    eq  = function(n,m) return n == m end;
    le  = function(n,m) return n <= m end;
    ge  = function(n,m) return n >= m end;
    ne  = function(n,m) return n ~= m end;
}

function fn.inc(v)
    return v + 1
end

function fn.dec(v)
    return v - 1
end

function fn.id(v)
	return v
end


------------------------------------------------------------
-- Treating tables as sequences
-----------------------------------------------------------

-- Returns the size of a table
function fn.count(tbl)
    return #tbl
end


-- Predicate test if a table is empty
function fn.is_empty(tbl)
    return #tbl == 0
end


-- Append an element onto the end of a table
function fn.append(tbl, val)
  table.insert(tbl, val)
  return tbl
end


-- Returns the first element of a table
function fn.first(tbl)
    return tbl[1]
end


-- Returns the second element of a table
function fn.second(tbl)
    return tbl[2]
end


-- Get the last element of a table
function fn.last(tbl)
    return tbl[#tbl]
end


-- Returns a new table with everything but the first element of a table,
-- or nil if the table is empty.
function fn.rest(tbl)
    if fn.is_empty(tbl) then
        return nil
    else
        local new_array = {}
        for i = 2, #tbl do
            table.insert(new_array, tbl[i])
        end
        return new_array
    end
end


-- Returns a new table containing the first n elements of tbl
function fn.take(n, tbl)
    local new_tbl = {}
    for i=1, n do
        fn.append(new_tbl, tbl[i])
    end
    return new_tbl
end


-- Returns a new table without the first n elements of tbl
function fn.drop(n, tbl)
    local new_tbl = {}
    for i=n+1, #tbl do
        fn.append(new_tbl, tbl[i])
    end
    return new_tbl
end

------------------------------------------------------------
-- Making use of functions
-----------------------------------------------------------



-- is(checker_function, expected_value)
-- @brief
--      check function generator. return the function to return boolean,
--      if the condition was expected then true, else false.  Helpful
--      for filtering and other functions that take a predicate.
-- @example
--      local is_table = fn.is(type, "table")
--      local is_even =  fn.is(fn.partial(math.mod, 2), 1)
--      local is_odd =   fn.is(fn.partial(math.mod, 2), 0)
function fn.is(check, expected)
    return function (...)
        if (check(unpack(...)) == expected) then
            return true
        else
            return false
        end
    end
end


-- comp(f,g)
-- Returns a function that is the composition of functions f and g: f(g(...))
-- e.g: printf = comp(io.write, string.format)
--          -> function(...) return io.write(string.format(unpack(arg))) end
function fn.comp(f,g)
    return function (...)
        return f(g(...))
    end
end


-- partial(f, args)
-- Returns a new function, which will call f with args and any additional
-- arguments passed to the new function.
function fn.partial(f, ...)
    local pargs = {...}
    return function(...)
        local args = {}
        for _,v in ipairs(pargs) do
            fn.append(args, v)
        end
        for _,v in ipairs({...}) do
            fn.append(args, v)
        end

        return f(unpack(args))
    end
end


-- thread(value, f, ...)
function fn.thread(val, ...)
    local functions = {...}

    for _, fun in ipairs(functions) do
        val = fun(val)
    end

    return val
end


--[[
  apply(f, args..., tbl)

  Call function f, passing args as the arguments, with the values in tbl appended to
  the argument list.

   e.g.
     function compute(m, x, b)
       return m * x + b
     end

     -- apply a list of args to a function
     fn.apply(compute, {2, 3, 4})

     -- prepend some args to the list that is applied
     fn.apply(compute, 2, {3, 4})
     fn.apply(compute, 2, 3, {4})
]]
function fn.apply(f, ...)
    local pargs = {}
    local args = {...}
    if #args > 1 then
        for i=1, (#args - 1) do
            fn.append(pargs, args[i])
        end
    end
    local full_args = util.concat(pargs, args[#args])
    return f(unpack(full_args))
end


-- map(function, table)
 -- e.g: map(double, {1,2,3})    -> {2,4,6}
 function fn.map(func, tbl)
     local newtbl = {}
     for i,v in pairs(tbl) do
         newtbl[i] = func(v)
     end
     return newtbl
 end


 -- filter(function, table)
 -- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
 function fn.filter(func, tbl)
     local newtbl= {}
     for i,v in ipairs(tbl) do
         if func(v) then
             fn.append(newtbl, v)
         end
     end
     return newtbl
 end


 -- reduce(function, init_val, table)
 -- e.g:
 --   reduce(fn.mul, 1, {1,2,3,4,5}) -> 120
 --   reduce(fn.add, 0, {1,2,3,4})   -> 10
 function fn.reduce(func, val, tbl)
     for _,v in pairs(tbl) do
         val = func(val, v)
     end
     return val
 end


-- Returns a map with keys mapped to corresponding vals.
-- e.g.
--   zipmap({1,2,3}, {'a', 'b', 'c'})     -- => {1 = 'a', 2 = 'b', 3 = 'c'}
function fn.zipmap(keys, vals)
    local m = {}
    for i, key in ipairs(keys) do
        m[key] = vals[i]
    end

    return m
end


-- zip(table, table)
-- e.g.
--    zip({1,2,3}, {'a', 'b', 'c'}) -> {{1,'a'}, {2,'b'}, {3,'c'}}
--    zip({1,2,3}, {'a', 'b', 'c', 'd'}) -> {{1,'a'}, {2,'b'}, {3,'c'}}
function fn.zip(tblA, tblB)
	local len = math.min(#tblA, #tblB)
	local newtbl = {}
	for i = 1,len do
		table.insert(newtbl, {tblA[i], tblB[i]})
	end
	return newtbl
end


-- zip_with(function, table, table)
-- e.g.:
--   zip_with(fn.add, {1,2,3}, {1,2,3}) -> {2,4,6}
--   zip_with(fn.add, {1,2,3}, {1,2,3,4}) -> {2,4,6}
function fn.zip_with(func, tblA, tblB)
	return fn.map(function(x) return func(unpack(x)) end, fn.zip(tblA, tblB))
end


