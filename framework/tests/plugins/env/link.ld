OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

SECTIONS
{
  /* -------------------------------- */
  /* Instruction Memory               */
  /* -------------------------------- */
  /* Start */
  . = 0x00000000;

  /* Text init (necessary for RISCOF Framework) */
  .text.init : { *(.text.init) }
  
  /* TEXT (Instructions to be executed) */
  . = ALIGN(0x1000);
  .text : { *(.text) }

  /* -------------------------------- */
  /* Data Memory                      */
  /* -------------------------------- */
  /* Start */
  . = 0x10000000;

  /* ToHost (necessary for RISCOF Framework) */
  .tohost : { *(.tohost) }
  . = ALIGN(0x1000);
  
  /* Data (Initialized Global/Static Variables) */
  .data : { *(.data) }

  /* Data string (necessary for RISCOF Framework) */
  .data.string : { *(.data.string)}

  /* Stack */
  .bss : { *(.bss) }

  /* Identify where program ends (Heap allocation) */
  _end = .;
}

