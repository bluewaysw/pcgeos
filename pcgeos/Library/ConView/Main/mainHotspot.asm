COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	ConView Library
MODULE:		Main
FILE:		mainHotspot.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

ROUTINES:
	Name			Description
    GLB CTStartSelect		MSG_META_START_SELECT
    GLB CTEndSelect		MSG_META_LARGE_END_SELECT
    GLB CTPtr			MSG_META_PTR
    GLB CTLargePtr		MSG_META_LARGE_PTR

    INT CTGetLinkAtMousePos	Find if there is a hyperlink or hotspot
				under the mouse.

    INT CTFeedbackForSelectingLink 
				Provides user with feedback when a
				hyperlink is selected.

    INT CTGetTextPosFromCoord	Get the nearest character to the passed
				coordinate

    INT CTGetLinkForPos		Get the link for the given position

    INT CTSelectRunAtPosition	Selects the run at the current position.

    GLB CTGetLinkBounds		Gets the bounds (text position of start and
				end) of the	 hyperlink type run that
				includes the current position

    INT HotspotHitDetect	Check if the coordinates are within a 
				hotspot. If it is, return the text
				offset of the hotspot's C_GRAPHIC.

    INT GetHotspotAtMouseClick	Get text offset of a hotspot at which mouse
				clicks

    INT MouseClickWithinHotspot Is the mouse click within the hotspot?
 
    INT MouseClickWithinSpline	Is the mouse click over a spline?

    INT GetHotspotInstanceData	extract the hotspot's instance data from
				the graphic vmChain

    INT GetHotspotUpperleftCorner 
				the name says it all

    INT GetGraphicAtMouseClick	Get text offset of a graphic at the mouse
				click

    INT WithinGraphicBound	Determine if the mouse click is over a
				graphic char

    INT GetGraphicIfThereIsOne 
				If there is a graphic run at the passed
				text offset, return the graphic element

    INT GetTokenCallback	Callback routine that returns the graphic
				run token if the enumerated graphic run
				array element contains the passed text
				offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Hotspot hit detection code for ContentTextClass.
		

	$Id: mainHotspot.asm,v 1.1 97/04/04 17:49:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/fsd.def			; for FSDLockInfoExcl
include system.def				; for SysLockBIOS

idata	segment
NOFXIP	<    convertHandle	hptr	0>
NOFXIP	<    convertOffset	nptr	0>
	    followingLink	byte	BB_FALSE
	    textProtocol	ProtocolNumber <0, 0>
idata	ends


BookFileCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a ContentText object.

CALLED BY:	via MSG_VIS_DRAW
PASS:		*ds:si	= Instance ptr
		bp	= GState
		cl	= DF_EXPOSED if we are doing an update
			  DF_PRINT if printing
			  DF_OBJECT_SPECIFIC if every line should be redrawn
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 nov 1994	added for Clive's sake.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTDraw		method dynamic	ContentTextClass, MSG_VIS_DRAW

	; If we're in the middle of deleting a book, don't
	; try to draw, because the text library has been known
	; to enter an infinite loop in such cases (eg. when the
	; Napa Wine Guide is open, then deleted).

		mov	ax, TEMP_CONTENT_TEXT_NO_DRAW
		call	ObjVarFindData
		jc	done

		push	bp, cx			;save the gstate, flags

	; If there is no text, don't try draw it. Sometimes the
	; text object thinks it has text because it still has lines or
	; fields or something, and will try to draw itself.
		
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		cmpdw	dxax, 0			;if no text, don't draw
		je	noText
		
		mov	ax, MSG_VIS_DRAW
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock

		pop	bp, cx			;^hbp <- passed gstate
						;cl <- draw flags

		test	cl, mask DF_PRINT
		jnz	done

		mov	ax, TEMP_CONTENT_TEXT_INVERT_HOTSPOTS
		call	ObjVarFindData
		jnc	done

		mov	ax, MSG_CT_INVERT_HOTSPOTS
		call	ObjCallInstanceNoLock

done:
		ret
noText:
		pop	bp, cx
		jmp	done
		
CTDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTInvertHotspots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the region of all hotspots to the passed gstate

CALLED BY:	via MSG_VIS_DRAW

PASS:		*ds:si	= Instance ptr
		bp	= GState

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 nov 1994	added for Clive's sake.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTInvertHotspots	method dynamic	ContentTextClass,
			MSG_CT_INVERT_HOTSPOTS

	uses	cx, dx, bp
	.enter

	;
	;  Loop through all the hotspots and invert 'em
	;

	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	call	ObjVarFindData
	jnc	ciao

	;
	;  Save the state of the thing so our MM_INVERT doesn't screw anyone
	;  else up.
	;
	mov	di, bp
	call	GrSaveState

	mov	al, MM_INVERT
	call	GrSetMixMode

	sub	sp, size VisTextConvertOffsetParams
	mov	dx, sp

	mov	cx, si			;*ds:cx <- text object
	mov	si, ds:[bx]		;*ds:si <- graphic run array
	mov	bx, cs
	mov	di, offset InvertHotspotsCallback
	call	ChunkArrayEnum

	add	sp, size VisTextConvertOffsetParams

	mov	di, bp
	call	GrRestoreState

ciao:
	.leave
	ret
CTInvertHotspots	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertHotspotsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to invert hotspots

CALLED BY:	CTDraw

PASS:		ds:di - graphic run array element 
		*ds:cx - text object
		bp - gstate to draw to.
		ss:dx - VisTextConvertOffsetParams

RETURN:		carry clear to keep enumerating
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertHotspotsCallback	proc	far
	uses	cx, bp, dx
	.enter

	;
	;  I have no idea what token = -1 means...
	;
	cmp	ds:[di].TRAE_token, -1
	LONG	je	done

	mov	si, cx				;*ds:si <- text object
	mov	cx, dx				;es:cx <- VTCOP
	mov	bx, bp				;bx <- gstate
	mov	bp, di				;ds:bp <- element,
	sub	sp, size VisTextGraphic
	mov	di, sp

	mov	al, ds:[bp].TRAE_position.WAAH_high
	cbw
	mov_tr	dx, ax
	mov	ax, ds:[bp].TRAE_position.WAAH_low

	mov	bp, cx				;ss:bp <- VTCOP

	call	GetGraphicElement

	;
	;  If the VTG's type isn't VTGT_VARIABLE, then it's VTGT_GRAPHIC,
	;  which means we want to record the graphic's x,y offset for future
	;  hotspots...
	;

	cmp	ss:[di].VTG_type, VTGT_VARIABLE
	jne	recordOffset

	cmp	ss:[di].VTG_data.VTGD_variable.VTGV_type, VTVT_HOTSPOT
	jne	freeVTGdone

	;
	; Get hotspot's offset from the upperleft corner of the graphic
	;

	mov	cx, bx				;^hcx <- gstate
	movdw	dxax, ss:[di].VTG_vmChain
	call	GetHotspotInstanceData		; es:si <- hs instance data
						; bx <- handle to free
	jc	freeVTGdone

	push	bx			 	; save block to free
	mov	bx, di				; ss:bx <- VTG
	mov	di, cx				; ^hdi <- gstate

	;
	;  Check to see whether we need to feedback a spline or a rectangle
	;

	cmp	es:[si].GHSDS_type, HST_SPLINE
	je	feedbackSpline

	;
	;  Why, it's just a rectangle!
	;
	
	mov	ax, {word}ss:[bx].VTG_data.VTGD_variable.VTGV_privateData
	mov	bx, {word}ss:[bx+2].VTG_data.VTGD_variable.VTGV_privateData

	add	ax, ss:[bp].VTCOP_xPos.low
	add	bx, ss:[bp].VTCOP_yPos.low
	mov	cx, ax
	add	cx, es:[si].GHSDS_parentWidth.WWF_int
	mov	dx, bx
	add	dx, es:[si].GHSDS_parentHeight.WWF_int

	call	GrFillRect

	;
	;  Free the GState, the instance data, and stack.
	;
freeBlock:
	pop	bx
	call	MemFree	

freeVTGdone:
	add	sp, size VisTextGraphic
	jmp	done

recordOffset:
	;
	;  ss:cx contains the passes VisTextConvertOffsetParams, and dxax
	;  contains the text offset of the graphic char... let's turn the
	;  thing into a coordinate so that subsequent hotspots will know
	;  where to draw.
	;
	movdw	ss:[bp].VTCOP_offset, dxax
	call	CallVisTextConvertOffsetToCoordinate
	jmp	freeVTGdone	

feedbackSpline:

	add	si, size GenHotSpotDataStruct		;es:si <- points

	;
	; Now draw a path to see whether a point is inside the path
	;
	mov	ax, {word}ss:[bx].VTG_data.VTGD_variable.VTGV_privateData
	mov	dx, {word}ss:[bx+2].VTG_data.VTGD_variable.VTGV_privateData

	add	ax, ss:[bp].VTCOP_xPos.low
	add	dx, ss:[bp].VTCOP_yPos.low

	mov	cx, es:[si].CAH_count		; cx - element number
	mov	bx, si				; ds:bx - chunk header
	add	si, es:[si].CAH_offset		; ds:si - pt to 1st element

