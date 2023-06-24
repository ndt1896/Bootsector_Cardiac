# Welcome to the Pulp Cardiac (P-C).
# P-C is a Bell Labs "Cardiac" Emulator
# The 1968 classic "Cardboard Illustrative Aid to Computation"
# is implemented as an x86 boostsector program in 2020.
# A farewell salute to the end of INTEL Legacy BIOS support this year.
# - ndt1896, Aug 2020
#
# THE BELL LABS CARDIAC: 
#
# Link:
# 	https://en.wikipedia.org/wiki/CARDboard_Illustrative_Aid_to_Computation
# Archive Version: 
#		Prepend "https://web.archive.org/web/20190217011224/" before "https" above.
#
# The Cardiac Manual, Detailed Introduction, and Collection of Program Listings:
# Link:
# 	https://www.cs.drexel.edu/~bls96/museum/cardiac.html
# Archive Version:
#		Prepend "https://web.archive.org/web/20200606190004/" before "https" above.
#
# The recommended way to proceed is to read the 1968/9 cardiac manual and maybe
# make your own.  Instructions and modern cut-outs can be found at: 
# https://www.instructables.com/id/CARDIAC-CARDboard-Illustrative-Aid-to-Computation-/
#
# It will also be useful to have a reference card with the 10 Cardiac Op codes handy.
#
# A video:
# "Bell Labs - THE THINKING MACHINE" was also shipped to schools along with
# the cardiac kits and is on youtube.com:
# https://www.youtube.com/watch?v=Ho5fy3BieSM
# Warning: Creepy start, more interesting when discussing technology, less the extended metaphor.
#
# An excellent book "The Paper Computer Unfolded: A Twenty-First Century Guide to 
# the Bell Labs CARDIAC (CARDboard Illustrative Aid to Computation), 
# the LMC (Little Man Computer), and the IPC (Instructo Paper Computer)
# by Mark Jones Lorenzo (Author) is available on Amazon (I also have a copy), and, 
# the author rightly comments on some of the sexism in the otherwise 
# insightful 1960's documentation.
#
#	BUILDING AND RUNNING THE PULP CARDIAC:
# 
# --Virtual Machines--: 
#
#		as cardiac.S -defsym EMU_BIOS=1 -o cardiac.o
#		ld -Ttext 0x7c00 -Tdata 0x7F00 --oformat=binary cardiac.o -o cardiac.bin
#
# Run on QEMU:
# 	qemu-system-x86_64 -fda cardiac.bin
# Run on VIRTUAL BOX:
#		dd if=cardiac.bin of=cardiac.img bs=10M conv=sync
#		VBoxManage convertfromraw cardiac.img cardiac.vdi --format VDI
#
# -- Real Hardware USB (BARE METAL)--:
#
#		as cardiac.S -defsym CLASSIC_BIOS=1 -o cardiac.o
#		ld -Ttext 0x7c00 -Tdata 0x7F00 --oformat=binary cardiac.o -o cardiac.bin
#
#	Write boot USB on UNIX/BSD/Linux:
# 	sudo dd if=cardiac.bin of=/dev/sd[X]
#
# Write boot USB on Windows:
#		"Win32 Disk Imager 1.0" 3rd party program works out of the box.
#		There is also dd for windows: http://www.chrysocome.net/dd
#
# Write boot Floppy on MSDOS:
# "As an operating system, DOS was pretty pathetic" 
#			- Brian Kernighan, co-author of UNIX, C programming Language, AWK, Go Language
#
# MISC COMMANDS AND RESOURCES
#
#	Inspect the binary image:  xxd cardiac.bin
# Note the "magic byte" 0xAA55 at the end of the image
# It is written 55 AA because x86 is a little endian CPU.
#
# C APPROXIMATION OF THE EMULATOR
#
# Strip the "#" comments from the C code below with:
# 	awk '!/^#/{ print >> "cardiac_c_version.c" }' cardiac.S 
#
# ------------- BEGIN C CODE -------------
#/*
#	Register and Helper Variable Description: 
#	ram[] : memory cells
#	ac    : accumulator
#	ir    : instruction register
#	op    : operation code
#	ea    : effective address
#	dp    : ea data pointer
#	pc    : program counter
#			
#	Description:
#			
#	The cardiac contains 100 memory cells.  
#	Each memory cell may contain instructions or data.
#	This is Von-Neumann architecture.
#	There is one addressing mode: indirect addressing.
#	Jumps are an exception and are direct jumps.
#			
#	Instruction Words are 3 digits.  
#	The first digit is the op code.
#	The second digit is the address of the data, or, direct jump address.
#			
#	Bootloader:
#		Memory 000 is preloaded with "001"
#		Memory : Instruction
#			000	: 001
#			001 : 002
#			002 : 800
#		Load your Program:
#			[address] 
#			[instruction]
#			8xx : Jump to your program; xx is start of label
#*/
#	
#	#include <stdio.h>
#	#define RAMSZ	100
#	
#	int dlsft(int *ac, int places)
#	{	
#		/* decimal left shift, max 9999 */
#		for(int i=0;i<places;i++) *ac *= 10;
#		*ac %=10000;	/* mask to accum max */
#	}
#	
#		int drsft(int *ac, int places)
#		{ 
#			/* decimal right shift */
#			for(int i=0;i<places;i++) *ac /= 10;
#		}
#	
#	void main() 
#	{ 
#		/* Bell Labs cardiac */
#		enum opCodes {INP,CLA,ADD,TAC,SFT,OUT,STO,SUB,JMP,HRS};
#					/* 0   1   2   3   4   5   6   7   8   9 */
#		signed int ram[RAMSZ], ac, ir, op, ea, pc;
#		signed int * ed;
#		printf("Bell Labs Cardiac\n");
#		pc=0; ram[0]=1; 		    	/* reset & bootloader */
#		for(;;) {					        	/* cardiac run loop */
#			ir=ram[pc++];	 		   	 	 /* fetch & increment */
#			op=ir/100; ea=ir%100; ed=&ram[ea];	/* decode */	
#			switch(op){											 	 /* execute */
#				case INP: printf(">"); 
#					scanf("%4d",ed);				break;
#				case CLA: ac=*ed;					break;
#				case ADD:	ac+=*ed;				break;
#				case TAC:	if(ac>=0) pc=ea;		break;
#				case SFT:	dlsft(&ac,ea/10);
#							drsft(&ac,ir%10);		break;
#				case OUT:	printf("%d\n",*ed);		break;
#				case STO:	*ed=ac;					break;
#				case SUB:	ac-=*ed;				break;
#				case JMP:	ram[RAMSZ-1]=(800*pc);
#										pc=ea;		break;
#					case HRS:	pc=ea;				main();
#				}
#			}
#		}
#
# ------------- END C CODE -------------
#
# LOADING AND RUNNING A PROGRAM ON THE PULP CARDIAC
#
# Below is a step-by-step method to load and run the 
# "Add 2 numbers" program introduced in the Bell Labs Cardiac Manual
#
# 1: CONFIRM YOUR COMPUTER or EMULATOR BOOTED
#	
# Running with "EMU_BIOS" defined (QEMU, VirtualBox, Some Bare Metal Hardware will be OK): 
# 
# On boot, the emulated VGA output output a blue background with yellow text.
# The Yellow text will say:
#
# cardiac*
# > 
# 
# Running with "CLASSIC_BIOS" defined, the screen will be black and white, 
# And there will only be a * as the welcome message.  The word "cardiac" will not appear. 
#
# 2: YOUR FIRST PROGRAM
#
# The goal is to restart the cardiac.  The Op code for stop and reset is Op Code 9xx.
# There should be a blinking cursor next to the ">" symbol.
# >_
# Try typing "900" with your keyboard and pressing enter.
#
# If the command is successful, the cardiac will reset and the welcome message will re-appear:
#
# cardiac*
# >900
# >cardiac*
# >_
#
# 3: ENTERING PROGRAMS FROM LISTINGS
#
# All of the details are in the Cardiac manual.  Jumping ahead to the execution, 
#
# Consider the following program listing for a program that adds 6+5: 
#
# Memory Cell	|	Instruction
# 010 005	; Memory Location 10 has the value 5.
# 011 006	; Memory Location 11 has the value 6
# 012 110	; Load Mem 10 into cleared Accumulator
# 013 211	; Add Mem 11 into Accumulator
# 014 620	; Store Accum. to Mem 20
# 015 520	; Print Contents of Mem 20.
# 016 900	; Halt and Reset.  
#
# Program listings follow the above format.  To load this program, you would do this:
#
# 	First, boot your virtual machine or hardware.  
#		Otherwise, we don't know what cell the program counter is pointing to.
#
# Second, type in the following bootstrap program:
# 
#>002[Enter]
#>800[Enter]
#
# Third, now the bootstrap program is loaded, and we can enter the program listing above.
# ** Note, you *must* include the above bootstrap program, otherwise, you aren't loading your code...
#	Type the following:
#
#>010[Enter]
#>005[Enter]
#>011[Enter]
#>006[Enter]
#>012[Enter]
#>110[Enter]
#>013[Enter]
#>211[Enter]
#>014[Enter]
#>620[Enter]
#>015[Enter]
#>520[Enter]
#>016[Enter]
#>900[Enter]
#
# Fourth, double check your work and then jump to the start of the code with:
#
#>812[Enter]
#
# If this is successful, you will see the following output:
#
#>011*
#>cardiac*
#
# The Cardiac computed the value of 6 + 5 and printed the results.  
# Finally, the cardiac reset itself with the last instruction 900.
#
# Now, reload the bootloader, and try loading an example from the cardiac book
# or one of the on-line sources.
#
# PULP CARDIAC SPECIFIC USAGE NOTES: 
#
#
# 1) All input must be EXACTLY 3 characters (except negative numbers).  The value 27 is input as 027.
# 2) Negative numbers are OK.  Negative Twelve is input as -012.
# 3) Backspace is allowed (except negative sign).
# ADVANCED: 
# 4) It is possible to "flip" the sign by pressing the "-" character again.  
# 		Example: You input -042 but you want 042.  Type: "-". The screen will now read -042+.  
#	In other words, pressing the "-" sign will display the current state of the INPUT SIGN flag.
# Consequently, a long expression like "-0+4-2+-+-+" is still a legal way to input 42.  
# Only use the "-" key to change signs.  Do not try to use the "+" key directly. 
#
# By this step, you may have watched a video, made a real cardiac out of paper, 
# and read the short Bell labs manual in full.
#
# The next step in my journey is to bootload graphics, sample programs, a small op-code assembler, from a disk into
# 16 bit real mode x86 Assembly.  It may use FAT16, or just borrow the next few "sectors" on a boot disk.
#  That will be a "second stage bootloader."  
#
# Finally, the switch will be made to protected mode, and the C version of the cardiac will run on a 
# micro "Operating System."  
#
#
# About GNU AS: 
# % means register.  $ means number.
# Code is written INSTRUCTION SOURCE DESTINATION.  
#
#
BOOTSEC 			= 	0x7c00	# Boot sector entry point
																	# Bios routines:
