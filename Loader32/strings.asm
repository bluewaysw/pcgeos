COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader
FILE:		strings.asm

ROUTINES:
	Name			Description
	----			-----------
   	ReadStringsFile		Read in the strings file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:

	$Id: strings.asm,v 1.1 97/04/04 17:26:44 newdeal Exp $

------------------------------------------------------------------------------@

stringsFileName	char	"geos.str",0
stringsFileRead	BooleanByte	BB_FALSE


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadStringsFile

DESCRIPTION:	Read the kernel strings file both into the buffer in this
		segment.

CALLED BY:	INTERNAL

PASS:
	ds, es - loader segment

RETURN:
	stringsFileRead - true if strings file can be read

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version

------------------------------------------------------------------------------@

ReadStringsFile	proc	near

	;USE LOWEST COMMON DENOMINATOR FOR ACCESS FLAGS. DOS 2.X doesn't like
	; sharing modes or inheritance bits...

	mov	ax, (MSDOS_OPEN_FILE shl 8) or FA_READ_ONLY
	mov	dx, offset stringsFileName
	int	21h
if	REQUIRE_STRINGS_FILE
	ERROR_C	LS_CANNOT_OPEN_STRINGS_FILE
else
	jc	done
endif
	mov	bx, ax

	; read strings into buffer
	mov	ah, MSDOS_READ_FILE
	mov	cx, MAX_STRING_FILE_SIZE
	mov	dx, STR_BUFFER
	int	21h				;ax = bytes read
if	REQUIRE_STRINGS_FILE
	ERROR_C	LS_CANNOT_OPEN_STRINGS_FILE
else
	jc	done
endif

	; store 0 at end
	mov	si, dx
	add	si, ax
	mov	{byte} ds:[si], 0

	mov	ah, MSDOS_CLOSE_FILE
	int	21h
if	REQUIRE_STRINGS_FILE
	ERROR_C	LS_CANNOT_OPEN_STRINGS_FILE
else
	jc	done
endif

	; 1) replace the CR,LF pairs with just CR
	; 2) remove comments

	mov	si, STR_BUFFER
	mov	di, si
	mov	cx, NUMBER_OF_STRINGS_IN_STRINGS_FILE

startOfLineLoop:
	lodsb
	cmp	al, '#'				;if a comment then skip it
	jz	skipComment
	stosb
	tst	al				;if NULL then done
	jz	compactDone
	cmp	al, C_CR			;if CR then skip LF
	jz	skipLF

	; middle of line -- copy until CR, LF

middleOfLineLoop:
	lodsb
	stosb
	tst	al
	jz	compactDone
	cmp	al, C_CR
	jnz	middleOfLineLoop
	dec	cx				;if done then exit
	jcxz	compactDoneStoreNull
skipLF:
	lodsb
	jmp	startOfLineLoop

	; comment - skip it

skipComment:
	lodsb
	tst	al
if	REQUIRE_STRINGS_FILE
	ERROR_Z	LS_CANNOT_OPEN_STRINGS_FILE
else
	jz	done
endif
	cmp	al, C_LF
	jnz	skipComment
	jmp	startOfLineLoop

compactDoneStoreNull:
	clr	al
	stosb
compactDone:

	tst	cx
if	REQUIRE_STRINGS_FILE
	ERROR_NZ	LS_CANNOT_OPEN_STRINGS_FILE
else
	jnz	done
endif

	mov	ds:[stringsFileRead], BB_TRUE

ife	REQUIRE_STRINGS_FILE
done:
endif

	.leave
	ret

ReadStringsFile	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderError

DESCRIPTION:	Handle a loader error

CALLED BY:	UTILITY

PASS:
	ax - KernelStrings

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@
crlfString	char	13, 10, '$'

LoaderError	proc	near
	LoaderDS
	LoaderES
	push	ax
	mov	ax, es
	and	ax, ax
	jne	validSeg
	; Must still be in real mode
	mov	ax, kcode
	mov	es, ax
	mov	ds, ax
validSeg:
	pop	ax

        ; /// Restore VIDEO here if you need to

	; output "System error: "
	push	ax
	mov	dx, offset crlfString
	mov	ah, MSDOS_DISPLAY_STRING
	int	21h

	mov	ax, LS_ERROR_PREFIX
	call	PrintString
	pop	ax

	; print the error
	cmp	ax, NUMBER_OF_STRINGS_IN_STRINGS_FILE
	jae	noPrint

	call	PrintString

	mov	dx, offset crlfString
	mov	ah, MSDOS_DISPLAY_STRING
	int	21h

noPrint:
	; run away
	mov	ax, 0x4c00
	int	21h
	.unreached
LoaderError	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrintString

DESCRIPTION:	Print a string from the strings file

CALLED BY:	LoaderError

PASS:
	ds, es - loader segment
	ax - KernelStrings

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@
PrintString	proc	near
	; if no strings file exists then use defaults
	tst	ds:[stringsFileRead]
	jnz	lookInBuffer

	mov	si, offset systemError
	cmp	ax, LS_ERROR_PREFIX
	jz	print

	mov	si, offset cannotLocateKernelString
	cmp	ax, LS_CANNOT_LOCATE_KERNEL
	jz	print

	mov	si, offset invalidMemoryArgument
	cmp	ax, LS_INVALID_MEMORY_ARGUMENT
	jz	print

	mov	si, offset cantStartGPMI
	cmp	ax, LS_GPMI_COULD_NOT_START
	jz	print

if LOAD_DOS_EXTENDER
	mov	si, offset cantLoadDOSExtender
	cmp	ax, LS_CANNOT_LOAD_DOS_EXTENDER
	jz	print
endif

	mov	si, offset cannotOpenStringsFile
	jmp	print

lookInBuffer:
	mov	si, STR_BUFFER

	; skip strings before the one we want
	clr	cx
	mov	cl, al			; cx = # strings to skip
	jcxz	print			;if no more strings to skip then got it

skipLineLoop:
	lodsb
	cmp	al, C_CR
	jnz	skipLineLoop
	loop	skipLineLoop

	; print it
print:
	mov	dx, si
	mov	ah, MSDOS_DISPLAY_STRING
	int	21h
	ret
PrintString	endp

	; This is the one string that cannot be translated

systemError			char	"System Error: $"
NEC <cannotLocateKernelString	char	"cannot load geos.geo (or cannot find geos.ini)$"	>
EC <cannotLocateKernelString	char	"cannot load geosec.geo (or cannot find geosec.ini)$"	>
invalidMemoryArgument		char	"invalid /mNNN or /rNNN argument$"
cannotOpenStringsFile		char	"cannot load strings file (geos.str)$"
cantStartGPMI			char	"GEOS requires DPMI$"

if LOAD_DOS_EXTENDER
cantLoadDOSExtender		char	"Cannot load DOS Extender (dosext.exe)$"
endif
