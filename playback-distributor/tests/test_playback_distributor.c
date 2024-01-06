#include <unity.h>

#include "mocks/mock_adder.h"

void setUp(void) {}

void tearDown(void) {}

void test_add(void) {
  add_ExpectAndReturn(1, 2, 4);
  TEST_ASSERT_EQUAL(4, add(1, 2));
}
