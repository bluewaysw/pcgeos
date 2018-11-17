COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Trivia project)
MODULE:		
FILE:		util.asm

AUTHOR:		Jason Ho, Feb 10, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		2/10/95   	Initial revision


DESCRIPTION:
	Misc utils copied from some other apps
		

	$Id: util.asm,v 1.1 97/04/04 15:14:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a time string and sets the Text Object to display
		this string.

CALLED BY:	SolitaireUpdateTime

PASS:		ES	= DGroup
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		CX	= # of seconds

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeToTextObject	proc	near
	uses	di, es
	.enter

	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, dx			; SS to ES and DX!
	sub	sp, EVEN_DATE_TIME_BUFFER_SIZE	; allocate room on the stack
	mov	bp, sp				; ES:BP => buffer to fill
	mov_tr	ax, cx
	call	WriteTime
	clr	cx				; string is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; send the method
	add	sp, EVEN_DATE_TIME_BUFFER_SIZE	; restore the stack

	.leave
	ret
TimeToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				WriteTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a time to ASCII, and writes it into a buffer

CALLED BY:	CreatetTimeString

PASS:		ES:BP	= Start of string buffer
		AX	= # of seconds

RETURN:		nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTime	proc	far
	uses	ax, bx, cx, dx, si, di
	.enter

	;
	;	ch <- hours
	;	dl <- minutes
	;	dh <- seconds
	mov	cx, 3600
	clr	dx
	div	cx				;ax <- hours, dx <- seconds

	mov	ch, al
	mov	ax, dx
	clr	dx
	mov	bx, 60
	div	bx				;ax <- minutes; dx <- seconds
	mov	dh, dl
	mov	dl, al

	mov	si, DTF_HMS_24HOUR
	tst	ch
	jnz	callLocal
	mov	si, DTF_MS
callLocal:
	mov	di, bp
	call	LocalFormatDateTime

	.leave
	ret
WriteTime	endp



CommonCode	ends
