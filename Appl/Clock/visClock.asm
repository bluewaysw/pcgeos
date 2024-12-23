COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		visClock.asm

AUTHOR:		Adam de Boor, Sep 13, 1991

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/13/91		Initial revision


DESCRIPTION:
	Implementation of the VisClock class for displaying an irregularly-
	shaped, always-on-top window in which a clock is drawn. This class
	is not meant to stand by itself. For example, it does not actually
	field the MSG_VIS_DRAW itself. Rather, it is intended to be subclassed
	to provide the actual desired display. VisClock exists to take care
	of the administrative overhead of creating a clock: opening the
	window under the field, ensuring it remains on top, allowing the user
	to move the clock around, saving its position, when the application
	is shut down, etc.


	$Id: visClock.asm,v 1.1 97/04/04 14:51:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	clock.def

UseLib	Internal/im.def

include input.def
include Internal/grWinInt.def

idata	segment
	VisClockClass		; declare class record.

;
; Field window dimensions, for ease of positioning.
;
fieldWinWidth	sword	0
fieldWinHeight	sword	0

idata	ends

CommonCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCAddRemoveToFromGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the application object to add or remove ourselves
		from a GeoWorks notification list.

CALLED BY:	VCAttach, VCDetach
PASS:		ax	= message to send (MSG_META_GCN_LIST_ADD or
			  MSG_META_GCN_LIST_REMOVE)
		cx	= GeoWorksGenAppGCNListType
		*ds:si	= VisClock object
RETURN:		ds	= fixed up
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		Always add or remove the object from the STARTUP_LOAD_OPTIONS
		list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCAddRemoveToFromGCNList proc	near
		class	VisClockClass
		uses	bx, si
		.enter
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, cx
		mov	cx, ds:[LMBH_handle]
		movdw	ss:[bp].GCNLP_optr, cxsi
		GetResourceHandleNS	ClockAppObj, bx
		mov	si, offset ClockAppObj
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		add	sp, size GCNListParams
		.leave
		ret
VCAddRemoveToFromGCNList endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCEnsureColorGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we've got an option tree and color group if
		we've been told we've got an array of colors.

CALLED BY:	VCAttach
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		ds:di	= VisClockInstance
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCEnsureColorGroup proc	near
		class	VisClockClass
		uses	ax, cx, dx, bp
		.enter
		tst	ds:[di].VCI_colorsPtr
		LONG jz	done
	;
	; Have a color array. See if we've got an options tree, as we'll need
	; one to set the colors.
	;
		tst	ds:[di].VCI_optionTree.handle
		jnz	haveOptionTree
	;
	; No option tree yet, so duplicate one.
	;
		push	si
		mov	cx, ds:[LMBH_handle]
		clr	dx		; no parent yet
		mov	bp, mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_COPY_TREE
		GetResourceHandleNS	TemplateOptions, bx
		mov	si, offset TemplateOptions
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	ds:[di].VCI_optionTree.handle, cx
		mov	ds:[di].VCI_optionTree.chunk, dx
		call	ObjMarkDirty

haveOptionTree:
	;
	; We've got an option tree, so see if we've already build ourselves
	; a color group.
	;
		tst	ds:[di].VCI_colorGroup.handle
		LONG jnz done		; yes, so done
	;
	; Not yet. Duplicate the group.
	;
		push	si
		mov	cx, ds:[di].VCI_optionTree.handle
		mov	dx, ds:[di].VCI_optionTree.chunk
		mov	bp, CCO_FIRST or mask CCF_MARK_DIRTY
		GetResourceHandleNS TemplateColorGroup, bx
		mov	si, offset TemplateColorGroup
		mov	ax, MSG_GEN_COPY_TREE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	bx, cx
		mov	si, dx
	;
	; Locate the new OD of the color list so we can keep it up-to-date;
	; it is the second child of the group
	;
		mov	cx, 1		; 2d child, 0-origin
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
EC <		ERROR_C	VIS_CLOCK_COULD_NOT_FIND_COLOR_LIST		>
		mov	bp, si		; ^lbx:bp <- group, ^lcx:dx <- list
		pop	si
	;
	; Save the two optrs away in our instance data.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	ds:[di].VCI_colorGroup.handle, bx
		mov	ds:[di].VCI_colorGroup.chunk, bp
		mov	ds:[di].VCI_colorList.handle, cx
		mov	ds:[di].VCI_colorList.chunk, dx
		call	ObjMarkDirty
	;
	; Now create the children of the list.
	;
		call	VCCreateColorListChildren
	;
	; "Set" our selected part to what we've got already so the color
	; list is set correctly.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	cx, ds:[di].VCI_selectedPart
		mov	ax, MSG_VC_SET_PART
		call	ObjCallInstanceNoLock
	;
	; Dereference ourselves for our caller.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
done:
		.leave
		ret
VCEnsureColorGroup endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCCreateColorListChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the GenItem children for the color list

CALLED BY:	(INTERNAL) VCEnsureColorGroup
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	One GenItem object is created for each clock part string.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCCreateColorListChildren proc	near
		class	VisClockClass
		uses	si
		.enter
		push	ds:[di].VCI_selectedPart,
			ds:[di].VCI_numParts,
			ds:[di].VCI_firstPartString
		mov	si, bp
		clr	cx		; 1st child, 0-origin
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx	; ^lbx:si <- GenItemGroup
		pop	cx, dx		; cx <- # parts, dx <- first string
		segmov	es, <segment GenItemClass>, di
		clr	bp		; bp <- identifier