BIOS_GETCHAR_CMD	= 	0x00		# CMD is loaded into %ah,
BIOS_GETCHAR_INT	= 	0x16		# INT[urrupt] is loaded into %al

BIOS_PUTCHAR_CMD	= 	0x0e		# Teletype Mode
BIOS_PUTCHAR_INT	= 	0x10		# Print 1 char to screen and advance cursor

BIOS_DELAY_CMD		=	0x00
BIOS_DELAY_INT		=	0x00

ASCII_OFFSET		=	0x30		# Equivalent to int i = 'i'-'0'
									# Bell Labs CARDIAC Opcodes:
OP_INP	=				0			# Input
OP_CLA	=				1			# Clear & Add
OP_ADD	=				2			# Add
OP_TAC	=				3			# Test Accum (Conditional Jump)
OP_SFT	=				4			# Shift
OP_OUT	=				5			# Output
OP_STO	=				6			# Store to Memory
OP_SUB	=				7			# Subtract
OP_JMP	=				8			# Jump (Unconditional Jump)
OP_HRS	=				9			# Halt and Reset

.code16								# Generate 16-bit code
.text                      			# Executable code location

.globl _start;						# Make entry point visible to linker

_start:                    			# Entry point
	
init:  											

	cli								# Disable interrupts
	cld								# Clear Inc/Dec Flag, rep/loop will dec counters.
	xor %ax, %ax					# Clear %ax
	mov %ax, %ds					# Data Segment
	mov %ax, %es					# Extra Segment
	mov %ax, %ss					# Stack Segment
	mov %ax, %sp					# Stack Pointer
	
