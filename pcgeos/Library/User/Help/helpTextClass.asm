COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiText.asm

AUTHOR:		Gene Anderson, Oct 27, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/27/92	Initial revision


DESCRIPTION:
	Help objects subclass of the text object

	$Id: helpTextClass.asm,v 1.1 97/04/07 11:47:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;---------------------------------------------------

UserClassStructures	segment resource

	HelpTextClass			;declare the class record

UserClassStructures	ends

;---------------------------------------------------

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTSelectRunAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects the run at the current position.

CALLED BY:	GLOBAL
PASS:		*ds:si - HelpText object
		bx - handle of HelpText object in *ds:si
		dx.ax - position
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTSelectRunAtPosition	proc	near
	.enter

	sub	sp, size VisTextRange
	mov	bp, sp			;SS:BP <- bounds of the run
	call	HTGetBoundsOfNameArrayRun

;	We have a problem here. If passed a position between runs,
;	HTGetBoundsOfNameArrayRun will return the run starting at the
;	position, while HTGetLinkForPos will return the run ending at
;	the passed position. This means, if we click at the end of a run,
;	HTGetLinkForPos will think we've clicked in a run, but 
;	HTGetBoundsOfNameArrayRun will select the *next* run.
;	SO... We check to see if the run is a valid name run. If not,
;	we get the *previous* run instead.

	movdw	dxax, ss:[bp].VTR_start
	movdw	cxdi, ss:[bp].VTR_end
	call	HTGetLinkForPos
	cmp	cx, -1
	jne	10$

	movdw	dxax, ss:[bp].VTR_start
	subdw	dxax, 1
EC <	ERROR_C	SELECTION_DID_NOT_INCLUDE_LINK				>
   	call	HTGetBoundsOfNameArrayRun
10$:

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	add	sp, size VisTextRange
	.leave
	ret
HTSelectRunAtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetBoundsOfNameArrayRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds (text position of start and end) of the 
		link (name array run) that includes the current position

CALLED BY:	GLOBAL
PASS:		dx.ax - position
		*ds:si - HelpTextClass
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
HTGetBoundsOfNameArrayRun	proc	near	uses	ax, cx, dx, bp
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
HTGetBoundsOfNameArrayRun	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpTextStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select in help object's text object

CALLED BY:	MSG_HELP_TEXT_START_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpTextClass
		ax - the message

		(cx,dx) - (x,y) position of mouse
		bp.low - ButtonInfo
		bp.high - UIFumctionsActive

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
HelpTextStartSelect		method dynamic HelpTextClass,
						MSG_META_START_SELECT
	;
	; Get the character nearest to the mouse click
	;
	call	HTGetTextPosFromCoord		;dx:ax <- nearest char	
	call	HTCheckForCRAtCoord
	jnc	checkForLink			; if the char is a CR, we don't select.
	mov	cx, -1		; no link
	jmp	noLink

checkForLink:
	;
	; See if there is any link. Also check for case of double-press on a
	; help link, which is an action that should be ignored because the
	; first press will have activated the link and the second press would
	; accidentally activate a link on the second help page. -Don 10/15/00
	;
	pushdw	dxax
	movdw	cxdi, dxax
	mov	bx, ds:LMBH_handle		;^lbx:si <- OD of text
	call	HTGetLinkForPos			;cx <- token of link name
	popdw	diax				;DIAX <- text position
	test	bp, mask BI_DOUBLE_PRESS	;if double-click, then don't
	jnz	noLink				; follow link to avoid confusion
	cmp	cx, -1				;any link?
	je	noLink				;branch if no link
	;
	; Select the bounds of the link, then unselect it, to provide user
	; feedback.
	;
	pushdw	cxdx
	mov	dx, di			;DX.AX <- position
	call	HTSelectRunAtPosition

	mov	ax, 6			;Sleep for a tenth of a second
	call	TimerSleep

	mov	ax, MSG_VIS_TEXT_SELECT_START
	call	ObjCallInstanceNoLock	;Nuke the selection

	popdw	cxdx
	;
	; Tell the controller a link has been clicked on
	;
	mov	ax, MSG_HELP_CONTROL_FOLLOW_LINK
	call	ObjBlockGetOutput		;^lbx:si <- OD of output
	call	HUObjMessageSend
	;
	; Return that we've processed the event
	;
noLink:
HTSetPointer	label	far
	mov	ax, MSG_HELP_CONTROL_GET_POINTER_IMAGE
	call	ObjBlockGetOutput		;^lbx:si <- OD of controller
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ornf	ax, mask MRF_PROCESSED
	ret
HelpTextStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpTextEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select in help object's text object

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpTextClass
		ax - the message
RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpTextEndSelect		method dynamic HelpTextClass,
						MSG_META_END_SELECT
	mov	cx, -1			;cx <- not over link
	GOTO	HTSetPointer
HelpTextEndSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle pointer event in help object's text object

CALLED BY:	MSG_META_PTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpTextClass
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
HelpTextPtr		method dynamic HelpTextClass,
						MSG_META_PTR
	;
	; Get the character nearest to the mouse click
	;
	call	HTGetTextPosFromCoord		;dx:ax <- nearest char
	call	HTCheckForCRAtCoord
	mov	bx, ds:LMBH_handle		;^lbx:si <- OD of text
	movdw	cxdi, dxax
	jc	noLink				; branch if CR, we don't want to change the cursor

	;
	; See if there is any link
	;	
	call	HTGetLinkForPos			;cx <- token of link

	GOTO	HTSetPointer

noLink:
	mov	cx, -1
	GOTO	HTSetPointer
HelpTextPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTCheckForCRAtCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for a CR at the passed character position.

CALLED BY:	HelpTextPtr, HelpTextStartSelect
PASS:		dx:ax <- character position to check
		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpTextClass
RETURN:		carry set <- character is a CR
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	11/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTCheckForCRAtCoord	proc	near
			class HelpTextClass
crCheck		local		2 dup (TCHAR)
textSize	local		dword
	uses	es, bx, cx, di, dx, ax
	.enter

	;
	; Get the text size for later use
	;
	push	dx, ax
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, offset HelpTextClass
	call	ObjCallSuperNoLock
	movdw	ss:[textSize], dxax
	pop	dx, ax

	;
	; To do this check, of course, we need to get the
	; text at the returned position.
	;
	segmov	es, ss, bx		; es:bx <- crCheck
	lea	bx, ss:[crCheck]
	push	bp
	sub	sp, size VisTextGetTextRangeParameters
	mov	cx, sp
	pushdw	ss:[textSize]
	mov	bp, cx			; ss:bp <- VisTextGetTextRangeParameters stack frame
	movdw	ss:[bp].VTGTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, esbx
	movdw	ss:[bp].VTGTRP_range.VTR_start, dxax

	;
	; We ensure that the end portion of the range is
	; within text bounds.  If it isn't, then we
	; obviously don't want to crash, so we pass
	; TEXT_ADDRESS_PAST_END
	;
	incdw	dxax
	popdw	cxbx		; cx:bx <- text size
	cmpdw	cxbx, dxax
	ja	finSetup
	movdw	dxax, TEXT_ADDRESS_PAST_END
	
finSetup:
	movdw	ss:[bp].VTGTRP_range.VTR_end, dxax
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	clr	ss:[bp].VTGTRP_flags
	mov	ax, segment HelpTextClass
	mov	di, offset HelpTextClass
	mov	es, ax
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	ObjCallSuperNoLock
	add	sp, size VisTextGetTextRangeParameters
	pop	bp

	;
	; OK, check to see if the returned char is a CR
	;
	clc
	cmp	byte ptr ss:[crCheck], C_CR
	jnz	noCR
	stc		; yes, CR

noCR:	
	.leave
	ret
HTCheckForCRAtCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTHelpTextNavigateToNextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Navigates to the next link in the help text.

CALLED BY:	MSG_HELP_TEXT_NAVIGATE_TO_NEXT_FIELD
PASS:		*ds:si	= HelpTextClass object
		ds:di	= HelpTextClass instance data
		ds:bx	= HelpTextClass object (same as *ds:si)
		es 	= segment of HelpTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bp, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Currently only needed to let the HelpControl make sure the
	first link is highlighted.  But maybe it will be useful
	for other things.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	12/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if HIGHLIGHT_LINK_WHEN_OPENED
HTHelpTextNavigateToNextField	method dynamic HelpTextClass, 
					MSG_HELP_TEXT_NAVIGATE_TO_NEXT_FIELD
	call	NavigateToNextField
	ret
HTHelpTextNavigateToNextField	endm

endif ; HIGHLIGHT_LINK_WHEN_OPENED




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateToPrevField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Navigates to the previous field

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateToPrevField	proc	near

	mov	di, -1
	GOTO	HTNavigateToField
NavigateToPrevField	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateToNextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Navigates to the next field

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateToNextField	proc	near

	clr	di
	FALL_THRU	HTNavigateToField
NavigateToNextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTNavigateToField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will navigate to the next field in the help text.

CALLED BY:	GLOBAL
PASS:		*ds:si - HelpText object
		di - non-zero if we are going backwards, otherwise forward

RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateLocals	struct
	NL_curRun	VisTextRange<>
	NL_haveWrapped	byte
	even
