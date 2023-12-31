set(
  sound_player_tests
  test_sound_player
)

foreach(unit_test ${sound_player_tests})
  add_executable(${unit_test} ${unit_test}.c)
  target_link_libraries(${unit_test} anesowa-commons)
  add_test(${unit_test} ${unit_test})
endforeach()
