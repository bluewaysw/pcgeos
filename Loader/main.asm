COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader -- PC/GEOS kernel loader
FILE:		main.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
	LoadGeos	Entry point

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	tony	1/11/91	Initial Revision

DESCRIPTION:
	This program loads the PC/GEOS kernel.

	$Id: main.asm,v 1.1 97/04/04 17:26:55 newdeal Exp $

------------------------------------------------------------------------------@

_Loader		=	1
_Kernel		= 	1	; This makes life easier in many cases, not the
				;  least of which is debugging, b/c we get the
				;  various data structures that would otherwise
				;  be defined in the "geos" library segment.

EC_INT_STATUS	=	0	;For writing INT_ON status to aux display

DEBUG_INT_STATUS	macro
if	EC_INT_STATUS
	call	DisplayIntStatus
endif
endm

include geos.def
include char.def
include heap.def
include library.def

include system.def		;for SysGetVideoConfig, SysInitialTextMode, etc.
include	color.def		;for Color enum.

include Internal/dos.def
include Internal/debug.def
include Internal/kLoader.def
include Internal/heapInt.def
include Internal/geodeStr.def
include Internal/fileStr.def
include Internal/geosts.def

include loader.def
.ioenable

	cgroup	group	kcode, stack


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub routine to notify the Swat stub that we've done
		something. THIS MUST BE THE FIRST FUNCTION IN KCODE

CALLED BY:	MoveLoader, LoadGeos
PASS:		al	= DebugLoaderFunction
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyStub	proc	near
		.enter
	rept	6			; room for pushf and direct far call
		nop
	endm		
		.leave
		ret
NotifyStub	endp

	assume cs:kcode, ds:kcode, es:kcode


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadGeos

DESCRIPTION:	Load the kernel (kernel{ec}.geo)

CALLED BY:	MS-DOS (on program startup)

PASS:
	ds, es - PSP

RETURN:
	never

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

1) Relocate loader to high memory
2) Locate geos.geo (using PATH if necessary) and cd to  that directory
3) Open the strings file (geos.str)
4) Open the geos.ini file and find the number of handles
5) Open geos.geo, get size of dgroup (kdata)
5) Initialize the heap, allocate handles for the loader and for kdata
6) "GeodeLoad" geos.geo
	a) Create a core block
	b) Allocate resources
	c) Load pre-loaded resources
7) Jump to kernel's LibraryEntry, passing various data we've obtained

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@


LoadGeos	proc	far

if	EC_INT_STATUS
	call	InitDebugDisplay
endif
	DEBUG_INT_STATUS

	cld

	segmov	ds, cs
	mov	ds:[loaderVars].KLV_pspSegment, es
	mov	ax, es:[PSP_envBlk]
	mov	ds:[loaderVars].KLV_envSegment, ax
	segmov	es, cs

ifidn	HARDWARE_TYPE, <RESPG2>

;	Fix up the timer so it goes off 60 times/second

	mov	dx, 0xF804
	mov	al, 0x0c
	out	dx, al
endif

if	0	;Moved to BIOS

;	Mysterious hardware tweaks for RESPONDER that have not yet been
;	fully explained to me - they have something to do with having the
;	bus controller generate the RDY line instead of the chip select
;	controller, but who knows what that means? Anyway, they let us
;	run from FLASH.

	mov	dx, 0xF400
	mov	al, 0x41
	out	dx, al

	mov	dx, 0xF420
	mov	al, 0x01
	out	dx, al

endif


ifidn HARDWARE_TYPE, <PC>
	;
	; The first thing to do is to walk the MCB chain to look for a 
	; loader that has TSRed. 
	;
	call	FindLoaderTSRStub
	jnc	noTSR

	jmp	TransferControlToLoaderTSR	;will exit the program
	.unreached

