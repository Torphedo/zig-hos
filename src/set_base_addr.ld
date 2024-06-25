OUTPUT_FORMAT(elf64-littleaarch64)
OUTPUT_ARCH(aarch64)

ENTRY(_module_start)

PHDRS
{
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
  dynamic PT_DYNAMIC;
  tls_init PT_TLS;
  tls PT_TLS;
}

SECTIONS
{
  PROVIDE(_module_start = 0x0);
  . = _module_start;
  __code_start__ = .;

  /* App code */
  .text : {
    HIDDEN(__text_start__ = .);
    KEEP (*(.text.crt0))
    *(.text .text.*)
    HIDDEN(__text_end__ = .);
  } :text

  /* Trampoline and stuffs */
  .plt : { *(.plt .plt.*) } :text
  __code_end__ = .;

  /* Read-only sections */
  . = ALIGN(0x1000);

  /* App name */
  .module_name : { KEEP (*(.nx-module-name)) } :rodata

  /* Make sure everything is aligned */
  . = ALIGN(8);

  /* App rodata */
  .rodata : {
    *(.rodata .rodata.*)
  } :rodata

  /* All the symbols needed for relocation lookup */
  .hash     : { *(.hash) } :rodata
  .gnu.hash : { *(.gnu.hash) } :rodata
  .dynsym   : { *(.dynsym .dynsym.*) } :rodata
  .dynstr   : { *(.dynstr .dynstr.*) } :rodata

  __rel_dyn_start__ = .;
  .rel.dyn : { *(.rel.dyn) } :rodata
  __rel_dyn_end__ = .;

  __rela_dyn_start__ = .;
  .rela.dyn : { *(.rela.dyn) } :rodata
  __rela_dyn_end__ = .;

  __rel_plt_start__ = .;
  .rel.plt        : { *(.rel.plt) } :rodata
  __rel_plt_end__ = .;

  __rela_plt_start__ = .;
  .rela.plt       : { *(.rela.plt) } :rodata
  __rela_plt_end__ = .;

  /* All exception handling sections */
  .gcc_except_table : { *(.gcc_except_table .gcc_except_table.*) } :rodata
  .eh_frame_hdr : {
    HIDDEN(__eh_frame_hdr_start__ = .);
    *(.eh_frame_hdr)
    HIDDEN(__eh_frame_hdr_end__ = .);
  } :rodata
  .eh_frame : { KEEP (*(.eh_frame)) } :rodata

  /* Misc .rodata stuffs (build-id, etc.) */
  .note.gnu.build-id : { *(.note.gnu.build-id) } :rodata

  /* Read-write sections */
  . = ALIGN(0x1000);

  PROVIDE (__data_start = .);
  /* App data */
  .data : {
    *(.data .data.*)
  } :data

  /* This section should be made read only after relocation but in practice we will not do that */
  .data.rela.ro : {
    *(.data.rela.ro.local*)
    *(.data.rela.ro .data.rela.ro.*)
  } :data

  /* This section should be made read only after relocation but in practice we will not do that */
  .data.rel.ro : {
    *(.data.rel.ro.local*)
    *(.data.rel.ro .data.rel.ro.*)
  } :data

  /* All GOT sections */
  __got_start__ = .;
  .got : { *(.got.plt) *(.igot.plt) *(.got) *(.igot) } :data
  __got_end__ = .;

  /* The dynamic section as we need it to be stored in the binary */
  .dynamic : {
    HIDDEN(__dynamic_start__ = .);
    *(.dynamic)
  } :data :dynamic

  /* Align for .init_array/.fini_array */
  . = ALIGN(8);

  .preinit_array ALIGN(8) :
  {
    PROVIDE (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE (__preinit_array_end = .);
  } :data

  /* App init array */
  .init_array : {
    PROVIDE (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*)))
    KEEP (*(.init_array))
    PROVIDE (__init_array_end  = .);
  } :data

  /* App fini array */
  .fini_array : {
    PROVIDE (__fini_array_start__ = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*)))
    KEEP (*(.fini_array))
    PROVIDE (__fini_array_end__ = .);
  } :data

  /* Thread Local sections */

  .data : /* For ld.bfd:  ALIGN_WITH_INPUT */ {
      *(.data .data.*)
      *(.gnu.linkonce.d.*)

      /* Need to pre-align so that the symbols come after padding */
      . = ALIGN(8);

      PROVIDE( __global_pointer$ = . + 0x800 );
      PROVIDE( _gp = . + 0x8000);
      *(.sdata .sdata.* .sdata2.*)
      *(.gnu.linkonce.s.*)
  }
  PROVIDE(__data_start = ADDR(.data));
  PROVIDE(__data_source = LOADADDR(.data));

  .tdata : ALIGN(__tls_align) {
    __tdata_align_abs__ = ABSOLUTE(.);
    __tdata_start__ = .;
    *(.tdata .tdata.*)
    __tdata_end__ = .;
    PROVIDE(__data_end = .);
  } :data :tls_init

  PROVIDE( __data_size = __data_end - __data_start );
  PROVIDE( __data_source_size = __data_source_end - __data_source );
  PROVIDE( __tls_base = ADDR(.tdata));
  PROVIDE( __tdata_start = ADDR(.tdata));

  .tbss (NOLOAD) : {
    __tbss_align_abs__ = ABSOLUTE(.);
    __tbss_start__ = .;
    *(.tbss .tbss.*)
    *(.tcommon)
    __tbss_end__ = .;
  } :data :tls
  PROVIDE( __arm64_tls_tcb_offset = MAX(16, __tls_align) );
  PROVIDE( __tls_align = MAX(ALIGNOF(.tdata), ALIGNOF(.tbss)) );

  /* BSS section */
  . = ALIGN(0x1000);

  .bss : {
    HIDDEN(__bss_start = .);
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(8);
    HIDDEN(__bss_end = .);
    . = ALIGN(0x1000);
  } :data
  PROVIDE( __bss_size = __bss_end - __bss_start );

  . = ALIGN(8);

  __end__ = ABSOLUTE(.);
  PROVIDE (__heap_start = __bss_end);
  PROVIDE (__heap_end = __bss_end + 0x00010000);
  PROVIDE (__heap_size = __heap_end - __heap_start);

  HIDDEN(__argdata__ = .);

  /DISCARD/ : {
    /* No need of the interpreter */
    *(.interp)
  }
}
