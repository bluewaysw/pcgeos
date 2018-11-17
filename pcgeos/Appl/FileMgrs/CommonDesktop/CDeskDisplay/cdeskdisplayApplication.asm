COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayApplication.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of DeskApplicationClass


	$Id: cdeskdisplayApplication.asm,v 1.5 98/08/20 06:50:12 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the ui for the express menu control panel.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DeskApplicationClass
		ax	= message #
	 	dx 	= AppLaunchBlock
		bp 	= Extra state block from state file, or 0 if none.
		  	  This is the same block as returned from
		  	  MSG_GEN_PROCESS_CLOSE_APPLICATION, in some previous
			  detach
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	2/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationAttach	method dynamic DeskApplicationClass, 
					MSG_META_ATTACH

		mov	di, offset DeskApplicationClass
		call	ObjCallSuperNoLock

	;
	; Fetch app features after attaching, as we don't know if we
	; restored from state or read the features from the .INI file
	;
		
		mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
		call	ObjCallInstanceNoLock

NOFXIP <	segmov	es, dgroup, bx			;es = dgroup	>
FXIP <		GetResourceSegmentNS dgroup, es, TRASH_BX		>
		mov	es:[desktopFeatures], ax

if _NEWDESK and 0
		mov	ax, MSG_GEN_CONTROL_GENERATE_UI
		mov	bx, handle DesktopMenuControlPanel
		mov	si, offset DesktopMenuControlPanel
		call	ObjMessageNone
endif 		;if _NEWDESK
		ret

DeskApplicationAttach	endm

InitCode ends


;---------------------------

DetachCode segment resource

if _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Logout

CALLED BY:	MSG_APP_LOGOUT
PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DeskApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	6/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationLogout	method dynamic DeskApplicationClass, 
					MSG_APP_LOGOUT
		mov	ax, MSG_META_GRAB_TARGET_EXCL	; grab target to force
		call	ObjCallInstanceNoLock	;  window list dialog to close

		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		call	ObjCallInstanceNoLock

		push	es
NOFXIP <	segmov	es, dgroup, ax			;es = dgroup	>
FXIP <		mov_tr	ax, bx				;save bx value	>
FXIP <		GetResourceSegmentNS dgroup, es, TRASH_BX		>
FXIP <		mov_tr	bx, ax				;restore bx	>
		mov	es:[loggingOutFlag], BB_TRUE
		pop	es
	;
	; Send message to parent field - "Yes, we want to logout."
	;

		mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
		mov	cx, IC_YES
		call	callParentField

	;
	; Set our application object as -targetable, -focusable, -modelable.
	; That way when all of the other apps have quit, the field won't be
	; able to find an active focus or target causing it to detach.
	;

		mov	ax, MSG_GEN_APPLICATION_SET_STATE
		clr	cx
		mov	dx, mask AS_FOCUSABLE or mask AS_MODELABLE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_SET_ATTRS
		mov	cx, mask GA_TARGETABLE shl 8	; clear this bit
		call	ObjCallInstanceNoLock

	;
	; Release focus and target if we have them and then ensure active FT.
	; The ensure active FT will either cause the field to detach if there
	; are no other apps running or it will give the active FT another app.
	;

		mov	ax, MSG_META_RELEASE_FT_EXCL
		call	ObjCallInstanceNoLock

		mov	ax, MSG_META_ENSURE_ACTIVE_FT
		call	callParentField

		ret


callParentField:
		push	si
		mov	bx, segment GenFieldClass
		mov	si, offset GenFieldClass
		mov	di, mask MF_RECORD
		call	ObjMessage		; di = event
		pop	si
		mov	cx, di			; cx = event
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
		retn
DeskApplicationLogout	endm

endif 	;	_NEWDESKBA


if (not (_FCAB or _NEWDESKBA or _ZMGR or _DOCMGR))

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	asks the user if they want to exit the system instead of
		just GeoManager

CALLED BY:	MSG_META_QUIT
PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DeskApplicationClass
		ax	= message #
RETURN:		none
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationQuit	method dynamic DeskApplicationClass, 
					MSG_META_QUIT
	uses	ax, si		; preserved for if we call superclass
	.enter

if not _NEWDESK
	; first check if NewDesk is running.  if so just quit.

	push	es
	push	'k '
	push	'es'
	push	'wd'
	push	'ne'
	segmov	es, ss
	mov	di, sp
	mov	ax, 8
	mov	cx, mask GA_APPLICATION or mask GA_PROCESS
	mov	dx, mask GA_LIBRARY or mask GA_DRIVER
	call	GeodeFind
	pop	ax, ax, ax, ax
	pop	es
	jc	callSuperClass

	; query user
	
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_CONFIRM_EXIT_GMGR
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCallFixup
	jnc	callSuperClass

	push	ds:[LMBH_handle]
	mov	bx, handle ConfirmExitGeoManager
	mov	si, offset ConfirmExitGeoManager
	call	UserDoDialog
	pop	bx
	call	MemDerefDS

	cmp	ax, EXIT_GM			; exit GeoManager?
	je	callSuperClass
	cmp	ax, EXIT_DOS			; exit to DOS?
	jne	exit				;    else, cancel
endif		; if (not _NEWDESK)

	mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				; move classed event into cx

	mov	si, offset Desktop
	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

if not _NEWDESK
	jmp	exit
		
callSuperClass:
	.leave
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock		; <- EXIT

exit:
endif		; if (not _NEWDESK)

	.leave
	ret					; <- EXIT
DeskApplicationQuit	endm

endif		; if (not (_FCAB or _NEWDESKBA or _ZMGR))



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set flag saying we are detaching, and shouldn't be doing
		anything strenuous, like call UserDoDialog

CALLED BY:	MSG_META_DETACH

PASS:		es - segment of DeskApplicationClass

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationDetach	method	DeskApplicationClass, MSG_META_DETACH

