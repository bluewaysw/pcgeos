COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinFieldUncommon.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION 
				Look through windows on field, & find top
				app

    INT FieldCreateAppArrayFromWindows 
				Create an array of GenApplication object
				optrs based on the ordering of
				standard-priority windows on the field.

    INT FieldCreateAppArrayFromWindowsCallback 
				Code largely stolen from
				CreateChunkArrayOnWindowsInLayerCallback to
				perform additional work necessary to yield
				an array of application objects.

    MTD MSG_META_GAINED_FOCUS_EXCL 
				Handler for gaining of field exclusive;
				i.e. focus field in system

    MTD MSG_META_LOST_FOCUS_EXCL 
				Handler for when field has lost the target
				exclusive, & must force active app to no
				longer be active as well

    INT OLFieldUpdateFocusCommon 
				Handler for when field has lost the target
				exclusive, & must force active app to no
				longer be active as well

    MTD MSG_META_GAINED_TARGET_EXCL 
				Handler for gaining of field exclusive;
				i.e. focus field in system

    MTD MSG_META_LOST_TARGET_EXCL 
				Handler for when field has lost the target
				exclusive, & must force active app to no
				longer be active as well

    INT OLFieldUpdateTargetCommon 
				Handler for when field has lost the target
				exclusive, & must force active app to no
				longer be active as well

    MTD MSG_META_GAINED_FULL_SCREEN_EXCL 
				Handler for gaining of full screen
				exclusive

    MTD MSG_META_LOST_FULL_SCREEN_EXCL 
				Handler for when field has lost the full
				screen exclusive

    INT OLFieldUpdateFullScreenCommon 
				Handler for when field has lost the full
				screen exclusive

    MTD MSG_META_GET_TARGET_AT_TARGET_LEVEL 
				Returns current target object within this
				branch of the hierarchical target
				exclusive, at level requested

    MTD MSG_META_START_SELECT   Process case of menu button being pressed
				in workspace area.

    MTD MSG_META_START_SELECT   Process case of menu button being pressed
				in workspace area.

    MTD MSG_OL_FIELD_POPUP_EXPRESS_MENU 
				Pop up the workspace menu, at the specified
				location

    MTD MSG_OL_FIELD_TOGGLE_EXPRESS_MENU 
				Open/close field's express menu.

    MTD MSG_OL_FIELD_SELECT_WINDOW_LIST_ENTRY 
				Brings window to front

    MTD MSG_OL_FIELD_WINDOW_LIST_CLOSE_WINDOW 
				Close the window currently selected in the
				window list.

    MTD MSG_GEN_FIELD_OPEN_WINDOW_LIST 
				Bring up the window list dialog

    MTD MSG_OL_FIELD_CLOSE_WINDOW_LIST 
				Close the window list.

    MTD MSG_OL_WIN_CLOSE        Handle specific UI close message releasing
				the target so the window list will go away.

    MTD MSG_META_FUP_KBD_CHAR   On a DELETE keypress, we want to close the
				currently selected window.

    MTD MSG_META_GAINED_TARGET_EXCL 
				Make sure the Express Menu is hidden when
				the window list come up.

    MTD MSG_META_LOST_TARGET_EXCL 
				Since we do not have a GenApplication above
				us, we need to provide some extra code to
				make we lose sys target.

    MTD MSG_GEN_GUP_INTERACTION_COMMAND 
				Make sure target goes somewhere when the
				window list is closed.

    MTD MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION 
				Copied from OLAppSendToFlow because
				WindowListDialog is not under an
				OLApplication.

    MTD MSG_GEN_INTERACTION_INITIATE 
				Hide the tool area immediately after it is
				initiated.

    MTD MSG_META_MUP_ALTER_FTVMC_EXCL 
				Intercept change of focus within tool area
				to give this app & window the focus, as
				long as a child has the focus within the
				dialog.

    MTD MSG_GEN_BRING_TO_TOP    Brings tool area to the top.  We subclass
				this merely to avoid giving the focus to
				it.  This is done in ToolAreaAlter-
				FTVMCExcl, and there seems to be a problem
				doing it in both places.

    MTD MSG_SPEC_GUP_QUERY_VIS_PARENT 
				direct requests for vis parent to UIApp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinField.asm


DESCRIPTION:

	$Id: cwinFieldUncommon.asm,v 1.10 97/04/01 22:58:17 joon Exp $

-----------------------------------------------------------------------------@
HighUncommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldGetTopGenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look through windows on field, & find top app

CALLED BY:	MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION
			UIApplicationNotify

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		es 	= segment of OLFieldClass
		ax	= message #

RETURN:		^lcx:dx	= top GenApplication
			0 if none

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldGetTopGenApplication	method dynamic	OLFieldClass,
					MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION

	; Run through all the windows on this field, locating focusable
	; application objects for each one of standard priority. The ordering
	; of the windows gives us the order in which the application objects
	; should be.
	;
	mov	di, ds:[di].VCI_window		; di <- parent window
	mov	bp, si				; Get *ds:bp = GenField for
						; callback
	call	FieldCreateAppArrayFromWindows
	push	si

	; *ds:si is now a chunk array of application object optrs in the
	; order in which they should be. Use this ordering to find top one.
	; 

	mov	ax, 0				; get first one
	call	ChunkArrayElementToPtr
	mov	cx, 0				; in case out of bounds
	jc	done				; out of bounds
	movdw	cxdx, ({optr}ds:[di])
	
done:
	pop	ax				; free app list chunk
	call	LMemFree
	ret
OLFieldGetTopGenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldCreateAppArrayFromWindows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an array of GenApplication object optrs based on
		the ordering of standard-priority windows on the field.

CALLED BY:	OLFieldOrderGenApplicationList
		OLFieldGetTopGenApplication
PASS:		di	= field window
		*ds:bp	= GenField object
RETURN:		*ds:si	= chunk array of optrs
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldCreateAppArrayFromWindows proc	far
	uses	bp
	.enter
	clr	al			; basic chunk.  we're going to nuke
					; later anyway
	mov	bx, size optr
	clr	cx, si			; create chunk, please
	call	ChunkArrayCreate
	mov	bp, si			; *ds:bp is chunk array

	; cx = 0 at this point (signals to callback we need the first child)

	mov	bx, SEGMENT_CS
	mov	si, offset FieldCreateAppArrayFromWindowsCallback
	push	ds:[LMBH_handle]	;Save handle of segment for fixup later
	call	WinForEach		;Does not fixup DS!
	pop	bx
	call	MemDerefDS		;Fixup LMem segment
					; We now have a list of the app objects
					; *ds:bp
	mov	si, bp			; pass chunk array in *ds:si
	.leave
	ret
FieldCreateAppArrayFromWindows endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldCreateAppArrayFromWindowsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Code largely stolen from 
		CreateChunkArrayOnWindowsInLayerCallback to perform additional
		work necessary to yield an array of application objects.

CALLED BY:	FieldCreateAppArrayFromWindows via WinForEach
PASS:		di	= window handle to process
		cx	= 0 if di is field and shouldn't be processed.
		*ds:bp	= chunk array to fill
RETURN:		carry set if done
		carry clear to keep going:
			di	= next window to process
		cx	= non-zero
DESTROYED:	bx, si
		ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldCreateAppArrayFromWindowsCallback proc	far
	.enter
	mov	si, WIT_FIRST_CHILD_WIN
	jcxz	getNextWindow

	;
	; Fetch window priority and ensure its layer is at the standard
	; priority. We only order applications based on standard priority layers
	; (anything non-standard will come up to the right place all by itself)
	; 
	mov	si, WIT_PRIORITY	; Check only standard priority layers
	call	WinGetInfo
	andnf	al, mask WPD_LAYER
	cmp	al, (LAYER_PRIO_STD shl offset WPD_LAYER)
	jne	getNextSib

	;
	; Make sure the UI doesn't own the thing, as it can take care of itself.
	; 
	mov	bx, di
	call	MemOwner		; get owning geode
	cmp	bx, handle ui		; if owned by the UI, skip out -- must
					; be the floating tool area or
					; something.  In any case, the UI app
					; doesn't sit below any field, so this
					; would be a mistake to continue.
	je	getNextSib

	;
	; Make sure the geode that owns the thing is focusable.
	; 
	call	WinGeodeGetFlags
	test	ax, mask GWF_FOCUSABLE
	jz	getNextSib

	;
	; Make sure the owner has an application object to be ordered.
	; 
	call	GeodeGetAppObject	; fetch application object
	tst	bx
	jz	getNextSib		; if no app object, nothing to move
	
	;
	; Now see if the beast is already in our array (might have two different
	; window layers with something else mixed in, you know, or just two
	; different windows in the same layer below the field...)
	; 
	mov	dx, si			; ^lbx:dx <- app object for which to
					;  search
	mov	si, ds:[bp]
	mov	cx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset	; ds:si <- first element
	jcxz	append			; => no elements

checkLoop:
	cmp	ds:[si].chunk, dx
	jne	checkNext
	cmp	ds:[si].handle, bx
	je	getNextSib		; => already here, so blow it off
checkNext:
	add	si, size optr
	loop	checkLoop

append:
	;
	; Not already in the array, so put it at the end.
	; 
	push	di			; preserve window handle
	xchg	si, bp
	call	ChunkArrayAppend
	mov	ds:[di].handle, bx
	mov	ds:[di].chunk, dx
	mov	bp, si
	pop	di

getNextSib:
	mov	si, WIT_NEXT_SIBLING_WIN

getNextWindow:	
	call	WinGetInfo		; ax <- window handle
	mov_tr	di, ax
	ornf	cx, -1			; this one ain't the field, and
					;  clear the carry too, please.
	.leave
	ret
FieldCreateAppArrayFromWindowsCallback endp

HighUncommon	ends
HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldBringToTop

DESCRIPTION:	Causes field to grab field exclusives & come to the top of
		the screen.

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_BRING_TO_TOP

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@


OLFieldBringToTop	method	OLFieldClass, MSG_GEN_BRING_TO_TOP
				; Raise window to top of window group
	call	VisQueryWindow
EC <	or	di, di						>
EC <	ERROR_Z	OL_ERROR					>
	clr	ax
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

if not SINGLE_FIELD_SYSTEM
				; Use MSG_META_ATTACH to reinitialize our
				; options (interfaceLevel, launchModel, etc.)
	mov	ax, MSG_META_ATTACH
	call	ObjCallInstanceNoLock
endif

				; Start up any detached apps - we're coming
				; to the front!  (It is illegal to be at
				; the front with detached applications)
				; (THIS IS DONE WHEN THE FIELD GETS THE
				; TARGET AND FOCUS EXCLUSIVES)
				;
				; WE SHOULD NOT CALL MSG_GEN_FIELD_RESTORE_APPS
				; HERE BECAUSE WE AREN'T THE SYSTEM'S EXCLUSIVE
				; FIELD YET, SO APPS MAY NOT START UNDER US.

	mov	bp, mask MAEF_GRAB or mask MAEF_FULL_SCREEN or \
				mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	mov	si, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	tst	bx
	jz	done
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	clr	di
	call	ObjMessage