NavigateLocals	ends
HTNavigateToField	proc	near
	.enter

;	We allocate space for 2 VisTextRanges - one holds the bounds of the
;	current run, while the other holds the bounds of all the runs we've
;	checked (so we know when we've checked them all)
	
	sub	sp, size NavigateLocals
	mov	bp, sp
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	call	ObjCallInstanceNoLock
	mov	bp, sp
if WRAPPING_LINK_NAVIGATION
	clr	ss:[bp].NL_haveWrapped
else
	mov	ss:[bp].NL_haveWrapped, TRUE
endif

;	Sit in a loop, where we check to see if the current position is in
;	a link. 

next:
	clr	bl
	tst	di
	jz	forward
	movdw	dxax, ss:[bp].NL_curRun.VTR_start
	subdw	dxax, 1
	jnc	common
	mov	bl,  TRUE
	movdw	dxax, (TEXT_ADDRESS_PAST_END-1)
	jmp	common
forward:
	movdw	dxax, ss:[bp].VTR_end
	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	jne	common
	clrdw	dxax
	mov	bl,  TRUE

common:
	tst	bl
	jz	noWrap

;	If we just wrapped from the end to the start, or vice versa, set
;	the flag. If we alread wrapped, then don't wrap again - just exit.
;	There may be some redundant work here - we might test a couple of
;	runs twice, but this is the simplest check, and this only happens
;	if the user tries to navigate when there aren't any links in the text.

	xchg	ss:[bp].NL_haveWrapped, bl
	tst	bl
	jnz	exit
noWrap:

;	Get the bounds of the run that starts at or before the passed
;	position, then check to see what the token for that run is. If it
;	is -1 (null token) then that means that the text area is not a link,
;	so we should go try the next run

	call	HTGetBoundsOfNameArrayRun

	push	di
	mov	bx, ds:[LMBH_handle]
	movdw	dxax, ss:[bp].VTR_start
	movdw	cxdi, ss:[bp].VTR_end
	call	HTGetLinkForPos
	pop	di

	cmp	cx, -1
	jz	next

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
exit:
	add	sp, size NavigateLocals
	.leave
	ret
HTNavigateToField	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTFollowSelectedLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follows the selected link, as if it had been clicked on

CALLED BY:	GLOBAL
PASS:		*ds:si - HelpText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTFollowSelectedLink	proc	near
	.enter
	sub	sp, size VisTextRange
	mov	bp, sp
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	call	ObjCallInstanceNoLock
	mov	bp, sp	
	movdw	dxax, ss:[bp].VTR_start
	movdw	cxdi, ss:[bp].VTR_end
	add	sp, size VisTextRange
	cmpdw	dxax, cxdi		;If nothing selected, exit
	jz	exit
	mov	bx, ds:[LMBH_handle]
	call	HTGetLinkForPos
EC <	cmp	cx, -1							>
EC <	ERROR_Z	SELECTION_DID_NOT_INCLUDE_LINK				>

	;
	; Tell the controller to follow the link
	;
	mov	ax, MSG_HELP_CONTROL_FOLLOW_LINK
	call	ObjBlockGetOutput
	call	HUObjMessageSend
exit:
	.leave
	ret
HTFollowSelectedLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpTextKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles navigation, etc in the help text.

CALLED BY:	GLOBAL
PASS:		cx - char value
		dl - CharFlags
		dh - ShiftState
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpTextKbdChar	method	HelpTextClass, MSG_META_KBD_CHAR

	push	cx, dx, bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock
	tstdw	dxax
	pop	cx, dx, bp
	jz	sendUp

	test	dl, mask CF_RELEASE	;If a release, pass it upwards
	jnz	sendUp

	push	ds, si
	mov	ax, length HelpShortcuts
	segmov	ds, cs
	mov	si, offset HelpShortcuts
	call	FlowCheckKbdShortcut
	mov	di, si
	pop	ds, si
	jnc	sendUp			;Branch if not a shortcut
	call	cs:HelpShortcutRoutines[di]
	ret
sendUp:
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
HelpTextKbdChar	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollViewDown/Up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls the view down/up one line

CALLED BY:	GLOBAL
PASS:		*ds:si - object under a view
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollViewDown	proc	near
	mov	ax, MSG_GEN_VIEW_SCROLL_DOWN
	GOTO	ToView
ScrollViewDown	endp
ScrollViewUp	proc	near
	mov	ax, MSG_GEN_VIEW_SCROLL_UP
	FALL_THRU	ToView
ScrollViewUp	endp

ToView	proc	near
	push	si
	mov	di, mask MF_RECORD
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	call	ObjMessage		;DI <- recorded message
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent
	ret
ToView	endp



if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
HelpShortcuts KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>,	;<Enter>
	<0, 0, 0, 0, C_SPACE and mask KS_CHAR>,		;<space>
	<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;<Tab>
	<0, 0, 1, 1, C_SYS_TAB and mask KS_CHAR>,	;<Shift><Tab>
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;<left arrow>
	<1, 0, 0, 0, C_SYS_JOYSTICK_0 and mask KS_CHAR>,	;<joystick rght>
	<1, 0, 0, 0, C_SYS_JOYSTICK_180 and mask KS_CHAR>,	;<joystick left>
	<1, 0, 0, 0, C_SYS_FIRE_BUTTON_1 and mask KS_CHAR>,	;<fire button 1>
	<1, 0, 0, 0, C_SYS_FIRE_BUTTON_2 and mask KS_CHAR>	;<fire button 2>
else
	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;

HelpShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_ENTER>,		;<Enter>
	<0, 0, 0, 0, 0x0, C_SPACE>,		;<Enter>
	<0, 0, 0, 0, 0xf, VC_TAB>,		;<Tab>
	<0, 0, 0, 1, 0xf, VC_TAB>,		;<Shift><Tab>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_0>,	;<joystick right>
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_180>,	;<joystick left>
	<1, 0, 0, 0, 0xf, VC_FIRE_BUTTON_1>,	;<fire button 1>
	<1, 0, 0, 0, 0xf, VC_FIRE_BUTTON_2>	;<fire button 2>
endif






HelpShortcutRoutines	nptr	\
	HTFollowSelectedLink,
	HTFollowSelectedLink,
	NavigateToNextField,
	NavigateToPrevField,
	ScrollViewDown,
	ScrollViewUp,
	NavigateToNextField,
	NavigateToPrevField,
	NavigateToNextField,
	NavigateToPrevField,
	HTFollowSelectedLink,
	HTFollowSelectedLink
	
.assert	size KeyboardShortcut eq size nptr

.assert length HelpShortcuts eq length HelpShortcutRoutines


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetTextPosFromCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the nearest character to the passed coordinate

CALLED BY:	HelpTextPtr(), HelpTextStartSelect()
PASS:		*ds:si - HelpTextClass object
		(cx,dx) - (x,y) coordinate to check
RETURN:		dx:ax - nearest character offset
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTGetTextPosFromCoord		proc	near
	uses	bp, di
	.enter

	clr	ax
CheckHack <(size PointDWFixed) eq 12>
	push	ax				;pass PDF_y.DWF_int.high
	push	dx				;pass PDF_y.DWF_int.low
	push	ax				;pass PDF_y.DWF_frac
	push	ax				;pass PDF_x.DWF_int.high
	push	cx				;pass PDF_x.DWF_int.low
	push	ax				;pass PDF_x.DWF_frac
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	mov	di, offset HelpTextClass
	call	ObjCallSuperNoLock		;dx:ax <- nearest char offset
	add	sp, (size PointDWFixed)

	.leave
	ret
HTGetTextPosFromCoord		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetLinkForPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the link for the given position

CALLED BY:	HelpTextPtr(), HelpTextStartSelect()
PASS:		^lbx:si - HelpTextClass object
		dx:ax - start of range to check
		cx:di - end of range to check
		ds - any memory block that can be fixed up (ie. ds:[0]
			contains the handle of the block)
RETURN:		cx - token of link name (-1 for none)
		dx - token of link file
		ax - token of context
		ds - fixed up
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

HTGetLinkForPos		proc	near
	uses	bp
	.enter

	sub	sp, (size GetTypeParams)
	mov	bp, sp				;ss:bp <- ptr to params
	movdw	ss:[bp].VTGAP_range.VTR_start, dxax
	movdw	ss:[bp].VTGAP_range.VTR_end, cxdi
	clr	ss:[bp].VTGAP_flags
	mov	ss:[bp].VTGAP_attr.segment, ss
	lea	ax, ss:[bp].GTP_attrs
	mov	ss:[bp].VTGAP_attr.offset, ax
	mov	ss:[bp].VTGAP_return.segment, ss
	lea	ax, ss:[bp].GTP_diffs
	mov	ss:[bp].VTGAP_return.offset, ax
	mov	ax, MSG_VIS_TEXT_GET_TYPE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, ss:[bp].GTP_attrs.VTT_hyperlinkName
	mov	dx, ss:[bp].GTP_attrs.VTT_hyperlinkFile
	mov	ax, ss:[bp].GTP_attrs.VTT_context
	add	sp, (size GetTypeParams)

	.leave
	ret
HTGetLinkForPos		endp

HelpControlCode ends