childLoop:
	;
	; Create the GenItem child.
	;
		mov	di, offset GenItemClass
		push	si		; save item group chunk
		call	ObjInstantiate	; ^lbx:si <- GenItem
		pop	ax
		push	cx, dx, ax, bp
	;
	; Create the moniker for the child from the string optr we have (*ds:dx)
	;
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	ax, ds:[LMBH_handle]
		movdw	ss:[bp].RVMF_source, axdx
		mov	ss:[bp].RVMF_sourceType, VMST_OPTR
		mov	ss:[bp].RVMF_dataType, VMDT_TEXT
		clr	ax
		mov	ss:[bp].RVMF_length, ax	; null-terminated
		mov	ss:[bp].RVMF_width, ax	; you figure the width...
		mov	ss:[bp].RVMF_height, ax	; ...and the height, please
		mov	ss:[bp].RVMF_updateMode, VUM_MANUAL	; not usable,
								;  so no update
		mov	dx, size ReplaceVisMonikerFrame
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		add	sp, size ReplaceVisMonikerFrame
	;
	; Moniker created. Set the identifier for the new item so we can
	; distinguish things.
	;
		pop	cx			; cx <- identifier
		mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage		; (doesn't destroy cx, because
						;  don't use MF_CALL)
	;
	; Add the item as the last child of the item group.
	;
		mov	bp, cx			; bp <- identifier (while we get
						;  the item group off the stack)
		movdw	cxdx, bxsi		; ^lcx:dx <- child
		pop	si			; ^lbx:si <- item group
		push	bp			; save identifier again
		mov	bp, CCO_LAST
		mov	ax, MSG_GEN_ADD_CHILD
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set the item usable, finally.
	;
		push	si
		mov	si, dx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Now advance to the next string/identifier and loop if more to create.
	;
		pop	cx, dx, bp
		inc	bp
		inc	dx
		inc	dx
		loop	childLoop
	;
	; Set the selected part as the selected thing in the list.
	;
		pop	cx
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
VCCreateColorListChildren endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the clock to the field object.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCAttach	method dynamic VisClockClass, MSG_META_ATTACH
		.enter
	;
	; Make sure we've got a color list and option tree if we've got
	; an array of colors.
	;
		call	VCEnsureColorGroup
	;
	; Get the current fixed position & interval from the application.
	;
		mov	ax, MSG_CAPP_GET_INITIAL_INFO
		call	GenCallApplication
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	ds:[di].VCI_fixedPosition.P_x, cx
		mov	ds:[di].VCI_fixedPosition.P_y, dx
		mov	{word}ds:[di].VCI_horizJust, bp

		mov	cx, 60
		mul	cx		; convert from seconds to ticks
		mov	ds:[di].VCI_interval, ax

	;
	; Find the field on which the application is located.
	;
		mov	cx, GUQT_FIELD
		mov	ax, MSG_GEN_GUP_QUERY
		call	UserCallApplication
	;
	; Make the clock a visible child of the application.
	;
		mov	dx, si
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_VIS_ADD_CHILD
		mov	bp, CCO_FIRST		; (don't mark dirty if comp is
						;  generic object, else death
						;  results...)
		call	UserCallApplication
	;
	; If we've got an option tree, tell the application object where it is
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		movdw	cxdx, ds:[di].VCI_optionTree
		jcxz	makeVisible

		mov	ax, MSG_CAPP_ADD_OPTIONS
		call	UserCallApplication

makeVisible:
	;
	; Force-queue a message to ourselves to load options, since the app
	; won't send us one (we're not on any list...)
	;
		mov	ax, MSG_META_LOAD_OPTIONS
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Bring ourselves up onto the screen.
	;
		mov	ax, MSG_VIS_SET_ATTRS
		mov	cx, mask VA_VISIBLE
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock
	;
	; Invalidate our geometry so we recalculate. We delay the update
	; via the UI queue just to be safe...
	;
		mov	cl, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	VisClockMarkInvalid

		.leave
		ret
VCAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach ourselves from the field and our options from the
		options dialog box.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= VisClock object
		cx	= ack ID
		dx:bp	= ack OD
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCDetach	method dynamic VisClockClass, MSG_META_DETACH
		.enter
	;
	; Set up to complete detach when WIN_DEAD message is received.
	;
		call	ObjInitDetach

; 11/29/92: WIN_DEAD no longer exists, so let's see if the in-use count problems
; we had before exist in 2.0
;		call	ObjIncDetach

	;
	; Set ourselves not visible. VIS_REMOVE just clears VA_REALIZED, not
	; VA_VISIBLE, so if a delayed update is queued, it will try and
	; realize the object again, which will fail, since there will be no
	; parent.
	;
		mov	ax, MSG_VIS_SET_ATTRS
		mov	cx, mask VA_VISIBLE shl 8
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Close and remove ourselves from the application.
	;
		mov	ax, MSG_VIS_REMOVE
		call	ObjCallInstanceNoLock
	;
	; If we've got options, detach them as well.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	bx, ds:[di].VCI_optionTree.handle
		tst	bx
		jz	optionsDetached

		push	si
		mov	si, ds:[di].VCI_optionTree.chunk
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_GEN_FIND_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		xchg	cx, bx
		xchg	dx, si
		mov	ax, MSG_GEN_REMOVE_CHILD
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Reset the geometry of our former parent.
	;
		push	bx, si
		mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bx, segment VisClass
		mov	si, offset VisClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	bx, si

		mov	cx, di		; cx <- recorded message
		mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	si