done:
	ret

OLFieldBringToTop	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldLowerToBottom

DESCRIPTION:	Causes field to grab field exclusives & come to the top of
		the screen.

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_GEN_LOWER_TO_BOTTOM

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@


OLFieldLowerToBottom	method	OLFieldClass, MSG_GEN_LOWER_TO_BOTTOM

	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	bp, mask MAEF_FULL_SCREEN or mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock

	call	VisQueryWindow
	tst	di
	jz	done
        mov     ax, mask WPF_PLACE_BEHIND
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	UserCallSystem

done:
	ret

OLFieldLowerToBottom	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldConsumeMessage

DESCRIPTION:	Consume the event so that the superclass will NOT provide
		default handling for it.

PASS:		*ds:si 	- instance data
		es     	- segment of OLFieldClass
		ax 	- message to eat

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

OLFieldConsumeMessage	method	OLFieldClass,	MSG_META_FORCE_GRAB_KBD,
						MSG_VIS_FORCE_GRAB_LARGE_MOUSE,
						MSG_VIS_FORCE_GRAB_MOUSE,
						MSG_META_GRAB_KBD,
						MSG_VIS_GRAB_LARGE_MOUSE,
						MSG_VIS_GRAB_MOUSE,
						MSG_META_RELEASE_KBD,
						MSG_VIS_RELEASE_MOUSE
	ret
	
OLFieldConsumeMessage	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGainedFocusExcl

DESCRIPTION:	Handler for gaining of field exclusive; i.e. focus field
		in system

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_GAINED_FOCUS_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


OLFieldGainedFocusExcl	method	dynamic OLFieldClass, 
					MSG_META_GAINED_FOCUS_EXCL
				; Start up any detached apps - we're coming
				; to the front!  (It is illegal to be at
				; the front with detached applications)
	push	ax

	mov	ax, MSG_GEN_FIELD_RESTORE_APPS
	call	ObjCallInstanceNoLock

	pop	ax
	call	OLFieldUpdateFocusCommon

	; Update keyboard grab
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	call	SysUpdateKbdGrab
	ret

OLFieldGainedFocusExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldLostFocusExcl

DESCRIPTION:	Handler for when field has lost the target exclusive, &
		must force active app to no longer be active as well

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_LOST_FOCUS_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


OLFieldLostFocusExcl	method	dynamic OLFieldClass,
					MSG_META_LOST_FOCUS_EXCL

	call	OLFieldUpdateFocusCommon

	; Force release of keyboard grab
	;
	clr	cx
	clr	dx
	call	SysUpdateKbdGrab
	ret

OLFieldLostFocusExcl	endm

;
;---
;

OLFieldUpdateFocusCommon	proc	far
	mov	bp, MSG_META_GAINED_FOCUS_EXCL	; Pass base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLFI_focusExcl
	GOTO	FlowUpdateHierarchicalGrab
OLFieldUpdateFocusCommon	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGainedTargetExcl

DESCRIPTION:	Handler for gaining of field exclusive; i.e. focus field
		in system

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_GAINED_FOCUS_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


OLFieldGainedTargetExcl	method	dynamic OLFieldClass, 
					MSG_META_GAINED_TARGET_EXCL
	push	ax

	; Set ourselves up as being the new default field within the system
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
	call	UserCallSystem

				; Start up any detached apps - we're coming
				; to the front!  (It is illegal to be at
				; the front with detached applications)
	mov	ax, MSG_GEN_FIELD_RESTORE_APPS
	call	ObjCallInstanceNoLock

	pop	ax
	GOTO	OLFieldUpdateTargetCommon

OLFieldGainedTargetExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldLostTargetExcl

DESCRIPTION:	Handler for when field has lost the target exclusive, &
		must force active app to no longer be active as well

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_LOST_TARGET_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


OLFieldLostTargetExcl	method	dynamic OLFieldClass, \
					MSG_META_LOST_TARGET_EXCL
	call	OLFieldUpdateTargetCommon

	; We're no longer the default field.  Clear out reference to us in the
	; system object
	;
EC <	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_FIELD			>
EC <	call	UserCallSystem						>
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	jne	badAssumption						>
EC <	cmp	dx, si							>
EC <	jne	badAssumption						>

	clr	cx
	clr	dx
	mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
	call	UserCallSystem
	ret

EC <badAssumption:							>
EC <	ERROR	OL_FIELD_BAD_ASSUMPTION_REGARDING_DEFAULT_FIELD		>

OLFieldLostTargetExcl	endm

;
;----
;

OLFieldUpdateTargetCommon	proc	far
	mov	bp, MSG_META_GAINED_TARGET_EXCL	; Pass base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLFI_targetExcl
	GOTO	FlowUpdateHierarchicalGrab
OLFieldUpdateTargetCommon	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGainedFullScreenExcl

DESCRIPTION:	Handler for gaining of full screen exclusive

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_GAINED_FULL_SCREEN_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

------------------------------------------------------------------------------@


OLFieldGainedFullScreenExcl	method	dynamic OLFieldClass, 
					MSG_META_GAINED_FULL_SCREEN_EXCL
	GOTO	OLFieldUpdateFullScreenCommon
OLFieldGainedFullScreenExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldLostFullScreenExcl

