COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainError.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	sp_report_error		Bitstream error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainError.asm,v 1.1 97/04/18 11:45:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_report_error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	error

CALLED BY:	Bitstream C code

PASS:		sp_report_error(fix15 n)

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version
	brianc	11/3/93		ASM version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_report_error	proc	far	errorCode:word

	uses	ds, es, si, di

	.enter

	segmov	ds, dgroup, ax
	tst	ds:[installFlag]
	jz	notInstall
	cmp	errorCode, 12			; no char data?
	je	charDataNotAvail
	cmp	errorCode, 0xfd5
	je	charDataNotAvail
notInstall:
;EC <	ERROR	BITSTREAM_INTERNAL_ERROR			>
	mov	ax, mask SNF_CONTINUE
	mov	bx, handle SysNotifyStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[(offset bitstreamError)]	; ds:si = string one
	ChunkSizePtr	ds, si, ax
	mov	cx, ax
DBCS <	shr	cx, 1			; # bytes -> # chars		>
	add	ax, UHTA_NULL_TERM_BUFFER_SIZE
	segmov	es, ss
	sub	sp, ax
	mov	di, sp
	push	ax
	push	di
	LocalCopyNString		; di = after copied bitstreamError
	pop	si				; es:si = copied bitstreamError
	mov	bx, handle SysNotifyStrings
	call	MemUnlock
	LocalPrevChar	esdi		; back up to null
	segmov	ds, es			; ds = strings
	mov	dx, 0
	mov	ax, errorCode
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii	; ds:di = error code
	mov	ax, mask SNF_ABORT or mask SNF_EXIT
	clr	di
	call	SysNotify
	pop	bx			; bx = stack space allocated
	add	sp, bx
	test	ax, mask SNF_EXIT
	jz	done
	mov	ax, SST_DIRTY
	call	SysShutdown
	.UNREACHED

done:
	.leave
	ret

charDataNotAvail:
;EC <	WARNING	BITSTREAM_CHAR_DATA_NOT_AVAIL			>
	jmp	short done

sp_report_error	endp

	SetDefaultConvention

SysNotifyStrings	segment	lmem	LMEM_TYPE_GENERAL
LocalDefString	bitstreamError	<'Bitstream error: ',0>
SysNotifyStrings	ends
