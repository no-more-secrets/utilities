cmake_minimum_required( VERSION 3.12...3.12 )

if( ${CMAKE_VERSION} VERSION_LESS 3.12 )
    cmake_policy(
      VERSION
      ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} )
endif()

project(
    clip
    VERSION 0.1.0
    DESCRIPTION "echo stdin, clipped to line width."
    LANGUAGES CXX
)

# === colors ======================================================

function( force_compiler_color_diagnostics )
	if( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
		# using Clang (either linux or apple)
    set( flag "-fcolor-diagnostics" )
	elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" )
		# using GCC
    set( flag "-fdiagnostics-color=always" )
	elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" )
		# using Intel C++
	elseif( "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC" )
		# using Visual Studio C++
	endif()
  set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}" PARENT_SCOPE )
endfunction()

# Just in case we are using Ninja (which will buffer the output of
# compilers causing them to suppress color output) let's tell the
# compilers to force color output.
force_compiler_color_diagnostics()

# === compiler warnings ===========================================

# Enable all warnings and treat warnings as errors.
function( set_warning_options target )
    target_compile_options(
        ${target} PRIVATE
        # clang/GCC warnings
        $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:GNU>>:
            -Wall -Wextra >
        # MSVC warnings
        $<$<CXX_COMPILER_ID:MSVC>:
            /Wall /WX > )
endfunction( set_warning_options )

# === compiler flags ==============================================

set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native -mtune=native" )

# === ccache ======================================================

find_program( CCACHE_PROGRAM ccache )
if( CCACHE_PROGRAM )
    set( CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" )
else()
    message( STATUS "ccache not found." )
endif()

# === build type ==================================================

set( default_build_type "Debug" )
if( NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES )
    message( STATUS "Setting build type to '${default_build_type}'." )
    set( CMAKE_BUILD_TYPE "${default_build_type}" CACHE
         STRING "Choose the type of build." FORCE )
    # Set the possible values of build type for cmake-gui
    set_property( CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                 "Debug" "Release" "RelWithDebInfo")
endif()
message( STATUS "Build type: ${CMAKE_BUILD_TYPE}" )

# === custom targets ==============================================

add_custom_target( run
                   COMMAND exe
                   WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
                   USES_TERMINAL )

# === this directory ==============================================

file( GLOB sources "[a-zA-Z0-9_-]*.cpp" )

add_executable( exe ${sources} )

target_compile_features( exe PUBLIC cxx_std_20 )
set_target_properties( exe PROPERTIES CXX_EXTENSIONS OFF )
set_warning_options( exe )

target_include_directories(
    exe
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR} )

# === address sanitizer ===========================================

function( enable_address_sanitizer_if_requested )
  if( ENABLE_ADDRESS_SANITIZER )
    message( STATUS "Enabling AddressSanitizer" )
    set( CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS} -fsanitize=address" PARENT_SCOPE )
    set( CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address" PARENT_SCOPE )
  endif()
endfunction()
enable_address_sanitizer_if_requested()

# === compile commands ============================================

set( CMAKE_EXPORT_COMPILE_COMMANDS ON )
