require 'torch'
require 'util'
require 'fn'

seq = {}

--------------------------------
-- functions of maps
--------------------------------

-- Return a sequence of the keys of table t.
function seq.keys(t)
  local k, v
  return function()
    k, v = next(t, k)
    return k
  end
end


-- Return a sequence of the values in table or tensor t.  If a tensor is passed
-- then only the first dimension is indexed, so you might need to flatten it if
-- you want to iterate of items of a multi-dimensional tensor.
function seq.vals(t)
  local k, v
  if util.is_table(t) then
      local has_ended = false
      return function()
          if has_ended then
              return nil
          else
              k, v = next(t, k)
              if k == nil then
                  has_ended = true
              end
              return v
          end
      end
  elseif util.is_tensor(t) then
      local i = 0
      local n = (#t)[1]
      return function()
          i = i + 1
          if i <= n then
              return t[i]
          else
              return nil
          end
      end
  end
end


--------------------------------
-- functions of sequences
--------------------------------


-- Returns a sequence iterator function that will return the successive values
-- of s.  If passed a function (e.g. an existing iterator), it just returns it
-- back, and if passed nil returns an empty iterator (returns nil on first
-- call.)
function seq.seq(s)
    if type(s) == 'function' then
        return s
    elseif s == nil then
        return function()
            return nil
        end
    else
        return seq.vals(s)
    end
end


-- Returns the elements of sequence s in a table.
function seq.table(s)
    local tbl = {}
    for elem in s do
        fn.append(tbl, elem)
    end
    return tbl
end


-- Returns a tensor containing the sequence s.
-- NOTE: since a tensor must be allocated in advance, we have to first
-- realize the sequence in a table, and then write it into a tensor.
function seq.tensor(s)
    return torch.Tensor(seq.table(s))
end


-- Returns a seq of the first n values of s.
function seq.take(n, s)
    local i = 0
    s = seq.seq(s)
    return function()
        i = i + 1
        if i <= n then
            return s()
        end
    end
end


-- Returns successive elements of s as long as pred(element) returns true.
function seq.take_while(pred, s)
    s = seq.seq(s)
    return function()
        local v = s()
        if pred(v) then
            return v
        end
    end
end


-- Returns a seq without the first n elements of s.
function seq.drop(n, s)
    s = seq.seq(s)
    for i=1,n do s() end
    return s
end


-- Drops successive elements of s as long as pred(element) returns true,
-- and then returns the rest of the sequence.
function seq.drop_while(pred, s)
    s = seq.seq(s)
    local dropped_all = false
    return function()
        if dropped_all then
            return s()
        else
            local v
            repeat
                v = s()
            until not pred(v)
            dropped_all = true
            return v
        end
    end
end


-- Returns successive pairs of (index, element), starting with one.
function seq.indexed(s)
    local i = 0
    s = seq.seq(s)

    return function()
        local elem = s()
        if elem then
            i = i + 1
            return i, elem
        else
            return nil
        end
    end
end


-- Successively returns n elements of an indexable object (table, tensor,
-- dataset) in shuffled order.  The object must either support the # operator
-- or have a .size() function available to get the full size.
function seq.shuffle(s)
    local n

    -- TODO: This is a bit of a hack because Lua doesn't currently support
    -- the __len method on tables.  With Lua 5.2 this can be removed.
    if type(s.size) == 'function' then
        n = s.size()
    else
        n = #s
    end

    local shuffle = torch.randperm(n)
    local i = 0

    return function()
        i = i + 1
        if i <= n then
            return s[shuffle[i]]
        end
    end
end


-- Returns the elements of s in groups of partition size n.
function seq.partition(n, s)
    s = seq.seq(s)

    return function()
        local i = 0
        local vals = {}

        repeat
            local v = s()
            if v == nil then
                break
            else
                fn.append(vals, v)
                i = i + 1
            end
        until i == n

        if i == 0 then
            return nil
        else
            return vals
        end
    end
end


-- range(), range(end), range(start, end), range(start, end, step)
function seq.range(...)
    local start = 1
    local n = nil
    local step = 1
    local args = {...}

    if #args == 1 then
        n = args[1]
    elseif #args == 2 then
        start = args[1]
        n = args[2]
    elseif #args == 3 then
        start = args[1]
        n = args[2]
        step = args[3]
    end

    return function()
        local v = start
        start = start + step
        if n == nil or v <= n then
            return v
        end
    end
end


-- Return an infinite sequence of the elements in s, starting
-- back at the beginning when reaching the end.
function seq.cycle(s)
    local the_seq = s
    local cur = seq.seq(s)
    return function()
        local v = cur()
        if v then
            return v
        else
            cur = seq.seq(s)
            return cur()
        end
    end
end


-- Concatenate two or more sequences.
function seq.concat(...)
    local args = seq.seq({...})
    local cur = seq.seq(args())
    return function()
        local v = cur()
        if v then
            return v
        else
            local new = args()
            if new then
                cur = seq.seq(new)
                if cur then
                    return cur()
                end
            end
        end
    end
end


-- seq.repeat_val(v)
-- seq.repeat_val(n, v)
--
-- Repeat v infinitely, or n times if n is passed.
-- e.g.
--   seq.repeat_val(10)    -- => {10, 10, 10, 10, ...}
--   seq.repeat_val(3, 42) -- => {42, 42, 42}
function seq.repeat_val(...)
    local args = {...}
    if #args == 2 then
        local n = args[1]
        local v = args[2]

        local i = 0
        return function()
            if i < n then
                return v
            end
        end
    else
        local v = args[1]
        return function()
            return v
        end
    end
end


-- Takes a function of no args, and returns a sequence of
-- f(), f(), f()...
function seq.repeatedly(f)
    return function()
        return f()
    end
end


-- Returns a sequences of f(x), f(f(x)), ...
function seq.iterate(f, x)
    local v = x
    return function()
        v = f(v)
        return v
    end
end


-- Return a new sequence of f applied to each value of s.
function seq.map(f, s)
    s = seq.seq(s)
    return function()
        local v = s()
        if v then
            return f(v)
        end
    end
end


-- Returns a sequence of the concatenation of applying f to each value
-- in s.  (Expects that f returns a seq.)
function seq.mapcat(f, s)
    s = seq.map(f, s)
    local cur = seq.seq(s())
    return function()
        local v = cur()
        if v then
            return v
        else
            local new = s()
            if new then
                cur = seq.seq(new)
                if cur then
                    return cur()
                end
            end
        end
    end
end


-- Filter out values of s for which pred(v) returns false.
function seq.filter(pred, s)
    s = seq.seq(s)
    return function()
        local v
        while true do
            v = s()
            if v == nil then
                return nil
            elseif pred(v) then
                return v
            end
        end
    end
end


-- Reduce sequence s using function f(mem, v), which should be a function of two args,
-- the memory and the next value.  The mem argument is the initial value of
-- mem passed to f.
function seq.reduce(f, mem, s)
    s = seq.seq(s)
    for v in s do
        mem = f(mem, v)
    end
    return mem
end


-- Creates a new sequence by interleaving elements from multiple sequences.
function seq.interleave(...)
    local args = {...}
    local n = #args
    args = seq.cycle(seq.map(seq.seq, args))
    return function()
        local s = args()
        if s then
            return s()
        end
    end
end


-- Return a sequence with the elements of s separated by sep.
function seq.interpose(sep, s)
    s = seq.seq(s)
    local toggle = false
    local next_val = s()
    return function()
        if next_val then
            if toggle then
                toggle = false
                return sep
            else
                toggle = true
                local v = next_val
                next_val = s()
                return v
            end
        end
    end
end