morePoint:
	add	es:[si].SPS_point.PWBF_y.WBF_int, dx
	push	es:[si].SPS_point.PWBF_y.WBF_int
	add	es:[si].SPS_point.PWBF_x.WBF_int, ax
	push	es:[si].SPS_point.PWBF_x.WBF_int
	add	si, size SplinePointStruct	; pt to next element
	loop	morePoint

	mov	cx, es:[bx].CAH_count		; cx - element number
	mov	si,sp
	push	ds
	segmov	ds,ss
	mov	al, RFR_ODD_EVEN
	call	GrFillPolygon
	pop	ds

	;
	; fix stack
	;
	shl	cx
	shl	cx		; 4 bytes per morePoint loop
	add	sp, cx		; ax - total bytes of spline points on stack

	jmp	freeBlock

done:
	clc
	.leave
	ret
InvertHotspotsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTToggleInvertAndInvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove TEMP_CONTENT_TEXT_INVERT_HOTSPOTS from this
		object (if it doesn't have or have it, respectively), and
		invert.

PASS:		*ds:si	= Instance ptr

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 nov 1994	added for Clive's sake.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTToggleInvertAndInvert		method dynamic	ContentTextClass,
				MSG_CT_TOGGLE_INVERT_AND_INVERT
	uses	cx, dx, bp
	.enter

	;
	;  Look for TEMP_CONTENT_TEXT_INVERT_HOTSPOTS. If it's there,
	;  we clear it; if it's not, we add it.
	;
	mov	ax, TEMP_CONTENT_TEXT_INVERT_HOTSPOTS
	call	ObjVarFindData
	jnc	addVar

	;
	;  Delete the vardata we just found.
	;

	call	ObjVarDeleteData
	jmp	invertHotspots

addVar:
	clr	cx					;no size
	call	ObjVarAddData

invertHotspots:
	;
	;  Let's create a gstate and draw this stuff right now.
	;

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CT_INVERT_HOTSPOTS
	call	ObjCallInstanceNoLock

	mov	di, bp
	call	GrDestroyState

	.leave
	ret
CTToggleInvertAndInvert	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If start select is over hyperlinked text, select the
		hyperlink to make it visible.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentTextClass
		ax - the message
		cx, dx - coordinates of mouse event
RETURN:		ax - MouseReturnFlags
DESTROYED:	bp, bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTStartSelect				method dynamic ContentTextClass,
					MSG_META_START_SELECT

		push	cx, dx
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock
	;
	; If not selectable, we must grab the large mouse so that
	; we recieve MSG_META_LARGE_END_SELECT, which is where
	; hyperlinks are actually followed.
	;
		mov	ax, MSG_VIS_GRAB_LARGE_MOUSE
		call	GrabOrReleaseMouse
		pop	cx, dx

		call	CTGetLinkAtMousePos		;DIAX <- text position
							;bp,bx - left, top of 
							;  graphic, if any
		cmp	cx, -1				;any link?
		je	noLink				;branch if no link
	;
	; Add current link selection info to vardata
	;
		
		push	ax				;save text pos
		push	cx				;save context token
		push	bx				;save graphic top
		mov	cx, size ContentTextLinkSelection		
		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION
		call	ObjVarAddData
EC <		mov	cx, 1				;want cx != -1	>

		pop	ds:[bx].CTLS_graphicTopLeft.P_y
		pop	ds:[bx].CTLS_contextToken
		pop	ax
		mov	ds:[bx].CTLS_fileToken, dx
		mov	dx, di		
		movdw	ds:[bx].CTLS_selectStart, dxax
		mov	ds:[bx].CTLS_graphicTopLeft.P_x, bp

	;
	; Select the bounds of the link iff it's a text link
	;
		cmp	bp, 0x8000
		jne	noLink
		cmp	ds:[bx].CTLS_graphicTopLeft.P_y, 0x8000
		jne	noLink

		call	CTSelectRunAtPosition
EC <		mov	cx, 1				;want cx != -1	>
			
noLink:
EC <		cmp	cx, -1						>
EC <		jne	noCheck						>
EC <		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION		> 
EC <		call	ObjVarFindData					>
EC <		WARNING_C CONTENT_TEXT_HAS_INVALID_LINK_SELECTION	>
EC < noCheck:								> 

		mov	ax, mask MRF_PROCESSED
		ret
CTStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select in help object's text object

CALLED BY:	MSG_META_LARGE_END_SELECT
PASS:		*ds:si	= Instance ptr
		ss:bp	= LargeMouseData
RETURN:		ax - MouseReturnFlag
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTEndSelect		method dynamic ContentTextClass,
						MSG_META_LARGE_END_SELECT

		call	EndSelectFollowLink
		jnc	noLink
	;
	; JM:  Pretend the mouse moved so that the pointer image
	; can be updated for the new page on which it resides.
	;
		mov	cx, {word}ss:[bp].LMD_location.PDF_x.DWF_int
		mov	dx, {word}ss:[bp].LMD_location.PDF_y.DWF_int
		clr	bp			; pretend no mouse click
		mov	ax, MSG_META_PTR
		mov	di, mask MF_FORCE_QUEUE
		mov	bx, ds:[LMBH_handle]	
		call	ObjMessage
noLink:
	;
	; If this text object is not selectable, release the mouse,
	; which was grabbed in MSG_META_START_SELECT solely to make
	; sure we received MSG_META_LARGE_END_SELECT, so that any
	; selected link would be followed.
	;
		mov	ax, MSG_VIS_RELEASE_MOUSE
		call	GrabOrReleaseMouse
		
		mov	ax, MSG_META_LARGE_END_SELECT
		call	MHSCallSuper

		ornf	ax, mask MRF_PROCESSED	
		ret

CTEndSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabOrReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the text object is not selectable, we will grab/release
		the mouse ourselves, to ensure that MSG_META_LARGE_END_SELECT
		is received and hyperlinks can be followed.

CALLED BY:	CTStartSelect, CTEndSelect
PASS:		*ds:si 	- ContentText
		ax - Grab/Release message
RETURN:		nothing	
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabOrReleaseMouse		proc	near
		uses	cx, dx, bp
		.enter
	;
	; If selectable, mouse is grabbed/released automatically
	;
		push	ax
		mov	ax, MSG_VIS_TEXT_GET_STATE
		call	ObjCallInstanceNoLock
		test	cl, mask VTS_SELECTABLE
		pop	ax
		jnz	done
	;
	; Do the grab/release
	;
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
GrabOrReleaseMouse		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndSelectFollowLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On end select, follow a hyperlink if one was selected.

CALLED BY:	CTEndSelect
PASS:		*ds:si - ContentText	
RETURN:		carry set if link was followed
DESTROYED:	ax, bx, di


PSEUDO CODE/STRATEGY:
	CTStartSelect() adds TEMP_CONTENT_TEXT_LINK_SELECTION if start
	select is over a hyperlink.  CTLargePtr removes it if mouse moves
	out of that link's boundaries.  We only want to follow a link
	if the end select occurs inside the hyperlink boundaries, so
	we only need to check for the existence of
	TEMP_CONTENT_TEXT_LINK_SELECTION

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	There is a problem with using TEMP_CONTENT_TEXT_LINK_SELECTION's
	presence as the determinant in whether or not to follow a
	hyperlink.

	If the user rapidly clicks twice on a hyperlink, it can happen
	that the second start select is received before the old text is
	deleted, so that the same ContentTextLinkSelection data is added 
	to vardata.  If the second end select is then received after the 
	new text has been loaded, the info in ContentTextLinkSelection 
	does not apply and can cause a crash in CTFeedbackForSelectingLink
	if it looks for a graphic element where there is none.  At best, 
	the link destination is loaded twice.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndSelectFollowLink		proc	near
		uses	cx, dx, bp
		.enter

	;
	; Check if we're in the process of following a hyperlink
	; right now.  Don't try to follow it again if so. (See note
	; under KNOWN BUGS above.)
	;
		call	CheckAlreadyFollowingHyperlink
		clc
		jz	noLink
	;
	; See if there is a link selection
	;
		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION
		call	ObjVarFindData
		jnc	noLink				;no link was selected

		movdw	diax, ds:[bx].CTLS_selectStart	;get text link start

		push	ds:[bx].CTLS_contextToken
		push	ds:[bx].CTLS_fileToken		;save link info

		push	ds:[bx].CTLS_graphicTopLeft.P_x
		push	ds:[bx].CTLS_graphicTopLeft.P_y	;save graphic pos
	;
	; If this is a text link, its graphicTopLeft == (0x8000,0x8000)
	;
		cmp	ds:[bx].CTLS_graphicTopLeft.P_y, 0x8000
		jne	noTextLink
		cmp	ds:[bx].CTLS_graphicTopLeft.P_y, 0x8000
		jne	noTextLink
	;
	; Clear the link text selection.
	;
		pushdw	diax	
		pushdw	diax
		mov	bp, sp				;ss:bp <- VisTextRange
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	ObjCallInstanceNoLock
		popdw	diax
		add	sp, size dword		