zero_cardiac_ram:
	mov $2*512, %cx					# Init 512words Memory to 0; dec counter in %cx
	mov $buffer, %di				# Destination index (pointer) %di
	rep stosw
	
	open_bpb_space:					# Open 26 Bytes for DOS 3.31 BPB (and below)
		.ifdef CLASSIC_BIOS			# Some real-hardware BIOS's try to "help" bootloaders
			.fill 26, 1 , 0x90		# by writing drive numbers etc to addresses where the BPB "should" be.
		.endif						# But Pulp is a bootsector program, not a bootloader with BPB.
	
main:			
	
.ifdef EMU_BIOS
	print_welcome_msg:				# Print welcome message "ok" (currently reduced to just *)
		mov $rwelcome_msg, %si		# Message address to source index $si
		call print_str				# Input: %si, affected:	%ax	
.endif
	
.ifdef CLASSIC_BIOS
	print_welcome_msg:				# See " " 
		mov $welcome_msg, %si					 
		call print_str								
.endif
	
	init_cardiac:
		movw $001, (RAM)			# Preload the cardiac bootloader ram[0]=1;	
	
	execute_cpu:
	
		.ifdef EMU_BIOS
			setTextAttr:
				mov $0x1e, %al 		# mov $0x1e, %al  # 52 purple 93 blu
				push %es            # save the seg register
				mov $80*25, %cx     # # of chars to do
				mov $0xB800,%bx     # segment of the screen memory for this video mode
				mov %bx, %es
				xor %di, %di        # point to char data of screen-pos 0,0
			setTextAttrLp:
				inc %di             # advance by 1 to point to the attribute, rather than the char
				stosb               # store our attribute byte to [es:di] and increment di. di now points to a character
				loop setTextAttrLp
				pop %es
		.endif
		
		mov (PC), %si				# Fetch: ir=ram[pc]; 0 on start.
		call load_cram_word			# Takes address in %si, returns IR from memory to %ax
		incw (PC)					#	Increment: pc++;

		decode:
			mov $100, %bl			# Decode: IR/100: 100's digit is op code, rem. 10's down is effective address
			div %bl					# IR is still in %ax; *some* code golf required at the expense of easy-to-read code
			mov %al, (OP) 			# (result) hundreds digit is the op code
			mov %ah, (EA) 			# (remainder) tens and ones digit is the effective address
			
			mov (EA),%si			# %ah is still EA.  Cardiac primary addressing mode is indirect
			call load_cram_word		# Takes address in %si, returns in %ax
			mov %ax, (ED)			# Effective data.  Load once so it can be used in multiple instructions.

		load_op_jump_table:
			mov $table,%bx			# Move opcode branch table address into %bx * table is placed at end of code.  Check the comments there for placement constraints. 
			mov (OP),%ax			# Move opcode into %ax
			add %ax,%bx				# The intent is: the jump table entries are 2 bytes apart: offset = offset*2 
			add %ax,%bx
			jmp *%bx				# Execute the opcode OP.
			
		table:
			jmp EX_IMP 				# The jump table will be assembled to use close jumps (up to +127 offset)
			jmp EX_CLA				# Unless the CARDIAC Op's take long enough that the last jump table entries
			jmp EX_ADD				# Would not fit into 127 bytes.  Most of the CARDIAC ops are simple memory movement
			jmp EX_TAC				# or arathmetic ops.  However, the shift instruction must be processed in decimal,
			jmp EX_SFT				# so an extra jump needed because that routine is (comparatively) long to the other OP codes.
			jmp EX_OUT				# All other op's together are still less than 127 bytes, 
			jmp EX_STO				# and so this jump table will assemble to all use the x86 op code byte-wide jump.
			jmp EX_SUB									
			jmp EX_JMP
			jmp init 				# Cardiac Op code 9xx is implemented as a "restart cardiac" command.

									# Cardiac OpCode jump table:
		EX_IMP:						# Input: printf(">"); scanf("%3d",ed);
			mov $buffer, %di		# Fill the buffer with 3 #'s
			call get_string			# Call process_input parse digits and return a 3 digit number to %dx
			mov %dx,%ax				# Return val in %dx to %ax
			call store_cram_word	# Store in EA
			jmp execute_cpu			# Move next instruction
			
		EX_CLA:						# Clear & Add
			mov (ED),%ax			# ED -> AC no add
			mov %ax, (AC)
			jmp execute_cpu			# Move next instruction
			
		EX_ADD:						# Add
			mov (AC), %ax			# Accum contents are preserved
			add (ED), %ax			# AC = AC + ED
			mov %ax, (AC)
			jmp execute_cpu			# Move next instruction
			
		EX_TAC:						# Test Accumulator (Conditional Jump)
			cmp $0,(AC)				# Use SIGNED info.
			jl take_branch			# Jump if lower than 0; signed
				jmp execute_cpu		# Otherwise continue execution
			take_branch:			# If < 0, take branch
				mov (EA),%ax		# EA -> PC
				mov %ax,(PC)		# Program Counter takes EA
			jmp execute_cpu			# Move next instruction
			
		EX_SFT:						# Shift EA: yx, left y then right z
			jmp exec_shift_op
			
		EX_OUT: 					#	Output: printf("%d\n",*ed);
			mov (ED), %ax
			call process_output		# takes numeric value in (OUT_VAL) returns a 3 digit ASCII number to BUFFER
			mov $buffer, %si		# point the source index to the buffer.
			call print_str			# print the contents of memory at ED.  This will be a 3-digit number.
			mov $welcome_msg, %si 	# mov $new_line, %si
			call print_str			# Prepare for next output: "\r\n>"
			jmp execute_cpu			# Move next instruction
			
		EX_STO:						# Store
			mov (AC), %ax
			call store_cram_word	# store AC to EA			
			jmp execute_cpu			# Move next instruction
			
		EX_SUB:						# Subtract
			mov (AC), %ax								
			sub (ED), %ax			# AC = AC - ED (indirect)
			mov %ax, (AC)
			jmp execute_cpu			# Move next instruction
			
		EX_JMP:						# Jump (Unconditional Jump)
			mov (PC), %ax 			# case JMP:	ram[RAMSZ-1]=pc;
			add $800, %ax
			mov $198, %di
			add $RAM, %di
			stosw
			mov (EA),%ax 			# pc=ea; break;
			mov %ax,(PC)
			jmp execute_cpu			# Move next instruction
		
