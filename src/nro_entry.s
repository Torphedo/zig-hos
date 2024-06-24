/*
    Thanks to Shadow's exlaunch project for having a slightly easier to
    understand build process than other NROs. This startup code & linker script
    are taken from their project.
                    https://github.com/shadowninja108/exlaunch
*/

.section ".text.crt0","ax"

.global __module_start
__module_start:
    b _pre_start

    // Put MOD0 offset in the NRO file.
    .word __nx_mod0 - __module_start

    // MOD0 has to start after the NRO header and at a power of 2 offset
    .balign 0x80

__nx_mod0:
    .ascii "MOD0"
    .word  __dynamic_start__        - __nx_mod0
    .word  __bss_start__            - __nx_mod0
    .word  __bss_end__              - __nx_mod0
    .word  __eh_frame_hdr_start__   - __nx_mod0
    .word  __eh_frame_hdr_end__     - __nx_mod0
    .word  main - __nx_mod0

// Put the rest of the code at the next 0x10 boundary just to make it neater
.balign 0x10

test_text:
.ascii "Assembly printing test\n"
.balign 0x10
_pre_start:
    adr X0, test_text
    movz X1, 23
    svc 0x27
    
    b main

    # elf2nro complains about the ELF format if we don't branch to _start,
    # so this is a dirty hack to link in libc even though we can't use it
    b _start

