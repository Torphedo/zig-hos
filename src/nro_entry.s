/*
    Thanks to Shadow's exlaunch project for having a slightly easier to
    understand build process than other NROs. This startup code & linker script
    are taken from their project.
                    https://github.com/shadowninja108/exlaunch
*/

.section ".text.crt0","ax"
_module_start:
    b aarch64_start
    // Put MOD0 offset in the NRO file.
    .word __nx_mod0 - _module_start

    // MOD0 has to start after the NRO header and at a power of 2 offset
    .balign 0x80

__nx_mod0:
    .ascii "MOD0"
    .word  __dynamic_start__        - __nx_mod0
    .word  __bss_start              - __nx_mod0
    .word  __bss_end                - __nx_mod0
    .word  __eh_frame_hdr_start__   - __nx_mod0
    .word  __eh_frame_hdr_end__     - __nx_mod0
    .word  main - __nx_mod0

// Put the rest of the code at the next 0x10 boundary just to make it neater
.balign 0x10

aarch64_start:
    // Normal picolibc init has to enable the FPU and init the stack. Since
    // we're running under HOS, we don't need any of that.

    // Jump into C code, passing it the mod0 header pointer.
    adr x0, __nx_mod0
    bl crt_entry
    
    // svcExitProcess(). Ryujinx doesn't respect this, but we'll do it anyway.
    svc 0x7
// Loop forever to prevent invalid opcode crashes
loop:
    b loop