NOFXIP <	segmov	es, dgroup, bx			; es = dgroup	>
FXIP <		GetResourceSegmentNS dgroup, es, TRASH_BX		>
		mov	es:[willBeDetaching], TRUE	; set flag
	;
	; set flag to cancel current operation in progress
	; (in case we got forced DETACH, we want to abort if possible)
	;
		mov	es:[cancelOperation], 0xff
	;
	; call superclass to handle
	;
		segmov	es, <segment DeskApplicationClass>, bx
		mov	di, offset DeskApplicationClass
		call	ObjCallSuperNoLock
		ret
DeskApplicationDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationDetachConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle detach-while-active stuff

CALLED BY:	MSG_META_CONFIRM_SHUTDOWN

PASS:		es - segment of DeskApplicationClass
		activeType - why application is active
		bp	= GCNShutdownControlType

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationDetachConfirm	method DeskApplicationClass, \
					MSG_META_CONFIRM_SHUTDOWN
	controlType		local	GCNShutdownControlType \
				push 	bp
	progressSource		local	optr
	progressDest		local	optr
	activeSource		local	optr
	activeDest		local	optr

	.enter

	cmp	ss:[controlType], GCNSCT_UNSUSPEND
	jne	checkActive
toExit:
	jmp	done

checkActive:

NOFXIP<	segmov	es, dgroup, ax		;es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es					>
	
	;
	; Gain the exclusive right to confirm things with the user.
	; 
	mov	ax, SST_CONFIRM_START
	call	SysShutdown
	jc	toExit		; => already canceled, so do nothing

	;
	; set-up before putting up detach-while-active box
	;
	mov	progressDest.handle, 0
ifndef GEOLAUNCHER
if _DISK_OPS
	mov	progressSource.handle, handle CopyStatusPercentage
	mov	progressSource.chunk, offset CopyStatusPercentage
	mov	activeSource.handle, handle ActiveCopyProgress
	mov	activeSource.chunk, offset ActiveCopyProgress
	cmp	es:[activeType], ACTIVE_TYPE_DISK_COPY
	je	haveTextFields_JMP
	mov	progressSource.handle, handle FormatStatusPercentage
	mov	progressSource.chunk, offset FormatStatusPercentage
	mov	activeSource.handle, handle ActiveFormatProgress
	mov	activeSource.chunk, offset ActiveFormatProgress
	cmp	es:[activeType], ACTIVE_TYPE_DISK_FORMAT
	jne	10$
haveTextFields_JMP:
	jmp	haveTextFields
10$:
endif
endif
	;
	; if file operation is active AND we do not have a file operation
	; progress box up, disable trigger that allows aborting file operation
	; as we don't support this while the file op is active (the trigger
	; exists for the case where the file operation needs attention)
	;
	mov	activeSource.handle, handle ActiveFileOpSource
	mov	activeSource.chunk, offset ActiveFileOpSource
	mov	activeDest.handle, handle ActiveFileOpDestination
	mov	activeDest.chunk, offset ActiveFileOpDestination
EC <	cmp	es:[activeType], ACTIVE_TYPE_FILE_OPERATION		>
EC <	ERROR_NZ	DESKTOP_FATAL_ERROR	; must be file-op	>
	cmp	es:[fileOpProgressBoxUp], TRUE
	je	afterCancel			; box is up, cancel is avail.
	mov	bx, handle ActiveFileOpCtrlContDetach
	mov	si, offset ActiveFileOpCtrlContDetach
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	push	bp				; save locals
	call	ObjMessageCallFixup
	pop	bp
	;
	; this is detach-while-active box for file operation, set correct
	; moniker and clear strings in progress area
	;
afterCancel:
	mov	progressSource.handle, handle MoveCopyProgressFrom
	mov	progressSource.chunk, offset MoveCopyProgressFrom
	mov	progressDest.handle, handle MoveCopyProgressTo
	mov	progressDest.chunk, offset MoveCopyProgressTo
	mov	ax, es:[fileOpProgressType]	; ax = progress type
	mov	cx, offset ActiveCopyMoniker	; assume copy
	mov	dx, offset ActiveDestinationMoniker
	cmp	ax, FOPT_COPY
	je	haveActiveFileOpMoniker

	mov	cx, offset ActiveMoveMoniker	; assume move
	mov	dx, offset ActiveDestinationMoniker
	cmp	ax, FOPT_MOVE
	je	haveActiveFileOpMoniker

	mov	progressSource.handle, handle DeleteProgressName
	mov	progressSource.chunk, offset DeleteProgressName
	mov	progressDest.handle, 0
	mov	cx, offset ActiveDeleteMoniker	; assume delete
	mov	dx, offset ActiveEmptyMoniker	; else nothing
	cmp	ax, FOPT_DELETE
	je	haveActiveFileOpMoniker

	mov	cx, offset ActiveEmptyMoniker	; else nothing
	mov	dx, cx
	mov	progressSource.handle, 0	; src = dest = 0
haveActiveFileOpMoniker:
	call	SetActiveFileOpMonikers		; saves locals
	;
	; clear strings in progress area
	;
	call	ClearFileOpActiveProgress	; saves locals
haveTextFields:
	;
	; grab progress text whatever progress box was up and put it into
	; progress fields of detach-while-active box as we'll be putting
	; it that box up and we want it to show some meaningful status
	;
	mov	bx, progressSource.handle
	mov	si, progressSource.chunk
	mov	ax, activeSource.handle
	mov	di, activeSource.chunk
	call	CopyProgressField		; source progress
	mov	bx, progressDest.handle
	mov	si, progressDest.chunk
	mov	ax, activeDest.handle
	mov	di, activeDest.chunk
	call	CopyProgressField		; destination progress
	;
	; set correct text in detach-while-active box
	;
	push	bp				; save locals
	mov	bp, offset activeNoAttn		; bp = no-attn string chunk
	cmp	es:[modalBoxUp], TRUE		; is a modal attn box up?
	je	useAttn				; yes, use attn-req'd string
	cmp	es:[hackModalBoxUp], TRUE	; is file-op-active-app box up?
	jne	afterModal			; nope, use no-attn string
	cmp	es:[fileOpProgressBoxUp], TRUE	; progress box up?
	je	afterModal			; yes, use no-attn string
						; else, use attn-req'd string
