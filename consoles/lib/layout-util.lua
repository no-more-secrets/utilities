-- Prevent setting globals.
_ENV = setmetatable( {}, {
  __index=_ENV,
  __newindex=function( _, k, _ )
    error( 'cannot set global ' .. k )
  end
} )

local M = {}

-- Recursive function that pretty-prints a layout.
function M.dump( o, prefix, spaces )
  spaces = spaces or ''
  if type( o ) == 'table' then
    local meta = getmetatable( o )
    if meta and meta.__tostring then
      local s = ''
      if #spaces == 0 then s = prefix end
      return s .. meta.__tostring( o )
    end
    local name = o.type or ''
    local s = ''
    if #spaces == 0 then s = prefix end
    s = s .. name .. '{\n'
    spaces = spaces .. '  '
    for k, v in ipairs( o ) do
      if type( k ) ~= 'number' then k = '\'' .. k .. '\'' end
      s = s .. prefix .. spaces .. '[' .. k .. '] = ' ..
              M.dump( v, prefix, spaces ) .. ',\n'
    end
    return s .. prefix .. string.sub( spaces, 3 ) .. '}'
  else
    local s = ''
    if #spaces == 0 then s = prefix end
    return s .. tostring( o )
  end
end

function M.horizontal( t )
  t.type = 'horizontal'
  return t
end

function M.vertical( t )
  t.type = 'vertical'
  return t
end

function M.command( t )
  t.type = 'command'
  local meta = getmetatable( t ) or {}
  meta.__tostring = function()
    local res = ''
    for _, v in ipairs( t ) do
      if res ~= '' then res = res .. ' ' end
      res = res .. tostring( v )
    end
    if string.match( res, '"' ) then
      return 'command{ [[' .. res .. ']] }'
    else
      return 'command{ "' .. res .. '" }'
    end
  end
  setmetatable( t, meta )
  return t
end

return M
