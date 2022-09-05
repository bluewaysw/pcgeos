COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Win (specific code for OpenLook)
FILE:		winClassSpec.asm

ROUTINES:
	Name			Description
	----			-----------
	OpenWinUpdatePinnedMenu	Updates the items within a newly-pinned menu.
	OpenWinRefresh		Refresh window, causing redraw.
	OpenWinBack		Push window to back of OpenLook window stack.
	OpenWinAdjustTitleForHeaderMarks
				Adjust the size of the "title area" according to
				which marks (Close Mark, Pin, etc) are visible.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Split off from cwinClass.asm

DESCRIPTION:
	This file contains OLWinClass-related code which is specific to
	OpenLook. See cwinClass.asm for class declaration and method table.

	$Id: winClassSpec.asm,v 1.1 97/04/07 10:56:29 newdeal Exp $

-------------------------------------------------------------------------------@

WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinUpdatePinnedMenu

DESCRIPTION:	This procedure updates the GenTriggers within a pinned
		menu - we make sure their borders are visible.

CALLED BY:	OpenWinUpdateVisBuild

PASS:		ds:*si	- instance data

RETURN:		ds:*si	= same
		bp	= same
		carry set if handled pinned menu case

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinUpdatePinnedMenu	proc	far
	;OpenLook: if this is a pinned menu which was just attached,
	;now is a good time to tell our kids to get borders

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_specState, mask OLWSS_NOTIFY_TRIGGERS_IS_PINNED
	jz	done			;skip if not (cy=0)...

	ANDNF	ds:[di].OLWI_specState, not mask OLWSS_NOTIFY_TRIGGERS_IS_PINNED

	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_SHADOW)
	ORNF	ds:[di].OLWI_attrs, mask OWA_MOVABLE or mask OWA_TITLED

	ANDNF	ds:[di].OLWI_winPosSizeFlags, not (mask WPSF_CONSTRAIN_TYPE)
	ORNF	ds:[di].OLWI_winPosSizeFlags, \
		(WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE)

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED

	push	bp
	mov	cx, TRUE		; make them all bordered
	mov	ax, MSG_OL_BUTTON_SET_BORDERED
	clr	dx
	push	dx			; initial child (first
	push	dx			; child of composite)
	mov	bx, offset VI_link
	push	bx			; Push offset to LinkPart
	push	dx			; No call-back routine
	mov	dx, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	push	dx
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren
	pop	bp
	stc				;indicate that we handled menu

done:
	ret
OpenWinUpdatePinnedMenu	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinRefresh 

DESCRIPTION:	"Refresh window" by causing it to redraw.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - MSG_OL_WINDOW_REFRESH

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@


OpenWinRefresh	method	OLWinClass, MSG_OL_WINDOW_REFRESH
	call	VisQueryWindow	; get graphics window
	tst	di
	jz	OWR_90		; skip if no window
	clr	ax		; INVALIDATE everything in window
	clr	bx
	mov	cx, 4000h-1	; to the end of graphics space
	mov	dx, 4000h-1
	call	WinInvalTree	; Does all sub windows, too
OWR_90:
	ret
OpenWinRefresh	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinBack

DESCRIPTION:	Push window to back of stack.  This is an OPEN LOOK function
	available through the popup menu associated with it.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_OL_WINDOW_BACK

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OpenWinBack	method	OLWinClass, MSG_OL_WINDOW_BACK
	call	VisQueryWindow	; get graphics window
	tst	di
	jz	OWB_90		; skip if no window

				; Send this sucker to the back.
	mov	ax, mask WPF_PLACE_BEHIND
	call	WinChangePriority
OWB_90:
	ret
OpenWinBack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinAdjustTitleForHeaderMarks

DESCRIPTION:	This OpenLook specific procedure reduces the size of the default
		window title area according to the marks which are visible.
		This allows optimzed title redraws, and correct centering.

CALLED BY:	OpenWinCalcWinHdrGeometry

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinAdjustTitleForHeaderMarks	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE or mask OWA_PINNABLE
	jz	done			;skip if neither...

	;there is a close mark or pin: add offset from left edge

	add	ds:[di].OLWI_titleBarBounds.R_left, \
			OLS_WIN_HEADER_MARK_X_POSITION + 4	;fudge factor

	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jz	checkPinnable

	add	ds:[di].OLWI_titleBarBounds.R_left, OLS_CLOSE_MARK_WIDTH
	
;NOTE: should add OLS_CLOSE_MARK_SPACING if both close mark and pin!

checkPinnable:
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	done

	add	ds:[di].OLWI_titleBarBounds.R_left, OLS_PUSHPIN_MAX_WIDTH

done:
	ret
OpenWinAdjustTitleForHeaderMarks	endp

WinCommon ends

