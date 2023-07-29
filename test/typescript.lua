local List = require 'pl.List'
ldoc = {
  ipairs = ipairs
}

function lua_to_ts(type)
  local result = ''
  for t in type:gmatch('([^|]+)') do
    if result ~= '' then
      result = result .. ' | '
    end
    result = result .. lua_to_ts_inner(t)
  end
  return result
end

function lua_to_ts_inner(t)
  if t == 'nil' then
    return 'null'
  elseif t == 'int' then
    return 'number'
  elseif t == 'bool' then
    return 'boolean'
  elseif t == 'func' then
    return '(...x: any[]) => any'
  elseif t == 'tab' or t == 'table' then
    return 'object'
  end

  if t:sub(1, 1) == '{' then
    if t:sub(-5) == ",...}" then
      local equals = t:find('=')
      -- Map
      if equals == nil then
        return lua_to_ts_inner(t:sub(2, -6)) .. '[]'
      end

      -- Array
      return '{[x: ' .. lua_to_ts_inner(t:sub(3, equals - 2)) .. ']: ' .. lua_to_ts_inner(t:sub(equals + 1, -6)) .. '}'
    else
      -- Struct
      if t:find('=') then
        local result = '{'
        for el in t:sub(2, -2):gmatch('[^,]+') do
          local equals = el:find('=')
          if result ~= '{' then
            result = result .. el:sub(1, equals - 1) .. ': ' .. lua_to_ts_inner(el:sub(equals + 1))
          else
            result = result .. el:sub(1, equals - 1) .. ': ' .. lua_to_ts_inner(el:sub(equals + 1)) .. ', '
          end
        end
        return result .. '}'
      end

      -- Tuple
      local result = '['
      for el in t:sub(2, -2):gmatch('[^,]+') do
        if result ~= '[' then
          result = result .. lua_to_ts_inner(el)
        else
          result = result .. lua_to_ts_inner(el) .. ', '
        end
      end
      return result .. ']'
    end
  end

  return t
end

function retgroup_to_ts(groups)
  if #groups == 0 then
    return 'void'
  end

  local max_group_size = 0
  for i, group in ldoc.ipairs(groups) do
    if #group > max_group_size then
      max_group_size = #group
    end
  end

  if max_group_size == 1 then
    -- No multi-return needed
    local result = ''
    for i, group in ldoc.ipairs(groups) do
      if i ~= 1 then
        result = result .. ' | '
      end
      for r in group:iter() do
        result = result .. lua_to_ts(r.type)
      end
    end
    return result
  else
    local result = 'LuaMultiReturn<'
    for i, group in ldoc.ipairs(groups) do
      if i ~= 1 then
        result = result .. ' | '
      end
      result = result .. '['
      local first = true
      for r in group:iter() do
        if not first then
          result = result .. ', '
        end
        first = false
        result = result .. lua_to_ts(r.type)
      end
      result = result .. ']'
    end
    return result .. '>'
  end
end

-- lua_to_ts tests

assert(lua_to_ts_inner('number') == 'number')
assert(lua_to_ts_inner('int') == 'number')
assert(lua_to_ts_inner('bool') == 'boolean')

assert(lua_to_ts_inner('{string,...}') == 'string[]')
assert(lua_to_ts_inner('{int,...}') == 'number[]')

assert(lua_to_ts_inner('{[string]=int,...}') == '{[x: string]: number}')

assert(lua_to_ts_inner('{string,string}') == '[string, string]')
assert(lua_to_ts_inner('{bool,number}') == '[boolean, number]')

assert(lua_to_ts_inner('{A=string,N=number}') == '{A: string, N: number}')

-- retgroup_to_ts tests

assert(retgroup_to_ts({}) == 'void')
assert(retgroup_to_ts({ List { { type = 'number' } } }) == 'number')
assert(retgroup_to_ts({ List { { type = 'number' } }, List { { type = 'number' } } }) == 'number | number')
assert(retgroup_to_ts({ List { { type = 'number' }, { type = 'string' } } }) == 'LuaMultiReturn<[number, string]>')
assert(retgroup_to_ts({ List { { type = 'number' }, { type = 'string' } },
  List { { type = 'number' }, { type = 'string' } } }) == 'LuaMultiReturn<[number, string], [number, string]>')