useAttn:
	call	EnableFileOpAbort		; else, allow aborting file-op
	mov	bp, offset activeAttn		; ...and use attn-req'd string
afterModal:
	call	SetActiveText			; use in box
	;
	; put up appropriate box, depending on why application is busy
	;
	mov	es:[detachActiveHandling], TRUE		; indicate handling in
							;	progress
	mov	bx, es:[activeBox].handle
	mov	si, es:[activeBox].offset
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageCallFixup
	pop	bp				; retrieve locals
done:
	.leave
	ret
DeskApplicationDetachConfirm	endm

ClearFileOpActiveProgress	proc	near
	push	bp				; save locals

NOFXIP<	mov	dx, cs							>
NOFXIP<	mov	bp, offset nullActiveFileOpProgress			>
FXIP<	mov	dx, NULL						>
FXIP<	push	dx							>
FXIP<	mov	dx, ss							>
FXIP<	mov	bp, sp							>
NOFXIP<	push	dx, bp							>
	mov	si, offset ActiveFileOpSource
	call	CallFixupSetText
NOFXIP<	pop	dx, bp							>
FXIP<	mov	dx, ss							>
FXIP<	mov	bp, sp							>
	mov	si, offset ActiveFileOpDestination
	call	CallFixupSetText
FXIP<	pop	dx							>
	pop	bp				; retrieve locals
	ret
ClearFileOpActiveProgress	endp

;
; bx:si = progress text field in progress box
; ax:di = progress text field in active box
;
CopyProgressField	proc	near
	uses	bp
	.enter
	tst	bx				; no text
	jz	done
	push	ax, di
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; return global buffer
	call	ObjMessageCallFixup		; cx = buffer
	mov	bx, cx				; 
	pop	cx, si				; (preserves flags)

	push	bx
	call	MemLock
	mov	dx, ax				; dx:bp = progress text
	clr	bp
	mov	bx, cx				; bx:si = field in active box
	call	CallFixupSetText
	pop	bx				; free text buffer
	call	MemFree
done:
	.leave
	ret
CopyProgressField	endp

if not _FXIP
LocalDefNLString nullActiveFileOpProgress <0>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationActiveAttention
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change text in active box to tell user that the operation
		that is causing the desktop to be active requires attention
		and that they must either abort detach and continue operation
		or abort operation and continue detach.

CALLED BY:	MSG_APP_ACTIVE_ATTENTION

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationActiveAttention	method	DeskApplicationClass, \
						MSG_APP_ACTIVE_ATTENTION
	;
	; Get dgroup
	;
NOFXIP<	segmov	es, dgroup, bx						>
FXIP  < GetResourceSegmentNS dgroup, es, TRASH_BX			>

	;
	; if file operation is active, enable trigger to allow abort
	; file operation
	;
	call	EnableFileOpAbort
	;
	; if file operation is active, clear file operation progress strings
	; as they are meaningless now
	;
	cmp	es:[activeType], ACTIVE_TYPE_FILE_OPERATION
	jne	afterFileOp
	mov	cx, offset ActiveEmptyMoniker
	mov	dx, cx
	call	SetActiveFileOpMonikers		; clear monikers
	call	ClearFileOpActiveProgress	; clear text
afterFileOp:
	;
	; change text in detach-while-active box
	;
	mov	bp, offset activeAttn		; bp = string chunk
	call	SetActiveText
	ret
DeskApplicationActiveAttention	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetActiveText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "active text" object with the text

CALLED BY:	

PASS:		es:bp - location of optr of text chunk to use
		es	= dgroup

RETURN:		nothing 

DESTROYED:	dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetActiveText	proc near
	uses	bx,si,ds
	.enter
EC <	ECCheckDGroup es						>
	movdw	bxsi, es:[bp]
	call	MemLock
	mov	ds, ax
	mov	dx, ax
	mov	bp, ds:[si]			; dx:bp - string
	push	bx
	movdw	bxsi, es:[activeText]
	call	CallFixupSetText
	pop	bx
	call	MemUnlock
	.leave
	ret
SetActiveText	endp



;
; pass:
;	es = desktop dgroup
;
EnableFileOpAbort	proc	near
EC <	ECCheckDGroup es						>
	cmp	es:[activeType], ACTIVE_TYPE_FILE_OPERATION
	jne	afterFileOp
	mov	bx, handle ActiveFileOpCtrlContDetach
	mov	si, offset ActiveFileOpCtrlContDetach
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
afterFileOp:
	ret
EnableFileOpAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationActive{Continue,Abort}Detach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle response to detach-while-active notification box

CALLED BY:	MSG_ACTIVE_{CONTINUE,ABORT}_DETACH

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationActiveAbortDetach	method	DeskApplicationClass, \
						MSG_APP_ACTIVE_ABORT_DETACH
	push	bx		
NOFXIP<	segmov	es, dgroup, bx						>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	pop	bx

	;
	; tell UI to abort detach
	;
	mov	cx, FALSE			; abort detach
	call	ActiveDetachCommon
	ret
DeskApplicationActiveAbortDetach	endm

DeskApplicationActiveContinueDetach	method	DeskApplicationClass,
					MSG_APP_ACTIVE_CONTINUE_DETACH
	push	bx		
NOFXIP<	segmov	es, dgroup, bx						>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	pop	bx

	;
	; stop whatever operation is in progress
	;
	cmp	es:[activeType], ACTIVE_TYPE_FILE_OPERATION	; file op?
	je	5$				; yes, cancel
	cmp	es:[activeType], ACTIVE_TYPE_DISK_FORMAT	; disk format?
	je	5$				; yes, cancel
	cmp	es:[activeType], ACTIVE_TYPE_DISK_COPY		; disk copy?
	jne	10$				; no, skip
5$:
	mov	es:[cancelOperation], 0xff	; cancel disk format and copy
	mov	es:[detachActiveHandling], FALSE	; needed for
							;	MarkNotActive
	call	MarkNotActive			; mark not active right now,
						;	before telling UI
						;	(okay to mark again,
						;	 later)
