#include "vfile.h"

vfile vfile_open(void* ptr, u32 size) {
    return (vfile) { .ptr = (u8*)ptr, .pos = 0, .size = size};
}

bool vfile_eof(vfile* file) {
    return (file->pos >= file->size);
}

bool vfile_writecheck(vfile* file, u32 writesize) {
    if (file->pos + writesize >= file->size) {
        // LOG_MSG(warning, "OOB write @ 0x%x / 0x%x [%d bytes]\n", file->pos, file->size, writesize);
        return false;
    }
    return true;
}

