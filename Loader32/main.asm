COMMENT @----------------------------------------------------------------------

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved

PROJECT:	GEOS32
MODULE:		Loader -- GEOS32 kernel loader
FILE:		main.asm

AUTHOR:		Lysle Shields

ROUTINES:
	Name		Description
	----		-----------
	LoadGeos	Entry point

REVISION HISTORY:
	Name	Date	   Description
	----	----	   -----------
	Lysle	08/09/2000 Initial Revision (Modified from PC/GEOS Loader)

DESCRIPTION:
	This program loads the PC/GEOS kernel.


        Command line swithes:

	        /m#	where xxx is the location (in k) where the
		        top of the heap should be placed. 640 is the
		        default. any value above 640 will be ignored.

	        /r#	where xxx is the amount of memory (in k) at
		        the top of memory that should be reserved.
		        the default is 0, of course.

	$Id: main.asm,v 1.1 97/04/04 17:26:55 newdeal Exp $

------------------------------------------------------------------------------@

_Loader		=	1
_Kernel		= 	1	; This makes life easier in many cases, not the
				;  least of which is debugging, b/c we get the
				;  various data structures that would otherwise
				;  be defined in the "geos" library segment.

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

.386
include loader.def
.ioenable

	cgroup	group	kcode, stack

; This is the first word in the list and it points to the GPMI routines.
        word GPMIVectorTable


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub routine to notify the Swat stub that we've done
		something. THIS MUST BE THE SECOND FUNCTION IN KCODE

CALLED BY:	ReportLoaderLocation, LoadGeos
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

                rept	8			; room for pushf and direct far call
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
	Lysle	1/91		Initial version

------------------------------------------------------------------------------@


LoadGeos	proc	far

	; first free unused memory of the loaded
	; so real memory is available for drivers and
	; DPMI usage.
	call	LimitLoaderSize

	cld
	call	GPMIQueryStarted
	jne	gpmiStarted
	call	GPMIStartup
	ERROR_C LS_GPMI_COULD_NOT_START
gpmiStarted:
	mov	bl, GPMI_EXCEPTION_GENERAL_PROTECTION_ERROR
	clr	edx
	mov	cx, cs
	mov	dx, offset GPF_Fault
	call	GPMISetExceptionHandler

	; Make our data area writeable
	mov	bx, cs
	call	GPMIAlias
	mov	ds, bx

	mov	ds:[loaderDSSelector], bx
	mov	ds:[loaderVars].KLV_pspSegment, es
	mov	ax, es:[PSP_envBlk]
	mov	ds:[loaderVars].KLV_envSegment, ax

	mov	ds, cs:[loaderDSSelector]
	mov	es, cs:[loaderDSSelector]

	;set basic defaults for video-configuration variables
	;(If NO_AUTODETECT is defined, these variables will remain this way.)

	mov	ds:[loaderVars].KLV_initialTextMode, SITM_UNKNOWN
	mov	ds:[loaderVars].KLV_defSimpleGraphicsMode, SSGM_NONE
	mov	ds:[loaderVars].KLV_curSimpleGraphicsMode, SSGM_NONE

        ; Determine the amount of DOS memory available
	call	FindMemory	; dx <- high segment address
				; ax, bx, cx destroyed

	; Tell swat where we are in REAL memory (as if we moved ... laugh!)
        call	ReportLoaderLocation	; ax, bx, cx, dx, si, di, bp destroyed

	; locate the GEOS32 "local tree" directory and CD to it
	call	LocateGeosDir

	; attempt to load the strings file from the local tree. Fails
	; gracefully if not there; will try again later.
	;call	ReadStringsFile

	; Attempt to open geos.ini file in the local tree. (If not there,
	; then scan for it in the "system tree".) If there is a path= statement
	; in that file, then load other .ini files.
	call	OpenIniFiles


if 1
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

endif
kernelLoaded::
	mov	al, DEBUG_KERNEL_LOADED
	call	NotifyStub

	; jump to the library entry point.

	mov	di, LCT_ATTACH
	retf

LoadGeos	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindMemory

DESCRIPTION:	Check for command line arguments which limit the amount
		of memory available to the heap:

			/mXXX	Where XXX is the location (in K) where the
				top of the heap should be placed. 640 is the
				default. Any value above 640 will be ignored.

			/rXXX	Where XXX is the amount of memory (in K) at
				the top of memory that should be reserved.
				The default is 0, of course.

		These two options are mutually exclusive. (If both are
		specified, only /m takes effect.)

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
        Lysle   8/2000          Converted for GEOS32

------------------------------------------------------------------------------@

FindMemory	proc	near
	uses	di, es, bp, si
	.enter

	; Search throught the command tail
	mov	es, ds:[loaderVars].KLV_pspSegment
	mov	dx, es:[PSP_endAllocBlk]	; end heap at end of

ifidn	HARDWARE_TYPE, <PC>
        mov     bl, 'm'
        mov     bh, 'M'
        call    FindCommandLineSwitch
        jc      tryReserved
        call    TextToNumber

	; multiply by 1024 to calculate location in K-bytes, and then divide
	; by 16 to make it a segment address
	mov	cl, 6
	shl	bp, cl				; turn into segment address

        ; Take the lower of the two
        cmp     bp, dx
        ja      doneMem
        mov     dx, bp
        jmp     doneMem

tryReserved:
        ;mov     bl, 'r'
        ;mov     bh, 'R'
        ;call    FindCommandLineSwitch
        ;jc      done
        ;call    TextToNumber
        mov	bp, 128
	mov     cl, 6
        shl     bp, cl                          ; reserve that amount of space
        sub     dx, bp
        jc      handleError

doneMem:
	; make sure that we still have the minimum heap space
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

FUNCTION:	ReportLoaderLocation

DESCRIPTION:	Tell SWAT where we are after recording our location

CALLED BY:	BootGeos

PASS:
	cs, ds - this segment
	dx - top of memory

RETURN:
	code running in high memory

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Lysle   8/2000          New version (does nothing)

------------------------------------------------------------------------------@

ReportLoaderLocation	proc	far	; must be FAR so can return to shifted code.
	; Get our heap location
        ; In GEOS32, we can no longer have a range of segments!
        ; but we will go ahead and report the range in real mode

        ; !!! TBD:  Hey!  What is CS's real address? -- lshields 11/6/2000
;;	mov	ds:[loaderVars].KLV_dosHeapStart, cs
;;	mov	ds:[loaderVars].KLV_dosHeapEnd, dx

        ; Allocate one 64K block to be the base of our 'heap'
        ; Really what this is is a block to the kernel's data
        ; and the handle table (which may be extended in the future)
        clr     cx
        clr     bx
        inc     bx
        call    GPMIAllocateBlock
	mov	ds:[loaderVars].KLV_dgroupSegment, bx

        ; Let's just setup the valid range of selectors
        mov     ds:[loaderVars].KLV_heapStart, 1
	mov	ds:[loaderVars].KLV_heapEnd, 0xEFFF

	mov	ds:[loaderVars].KLV_GPMIVectorTable.offset, offset GPMIVectorTable
	mov	ds:[loaderVars].KLV_GPMIVectorTable.segment, cs

	push	es
	mov	ax, cs
	mov	es, ax

	; tell stub where we're living now.
	mov	al, DEBUG_LOADER_MOVED
	call	NotifyStub
	pop	es
	ret
ReportLoaderLocation	endp

;------------------------------------------------------------------------------
;				Data
;------------------------------------------------------------------------------
;common variables:

loaderDSSelector	word	0
loaderVars	KernelLoaderVars	<>

PC <kdataSize	word							?>

;------------------------------------------------------------------------------
;				DPMI buffer
;------------------------------------------------------------------------------

DPMIBuffer	segment	para public 'BSS'
	dw	DPMI_BUFFER_SIZE/2 dup (?)
DPMIBuffer	ends

;------------------------------------------------------------------------------
;				Stack
;------------------------------------------------------------------------------

stack	segment	para stack 'STACK'

	dw	LOADER_STACK_SIZE/2 dup (?)	; XXX
endStack	label	word
stack	ends

;---------------------------

