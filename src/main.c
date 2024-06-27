#include "int.h"
#include "vfile.h"
#include "aarch64.h"
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

typedef enum {
    HIPC_MSG_INVALID, 
    HIPC_MSG_INVOKE_METHOD_DEPRECATED, 
    HIPC_MSG_RELEASE, 
    HIPC_MSG_INVOKE_MANAGER_METHOD_DEPRECATED, 
    HIPC_MSG_INVOKE_METHOD, 
    HIPC_MSG_INVOKE_MANAGER_METHOD, 
}hipc_msg_type;

enum {
    // Just an arbitrary size, TLS should be writable with no problems.
    HIPC_MSG_SIZE = 0x4000,
};

int main() {
    const char* msg = "Hello from C!\n";
    svcOutputDebugString(msg, strlen(msg));

    Handle sm;
    Result rc = svcConnectToNamedPort(&sm, "sm:");
    if (rc != RESULT_SUCESS) {
        const char* sm_fail = "Failed to open port sm:\n";
        svcOutputDebugString(sm_fail, strlen(sm_fail));
        return 1;
    }
    svcOutputDebugString("Got Service manager handle!\n", 28);
    // const char sm_pass[256] = {0};
    // sprintf(sm_pass, "Got Service Manager handle 0x%x\n", &sm);
    // svcOutputDebugString(sm_pass, strlen(sm_pass));

    HipcHeader header = {0};

    vfile hipc_msg = vfile_open(tls_ptr(), HIPC_MSG_SIZE);
    header.type = HIPC_MSG_INVOKE_METHOD;
    VFILE_WRITE(HipcHeader, &hipc_msg, header);

    return 0;
}