optionsDetached:
	;
	; Now deal with a timer event that might be in the queue by queueing
	; a MSG_META_ACK to ourselves.
	;
		call	ObjIncDetach
		mov	ax, MSG_META_ACK
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

	;
	; Finally, allow detach to complete
	;
		call	ObjEnableDetach
		.leave
		ret
VCDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect ourselves from the field etc. This is like
		detach, except we know we won't be the current clock, so
		we take ourselves off the OptAdmin and active lists

CALLED BY:	MSG_VC_DISCONNECT
PASS:		*ds:si	= VisClock object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCDisconnect	method dynamic VisClockClass, MSG_VC_DISCONNECT
		.enter
	;
	; Tell the app object to take us off its list.
	;
		mov	ax, MSG_META_GCN_LIST_REMOVE
		mov	cx, GAGCNLT_SELF_LOAD_OPTIONS
		call	VCAddRemoveToFromGCNList
	;
	; Tell the application to remove us from the active list.
	;
		mov	ax, MSG_META_GCN_LIST_REMOVE
		mov	cx, MGCNLT_ACTIVE_LIST
		call	VCAddRemoveToFromGCNList
	;
	; Now detach ourselves normally.
	;
		clr	cx
		mov	dx, cx
		mov	bp, cx
		mov	ax, MSG_META_DETACH
		call	ObjCallInstanceNoLock
		.leave
		ret
VCDisconnect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle preliminaries for coming up on the screen

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCVisOpen	method dynamic VisClockClass, MSG_VIS_OPEN
		.enter
	;
	; Let our superclass do its thing, first.
	;
		mov	di, offset VisClockClass
		CallSuper	MSG_VIS_OPEN
	;
	; Add ourselves to the App object's list of people to notify.
	;
		mov	ax, MSG_META_GCN_LIST_ADD
		mov	cx, GAGCNLT_SELF_LOAD_OPTIONS
		call	VCAddRemoveToFromGCNList
	;
	; Make sure we're on the active list.
	;
		mov	ax, MSG_META_GCN_LIST_ADD
		mov	cx, MGCNLT_ACTIVE_LIST
		call	VCAddRemoveToFromGCNList
	;
	; Hook into the general-change notification list so we force an update
	; when someone else changes the time.
	;
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListAdd
	;
	; Now start the timer off
	;
		call	VCStartTimer
		.leave
		ret
VCVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCFixUpPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our visible bounds are proper for the fixed
		position and justification we've got stored.

CALLED BY:	VCOpenWin, VCMoveResizeWin
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		es	= dgroup
		es:[fieldWinHeight], es:[fieldWinWidth] set
RETURN:		object with visual bounds adjusted properly
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCFixUpPosition	proc	near
		class	VisClockClass
		uses	cx, dx, bx
		.enter
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset

	;
	; Constrain the fixed position to be on-screen.
	;
		mov	cx, ds:[di].VCI_fixedPosition.P_x
		mov	dx, ds:[di].VCI_fixedPosition.P_y
		cmp	cx, es:[fieldWinWidth]
		jl	checkXOffLeft
		mov	cx, es:[fieldWinWidth]
checkXOffLeft:
		cmp	cx, 0
		jge	fixedXOK
		clr	cx
fixedXOK:
		cmp	dx, es:[fieldWinHeight]
		jl	checkYOffTop
		mov	dx, es:[fieldWinHeight]
checkYOffTop:
		cmp	dx, 0
		jge	fixedYOK
		clr	dx
fixedYOK:
	;
	; Now deal with the horizontal, setting the R_left or R_right
	; bound to match the constrained fixed point and adjusting the
	; other appropriately.
	;
		mov	al, ds:[di].VCI_horizJust
		cmp	al, J_RIGHT
		je	rightHoriz
		cmp	al, J_CENTER
		je	centerHoriz
		mov	ax, cx
		xchg	ds:[bx].VI_bounds.R_left, cx
		sub	cx, ax
		sub	ds:[bx].VI_bounds.R_right, cx
		jmp	doVert
centerHoriz:
		mov	ax, ds:[bx].VI_bounds.R_right
		sub	ax, ds:[bx].VI_bounds.R_left
		shr	ax
		pushf
		sub	cx, ax
		mov	ds:[bx].VI_bounds.R_left, cx
		popf
		rcl	ax
		add	cx, ax
		mov	ds:[bx].VI_bounds.R_right, cx
		jmp	doVert
rightHoriz:
		mov	ax, cx
		xchg	ds:[bx].VI_bounds.R_right, cx
		sub	cx, ax
		sub	ds:[bx].VI_bounds.R_left, cx
doVert:
	;
	; Now deal with the vertical, setting the R_top or R_bottom
	; bound to match the constrained fixed point and adjusting the
	; other appropriately.
	;
		mov	al, ds:[di].VCI_vertJust
		cmp	al, J_BOTTOM
		je	bottomVert
		cmp	al, J_CENTER
		je	centerVert
		mov	ax, dx
		xchg	ds:[bx].VI_bounds.R_top, dx
		sub	dx, ax
		sub	ds:[bx].VI_bounds.R_bottom, dx
		jmp	done