;This is the size of the loader code, data, and stack. Is used by
;InitHeap to record the size of the loader in the heap.

LOADER_CODE_AND_STACK_SIZE	equ	(offset cgroup:endStack)

;------------------------------------------------------------------------------
;	The data from this point forward is NOT moved with the loader
;------------------------------------------------------------------------------

;--------------------------------
;buffer to read in strings file

    STR_BUFFER	equ	(offset cgroup:endStack)

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
















COMMENT @----------------------------------------------------------------------

FUNCTION:	FindCommandLineSwitch

DESCRIPTION:	Search for /X switch item where X is passed in.

CALLED BY:	

PASS:
	bl - lower case letter to search for
        bh - upper case letter to search for

RETURN:
	es:di - Location to switch
        carray - set if not found

DESTROYED:
	ax, bx, cx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Lysle   8/2000          Initial version.

------------------------------------------------------------------------------@
FindCommandLineSwitch  proc far
        .enter
	mov	es, ds:[loaderVars].KLV_pspSegment
	mov	di, offset PSP_cmdTail
	mov	cl, es:[di]
	clr	ch				; length of command tail -> cx

	; Now scan for any arguments

	mov	al, '/'				; switch delimiter -> al
next:
	repne	scasb				; scan for delimiter
	jnz	notFound		        ; if none, found, we're done

	cmp	{byte} es:[di], bl
	je	foundSwitch
	cmp	{byte} es:[di], bh
	jne	next
foundSwitch:
        inc di
        ; es:di is location of switch data
        clc
        jmp     done

notFound:
        stc
done:
        .leave
        ret
FindCommandLineSwitch  endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TextToNumber

DESCRIPTION:	Convert the digits at es:di into a 16-bit number

CALLED BY:	

PASS:
	es:di - text to convert

RETURN:
        di - end of digits (one character past last digit)
        bp - value found (or 0)

DESTROYED:
	ax, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Lysle   8/2000          Initial version.

------------------------------------------------------------------------------@
TextToNumber    proc far
        clr     bp
        clr     ah
convertLoop:
        mov     al, es:[di]
        sub     al, '0'
        cmp     al, 9
        jg      done

        ; Multiply current number by 10 for next digit
        shl     bp, 1           ; x2
        mov     si, bp
        shl     bp, 1           ; x4
        shl     bp, 1           ; x8
        add     bp, si          ; x8 + x2 = x10

        ; Add in the next lowest digit
        add     bp, ax
        inc     di
        jmp     convertLoop
done:
        ret
TextToNumber    endp

GPF_Fault	proc far
	push	eax		; sp+4
	push	bx		; sp+6
	push	cx		; sp+8
	push	bp		; sp+10
	mov	bx, sp
	mov	cx, ss
	push	cx		; sp+12
	push	bx		; sp+14

	; Put us back on the stack where we were when the protection fault occured
	mov	bp, sp
	mov	eax, ss:[bp+20]
	mov	bx, ss:[bp+26]	; sp on DPMI call stack
	mov	cx, ss:[bp+28]	; ss on DPMI call stack
	mov	sp, bx
	mov	ss, cx

	; Use on this other stack
	push	eax
	on_stack retf
	mov	ax, LS_GENERAL_PROTECTION_ERROR
	call	LoaderError

	pop	bx
	pop	cx
	mov	sp, bx
	mov	ss, cx

	pop	bp
	pop	cx
	pop	bx
	pop	eax
	on_stack retf
	iret
GPF_Fault	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LimitLoaderSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the loader so that there is a room for the dos
		extender at the top of memory.  If there is not enough
		room, a loader error is generated.
CALLED BY:	Loader
PASS:		es = PSP of loader.exe
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Look at the PSP and see if we have room
	If so, calculate what our new size is minus 128K
	Do the resize

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	frehwagen	07/20/2009	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LimitLoaderSize	proc	near
	uses	ax, bx, es
	.enter

	; es should point to PSP of loader
	
	mov	bx, LOADER_SIZE
	shr	bx, 4
	mov	ah, MSDOS_RESIZE_MEM_BLK
	int	21h

	.leave
	ret
LimitLoaderSize	endp
