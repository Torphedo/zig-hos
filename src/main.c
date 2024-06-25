#include <string.h>

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
    const char* msg = "Hello from C!\n";
    svcOutputDebugString(msg, strlen(msg));

    Handle sm;
    Result rc = svcConnectToNamedPort(&sm, "sm:");
    if (rc != RESULT_SUCESS) {
        const char* sm_fail = "Failed to open port sm:\n";
        svcOutputDebugString(sm_fail, strlen(sm_fail));
    }
    else {
        // const char sm_pass[256] = {0};
        svcOutputDebugString("Got Service manager handle!\n", 28);
        // sprintf(sm_pass, "Got Service Manager handle 0x%x\n", &sm);
        // svcOutputDebugString(sm_pass, strlen(sm_pass));
    }

    return 0;
}

