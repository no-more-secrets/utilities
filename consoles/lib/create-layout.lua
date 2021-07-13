#!/usr/bin/env lua

-- This file will generate a shell script which, when run, will
-- create a tmux screen layout described by the (Lua) config that
-- is piped into to stdin.
layout_util = require( 'lib/layout-util' )

-- Needed by the layout file.
vertical = layout_util.vertical
horizontal = layout_util.horizontal
command = layout_util.command

-- Get layout.
input = ''
for line in io.lines() do input = input .. line .. '\n' end
layout = load( input )()

-- Generate preamble with pretty-printed layout.
print( '#!/bin/sh' )
print( '# Generating instructions for layout:' )
print( '#' )
print( layout_util.dump( layout, '#   ' ) )
print( '#' )

-- Horizontal splits.
function gen_horizontal( t )
  local count = #t
  local num_splits = count - 1
  assert( num_splits > 0,
          'must have at least one split when using ' ..
              'the horizontal layout.' )
  assert( num_splits < 2,
          'this script does not work well with more than ' ..
              'one split in a single array; use nesting and ' ..
              'recursion to get multiple splits.' )
  for i = 1, num_splits do print( 'tmux split-window -h' ) end
  for i = count, 1, -1 do
    dispatch( t[i] )
    if i == 1 then break end
    print( 'tmux select-pane -L' )
  end
end

-- Vertical splits.
function gen_vertical( t )
  local count = #t
  local num_splits = count - 1
  assert( num_splits > 0,
          'must have at least one split when using ' ..
              'the vertical layout.' )
  assert( num_splits < 2,
          'this script does not work well with more than ' ..
              'one split in a single array; use nesting and ' ..
              'recursion to get multiple splits.' )
  for i = 1, num_splits do print( 'tmux split-window' ) end
  for i = count, 1, -1 do
    dispatch( t[i] )
    if i == 1 then break end
    print( 'tmux select-pane -U' )
  end
end

-- Just run a command in the pane.
function gen_command( t )
  local res = ''
  for _, v in ipairs( t ) do
    if res ~= '' then res = res .. ' ' end
    res = res .. tostring( v )
  end
  res = 'tmux respawn-pane -k \'' .. res .. '\''
  print( res )
end

function dispatch( t )
  if t.type == 'horizontal' then
    gen_horizontal( t )
    return
  end
  if t.type == 'vertical' then
    gen_vertical( t )
    return
  end
  if t.type == 'command' then
    gen_command( t )
    return
  end
  error( 'invalid type: ' .. tostring( t.type ) )
end

dispatch( layout )