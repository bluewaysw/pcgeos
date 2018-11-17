COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ViewSamp1
FILE:		view.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/91		Initial version

DESCRIPTION:
	This file contains a application that shows an example of a fixed
	sized content in a GenView.

	$Id: view1.asm,v 1.1 97/04/04 16:34:57 newdeal Exp $

------------------------------------------------------------------------------@
;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;
; Standard include files
;
include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include lmem.def
include localize.def
include initfile.def
include vm.def
include dbase.def
include timer.def
include timedate.def
include system.def
include font.def
include Objects/winC.def	

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
	
;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		view1.rdef

			
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
	
			
view1_ProcessClass	class GenProcessClass

MSG_WENDY_PAGE_DOWN		message
;
; Pages down MyView, wrapping to the top again if at the bottom.
;
; Pass:	nothing
; Return: nothing
;
			
view1_ProcessClass	endc
			
			
			
idata	segment
	view1_ProcessClass	mask CLASSF_NEVER_SAVED
		
	curOrigin	PointDWord <0, 0>
	curWidth	word	0
	curHeight	word	0
	viewWin		hptr Window

idata	ends

main	segment resource
	
	



COMMENT @----------------------------------------------------------------------

METHOD:		ViewOriginChanged -- 
		MSG_ORIGIN_CHANGED for view1_ProcessClass

DESCRIPTION:	Records change in origin.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_ORIGIN_CHANGED
		ss:bp	- {OriginChangedParams} new origin

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@

ViewOriginChanged	method view1_ProcessClass, \
				MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
	mov	cx, ss:[bp].OCP_origin.PD_x.low
	mov	ds:curOrigin.PD_x.low, cx
	mov	cx, ss:[bp].OCP_origin.PD_x.high
	mov	ds:curOrigin.PD_x.high, cx
	mov	cx, ss:[bp].OCP_origin.PD_y.low
	mov	ds:curOrigin.PD_y.low, cx
	mov	cx, ss:[bp].OCP_origin.PD_y.high
	mov	ds:curOrigin.PD_y.high, cx
	ret
ViewOriginChanged	endm



COMMENT @----------------------------------------------------------------------

METHOD:		ViewSizeChanged -- 
		MSG_META_CONTENT_VIEW_WIN_OPENED for ViewClass
		MSG_META_CONTENT_VIEW_SIZE_CHANGED for ViewClass

DESCRIPTION:	Size changed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- method
		cx, dx	- new window size
		bp	- window

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@

ViewCreated	method view1_ProcessClass,
			MSG_META_CONTENT_VIEW_WIN_OPENED,
			MSG_META_CONTENT_VIEW_SIZE_CHANGED
	mov	ds:curWidth, cx
	mov	ds:curHeight, dx
	mov	ds:viewWin, bp
	ret
ViewCreated	endm





COMMENT @----------------------------------------------------------------------

METHOD:		ViewStartSelect -- 
		MSG_META_START_SELECT for view1_ProcessClass

DESCRIPTION:	Handles a button press.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT
		cx, dx  - mouse coordinates, in doc coords

RETURN:		nothing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/26/91		Initial version

------------------------------------------------------------------------------@

ViewStartSelect	method view1_ProcessClass, MSG_META_START_SELECT
	mov	di, ds:viewWin			;window handle in di
	tst	di
	jz	exit
	call	GrCreateState
	
	push	cx, dx
	mov	al, MM_XOR
	call	GrSetMixMode
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	cx, dx			;offset to mouse press
	
	mov	ax, cx
	mov	bx, dx
	sub	ax, 20
	sub	bx, 20
	add	cx, 20
	add	dx, 20
	call	GrFillEllipse
	call	GrFillEllipse
	call	GrDestroyState
exit:
	ret
ViewStartSelect	endm
		
		

COMMENT @----------------------------------------------------------------------

METHOD:		ViewViewClosing -- 
		MSG_META_CONTENT_VIEW_CLOSING for view1_ProcessClass

DESCRIPTION:	Clears the viewWin variable.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_CLOSING

RETURN:		

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/26/91		Initial version

------------------------------------------------------------------------------@

