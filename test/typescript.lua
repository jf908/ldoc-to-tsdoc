local List = require 'pl.List'
ldoc = {
  ipairs = ipairs
}

function lua_to_ts(input)
  local parsed, rest = lua_to_ts_inner(input)

  if rest:sub(1, 1) ~= '|' then
    return parsed, rest
  end
  while rest:sub(1, 1) == '|' do
    local parsed_next
    parsed_next, rest = lua_to_ts_inner(rest:sub(2))
    parsed = parsed .. ' | ' .. parsed_next
  end

  return '(' .. parsed .. ')', rest
end

function lua_to_ts_inner(input)
  local first_char = input:sub(1, 1)
  if first_char == '(' then
    local parsed, rest = parse_parens(input:sub(2))
    return parsed, rest
  elseif first_char == '{' then
    local parsed, rest = parse_table(input:sub(2))
    return parsed, rest
  end

  local found = input:find('[%[%]%(%){}|,]')
  if found == nil then
    return convert_ident(input), ''
  else
    return convert_ident(input:sub(1, found - 1)), input:sub(found)
  end
end

function convert_ident(t)
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
  return t
end

function parse_parens(input)
  local parsed, rest = lua_to_ts(input)
  if rest:sub(1, 1) == ')' then
    return '(' .. parsed .. ')', rest:sub(2)
  else
    -- Failed to match parenthesis
    return parsed, rest
  end
end

function parse_table(input)
  -- Map
  if input:sub(1, 1) == '[' then
    local parsed_key, rest = lua_to_ts(input:sub(2))
    -- Skip "]="
    local parsed_value
    parsed_value, rest = lua_to_ts(rest:sub(3))
    -- Skip ",..."
    local found = rest:find('[}]')
    if found == nil then
      return '{[x: ' .. parsed_key .. ']: ' .. parsed_value .. '}', rest
    else
      return '{[x: ' .. parsed_key .. ']: ' .. parsed_value .. '}', rest:sub(found)
    end
  end

  local parsed, rest, is_struct = parse_table_el(input)
  local list = { parsed }

  while rest:sub(1, 1) == ',' do
    parsed, rest = parse_table_el(rest:sub(2))
    list[#list + 1] = parsed
  end

  -- Array
  if list[#list] == '...' then
    return list[1] .. '[]', rest:sub(2)
  end

  if is_struct then
    -- Struct
    local result = '{'
    for i, v in ldoc.ipairs(list) do
      if i ~= 1 then
        result = result .. ', '
      end
      result = result .. v
    end
    return result .. '}', rest:sub(2)
  else
    -- Tuple
    local result = '['
    for i, v in ldoc.ipairs(list) do
      if i ~= 1 then
        result = result .. ', '
      end
      result = result .. v
    end
    return result .. ']', rest:sub(2)
  end
end

function parse_table_el(input)
  local potential_ident = input:find('[%[%]%(%){}|,]')
  if potential_ident ~= nil then
    local equals = input:sub(1, potential_ident):find('=')
    if equals ~= nil then
      local ident = input:sub(1, equals - 1)
      local parsed, rest = lua_to_ts(input:sub(equals + 1))
      return ident .. ': ' .. parsed, rest, true
    end
  end

  local parsed, rest = lua_to_ts(input)
  return parsed, rest, false
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

assert(lua_to_ts('number') == 'number')
assert(lua_to_ts('int') == 'number')
assert(lua_to_ts('bool') == 'boolean')

-- Maps
assert(lua_to_ts('{[string]=int,...}') == '{[x: string]: number}')

-- Arrays
assert(lua_to_ts('{string,...}') == 'string[]')
assert(lua_to_ts('{int,...}') == 'number[]')

-- Tuples
assert(lua_to_ts('{string,string}') == '[string, string]')
assert(lua_to_ts('{bool,number}') == '[boolean, number]')

-- Structs
assert(lua_to_ts('{A=string,N=number}') == '{A: string, N: number}')

-- Mixed
assert(lua_to_ts('{(number|nil),...}') == '((number | null))[]')
assert(lua_to_ts('{string}|{number}') == '([string] | [number])')
assert(lua_to_ts('{number,...}|{string,...}') == '(number[] | string[])')

-- retgroup_to_ts tests

assert(retgroup_to_ts({}) == 'void')
assert(retgroup_to_ts({ List { { type = 'number' } } }) == 'number')
assert(retgroup_to_ts({ List { { type = 'number' } }, List { { type = 'number' } } }) == 'number | number')
assert(retgroup_to_ts({ List { { type = 'number' }, { type = 'string' } } }) == 'LuaMultiReturn<[number, string]>')
assert(retgroup_to_ts({ List { { type = 'number' }, { type = 'string' } },
  List { { type = 'string' }, { type = 'number' } } }) == 'LuaMultiReturn<[number, string] | [string, number]>')
