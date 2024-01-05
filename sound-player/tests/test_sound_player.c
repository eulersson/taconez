#include <stdarg.h>
#include <setjmp.h>
#include <stddef.h>
#include <cmocka.h>

// Third-Party
#include <cjson/cJSON.h>
#include <pulse/error.h>
#include <pulse/simple.h>
#include <zmq.h>

static void test(void **state)
{
    assert_int_equal(2, 2);
}

int main()
{
    void *context = zmq_ctx_new();
    const struct CMUnitTest tests[] =
    {
        cmocka_unit_test(test),
    };

    return cmocka_run_group_tests(tests, NULL, NULL);
}