load_cram_word:
	add %si,%si						# RAM is 16-bit cells, so multiply index by 2 -- replace with 2 ADD to support picky CPU's
	add $RAM, %si					# Add RAM start address offset
	lodsw							# load word into $ax
ret

store_cram_word:
	mov (EA),%di
	add %di,%di						# RAM is 16-bit cells, so multiply index by 2 -- replace with 2 ADD to support picky CPU's								
	add $RAM, %di
	stosw 
ret

exec_shift_op:
			mov (EA), %ax			# Decode op + operand
			mov $10, %bx			# Result: Left Shift Remainder: Right Shift
			div %bl					# %al - shift left.  %ah - shift right.
			mov %ax, (IN_VAL)		# Need to store in a mem variable as %ax over-written during mul/div.

			mov %al, %cl			# %al - result of EA/10 - shift left
			or %al, %al
			jz nextone
			pulseLeft:
				movw (AC), %ax
				mov $10,%bx
				mul %bx				# Multiply * 10 Shifts AC 1 to the left (ex: 123 * 10 = 1230)
				xor %dx,%dx			# Clear remainder reg. 
				mov $10000, %bx		# Now Mask to 4 Digits.  Why 4 not 3? Cardiac AC has 1 extra digit - a carry place.
				div %bx
				mov %dx, (AC)  		# With 16-bit division, result is in %ax and remainder is put in %dx.  
			loop pulseLeft			# Loop the number of times to shift left (counter in %cl)
			
			nextone:
			mov (IN_VAL), %ax
			mov %ah, %cl			# %ah - remainder of EA/10 - shift right
			or %ah, %ah
			jz endone
			
			pulseRight:
				xor %dx, %dx		# Clear remainder reg. 
				mov (AC), %ax
			 mov $10,%bx
				div %bx				# AC/10 Shifts AC 1 to the right (ex: 123 / 10 = 12 rem. x)
				mov %ax, (AC)		# In 16-bit div, result is stored in %ax, remainder in %dx
			loop pulseRight			# Loop the number of times to shift left (counter in %cl)
	endone:
		jmp execute_cpu

