#include "unity.h"


void setUp(void) {}
void tearDown(void) {}

void test_add() {
  TEST_ASSERT_EQUAL(30, 30);
}

int main(void) {
  UNITY_BEGIN();
  RUN_TEST(test_add);
  return UNITY_END();
}
