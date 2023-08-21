.set ALIGN,    1<<0
.set MEMINFO,  1<<1
.set FLAGS,    ALIGN | MEMINFO
.set MAGIC,    0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

.section .text
.global _start
.type _start, @function
_start:
		mov $stack_top, %esp

		/*
		This is a good place to initialize crucial processor state before the
		high-level kernel is entered. It's best to minimize the early
		environment where crucial features are offline. Note that the
		processor is not fully initialized yet: Features such as floating
		point instructions and instruction set extensions are not initialized
		yet. The GDT should be loaded here. Paging should be enabled here.
		C++ features such as global constructors and exceptions will require
		runtime support to work as well.
		*/

		/*
		Enter the high-level kernel. The ABI requires the stack is 16-byte
		aligned at the time of the call instruction (which afterwards pushes
		the return pointer of size 4 bytes). The stack was originally 16-byte
		aligned above and we've pushed a multiple of 16 bytes to the
		stack since (pushed 0 bytes so far), so the alignment has thus been
		preserved and the call is well defined.
		*/
		call kernel_main

		/*
		If the system has nothing more to do, put the computer into an
		infinite loop. To do that:
		1) Disable interrupts with cli (clear interrupt enable in eflags).
		   They are already disabled by the bootloader, so this is not needed.
		   Mind that you might later enable interrupts and return from
		   kernel_main (which is sort of nonsensical to do).
		2) Wait for the next interrupt to arrive with hlt (halt instruction).
		   Since they are disabled, this will lock up the computer.
		3) Jump to the hlt instruction if it ever wakes up due to a
		   non-maskable interrupt occurring or due to system management mode.
		*/
		cli
1:		hlt
		jmp 1b

.size _start, . - _start	