process_output:						# Numeric input to single decimal digit ASCII output	

	movb $0x00, %cl					# use %cl as temp reg for negative sign.  Begin with negative sign as 0.
	mov %ax,%dx						# Test if the value to output is negative
	and $0x8000, %dx					
	jz normal						# If the number is positive, process the value "normally."
		xor $0xFFFF, %ax			# If it's a negative number, convert to positive and add the negative sign to output string.
		incw %ax					# Signed negative to positive, I am using !val = ((val ^ $FFFF) + 1)
		movb $0x2D, %cl				# 0x2D is the ASCII char "-" which will indicate negative.
	normal:
		mov $buffer, %di
		movb $100, %bl
		div %bl						# %Al is the result.  The remainder %ah will be used in calculating the next digit.
		add $0x30, %al
		stosb 
		
		movb %ah,%al  				# Store the remainder in al.  Again, keeping track of reg values saves bytes is difficult to read.
		xor %ah,%ah					# Don't need to clear %ah for 8-bit division?  !!! Check the docs !!!
		movb $10, %bl				# Process second digit: result/10 -> remainder is the second digit.
		div %bl
		add $0x30,%al 
		stosb
		
		movb %ah,%al				# move remainder.
		add $0x30,%al
		stosb
		
		movb %cl, %al  				# Append the negative flag.  If no negative, val 0x00 becomes the string terminator.
		stosb