noTSR:
endif

	segmov	ds, cs

	;set basic defaults for video-configuration variables
	;(If NO_AUTODETECT is defined, these variables will remain this way.)

	mov	ds:[loaderVars].KLV_initialTextMode, SITM_UNKNOWN
	mov	ds:[loaderVars].KLV_defSimpleGraphicsMode, SSGM_NONE
	mov	ds:[loaderVars].KLV_curSimpleGraphicsMode, SSGM_NONE

	; move the loader to high memory and continue execution there...

	call	FindMemory	; dx <- high segment address
				; ax, bx, cx destroyed

	; do XIP-specific activities before moving...

BULL <	call	BulletLoadKernel	; bx:ax <- library entry	>
BULL <	push	bx, ax			; push library entry point	>
RED  <	call	RedwoodLoadKernel	; bx:ax <- library entry	>
RED  <	push	bx, ax			; push library entry point	>

FULLXIP <	call	XIPLoadKernel	; bx:ax <- library entry	>
FULLXIP <				; cx, di, si, bp destroyed	>
FULLXIP < 	push	bx, ax		; push library entry pt		>

	call	MoveLoader	; ax, bx, cx, dx, si, di, bp destroyed

	; locate the PC/GEOS "local tree" directory and CD to it

	call	LocateGeosDir

	; attempt to load the strings file from the local tree. Fails
	; gracefully if not there; will try again later.

	call	ReadStringsFile

	; Attempt to open geos.ini file in the local tree. (If not there,
	; then scan for it in the "system tree".) If there is a path= statement
	; in that file, then load other .ini files.

	call	OpenIniFiles

ifndef	NO_AUTODETECT
	;attempt to determine the initial text video mode, and which (if any)
	;of the "simple" graphics modes is possible on this beast.

	call	LoaderDetectVideoModes
endif

ifndef NO_SPLASH_SCREEN
	;If possible, switch to the default graphics mode, and display
	;the splash screen data on it.

	call	LoaderDisplaySplashScreen
endif

	; open geos.ini and find the number of handles

PC <	call	GetNumberOfHandles					>

	; Scan for /sp_<std path name>=<path> on the command line.

PC <	call	ParseCmdLineStdPaths					>

	; parse all paths in any .ini files

	call	GetPaths

	; start loading the kernel

PC <	call	OpenKernelGetDataSize					>

	; Initialize the heap

	call	InitHeap

	; Load in the kernel

PC <	call	LoadKernel		; bx:ax <- library entry	>
PC <	push	bx, ax			; push library entry

	; make the kernel own all allocated blocks

PC <	call	MakeKernelOwnBlocks					>

	; jump to kernel's library entry point
	;	pass:
	;		ds, es - kernel's dgroup
	;		ss:sp - kernel's stack
	;		cx:dx - KernelLoadervars structure

	pop	bx, ax
	mov	cx, es
	mov	dx, offset loaderVars
	mov	si, cs:[loaderVars].KLV_dgroupSegment

	mov	ds, si
	mov	ss, si
	mov	sp, es:[loaderVars].KLV_handleTableStart
	mov	es, si
	push	bx, ax


	; let the debugger know we're launching the kernel (passing cx:dx)

kernelLoaded::
	mov	al, DEBUG_KERNEL_LOADED
	call	NotifyStub

	; jump to the library entry point.

	mov	di, LCT_ATTACH
	retf

LoadGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLoaderTSRStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out if there is a TSRed loader stub sitting in memory.

CALLED BY:	LoadGeos
PASS:		nothing
RETURN:		if TSRed Loader exists:
			carry set
			ds	= PSP of TSRed Loader
		else:
			carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Walk the MCB chain, looking for the signature of the loader stub.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn HARDWARE_TYPE, <PC>

FindLoaderTSRStub	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter
	;
	; Get the first MCB in the chain by looking at offset -2 of the 
	; es:bx address returned by MSDOS_GET_DOS_TABLES.
	; 
		mov	ah, MSDOS_GET_DOS_TABLES
		int	21h
		mov	ax, es:[bx-2]
		mov	es, ax

	;
	; Follow the MCB chain starting with es:0, looking for the 
	; signature of the swat stub, except that we're not interested
	; in ourselves.
	;

