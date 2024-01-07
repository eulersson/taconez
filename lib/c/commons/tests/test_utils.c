#include "multiplier.h"

#include <unity.h>

#include "fff.h"
DEFINE_FFF_GLOBALS;
FAKE_VOID_FUNC(potato);

void setUp(void) {}

void tearDown(void) {}

void test_s_send(void)
{
  int result = multiply(3, 4);
  TEST_ASSERT_EQUAL(potato_fake.call_count, 1);
}
