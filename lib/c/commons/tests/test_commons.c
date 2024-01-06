#include <unity.h>

#include "anesowa/commons/multiplier.h"

void setUp(void) {}

void tearDown(void) {}

void test_multiply(void) { TEST_ASSERT_EQUAL(6, multiply(3, 2)); }