10$:
	;
	; tell UI to continue detach
	;
	mov	cx, TRUE			; continue detach
	call	ActiveDetachCommon
	ret
DeskApplicationActiveContinueDetach	endm

;
; pass: cx = TRUE to continue detach
;
ActiveDetachCommon	proc	far
EC <	ECCheckDGroup es						>
	mov	es:[detachActiveHandling], FALSE
	
	mov	ax, SST_CONFIRM_END
	call	SysShutdown
	ret
ActiveDetachCommon	endp

DetachCode	ends

;-----------------------------------------------------------------------------


PseudoResident segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationMarkNotActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close down detach-while-active box if it is up

CALLED BY:	MSG_APP_MARK_NOT_ACTIVE

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationMarkNotActive	method	DeskApplicationClass, \
						MSG_APP_MARK_NOT_ACTIVE
	;
	; Get Dgroup
	;
NOFXIP<	segmov	es, dgroup, bx						>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	;
	; check if detach-while-active box is up
	; if so, bring box down
	;
	cmp	es:[detachActiveHandling], TRUE
	jne	30$				; nope, skip
	push	si
	mov	bx, es:[activeBox].handle
	mov	si, es:[activeBox].offset
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageCallFixup
	pop	si
30$:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListRemove
	
	;
	; check if detach-while-active box WAS up
	; if so, tell UI we can continue detach
	;
	cmp	es:[detachActiveHandling], TRUE
	jne	60$				; nope, skip
	mov	cx, TRUE			; continue detach
	call	ActiveDetachCommon
60$:
	ret
DeskApplicationMarkNotActive	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationMarkActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark our application "active" so we get some say in whether
		to shutdown/suspend

CALLED BY:	MSG_APP_MARK_ACTIVE
PASS:		
RETURN:		cx	= TRUE If app marked active
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationMarkActive method dynamic DeskApplicationClass, 
					MSG_APP_MARK_ACTIVE
	.enter
		CheckHack <DeskApplication_offset eq Gen_offset>
	;
	; Don't do this if app currently shutting down.
	; 
	clr	cx
	test	ds:[di].GAI_states, mask AS_DETACHING or mask AS_QUITTING
	jnz	done

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListAdd
	mov	cx, TRUE
done:
	.leave
	ret
DeskApplicationMarkActive endm


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		DeskApplicationEnsureActiveFT