DESCRIPTION:	Handler for when field has lost the full screen exclusive

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_LOST_FULL_SCREEN_EXCL

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

------------------------------------------------------------------------------@


OLFieldLostFullScreenExcl	method	dynamic OLFieldClass,
					MSG_META_LOST_FULL_SCREEN_EXCL
	FALL_THRU	OLFieldUpdateFullScreenCommon
OLFieldLostFullScreenExcl	endm

;
;---
;

OLFieldUpdateFullScreenCommon	proc	far
	mov	bp, MSG_META_GAINED_FULL_SCREEN_EXCL	; base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLFI_fullScreenExcl
	GOTO	FlowUpdateHierarchicalGrab
OLFieldUpdateFullScreenCommon	endp


HighUncommon ends
HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGetTarget

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	ax:bp	- Class of target object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


OLFieldGetTarget	method	dynamic OLFieldClass, \
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_GEN_FIELD
	mov	bx, Vis_offset
	mov	di, offset OLFI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
OLFieldGetTarget	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldStartMenu

DESCRIPTION:	Process case of menu button being pressed in workspace area.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- OLButton object
	cx, cx	- ptr position
	bp	- OLBF_IN flag set appropriately

RETURN:
	ax - 0 if ptr not in button, MRF_PROCESSED if ptr is inside

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

		MENU causes the workspace menu to come up, in non-stay-up
	mode.  If menu is released within a certain amount of time,
	a transition is made to stay-up mode.
	In stay up mode, the menu button is undepressed.  In non-stay-up
	mode, the button will stay depressed until the menu should be
	taken down, which occurs when the button is notified of having
	lost the active exclusive from its UI window.

	States:
	OLFI_menuTimer			- time at which button was pressed
					  on button such that a menu was
					  brought up.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@

if	(0)			; The ability to bring up the Express menu
				; by pressing the mouse in the field is hereby
				; turned off, effective 6/23/92 -- Doug
				; The reasons for its demise:
				;
				; 1) The standard Express menu is working again,
				;    so it is no longer necessary.
				; 2) The field version didn't kick the menu
				;    into stay-up mode, which would be the
				;    correct behavior, & I don't have time to
				;    go trying to get it to work correctly.

OLFieldStartMenu	method	dynamic OLFieldClass, MSG_META_START_SELECT
	mov	ax, MSG_OL_FIELD_POPUP_EXPRESS_MENU
	GOTO	ObjCallInstanceNoLock
OLFieldStartMenu	endm
endif

if	(0)	; didn't work.
; A test -- let's see if we can remotely get express menu up as a stay-up menu. 
;
OLFieldPutExpressMenuUpInStayUpMode	method	dynamic OLFieldClass, \
					MSG_META_START_SELECT

					; Create the workspace menu if not
					; already existing, add to GenField w/
					; upward link only
	call	OLFieldEnsureExpressMenu
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLFI_expressMenu	;set *ds:si = menu

	mov	ax, MSG_OL_POPUP_ACTIVATE	; bring up menu
	call	ObjCallInstanceNoLock		; put it up.
	mov	ax, MSG_MO_MW_ENTER_STAY_UP_MODE
	clr	cx
	call	ObjCallInstanceNoLock		; put it up.
	pop	si
	ret
OLFieldPutExpressMenuUpInStayUpMode	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldPopupExpressMenu

DESCRIPTION:	Pop up the workspace menu, at the specified location

CALLED BY:	INTERNAL

PASS:
	*ds:si	- OLButton object
	cx, dx	- ptr position (in field window)

RETURN:
	ax - 0 if ptr not in button, MRF_PROCESSED if ptr is inside

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	In stay up mode, the menu button is undepressed.  In non-stay-up
	mode, the button will stay depressed until the menu should be
	taken down, which occurs when the button is notified of having
	lost the active exclusive from its UI window.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version
------------------------------------------------------------------------------@

if	(0)			; The ability to bring up the Express menu
				; by pressing the mouse in the field is hereby
				; turned off, effective 6/23/92 -- Doug
				; The reasons for its demise:
				;
				; 1) The standard Express menu is working again,
				;    so it is no longer necessary.
				; 2) The field version didn't kick the menu
				;    into stay-up mode, which would be the
				;    correct behavior, & I don't have time to
				;    go trying to get it to work correctly.

OLFieldPopupExpressMenu	method	dynamic OLFieldClass, \
					MSG_OL_FIELD_POPUP_EXPRESS_MENU

					; Create the workspace menu if not
					; already existing, add to GenField w/
					; upward link only
	call	OLFieldEnsureExpressMenu

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_expressMenu	; if no exrpress menu on field,
	jz	done				; exit.

	push	si
	mov	si, ds:[di].OLFI_expressMenu	;set *ds:si = menu
	mov	ax, MSG_OL_POPUP_ACTIVATE	; bring up menu
	call	ObjCallInstanceNoLock		; put it up.
	pop	si
	call	VisAddButtonPostPassive		; Add post-passive grab so we
						;  can take down the menu when
						;  everything goes away.

done:
	mov	ax, mask MRF_PROCESSED		; show processed
	ret
OLFieldPopupExpressMenu	endm

endif


if _EXPRESS_MENU
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldToggleExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open/close field's express menu.

