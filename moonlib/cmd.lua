#!/usr/bin/env lua
-- local function read_from_stdin( title )
--   assert( title )
--   io.write( "title: ", title, "\n" )
--   for l in io.lines() do
--     io.write( "line: ", l, "\n" )
--   end
-- end

-- read_from_stdin(...)

local function cmd( prog, ... )
  local c = prog
  for _, s in ipairs( table.pack( ... ) ) do
    c = c .. ' ' .. s
  end
  print( 'running:' .. c )
  return assert( io.popen( c ) )
end

-- local f = cmd( 'lua', '--version', '--jjj' )
local f = cmd( 'lua', '-v' )
f:flush()
assert( f )

print( '--- start stdout ---' )
-- for l in f:lines() do
--   print( l )
-- end
print( '--- end stdout ---' )

local success, termination, code = f:close()

print( 'success:', success==true )
print( 'termination:', termination )
print( 'exit code:', code )