centerVert:
		mov	ax, ds:[bx].VI_bounds.R_bottom
		sub	ax, ds:[bx].VI_bounds.R_top
		shr	ax
		pushf
		sub	dx, ax
		mov	ds:[bx].VI_bounds.R_top, dx
		popf
		rcl	ax
		add	dx, ax
		mov	ds:[bx].VI_bounds.R_bottom, dx
		jmp	done
bottomVert:
		mov	ax, dx
		xchg	ds:[bx].VI_bounds.R_bottom, dx
		sub	dx, ax
		sub	ds:[bx].VI_bounds.R_top, dx
done:
		.leave
		ret
VCFixUpPosition endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCOpenWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the window for the object

CALLED BY:	MSG_VIS_OPEN_WIN
PASS:		*ds:si	= object to open
		bp	= parent window handle
RETURN:		bp	= handle of opened window.
		VCI_window set to window handle
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCOpenWin	method dynamic VisClockClass, MSG_VIS_OPEN_WIN
		.enter
EC <		tst	bp						>
EC <		ERROR_Z	VC_FIELD_WINDOW_NOT_PASSED			>

	;
	; Figure the dimensions of our parent window, so we can handle
	; positioning the window more easily.
	;
		push	di
		mov	di, bp
		call	WinGetWinScreenBounds
		sub	cx, ax
		inc	cx
		mov	es:[fieldWinWidth], cx
		sub	dx, bx
		inc	dx
		mov	es:[fieldWinHeight], dx
		pop	di
	;
	; Now make sure our bounds are appropriate to the fixed position and
	; justification we've got.
	;
		call	VCFixUpPosition

		push	si		; save object chunk

	;
	; Set up stack parameters for WinOpen.
	;
		clr	ax
		push	ax		; layer ID (not used)

		call	GeodeGetProcessHandle
		push	bx		; owner for window (our app, not ui)
		push	bp		; parent window

	;
	; set ax:bx to region pointer. ax already 0 from pushing of layer ID.
	;
		mov	bx, ds:[di].VCI_region
		tst	bx
		jz	pushRegionAddr
		mov	bx, ds:[bx]
		mov	ax, ds
pushRegionAddr:
		push	ax
		push	bx
	;
	; Fetch the parameters for the region/corners of the window to open.
	;
		mov	ax, MSG_VC_GET_REGION_PARAMS
		call	ObjCallInstanceNoLock
		push	dx
		push	cx
		push	bp
		push	ax
	;
	; Set up the register parameters for WinOpen.
	;
		mov	ax, MSG_VC_GET_WINDOW_COLOR
		call	ObjCallInstanceNoLock
		mov	bx, dx		; bx = color info

		mov	cx, ds:[LMBH_handle]
		mov	dx, si		; ^lcx:dx <- input OD (us)
		mov	di, cx
		mov	bp, dx		; ^ldi:bp <- expose OD (us)
		mov	si, WinPriorityData <
				LAYER_PRIO_ON_TOP,
				WIN_PRIO_ON_TOP
		>			; si <- WinPassFlags, only WPF_PRIORITY
					;  needs to be set for this window...
		call	WinOpen

	;
	; Store the window in our instance data.
	;
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ds:[di].VCI_window, bx
		.leave
		ret
VCOpenWin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCGetWindowColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the color for the window that's about to be opened.

CALLED BY:	MSG_VC_GET_WINDOW_COLOR
PASS:		*ds:si	= VisClock object
RETURN:		ah	= WinColorFlags
		al	= color index or red value, if using RGB
		dl	= green value, if using RGB
		dh	= blue value, if using RGB
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCGetWindowColor method dynamic VisClockClass, MSG_VC_GET_WINDOW_COLOR
		.enter
		mov	ax, (WinColorFlags <
			0,		; WCF_RGB: using color index
			0,		; WCF_TRANSPARENT: window has background color
			0,		; WCF_PLAIN: window requires exposes
			0,		; WCF_MASKED
			0,		; WCF_DRAW_MASK
			ColorMapMode <	; WCF_MAP_MODE
				1,		; CMM_ON_BLACK: black is our
						;  background color, always.
				CMT_CLOSEST	; CM_MAP_TYPE: map to
						;  solid, never pattern or
						;  dither, please.
			>
		> shl 8) or C_BLACK
		.leave
		ret
VCGetWindowColor endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCMoveResizeWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the window according to the region bound to the object
		and its new vis bounds

CALLED BY:	MSG_VIS_MOVE_RESIZE_WIN
PASS:		*ds:si	= VisClock object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCMoveResizeWin	method dynamic VisClockClass, MSG_VIS_MOVE_RESIZE_WIN
		.enter
	;
	; Ensure justification is obeyed here. We need to do this to deal
	; with resizing of the window. The END_SELECT handler will set things
	; up so the user's desired position is properly obeyed...
	;
		call	VCFixUpPosition
	;
	; Push flag indicating move/resize is absolute
	;
		mov	ax, mask WPF_ABS
		push	ax
	;
	; Push the window & region handles for later...
	;
		add	bx, ds:[bx].Vis_offset
		push	ds:[bx].VCI_window
		push	ds:[di].VCI_region

		mov	ax, MSG_VC_GET_REGION_PARAMS
		call	ObjCallInstanceNoLock
		mov	bx, bp		; bx <- top

		pop	si		; si <- region handle
		pop	di		; di <- window handle

	;
	; See if actual region being used and dereference it if so.
	;
		clr	bp		; assume rectangular
		tst	si
		jz	doResize

		mov	si, ds:[si]
		mov	bp, ds
