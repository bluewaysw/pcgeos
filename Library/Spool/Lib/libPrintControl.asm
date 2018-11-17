COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool Library
FILE:		libPrintControl.asm

AUTHOR:		Jim DeFrisco, 9 March 1990

ROUTINES:
	Name			Description
	----			-----------
	SpoolGetPageSize	get size of page, given PaperSizes enum

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/9/90		Initial revision


DESCRIPTION:
	This file contains miscellaneous library routines exported by the
	print spooler
		

	$Id: libPrintControl.asm,v 1.1 97/04/07 11:10:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Include any additional defs or file
;
include	libStrings.rdef				; the strings themselves

ifdef		manual				; only ForceRef if defined
ForceRef	manual
ForceRef	tractor1
ForceRef	tractor2
ForceRef	tractor3
ForceRef	tray1
ForceRef	tray2
ForceRef	tray3
endif

SpoolerLib	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		cl	- PaperSizes enum

RETURN:		cx	- width (points)
		dx	- height (points)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just grab the values out of the tables in Lib/libTables.asm

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPageSize proc	far
		uses	bx
		.enter

		; just consult the width and height tables

		mov	bx, cx
		clr	bh
		shl	bx, 1		; make enum a word table offset
		mov	cx, cs:[paperWidths][bx]
		mov	dx, cs:[paperHeights][bx]

		.leave
		ret
SpoolGetPageSize endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolConvertToPaperSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the reverse of SpoolGetPagesize - pass in the 
		dimmensions and return a PaperSizes enum. If a standard
		size is not recognized, PS_CUSTOM is returned.

CALLED BY:	GLOBAL
	
PASS:		CX	= Width (in points)
		DX	= Height (in points)

RETURN:		CL	= PaperSizes enum

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		PaperSizes are in ascending width order, and acsending
		height within equal widths.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolConvertToPaperSizes	proc	far
	uses	bx
	.enter

	; Some set-up work
	;
	clr	bx				; inital table offset
sizeLoop:
	cmp	cx, cs:[paperWidths][bx]
	jg	next
	jl	fail
	cmp	dx, cs:[paperHeights][bx]
	je	done
next:
	add	bx, 2
	cmp	bx, (PaperSizes * 2)
	jl	sizeLoop
fail:
	clr	bx
done:
	shr	bx, 1				; change to byte offset..
	mov	cl, bl				; PaperSizes => CL
	
	.leave
	ret
SpoolConvertToPaperSizes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPaperSizeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return block holding requested string

CALLED BY:	GLOBAL

PASS:		CL	= PaperSizes enum
		
RETURN:		CX	= Length of the string
		DX	= Handle of block containing the string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetPaperSizeString	proc	far
	.enter

	; Find the correct string, and calculate its size
	;
EC <	cmp	cl, PaperSizes			; check enum		>
EC <	ERROR_GE	GET_PAPER_SIZE_STRING_ENUM_TOO_BIG		>

	clr	ch
	shl	cx, 1				; make this count by two
	add	cx, offset PaperSizeStrings:String_PS_CUSTOM
						; chunk handle => CX
	call	IntGetPaperSizeString		; returns cx, dx

	.leave
	ret
SpoolGetPaperSizeString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntGetPaperSizeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return block holding requested string

CALLED BY:	INTERNAL

PASS:		CX	= chunk handle

RETURN:		CX	= Length of the string
		DX	= Handle of block containing the string

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/10/90		Initial version
	tony	12/5/90

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IntGetPaperSizeString	proc	far	uses	ax, bx, di, si, ds, es
	.enter

	mov	bx, handle PaperSizeStrings	; block handle => BX
	call	MemLock		; lock the block
	mov	ds, ax				; segment => DS

	mov	si, cx
	mov	si, ds:[si]			; dereference the handle
	ChunkSizePtr	ds, si, dx		; length of string => DX

	; Now allocate a block to hold copy
	;
	mov	ax, dx				; byte to allocate => AX
	inc	ax				; NULL termination
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc			; block handle => BX
	mov	es, ax				; segment => ES
	clr	di				; ES:DI => string
	mov	cx, dx				; bytes to copy
	rep	movsb				; copy the bytes
	mov	{byte} es:[di], 0		; add the null termination

	; Now clean up
	;
	call	MemUnlock			; unlock the copy block
	mov	cx, dx				; string length => CX
	mov	dx, bx				; block handle => DX
	mov	bx, handle PaperSizeStrings	; block handle => BX
	call	MemUnlock			; unlock the string resource

	.leave
	ret
IntGetPaperSizeString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and open a unique spool file. The file will be
		located in the SP_SPOOL standard directory

CALLED BY:	GLOBAL

PASS:		DX:SI	= Buffer for filename (13 bytes long)

RETURN:		DX:SI	= Buffer filled with filename
		AX	= New file handle (or 0 for failure)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Code courtesy of Jim

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/27/90		Initial version
	Don	5/03/91		Moved into spool library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

spoolBaseName	SpoolFileName <>		; as the structure is defined

SpoolCreateSpoolFile	proc	far
	uses	bx, cx, dx, di, si, ds, es
	.enter

	; Change to the spool directory
	;
	call	FilePushDir			; save the current directory
	mov	ax, SP_SPOOL			; change to the spool directory
	call	FileSetStandardPath		; as one of the standard paths

	; Copy in the filename first
	;
	push	si				; save start of buffer
	mov	es, dx
	mov	di, si				; buffer => ES:DI
	mov	si, offset cs:spoolBaseName
	segmov	ds, cs				; DS:SI points to the string
	mov	cx, 13				; copy the thirteen characters
	rep	movsb				; copy them bytes
	mov	di, bp

	; Start out trying a base file, then incrementing
	;
	mov	ds, dx
	pop	di				; DS:DI points at the filename
	mov	dx, di				; DS:DX points at the file name
tryAnotherFile:
	mov     ah, FILE_CREATE_ONLY            ; don't truncate
	mov     al, FILE_DENY_W or FILE_ACCESS_W
	mov     cx, FILE_ATTR_NORMAL
	call    FileCreate			; attempt to create the file
	jnc     fileOK                          ; we have one - done

	; Else go to the next logical file name
	;
	mov	bx, 2				; initialize a counter
nextNameLoop:
	inc     ds:[di][bx].SFN_num		; increment the digit
	cmp     ds:[di][bx].SFN_num, '9'
	jl      tryAnotherFile			; try again in no rollover
	mov     ds:[di][bx].SFN_num, '0'
	dec	bx				; go to the next digit
	jge	nextNameLoop			; jump if not negative
	clr	ax				; no file handle!!!
fileOK:
	call	FilePopDir			; return to original directory

	.leave
	ret
SpoolCreateSpoolFile	endp

SpoolerLib	ends