findLoop:
		cmp	es:[MCB_endMarker], MCB_NOT_LAST_BLOCK_MARKER
		jne 	notFound		;end of MCB chain

		mov	ax, es:[MCB_PSP]
		mov	bx, ax
		tst	ax				
		jz	findNext		;skip free blocks
	
		;
		; Look for the right signature. 
		;

		push	es			;save MCB

		; 
		; account for the difference between the PSP and cs in 
		; an EXE program.  cs is the first block after the PSP.
		;
		mov	dx, ax			;save the PSP
		add	ax, 0x10		;skip the PSP
		mov	ds, ax			;ds = cs of TSR (?)
		mov	si, 0 			;signature is at start 
						; of segment
		segmov	es, cs
		mov	di, offset loaderStubSignature
		mov	cx, length loaderStubSignature

		repe	cmpsb
		pop	es			;restore MCB
		stc
		mov	ds, dx			;restore that PSP.
		jz	done

findNext:
		;
		; jump to the next MCB
		;
		mov	ax, es
		add	ax, es:[MCB_size]
		inc	ax
		mov	es, ax
		jmp	findLoop
notFound:
		clc
done:	
	
	.leave
	ret
FindLoaderTSRStub	endp
loaderStubSignature	char	GEOS_TSR_SIGNATURE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransferControlToLoaderTSR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer control to the Loader that is TSRed.

CALLED BY:	LoadGeos
PASS:		ds	= PSP of TSRed Loader.
RETURN:		does not return
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransferControlToLoaderTSR	proc	near
	; 
	; Before transfering control to the TSRed Loader, copy the 7 bytes
	; of NotifyStub to the signature area of the TSRed Loader, which
	; will copy it later into the new version of the Loader it starts...
	;
		mov	dx, ds				
		push	dx				;PSP of TSR
		add	dx, 0x10			;dx = code seg. of TSR
		segmov	ds, cs

		mov	es, dx
		mov	si, offset NotifyStub		;ds:si = NotifyStub
		mov	di, length loaderStubSignature	;es:di = dest. in TSR
		mov	cx, 7
		rep	movsb
		pop	cx				;PSP of TSR

	;	
	; transfer control to TSRed instance of Loader.
	; This is accomplished by setting our PSP_parentId to the PSP of
	; the Loader TSR, and setting PSP_saveQuit to the address to resume
	; execution.  When we exit, DOS will think that the stub had 
	; originally Exec'ed us, and will return execution at the
	; PSP_saveQuit address.
	;
		mov	ax, ds:[loaderVars].KLV_pspSegment
		mov	ds, ax

		; the reload function comes right after the signature.
		mov	ds:[PSP_parentId], cx
		mov	ds:[PSP_saveQuit].segment, dx
		mov	ds:[PSP_saveQuit].offset, offset GTH_reload
	
	;
	; perform a standard exit
	;
		mov	ax, MSDOS_QUIT_APPL shl 8
		int	21h
	
	.unreached
TransferControlToLoaderTSR	endp

endif	; HARDWARE_TYPE, PC


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindMemory

DESCRIPTION:	Check for command line arguments which limit the amount
		of memory available to the heap:

			/mXXX	Where XXX is the location (in K) where the
				top of the heap should be placed. 640 is the
				default. Any value above 640 will be ignored.

			/mrXXX	Where XXX is the amount of memory (in K) at
				the top of memory that should be reserved.
				The default is 0, of course.

		These two options are mutually exclusive. (If both are
		specified, only the first takes effect.)

CALLED BY:	LoadGeos

PASS:
	cs, ds, es, ss - this segment

RETURN:
	dx - high segment address

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Tony	1/91		Moved to loader
	Eric	3/93		Added /mr flag, to reserve space on 512K
				and 640K machines for the transient
				portion of command.com. (Approx 48K)

------------------------------------------------------------------------------@

FindMemory	proc	near
	uses	di, es, bp
	.enter


	; Search throught the command tail
	mov	es, ds:[loaderVars].KLV_pspSegment
	mov	dx, es:[PSP_endAllocBlk]	; end heap at end of