doResize:
		call	WinResize

		.leave
		ret
VCMoveResizeWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCGetRegionParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for this message: just return our vis bounds

CALLED BY:	MSG_VC_GET_REGION_PARAMS
PASS:		*ds:si	= VisClock object
RETURN:		ax	= left
		bp	= top
		cx	= right
		dx	= bottom
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCGetRegionParams method dynamic VisClockClass, MSG_VC_GET_REGION_PARAMS
		.enter
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		.leave
		ret
VCGetRegionParams endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the interval at which VC_CLOCK_TICK messages arrive.

CALLED BY:	MSG_VC_SET_INTERVAL
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		cx	= seconds between VC_CLOCK_TICK messages
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCSetInterval	method dynamic VisClockClass, MSG_VC_SET_INTERVAL
		.enter
	;
	; Stop any existing timer.
	;
		call	VCStopTimer
	;
	; Convert seconds to ticks
	;
		mov	ax, 60
		mul	cx
	;
	; Store the interval away.
	;
		mov	ds:[di].VCI_interval, ax
		call	ObjMarkDirty

	;
	; Start the timer if we've been realized.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		test	ds:[di].VI_attrs, mask VA_REALIZED
		jz	done

		call	VCStartTimer
done:
		.leave
		ret
VCSetInterval	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the timer for the passed VisClock object

CALLED BY:	VCSetInterval, VCVisOpen
PASS:		*ds:si	= VisClock object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCStartTimer	proc	far
		class	VisClockClass
		.enter
	;
	; Start a continual event timer to send us a MSG_VC_CLOCK_TICK
	; message at the prescribed interval.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	cx, ds:[di].VCI_interval
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:[LMBH_handle]
		mov	dx, MSG_VC_CLOCK_TICK
		mov	di, cx
		call	TimerStart
	;
	; Store the handle and ID away in our instance data.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	ds:[di].VCI_timerID, ax
		mov	ds:[di].VCI_timer, bx
		.leave
		ret
VCStartTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer currently active for the clock.

CALLED BY:	VCSetInterval, VCVisClose
PASS:		*ds:si	= VisClock object
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCStopTimer	proc	near
		class	VisClockClass
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset

		clr	bx
		xchg	bx, ds:[di].VCI_timer
		mov	ax, ds:[di].VCI_timerID
		tst	bx
		jz	done
		call	TimerStop
done:
		.leave
		ret
VCStopTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut off the interval timer we use for updates.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		need to save current position.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCVisClose	method dynamic VisClockClass, MSG_VIS_CLOSE
		.enter
	;
	; Stop any timer first
	;
		call	VCStopTimer
	;
	; Remove ourselves from the general-change notification list.
	;
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListRemove
	;
	; Then give our superclass a shot at the message.
	;
		mov	ax, MSG_VIS_CLOSE
		mov	di, offset VisClockClass
		CallSuper	MSG_VIS_CLOSE
		.leave
		ret
VCVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCClockTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the display of the clock now an interval has expired

CALLED BY:	MSG_VC_CLOCK_TICK
PASS:		*ds:si	= object
		ds:bx	= VisClockBase
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCClockTick	method dynamic VisClockClass, MSG_VC_CLOCK_TICK
		.enter
	;
	; Create a gstate for drawing the beast.
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock

		tst	bp		; any come back?
		jz	done		; no => don't draw
	;
	; Call MSG_VIS_DRAW on ourselves...
	;
		clr	cl		; XXX: what about DF_DISPLAY_TYPE?
					;  doesn't seem to be set on
					;  MSG_META_EXPOSED, so...

		mov	ax, MSG_VIS_DRAW
		push	bp
		call	ObjCallInstanceNoLock
	;
	; Nuke the gstate.
	;
		pop	di
		call	GrDestroyState
done:
		.leave
		ret
VCClockTick	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCNotifyDateTimeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notification of a change in the system clock

CALLED BY:	MSG_NOTIFY_DATE_TIME_CHANGE
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCNotifyDateTimeChange method dynamic VisClockClass, MSG_NOTIFY_DATE_TIME_CHANGE
		.enter
	;
	; Pretend the timer just fired and update the display.
	;
		mov	ax, MSG_VC_CLOCK_TICK
		call	ObjCallInstanceNoLock

		.leave
		ret
VCNotifyDateTimeChange endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the mouse when the user clicks in our window.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= object
		cx	= ptr X position
		dx	= ptr Y position
		bp.low	= ButtonInfo
		bp.high	= UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCStartSelect	method dynamic VisClockClass, MSG_META_START_SELECT,
						MSG_META_START_MOVE_COPY
		.enter
	;
	; Mark the clock as not being moved (since a start must always come
	; before a drag and it's only a drag of the SELECT button that causes
	; us to start moving the clock) and grab the mouse. We don't much care
	; for pointer events, so leave it in the default state of not sending
	; them...
	;
		andnf	ds:[di].VCI_flags, not mask VCF_MOVING
		mov	ds:[di].VCI_clickPoint.P_x, cx
		mov	ds:[di].VCI_clickPoint.P_y, dx

		call	VisGrabMouse

		mov	ax, mask MRF_PROCESSED
		.leave
		ret
VCStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If didn't start moving, be sure our primary is around and
		at the top of the heap, as the user might have clicked on us
		to unbanish the beast.

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		cx	= ptr X position
		dx	= ptr Y position
		bp.low	= ButtonInfo
		bp.high = UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCEndSelect	method dynamic VisClockClass, MSG_META_END_SELECT,
						MSG_META_END_MOVE_COPY
		.enter
		test	ds:[di].VCI_flags, mask VCF_MOVING
		jnz	endMove

	;
	; Bring our application to the top, in case it wasn't there before.
	; This will also bring the primary up if it's been banished.
	; YYY: STILL TRUE?
	;
		mov	ax, MSG_META_NOTIFY_TASK_SELECTED
		call	GenCallApplication

done:
		call	VisReleaseMouse

		mov	ax, mask MRF_PROCESSED
		.leave
		ret

endMove:
	;
	; Flag no longer moving.
	;
		andnf	ds:[di].VCI_flags, not mask VCF_MOVING

	;
	; Call the IM to stop the xor.
	;
		push	cx, dx, di
		call	ImStopMoveResize	; XXX: returns (left,top) in
						; (cx,dx)... perhaps we should
						; use it? queue delays...
	;
	; Free the region block, now we know the thing isn't being used by the
	; video driver.
	;
		clr	bx
		xchg	bx, ds:[di].VCI_regionCopy
		tst	bx
		jz	xorStopped
		call	MemFree
xorStopped:
		pop	cx, dx, di
	;
	; Figure difference from start to now.
	;
		sub	cx, ds:[di].VCI_clickPoint.P_x
		sub	dx, ds:[di].VCI_clickPoint.P_y
	;
	; Add current (left,top) to that.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset
		add	cx, ds:[bx].VI_bounds.R_left
		add	dx, ds:[bx].VI_bounds.R_top
	;
	; Move there, bub.
	;
		mov	ax, MSG_VIS_POSITION_BRANCH
		call	ObjCallInstanceNoLock
	;
	; Now figure appropriate justification and fixed position.
	;
		mov	bx, ds:[si]
		mov	di, bx
		add	bx, ds:[bx].Vis_offset
		add	di, ds:[di].VisClock_offset

	;
	; If horizontal is more than 1/2 screen distance, set right
	; justification
	;
		mov	ax, es:[fieldWinWidth]
		shr	ax
		cmp	ds:[bx].VI_bounds.R_right, ax
		jg	rightJustify
		mov	ax, ds:[bx].VI_bounds.R_left
		mov	ds:[di].VCI_horizJust, J_LEFT
		jmp	setFixedX
rightJustify:
		mov	ax, ds:[bx].VI_bounds.R_right
		mov	ds:[di].VCI_horizJust, J_RIGHT
setFixedX:
		mov	ds:[di].VCI_fixedPosition.P_x, ax
	;
	; Ditto for the vertical.
	;
		mov	ax, es:[fieldWinHeight]
		shr	ax
		cmp	ds:[bx].VI_bounds.R_bottom, ax
		jg	bottomJustify
		mov	ax, ds:[bx].VI_bounds.R_top
		mov	ds:[di].VCI_vertJust, J_TOP
		jmp	setFixedY
bottomJustify:
		mov	ax, ds:[bx].VI_bounds.R_bottom
		mov	ds:[di].VCI_vertJust, J_BOTTOM
setFixedY:
		mov	ds:[di].VCI_fixedPosition.P_y, ax
	;
	; Mark ourselves dirty so the new position goes to state.
	;
		call	ObjMarkDirty
	;
	; Notify the application of our status.
	;
		mov	cx, ds:[di].VCI_fixedPosition.P_x
		mov	dx, ax
		mov	bp, {word}ds:[di].VCI_horizJust
		mov	ax, MSG_CAPP_UPDATE_FIXED_POSITION
		call	GenCallApplication
	;
	; Geez. You'd think MSG_VIS_SET_POSITION would move the window, wouldn't you?
	;
		mov	ax, MSG_VIS_MOVE_RESIZE_WIN
		call	ObjCallInstanceNoLock

		jmp	done
VCEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start moving this clock around on the screen.

