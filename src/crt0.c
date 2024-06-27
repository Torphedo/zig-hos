#include <stdint.h>
#include <memory.h>

typedef struct {
    uint32_t magic; // "MOD0"
    uint32_t dynamic_offset;
    uint32_t bss_start;
    uint32_t bss_end;
    uint32_t eh_frame_hdr_start;
    uint32_t eh_frame_hdr_end;
    uint32_t module_offset;
}mod0_header;

// Exported from linker
extern void* __data_start;
extern void* __data_source;
extern void* __data_size;

// "User" code entrypoint
int main(int, char **);

// Recreation of the normal picolibc crt init function, but using NRO header
// data for more reliable .bss size (prevents a segfault)
void crt_entry(mod0_header* mod0) {
    memcpy(__data_start, __data_source, (uintptr_t) __data_size);
    void* bss_section = (uint8_t*)mod0 + mod0->bss_start;
    memset(bss_section, '\0', (uintptr_t) mod0->bss_end - mod0->bss_end);

    main(0, NULL);
}

