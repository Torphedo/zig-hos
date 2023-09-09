#include <stdbool.h>
#include <string.h>
#include <stdint.h>

#include "hos_syscall.h"

int main() {
    uint32_t num = 5;

    const char msg[] = "Zig syscall test.\n";

    while (true) {
        svcOutputDebugString(msg, strlen(msg));
    }
    return num;
}

