COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurTomato.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurTomato.asm,v 1.1 97/04/04 15:12:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TomatoStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize data for smart peanut

PASS:		*ds:si	= TomatoClass object
		ds:di	= TomatoClass instance data
		es	= Segment of TomatoClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TomatoStart	method	dynamic	TomatoClass, 
					MSG_MOVE_START
	uses	ax,cx,dx,bp
	.enter
	push	di
	mov	di, offset TomatoClass
	call	ObjCallSuperNoLock
	pop	di

	ornf	ds:[di].APNI_status, mask MS_SMART
	clrdw	ds:[di].TI_move

	.leave
	ret
TomatoStart	endm




COMMENT @---------------------------------------------------------------------
		TomatoMove		
------------------------------------------------------------------------------

SYNOPSIS:	Update the peanut's position

CALLED BY:	

PASS:		

RETURN:		cx, dx - current position

DESTROYED:	ax,bp,di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
TomatoMove	proc near
	class	TomatoClass
	.enter

	mov	di, ds:[si]		; deref instance data

	; Get posn

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int

	; erase old position

	call	GetBackgroundColor
	call	DrawTomato

	; See if done

	test	ds:[di].APNI_status, mask MS_DEAD
	jnz	endMove

	cmp	dx, ds:[di].MOI_end.P_y
	jge	endMove

	addwwf	ds:[di].MOI_curPos.PF_x, ds:[di].MOI_incr.PF_x, cx

	; Don't add y-increment if "smart"

	tst	ds:[di].TI_move.P_y
	jnz	afterYIncr
	
	addwwf	ds:[di].MOI_curPos.PF_y, ds:[di].MOI_incr.PF_y, cx

afterYIncr:

	; Now, add smart movement amounts

	mov	ax, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	bx, ds:[di].MOI_curPos.PF_y.WWF_int
	add	ax, ds:[di].TI_move.P_x
	js	dontStore

	add	bx, ds:[di].TI_move.P_y
	js	dontStore

	mov	ds:[di].MOI_curPos.PF_x.WWF_int, ax
	mov	ds:[di].MOI_curPos.PF_y.WWF_int, bx

dontStore:
	clr	ds:[di].TI_move.P_x
	clr	ds:[di].TI_move.P_y

	mov	cx, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	dx, ds:[di].MOI_curPos.PF_y.WWF_int
	mov	ax, ds:[di].APNI_color
	call	DrawTomato
	clc
done:
	.leave
	ret

endMove:
	stc
	jmp	done

TomatoMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTomato
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a smart peanut

CALLED BY:

PASS:		ax - color
		cx, dx, - position

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTomato	proc near	
	uses	cx,dx,di
	.enter
	mov	di, es:[gstate]
	call	GrSetAreaColor
	mov	ax, cx
	mov	bx, dx
	push	cx, dx
	sub	ax, TOMATO_WIDTH/2
	sub	bx, TOMATO_HEIGHT/2
	add	cx, TOMATO_WIDTH/2
	add	dx, TOMATO_HEIGHT/2
	call	GrFillRect

	pop	cx, dx
	mov	ax, cx
	mov	bx, dx
	sub	ax, TOMATO_VERT_RECT_WIDTH/2
	add	cx, TOMATO_VERT_RECT_WIDTH/2
	sub	bx, TOMATO_VERT_RECT_HEIGHT/2
	add	dx, TOMATO_VERT_RECT_HEIGHT/2
	call	GrFillRect

	.leave
	ret
DrawTomato	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TomatoActSmart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change the peanut's "move" values based on how close
		the current cloud is

CALLED BY:	PeanutNotifyCloud

PASS:		cx, dx - cloud position
		bp - cloud size

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TomatoActSmart	proc near	
	uses	cx,dx,bp

	class	TomatoClass

	.enter
	mov	ax, ds:[di].MOI_curPos.PF_x.WWF_int
	mov	bx, ds:[di].MOI_curPos.PF_y.WWF_int

	; calculate deltas	
	sub	ax, cx
	sub	bx, dx
	
	; take absolute values
	mov	cx, ax
	mov	dx, bx
	abs	cx
	abs	dx

	; multiply cloud size by some factor (4 for now)
	shl	bp, 1
	shl	bp, 1

	; subtract absolute values of deltas
	sub	bp, cx
	sub	bp, dx
	js	done			; too far away, no effect

	; Only update smart bomb if it's ABOVE the cloud (delta is
	; negative)
 
	tst	bx
	jns	done
	mov	ds:[di].TI_move.P_y, -TOMATO_MOVE_Y
done:
	.leave
	ret
TomatoActSmart	endp

