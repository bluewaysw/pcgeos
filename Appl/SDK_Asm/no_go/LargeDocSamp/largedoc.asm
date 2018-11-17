COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		largedoc
FILE:		app.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/91		Initial version

DESCRIPTION:
	This file contains a application that shows the basics for a large
	application.

	$Id: largedoc.asm,v 1.1 97/04/04 16:34:33 newdeal Exp $

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

include		largedoc.rdef

			
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
	
			
largedoc_ProcessClass	class GenProcessClass
			
largedoc_ProcessClass	endc
			
			
			
idata	segment
	largedoc_ProcessClass	mask CLASSF_NEVER_SAVED
		
	curOrigin	PointDWord <0, 0>
	curWidth	word	0
	curHeight	word	0
	viewWin		hptr Window

idata	ends

main	segment resource
	
	



COMMENT @----------------------------------------------------------------------

METHOD:		LargeDocOriginChanged -- 
		MSG_ORIGIN_CHANGED for largedoc_ProcessClass

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

LargeDocOriginChanged	method largedoc_ProcessClass, \
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
LargeDocOriginChanged	endm



COMMENT @----------------------------------------------------------------------

METHOD:		LargeDocSizeChanged -- 
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

LargeDocCreated	method largedoc_ProcessClass,
			MSG_META_CONTENT_VIEW_WIN_OPENED,
			MSG_META_CONTENT_VIEW_SIZE_CHANGED
	mov	ds:curWidth, cx
	mov	ds:curHeight, dx
	mov	ds:viewWin, bp
	ret
LargeDocCreated	endm





COMMENT @----------------------------------------------------------------------

METHOD:		LargeDocStartSelect -- 
		MSG_META_START_SELECT for largedoc_ProcessClass

DESCRIPTION:	Handles a button press.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT
		cx, dx  - mouse coordinates relative to window, hopefully...

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

LargeDocStartSelect	method largedoc_ProcessClass, MSG_META_START_SELECT
	mov	di, ds:viewWin			;window handle in di
	tst	di
	jz	exit
	call	GrCreateState
	
	push	cx, dx
	mov	ax, ds:curOrigin.PD_y.low
	mov	bx, ds:curOrigin.PD_y.high
	mov	cx, ds:curOrigin.PD_x.low
	mov	dx, ds:curOrigin.PD_x.high
	call	GrApplyTranslationDWord
	
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
LargeDocStartSelect	endm
		
		

COMMENT @----------------------------------------------------------------------

METHOD:		LargeDocViewClosing -- 
		MSG_META_CONTENT_VIEW_CLOSING for largedoc_ProcessClass

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

LargeDocViewClosing	method largedoc_ProcessClass, \
				MSG_META_CONTENT_VIEW_CLOSING
	clr	ds:viewWin
	ret
LargeDocViewClosing	endm

			
COMMENT @----------------------------------------------------------------------

FUNCTION:	LargeDocExposedWin -- MSG_META_EXPOSED for largedoc_ProcessClass

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

LargeDocExposedWin	method	largedoc_ProcessClass, \
					MSG_META_EXPOSED
	; Updating the window...

	mov	di,cx
	call	GrCreateState
	call	GrBeginUpdate
	;
	; Do any drawing here.
	;
exit:
	call	GrEndUpdate
	call	GrDestroyState
	ret

LargeDocExposedWin	endm

main	ends

end
