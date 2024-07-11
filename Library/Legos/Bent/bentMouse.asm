COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		benthack.asm

AUTHOR:		Jimmy Lefkowitz, Mar 13, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 3/13/95   	Initial revision


DESCRIPTION:
	
	$Id: bentMouse.asm,v 1.1 98/03/11 15:08:41 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include stdapp.def
include Objects/visC.def
include Internal/im.def

BentHack	segment resource
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BentNavigateQueryLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_BentNavigateQueryLow	proc	far	queryOrigin:optr,
					navFlags:word,
					oself:optr,
					navQueryParams:fptr
	uses	ds, es, di, si
	.enter

	;; save the retval pointer on the stack for later
	les	di, navQueryParams
	push	es, di

	;;  point ds at the block of the object in question
	mov	bx, oself.segment
	call	MemDerefDS

	;;  and get *ds:di = object, *ds:si as well
	mov	di, oself.offset
	mov	si, di

	
	clr	bl
	movdw	cxdx, queryOrigin
	mov	bp, navFlags
	call	VisNavigateCommon
	pop	es, bx
	;; 	pushf			
	mov	es:[bx], bp
	add	bx, 2
	mov	es:[bx], ax
	add	bx, 2
	mov	es:[bx], dx
	add	bx, 2
	mov	es:[bx], cx
	;; 	popf
	mov	ax, 1
	;; 	jnc	done
	;; 	inc	ax
	;; done:	
	;;  	mov	es:[di].NQP_navFlags, bp
	;; 	mov	es:[di].NQP_backtrackFlag, al
	;; 	movdw	es:[di].NQP_nextObject, cxdx
	.leave
	ret
_BentNavigateQueryLow	endp
	public _BentNavigateQueryLow



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BentMouseInWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the mouse is in the passed in window

CALLED BY:	BentWindow::VIS_OPEN_WIN
PASS:		window
		OD of window
RETURN:		boolean		- 0 if not in window
				  1 if in window
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_BentMouseInWindow	proc	far	win:hptr, self:optr
	uses	bx,cx,dx,si,di,bp
		.enter
		mov	di, win
		call	ImGetMousePos
		clr	ax
	;
	; if negative, not in window
		cmp	cx, 0
		jl	done
		cmp	dx, 0
		jl	done
		pushdw	cxdx		; pos
		movdw	bxsi, self
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjMessage
		mov	ax, cx		; right edge
		mov	bx, dx		; bottom edge
		popdw	cxdx		; pos
	; is position beyond edge
		clr	di		; not valid
		cmp	cx, ax
		jg	didone
		cmp	dx, bx
		jg	didone
	; in bounds
		mov	di, 1
didone:
		mov	ax, di
done:
		.leave
		ret
_BentMouseInWindow	endp
	public	_BentMouseInWindow

BentHack	ends