ret

get_string:
   xor %cl, %cl
 
 loop:
   mov $BIOS_GETCHAR_CMD, %ah
   int $BIOS_GETCHAR_INT  			# Block waiting for single key input
 
   cmp $0x08, %al  					# Compare for backspace char
   je backspace   					# yes, handle input
 
   cmp $0x0D, %al  					# Was enter pressed?
   je done      					# Yes, then go to done!
	 
	 cmp $0x2D, %al					# - entered.  # negative flag set?
	 je set_neg_flag
 
   cmp $0x03, %cl  					# 3 chars inputted?
   je loop      					# yes, only let in backspace and enter
 
   mov $BIOS_PUTCHAR_CMD, %ah
   int $BIOS_PUTCHAR_INT      		# print (echo) out character
 
   stosb 							# put character in buffer
   inc %cl
   jmp loop
	 
	set_neg_flag:
		mov $BIOS_PUTCHAR_CMD, %ah
		xor $1, (NF)				# Check the Zero flag
		jz NF_ON
			jmp neg_done
		NF_ON:
			mov $0x2B, %al			# change to +
		neg_done:
			int $BIOS_PUTCHAR_INT   # print (echo) out character
			jmp loop
 
	backspace:
   cmp $0, %cl						# beginning of string?
   je loop							# yes, ignore the key
 
   dec %di							# movb $0,(%di)	# Implied step - OPTOMIZED OUT delete character because it MUST be back filled for program to continue.
   dec %cl							# decrement counter as well
 
	 mov $bksp_str, %si
	 call print_str
 
   jmp loop							# go to the main loop
 
	done:
	 cmp $0x03, %cl  				# exactly 3 chars inputted?
   jne loop      					# Go back if not exactly 3 chars input
									# since buffer[3] is ALWAYS 0 - this can be optomized out. null terminator
	mov $new_line, %si
	call print_str
			
	process_input:					# take $buffer and output int to %IN_VAL
		xor %dx,%dx
		mov $3, %cx					# the number of times to loop should be cx
		mov $radix, %si
		mov $buffer, %bx

	digitloop:						#now consider:
		lodsb	
		sub $0x30,(%bx)				# Subtrack 0x30, converting to decimal. '0'
		mulb (%bx)
		add %ax, %dx		
		inc %bx
	loop digitloop
	
									# now the question on everyone's minds: Is %dx actually.....NEGATIVE?	
	cmp $0, (NF)
	je no_neg
	xor $0xFFFF, %dx				# -(INT) == INT xor (FFFF) + 1
	inc %dx
	movb $0, (NF)					# reset 0 flag
	no_neg:
ret									# result is in dx
	
print_str:	
	movb $BIOS_PUTCHAR_CMD, %ah
	load_next:
		lodsb						# load SI into AL and increment.
		or %al, %al					# is al 0?
		jz str_done
		int $BIOS_PUTCHAR_INT
		jmp load_next
	str_done: 
ret

bksp_str:
	.byte 0x08,0x20,0x08,0x00

radix:
	.byte 0x64, 0x0a, 0x01

.ifdef EMU_BIOS
	rwelcome_msg:
		.ascii "cardiac"							
.endif

welcome_msg: 
	.ascii "*" 						# stores the string (plus a byte with value "0") and gives us access via $msg
new_line:
	.asciz "\r\n>"

.fill 510-(.-_start), 1, 0 			# add 0's as padding to make code 510 bytes long
.word 0xaa55 						# "magic bytes" that tell BIOS that this is bootable

.section .bss						# Heap Section

	.comm buffer,	6
	.comm IN_VAL,	2		
	.comm OUT_VAL,	2   

	.comm AC,			2			# Accumulator
	.comm IR,			2			# Instruction Register
	.comm OP,			2			# Opcode
	.comm EA,			2			# Effective Address
	.comm ED,			2			# Effective Data
	.comm PC,			2			# Program Counter
	.comm NF,			1			# Negative Flag
	.comm RAM,		200				# Cardiac RAM/ROM
	