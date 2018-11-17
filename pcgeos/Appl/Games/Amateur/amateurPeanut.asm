COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	
MODULE:	
FILE:		amateurPeanut.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
		Routines to implement peanuts

	$Id: amateurPeanut.asm,v 1.1 97/04/04 15:11:56 newdeal Exp $
-----------------------------------------------------------------------------@


COMMENT @---------------------------------------------------------------------
		PeanutStart		
------------------------------------------------------------------------------

SYNOPSIS:	Set up a peanut's instance data to begin moving

CALLED BY:	MSG_MOVE_START (from ContentSendPeanuts)

PASS:		ss:bp - PeanutParams

RETURN:		nothing 

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:	pick random #s for starting and ending x-positions,
			figure out if peanut is moving left or right, etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@


PeanutStart	method	dynamic AmateurPeanutClass, MSG_MOVE_START
	uses	ax, cx, dx, bp
	.enter

	clr	ds:[di].APNI_status

	mov	ax, ss:[bp].MP_color
	mov	ds:[di].APNI_color, ax

	mov	ax, ss:[bp].MP_trailColor
	mov	ds:[di].APNI_trailColor, ax

	mov	cx, ss:[bp].MP_viewWidth
	mov	dx, ss:[bp].MP_viewHeight

	; store ending position

	mov	ds:[di].MOI_end.P_y, dx

	; calc starting position

	mov	dx, cx
	call	GameRandom
	
	mov	ds:[di].APNI_start.P_x, dx
	mov	ds:[di].APNI_start.P_y, PEANUT_START_HEIGHT

	mov	ds:[di].MOI_curPos.PF_x.WWF_int, dx
	mov	ds:[di].MOI_curPos.PF_y.WWF_int, PEANUT_START_HEIGHT


	; calculate increment

	mov	dx, length PeanutTable
	call	GameRandom

	mov	bx, dx
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	movwwf	dxcx, es:PeanutTable[bx].PF_x

	push	bx
	mov	bx, ss:[bp].MP_speed
	clr	ax	
	call	GrMulWWFixed

	call	SetDirection

	movwwf	ds:[di].MOI_incr.PF_x, dxcx

	pop	bx
	movwwf	dxcx, es:PeanutTable[bx].PF_y

	mov	bx, ss:[bp].MP_speed
	call	GrMulWWFixed
	movwwf	ds:[di].MOI_incr.PF_y, dxcx

	.leave	
	ret
PeanutStart	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the direction to either "left" or "right"

CALLED BY:

PASS:		dx.cx - WWFixed value indicating position increment
		ds:di - peanut instance data
		ss:bp - PeanutParams

RETURN:		dx.cx - negated, if changing direction

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDirection	proc near	
	class	AmateurPeanutClass
	uses	ax, bx
	.enter

	mov	ds:[di].APNI_direction, DT_RIGHT

	; If peanut is starting at less than 1/4 of screen width,
	; then have it move right (default)

	mov	ax, ds:[di].APNI_start.P_x
	mov	bx, ss:[bp].MP_viewWidth
	shr	bx, 1
	shr	bx, 1
	cmp	ax, bx
	jl	done

	; If peanut is starting at more than 3/4 of screen width,
	; then have it move left

	sub	bx, ss:[bp].MP_viewWidth
	neg	bx
	cmp	ax, bx
	jg	moveLeft

	; otherwise, pick a random direction

	push	dx
	mov	dx, 100
	call	GameRandom
	cmp	dx, 50
	pop	dx
	jg	done

moveLeft:
	negwwf	dxcx
	mov	ds:[di].APNI_direction, DT_LEFT
done:
	.leave
	ret
SetDirection	endp




COMMENT @---------------------------------------------------------------------
		PeanutMove		
------------------------------------------------------------------------------

SYNOPSIS:	Update the peanut's position

CALLED BY:	

PASS:		bp - gstate handle

RETURN:		cx, dx - current position

