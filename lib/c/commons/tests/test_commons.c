#include <unity.h>

#include "anesowa/commons/mocks/mock_multiplier.h"

void setUp(void) {}

void tearDown(void) {}

void test_multiply(void) {
  multiply_ExpectAndReturn(3, 2, 7);
  TEST_ASSERT_EQUAL(7, multiply(3, 2));
}