noTextLink:
	;
	; Select the bounds of the link, then unselect it, to provide user
	; feedback.
	;
		pop	bx				;bx <- graphic top
		pop	dx				;dx <- graphic left
		call	CTFeedbackForSelectingLink
	;
	; Tell the controller a link has been clicked on
	;
		pop	dx
		pop	cx				;get link info

		push	si
		mov	ax, MSG_CGV_FOLLOW_LINK
		call	ObjBlockGetOutput	; ^lbx:si <- block output
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		stc
noLink:
	;
 	; Delete the link info in case we are following a link.
	;
		pushf
		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION
		call	ObjVarDeleteData
		popf
		
		.leave
		ret
EndSelectFollowLink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAlreadyFollowingHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether a hyperlink is already being followed,
		by checking for certain messages on the queue.

CALLED BY:	CTEndSelect
PASS:		*ds:si - ContentText object
RETURN:		zero flag set if following a link
DESTROYED:	ax, bx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAlreadyFollowingHyperlink		proc	near
		.enter

		mov	ax, cs
		push	ax
		mov	ax, offset CustomCheckFollowingLinkCallback
		push	ax
		mov	ax, MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_FREE_BLOCK
		mov	di, mask MF_CUSTOM or mask MF_CHECK_DUPLICATE or \
			mask MF_DISCARD_IF_NO_MATCH or mask MF_FORCE_QUEUE
		mov	bx, ds:[LMBH_handle]
		call	ObjMessage

NOFXIP	<	segmov	es, dgroup, ax					>
FXIP	<	mov	bx, handle dgroup				>
FXIP 	<	call	MemDerefES					>
		cmp	es:followingLink, BB_TRUE	; sets Z flag if TRUE
		mov	es:followingLink, BB_FALSE	; reset
	
		.leave
		ret
CheckAlreadyFollowingHyperlink		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomCheckFollowingLinkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for an event with a method that indicates
		a hyperlink is already being followed.
		If found, set followingLink = TRUE, and
		make sure that this message is discarded by returning
		PROC_SE_EXIT.

CALLED BY:	CheckAlreadyFollowingHyperlink, via ObjMessage
PASS:		ds:bx	= HandleEvent of an event already on queue
		ds:si	= HandleEvent of new event
RETURN:		di = PROC_SE_EXIT, means that a match was found
		di = PROC_SE_CONTINUE, no match so continue looking
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomCheckFollowingLinkCallback		proc	far

		mov	ax,ds:[bx].HE_method	
		cmp	ax, MSG_CT_FREE_STORAGE_AND_FILE
		je	found
		cmp	ax, MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_FREE_BLOCK
		je	found
		cmp	ax, MSG_CT_LOAD_FROM_DB_ITEM_AND_UPDATE_SCROLLBARS
		je	found
		cmp	ax, MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
		je	found
		mov	di, PROC_SE_CONTINUE	; no match, continue
		ret
found:
		push	es
NOFXIP	<	segmov	es, dgroup, ax					>
FXIP 	<	mov	bx, handle dgroup				>
FXIP 	<	call	MemDerefES					>
		mov	es:followingLink, BB_TRUE
		mov	di, PROC_SE_EXIT	; show we're done
		pop	es
		ret
CustomCheckFollowingLinkCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the pointer image if mouse is over a hyperlink

CALLED BY:	MSG_META_PTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentTextClass
		ax - the message

		(cx,dx) - (x,y) position
		bp.low - ButtonInfo
		bp.high - ShiftState

RETURN:		ax - MouseReturnFlags
		^lcx:dx - optr of pointer image, if MRF_SET_POINTER_IMAGE

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTPtr					method dynamic ContentTextClass,
					MSG_META_PTR

		call	CTGetLinkAtMousePos	;cx <- context token
	;
	; JM: Inlined instead
	;
		mov	ax, MSG_CGV_GET_POINTER_IMAGE
		call	MUCallView

		ornf	ax, mask MRF_PROCESSED
		ret

CTPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTLargePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for drag select that leaves a hyperlink boundary

CALLED BY:	MSG_META_LARGE_PTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentTextClass
		ax - the message
		ss:bp - LargeMouseData

RETURN:		ax - MouseReturnFlags
		^lcx:dx - optr of pointer image, if MRF_SET_POINTER_IMAGE

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTLargePtr				method dynamic ContentTextClass,
					MSG_META_LARGE_PTR
	;
	; Convert DWFixed coordinates to format
	; used by MSG_META_START/END_SELECT
	;
		mov	cx, {word}ss:[bp].LMD_location.PDF_x.DWF_int
		mov	dx, {word}ss:[bp].LMD_location.PDF_y.DWF_int

		push	bp			; save LargeMouseData
		call	CTGetLinkAtMousePos	;cx <- contenxt token
						;dx <- file token
						;di.ax <- link start
						;bp,bx - left, top 
						;  graphic, if any
	;
	; If doing a drag selection, check whether ptr has left the link
	; boundaries.  If so, we want to reset the selection boundaries
	; to the original selection start, current end.
	;
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].ContentText_offset
		test	ds:[di].VTI_intSelFlags, \
			mask VTISF_DOING_DRAG_SELECTION
		pop	di
		jz	done

		pushdw	diax
		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION
		call	ObjVarFindData
		popdw	diax
		jnc	noLink			;no link was selected
		cmp	cx, ds:[bx].CTLS_contextToken
		jne	removeLinkSelection
		cmp	dx, ds:[bx].CTLS_fileToken
		jne	removeLinkSelection
		
done:
		pop	bp			; restore LargeMouseData
		mov	ax, MSG_META_LARGE_PTR
		call	MHSCallSuper
		ornf	ax, mask MRF_PROCESSED
		ret

removeLinkSelection:
	;
	; Reset the selection range to {original start select, current pos}
	;
		movdw	cxbx, ds:[bx].CTLS_selectStart
		cmpdw	diax, cxbx
		jae	haveEnd
		xchg	di, cx
		xchg	ax, bx
haveEnd:		
		pushdw	diax			;push VTR_end
		pushdw	cxbx			;push VTR_start
		mov	bp, sp			;ss:bp <- VisTextRange
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	MHSCallSuper
		add	sp, size VisTextRange
	;
	; Remove current link selection info
	;
		mov	ax, TEMP_CONTENT_TEXT_LINK_SELECTION
		call	ObjVarDeleteData
noLink:
		push	si
		mov	cx, -1			;no link ptr, please
		mov	ax, MSG_CGV_GET_POINTER_IMAGE
		call	MUCallView
		pop	si
		jmp	done
		
CTLargePtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetLinkAtMousePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find if there is a hyperlink or hotspot under the mouse.

CALLED BY:	(INTERNAL)

PASS:		*ds:si - ContentTextClass object
		cx, dx - mouse coordinates
		es - dgroup

RETURN:		cx - context token of link
		dx - file token of link
		di.ax - start pos of link
		bp,bx - left, top of graphic, if any

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTGetLinkAtMousePos		proc	near
		uses	es
		.enter
	; 
	; Here a routine checks if mouse click(cx,dx) hits a hotspot
	; If yes, don't try to hilight any text.
	;
		mov	di, dx
		call	HotspotHitDetect		;dx.ax <- hotspot pos
							;cx,bx <- left,top
							;         of graphic
		pushdw	cxbx				; save graphic pos
		mov	bx, 1				;assume it is hotspot
		jc	gotHotspot
	;
	; Get the character nearest to the mouse click
	;
		mov	dx, di
		call	CTGetTextPosFromCoord		;dx:ax <- nearest char
		mov	cx, -1				;assume no link
		mov	di, dx				;di:ax <- offset
		jnc	validTextPos			;if not valid position,
		cmpdw	dxax, 0				; dx:ax = 0 if no text
		je	noLink
validTextPos:
	;
	;  Indicate that this thing isn't graphic by stuffing
	;  0x8000, 0x8000 into the graphic top, left
	;
		add	sp, 4
		mov	bx, 0x8000
		pushdw	bxbx
		clr	bx				;not hotspot
gotHotspot:
	;
	; See if there is any link on that character
	;
		pushdw	dxax			;save char position
		mov	cx, dx
		add	bx, ax			;inc ax if hotspot
		adc	cx, 0			;cx.bx <- end range
		call	CTGetLinkForPos		;cx <- link context token
		popdw	diax
noLink:		
		popdw	bpbx			;bp,bx <- graphic left, top 
		.leave
		ret
CTGetLinkAtMousePos		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTFeedbackForSelectingLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provides user with feedback when a hyperlink is
		selected.

CALLED BY:	CTEndSelect
PASS:		*ds:si - text object
		cx     - token of link name
		diax   - text position
		dx,bx  - left, top of graphic, if applicable
RETURN:		nothing
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTFeedbackForSelectingLink	proc	near
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	cmp	dx, 0x8000
	jne	doHotSpot

	cmp	bx, 0x8000
	LONG	je notHotSpot

