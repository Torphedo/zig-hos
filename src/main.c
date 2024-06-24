#include <kernel/svc.h>
#include <sf/tipc.h>
#include <sf/hipc.h>

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

