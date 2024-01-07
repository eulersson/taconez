
#include "anesowa/commons/multiplier.h"

#include <unity.h>

#include "fff.h"
DEFINE_FFF_GLOBALS;
FAKE_VOID_FUNC(potato);

void setUp(void) {}

void tearDown(void) {}

void test_s_send(void) {
  int result = multiply(3, 4);
  TEST_ASSERT_EQUAL(potato_fake.call_count, 1);
  // multipy_fake.return_val = 123;
  // TEST_ASSERT_EQUAL(13, multiply(6, 2));
  // TEST_ASSERT_EQUAL(multiply.call_count, 1);
}
