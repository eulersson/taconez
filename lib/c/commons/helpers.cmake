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
      ${VENDOR_DIR}/unity/auto/generate_test_runner.rb
      ${VENDOR_DIR}/../project.yml
      ${test_src_absolute}
      ${test_name}_runner.c
    DEPENDS ${test_src}
  )

  add_executable        (${test_name} ${test_src} ${test_name}_runner.c)
  add_test              (${test_name} ${test_name})
endfunction()

# Generates a mock library based on a module's header file
function(create_mock mock_name header_abs_path)
  if(NOT DEFINED VENDOR_DIR)
    message(FATAL_ERROR "Missing VENDOR_DIR variable.")
  endif()


  get_filename_component(header_folder ${header_abs_path} DIRECTORY)
  file(MAKE_DIRECTORY ${header_folder}/mocks)

  message(
    "[create_mock] ${mock_name} \n"
    "VENDOR_DIR: ${VENDOR_DIR} \n"
    "Mocks will be placed at ${header_folder}/mocks}"
  )

  add_custom_command(
    OUTPUT ${header_folder}/mocks/${mock_name}.c
    COMMAND
      ruby
        ${VENDOR_DIR}/cmock/lib/cmock.rb
        -o${VENDOR_DIR}/../project.yml
        ${header_abs_path}
    WORKING_DIRECTORY ${header_folder}
    DEPENDS
      ${header_abs_path}
  )

  add_library                (${mock_name} ${header_folder}/mocks/${mock_name}.c)
  target_include_directories (${mock_name} PUBLIC ${header_folder})
  target_include_directories (${mock_name} PUBLIC ${header_folder}/mocks)
  target_link_libraries      (${mock_name} unity_lib)
  target_link_libraries      (${mock_name} cmock_lib)
endfunction()