doHotSpot:
	sub	sp, size RectDWord	
	mov	bp, sp

	mov	ss:[bp].RD_left.low, dx
	mov	ss:[bp].RD_left.high, 0
	mov	ss:[bp].RD_top.low, bx
	mov	ss:[bp].RD_top.high, 0

	mov	dx, di				;dx:ax <- char position
	call	GetHotspotUpperleftCorner	;dx:ax <- vm chain
	jnz	hsDone

	;
	;  It is a hotspot... let's figure out whether it's a rectangle or
	;  a spline, and draw the thing.
	;

	push	si				; save obj chunk
	call	GetHotspotInstanceData		; es:si <- hs instance data
						; bx <- handle to free
	mov_tr	ax, si				; es:ax <- hs instance data
	pop	si
	jc	hsDone

	push	bx			 	; save block to free

	;
	;  Let's make a GState here and set it's draw mode to MM_INVERT,
	;  since we'll want that in either the rectangle or spline case.
	;
	push	ax, bp				; save hs instance data,
						; RectDWord
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; ^hbp <- gstate
	mov	di, bp				; ^hdi <- gstate

	mov	al, MM_INVERT
	call	GrSetMixMode

	pop	si, bp				; es:si <- hs instance data
						; ss:bp <- RectDWord

	;
	;  Check to see whether we need to feedback a spline or a rectangle
	;

	cmp	es:[si].GHSDS_type, HST_SPLINE
	je	feedbackSpline

	;
	;  Why, it's just a rectangle!
	;

	mov	ax, ss:[bp].RD_right.low
	mov	bx, ss:[bp].RD_bottom.low
	mov	cx, ax
	add	cx, es:[si].GHSDS_parentWidth.WWF_int
	mov	dx, bx
	add	dx, es:[si].GHSDS_parentHeight.WWF_int

	call	GrFillRect

	;
	; Sleep for a bit
	;

	push	ax
	mov	ax, 3
	call	TimerSleep
	pop	ax

	;
	;  Draw it again to erase it.
	;

	call	GrFillRect

	;
	;  Free the GState, the instance data, and stack.
	;
freeGState:
	call	GrDestroyState
	pop	bx
	call	MemFree	

hsDone:
	add	sp, size RectDWord
	jmp	done

feedbackSpline:

	add	si, size GenHotSpotDataStruct		;es:si <- points

	;
	; Now draw a path to see whether a point is inside the path
	;
	mov	cx, es:[si].CAH_count		; cx - element number
	mov	bx, si				; ds:bx - chunk header
	add	si, es:[si].CAH_offset		; ds:si - pt to 1st element
	mov	ax, ss:[bp].RD_right.low	; hotspot's LEFT edge
	mov	dx, ss:[bp].RD_bottom.low	; hotspot's RIGHT edge

morePoint:
	add	es:[si].SPS_point.PWBF_y.WBF_int, dx
	push	es:[si].SPS_point.PWBF_y.WBF_int
	add	es:[si].SPS_point.PWBF_x.WBF_int, ax
	push	es:[si].SPS_point.PWBF_x.WBF_int
	add	si, size SplinePointStruct	; pt to next element
	loop	morePoint

	mov	cx, es:[bx].CAH_count		; cx - element number
	mov	si,sp
	segmov	ds,ss
	mov	al, RFR_ODD_EVEN
	call	GrFillPolygon

	mov	ax, 3
	call	TimerSleep
	
	mov	al, RFR_ODD_EVEN
	call	GrFillPolygon

	;
	; fix stack
	;
	shl	cx
	shl	cx		; 4 bytes per morePoint loop
	add	sp, cx		; ax - total bytes of spline points on stack

	jmp	freeGState

notHotSpot:
	;
	; Sleep for a bit
	;
		push	ax
		mov	ax, 3
		call	TimerSleep
		pop	ax
	;
	; Select the link.
	;
		mov	dx, di
		call	CTSelectRunAtPosition	
		pushdw	dxax			;dxax <- VTR_start
		pushdw	dxax			;dxax <- VTR_end
		mov	bp, sp			;ss:bp <- VisTextRange
	;
	; Sleep for another bit
	;
		mov	ax, 3
		call	TimerSleep
	;
	; Unselect the link.
	;
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	ObjCallInstanceNoLock	;Nuke the selection
		add	sp, size VisTextRange

done:
		.leave
		ret
CTFeedbackForSelectingLink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetTextPosFromCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the nearest character to the passed coordinate

CALLED BY:	ContentTextPtr(), ContentTextEndSelect()
PASS:		*ds:si - ContentTextClass object
		(cx,dx) - (x,y) coordinate to check
RETURN:		carry clear if dx:ax contains a valid text position
			dx:ax - nearest character offset
		carry set if outside text bounds
			dx:ax - offset after last character, or
			dx:ax - 0 if no text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTGetTextPosFromCoord		proc	near
	uses	bx,cx,bp,di
	.enter

	pushdw	dxcx				;save the coordinate
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock		;dx:ax <- size of text
	popdw	cxbx
	tstdw	dxax				;is there any text?
	stc
	jz	done				;nope

	pushdw	dxax				; save the text size
	sub	sp, size PointDWFixed		; allocate a range on stack
	mov	bp, sp				; ss:bp <- point to check
	clr	di	
	mov	ss:[bp].PDF_x.DWF_int.low, bx
	mov	ss:[bp].PDF_y.DWF_int.low, cx
	mov	ss:[bp].PDF_x.DWF_int.high, di
	mov	ss:[bp].PDF_y.DWF_int.high, di
	mov	ss:[bp].PDF_x.DWF_frac, di
	mov	ss:[bp].PDF_y.DWF_frac, di
	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	ObjCallInstanceNoLock		; dx:ax - nearest char position
	add	sp, size PointDWFixed
	popdw	cxbx				; cx:bx <- text size
	;
	; Check if returned position = text size.
	; Hopefully this means that the mouse is outside (below, to the
	; right) of the text bounds, and there is no hyperlink or hotspot
	; here.
	;	
	cmpdw	dxax, cxbx
	clc		
	jne	done
	stc
done:
		
	.leave
	ret
CTGetTextPosFromCoord		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetLinkForPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the link for the given position

CALLED BY:	HelpTextPtr(), HelpTextStartSelect()
PASS:		*ds:si - ContentTextClass object
		dx:ax - start of range to check
		cx:bx - end of range to check
RETURN:		cx - token of link name (-1 for none)
		dx - token of link file
		ax - token of context
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

NOTE: If you pass a position at the start of a run, it'll give you the
      token of the *previous* range. I dunno why.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTypeParams	struct
    GTP_params	VisTextGetAttrParams
    GTP_attrs	VisTextType
    GTP_diffs	VisTextTypeDiffs
GetTypeParams	ends

CTGetLinkForPos		proc	near
	uses	bp
	.enter

	sub	sp, (size GetTypeParams)
	mov	bp, sp				;ss:bp <- ptr to params
	movdw	ss:[bp].VTGAP_range.VTR_start, dxax
	movdw	ss:[bp].VTGAP_range.VTR_end, cxbx
	clr	ss:[bp].VTGAP_flags
	mov	ss:[bp].VTGAP_attr.segment, ss
	lea	ax, ss:[bp].GTP_attrs
	mov	ss:[bp].VTGAP_attr.offset, ax
	mov	ss:[bp].VTGAP_return.segment, ss
	lea	ax, ss:[bp].GTP_diffs
	mov	ss:[bp].VTGAP_return.offset, ax
	mov	ax, MSG_VIS_TEXT_GET_TYPE
	call	ObjCallInstanceNoLock
	mov	cx, ss:[bp].GTP_attrs.VTT_hyperlinkName
	mov	dx, ss:[bp].GTP_attrs.VTT_hyperlinkFile
	mov	ax, ss:[bp].GTP_attrs.VTT_context
	add	sp, (size GetTypeParams)

	.leave
	ret
CTGetLinkForPos		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTSelectRunAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects the run at the current position.

CALLED BY:	CTFeedbackForSelectingLink
PASS:		*ds:si - ContentText object
		dx.ax - position
RETURN:		dxax - VTR_start of selected range
		cxbx - VTR_end of selected range

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTSelectRunAtPosition	proc	near
	.enter

	sub	sp, size VisTextRange
	mov	bp, sp			;SS:BP <- bounds of the run
	call	CTGetLinkBounds

;	We have a problem here. If passed a position between runs,
;	CTGetLinkBounds will return the run starting at the
;	position, while CTGetLinkForPos will return the run ending at
;	the passed position. This means, if we click at the end of a run,
;	CTGetLinkForPos will think we've clicked in a run, but 
;	CTGetLinkBounds will select the *next* run.
;	SO... We check to see if the run is a valid type run. If not,
;	we get the *previous* run instead.

	movdw	dxax, ss:[bp].VTR_start
	push	dx, ax				;Save return values.
	movdw	cxbx, ss:[bp].VTR_end
	push	cx, bx
	call	CTGetLinkForPos
	cmp	cx, -1
	jne	10$

	movdw	dxax, ss:[bp].VTR_start
	subdw	dxax, 1
EC <	ERROR_C	SELECTION_DID_NOT_INCLUDE_LINK				>
   	call	CTGetLinkBounds
10$:

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	pop	cx, bx
	pop	dx, ax				;Get return values.
	add	sp, size VisTextRange
	.leave
	ret
CTSelectRunAtPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetLinkBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds (text position of start and end) of the 
		hyperlink type run that includes the current position

CALLED BY:	GLOBAL
PASS:		dx.ax - position
		*ds:si - ContentTextClass
		ss:bp - VisTextRange to fill in
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTGetLinkBounds		proc	near
	uses	ax, cx, dx, bp
	.enter
	mov	cx, bp			;ss:cx - VisTextRange
	sub	sp, size VisTextGetRunBoundsParams
	mov	bp, sp			;SS:BP <- params for message
	mov	ss:[bp].VTGRBP_type, OFFSET_FOR_TYPE_RUNS
	movdw	ss:[bp].VTGRBP_position, dxax
	movdw	ss:[bp].VTGRBP_retVal, sscx
	mov	ax, MSG_VIS_TEXT_GET_RUN_BOUNDS
	call	ObjCallInstanceNoLock

	add	sp, size VisTextGetRunBoundsParams
	.leave
	ret
CTGetLinkBounds	endp


;------------------------------------------------------------------------
;		HotSpot hit detection code
;------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HotspotHitDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the coordinates are within a hotspot.
		If it is, return the text offset of the hotspot's C_GRAPHIC.

CALLED BY:	(INTERNAL) CTGetLinkAtMousePos
PASS:		*ds:si - ContentTextClass object
		(cx,dx) - (x,y) coordinate to check
RETURN:		carry set if the mouse is within a hotspot
		     dx:ax - character offset of the hotspot's C_GRAPHIC
		     cx,bx - left,top of graphic containing hotspot
		carry clear if the mouse is NOT within a hotspot

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	The hotspots are stored in the order that they were created.
	If there are overlapping hotspots, we want to find the last
	hotspot created that contains the mouse click.
	So, we check the hotspots in reverse order and return the 
	first hotspot that contains the mouse click.
	
	/* Is the mouse click over a graphic? */
	if( GetGraphicAtMouseClick(&position) == NotOverAGraphic )
		return carry clear;

	count = -1;

	/* find position after last hotspot and count hotspots */
	do {
		position++;
		count++;
	} until ( HotspotCharAtPosition(position) == FALSE );

	/* test if no hotspots */
	if (count == 0) {
		return carry clear;
	}

	/* check hotspots in reverse order */
	do {
		position--;
		if ( mouseCoordinatesWithinHotspot() == TRUE ) {
			return carry set;
		}
		count--;
	} until ( count == 0 );

	return carry clear; /* no hotspot hits */


Here we assume that the text object stores the graphics and hotspots in
the following sequence: (this is an example)

On the screen:
	           +-------------+
	           |             |
	           | +--+   |\   |
	           | |  |   | \  |
	           | +--+   |_/  |
	           |             |
       a graphipc, +-------------+ with 2 hotspots

text object:
	/gstring graphic char/hotspot graphic char/hotspot graphic char/

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/15/94    	Initial version
	lester	11/ 2/94  	check hotspots in reverse order

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HotspotHitDetect	proc	near
	uses	si,di,bp
mouseX		local	word	push	cx
corner		local	RectDWord
graphic		local	VisTextGraphic
	.enter

	;
	; Get the graphic char at the mouse click
	;
	mov	bx, dx			; (cx, bx) - mouse position
	lea	di, corner
	call	GetGraphicAtMouseClick	; dx:ax - graphic char position
					; corner - upper left corner of graphic
	jnc	noGraphic		; jump if mouse not on a graphic

	;
	; move to end of hotspot list (right after)
	;
	mov	cx, -1	   		; cx = -1 = hotspot counter, 
	lea	di, graphic
moreHotspots:
	incdw	dxax
	inc	cx
	call	GetGraphicIfThereIsOne
	jnc	continue			; not a graphic
	;
	; make sure it's hotspot
	;
	cmp	ss:[di].VTG_type, VTGT_VARIABLE
	jnz	continue
	cmp	ss:[di].VTG_data.VTGD_variable.VTGV_type, VTVT_HOTSPOT
	jnz	continue

	jmp	moreHotspots

continue:
	; cx = count of hotspots
	; dx.ax = position right after last hotspot or right after the 
	;         graphic char if no hotspots
	; mouseX,bx = mouse position
	; corner = upper left corner of graphic

	tst	cx				; no hotspots
	jz	noHotspots

	;
	; Check hotspots in reverse order
	;
checkNextHotspot:
	decdw	dxax		; dxax = current hotspot char offset
	push	bp, cx
	mov	cx, mouseX
	lea	bp, corner
	call	GetHotspotAtMouseClick
	pop	bp, cx
	tst	di
	stc				; assume hotspot hit
	jz	hitHotspot		; mouse whithin hotspot, return carry set

	loop	checkNextHotspot

noHotspots:
	clc			; none of the hotspots contained the mouse pos

hitHotspot:
	mov	bx, corner.RD_top.low
	mov	cx, corner.RD_left.low
noGraphic:

	.leave
	ret
HotspotHitDetect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHotspotAtMouseClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if mouse click is within a hotspot

CALLED BY:	HotspotHitDetect
PASS:		*ds:si - instance
		dx:ax - text offset to check
		cx:bx - mouse position
		ss:bp - RectDWord, upper left corner of the graphic
			in (RD_left, RD_top)
RETURN:		zero clear - graphic at passed offset is NOT a hotspot
		zero set - graphic at passed offset is a hotspot
 		  di = 0
			the mouse click is within the hotspot
		  di != 0
			the mouse click is not within the hotspot
DESTROYED:	es
SIDE EFFECTS:	NOTE:
		the passed text offset MUST be in the grahic run
		array.  Thus, before call this routine, call
		GetGraphicIfThereIsOne first to determine.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHotspotAtMouseClick	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter

	call	GetHotspotUpperleftCorner	; (RD_right,RD_bottom) ==
						; upper left corner of
						; hotspot
	jnz	nothotspot

	;
	; ss:bp - RectDWord
	;	(RD_left,RD_top) =  upperleft corner of the graphic
	; 	(RD_right,RD_bottom) = upperleft corner of the hotspot
	; dx:ax - vmChain of the graphic element
	; cx:bx - mouse position
	;
	call	MouseClickWithinHotspot
	mov	di, 0				;return di=0 if click is
	jc	clickInside			; within hotspot
	inc	di				;else return di != 0
clickInside:
	xor	si, si				;sets the zero flag
nothotspot:
	.leave
	ret
GetHotspotAtMouseClick	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseClickWithinHotspot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is the mouse click within the hotspot?

CALLED BY:	GetHotspotAtMouseClick
PASS:		*ds:si - text object
		dx:ax - vmChain of the graphic element
		(cx, bx) - mouse position
		ss:bp - RectDWord, in document coord.
		(RD_left, RD_top) - upper left corner of the graphic
		(RD_right, RD_bottom) - upper left corner of hotspot 

RETURN:		carry set -
			mouse click within the hotspot
		carry clear -
			mouse click is not within the hotspot
DESTROYED:	everything but bp and ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseClickWithinHotspot	proc	near
	uses	bp
	.enter
	;
	; Is mouse position < hotspot left edge or top edge?
	; 
	mov	di, ax
	clr	ax
	cmpdw	axcx, ss:[bp].RD_right	; hotspot's LEFT edge, not right
	jl	notIn			; mouse pos < hotspot left edge?
	cmpdw	axbx, ss:[bp].RD_bottom	; hotspot's TOP edge, not bottom
	jl	notIn			; mouse pos < hotspot top edge?
	mov	ax, di
	;
	; Now get the width of the hotspot
	;
	push	si			; *ds:si - text object
	pushdw	cxbx			; save mouse position
	call	GetHotspotInstanceData	; es:si - instance data of type
	jc	error			;	GenHotSpotDataStruct
					; ^hbx - handle of es
	mov	ax, es:[si].GHSDS_parentWidth.WWF_int
	mov	cx, es:[si].GHSDS_parentHeight.WWF_int
	mov	dx, si
	popdw	disi			; restore mouse position
	;
	; Is mouse position > hotspot right edge or bottom edge?
	; 	(di,si) - mouse position
	; 	ax - width 
	;	cx - height of hotspot
	;
	push	bx			; save handle for MemFree
	push	dx			; save es:[si]
	clr	dx, bx
	adddw	dxcx, ss:[bp].RD_bottom	; dxcx - hotspot's bottom edge
	cmpdw	bxsi, dxcx		; mouse pos > hotspot bot. edge?
	mov	cx, si			; (di, cx) - mouse position
	pop	si			; restore es:[si]
	jg	notInside
	clr	dx
	adddw	dxax, ss:[bp].RD_right 	; dxax - hotspot's right edge
	cmpdw	bxdi, dxax		; mouse pos > hotspot right edge?
	jg	notInside
	;
	; If the hotspot is a spline, we need to do vigorous check
	;	(di,cx) - mouse position
	;
	cmp	es:[si].GHSDS_type, HST_SPLINE
	jne	inside
	
	add	si, size GenHotSpotDataStruct
	mov	bx, si
	pop	ax
	pop	si			; get *ds:si - text object
	push	si
	push	ax
	call	MouseClickWithinSpline
	jnc	notInside