CALLED BY:	MSG_OL_FIELD_TOGGLE_EXPRESS_MENU

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		es 	= segment of OLFieldClass
		ax	= MSG_OL_FIELD_TOGGLE_EXPRESS_MENU

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/30/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldToggleExpressMenu	method	dynamic	OLFieldClass,
						MSG_OL_FIELD_TOGGLE_EXPRESS_MENU

	tst	ds:[di].OLFI_expressMenu	; if no exrpress menu on field,
	jz	done				; exit.

	mov	si, ds:[di].OLFI_expressMenu	;set *ds:si = menu
EC <	mov	di, segment OLPopupWinClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLPopupWinClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>

	;
	; if not vis built yet, open it
	;
	call	VisCheckIfSpecBuilt
	jnc	open				; nope, open
	;
	; check if currently opened
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	close				; visible, close it
	;
	; else, open it
	;
open:
	mov	ax, MSG_OL_POPUP_FIND_BUTTON
	call	ObjCallInstanceNoLock		; ^lcx:dx = button
	tst	dx
	jz	done
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_ACTIVATE
	clr	di
	GOTO	ObjMessage			; open menu

close:
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	GOTO	ObjCallInstanceNoLock

done:
	ret
OLFieldToggleExpressMenu	endm
endif		; if _EXPRESS_MENU


HighUncommon ends
HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldSelectWindowListEntry

DESCRIPTION:	Brings window to front

PASS:		*ds:si	- instance data
		ds:bx	- instance data
RETURN:		ax = chunk handle of currently selected item
		carry set if no window selected

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/92		initial version

------------------------------------------------------------------------------@

if _PM	;----------------------------------------------------------------------

OLFieldSelectWindowListEntry	method	dynamic OLFieldClass,
					MSG_OL_FIELD_SELECT_WINDOW_LIST_ENTRY
	;
	; Get current selection
	;
	mov	si, ds:[di].OLFI_windowListList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	jc	done
	;
	; Send notification to the entry itself (which will provide
	; behavior of relaying notification to window)
	;
	mov	si, ax
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	ObjCallInstanceNoLock
	mov	ax, si
	clc
done:
	ret
OLFieldSelectWindowListEntry	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldWindowListCloseWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the window currently selected in the window list.

CALLED BY:	MSG_OL_FIELD_WINDOW_LIST_CLOSE_WINDOW
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

OLFieldWindowListCloseWindow	method dynamic OLFieldClass,
					MSG_OL_FIELD_WINDOW_LIST_CLOSE_WINDOW
	mov	ax, MSG_OL_FIELD_SELECT_WINDOW_LIST_ENTRY
	call	ObjCallInstanceNoLock
	jc	done		

	mov	si, ax
	mov	ax, MSG_OL_WINDOW_LIST_ITEM_CLOSE_WINDOW
	call	ObjCallInstanceNoLock
done:
	ret
OLFieldWindowListCloseWindow	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldOpenWindowList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the window list dialog

CALLED BY:	MSG_GEN_FIELD_OPEN_WINDOW_LIST
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

OLFieldOpenWindowList	method dynamic OLFieldClass, 
					MSG_GEN_FIELD_OPEN_WINDOW_LIST
	mov     si, ds:[di].OLFI_windowListDialog
	tst     si
	jz      done

	mov     ax, MSG_GEN_INTERACTION_INITIATE
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLFieldOpenWindowList	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldCloseWindowList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the window list.

CALLED BY:	MSG_OL_FIELD_CLOSE_WINDOW_LIST
PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	10/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

OLFieldCloseWindowList	method dynamic OLFieldClass,
					MSG_OL_FIELD_CLOSE_WINDOW_LIST
	mov	si, ds:[di].OLFI_windowListDialog
	tst	si
	jz	done
	;
	; Release target so the window list will go away.
	;
	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLFieldCloseWindowList	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle specific UI close message releasing the target so
		the window list will go away.

CALLED BY:	MSG_OL_WIN_CLOSE
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

WindowListClose	method dynamic WindowListDialogClass, MSG_OL_WIN_CLOSE

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	GOTO	ObjCallInstanceNoLock

WindowListClose	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On a DELETE keypress, we want to close the currently
		selected window.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		carry set if character was handled by someone (and should
		not be used elsewhere).
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	10/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

WindowListKeyboard	method dynamic WindowListDialogClass, 
					MSG_META_FUP_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS
	jz	done				; ignore if not first press

	tst	dh
	jnz	callSuper			; callsuper if any ShiftState

	cmp	cx, (VC_ISCTRL shl 8) or VC_ESCAPE
	jne	notESC

	mov	ax, MSG_OL_WIN_CLOSE		; close if Escape key pressed
	call	ObjCallInstanceNoLock
	jmp	handled

notESC:
	cmp	cx, (VC_ISCTRL shl 8) or VC_DEL
	jne	callSuper			; callsuper if not DELETE key

	mov	ax, MSG_OL_FIELD_WINDOW_LIST_CLOSE_WINDOW
	call	GenCallParent
handled:
	stc
	ret

callSuper:
	mov	di, offset WindowListDialogClass
	GOTO	ObjCallSuperNoLock
done:
	ret
WindowListKeyboard	endm

endif	;----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the Express Menu is hidden when the window list
		come up.

CALLED BY:	MSG_META_GAINED_TARGET_EXCL
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WIZARDBA	;--------------------------------------------------------------

WindowListGainedTargetExcl	method dynamic WindowListDialogClass, 
					MSG_META_GAINED_TARGET_EXCL
	mov	di, offset WindowListDialogClass
	call	ObjCallSuperNoLock

	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	dx, size OLFieldMoveToolAreaParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].OLFMTAP_geode, 0	; park the tool area off screen
	mov	ss:[bp].OLFMTAP_xPos, 0	; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_yPos, 0	; not needed for parking off-screen
					; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_layerPriority, 0
	mov	ax, MSG_OL_FIELD_MOVE_TOOL_AREA
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	add	sp, size OLFieldMoveToolAreaParams
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	GOTO	GenCallParent

