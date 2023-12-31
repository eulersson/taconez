set(
  anesowa_common_tests
  test_playback_distributor
)

foreach(unit_test ${anesowa_common_tests})
  add_executable(${unit_test} ${unit_test}.c)
  target_link_libraries(${unit_test} anesowa-commons)
  add_test(${unit_test} ${unit_test})
endforeach()
