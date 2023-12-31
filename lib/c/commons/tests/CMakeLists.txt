set(
  anesowa_common_tests
  test_utils
)

foreach(unit_test ${unity_tests})
  add_executable(${unit_test} ${unit_test}.c)
  add_test(${unit_test} ${unit_test})
endforeach()