DESTROYED:	
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
PeanutMove	proc near
	uses	ax,bp
	class	AmateurPeanutClass

	.enter

	mov	di, ds:[si]		; deref instance data

	; Erase the old dot

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int
	mov	ax, ds:[di].APNI_trailColor
	call	DrawPeanut

	test	ds:[di].APNI_status, mask MS_DEAD
	jnz	endPeanut

	cmp	dx, ds:[di].MOI_end.P_y
	jl	stillGoing

endPeanut:
	stc	
	jmp	done

stillGoing:

	addwwf	ds:[di].MOI_curPos.PF_x, ds:[di].MOI_incr.PF_x, cx
	addwwf	ds:[di].MOI_curPos.PF_y, ds:[di].MOI_incr.PF_y, cx
	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int
	mov	ax, ds:[di].APNI_color
	call	DrawPeanut
	clc
done:
	.leave
	ret

PeanutMove	endp


COMMENT @---------------------------------------------------------------------
		PeanutNotifyCloud		
------------------------------------------------------------------------------

SYNOPSIS:	

CALLED BY:	ContentCheckPeanutsHit

PASS:		cx, dx, bp:   location and size of cloud

RETURN:		cx, dx - location of peanut, 
		carry set if cloud hits peanut

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:
	OPTIMIZE for SPEED in the case where the peanut is NOT HIT

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
PeanutNotifyCloud	proc near
	uses	ax, bx,di
	class	AmateurPeanutClass
	.enter

	mov	di, ds:[si]	; deref instance data

	test	ds:[di].APNI_status, mask MS_DEAD
	jnz	done

	test	ds:[di].APNI_status, mask MS_SMART
	jnz	actSmart

afterSmart:
	mov	ax, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	bx, ds:[di].MOI_curPos.PF_y.WWF_int

	diff	ax, cx
	diff	bx, dx

	cmp	ax, bp		; if difference  less than size, cloud
	jg	miss
	cmp	bx, bp
	jg	miss
	ornf	ds:[di].APNI_status, mask MS_DEAD
	stc
	jmp	done
miss:
	clc
done:
	.leave
	ret
actSmart:
	call	TomatoActSmart
	jmp	afterSmart

PeanutNotifyCloud		endp

if 0


COMMENT @---------------------------------------------------------------------
		PeanutErase
------------------------------------------------------------------------------

SYNOPSIS:	erase the peanut's trajectory  --  draw a big fat line
		from the peanut's starting point to its ending point
		in the background color -- hope it erases everything

CALLED BY:	PeanutMove

PASS:		ds:di - Peanut instance data
		cx, dx - x and y position
		bp - gstate handle

RETURN:		nothing 

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
PeanutErase	proc	near 
	uses	ax,bx, di
	class	AmateurPeanutClass
	.enter
	mov	ax, ds:[di].APNI_start.P_x
	cmp	ds:[di].APNI_direction, DT_LEFT
	je	left
	dec	ax
	dec	ax
left:
	mov	bx, 0

	push	ax

	mov	di, es:[gstate]
	call	GetBackgroundColor
	call	GrSetLineColor
	mov	ax, 5
	call	GrSetLineWidth

	pop	ax
	add	dx, 2			; draw a little below, too!

	call	GrDrawLine

	.leave
	ret

PeanutErase	endp


endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPeanut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a peanut

CALLED BY:

PASS:		ax - color
		cx, dx - position

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	draw:	X
	       XXX
 	        X

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPeanut	proc near
	uses	ax,bx,di
	.enter
	mov	di, es:[gstate]
	call	GrSetAreaColor

	mov	ax, cx
	mov	bx, dx
	call	GrDrawPoint
	inc	bx
	call	GrDrawPoint
	dec	bx
	inc	ax
	call	GrDrawPoint
	dec	ax
	dec	bx
	call	GrDrawPoint
	dec	ax
	inc	bx
	call	GrDrawPoint
		
	.leave
	ret
DrawPeanut	endp