inside:
	pop	bx
	call	MemFree
	pop	si			; restore *ds:si - text object
	stc
	jmp	exit

notInside:
	pop	bx			; restore handle for MemFree
	call	MemFree
	pop	si			; restore *ds:si - text object
notIn:
	clc
exit:
	.leave
EC <	call	AssertIsCText				>	
	ret

error:
	popdw 	cxbx
	pop	si
	clc
	jmp	exit

MouseClickWithinHotspot	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseClickWithinSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is the mouse click over a spline?

CALLED BY:	MouseClickWithinHotspot
PASS:		*ds:si - text object
		(di,cx) - mouse click
		es:bx - spline point array
		ss:bp - RectDWord, in document coord.
		(RD_left, RD_top) - upper left corner of the graphic
		(RD_right, RD_bottom) - upper left corner of hotspot 

RETURN:		carry set - mouse click is in the spline
		carry clear - otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseClickWithinSpline	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter
EC <	call	AssertIsCText				>	

	pushdw	dicx				; save mouse position
	;
	; Create a gstate
	;
	push	bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; ^hbp - gstate

	mov	si, bx				; es:si - point array
	mov	di, bp
	mov	cx, PCT_REPLACE
	call	GrBeginPath
	;
	; Now draw a path to see whether a point is inside the path
	;
	segmov	ds, es				; ds:si - point array
	mov	cx, ds:[si].CAH_count		; cx - element number
	mov	bx, si				; ds:bx - chunk header
	add	si, ds:[si].CAH_offset		; ds:si - pt to 1st element
	pop	bp
	mov	ax, ss:[bp].RD_right.low	; hotspot's LEFT edge
	mov	dx, ss:[bp].RD_bottom.low	; hotspot's RIGHT edge

morePoint:
	add	ds:[si].SPS_point.PWBF_y.WBF_int, dx
	push	ds:[si].SPS_point.PWBF_y.WBF_int
	add	ds:[si].SPS_point.PWBF_x.WBF_int, ax
	push	ds:[si].SPS_point.PWBF_x.WBF_int
	add	si, size SplinePointStruct	; pt to next element
	loop	morePoint

	mov	cx, ds:[bx].CAH_count		; cx - element number
	mov	si,sp
	segmov	ds,ss
	call	GrDrawPolyline
	call	GrEndPath

	;
	; fix stack
	;
	shl	cx
	shl	cx		; 4 bytes per morePoint loop
	add	sp, cx		; ax - total bytes of spline points on stack

	;
	; Determine if the mouse click is in the spline
	;
	popdw	axbx
	mov	cl, RFR_ODD_EVEN
	call	GrTestPointInPath

if 0
	jnc	destroyState
	;
	; Draw the path just for the hooey of it
	;

	mov	al, MM_INVERT
	call	GrSetMixMode

	call	GrFillPath
	stc
destroyState:
endif

	;
	; Don't forget to destroy the gstate.
	;
	pushf
	call	GrDestroyState
	popf

	.leave
	ret
MouseClickWithinSpline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHotspotInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	extract the hotspot's instance data from the graphic vmChain

CALLED BY:	MouseClickWithinHotspot
PASS:		*ds:si - ContentText
		dx:ax - hotspot's graphic vmChain
RETURN:		carry clear - got instance data
			es:si - GenHotSpotDataStruct
			^hbx - handle of block which must be freed by caller
		carry set - error allocating block
			bx - 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHotspotInstanceData	proc	near
		class	ContentTextClass
		uses	ax, cx, dx, di, bp, ds
gstring		local	word
sizeElmt	local	word
dataHandle	local	word
		.enter
EC <		call	AssertIsCText					>

		clr	ss:dataHandle
	;
	; Get vm file
	;
		mov	di, ds:[si]
		add	di, ds:[di].ContentText_offset
		mov	bx, ds:[di].VTI_vmFile
	;
	; load gstring
	; 
		mov	cl, GST_VMEM
		mov	si, dx
		call	GrLoadGString	; si - handle of graphic string
		mov	ss:gstring, si

		clr	di, cx, bx
		call	GrGetGStringElement	; cx - size
						; al - opcode of element
		mov	ss:sizeElmt, cx
		cmp	al, GR_ESCAPE		
		jne	badElement
	;
	; allocate block to store hotspot instance data
	; 
		mov	ax, cx			; ax - size needed
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	finish
		mov	ds, ax
		mov	ss:dataHandle, bx
	;
	; get gstring element
	;
		clr	bx			; ds:bx - data buffer
		mov	si, ss:gstring		; ^hsi - gstring
		clr	di			; no gstate
		mov	cx, ss:sizeElmt		; cx - buffer size
		call	GrGetGStringElement
		add	bx, 5			; skip the opcode
	; 
	; destroy the gstring
	;
		push	bx
		clr	di
		mov	si, ss:gstring
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		pop	si
		segmov	es, ds, ax		; es:si <- data
		mov	bx, ss:dataHandle	; ^hbx <- data block handle
		clc
finish:
		.leave
		ret
badElement:
		clr	di
		mov	si, ss:gstring
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		stc
		jmp	finish
GetHotspotInstanceData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHotspotUpperleftCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	the name says it all

CALLED BY:	GetHotspotAtMouseClick
PASS:		*ds:si - ContentText
		dx:ax - potential hotspot char position
		ss:bp - RectDWord coord of upper left corner of graphic
RETURN:		zero set:
			(RD_right, RD_bottom) -   
				upper left corner of hotspot
			dx:ax - vmChain of graphic element
		zero clear:
			the position is not a hotspot
			ax, dx - preserved
DESTROYED:	nothing
SIDE EFFECTS:	NOTE:
		the passed text offset MUST be in the grahic run
		array.  Thus, before call this routine, call
		GetGraphicIfThereIsOne first to determine.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHotspotUpperleftCorner	proc	near
		uses	bx,cx,di,bp
		.enter
EC <		call	AssertIsCText				>	

	;
	; Get the graphic element of the passed char
	;
		sub	sp, size VisTextGraphic
		mov	di, sp
		call	GetGraphicElement		
	;
	; make sure it's hotspot
	;
		cmp	ss:[di].VTG_type, VTGT_VARIABLE
		jnz	done
		cmp	ss:[di].VTG_data.VTGD_variable.VTGV_type, VTVT_HOTSPOT
		jnz	done
	;
	; Get hotspot's offset from the upperleft corner of the graphic
	;
		mov	bx,
			{word}ss:[di].VTG_data.VTGD_variable.VTGV_privateData
		mov	cx,
			{word}ss:[di+2].VTG_data.VTGD_variable.VTGV_privateData
	;
	; Calculate hotspot's absolute upperleft corner
	;
		clr	ax
		adddw	axbx, ss:[bp].RD_left	; borrow RD_right and RD_bottom
		movdw	ss:[bp].RD_right, axbx	; to store hotspot upperleft
		clr	ax		
		adddw	axcx, ss:[bp].RD_top
		movdw	ss:[bp].RD_bottom, axcx
	;
	; Return the hotspot's VMChain, and set the ZERO flag
	;
		movdw	dxax, ss:[di].VTG_vmChain
		xor	cx, cx			; set the ZERO flag
done:
		mov	bx, ax			
		lahf				
		add	sp, size VisTextGraphic
		sahf				
		mov	ax, bx
		.leave
		ret
GetHotspotUpperleftCorner	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGraphicAtMouseClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text offset of a graphic at the mouse click

CALLED BY:	(INTERNAL) HotSpotHitDetect
PASS:		*ds:si - ContentText
		(cx,dx) coordinate to check
		ss:di - RectDWord to fill in
RETURN:		carry set - 
			dx:ax - graphic char at which the mouse clicks
			ss:di - upperleft corner of the graphic
		carry clear -
			the mouse click is not over a graphic char
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGraphicAtMouseClick	proc	near
	uses	bx,cx,si,di,bp
	.enter
EC <	call	AssertIsCText				>	

	push	di			; save ss:di structure
	pushdw	cxdx			; save mouse click

	call	CTGetTextPosFromCoord	; dx:ax - nearest char position

	popdw	bxcx			; restore (bx,cx) - mouse click
	pop	di			; restore ss:di struture
	;
	; If carry set, either there is no text (dx:ax = 0), or the
	; returned position is after the last char (dx:ax = text size)
	;
	jnc	validTextPos
	cmpdw	dxax, 0
	clc
	je	done	
validTextPos:
	;
	; The nearest char may not be the one under the mouse click.
	; Thus, we need to check the neighbor chars to see which one
	; that mouse click is actually over.
	;
	call	WithinGraphicBound
	jc	done
	decdw	dxax
	call	WithinGraphicBound
	jc	done
	incdw	dxax
	incdw	dxax
	call	WithinGraphicBound
done:
	.leave
	ret
GetGraphicAtMouseClick	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WithinGraphicBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the mouse click is over a graphic char

CALLED BY:	(INTERNAL) GetGraphicAtMouseClick
PASS:		*ds:si - ContentText
		dx:ax - text offset to check
		(bx, cx) - mouse click
		ss:di - RectDWord to fill in