ViewViewClosing	method view1_ProcessClass, \
				MSG_META_CONTENT_VIEW_CLOSING
	clr	ds:viewWin
	ret
ViewViewClosing	endm

ViewWendyPageDown	method view1_ProcessClass, \
				MSG_WENDY_PAGE_DOWN
				
	
	sub	sp, size RectDWord
	mov	dx, sp
	mov	cx, ss
	mov	si, offset MyView
        GetResourceHandleNS	MyView, bx	
	push	di
	mov	di, mask MF_CALL 
	mov	ax, MSG_GEN_VIEW_GET_VISIBLE_RECT
	call	ObjMessage
	pop	di
	mov	bp, dx
	mov	ax, ss:[bp].RD_bottom.low
	add	sp, size RectDWord
	
	push	ax
	sub	sp, size RectDWord
	mov	dx, sp
	mov	cx, ss
	mov	si, offset MyView
        GetResourceHandleNS	MyView, bx	
	push	di
	mov	di, mask MF_CALL 
	mov	ax, MSG_GEN_VIEW_GET_DOC_BOUNDS
	call	ObjMessage
	pop	di
	mov	bp, dx
	mov	dx, ss:[bp].RD_bottom.low
	add	sp, size RectDWord
	
	pop	ax
	cmp	ax, dx
	je	goToTop
	
	;
	; Page down.
	;
	mov	si, offset MyView
        GetResourceHandleNS	MyView, bx	
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	mov	di, mask MF_CALL 
	call	ObjMessage
	jmp	exit
	
goToTop:
	mov	si, offset MyView
        GetResourceHandleNS	MyView, bx	
	mov	ax, MSG_GEN_VIEW_SCROLL_TOP
	mov	di, mask MF_CALL 
	call	ObjMessage
	
exit:
	ret
ViewWendyPageDown	endm

			
			
			
COMMENT @----------------------------------------------------------------------

FUNCTION:	ViewExposedWin -- MSG_META_EXPOSED for view1_ProcessClass

DESCRIPTION:	-

PASS:
	ds - core block of geode
	es - core block

	di - MSG_META_EXPOSED

	cx - window
	dx - ?
	bp - ?
	si - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


ViewExposedWin	method	view1_ProcessClass, \
					MSG_META_EXPOSED
	; Updating the window...

	mov	di,cx
	call	GrCreateState
	call	GrBeginUpdate
	;
	; Do any drawing here.
	;
	call	DrawSomeRects
exit:
	call	GrEndUpdate
	call	GrDestroyState
	ret

ViewExposedWin	endm

		


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawSomeRects

SYNOPSIS:	Draws some rectangles around the edge of the view.

CALLED BY:	ViewExposedWin

PASS:		ds -- dgroup
		di -- gstate

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/29/91		Initial version

------------------------------------------------------------------------------@

DrawSomeRects	proc	near
	sub	sp, size RectDWord
	mov	dx, sp
	mov	cx, ss
	mov	si, offset MyView
        GetResourceHandleNS	MyView, bx	
	push	di
	mov	di, mask MF_CALL 
	mov	ax, MSG_GEN_VIEW_GET_DOC_BOUNDS
	call	ObjMessage
	pop	di
	mov	bp, dx
	mov	ax, ss:[bp].RD_left.low
	mov	bx, ss:[bp].RD_top.low
	mov	cx, ss:[bp].RD_right.low
	mov	dx, ss:[bp].RD_bottom.low
	push	ax
	mov	ax, C_RED
	call	GrSetAreaColor
	pop	ax
	call	GrFillRect
	push	ax
	mov	ax, C_CYAN
	call	GrSetAreaColor
	pop	ax
	add	ax, 20
	add	bx, 20
	sub	cx, 20
	sub	dx, 20
	call	GrFillRect
	push	ax
	mov	ax, C_YELLOW
	call	GrSetAreaColor
	pop	ax
	add	ax, 20
	add	bx, 20
	sub	cx, 20
	sub	dx, 20
	call	GrFillRect
	add	sp, size RectDWord
	ret
DrawSomeRects	endp


		

main	ends

end