WindowListGainedTargetExcl	endm

endif	;----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since we do not have a GenApplication above us, we need
		to provide some extra code to make we lose sys target.

CALLED BY:	MSG_META_LOST_TARGET_EXCL
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	10/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

WindowListLostTargetExcl	method dynamic WindowListDialogClass, 
					MSG_META_LOST_TARGET_EXCL
	mov	di, offset WindowListDialogClass
	call	ObjCallSuperNoLock
	;
	; Close window list dialog.
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

WindowListLostTargetExcl	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure target goes somewhere when the window list is closed.

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

WindowListInteractionCommand	method dynamic WindowListDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
	push	cx
	mov	di, offset WindowListDialogClass
	call	ObjCallSuperNoLock
	pop	cx

	cmp	cx, IC_DISMISS
	jne	done

	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	GenCallParent

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	movdw	bxsi, cxdx
	clr	di
	GOTO	ObjMessage
done:
	ret
WindowListInteractionCommand	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WindowListVisVupBumpMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copied from OLAppSendToFlow because WindowListDialog is not
		under an OLApplication.

CALLED BY:	MSG_VIS_VUP_BUMP_MOUSE
PASS:		*ds:si	= WindowListDialogClass object
		ds:di	= WindowListDialogClass instance data
		ds:bx	= WindowListDialogClass object (same as *ds:si)
		es 	= segment of WindowListDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	6/17/93   	Initial version copied from OLAppSendToFlow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

WindowListSendToFlow	method dynamic WindowListDialogClass, 
			MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION, \
			MSG_VIS_VUP_GET_MOUSE_STATUS, \
			MSG_VIS_VUP_BUMP_MOUSE
	mov	di, mask MF_CALL
	GOTO	UserCallFlow

WindowListSendToFlow	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide the tool area immediately after it is initiated.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= ToolAreaClass object
		es 	= segment of ToolAreaClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/20/92   	Initial version
	brianc	11/30/92	updated for UIEP_LOWER_LEFT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToolAreaInteractionInitiate	method dynamic ToolAreaClass, 
					MSG_GEN_INTERACTION_INITIATE
	mov	di, offset ToolAreaClass
	call	ObjCallSuperNoLock

;
; WIZARDBA always moves tool area offscreen.  Others will only make a
; move request if UIEP_LOWER_LEFT, in which case, MSG_OL_FIELD_MOVE_TOOL_AREA
; will move the thing to the correct place
;
ifndef WIZARDBA	;--------------------------------------------------------------
if not _NIKE	; NIKE moves tool area offscreen ------------------------------

	;
	; if UIEP_LOWER_LEFT, force a move so that it'll be position at
	; the lower left
	;
	push	es
	segmov	es, dgroup, ax				;es = dgroup
	mov	ax, es:[olExpressOptions]
	pop	es
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_LOWER_LEFT shl offset UIEO_POSITION
	jne	done

endif		; if not _NIKE ------------------------------------------------
endif		;--------------------------------------------------------------

	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	dx, size OLFieldMoveToolAreaParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].OLFMTAP_geode, 0	; park the tool area off screen
	mov	ss:[bp].OLFMTAP_xPos, 0	; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_yPos, 0	; not needed for parking off-screen
if EVENT_MENU
	mov	ss:[bp].OLFMTAP_eventPos, 0
endif
					; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_layerPriority, 0
	mov	ax, MSG_OL_FIELD_MOVE_TOOL_AREA
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	add	sp, size OLFieldMoveToolAreaParams
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent
	
done:
	ret
ToolAreaInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppListItemKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch application on C_SPACE

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= AppListItemClass object
		ds:di	= AppListItemClass instance data
		ds:bx	= AppListItemClass object (same as *ds:si)
		es 	= segment of AppListItemClass
		ax	= message #
		cx	= character value
				SBCS: ch = CharacterSet, cl = Chars
				DBCS: cx = Chars
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	4/ 1/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;--------------------------

AppListItemKbdChar	method dynamic AppListItemClass, 
					MSG_META_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS
	jz	callSuper
	tst	dh
	jnz	callSuper
	cmp	cx, C_SPACE
	jne	callSuper

	GOTO	AppListItemLaunchApp

callSuper:
	mov	di, offset AppListItemClass
	GOTO	ObjCallSuperNoLock

AppListItemKbdChar	endm

endif ; APPLICATION_MENU	;------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppListItemEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch application on END_SELECT

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= AppListItemClass object
		ds:di	= AppListItemClass instance data
		ds:bx	= AppListItemClass object (same as *ds:si)
		es 	= segment of AppListItemClass
		ax	= message #
		cx	= X position of mouse
		dx	= X position of mouse
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	4/ 1/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;--------------------------

AppListItemEndSelect	method dynamic AppListItemClass, 
					MSG_META_END_SELECT
	call	AppListItemLaunchApp
	mov	ax, mask MRF_PROCESSED
	ret
AppListItemEndSelect	endm

endif ; APPLICATION_MENU	;------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppListItemLaunchApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch application

CALLED BY:	AppListItemKbdChar, AppListItemEndSelect
PASS:		*ds:si	= AppListItemClass object
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	4/ 1/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;------------------------------