RETURN:		carry set - the passed text offset is a graphic char
			and the mouse click is within the bound of the
			the graphic char
			ss:di - upper left corner of the graphic
		carry clear - otherwise

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WithinGraphicBound	proc	near
	uses	ax,bx,cx,dx,si,di,bp
passedDI	local	word	push di
mousePos	local	Point
params		local	VisTextConvertOffsetParams
graphic		local   VisTextGraphic		
	.enter
EC <	call	AssertIsCText				>	

	mov	mousePos.P_x, bx
	mov	mousePos.P_y, cx
	movdw	params.VTCOP_offset, dxax
	;
	; Is there a graphic at the passed offset?
	;
	lea	di, graphic			;ss:di <- graphic
EC <	tst	di						>
EC <	ERROR_Z -1 						>
	call	GetGraphicIfThereIsOne
	LONG 	jnc	notFound
	;
	; Is it an embedded graphic?
	;
	cmp	graphic.VTG_type, VTGT_GSTRING
	LONG	jne	notFound
	;
	; Get the coordinate of its upper left corner
	;
	push	bp				; save local frame pointer
	lea	bp, params
	call	CallVisTextConvertOffsetToCoordinate		
	pop	bp
	;
	; Is the mouse click within the bound of the graphic char?
	;
	clr	cx
	mov	dx, mousePos.P_x	; cx.dx <- mouse X position
	cmpdw	params.VTCOP_xPos, cxdx	; is graphic left > mouse X?
	jg	notFound	
	clr	bx			
	mov	ax, graphic.VTG_size.XYS_width
	adddw	bxax, params.VTCOP_xPos	; bx.ax <- graphic Right edge
	cmpdw	cxdx, bxax		; is mouse X > graphic right?
	jg	notFound
	;
	; XXX - What about mouse Y????
	;
	movdw	bxax, params.VTCOP_xPos	; (xPos, yPos) upper left
	movdw 	cxdx, params.VTCOP_yPos	; of the graphic char
	mov	di, passedDI
	movdw	ss:[di].RD_left, bxax	; fill in PointDWord
	movdw	ss:[di].RD_top, cxdx
	stc
	jmp	exit		; YES, mouse click within the bound

notFound:
	clc			; oh NO! mouse click not in the bound
exit:
	.leave
	ret
WithinGraphicBound	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallVisTextConvertOffsetToCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE if
		running on a 2.1 or later text library, else hack around
		in the text code and call TSL_ConvertOffsetToCoordinate
		directly.

CALLED BY:	WithinGraphicBound
PASS:		*ds:si - ContentText object
		ss:bp - VisTextConvertOffsetParams
RETURN:		ss:bp - filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallVisTextConvertOffsetToCoordinate		proc	far
		uses ax, bx, cx, dx, di, es
		.enter

		call	CheckTextLibraryProtocol
		jc	oldLibrary
		mov	dx, ss
		mov	ax, CONVERT_OFFSET_TO_COORDINATE_MSG_NUMBER
		call	ObjCallInstanceNoLock
done::
		.leave
		ret
oldLibrary:

if 	_FXIP
		ERROR FXIP_CANNOT_CALL_TEXT_MSG_DIRECTLY
else
		
	; Create a GState so that one is available when
	; TSL_ConvertOffsetToCoordinate is called.

		mov	ax, MSG_VIS_CREATE_CACHED_GSTATES
		call	ObjCallInstanceNoLock
	;
	; If passed offset is beyond the end of the text, replace the
	; offset with the last text position, else the routine will crash.
	;
		movdw	cxbx, ss:[bp].VTCOP_offset
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock		;dx.ax <- text size
		cmpdw	cxbx, dxax
		jbe	usePassedOffset
		movdw	ss:[bp].VTCOP_offset, dxax
usePassedOffset:		
		
	; set up extra values to pass to ProcCallModuleRoutine

		segmov	es, <segment idata>, ax
		tst	es:convertHandle
		jz	getOffset
		mov	bx, es:convertHandle
		mov	di, es:convertOffset
haveOffset:
		push	bx
		call	MemLock
		mov	es, ax
		movdw	dxax, ss:[bp].VTCOP_offset
		call	CallIt
		movdw	ss:[bp].VTCOP_xPos, cxbx
		movdw 	ss:[bp].VTCOP_yPos, dxax
		pop	bx
		call	MemUnlock

	; now destory the cached gstate we created above 

		mov	ax, MSG_VIS_DESTROY_CACHED_GSTATES
		call	ObjCallInstanceNoLock

		jmp	done

getOffset:
		call	GetHandleForTSL_ConvertOffsetToCoordinate
		call	GetOffsetForTSL_ConvertOffsetToCoordinate
		mov	es:convertHandle, bx
		mov	es:convertOffset, ax
		mov	di, ax
		jmp	haveOffset		
endif
CallVisTextConvertOffsetToCoordinate		endp

ife 	_FXIP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn TSL_ConvertOffsetToCoordinate into a far procedure
		before calling it, then restore it to its pristine state.

CALLED BY:	CallVisTextConvertOffsetToCoordinate
PASS:		es:di - address of TSL_ConvertOffsetToCoordinate
		dx.ax - text position to pass to TSL_ConvertOffsetToCoordinate 
RETURN:		return values from TSL_ConvertOffsetToCoordinate 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We need to grab the semaphores that might be needed by 
	TSL_ConvertOffsetToCoordinate because when we call SysEnterCritical
	we can no longer context switch. 

	If we do not grab the semaphores that TSL_ConvertOffsetToCoordinate
	might need and it turns out that a different thread has them, we 
	are in bad shape because we can not context switch to that thread
	and have it release the semaphores. ----> Deadlock city.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/14/94		Initial version
	lester	10/27/94  	grab the semaphores we might need

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallIt		proc	far			;*MUST* be a far proc so that
						; it has a far return
	;
	; Grab all the semaphors that we might need before we call 
	; SysEnterCritical which disables context switching.
	;
		push	ax
		call	FSDLockInfoExcl		; nukes ax
		call	MemGrabHeap
		call	SysLockBIOS
		pop	ax		

		call	SysEnterCritical	; prevent context switches
						; while we dork w/code
		mov	bx, di			; save offset of TSL_Convert...
		push	ax
		mov	cx, -1			; look forever		
		mov	al, 0xc3		; look for RETN
		repnz	scasb			; find it
		dec	di			; back up to point at it 
		mov	{byte}es:[di], 0xcb	; change to far return
		pop	ax			; dx.ax <- text offset
	;
	; Monkey with the stack to get returns to take us to the right place.
	;
	; First, push the "return" address that we want to return to after
	; TSL_ConvertOffsetToCoordinate is completed.
	;
		push	cs
		mov	cx, offset returnLocation
		push	cx
	;
	; Then push address of TSL_ConvertOffsetToCoordinate itself,
	; so that a far return will cause a jump to it.
	;
		push	es
		push	bx
		ret		

returnLocation:
	;
	; es:di points to the return opcode.  Change back to a near return.
	;  	
		mov	{byte}es:[di], 0xc3

		call	SysExitCritical		; allow context switches again.
	;
	; Release the semaphors. In reverse order.
	;
		call	SysUnlockBIOS
		call	MemReleaseHeap
		call	FSDUnlockInfoExcl

		ret
CallIt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GetOffsetForTSL_ConvertOffsetToCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Reach deep into an old text library (from 2.0 to before 2.01,
                which should have been determined before this routine is
                called) & pull out the offset of TSL_ConvertOffsetToCoordinate.
                This offset should be stored in a global variable in dgroup
                & then used to call the routine later if this technique must
                be used.

CALLED BY:      CallVisTextConvertOffsetToCoordinate
PASS:           bx      = handle of VisTextDoKeyFunction
	        ax      = offset of VisTextDoKeyFunction