DESCRIPTION:	This message is subclassed because we want to make sure that
		when the Application object gets the focus/target it checks all
		window that its geode owns regardless of LayerID.  The normal
		superclass handler uses whatever already has the focus/target
		or checks within only the owning geode layer.  By doing this
		preliminary check, when we call the superclass the target is
		already set (by us) or (if we can't find one) does its normal
		routine, which then sets the focus appropriately because one
		place for the focus to default to is the target.

CALLED BY AS OF 2/22/92:
	see superclass handler (OLApplicationEnsureActiveFT)

PASS:		standard object stuff

RETURN:		Nothing

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskApplicationEnsureActiveFT	method dynamic DeskApplicationClass,
						MSG_META_ENSURE_ACTIVE_FT
	.enter

	push	ax, bx, cx, dx, bp, di, si
	mov	di, ds:[si]			; dereference object
	add	di, ds:[di].Vis_offset		; go to Vis Data
	cmp	ds:[di].VCNI_targetExcl.FTVMC_OD.handle, 0
	jne	callTheSuperClass
	;
	; look for the first window owned by the geode to
	; have a WIN_PRIO_STD
	;
	mov	cx, mask GWF_TARGETABLE or (WIN_PRIO_STD shl offset WPD_WIN)
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	ax, bx			; put owning Geode into bx
	clr	bx					; any layer
	;
	; following two routines are the copies of the internal UI routines
	; in the file /Library/CommonUI/CUtils/copenSystem.asm.  They have
	; 'NewDesk' prepended to them for clarity.
	;
	mov	di, ds:[di].VCI_window
	call	NewDeskFindWinOnWin
	tst	cx
	jz	callTheSuperClass			; if no window found

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	mov	bx, cx
	mov	si, dx					; have obj grab target
	call	ObjMessageCallFixup

callTheSuperClass:
	pop	ax, bx, cx, dx, bp, di, si
	;
	; The focus will be set accordingly or will default to the target obj
	;
	mov	di, offset DeskApplicationClass
	call	ObjCallSuperNoLock

	.leave
	ret
NewDeskApplicationEnsureActiveFT	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	NewDeskFindWinOnWin

DESCRIPTION:	Looks through all child windows of the passed window, looking
		for the first one matching the description passed.

CALLED BY:	INTERNAL

PASS:		*ds:si	- system object
		ax	- Owning geode of window to look for (or 0 for any)
		bx	- LAYER ID of window to look for (or 0 for any)
		cl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		ch	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.
			  NOTE:  GenFieldClass objects run by the UI are
				 exempted from this check, as we always wish
				 for them to be focusable & targetable even
				 though their owning app, the UI app, is not.
		di	- Window whose children we are to look at (or 0 if
			  no window, in which case return values will indicate
			  nothing found)

RETURN:		cx:dx	- set to InputOD of first such window
			else 0:0
		bp	- handle of window, else 0

DESTROYED:	nothing
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
	dlitwin	8/13/92		copied from UI internal routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskFindWinOnWin	proc	near
	uses	ax, bx, si, di
	.enter

	tst	di
	jz	nullDone

	push	cx
	call	NewDeskCreateChunkArrayOnWindows

					; We now have a list of the windows
					; belonging to this app, in *ds:si
	clr	cx			; Haven't found one yet.

	pop	dx			; Get priority to look for, in dl
	mov	bx, cs
	mov	di, offset NewDeskFindWinOfPrioInChunkArrayCallBack
	call	ChunkArrayEnum

	tst	cx			; if no handle returned,
	jnz	10$
	clr	dx			; return NULL for chunk as well
	clr	bp			; return NULL for window as well
10$:
					; cx:dx is result, if any
	mov	ax, si
	call	LMemFree

done:
	.leave
	ret

nullDone:
	clr	cx
	clr	dx
	clr	bp
	jmp	short done

NewDeskFindWinOnWin	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	NewDeskCreateChunkArrayOnWindows

DESCRIPTION:	Creates a list of the top-most child of a given window which
		meets the following criteria:

			* Has LayerID equal to that passed

CALLED BY:	INTERNAL

PASS:		*ds:si	- Object whose block we can use for a temp chunk 
		ax	- owner of window we're looking for (or 0 for any)
		bx	- LAYER ID of window we're looking for (or 0 for any)
		di	- parent window whose children we should check

RETURN:		*ds:si	- chunk array

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	dlitwin	8/13/92		copied from UI internal routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskCreateChunkArrayOnWindows	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter
	push	ax, bx			; owner, layerID

	clr	al			; basic chunk.  we're going to nuke
					; later anyway
	mov	bx, size hptr
	clr	cx
	mov	si, cx
	call	ChunkArrayCreate
	mov	bp, si			; *ds:bp is chunk array

	; cx = 0 at this point
	pop	ax, dx			; owner, layerID

	mov	bx, SEGMENT_CS		; bx <- vseg if XIP'ed
	mov	si, offset NewDeskCreateChunkArrayOnWindowsInLayerCallBack
	push	ds:[LMBH_handle]	;Save handle of segment for fixup later
	call	WinForEach		;Does not fixup DS!
	pop	bx
	call	MemDerefDS		;Fixup LMem segment
					; We now have a list of the windows
					; belonging to this app, in *ds:bp
	mov	si, bp			; pass chunk array in *ds:si
	.leave
	ret
NewDeskCreateChunkArrayOnWindows	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	NewDeskCreateChunkArrayOnWindowsInLayerCallBack

DESCRIPTION:	Fill chunk array passed with windows of the given layer
		which are children of the initial window passed

CALLED BY:	INTERNAL
			GenFindTopModalWin

PASS:
	di	- window handle to process
	ax	- owner we're looking for, or zero for any
	cx	- flag:  0 if first (parent) window
	dx	- layer ID we're looking for, or zero for any
	*ds:bp	- chunk array

RETURN:
	carry set	- if done, else:
	di	- next window to do

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
	dlitwin	8/13/92		copied from UI internal routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskCreateChunkArrayOnWindowsInLayerCallBack	proc	far
	uses	ax
	.enter
	tst	cx			; is this the parent window?
	jz	findFirstChild		; if so, branch to get first child

	; See if correct owner
	tst	ax
	jz	afterOwner
	mov	bx, di
	call	MemOwner
	cmp	bx, ax
	jne	doNext

afterOwner:
	; See if in correct layer
	;
	tst	dx
	jz	thisOneOK
	mov	si, WIT_LAYER_ID
	call	WinGetInfo
	cmp	ax, dx			; a match?
	jne	doNext			; if not, skip to do next

thisOneOK:
	push	di
	mov	si, bp			; put chunk array in ds:si
	call	ChunkArrayAppend	; add a new entry in array
					; ds:di = ptr to new element
	mov	si, di			; ds:si = ptr to new element
	pop	di
	mov	ds:[si], di		; store window handle
doNext:
	mov	si, WIT_NEXT_SIBLING_WIN; do next sibling next.
	jmp	short done

findFirstChild:
	mov	si, WIT_FIRST_CHILD_WIN	; fetch first child of this parent win
done:
	call	WinGetInfo
	mov	di, ax			; make that the next window we do
	mov	cx, -1			; not doing parent win
	clc				; keep going until null window
	.leave
	ret

NewDeskCreateChunkArrayOnWindowsInLayerCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	NewDeskFindWinOfPrioInChunkArrayCallBack

DESCRIPTION:	Searches the in the chunk array passed, looking for
		a window that matches the passed description

CALLED BY:	INTERNAL

PASS:		*ds:si	- chunk array
		ds:di	- element to process
		dl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		dh	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.

RETURN:		carry set if found, &
		^lcx:dx	- InputOD of window willing to take modal excl.
		^hbp	- window
		ELSE carry clear, cx=0

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	dlitwin	8/13/92		copied from UI internal routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewDeskFindWinOfPrioInChunkArrayCallBack	proc	far	uses	si, di
	.enter

	mov	di, ds:[di]			; get window
	mov	si, WIT_PRIORITY		; Look for MODAL priority window

	call	WinGetInfo
	test	dl, mask WPD_WIN
	jnz	compareWinPrio
	and	al, not mask WPD_WIN
compareWinPrio:
	test	dl, mask WPD_LAYER
	jnz	compareLayerPrio
	and	al, not mask WPD_LAYER
compareLayerPrio:
	cmp	al, dl
	jne	skip

	tst	dh				; If no focusable/targetable
	jz	gotOne				; restrictions, continue
	mov	bx, di
	call	MemOwner			; get owning process
	call	WinGeodeGetFlags		; get GeodeWinFlags for that
						;	geode, in AX
	and	ah, dh
	cmp	ah, dh
	je	gotOne				; if flags meet spec, got it!

	; Otherwise, handle execption case of GenField objects
	;
	push	dx
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	call	NewDeskTestIfCXDXGenFieldObject
	jnc	skipPopDX			; if not GenField, skip out

	; If it is a GenField, check to see if it is focusable/targetable in
	; a somewhat different manner -- see if some object within it has
	; the same exclusive.
	;
	test	ax, mask GWF_FOCUSABLE		; looking for focusable?
	mov	ax, MSG_META_GET_FOCUS_EXCL	; if so, query for focus
	jnz	haveQueryMesssage
	mov	ax, MSG_META_GET_TARGET_EXCL	; otherwise, check for target
haveQueryMesssage:
	mov	bx, cx
	mov	si, dx
	push	di
	call	ObjMessageCallFixup		; ask it -- who's got it?
	pop	di
	tst	cx				; anyone?
	jz	skipPopDX			; if not, doesn't qualify.

	pop	dx

gotOne:
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	mov	bp, di

	stc					; Indicate found
	jmp	short done

skipPopDX:
	pop	dx
skip:
	clr	cx				; return CX = 0
	clc					; go on to do next.
done:
	.leave
	ret
NewDeskFindWinOfPrioInChunkArrayCallBack	endp



;
; This is a copy if the UI's internal routine TestIf CXDXGenFieldObject
;
NewDeskTestIfCXDXGenFieldObject	proc	near
					; Returns carry set if cx:dx is 
					; GenField object run by current thread.
	tst	cx
	jz	notGenField

	push	bx
	mov	bx, cx
	call	ObjTestIfObjBlockRunByCurThread
	pop	bx
	jne	notGenField		; If run by a different thread, can't
					; test.  GenField's are all run by
					; global UI thread, so this shouldn't be
					; a problem.

	; If run by the same thread, check to see if a GenField object
	;
	push	bx, si, di, es
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	mov	di, segment GenFieldClass
	mov	es, di
	mov	di, offset GenFieldClass
	call	ObjIsObjectInClass
	call	ObjSwapUnlock
	pop	bx, si, di, es
	ret

notGenField:
	clc
	ret
NewDeskTestIfCXDXGenFieldObject	endp


endif		; if _NEWDESK
PseudoResident	ends

;-----------

PseudoResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	on ZMGR, fake UIFA_MOVE_COPY if doing quick-transfer

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_PTR

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/12/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DeskApplicationPtr	method	dynamic	DeskApplicationClass, MSG_META_PTR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	callSuper

	;
	; although fileDragging may indicate quick-transfer in progress,
	; we may just be waiting for the folder object to get the end-select
	; via the process from the GenView - brianc 6/28/93
	;
	tst	es:[delayedFileDraggingEnd]
	jnz	callSuper			; we are waiting, move-copy
						;	not in progress
						; otherwise, is move-copy

	test	es:[fileDragging], mask FDF_FAKE_COPY
	jz	not1
	ornf	bp, mask UIFA_COPY shl 8
not1:
	test	es:[fileDragging], mask FDF_FAKE_MOVE
	jz	not2
	ornf	bp, mask UIFA_MOVE shl 8
not2:
	ornf	bp, mask UIFA_MOVE_COPY shl 8
	andnf	bp, not mask UIFA_SELECT shl 8
callSuper:
	segmov	es, <segment DeskApplicationClass>, bx
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationPtr	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On ZMGR, fake UIFA_MOVE and UIFA_COPY

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_KBD_CHAR

		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState (sic?)
		bp high = scan code (sic)

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/26/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ZMGR	; _PEN_BASED

DeskApplicationKbdChar	method	dynamic	DeskApplicationClass, MSG_META_KBD_CHAR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	al, es:[fileDragging]	; save for checking for changes
	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	callSuper
	test	dh, mask SS_FIRE_BUTTON_2
	jz	not1
	test	dl, mask CF_FIRST_PRESS
	jnz	set1
	test	dl, mask CF_RELEASE
	jz	not1
	andnf	es:[fileDragging], not mask FDF_FAKE_COPY
	jmp	short not1
set1:
	ornf	es:[fileDragging], mask FDF_FAKE_COPY
not1:
	test	dh, mask SS_FIRE_BUTTON_1
	jz	not2
	test	dl, mask CF_FIRST_PRESS
	jnz	set2
	test	dl, mask CF_RELEASE
	jz	not2
	andnf	es:[fileDragging], not mask FDF_FAKE_MOVE
	jmp	short not2
set2:
	ornf	es:[fileDragging], mask FDF_FAKE_MOVE
not2:
callSuper:
	cmp	al, es:[fileDragging]		; any chagnes?
	jz	noChanges			; nope
	call	ImForcePtrMethod		; changes made, force ptr
						;	to update cursor
	ret			; THEN, eat the kbd event
				; <-- EXIT HERE

noChanges:
	segmov	es, <segment DeskApplicationClass>, ax
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationKbdChar	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On BMGR, fake UIFA_MOVE and UIFA_COPY

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_KBD_CHAR

		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState (sic?)
		bp high = scan code (sic)

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/24/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _BMGR	; _PEN_BASED

DeskApplicationKbdChar	method	dynamic	DeskApplicationClass, MSG_META_KBD_CHAR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	al, es:[fileDragging]	; save for checking for changes
	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	noChanges
	cmp	ch, VC_ISCTRL		; control char?
	jne	noChanges		; nope
	cmp	cl, VC_LCTRL		; left ctrl?
	je	checkCtrlUpDown		; yes, handle
	cmp	cl, VC_RCTRL		; right ctrl?
	jne	notCtrl			; nope, check ALT
checkCtrlUpDown:
	test	dl, mask CF_FIRST_PRESS
	jnz	setCtrl
	test	dl, mask CF_RELEASE
	jz	notCtrl
	andnf	es:[fileDragging], not mask FDF_FAKE_COPY
	jmp	short notCtrl
setCtrl:
	ornf	es:[fileDragging], mask FDF_FAKE_COPY
notCtrl:
	cmp	cl, VC_LALT		; left alt?
	je	checkAltUpDown		; yes, handle
	cmp	cl, VC_RALT		; right alt?
	jne	notAlt			; nope
checkAltUpDown:
	test	dl, mask CF_FIRST_PRESS
	jnz	setAlt
	test	dl, mask CF_RELEASE
	jz	notAlt
	andnf	es:[fileDragging], not mask FDF_FAKE_MOVE
	jmp	short notAlt
setAlt:
	ornf	es:[fileDragging], mask FDF_FAKE_MOVE
notAlt:
	cmp	al, es:[fileDragging]		; any chagnes?
	jz	noChanges			; nope
	call	ImForcePtrMethod		; changes made, force ptr
						;	to update cursor
	ret			; THEN, eat the kbd event
				; <-- EXIT HERE

noChanges:
	segmov	es, <segment DeskApplicationClass>, ax
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationKbdChar	endm

endif

ifdef GPC	; _PEN_BASED

DeskApplicationKbdChar	method	dynamic	DeskApplicationClass, MSG_META_KBD_CHAR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	al, es:[fileDragging]	; save for checking for changes
	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	noChanges
if DBCS_PCGEOS
	cmp	cx, C_SYS_LEFT_CTRL	; left ctrl?
	je	checkCtrlUpDown		; yes, handle
	cmp	cx, C_SYS_RIGHT_CTRL	; right ctrl?
	jne	notCtrl			; nope, check ALT
else
	cmp	ch, VC_ISCTRL		; control char?
	jne	noChanges		; nope
	cmp	cl, VC_LCTRL		; left ctrl?
	je	checkCtrlUpDown		; yes, handle
	cmp	cl, VC_RCTRL		; right ctrl?
	jne	notCtrl			; nope, check ALT
endif
checkCtrlUpDown:
	test	dl, mask CF_FIRST_PRESS
	jnz	setCtrl
	test	dl, mask CF_RELEASE
	jz	notCtrl
	andnf	es:[fileDragging], not mask FDF_FAKE_COPY
	jmp	short notCtrl
setCtrl:
	ornf	es:[fileDragging], mask FDF_FAKE_COPY
notCtrl:
if DBCS_PCGEOS
	cmp	cx, C_SYS_LEFT_ALT	; left alt?
	je	checkAltUpDown		; yes, handle
	cmp	cx, C_SYS_RIGHT_ALT	; right alt?
	jne	notAlt			; nope
else
	cmp	cl, VC_LALT		; left alt?
	je	checkAltUpDown		; yes, handle
	cmp	cl, VC_RALT		; right alt?
	jne	notAlt			; nope
endif
checkAltUpDown:
	test	dl, mask CF_FIRST_PRESS
	jnz	setAlt
	test	dl, mask CF_RELEASE
	jz	notAlt
	andnf	es:[fileDragging], not mask FDF_FAKE_MOVE
	jmp	short notAlt
setAlt:
	ornf	es:[fileDragging], mask FDF_FAKE_MOVE
notAlt:
	cmp	al, es:[fileDragging]		; any chagnes?
	jz	noChanges			; nope
	call	ImForcePtrMethod		; changes made, force ptr
						;	to update cursor
	ret			; THEN, eat the kbd event
				; <-- EXIT HERE

noChanges:
	segmov	es, <segment DeskApplicationClass>, ax
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationKbdChar	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On BMGR, ignore Alt-ESC if doing file linking

CALLED BY:	MSG_META_FUP_KBD_CHAR

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_FUP_KBD_CHAR

		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState (sic?)
		bp high = scan code (sic)

RETURN:		carry set if key handled

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/23/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _KEEP_MAXIMIZED and _CONNECT_TO_REMOTE

DeskApplicationFupKbdChar	method	dynamic	DeskApplicationClass,
							MSG_META_FUP_KBD_CHAR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	cmp	es:[connection], CT_FILE_LINKING
	jne	callSuper
	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		; skip if not press event
	test	dh, mask SS_LALT or mask SS_RALT
	jz	callSuper
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_ESCAPE			>
DBCS <	cmp	cx, C_SYS_ESCAPE					>
	jne	callSuper
	;
	; put up error box
	;
	mov	cx, ERROR_RFSD_ACTIVE_2
	mov	ax, MSG_REMOTE_ERROR_BOX
	mov	bx, handle 0
	call	ObjMessageForce
	stc				; handled
	ret				; <-- EXIT HERE

callSuper:
	segmov	es, <segment DeskApplicationClass>, ax
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationFupKbdChar	endm

endif ; _KEEP_MAXIMIZED and _CONNECT_TO_REMOTE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On ZMGR, fake UIFA_MOVE and UIFA_COPY

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_END_SELECT

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive


RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/26/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DeskApplicationEndSelect	method	dynamic	DeskApplicationClass,
							MSG_META_END_SELECT

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	callSuper
	test	es:[fileDragging], mask FDF_FAKE_COPY
	jz	not1
	ornf	bp, mask UIFA_COPY shl 8
not1:
	test	es:[fileDragging], mask FDF_FAKE_MOVE
	jz	not2
	ornf	bp, mask UIFA_MOVE shl 8
not2:
callSuper:
	;
	; If we are doing a start select move-copy, then if we don't have
	; an active mouse grab, about the quick-transfer as we'll end
	; up converting to an END_OTHER, which may or may not be handled
	; - brianc 6/25/93
	;
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	jz	reallyCallSuper			; not doing quick-transfer
	call	VisCheckIfVisGrown
	jnc	reallyCallSuper			; not grown
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VCNI_activeMouseGrab.VMG_object.handle
	jnz	reallyCallSuper			; have active grab, A-OK
	call	SendAbortQuickTransfer		; else, abort via process
reallyCallSuper:
	segmov	es, <segment DeskApplicationClass>, di
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationEndSelect	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationEndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	on ZMGR, if doing START_SELECT quick transfer and we get
		an END_OTHER it means we got an END_SELECT with no
		active grab (some timing problem with the user doing some
		quick-transfer really quickly), just stop the quick-transfer

CALLED BY:	MSG_META_END_OTHER

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		es 	= segment of DeskApplicationClass
		ax	= MSG_META_END_OTHER

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/24/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DeskApplicationEndOther	method	dynamic	DeskApplicationClass, MSG_META_END_OTHER

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	jz	callSuper
	call	SendAbortQuickTransfer
callSuper:
	segmov	es, <segment DeskApplicationClass>, di
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

DeskApplicationEndOther	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When app loses sys target make sure popup menu is closed.

CALLED BY:	MSG_META_LOST_TARGET_EXCL
PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DeskApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This should work since all UI objects are run by
		a single thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESK	;--------------------------------------------------------------

DeskApplicationLostTargetExcl	method dynamic DeskApplicationClass, 
					MSG_META_LOST_TARGET_EXCL
	mov	di, offset DeskApplicationClass
	call	ObjCallSuperNoLock

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	bx, es:[popupMenu].handle
	tst	bx
	jz	done

	mov	si, es:[popupMenu].offset
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageCall
done:
	ret
DeskApplicationLostTargetExcl	endm

endif		;--------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclassed to prevent other applications from being started
		while doing file linking

CALLED BY:	MSG_META_NOTIFY

PASS:		*ds:si	= DeskApplication object
		ds:di	= DeskApplication instance data
		es 	= segment of DeskApplication
		ax	= MSG_META_NOTIFY

		cx:dx - NotificationType
			cx - NT_manuf
			dx - NT_type
		bp - change specific data

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/14/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CONNECT_TO_REMOTE

DeskApplicationNotify	method dynamic DeskApplicationClass, MSG_META_NOTIFY

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	cmp	es:[connection], CT_FILE_LINKING
	jne	callSuper

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	cmp	dx, GWNT_STARTUP_INDEXED_APP
	je	preventLaunching
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	jne	callSuper
	cmp	bp, HIBF_TOGGLE_EXPRESS_MENU
	je	preventLaunching

callSuper:
	segmov	es, <segment DeskApplicationClass>, di
	mov	di, offset DeskApplicationClass
	GOTO	ObjCallSuperNoLock

preventLaunching:
	;
	; must put up error message from process thread
	;
	mov	cx, ERROR_RFSD_ACTIVE
	mov	ax, MSG_REMOTE_ERROR_BOX
	mov	bx, handle 0
	GOTO	ObjMessageForce

DeskApplicationNotify	endm

endif

PseudoResident	ends

;-----------------------

FolderObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationChangeIconChangeToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to process to handle change icon.

CALLED BY:	MSG_APP_CHANGE_ICON_CHANGE_TOKEN
PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DeskApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationChangeIconChangeToken	method dynamic DeskApplicationClass, 
					MSG_APP_CHANGE_ICON_CHANGE_TOKEN
	mov	ax, MSG_FM_END_CHANGE_TOKEN
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE or \
		    mask MF_CHECK_DUPLICATE or mask MF_REPLACE
	GOTO	ObjMessage

DeskApplicationChangeIconChangeToken	endm

FolderObscure	ends


InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationGenLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	fetch features from .INI file.

PASS:		*ds:si	- DeskApplicationClass object
		ds:di	- DeskApplicationClass instance data
		es	- segment of DeskApplicationClass
		ss:bp	- GenOptionsParams
RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeskApplicationGenLoadOptions	method	dynamic	DeskApplicationClass, 
					MSG_GEN_LOAD_OPTIONS
		push	ds, si
		mov	cx, ss
		mov	ds, cx
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		clr	ax		; assume no features
		call	InitFileReadInteger
		pop	ds, si

		mov_tr	cx, ax
		mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
		GOTO	ObjCallInstanceNoLock

DeskApplicationGenLoadOptions	endm


if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationMetaLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- DeskApplicationClass object
		ds:di	- DeskApplicationClass instance data
		es	- segment of DeskApplicationClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _ZMGR

DeskApplicationMetaLoadOptions	method	dynamic	DeskApplicationClass, 
					MSG_META_LOAD_OPTIONS

		mov	di, offset DeskApplicationClass
		call	ObjCallSuperNoLock

		mov	bx, handle OptionsDrivesList	
		mov	si, offset OptionsDrivesList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessageCallFixup	; ax = DriveButtonLocations
		jnc	haveSelection
		mov	al, DRIVES_SHOWING	; else, use default
haveSelection:
		mov	cl, al			; cl = DriveButtonLocations
		mov	ax, MSG_TA_SET_DRIVE_LOCATION
		mov	bx, handle FloatingDrivesDialog
		mov	si, offset FloatingDrivesDialog
		call	ObjMessageNone

		ret
DeskApplicationMetaLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationUpdateAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the features using the tables, etc.

PASS:		*ds:si	- DeskApplicationClass object
		ds:di	- DeskApplicationClass instance data
		es	- segment of DeskApplicationClass
		ss:bp	- GenAppUpdateFeaturesParams
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _FXIP
TableResourceXIP	segment resource
endif

if _CONNECT_TO_REMOTE
deskAppFeaturesTable	fptr \
	connectTable	; DF_CONNECT
; When you add other DesktopFeatures, add offsets to tables here
endif


connectTable	label	GenAppUsabilityTuple
if _CONNECT_TO_REMOTE
if _CONNECT_ICON
	GenAppMakeUsabilityTuple ConnectionConnect
endif ; _CONNECT_ICON
if not _CONNECT_MENU
	GenAppMakeUsabilityTuple DiskMenuFileLinking, end
endif ; (not _CONNECT_MENU)
endif ; _CONNECT_TO_REMOTE

if _FXIP
TableResourceXIP	ends
endif

if _CONNECT_TO_REMOTE

DeskApplicationUpdateAppFeatures	method	dynamic	DeskApplicationClass, 
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

NOFXIP<		mov	ss:[bp].GAUFP_table.segment, cs			   >
FXIP<		mov	ss:[bp].GAUFP_table.segment, vseg TableResourceXIP >

		mov	ss:[bp].GAUFP_table.offset, offset deskAppFeaturesTable
		mov	ss:[bp].GAUFP_tableLength, length deskAppFeaturesTable
		clrdw	ss:[bp].GAUFP_levelTable
		clrdw	ss:[bp].GAUFP_reparentObject
		clrdw	ss:[bp].GAUFP_unReparentObject
		mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
		GOTO	ObjCallInstanceNoLock 

DeskApplicationUpdateAppFeatures	endm

endif

endif		; !_ZMGR
endif		; if _GMGR

if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskApplicationOptionsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_GEN_APPLICATION_OPTIONS_CHANGED to app obj

CALLED BY:	MSG_APP_OPTIONS_CHANGED

PASS:		*ds:si	= DeskApplicationClass object
		ds:di	= DeskApplicationClass instance data
		ds:bx	= DeskApplicationClass object (same as *ds:si)
		es 	= segment of DesktopClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	3/19/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskApplicationOptionsChanged	method DeskApplicationClass, 
					MSG_APP_OPTIONS_CHANGED
	.enter

	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	exit			; no change when attaching
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	ObjCallInstanceNoLock
exit:

	.leave
	ret
DeskApplicationOptionsChanged	endm

endif

InitCode	ends
