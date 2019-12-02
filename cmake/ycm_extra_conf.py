import os, sys, json
import subprocess as sp

files = json.loads( file( '.builds/current/compile_commands.json', 'r' ).read() )

flags = {}
directories = {}
commands = set( {} )

for f in files:
    name = str( f['file'] )
    flags[name] = str( f['command'] ).split()
    directories[name] = str( f['directory'] )
    commands |= set( [flags[name][0]] )

def is_mac():
    return 'Darwin' in os.uname()[0]

# cmd is a string with a shell command.
def run_cmd( cmd ):
    p = sp.Popen( cmd, stdout=sp.PIPE, stderr=sp.PIPE, shell=True )
    (stdout, stderr) = p.communicate()
    assert p.returncode == 0, \
          'error running: %s\nerror: %s' % (cmd,stderr)
    return stdout

# Normally when calling a compiler it has a set of built-in
# header search paths where it looks for its standard headers
# that will be used automatically without having to explicitly
# specify them with -I on the compile commandline. However, when
# calling libclang.so it will not autmatically use those. This is
# bad because YCM will try to deduce what they are and then ap-
# pend them (with -isystem ...) to the commandline which can mess
# things up when it gets it wrong. So in this function we invoke
# the compiler binary and get it to tell us what the search paths
# are so we can later append them manually to the commandline
# with -isystem.
def find_system_include_paths( compiler_binary ):
  cmd = 'echo | %s -v -E -x c++ - 2>&1' % compiler_binary
  output = run_cmd( cmd )
  is_header = False
  search_paths = []
  # Print lines between the two marker patterns.
  for line in output.split( '\n' ):
    if 'End of search' in line:
      is_header = False
    if is_header:
      search_paths.append( line.strip() )
    if 'include <..' in line:
      is_header = True
  return search_paths

def CompileSearchPathList():
    all_paths = []
    for cmd in commands:
        paths = find_system_include_paths( cmd )
        for p in paths:
            # On OSX some of these have been observed to end with:
            #
            #   "ABC (framework directory)"
            #
            # In that case we want ABC.
            if '(framework directory)' in p:
                p = p.split()[0]
            # need to preserve ordering
            if p not in all_paths:
                all_paths.append( p )
    return all_paths

def FlagsForFile( filename, **kwargs ):
    try:
        result = flags[filename]
        result_dir = directories[filename]
    except:
        # Try to find a file in the same folder and use those
        for f,cmd in flags.iteritems():
            if os.path.dirname( f ) == os.path.dirname( filename ):
                result = cmd
                result_dir = directories[f]
                break
        else:
            result = []
    if result:
        # Here we need to scan for any -I directives and, if they contain
        # relative paths, we need to make them absolute.  Seems that some
        # CMake generators will make them relative paths and that seems to
        # mess up YCM.
        def fix( i ):
            if i.startswith( '-I' ):
                include = i[2:]
                abs_include = os.path.abspath( os.path.join( result_dir, include ) )
                return '-I%s' % abs_include
            return i
        result = map( fix, result )

    if is_mac():
        isystems = CompileSearchPathList()
        if isystems:
            # There MUST NOT be a space between -isystem and the
            # path, otherwise it will be silently ignored!
            result.extend( ['-isystem%s' % f for f in isystems] )

    return { 'flags': result }

if __name__ == '__main__':
    print FlagsForFile( os.path.realpath( sys.argv[1] ) )
