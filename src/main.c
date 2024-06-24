#include <kernel/svc.h>
#include <sf/tipc.h>
#include <sf/hipc.h>

typedef enum {
    RESULT_SUCESS,
    RESULT_UNIMPLEMENTED,
    RESULT_INVALID_ARG,
    RESULT_IN_PROGRESS,
    RESULT_NO_ASYNC_OPERATION,
    RESULT_INVALID_ASYNC_OPERATION,
    RESULT_NOT_PERMITTED, // 8.0.0+
}syscall_result;

HipcHeader header = {0};

int main() {
    Handle sm;
    Result rc = svcConnectToNamedPort(&sm, "sm:");
    if (rc != RESULT_SUCESS) {
        const char sm_fail[] = "Failed to open port sm:\n";
        svcOutputDebugString(sm_fail, sizeof(sm_fail));
    }
    else {
        const char sm_pass[] = "Got Service Manager handle.\n";
        svcOutputDebugString(sm_pass, sizeof(sm_pass));
    }

    const char msg[] = "Hello from C!\n";
    svcOutputDebugString(msg, sizeof(msg));
    return 0;
}