ifidn	HARDWARE_TYPE, <PC>
	mov	di, offset PSP_cmdTail
	mov	cl, es:[di]
	clr	ch				; length of command tail -> cx
	jcxz	done				; if no tail, do nothing
	inc	di				; point past count

;nuked 1/25/93: there is no CR at the end
;	dec	cx				; don't count CR at end
;	jcxz	done

	; Now scan for any arguments

	mov	al, '/'				; switch delimiter -> al
next:
	repne	scasb				; scan for delimiter
	jnz	done				; if none, found, we're done
	cmp	{byte} es:[di], 'm'
	je	foundMemory

	cmp	{byte} es:[di], 'M'
	jne	next

	;We found the memory switch. Read the three-digit value passed

foundMemory:

	cmp	{byte} es:[di]+1, 'r'
	je	reserveSpace

	cmp	{byte} es:[di]+1, 'R'
	stc					; default: is top of memory flag
	jne	readValue			; skip if /m instead of /mr...

reserveSpace:
	;we must reserve the specified amount of space at the top of the heap

	inc	di				;eat this char
	dec	cx
	clc					; flag: is /mr

readValue:
	pushf					; save /m -- /mr flag
	cmp	cx, 4				; ensure four byte are left
						; (m plus three digits)
	jl	handleError			; abort if not...

	mov	cx, 3				; 3 characters
	clr	ax, bp				; clear ah, running total in bp

memLoop:
	inc	di
	mov	al, es:[di]
	sub	al, '0'
	jl	handleError			; if below 0, abort

	cmp	al, 9
	jg	handleError			; if above 9, abort

	shl	bp, 1				; 2 * total -> BP
	mov	bx, bp
	shl	bp, 1				; 4 * total -> BP
	shl	bp, 1				; 8 * total -> BP
	add	bp, bx
	add	bp, ax				; new running total -> BP
	loop	memLoop

	;multiply by 1024 to calculate location in K-bytes, and then divide
	;by 16 to make it a segment address

	mov	cl, 6
	shl	bp, cl				; turn into segment address

	popf					; get /m -- /mr flag
	jnc	checkReservedSpace		; skip if is /mr...

checkNewHeapTop::
	cmp	bp, dx				; compare with real high memory
	ja	doneMem				; abort if too high (use dx)...

	mov	dx, bp				; use the specified top-of-mem
						; value
	jmp	short doneMem

checkReservedSpace:				; handle /mr flag
	sub	dx, bp				; reserve that amount of space
	jc	handleError			; skip if on drugs...

doneMem:
	;make sure that we still have the minimum heap space

	mov	ax, cs				; ax = bottom of heap
	add	ax, MINIMUM_HEAP_SIZE/16	; ax = minimum top of heap
	cmp	ax, dx
	jae	handleError			; skip if error...

done:
endif
	.leave
	ret

ifidn	HARDWARE_TYPE, <PC>
handleError:
	;print an error to the screen and exit to DOS

	ERROR	LS_INVALID_MEMORY_ARGUMENT
endif
FindMemory	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	MoveLoader

DESCRIPTION:	Move the loader to high memory and continue execution there

CALLED BY:	BootGeos

PASS:
	cs, ds, es, ss - this segment
	dx - top of memory

RETURN:
	code running in high memory

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Tony	1/91		Moved to loader

------------------------------------------------------------------------------@

MoveLoader	proc	far	; must be FAR so can return to shifted code.

	; get top of memory...

	mov	ds:[loaderVars].KLV_heapStart, cs


	mov	ds:[loaderVars].KLV_heapEnd, dx