AppListItemLaunchApp	proc	far

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx
	call	GenCallParent

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	lea	si, ds:[si].ALII_token

	mov	ax, size GeodeToken
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	clr	di
	mov	cx, size GeodeToken
	rep	movsb
	call	MemUnlock

	push	bx
	call	GeodeGetProcessHandle
	mov	bp, bx
	pop	bx

	mov	al, PRIORITY_UI
	mov	cx, vseg AppListItemThreadLaunchApp
	mov	dx, offset AppListItemThreadLaunchApp
	mov	di, 2048
	call	ThreadCreate
done:
	ret
AppListItemLaunchApp	endp

endif ; APPLICATION_MENU	;----------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppListItemThreadLaunchApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch app on separate thread
		(cuz we can't IACPConnect from ui:0)

CALLED BY:	AppListItemLaunchApp via ThreadCreate
PASS:		^hcx	= GeodeToken
RETURN:		ThreadDestroy return values
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	4/ 1/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if APPLICATION_MENU	;---------------------------------

AppListItemThreadLaunchApp	proc	far
	mov	bx, cx			; ^hbx = GeodeToken

	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	jc	free

	push	bx
	call	MemLock
	mov	es, ax
	clr	di
	mov	ax, mask IACPCF_OBEY_LAUNCH_MODEL or mask IACPCF_FIRST_ONLY or\
		    (IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	mov	bx, dx
	call	IACPConnect		; bp = IACPConnection
	pop	bx
	jc	free

	clr	cx
	call	IACPShutdown
free:
	call	MemFree
done:
	clr	cx,dx,bp,si
	ret
AppListItemThreadLaunchApp	endp

endif ; APPLICATION_MENU	;----------------------

HighUncommon ends
HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		ToolAreaAlterFTVMCExcl

DESCRIPTION:	Intercept change of focus within tool area to give this
		app & window the focus, as long as a child has the focus
		within the dialog.

PASS:
	*ds:si - instance data (for object in OLField class)
	es - segment of OLFieldClass

	ax - MSG_META_MUP_ALTER_FTVMC_EXCL

	^lcx:dx - object requesting grab/release
	bp	- MetaAlterFTVMCExclFlags

RETURN:	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/92		Initial version

------------------------------------------------------------------------------@


ToolAreaAlterFTVMCExcl method dynamic ToolAreaClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL

	;
	; redirect requests to UIApp, if a OLWin object
	;
	push	ax, cx, dx, bp, bx, si
	movdw	bxsi, cxdx
	mov	cx, segment OLWinClass
	mov	dx, offset OLWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, dx, bp, bx, si
	jnc	callSuper
	call	UserCallApplication
	;
	; if focus under UIApp, give it focus, else have it release focus
	;
	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	UserCallApplication		; ^lcx:dx = focus
	jcxz	release
;grab:
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	GOTO	UserCallApplication

release:
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	UserCallApplication
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	GOTO	UserCallSystem

callSuper:
	mov	di, offset ToolAreaClass
	GOTO	ObjCallSuperNoLock

ToolAreaAlterFTVMCExcl endm




COMMENT @----------------------------------------------------------------------

METHOD:		ToolAreaBringToTop -- 
		MSG_GEN_BRING_TO_TOP for ToolAreaClass

DESCRIPTION:	Brings tool area to the top.  We subclass this merely to
		avoid giving the focus to it.  This is done in ToolAreaAlter-
		FTVMCExcl, and there seems to be a problem doing it in both
		places.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_BRING_TO_TOP

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/ 3/92         	Initial Version

------------------------------------------------------------------------------@

ToolAreaBringToTop	method dynamic	ToolAreaClass, \
				MSG_GEN_BRING_TO_TOP

	;
	; Hack things to avoid giving the express menu the focus.
	;
	mov	di, ds:[si]			; can't use incoming ds:di!
	add	di, ds:[di].Vis_offset		;	(ToolAreaClass is
						;	subclass of GenInter)
	or	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX

	mov	di, offset ToolAreaClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLCI_buildFlags, not mask OLBF_TOOLBOX
	ret
ToolAreaBringToTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaGupQueryVisParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	direct requests for vis parent to UIApp

CALLED BY:	MSG_SPEC_GUP_QUERY_VIS_PARENT

PASS:		*ds:si	= ToolAreaClass object
		ds:di	= ToolAreaClass instance data
		es 	= segment of ToolAreaClass
		ax	= MSG_SPEC_GUP_QUERY_VIS_PARENT

		cx	= SpecQueryVisParentType

RETURN:		carry	= set if data found & returned, clear if no object
				responded
		^lcx:dx	= object suitable to be visible parent

ALLOWED TO DESTROY:	
		ax, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/5/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaGupQueryVisParent	method	dynamic	ToolAreaClass,
					MSG_SPEC_GUP_QUERY_VIS_PARENT
	cmp	cx, SQT_VIS_PARENT_FOR_POPUP
	jne	toApp
	;
	; Make our own vis parent (the field on which we sit) be the parent of
	; any popup. It makes no sense to me to have it be the application
	; object -- ardeb 10/5/95
	;
	call	VisFindParent
	movdw	cxdx, bxsi
	stc
	ret
toApp:
	;
	; pass on to UIApp
	;
	call	UserCallApplication
	ret
ToolAreaGupQueryVisParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	don't draw anything for ourselves, just our children

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= ToolAreaClass object
		ds:di	= ToolAreaClass instance data
		ds:bx	= ToolAreaClass object (same as *ds:si)
		es 	= segment of ToolAreaClass
		ax	= message #
	cl	- DrawFlags:  DF_EXPOSED set if GState is set to update window
	^hbp	- GState to draw through.
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if EVENT_MENU
ToolAreaDraw	method dynamic ToolAreaClass, 
					MSG_VIS_DRAW
	mov	di, segment VisCompClass
	mov	es, di
	mov	di, offset VisCompClass
	call	ObjCallClassNoLock
	ret
ToolAreaDraw	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	always minimize

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= ToolAreaClass object
		ds:di	= ToolAreaClass instance data
		ds:bx	= ToolAreaClass object (same as *ds:si)
		es 	= segment of ToolAreaClass
		ax	= message #
		cx, dx	= suggested size
RETURN:		cx, dx	= desired size
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if EVENT_MENU
ToolAreaRecalcSize	method dynamic ToolAreaClass, 
					MSG_VIS_RECALC_SIZE

	mov	cx, mask RSA_CHOOSE_OWN_SIZE	; allow minimal width
	mov	di, offset ToolAreaClass
	call	ObjCallSuperNoLock
	ret
ToolAreaRecalcSize	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaGetMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return minimal width

CALLED BY:	MSG_VIS_COMP_GET_MINIMUM_SIZE
PASS:		*ds:si	= ToolAreaClass object
		ds:di	= ToolAreaClass instance data
		ds:bx	= ToolAreaClass object (same as *ds:si)
		es 	= segment of ToolAreaClass
		ax	= message #
RETURN:		cx, dx	= minimum size
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if EVENT_MENU
ToolAreaGetMinimumSize	method dynamic ToolAreaClass, 
					MSG_VIS_COMP_GET_MINIMUM_SIZE
	mov	di, offset ToolAreaClass
	call	ObjCallSuperNoLock
	mov	cx, 0			; allow mimimal width
	ret
ToolAreaGetMinimumSize	endm
endif

if RECTANGULAR_ROTATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldRotateDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate!

CALLED BY:	MSG_GEN_ROTATE_DISPLAY

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data

RETURN:		nuthin'
DESTROYED:	nuthin' 'ceptin' ax, cx, dx, 'n' bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldRotateDisplay	method dynamic OLFieldClass, MSG_GEN_ROTATE_DISPLAY
		.enter
	;
	;  Get the new bounds.
	;
		mov	ax, MSG_VIS_GET_BOUNDS	; cx = width, dx = heigth
		call	ObjCallInstanceNoLock
		xchg	cx, dx			; cx = height

		call	ResizeFieldWindow
	;
	;  Resize the field.
	;
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
	;
	;  Invalidate.
	;
		call	VisMarkFullyInvalid	; uses VUM_MANUAL
	;
	;  Tell children to rotate.
	;
		call	RotateChildCallback
done:
		.leave
		ret
OLFieldRotateDisplay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeFieldWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the field window.

CALLED BY:	OLFieldRotateDisplay

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 9/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeFieldWindow	proc	near
		uses	dx
		.enter
	;
	;  Get the window for resizing.
	;
		push	cx, dx
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock
		pop	bx, dx
		jcxz	done
	;
	;  Resize the window without generating an expose event.
	;
		push	si
		mov	di, cx		; ^hdi = window

		push	ax
		mov	si, WIT_COLOR
		mov	ah, mask WCF_PLAIN	; no expose event!
		call	WinSetInfo		; (WIT_COLOR, WCF_PLAIN)
		pop	ax

		mov_tr	cx, bx		; cx = height
		mov	bx, mask WPF_ABS; move in absolute screen coordinates
		push	bx		; put WinPassFlags on stack
		clr	ax, bx, bp, si		; top, left, & 
						; associated region (none)
		call	WinResize
	;
	;  Set the WinColorFlags back to what they were before.
	;
		mov	si, WIT_COLOR
		mov	ah, mask WCF_TRANSPARENT
		call	WinSetInfo		; (WIT_COLOR, WCF_PLAIN)

		pop	si		; *ds:si = field
done:
		.leave
		ret
ResizeFieldWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateChildCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell child to rotate.

CALLED BY:	OLFieldRotate

PASS:		*ds:si = field

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 8/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateChildCallback	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; quit all apps in this field
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GFI_genApplications
		tst	di				; any apps?
		jz	done				; nope
		mov	di, ds:[di]			; ds:di = list
		inc	di
		jz	done				; no apps
		dec	di
		jz	done				; no apps
		ChunkSizePtr	ds, di, cx		; cx = size of list
		shr	cx
		shr	cx				; cx = number of apps
	;
	; send to all applications
	;	*ds:si = GenField
	;	cx = number of GenApps
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GFI_genApplications
		mov	di, ds:[di]		; ds:di = GenApp list
appLoop:
		push	cx			; save GenApp counter
		push	si			; save GenField chunk
	;
	; send MSG_GEN_ROTATE_DISPLAY to GenApp object
	;
		mov	bx, ds:[di]+2		; GenApp handle
		mov	si, ds:[di]+0		; GenApp chunk
		push	di			; save GenApp list offset
		mov	ax, MSG_GEN_ROTATE_DISPLAY
	;
	; force-queue -> doesn't move lmem block
	;
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	di			; retrieve GenApp list offset
		add	di, size optr
		pop	si			; *ds:si = GenField
		pop	cx			; cx = GenApp counter
		loop	appLoop
done:
		.leave
		ret
RotateChildCallback	endp

endif	; RECTANGULAR_ROTATION

HighUncommon	ends
