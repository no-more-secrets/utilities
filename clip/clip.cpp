// --------------------------------------------------------------
// clip
// --------------------------------------------------------------
// Usage:
//
//   $ clip <columns>
//
// Typical usage:
//
//   $ clip $COLUMNS
//
// Will forward lines from stdin to stdout clipping each line to
// a maximum of <columns> characters.
// --------------------------------------------------------------
#include <stdlib.h>
#include <unistd.h>
#include <string>
#include <utility>

#include <iostream>

template<typename... Args>
void die( Args&&... args ) {
  fprintf( stderr, args... );
  fprintf( stderr, "\n" );
  exit( 1 );
}

int main( int argc, char** argv ) {
  if( argc != 2 )
      die( "%s", "usage: clip <max_columns>" );

  auto columns = atoi( argv[1] );
  if( columns <= 0 )
    die( "integer columns is invalid: %d", columns );

  std::string line;
  while( true ) {
    std::getline( std::cin, line );
    if( std::cin.eof() )
        break;
    if( int( line.size() ) > columns )
        line.resize( columns );
    std::cout << line << "\n";
  }
  return 0;
}