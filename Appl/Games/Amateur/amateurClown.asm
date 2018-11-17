COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	Amateur Night
MODULE:		Clowns
FILE:		amateurClown.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:	routines to draw and erase clowns

	$Id: amateurClown.asm,v 1.1 97/04/04 15:12:29 newdeal Exp $
-----------------------------------------------------------------------------@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClownSetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ClownSetMonikerClass object
		ds:di	= ClownSetMonikerClass instance data
		es	= Segment of ClownSetMonikerClass.

		cx = moniker number (1-6)

RETURN:		nothing 

DESTROYED:	dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	Assumes clown is ALIVE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClownSetMoniker	method	dynamic	ClownClass, 
					MSG_CLOWN_SET_MONIKER
	uses	ax,cx
	.enter

	; If moniker is already set, then return carry
	tst	ds:[di].BI_moniker
	jnz	alreadySet

	dec	cx
	shl	cx
	mov	bx, cx
	mov	ax, cs:normalMonikers[bx]
	mov	ds:[di].BI_moniker, ax
	mov	ds:[di].CI_aliveMoniker, ax

	mov	ax, cs:deadMonikers[bx]
	mov	ds:[di].CI_deadMoniker, ax
	clc
done:
	.leave
	ret

alreadySet:
	stc
	jmp	done
ClownSetMoniker	endm


normalMonikers	word	\
	offset	Clown0Moniker,
	offset	Clown1Moniker,
	offset	Clown2Moniker,
	offset	Clown3Moniker,
	offset	Clown4Moniker,
	offset	Clown5Moniker

deadMonikers word	\
	offset	Dead0Moniker,
	offset	Dead1Moniker,
	offset	Dead2Moniker,
	offset	Dead3Moniker,
	offset	Dead4Moniker,
	offset	Dead5Moniker





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClownSetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the status of the current clown

PASS:		*ds:si	= ClownClass object
		ds:di	= ClownClass instance data
		es	= Segment of ClownClass.

		cl - ClownStatus

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClownSetStatus	method			ClownClass, 
					MSG_CLOWN_SET_STATUS
	mov	ds:[di].CI_status, cl
	cmp	cl, CS_ALIVE
	je	alive

	; clown is dead

	mov	ax, ds:[di].CI_deadMoniker

store:
	mov	ds:[di].BI_moniker, ax
	clc
	ret
alive:
	mov	ax, ds:[di].CI_aliveMoniker
	jmp	store

ClownSetStatus	endm

ClownGetStatus	method	dynamic ClownClass, MSG_CLOWN_GET_STATUS
	mov	cl, ds:[di].CI_status
	clc
	ret
ClownGetStatus	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClownCheckHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ClownClass object
		ds:di	= ClownClass instance data
		es	= Segment of ClownClass.

		cx, dx 	= position of peanut

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClownCheckHit	method	dynamic	ClownClass, 
					MSG_BITMAP_CHECK_PEANUT
	uses	cx,dx,bp
	.enter
	cmp	ds:[di].CI_status, CS_ALIVE
	jne	noHit

	cmp	cx, ds:[di].VI_bounds.R_left
	jl	noHit
	cmp	cx, ds:[di].VI_bounds.R_right
	jg	noHit
	
	; Clown was hit -- black out spotlight
	mov	cl, CS_DEAD
	call	ClownSetStatus

	call	GetBackgroundColor

	mov	si, di			; instance ptr
	mov	di, es:[gstate]
	call	GrSetAreaColor

	mov	ax, ds:[si].VI_bounds.R_left
	mov	bx, ds:[si].VI_bounds.R_top
	mov	cx, ds:[si].VI_bounds.R_right
	mov	dx, ds:[si].VI_bounds.R_bottom
	call	GrFillRect
	stc
done:
	.leave
	ret
noHit:
	clc
	jmp	done
ClownCheckHit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClownTallyScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	add up a score for each clown

PASS:		*ds:si	= ClownClass object
		ds:di	= ClownClass instance data
		es	= Segment of ClownClass.
		ss:bp 	= ClownScoreParams

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClownTallyScore	method	dynamic	ClownClass, 
					MSG_CLOWN_TALLY_SCORE
	.enter
	cmp	ds:[di].CI_status, CS_ALIVE
	jne	done

	mov	ax, ss:[bp].CSP_score
	add	ss:[bp].CSP_scoreTally, ax
	clr	dx

	push	di
	mov	di, offset tempTextBuffer
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii

	add	ax, ss:[bp].CSP_scoreAdder
	mov	ss:[bp].CSP_score, ax

	mov	si, di		; pointer to text
	mov	di, es:[gstate]
	mov	ax, ss:[bp].CSP_color
	call	GrSetTextColor
	pop	di

	mov	ax, ds:[di].VI_bounds.R_left
	mov	cx, ds:[di].VI_bounds.R_right
	add	ax, cx
	shr	ax, 1
	sub	ax, HACK_SCORE_CLOWN_WIDTH
	mov	bx, ds:[di].VI_bounds.R_top
	sub	bx, ss:[bp].CSP_textHeight
	mov	di, es:[gstate]
	segxchg	ds, es
	clr	cx
	call	GrDrawText
	segxchg	ds, es

	mov	al, ST_TALLY_CLOWN
	call	PlaySound

	mov	ax, INTERVAL_TALLY_CLOWN
	call	TimerSleep

done:
	clc
	.leave
	ret
ClownTallyScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClownResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ClownClass object
		ds:di	= ClownClass instance data
		es	= Segment of ClownClass.

RETURN:		width added to BP

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClownResize	method	dynamic	ClownClass, 
					MSG_VIS_RECALC_SIZE
	.enter

	call	CalcClownSize
	call	BitmapResizeCommon
	.leave
	ret
ClownResize	endm

