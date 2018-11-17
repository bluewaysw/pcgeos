COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		libMisc.asm

AUTHOR:		Don Reeves, Jan 31, 1992

ROUTINES:
	Name			Description
	----			-----------
	SpoolCreateSpoolFile	Create and open a spool file
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/31/92		Initial revision

DESCRIPTION:
	Contains miscellaneous spool library routines.

	$Id: libMisc.asm,v 1.1 97/04/07 11:11:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolMisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and open a unique spool file. The file will be
		located in the SP_SPOOL standard directory

CALLED BY:	GLOBAL

PASS:		DX:SI	= Buffer for filename (13 characters long)

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
SBCS<	rep	movsb				; copy them bytes	>
DBCS<	rep	movsw				; copy them bytes	>
	mov	di, bp

	; Start out trying a base file, then incrementing
	;
	mov	ds, dx
	pop	di				; DS:DI points at the filename
	mov	dx, di				; DS:DX points at the file name
tryAnotherFile:
	mov     ah, FILE_CREATE_ONLY            ; don't truncate
	mov     al, FILE_DENY_W or FILE_ACCESS_RW
	mov     cx, FILE_ATTR_NORMAL
	call    FileCreate			; attempt to create the file
	jnc     fileOK                          ; we have one - done
	cmp	ax, ERROR_SHORT_READ_WRITE
	je	fileError			; if short read/write fail now

	; Else go to the next logical file name
	;
SBCS <	mov	bx, 2				; initialize a counter	>
DBCS <	mov	bx, 2*(size wchar)		; initialize a counter	>
nextNameLoop:
	inc     ds:[di][bx].SFN_num		; increment the digit
	cmp     ds:[di][bx].SFN_num, '9'
	jl      tryAnotherFile			; try again in no rollover
	mov     ds:[di][bx].SFN_num, '0'
SBCS <	dec	bx				; go to the next digit	>
DBCS <	sub	bx, 2				; go to the next digit	>
	jge	nextNameLoop			; jump if not negative
fileError:
	clr	ax				; no file handle!!!
fileOK:
	call	FilePopDir			; return to original directory

	.leave
	ret
SpoolCreateSpoolFile	endp

SpoolMisc	ends








