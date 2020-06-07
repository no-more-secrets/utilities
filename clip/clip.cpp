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
// a maximum of <columns> characters. Input lines that contain
// tabs will have those tabs converted to four spaces.
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

constexpr size_t kBufSize = 2048;

size_t remove_tabs( std::string const& line, char* copied ) {
  size_t i = 0;
  size_t j = 0;
  while( i < line.size() && j < kBufSize - 1 ) {
    if( line[i] == '\t' ) {
      copied[j++] = ' ';
      copied[j++] = ' ';
      ++i;
      continue;
    }
    copied[j++] = line[i];
    ++i;
  }
  copied[j] = '\0';
  return j;
}

int main( int argc, char** argv ) {
  if( argc != 2 ) die( "%s", "usage: clip <max_columns>" );

  auto columns = atoi( argv[1] );
  if( columns <= 0 )
    die( "integer columns is invalid: %d", columns );

  std::string line;
  char buffer[kBufSize];
  while( true ) {
    std::getline( std::cin, line );
    if( std::cin.eof() ) break;
    int len = remove_tabs( line, buffer );
    len = std::min(len, columns);
    std::cout << std::string_view(buffer, len) << "\n";
  }
  return 0;
}