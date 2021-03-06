include( CMakeParseArguments )

# A high level target that the individual targets depend on.
#add_custom_target( CreateTarballs ALL
#  ${CMAKE_COMMAND} -E echo "Done creating individual example tarballs..."
#)

# Macro for adding an example.
#
# Most of the CMake logic for the example should live in the examples
# CMakeLists.txt.  That file should be standalone for building the example.
# This macro is intended to be instantiated in the CMakeLists.txt one directory
# above where the example exists.  It does things like creating the example
# tarball's in the example output directory, and custom targets for building
# the Sphinx documentation for an individual example.  The Sphinx target will be
# called ${example_name}Doc.
macro( add_example example_name )
  if( BUILD_DOCUMENTATION )
    if( SPHINX_HTML_OUTPUT )
      add_custom_target( ${example_name}Tarball
        COMMAND ${PYTHON_EXECUTABLE} ${ITKExamples_SOURCE_DIR}/Utilities/CreateTarball.py
          ${example_name} ${SPHINX_DESTINATION}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Creating tarballs for ${example_name}"
        DEPENDS copy_sources
        )
      add_dependencies( CreateTarballs ${example_name}Tarball )
    endif()
  endif()

  # Process the example's CMakeLists.txt
  add_subdirectory( ${example_name} )

endmacro()


# Macro if the corresponding module is enabled when ITK was built
# Pass in the module directory path.  Also pass the module name as the second
# argument if it is different than ITK${_dir}.
macro( add_subdirectory_if_module_enabled _dir )
  set( _module_name ITK${_dir} )
  if( "${ARGV1}" STRGREATER "" )
    set( _module_name ${ARGV1} )
  endif()
  list( FIND ITK_MODULES_ENABLED ${_module_name} _have )

  if( NOT ${_have} EQUAL "-1" )
    add_subdirectory( ${_dir} )
  endif()
endmacro()

# Creates a test that compares the output image of an example to its baseline
# image.
#
# Usage:
# compare_to_baseline(
#   [TEST_NAME myAwesomeExampleBaselineComparison1] // this argument is optional and meant
#                                                   // to be used when there would be several
#                                                   // baseline comparison tests based on one given
#                                                   // example
#   EXAMPLE_NAME myAwesomeExampleName
#   BASELINE_PREFIX myBaselineImagePrefix
#   [TEST_IMAGE myAwesomeExampleOutputImagePrefix.png] // this argument is optional and meant
#                                                      // to be used when there would be several
#                                                      // baseline comparison tests based on one given
#                                                      // example
#   [OPTIONS myListOfOptions]
#   [DEPENDS myListOfDependencies]
# )
#
# Note:
# * By default TEST_NAME is set to ${EXAMPLE_NAME}TestBaselineComparison
# * For Python the comparison test is added automatically

function( compare_to_baseline )

  set( options
  )

  set( oneValueArgs
    EXAMPLE_NAME
    TEST_IMAGE
    BASELINE_PREFIX
    TEST_NAME
  )

  set( multiValueArgs
    DEPENDS
    OPTIONS
  )

  cmake_parse_arguments( LOCAL_COMPARISON
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if( NOT LOCAL_COMPARISON_EXAMPLE_NAME )
    message( FATAL_ERROR "Syntax error in use of compare_to_baseline: EXAMPLE_NAME is required" )
  endif()

  if( NOT LOCAL_COMPARISON_BASELINE_PREFIX )
    message( FATAL_ERROR "Syntax error in use of compare_to_baseline: BASELINE_PREFIX is required" )
  endif()

  set( depends ${LOCAL_COMPARISON_EXAMPLE_NAME}Test )
  if( LOCAL_COMPARISON_DEPENDS )
    set( depends ${LOCAL_COMPARISON_DEPENDS} )
  endif()

  file( GLOB baseline_image ${CMAKE_CURRENT_SOURCE_DIR}/${LOCAL_COMPARISON_EXAMPLE_NAME}/${LOCAL_COMPARISON_BASELINE_PREFIX}.* )
  string( REPLACE .md5 "" baseline_image "${baseline_image}" )
  get_filename_component( baseline_image_file "${baseline_image}" NAME )
  set( baseline_image "${CMAKE_CURRENT_BINARY_DIR}/${LOCAL_COMPARISON_EXAMPLE_NAME}/${baseline_image_file}" )

  if( NOT LOCAL_COMPARISON_TEST_IMAGE )
    string( REPLACE Baseline "" test_image "${baseline_image}" )
  else()
    set( test_image ${CMAKE_CURRENT_BINARY_DIR}/${LOCAL_COMPARISON_EXAMPLE_NAME}/${LOCAL_COMPARISON_TEST_IMAGE} )
  endif()

  set( test_name )
  if( NOT LOCAL_COMPARISON_TEST_NAME )
    set( test_name ${LOCAL_COMPARISON_EXAMPLE_NAME}TestBaselineComparison )
  else()
    set( test_name ${LOCAL_COMPARISON_TEST_NAME} )
  endif()

  add_test( NAME ${test_name}
    COMMAND "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ImageCompareCommand"
      --test-image "${test_image}"
      --baseline-image "${baseline_image}"
      ${LOCAL_COMPARISON_OPTIONS}
  )

  set_tests_properties( ${test_name}
    PROPERTIES DEPENDS ${depends}
    )

  get_property( has_python_test GLOBAL PROPERTY ${depends}HASPYTHONTEST )
  if( ${has_python_test} )

    set( python_test_name ${test_name}Python )
    string( REPLACE . "Python." test_image "${test_image}" )

    # Add the comparison for the Python test output
    # Use the same baseline image as for the c++ output
    add_test( NAME ${python_test_name}
      COMMAND "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ImageCompareCommand"
        --test-image "${test_image}"
        --baseline-image "${baseline_image}"
        ${LOCAL_COMPARISON_OPTIONS}
    )

    # Depend on the Python test.
    set( depends ${depends}Python )
    set_tests_properties( ${python_test_name}
      PROPERTIES DEPENDS ${depends}
    )

  endif()

endfunction()