RETURN:         ax      = offset of TSL_ConvertOffsetToCoordinate
DESTROYED:      ax,cx,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This code is highly sensitive to changes in the routines
	which are scanned to find the offset of TSL_ConvertOffsetToCoordinate.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Doug    9/8/94          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOffsetForTSL_ConvertOffsetToCoordinate       proc    near
        	uses    si, es
	        .enter

		mov	di, ax
	        call    MemLock		; lock the TextSelect resource
        	mov     es, ax		; es:di <- address VisTextDoKeyFunction

	; search VisTextDoKeyFunction for call to TSL_HandleKbdShortcut

		mov	cx, -1
		mov     al, 0xe8 	; e8h = opcode for near call
          	repnz   scasb           ; find call to TSL_HandleKbdShortcut
		mov 	ax, es:[di]	; ax <- displacement from ip to 
					; address of TSL_HandleKbdShortcut
		add	di, size word	; es:di <- offset of next opcode
		add	di, ax		; di <- offset of TSL_HandleKbdShortcut

	; search TSL_HandleKbdShortcut for call VTFSelectAdjustStartOfLine

		mov	cx, -1
		mov     al, 0x81        ; need opcode for "add bx, offset cs:"
		repnz   scasb           ; find the add opcode
		inc	di		; step past the add destination
		mov     di, es:[di]     ; load the offset of visTextBindings
		add	di, 6*26+1	; get offset of DefTextCall entry 
					; for VTFSelectAdjustStartOfLine,
					; where entries are 6 bytes and the
					; first byte is near call opcode
		mov	ax, es:[di]	; ax <- the displacement
		add 	di, size word	; es:di <- next opcode
		add	di, ax		; di <- offset of
					; VTFSelectAdjustStartOfLine

	; search VTFSelectAdjustStartOfLine for TSL_ConvertOffsetToCoordinate

		mov	cx, -1
		mov     al, 0xe8       	; opcode for near call
		repnz   scasb           ; find first near call
					;   (FindPreviousLineEdge)
	;;
	;; It just so happens that in the trunk version of 
	;; VTFSelectAdjustStartOfLine, the displacment for the above call
	;; contains the byte e8h, so that the next scan only moves one
	;; byte forward in the code, and does not correctly find the
	;; offfset to TSL_ConvertOffsetToCoordinate.  The fix is to 
	;; increment di past the displacement before continuing the scan.
	;; (cassie, 1/12/95)
	;;
		add	di, size word	; step past the displacement, which
					;   could contain 0xe8
		repnz   scasb           ; find 2nd near call
					;   (TSL_ConvertOffsetToCoordinate)
		mov	ax, es:[di]	; ax <- displacement to TSL_Convert...
		add	di, size word	; es:di <- next opcode
		add	ax, di		; ax <- offset to TSL_ConvertOffset...

		call    MemUnlock
	        .leave
	        ret
GetOffsetForTSL_ConvertOffsetToCoordinate       endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GetHandleForTSL_ConvertOffsetToCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Search through the VisTextClass method table for
		MSG_VIS_TEXT_DO_KEY_FUNCTION resource handle and offset.

CALLED BY:      CallVisTextConvertOffsetToCoordinate
PASS:		*ds:si  = ContentText object
RETURN:         bx      = handle TSL_ConvertOffsetToCoordinate
		ax	= offset of VisTextKeyFunction
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	This code is from ObjCallMethodTable.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Cassie  9/8/94          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHandleForTSL_ConvertOffsetToCoordinate       proc    near
        	uses    si, ds, bp, es
		.enter
EC <		call	AssertIsCText					>
		mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
		mov	bp, segment VisTextClass
		mov	es, bp
		mov	bp, offset VisTextClass		;es:di <- VisTextClass
	;
	; Scan method table for match. es:bp = class structure
	; Since we have already determined that methods defined in
	; the master class that the method passed is defined in
	; ARE handled by this class, then know that Class_methodCount
	; is not 0.
	;
		mov	di,bp				
		add	di,Class_methodTable		
		mov	cx,es:[bp].Class_methodCount		
		repnz	scasw		
EC <		ERROR_NZ	-1					>

	; found method -- call it
	; di points 2 beyond the method number, 1 is the number of methods
	; after the match. To get to the routine we need to evaluate:
	; 	bx = ((di - (bp.Class_methodTable+2)) * 2) + (di + cx*2)
	; the first term yields the offset into the routine table of the
	; routine we want, while the second term advances di to the start
	; of the routine table. This can be simplified to
	; 	bx = ((di - bp - (Class_methodTable+2) + cx) * 2) + di

		mov	bx, di			; Calculate distance
		sub	bx, bp			; from start of method
						; table in BX
		sub	bx, Class_methodTable+2
		add	bx, cx			; Merge in number of
						; remaining methods
		shl	bx			; Distributive law lets	
						; us do a single
						; multiplication by 2
		add	bx, di			; Point to routine

	; handler in dword ptr es:[bx]

		mov	ax, es:[bx].segment

	; CASE for method handler in a movable resource

		shl	ax,1					
		shl	ax,1					
					    ;break up series of shifts for
					    ;pre-fetch queue
		mov	bx,es:[bx]	    ;bx = offset of call

		shl	ax,1	
		shl	ax,1	

		xchg	ax,bx	
		.leave
	        ret
GetHandleForTSL_ConvertOffsetToCoordinate       endp
endif				



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTextLibraryProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out whether text library has 
		MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE or not.

CALLED BY:	CallVisTextConvertOffsetToCoordinate
PASS:		nothing
RETURN:		carry set if text library is old and doesn't
		have MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTextLibraryProtocol		proc	near
		uses	ax,bx,di,ds,es
		.enter

NOFXIP< 	segmov	ds, <segment idata>, ax		;ds = dgroup	>
FXIP <		mov	bx, handle dgroup				>
FXIP <		call	MemDerefDS			; ds = dgroup	>
		tst	ds:textProtocol.PN_major
		jz	getProtocol
		mov	ax, ds:textProtocol.PN_major
		mov	bx, ds:textProtocol.PN_minor
testProtocol:
	;
	; Anything below protocol 3.13 (which the 2.1 text library has on
	; 1/26/95 - this is more stringent than need be, but we haven't 
	; shipped any devices which have 2.1 yet) will be treated specially
	;
		cmp	ax, 3				;carry set if < 3
		jc	done
		cmp	bx, 13				;carry set if < 13
done:
		.leave
		ret

getProtocol:
		sub	sp, size ProtocolNumber
		mov	di, sp
		segmov	es, ss, ax
		mov	bx, handle text
		mov	ax, GGIT_GEODE_PROTOCOL
		call	GeodeGetInfo
		mov	ax, ss:[di].PN_major
		mov	bx, ss:[di].PN_minor
		mov	ds:textProtocol.PN_major, ax
		mov	ds:textProtocol.PN_minor, bx
		add	sp, size ProtocolNumber
		jmp	testProtocol

CheckTextLibraryProtocol		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGraphicIfThereIsOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is a graphic run at the passed text offset,
		return the graphic

CALLED BY:	(INTERNAL)

PASS:		*ds:si - ContentTextClass object
		dx:ax - text offset
		ss:di - buffer for VisTextGraphic
		   di = 0 if don't want element returned
RETURN:		carry set if graphic token found
		carry clear if no graphic token found
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGraphicIfThereIsOne	proc	near
	class	ContentTextClass
	uses	ax,bx,cx,dx,si,bp,di
	.enter
EC <	call	AssertIsCText				>	
	;
	; Get VM file
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].ContentText_offset
	tst	ds:[bx].VTI_vmFile
	clc				; default for jump: no graphic token
	jz	done
	;
	; Get VM block of graphic runs.
	;
	push	si
	pushdw	dxax
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	call	ObjVarFindData
EC <	ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	mov	si, ds:[bx]		;*ds:si <- graphic run array
	popdw	cxdx			;cx:dx <- text offset
	;
	; Search for the passed position in the graphics run array
	;
	push	di
	mov	bx, cs
	mov	di, offset FindGraphicRunCallback
	call	ChunkArrayEnum	
	pop	di			; ss:di <- buffer for graphic
	pop	si			;*ds:si <- text object
	jnc	done			; carry clear if no graphic
	;
	; Get the graphic element of the passed text offset
	;
	tst	di
	jz	noData		
	mov	ax, cx
	xchg	ax, dx			; dx.ax = text position of graphic
	call	GetGraphicElement
noData:		
	stc				; carry set to indicate graphic found
done:
	.leave
	ret

GetGraphicIfThereIsOne	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGraphicElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a graphic element

CALLED BY:	INTERNAL
PASS:		*ds:si - text object
		dxax - text offset of graphic
		ss:di - buffer for graphic
RETURN:		buffer filled 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGraphicElement		proc	near
		uses	ax, bx, cx, dx, bp
		.enter
EC <		call	AssertIsCText				>	
		sub	sp, size VisTextGetGraphicAtPositionParams
		mov	bp, sp
		movdw	ss:[bp].VTGGAPP_position, dxax
		mov	ax, ss
		mov	ss:[bp].VTGGAPP_retPtr.high, ax
		mov	ss:[bp].VTGGAPP_retPtr.low, di
		mov	ax, MSG_VIS_TEXT_GET_GRAPHIC_AT_POSITION
		call	ObjCallInstanceNoLock
		add	sp, size VisTextGetGraphicAtPositionParams	
		.leave
		ret
GetGraphicElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGraphicRunCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that returns the graphic run token if
		the enumerated graphic run array element contains the 
		passed text offset

CALLED BY:	GetGraphicIfThereIsOne
PASS:		ds:di - graphic run array element 
		cx:dx - text offset we are looking for
RETURN:		carry set if there is a graphic run at the passed position
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGraphicRunCallback	proc	far
	.enter

		cmp	ds:[di].TRAE_token, -1
		je	done

		cmp	cl, ds:[di].TRAE_position.WAAH_high
		jne	done

		cmp	dx, ds:[di].TRAE_position.WAAH_low
		stc
		je	exit

done:
		clc			; make sure enumerate all elements
exit:
		.leave
		ret
FindGraphicRunCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MHSCallSuper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:		

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentText
		ax - message
		cx, dx, bp - data
RETURN:		ax, cx, dx, bp
DESTROYED:	di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MHSCallSuper		proc	near
EC <		call	AssertIsCText				>	
		mov	di, segment ContentTextClass
		mov	es, di
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock		
		ret
MHSCallSuper		endp

BookFileCode	ends