CALLED BY:	MSG_META_DRAG_SELECT
PASS:		*ds:si	= VisClock object
		cx	= ptr X position (window coords)
		dx	= ptr Y position (window coords)
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCDragSelect	method dynamic VisClockClass, MSG_META_DRAG_SELECT,
						MSG_META_DRAG_MOVE_COPY
		.enter
	;
	; Set flag to indicate move in progress.
	;
		ornf	ds:[di].VCI_flags, mask VCF_MOVING
	;
	; Pass ptr position to ImStartMoveResize.
	;
		push	ds:[di].VCI_clickPoint.P_x,
			ds:[di].VCI_clickPoint.P_y
	;
	; Duplicate the region, since it might move and ImStartMoveResize needs
	; ^hbx:ax...
	;
		mov	bx, ds:[di].VCI_region
		mov	ax, bx		; assume no region
		tst	bx
		LONG jz	allocRectRegion

		ChunkSizeHandle	ds, bx, ax	; ax <- # bytes to alloc
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		push	ax
		add	ax, size Rectangle	; make room for bounds @ front
		call	MemAlloc
		mov	ds:[di].VCI_regionCopy, bx
		pop	cx
		mov	es, ax
		push	si
		mov	si, ds:[di].VCI_region
		mov	si, ds:[si]
		mov	di, size Rectangle	; region data goes after bounds
		rep	movsb
		pop	si
	;
	; Set bounding box of region.
	;
		mov	es:[R_left], cx
		mov	es:[R_top], cx
		call	VisGetSize
		dec	cx
		mov	es:[R_right], cx
		dec	dx
		mov	es:[R_bottom], dx
	;
	; Unlock the region block.
	;
haveRegion:
		call	MemUnlock
		clr	ax		; region @ offset 0 in block
		push	bx, ax		; push region
	;
	; Get region parameters.
	;
		mov	ax, MSG_VC_GET_REGION_PARAMS
		push	bp
		call	ObjCallInstanceNoLock
		mov	bx, bp		; bx <- top
	;
	; Adjust them to be window-relative. Do not use vis bounds, as those
	; could well not correspond to the origin of the window, if the region
	; we gave WinResize had a non-zero left- or top-edge minimum.
	;
		call	VisQueryWindow	; di <- window handle
		push	ax, bx, cx, dx
		call	WinGetWinScreenBounds
		mov	di, ax		; di <- left edge
		mov	bp, bx		; bp <- top edge
		pop	ax, bx, cx, dx

		sub	ax, di
		sub	bx, bp
		sub	cx, di
		sub	dx, bp
		pop	bp

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
	;
	; Get the window and set the action that ends the move.
	;
		mov	di, ds:[di].VCI_window
		mov	si, mask XF_END_MATCH_ACTION
		andnf	bp, mask BI_BUTTON
	;
	; Finally...start the move.
	;
		call	ImStartMoveResize

		mov	ax, mask MRF_PROCESSED
		.leave
		ret

allocRectRegion:
	;
	; Input manager is hosed as far as rubber-banding a rectangle is
	; concerned, so allocate a rectangular region + bounding box
	; ourselves.
	;
		mov	ax, size RectRegion + size Rectangle
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	es, ax
		mov	es:[R_left], PARAM_0
		mov	es:[R_top], PARAM_1
		mov	es:[R_right], PARAM_2
		mov	es:[R_bottom], PARAM_3
		mov	es:[size Rectangle].RR_y1M1, PARAM_1-1
		mov	es:[size Rectangle].RR_eo1, EOREGREC
		mov	es:[size Rectangle].RR_y2, PARAM_3
		mov	es:[size Rectangle].RR_x1, PARAM_0
		mov	es:[size Rectangle].RR_x2, PARAM_2
		mov	es:[size Rectangle].RR_eo2, EOREGREC
		mov	es:[size Rectangle].RR_eo3, EOREGREC
		jmp	haveRegion
VCDragSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCSetFixedPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position of the clock to be fixed at a particular
		location on the screen.

CALLED BY:	MSG_VC_SET_FIXED_POSITION
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		ds:bx	= VisClockBase
		cx	= fixed X position
		dx	= fixed Y position
		bp.low	= horizontal justification
		bp.high	= vertical justification
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCSetFixedPosition method dynamic VisClockClass, MSG_VC_SET_FIXED_POSITION
		.enter
	;
	; Set the new position and justification.
	;
		mov	ds:[di].VCI_fixedPosition.P_x, cx
		mov	ds:[di].VCI_fixedPosition.P_y, dx
		CheckHack <offset VCI_vertJust eq offset VCI_horizJust+1>
		mov	{word}ds:[di].VCI_horizJust, bp
	;
	; Mark ourselves dirty so the new position gets saved to state.
	;
		call	ObjMarkDirty
	;
	; And tell ourselves to move it there, if we're realized...
	;
		add	bx, ds:[bx].Vis_offset
		test	ds:[bx].VI_attrs, mask VA_REALIZED
		jz	done

		mov	ax, MSG_VIS_MOVE_RESIZE_WIN
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
VCSetFixedPosition endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save all our options to the ini file

CALLED BY:	MSG_META_SAVE_OPTIONS
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
colorsString	char	'colors', 0

VCSaveOptions	method dynamic VisClockClass, MSG_META_SAVE_OPTIONS
		uses	si, es
		.enter
	;
	; If no category defined, can't save things.
	;
		mov	si, ds:[di].VCI_category
		tst	si
		jz	done
	;
	; If no color array defined, can't save things.
	;
		tst	ds:[di].VCI_colorsPtr
		jz	done

		mov	si, ds:[si]
		mov	cx, cs
		mov	dx, offset colorsString
		segmov	es, ds
		mov	bp, ds:[di].VCI_numParts
			CheckHack <size ColorQuad eq 4>
		shl	bp
		shl	bp
		add	di, ds:[di].VCI_colorsPtr
		call	InitFileWriteData

done:
		.leave
		ret
VCSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCRestoreOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our options from the .ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCRestoreOptions method dynamic VisClockClass, MSG_META_LOAD_OPTIONS
		uses	es
		.enter
	;
	; If restoring from state or have no category bound, just update
	; with current values (specifically the color selector -- controllers
	; depend on notification, so no state is saved for them)
	;
		test	ds:[di].VCI_flags, mask VCF_RESTORED
		jnz	updateOnly

		mov	bx, ds:[di].VCI_category
		tst	bx
		jz	updateOnly
	;
	; If no color array defined, then nothing to restore.
	;
		tst	ds:[di].VCI_colorsPtr
		jz	checkOptionTree
	;
	; Else fetch our color table from the ini file, if it's there.
	;
		push	si
		mov	si, ds:[bx]
		mov	cx, cs
		mov	dx, offset colorsString
		mov	bp, ds:[di].VCI_numParts
			CheckHack <size ColorQuad eq 4>
		shl	bp
		shl	bp
		add	di, ds:[di].VCI_colorsPtr
		segmov	es, ds
		call	InitFileReadData
		pop	si
		jc	update		; => not there, just update

	;
	; Mark our image invalid so we get redrawn with the new color set.
	;
		mov	cx, mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	VisClockMarkInvalid
update:
	;
	; "Set" our selected part to what we've got already so the color
	; list is set correctly.
	;
		call	updateColor
checkOptionTree:
	;
	; Propagate LOAD_OPTIONS to option tree, if we've got one.
	;
		tst	ds:[di].VCI_optionTree.handle
		jz	done
		movdw	bxsi, ds:[di].VCI_optionTree
		mov	ax, MSG_META_LOAD_OPTIONS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret

updateOnly:
		andnf	ds:[di].VCI_flags, not mask VCF_RESTORED
		call	updateColor
		jmp	short done

updateColor	label	near
		mov	di, ds:[si]
		add	di, ds:[di].VisClock_offset
		mov	cx, ds:[di].VCI_selectedPart
		mov	ax, MSG_VC_SET_PART
		call	ObjCallInstanceNoLock
		retn

VCRestoreOptions endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCSetPart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the part of the clock on which future VC_SET_PART_COLOR
		messages will act.

CALLED BY:	MSG_VC_SET_PART
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		cx	= part on which to operate
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCSetPart	method dynamic VisClockClass, MSG_VC_SET_PART
		.enter
		mov	ds:[di].VCI_selectedPart, cx
EC <		cmp	cx, ds:[di].VCI_numParts			>
EC <		ERROR_AE	VIS_CLOCK_PART_OUT_OF_BOUNDS		>

	;
	; Now set the color list appropriately.
	;
		mov	bx, ds:[di].VCI_colorList.handle
		mov	si, ds:[di].VCI_colorList.chunk
		tst	bx				; built yet?
		jz	colorListSet			; no

		add	di, ds:[di].VCI_colorsPtr	; ds:di <- colors array
			CheckHack <size ColorQuad eq 4>
		shl	cx
		shl	cx
		add	di, cx
		movdw	dxcx, ({dword}ds:[di])
		clr	bp				; not indeterminate
		mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
colorListSet:
		.leave
		ret
VCSetPart	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCSetPartColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color of the currently-selected part of the clock.

CALLED BY:	MSG_VC_SET_PART_COLOR
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		dxcx	= ColorQuad
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCSetPartColor	method dynamic VisClockClass, MSG_META_COLORED_OBJECT_SET_COLOR
		.enter
EC <		tst	ds:[di].VCI_colorsPtr				>
EC <		ERROR_Z	VIS_CLOCK_CANNOT_SET_COLOR_IF_NO_COLOR_ARRAY_DEFINED>
	;
	; Store the color away...
	;
   		mov	bx, ds:[di].VCI_selectedPart
		add	di, ds:[di].VCI_colorsPtr
			CheckHack <size ColorQuad eq 4>
		shl	bx
		shl	bx
		movdw	({dword}ds:[di][bx]), dxcx
	;
	; And mark the whole image invalid, so it all gets redrawn.
	;
		mov	cx, mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	VisClockMarkInvalid
		.leave
		ret
VCSetPartColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VCRelocOrUnReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with going out to state or coming back in

CALLED BY:	MSG_META_RELOCATE/MSG_META_UNRELOCATE
PASS:		*ds:si	= VisClock object
		ds:di	= VisClockInstance
		ax	= MSG_META_RELOCATE/MSG_META_UNRELOCATE
RETURN:		carry set on error
DESTROYED:	anything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VCRelocOrUnReloc method dynamic VisClockClass, reloc
	;
	; If unrelocating, set the VCF_RESTORED flag so we know not to
	; load options when the app is restored from state.
	;
		cmp	ax, MSG_META_RELOCATE
		je	done
		ornf	ds:[di].VCI_flags, mask VCF_RESTORED
done:
		mov	di, offset VisClockClass
		call	ObjRelocOrUnRelocSuper
		ret
VCRelocOrUnReloc endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisClockMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the some part of the clock if it's on-screen

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= VisClock object
		cx	= VisOptFlags
		dl	= VisUpdateMode
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisClockMarkInvalid proc	far
		class	VisClockClass
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		test	ds:[di].VI_attrs, mask VA_VISIBLE
		jz	done

		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	VisMarkInvalid
done:
		.leave
		ret
VisClockMarkInvalid endp

CommonCode	ends
