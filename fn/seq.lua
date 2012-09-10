seq = {}

--------------------------------
-- functions of maps
--------------------------------

function seq.keys(t)
  local k, v
  return function()
    k, v = next(t, k)
    return k
  end
end


function seq.vals(t)
  local k, v
  return function()
    k, v = next(t, k)
    return v
  end
end


--------------------------------
-- functions of sequences
--------------------------------

function seq.seq(s)
    if type(s) == 'function' then
        return s
    elseif s == nil then
        return function() return nil end
    else
        return seq.vals(s)
    end
end


-- Returns a seq of the first n values of s.
function seq.take(s, n)
    local i = 0
    s = seq.seq(s)
    return function()
        i = i + 1
        if i <= n then
            return s()
        end
    end
end


function seq.take_while(pred, s)
end


function seq.drop_while(pred, s)
end


-- An iterator that successively returns n elements of an indexable object (table, tensor,
-- dataset) in shuffled order.
function seq.shuffle(dataset, n)
    local shuffle = torch.randperm(n)
    local i = 0

    return function()
        i = i + 1
        if i <= n then
            return dataset[shuffle[i]]
        end
    end
end


-- An iterator that takes an iterator, and partitions its elements in
-- chunks of size, returning a full partition on each call.
function seq.partition(stream, size)
    return function()
        local i = 0
        local vals = {}

        repeat
            local v = stream()
            if v == nil then
                break
            else
                fn.append(vals, v)
            end
            i = i + 1
        until i == size
        return vals
    end
end


-- Returns a seq without the first n elements of s.
function seq.drop(s, n)
    for i=1,n do s() end
    return s
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


-- Repeat v infinitely, or n times if n is passed.
function seq.repeat_val(v, n)
    if n then
        local i = 0
        return function()
            if i < n then
                return v
            end
        end
    else
        return function()
            return v
        end
    end
end


-- Takes a function of no args, and returns a sequence of
-- f(), f(), f()...
function seq.repeatedly(f)
    return function()
        f()
    end
end


-- Returns a sequences of f(x), f(f(x)), ...
function seq.iterate(f, x)
    local v = x
    return function()
        v = f(x)
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


function seq.mapcat(f, s)
    s = seq.map(f, s)
    local cur = seq.seq(s())
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


function seq.reduce(f, mem, s)
    s = seq.seq(s)
    for v in s do
        mem = f(mem, v)
    end
    return mem
end


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


-- range(), range(end), range(start, end), range(start, end, step)
function seq.range(...)
    local start = 0
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
        if n == nil or v < n then
            return v
        end
    end
end