ifidn	HARDWARE_TYPE, <PC>

	; ax <- init size (bytes) -- buffer for .ini file and for strings
	; file added to the end

	mov	ds:[loaderVars].KLV_dgroupSegment, cs
	mov	cx, dx
	mov	ax, LOADER_SIZE
	shr	ax
	shr	ax
	shr	ax
	shr	ax
	inc	ax			;ax = init size (paragraphs)
	sub	cx, ax			;cx = segment for loader
	mov	es, cx			;es = segment
	mov	cs:[simpleAllocSegment], cx

	; move both code and stack

	clr	si
	clr	di
	mov	cx, LOADER_CODE_AND_STACK_SIZE
	shr	cx
	rep movsw			;move the code


	pop	bx			;retf.offset
	pop	cx			;retf.segment

	; use stack in high memory

	mov	ax, es
	mov	ds, ax

	sub	ax, kcode		;adjust to stack segment
	add	ax, stack
	mov	ss, ax

	; modify return address so that we return to high memory

	push	ds			;new segment
	push	bx

endif
	; tell stub where we're living now.

	mov	al, DEBUG_LOADER_MOVED
	call	NotifyStub

	ret

MoveLoader	endp


;---------------------------------------------------------------

if	EC_INT_STATUS

SCREEN_ATTR_NORMAL	equ	07h
SCREEN_ATTR_INV		equ	70h

SCREEN_BASE		equ	0b000h
SCREEN_SIZE		equ	(80*2)*25

displayPos	word	1000

DisplayIntStatus	proc	near
	pushf
	push	ax

	pushf
	pop	ax
	and	ax, 0x200
	mov	al, '0'
	jz	10$
	mov	al, '1'
10$:
	mov	ah, SCREEN_ATTR_NORMAL
	call	DebugPrintChar

	pop	ax
	popf
	ret
DisplayIntStatus	endp

DebugPrintChar	proc	near
	pushf
	push	di, es

	mov	di, SCREEN_BASE
	mov	es, di
	mov	di, cs:[displayPos]
	cmp	di, SCREEN_SIZE
	jnz	5$
	clr	di
5$:
	stosw
	mov	cs:[displayPos], di

	pop	di, es
	popf
	ret
DebugPrintChar	endp

InitDebugDisplay	proc	near
	pushf
	push	ax, cx, di, es

	mov	di, SCREEN_BASE
	mov	es, di
	clr	di
	mov	cx, SCREEN_SIZE/2
	mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
	rep stosw

	pop	ax, cx, di, es
	popf
	ret
InitDebugDisplay	endp

endif

;------------------------------------------------------------------------------
;				Data
;------------------------------------------------------------------------------
;common variables:

loaderVars	KernelLoaderVars	<>

PC <kdataSize	word							?

;------------------------------------------------------------------------------
;				Stack
;------------------------------------------------------------------------------

stack	segment	para stack 'STACK'

	dw	LOADER_STACK_SIZE/2 dup (?)	; XXX
endStack	label	word
stack	ends

;---------------------------

;This is the size of the loader code, data, and stack. Is used by
;MoveLoader to know how much stuff to move to the upper portion of the
;heap.

LOADER_CODE_AND_STACK_SIZE	equ	(offset cgroup:endStack)

;------------------------------------------------------------------------------
;	The data from this point forward is NOT moved with the loader
;------------------------------------------------------------------------------
;Buffer for the splash screen text

ifndef NO_AUTODETECT
  ifndef NO_SPLASH_SCREEN

    SPLASH_SCREEN_BUFFER_SIZE	equ	4096

    SPLASH_SCREEN_BUFFER	equ	(offset cgroup:endStack)

  endif
endif

;--------------------------------
;buffer to read in strings file

ifndef	NO_SPLASH_SCEEN
    STR_BUFFER	equ	(offset cgroup:endStack)
else
    STR_BUFFER	equ	(offset cgroup:endStack)+SPLASH_SCREEN_BUFFER_SIZE
endif

;--------------------------------

;This is the total size of the loader:
;	code
;	data
;	stack
;	splash screen text buffer
;	strings file buffer
;

ifndef	NO_SPLASH_SCEEN
    LOADER_SIZE	equ	LOADER_CODE_AND_STACK_SIZE + \
			MAX_STRING_FILE_SIZE

else
    LOADER_SIZE	equ	LOADER_CODE_AND_STACK_SIZE + \
			SPLASH_SCREEN_BUFFER_SIZE + \
			MAX_STRING_FILE_SIZE
endif

;--------------------------------

