function(print_all_vars)
  get_cmake_property(_variableNames VARIABLES)
  list (SORT _variableNames)
  foreach (_variableName ${_variableNames})
      message(STATUS "${_variableName}=${${_variableName}}")
  endforeach()
endfunction()

# Sources:
#
# - https://github.com/ThrowTheSwitch/CMock/issues/379
# - https://github.com/mihaiolteanu/calculator
#
function(create_test test_name test_src)
  if(NOT DEFINED VENDOR_DIR)
    message(FATAL_ERROR "Missing VENDOR_DIR variable.")
  endif()

  message("[create_test] ${test_name} VENDOR_DIR: ${VENDOR_DIR}")

  get_filename_component(test_src_absolute ${test_src} REALPATH)

  add_custom_command(
    OUTPUT ${test_name}_runner.c
    COMMAND
      ruby
      ${VENDOR_DIR}/Unity/auto/generate_test_runner.rb
      ${VENDOR_DIR}/../project.yaml
      ${test_src_absolute}
      ${test_name}_runner.c
    DEPENDS ${test_src}
  )

  add_executable        (${test_name} ${test_src} ${test_name}_runner.c)
  target_link_libraries (${test_name} PRIVATE unity_lib fff) # fff is a mocking library
  add_test              (${test_name} ${test_name})
endfunction()
