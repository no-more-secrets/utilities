-----------------------------------------------------------------
-- Imports.
-----------------------------------------------------------------
local cmd = require( 'moon.cmd' )

-----------------------------------------------------------------
-- Aliases.
-----------------------------------------------------------------
local format = string.format
local pack = table.pack

local command = cmd.command
local command_pipe = cmd.command_pipe
local make_command_string = cmd.make_command_string

-----------------------------------------------------------------
-- Functions.
-----------------------------------------------------------------
local function test_command( prog, ... )
  -- Try uncommenting this if we're not getting full output.
  -- io.stdout:setvbuf( 'no' )
  local stdout = command( prog, ... )
  print( stdout )
end

local function test_command_pipe( prog, ... )
  -- Try uncommenting this if we're not getting full output.
  -- io.stdout:setvbuf( 'no' )
  local file = command_pipe( prog, ... )
  for line in file:lines() do print( 'stdout:', line ) end
  local success, termination, code = file:close()
  print( format( 'system command result.\n' .. --
                     '  success:     %s\n' .. --
                     '  termination: %s\n' .. --
                     '  code:        %d\n' .. --
  '  command:     %s', --
  success, termination, code, make_command_string( prog, ... ) ) )
end

-----------------------------------------------------------------
-- Main.
-----------------------------------------------------------------
local function main( _ )
  local txt = '/home/dsicilia/dev/utilities/moonlib/moon/cmd.lua'
  print( '=================== Without pipe ===================' )
  test_command( 'cat', txt )
  print( '===================== With pipe ====================' )
  test_command_pipe( 'cat', txt )
end

-----------------------------------------------------------------
-- Startup.
-----------------------------------------------------------------
main( pack( ... ) )
