/*
    Thanks to Shadow's exlaunch project for having a slightly easier to
    understand build process than other NROs. This startup code & linker script
    are taken from their project.
                    https://github.com/shadowninja108/exlaunch
*/

.section ".text.crt0","ax"

.global _start
_start:
    b main

    // Put MOD0 offset in the NRO file.
    .word __nx_mod0 - _start

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

