/*
	Linker script for the fx9860g platform. Most of the symbols defined
	here are used in the initialization routine in core/start.c; others are
	used in core/setup.c.
*/

/* fx9860g may mean SH3 or SH4 and we want full compatibility */
OUTPUT_ARCH(sh4)
/* ELF offers a lot of symbol/section/relocation insights */
OUTPUT_FORMAT(elf32-sh)
/* Located in core/start.c */
ENTRY(_start)

MEMORY
{
	/* Userspace mapping of the add-in (G1A header takes 0x200 bytes) */
	rom   (rx):   o = 0x00300200, l = 500k

	/* User RAM is mapped at 0x08100000 through MMU; usually 8k on SH3, 32k
	   on SH4. This script exposes only 6k to the user, reserving:
	   * 0x200 bytes for text accessed without the TLB when SR.BL=1, linked
	     into the rram region below, then loaded dynamically
	   * 0x600 bytes for the VBR space, also without MMU
	   On SH3, the VBR space consumes these 0x600 bytes. On SH4, it spans
	   0x1100 bytes near the end of the user RAM, which is larger; the 6k
	   left for the user are honored in both cases. Unused memory from the
	   exposed 6k and non-exposed memory is available through malloc(). */
	/* ram   (rw):   o = 0x08100200, l = 32k */
	ram   (rw):   o = 0x88040000, l = 256k

	/* This region represents the first block of user RAM. Linker arranges
	   sections as if linked to address 0, then gint's runtime determines
	   the location and relocates references (which are manual) */
	rram  (rwx):  o = 0x00000000, l = 512

	/* On-chip IL memory */
	ilram (rwx):  o = 0xe5200000, l = 4k
	/* On-chip X and Y memory */
	xyram (rwx):  o = 0xe500e000, l = 16k
}

SECTIONS
{
	/*
	**  ROM sections
	*/

	/* First address to be mapped to ROM (including G1A header) */
	_brom = 0x00300000;
	/* Size of ROM mappings */
	_srom = 0x200
	      + SIZEOF(.text) + SIZEOF(.rodata)
	      + SIZEOF(.gint.drivers) + SIZEOF(.gint.blocks);

	/* Machine code going to ROM:
	   - Entry function (.text.entry)
	   - Compiler-provided constructors (.ctors) and destructors (.dtors)
	   - All text from .text and .text.* (including user code)
	   - Code sections from fxlib, named "C" and "P" */

	.text : {
		*(.text.entry)

		_bctors = . ;
		KEEP(*(.ctors .ctors.*))
		_ectors = . ;

		_bdtors = . ;
		KEEP(*(.dtors .dtors.*))
		_edtors = . ;

		_gint_exch_start = . ;
		KEEP(*(.gint.exch))
		_gint_exch_size = ABSOLUTE(. - _gint_exch_start);

		_gint_tlbh_start = . ;
		KEEP(*(.gint.tlbh))
		_gint_tlbh_size = ABSOLUTE(. - _gint_tlbh_start);

		*(.text .text.*)
		*(C P)
	} > rom

	/* Interrupt handlers going to ROM:
	   - gint's interrupt handler blocks (.gint.blocks)

	   Although gint's blocks end up in VBR space, they are selected and
	   installed on-the-fly by the library and the drivers, so we can't
	   just put them in the vbr region and wait for the copy */
	.gint.blocks : {
		KEEP(*(.gint.blocks));
	} > rom

	/* Driver data going to ROM:
	   - Exposed driver interfaces (.gint.drivers)

	   The driver information is required to start and configure the
	   driver, even if the symbols are not referenced */
	.gint.drivers : {
		_gint_drivers = . ;
		KEEP(*(SORT_BY_NAME(.gint.drivers.*)));
		_gint_drivers_end = . ;
	} > rom

	/* Read-only data going to ROM:
	   - Resources or assets from fxconv or similar converters
	   - Data marked read-only by the compiler (.rodata and .rodata.*) */
	.rodata : SUBALIGN(4) {
		/* Put these first, they need to be 4-aligned */
		*(.rodata.4)

		*(.rodata .rodata.*)
		*(.gint.rodata.sh3)
	} > rom



	/*
	**  RAM sections
	*/

	. = ORIGIN(ram);

	/* BSS stuff going to RAM:
	   - Data marked BSS by the compiler
	   - BSS sections from fxlib, namely "B" and "R"
	   The BSS section is to be stripped from the ELF file later, and wiped
	   at startup. */
	.bss (NOLOAD) : {
		_rbss = . ;

		*(.bss .bss.* COMMON)
		*(B R)

		. = ALIGN(16);
	} > ram :NONE

	_sbss = SIZEOF(.bss);

	/* Read-write data going to RAM:
	   - Data sections generated by the compiler (.data and .data.*)
	   - Data sections from fxlib, "D"
	   - The SH3-only data section (.gint.data.sh3) */
	.data ALIGN(4) : ALIGN(4) {
		_ldata = LOADADDR(.data);
		_rdata = . ;

		_lreloc = . ;
		*(.gint.mappedrel);
		_sreloc = ABSOLUTE(. - _lreloc);

		*(.data .data.*)
		*(D)
		*(.gint.data.sh3)

		. = ALIGN(16);
	} > ram AT> rom

	/* Read-write data sub-aligned to 4 bytes (mainly from fxconv) */
	.data.4 : SUBALIGN(4) {
		*(.data.4)
		. = ALIGN(16);
	} > ram AT> rom

	_sdata = SIZEOF(.data) + SIZEOF(.data.4);

	/* gint's uninitialized BSS section */
	.gint.bss (NOLOAD) : {
		/* Since it's uninitialized, the location doesn't matter */
		*(.gint.bss .gint.bss.sh3)

		. = ALIGN(16);

		/* End of user RAM */
		_euram = . ;
	} > ram :NONE

	_sgbss = SIZEOF(.gint.bss);

	/* On-chip memory sections: IL, X and Y memory */

	. = ORIGIN(ilram);
	.ilram ALIGN(4) : ALIGN(4) {
		_lilram = LOADADDR(.ilram);
		_rilram = . ;

		*(.ilram)

		. = ALIGN(16);
	} > ilram AT> rom

	. = ORIGIN(xyram);
	.xyram ALIGN(4) : ALIGN(4) {
		_lxyram = LOADADDR(.xyram);
		_rxyram = . ;

		*(.xram .yram .xyram)

		. = ALIGN(16);
	} > xyram AT> rom

	_silram = SIZEOF(.ilram);
	_sxyram = SIZEOF(.xyram);



	/*
	**  Relocated no-MMU RAM sections
	*/

	. = ORIGIN(rram);

	/* Code that must remain permanently mapped (.gint.mapped); relocated
	   to start of user RAM at startup, accessed through P1 */
	.gint.mapped ALIGN(4) : ALIGN(4) {
		_lgmapped = LOADADDR(.gint.mapped);
		*(.gint.mapped)
		. = ALIGN(16);
	} > rram AT> rom

	_sgmapped = SIZEOF(.gint.mapped);



	/*
	**  Unused sections
	*/

	/DISCARD/ : {
		/* Java class registration (why are they even here?!) */
		*(.jcr)
		/* Asynchronous unwind tables: no C++ exception handling */
		*(.eh_frame_hdr)
		*(.eh_frame)
		/* Comments or anything the compiler might generate */
		*(.comment)
	}
}
