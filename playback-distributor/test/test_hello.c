#include "unity.h"


void setUp(void) {}
void tearDown(void) {}

void test_add() {
  int output = 30;
  TEST_ASSERT_EQUAL(31, output);
}

int main(void) {
  UNITY_BEGIN();
  RUN_TEST(test_add);
  return UNITY_END();
}
