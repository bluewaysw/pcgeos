COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Spool/UI
FILE:		uiSpoolSummons.asm

AUTHOR:		Don Reeves, March 30, 1990

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/89		Initial revision


DESCRIPTION:
	Containts the procedures and method handlers that define that action
	of the SpoolSummons class.
		
	$Id: uiSpoolSummons.asm,v 1.2 98/01/27 21:29:01 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to InteractionCommand's

CALLED BY:	GLOBAL (MSG_GEN_GUP_INTERACTION_COMMAND)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		CX	= InteractionCommand

RETURN:		Nothing

DESTROYED:	see message documentation

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGenGupInteractionCommand	method dynamic	SpoolSummonsClass,
					MSG_GEN_GUP_INTERACTION_COMMAND

		; If we are dimissing, ensure we destroy Print & Options UI
		;
		CheckHack <IC_NULL eq 0>
		CheckHack <IC_DISMISS eq 1>
		cmp	cx, IC_DISMISS		; jump if not IC_NULL nor
		ja	callSuperClass		; ...IC_DISMISS
		push	ax, cx, dx, bp, si
		mov	si, offset PrinterChangeBox
		mov	cx, IC_RESET		; send RESET, to clear out
		call	ObjCallInstanceNoLock	; ...any changes to options
		pop	ax, cx, dx, bp, si
callSuperClass:
		mov	di, offset SpoolSummonsClass
		GOTO	ObjCallSuperNoLock
SpoolSummonsGenGupInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsInitiateInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up some things before the window appears

CALLED BY:	UI (MSG_GEN_INTERACTION_INITIATE)

PASS:		ES	= Segment of SpoolSummonsClass
		DS:*SI	= SpoolSummons instance data

RETURN:		carry set on error

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version
	Don	4/18/91		Hopefully eliminated redundant code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsInteractionInitiate	method	SpoolSummonsClass,
					MSG_GEN_INTERACTION_INITIATE

	test	ds:[di].SSI_printAttrs, mask PCA_USES_DIALOG_BOX
	jnz	openWindow			; => we'll get a VIS_OPEN, and
						;  will initialize ourselves
						;  then

	; Initialize all the printer stuff, if necessary
	;
	call	SpoolSummonsInitialize		; load any necessary info
	jc	done				; if error, we're done

	; Send method to print trigger to automatically print
	;
	mov	cx, ds:[di].SSI_appDefPrinter	; default printer # => CX
	cmp	cx, -1				; no default printer ??
	jne	compareDefault
	mov	cx, ds:[di].SSI_sysDefPrinter	; else use system default
compareDefault:
	cmp	cx, ds:[di].SSI_currentPrinter	; compare current with default
	je	printNow			; if same, print now
	push	cx				; save the default printer
	call	SpoolSummonsGetPrinterInfo	; get information on printer
	pop	cx				; restore the default printer
	test	dh, mask SSPI_VALID		; valid printer ??
	jz	printNow			; if not, print with current
	call	SpoolSummonsForcePrinter	; select printer number in CX

	; Print w/o bringing up the dialog box
printNow:
	call	InitPaperSize			; re-initialize the paper size
						; ...to ensure it matches the
						; ...current default size
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	si, offset PrintUI:PrintToFileTrigger
	test	ds:[di].SSI_printerInfo, mask SSPI_PRINT_TO_FILE
	jnz	printNowReally
	mov	si, offset PrintUI:PrintOKTrigger
printNowReally:	
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION ; want to activate printing
	mov	bx, ds:[LMBH_handle]		; BX:SI is the OD of the trigger
	mov	di, mask MF_FORCE_QUEUE		; send via the queue
	GOTO	ObjMessage			; send the method

	; Finish the initiate interaction
openWindow:
	mov	di, offset SpoolSummonsClass	; ES:DI points to my class
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallSuperNoLock		; call my superclass
	clc
done:
	ret
SpoolSummonsInteractionInitiate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the SpoolSummons dialog box

CALLED BY:	SpoolSummonsInitiateInteraction
	
PASS:		DS:*SI	= SpoolSummonsClass object

RETURN:		DS:DI	= SpoolSummonsInstance
		Carry	= Clear if no problem
			= Set if problem (no printers, or none are usable)

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsInitialize	proc	near
	class	SpoolSummonsClass

	;
	; Grab gobs of stack to prevent EC-only death when opening the 
	; printer dialog for the ccom driver 
	;
EC <	mov	di, 1500			>
EC <	call	ThreadBorrowStackSpace		>
EC <	push	di				>

	; Re-load the printer stuff, if necessary
	;
	call	SpoolSummonsLoadPrinters	; load them printers
	pushf					; save results
	mov	cx, PCERR_NO_PRINTERS		; assume no printers available
	tst	ds:[di].SSI_numPrinters		; any printers ??
	jz	error
	mov	cx, PCERR_ALL_BAD_PRINTERS	; assume all printers are bad
	tst	ds:[di].SSI_numValidPrinters	; any valid printers ??
	jnz	checkReset
error:
	popf
	mov	ax, MSG_PRINT_CANNOT_PRINT
	push	si
	movdw	bxsi, ds:[OLMBH_output]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	stc
	jmp	enableDisable

	; See if we can print with the currently known printers
checkReset:
	popf					; reset selection ??
	jnc	done				; no, so do nothing

	; Tell the dynamic list to reset itself
	;
	push	dx, si				; save printer, chunk handle
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, ds:[di].SSI_numPrinters	; number of printers => CX
	mov	si, offset PrintUI:PrinterChoice
	call	ObjCallInstanceNoLock		; initilize the list
	pop	cx, si				; restore printer, chunk handle
	call	SpoolSummonsForcePrinter
done:
	mov	ax, MSG_GEN_SET_ENABLED
	clc	

enableDisable:
	pushf
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	popf

EC <	mov_tr	ax, di							>
EC <	pop	di							>
EC <	call	ThreadReturnStackSpace					>
EC <	mov_tr	di, ax							>
	ret
SpoolSummonsInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsForcePrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a specific printer to be selected

CALLED BY:	SpoolSummonsInitiateInteraction, SpoolSummonsInitialize
	
PASS:		DS:*SI	= SpoolSummonsClass object
		CX	= Printer to select

RETURN:		DS:DI	= SpoolSummonsInstance

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsForcePrinter	proc	near
	.enter

	; Reset the printer selection (DS:*SI is the SpoolSummonsClass object)
	;
	push	si
	mov	si, offset PrintUI:PrinterChoice
	call	SSSetItemSelectionStatus
	pop	si				; restore SpoolSummons chunk
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data

	.leave
	ret
SpoolSummonsForcePrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize ourselves

CALLED BY:	MSG_SPOOL_SUMMONS_INITIALIZE
PASS:		*ds:si	= SpoolSummons object
		ds:di	= SpoolSummonsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSInitialize	method dynamic SpoolSummonsClass, MSG_SPOOL_SUMMONS_INITIALIZE
		.enter
		call	SpoolSummonsInitialize
		.leave
		ret
SSInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the OD that the dialog box is entering the screen

CALLED BY:	UI (MSG_VIS_OPEN)

PASS:		DS:*SI	= SpoolSummons class
		DS:DI	= SpoolSummons specific instance data
		ES	= Segment of SpoolSummons class
		BP	= window on which to open (or 0 if top window)

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsVisOpen	method	SpoolSummonsClass,	MSG_VIS_OPEN

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SPOOL_SUMMONS_INITIALIZE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

	; Send the method; finish the open
	;
	mov	ax, MSG_VIS_OPEN
	mov	bx, PCS_PRINT_BOX_VISIBLE
	GOTO	NotifyOD
SpoolSummonsVisOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the OD that we are leaving the screen

CALLED BY:	UI (MSG_VIS_CLOSE)

PASS:		DS:*SI	= SpoolSummons class
		DS:DI	= SpoolSummons specific instance data
		ES	= Segment of SpoolSummons class

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsVisClose	method	SpoolSummonsClass,	MSG_VIS_CLOSE

	; Send the method; finish the close
	;
	mov	bx, PCS_PRINT_BOX_NOT_VISIBLE
	FALL_THRU	NotifyOD
SpoolSummonsVisClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the OD of the impending on/off screen

CALLED BY:	SpoolSummonsVisOpen, SpoolSummonsVisClose

PASS:		*DS:SI	= SpoolSummons class
		DS:DI	= SpoolSummonsInstance
		ES	= Segment of SpoolSummons class
		BX	= PrintControlStatus

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NotifyOD	proc	far
	class	SpoolSummonsClass

	; Get the output OD
	;
	push	bp, ax, si			; save bp, message and chunk
						;  handle
	mov	bp, bx				; bp <- status 
	mov	ax, MSG_PRINT_CONTROL_GET_OUTPUT
	call	ObjBlockGetOutput		; PrintControl OD => BX:SI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage			; output OD => CX:DX
	
	; Now send a message to that OD
	;
	pop	ax				; SpoolSummons OD => *DS:AX
	push	cx, dx				; destination optr => stack
	mov	cx, bx
	mov	dx, si				; PrintControl OD => CX:DX
	mov_tr	si, ax				; SpoolSummons OD => *DS:SI
	mov	ax, MSG_PRINT_NOTIFY_PRINT_DB
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	GenProcessAction		; send off the message

	; Now finish the message we began
	;
	pop	bp, ax				; restore bp & message
	mov	di, offset SpoolSummonsClass
	GOTO	ObjCallSuperNoLock
NotifyOD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsVisUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure everything is cleaned up as we visually shut down

CALLED BY:	UI (MSG_SPEC_UNBUILD)

PASS:		ES	= Segment of SpoolSummonsClass
		DS:*SI	= SpoolSummons instance data
		DS:DI	= SpoolSummons specific instance data
		BP	= SpecBuild flags

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsVisUnbuild	method	SpoolSummonsClass, MSG_SPEC_UNBUILD

	; Clean up, and then pass on the message
	;
	call	SpoolSummonsCleanUp		; clean up any & all
	mov	di, offset SpoolSummonsClass	; ES:DI => ClassStruc
	GOTO	ObjCallSuperNoLock		; call my superclass
SpoolSummonsVisUnbuild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up any merory allocation

CALLED BY:	INTERNAL, method from SpoolPrintControl
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveFromGCNList	proc	near
	push	bx, si
	mov	si, dx
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, ax
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListParams
	pop	bx, si
	ret
RemoveFromGCNList	endp

SpoolSummonsCleanUp	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_CLEAN_UP
	.enter

	; Remove any memory handles
	;
	clr	bx				; store a zero value
	xchg	bx, ds:[di].SSI_printDataHan	; printer data => BX
	tst	bx				; any handle ??
	jz	none				; no - finish up
	call	MemFree				; else free the block

	; Remove any displayed UI
none:
	mov	ax, ds:[di].SSI_currentPrinter
	mov	ds:[di].SSI_backupPrinter, ax
	mov	ax, -1				; no new current printer
	mov	ds:[di].SSI_currentPrinter, ax
	call	InitPrinterUI			; remove the printer UI

	; Remove controller from active list
	;
	mov	dx, offset PrinterPageSizeControl
	mov	ax, MGCNLT_ACTIVE_LIST
	call	RemoveFromGCNList

	; Remove dialog from window list
	;
	mov	dx, offset PrinterChangeBox
	mov	ax, GAGCNLT_WINDOWS
	call	RemoveFromGCNList

	; Remove any cached drivers
	;
	mov	bx, FREE_DRIVER_IMMEDIATELY	; leave exit marker
	call	SpoolFreeDriver			; free cached driver
	call	DeletePrinterUIState

	.leave
	ret
SpoolSummonsCleanUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolChangeInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that change dialog box is coming up on screen

CALLED BY:	GLOBAL (MSG_GEN_INTERACTION_INITIATE)

PASS:		*DS:SI	= SpoolChangeClass object
		DS:DI	= SpoolChangeClassInstance
		see MSG_GEN_INTERACTION_INITIATE

RETURN:		see MSG_GEN_INTERACTION_INITIATE

DESTROYED:	see MSG_GEN_INTERACTION_INITIATE

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolChangeInteractionInitiate	method dynamic	SpoolChangeClass,
						MSG_GEN_INTERACTION_INITIATE

		; Save the state of the printer UI
		;
		push	ax, si
		mov	si, offset PrintDialogBox
		call	SavePrinterUIState
		jc	error

		; Now set the maximum paper width (it's a hack!)
		;
		mov	si, offset PrintDialogBox
		call	SetPaperSizeMaxWidth

		; Finish up by calling superclass
		;
		pop	ax, si
		mov	di, offset SpoolChangeClass
		GOTO	ObjCallSuperNoLock

error:
		add	sp, 4		; clear ax, si off stack
		ret
SpoolChangeInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolChangeApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that the Options dialog box is undergoing an APPLY

CALLED BY:	GLOBAL (MSG_GEN_APPLY)

PASS:		*DS:SI	= SpoolChangeClass object
		DS:DI	= SpoolChangeClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolChangeApply	method dynamic	SpoolChangeClass, MSG_GEN_APPLY

	; Pass this on to our superclass
	;
	push	ax
	mov	di, offset SpoolChangeClass	; ES:DI => my class
	call	ObjCallSuperNoLock		; call my superclass

ifdef GPC_ONLY
	; We now automatically save the options whenever the DB is closed
	;
	mov	ax, MSG_SPOOL_SUMMONS_SAVE_OPTIONS
	mov	si, offset PrintDialogBox
	call	ObjCallInstanceNoLock
endif	
			
	; Now do the rest of the work
	;
	pop	ax
	mov	si, offset PrintDialogBox
	GOTO	ObjCallInstanceNoLock		; do the work
SpoolChangeApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolChangeReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that the Options dialog box is undergoing a RESET.

CALLED BY:	UI (MSG_GEN_RESET)
	
PASS:		DS:*SI	= SpoolChangeClass instance data
		ES	= Segment holding class definition

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolChangeReset	method	SpoolChangeClass, MSG_GEN_RESET

	; Do any clean-up work necessary if the user RESET's
	;
	push	ax, si				; save method & my handle
	mov	si, offset PrintDialogBox
	call	ObjCallInstanceNoLock		; do the work

	; Now do the rest of the RESET work
	;
	pop	ax, si				; restore method & my handle
	mov	di, offset SpoolChangeClass	; ES:DI => my class
	GOTO	ObjCallSuperNoLock		; call my superclass
SpoolChangeReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply (remember) changes made to the print change dialog box.

CALLED BY:	GLOBAL (MSG_GEN_APPLY)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsApply	method dynamic	SpoolSummonsClass, MSG_GEN_APPLY
		.enter

		; Store some data away in case we need it later
		;
		mov	ax, ds:[di].SSI_timeout
		mov	ds:[di].SSI_backupTimeout, ax
		mov	al, ds:[di].SSI_retries
		mov	ds:[di].SSI_backupRetries, al
		mov	al, ds:[di].SSI_flags
		mov	ds:[di].SSI_backupFlags, al
		call	DeletePrinterUIState

if 	_LABELS
		; We want to see if we are printing to labels, so we can
		; later disable the Collate option in the main print DB.
		;
		mov	di, ds:[si]
		add	di, ds:[di].SpoolSummons_offset
		andnf	ds:[di].SSI_flags, not mask SSF_PRINTING_TO_LABELS
		test	bp, PT_LABEL		; don't need to use mask
		jz	setCollateState
		ornf	ds:[di].SSI_flags, mask SSF_PRINTING_TO_LABELS
setCollateState:
		call	CollateEnableDisable	; need to disable if labels
endif ;	_LABELS

	;
	; Tell the user what paper needs to be installed in the printer
	;
		call	SpoolSummonsAnnouncePaperSize
	;
	; Clavin: if not a dialog and print-to-file is enabled, we don't
	; have a Print To File trigger usable (as the trigger group was
	; set not-usable by the PrintControl), but we still need the file name,
	; so initiate the dialog now.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenInteraction_offset
		cmp	ds:[di].GII_visibility, GIV_DIALOG
		je	done

		mov	di, ds:[si]
		add	di, ds:[di].SpoolSummons_offset
		test	ds:[di].SSI_flags, mask SSF_PRINTING_TO_FILE
		jz	done
		test	ds:[di].SSI_flags, mask SSF_HAVE_FILE_NAME
		jnz	done
		ornf	ds:[di].SSI_flags, mask SSF_HAVE_FILE_NAME
		
	    ;
	    ; Nuke the reply triggers so we get just standard OK/Cancel
	    ; sort of things.
	    ;
		mov	si, offset PrintFileNonACReplyGroup
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjCallInstanceNoLock
	    ;
	    ; Switch the dialog to be notification (no cancelation allowed)
	    ; 
		mov	si, offset PrintFileDialogBox
		
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		
		mov	cl, GIT_NOTIFICATION
		mov	ax, MSG_GEN_INTERACTION_SET_TYPE
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock
	    ;
	    ; Bring the box up on-screen
	    ;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
SpoolSummonsApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that every state will be restored correctly on the
		soon-to-occur RESET of the Options dialog box.

CALLED BY:	SpoolChangeReset (MSG_GEN_RESET)
	
PASS: 		*DS:SI	= SpoolSummonClass object
		DS:DI	= SpoolSummonsInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsReset	method	SpoolSummonsClass, MSG_GEN_RESET
	.enter

	; Reset all of the UI in the change dialog box
	;
	call	ResetPrinterUI			; reset printer UI
	call	DeletePrinterUIState		; delete state information
	call	ResetTimeoutRetry		; re-initialize timeout/retry
	call	ResetPrintToFile		; re-initialize print-to-file

	.leave
	ret
SpoolSummonsReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the options from the .INI file for the current printer

CALLED BY:	UI (MSG_SPOOL_SUMMONS_LOAD_OPTIONS)
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsLoadOptions	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_LOAD_OPTIONS
	.enter

	; Load all of the options in the options dialog box.
	; Need to exlicitly send message to a number of objects,
	; as controller objects do not pass along the message.
	;
	mov	ax, MSG_META_LOAD_OPTIONS
	mov	si, offset PrinterChangeBox
	call	ObjCallInstanceNoLock		; save those options

	mov	ax, MSG_META_LOAD_OPTIONS
	mov	si, offset TimeoutRetryGroup
	call	ObjCallInstanceNoLock		; save those options

	mov	ax, MSG_META_LOAD_OPTIONS
	mov	si, offset PrintToOptionsList
	call	ObjCallInstanceNoLock		; save those options

	.leave
	ret
SpoolSummonsLoadOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current options as specified by the user

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SAVE_OPTIONS)
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSaveOptions	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SAVE_OPTIONS
	.enter

	; Save all of the options in the options dialog box.
	; Need to exlicitly send message to a number of objects,
	; as controller objects do not pass along the message.
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	mov	si, offset PrinterChangeBox
	call	ObjCallInstanceNoLock		; save those options

	mov	ax, MSG_META_SAVE_OPTIONS
	mov	si, offset TimeoutRetryGroup
	call	ObjCallInstanceNoLock		; save those options

	mov	ax, MSG_META_SAVE_OPTIONS
	mov	si, offset PrintToOptionsList
	call	ObjCallInstanceNoLock		; save those options

	call	InitFileCommit			; commit the changes

	; Tell user we saved the options. Removed by Don 1/2/99 for GPC.
	;
if	0
	clr	ax
	pushdw	axax				; SDOP_helpContext
	pushdw	axax				; SDOP_customTriggers
	pushdw	axax				; SDOP_stringArg2
	pushdw	axax				; SDOP_stringArg1
	mov	bx, handle SpoolErrorBlock
	mov	si, offset SpoolPrinterOptsSaved
	pushdw	bxsi				; SDOP_customString
	mov	ax, CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or \
		    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
	push	ax				; SDOP_customFlags
	call	UserStandardDialogOptr
endif
	.leave
	ret
SpoolSummonsSaveOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsPrinterSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A printer has been selected.  Set up the dialog box.

CALLED BY:	UI (MSG_SPOOL_SUMMONS_PRINTER_SELECTED)

PASS:		DS:*SI	= SpoolSummonsClass instance data
		DS:DI	= SpoolSummonsClass specific instance data
		CX	= Printer number (0 -> N-1)

RETURN:		Carry	= Set if printer was bad!

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		When a new printer is selected, it may either be the 
		"actual" printer, or the "user" printer. The actual
		printer means the user has really made a choice to use
		this printer, by pressing OK in the Change Options Box.
		The user printer means that this printer has been selected,
		but may not be the eventual choice. Here's the work that
		must be done in each case:

		Actual:
			Change printer name in main dialog box
			Get the new print attributes, and reset them
			Get the paper size information, and reset it
			Reset the paper source information

		User:
			Get the paper size information, & reset it
			Reset the paper source information
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsPrinterSelected	method	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_PRINTER_SELECTED

	; For NIKE, if we are printing, this routine can actually be called
	; in a myriad of different ways. We always query the ink & medium
	; settings to determine which printer driver to be using. For fax,
	; of course, we skip all of this garbage.
	;
	
	; Store all the printer information
	;
	cmp	cx, ds:[di].SSI_currentPrinter	; have we changed printers??
	je	exit				; no, so do nothing
	mov	ax, cx				; new printer => AX
	call	SpoolSummonsGetPrinterInfo	; get info about a printer
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	test	dh, mask SSPI_VALID		; check for validity...
	jz	badPrinter			; if clear, its invalid
	mov	ds:[di].SSI_printerAttrs, dl	; store the print modes
	mov	ds:[di].SSI_printerInfo, dh	; store the printer info

	; Change the actual values
	;
	xchg	ds:[di].SSI_currentPrinter, ax	; store the new current printer
	mov	ds:[di].SSI_backupPrinter, ax	; store the old printer
	call	InitOptionsCategory
	call	InitPrinterUI			; init printer's UI
	call	InitPrinterModes		; init the printer modes
	call	InitPaperSize			; init paper size information
	call	InitTimeoutRetry		; init time & retry options
	call	InitPrintToFile			; init print-to-file ability

	; Now tell the dialog box to remember its state
	;
	mov	ax, MSG_SPOOL_SUMMONS_LOAD_OPTIONS
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_APPLY
	mov	si, offset PrinterChangeBox
	call	ObjCallInstanceNoLock

	; Finally, reset the geometry of the dialog box
	;
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bx, ds:[LMBH_handle]		; change dialog OD => BX:SI
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	si, offset PrintDialogBox
	call	ObjCallInstanceNoLock
exit:
	ret

	; Handle a bad printer (PRINT_CONTROL_ERROR in CX, new printer in AX)
badPrinter:
	xchg	dx, ax				; new printer => DX
	mov	ax, MSG_SPOOL_SUMMONS_RESET_PRINTER
	call	UISpoolErrorBox			; send AX back to me when done
	ret
SpoolSummonsPrinterSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOptionsCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the name of the printer category in vardata

CALLED BY:	SpoolSummonsPrinterSelected

PASS:		*DS:SI	= SpoolSummons object
		DS:DI	= SpoolSummonsInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOptionsCategory	proc	near
		.enter
	;
	; Due to how we've hooked some of the UI objects into the
	; Options dialog box, we need to set this category on
	; multiple objects.
	;
		mov	cx, si
		call	InitOptionsCategoryLow
		mov	cx, offset TimeoutRetryGroup
		call	InitOptionsCategoryLow
		mov	cx, offset PrintToOptionsList
		call	InitOptionsCategoryLow

		.leave
		ret
InitOptionsCategory	endp

InitOptionsCategoryLow	proc	near
	class	SpoolSummonsClass
	uses	es
	.enter

	; Allocate room in vardata, if a printer was chosen
	;
	mov	bp, ds:[di].SSI_currentPrinter
	cmp	bp, -1				; no printer ??
	je	done				; so do nothing
	push	si
if	_SINGLE_PRINT_OPTIONS_INI_CATEGORY
	cmp	ds:[di].SSI_driverType, PDT_PRINTER
	pushf
endif
	push	si
	mov	si, cx
	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	mov	cx, MAXIMUM_PRINTER_NAME_LENGTH
	call	ObjVarAddData
	segmov	es, ds				; buffer => DS:BX
	pop	si

	; Grab printer category string
	;
	call	SSOpenPrintStrings		; strings block => DS:DI
	mov	dx, bp				; printer number => DX
	call	SpoolSummonsGetPrinterCategory	; printer string => DS:SI
	mov	di, bx				; destination => ES:DI
if DBCS_PCGEOS
	call	PrinterNameToIniCatLen		; cx <- length of cat w/NULL
else
	inc	cx				; copy NULL-terminator also
endif

if	_SINGLE_PRINT_OPTIONS_INI_CATEGORY

	; If we want all of the printer's options to come from a
	; single location, now is the time to make that happen
	;
	popf					; restore comprison result
	jne	doCopy				; if not printer, we're done
	segmov	ds, cs
	mov	si, offset defaultPrinterCategory
	mov	cx, length defaultPrinterCategory
doCopy:
endif
	; Copy the string and clean up
	;
	rep	movsb				; copy the string
	ConvPrinterNameDone
	segmov	ds, es
	pop	si
	call	SSClosePrintStrings
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
done:
	.leave
	ret
InitOptionsCategoryLow	endp

if	_SINGLE_PRINT_OPTIONS_INI_CATEGORY
defaultPrinterCategory	char	"installedPrinter", 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsResetPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the "USER" printer selection - this occurs after
		the user has selected a printer that is invalid.

CALLED BY:	UI (MSG_SPOOL_SUMMONS_RESET_PRINTER) via UserStandardDialog
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsResetPrinter	method	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_RESET_PRINTER
	.enter

	mov	cx, ds:[di].SSI_currentPrinter	; current printer => CX
	mov	si, offset PrintUI:PrinterChoice
	call	SSSetItemSelection

	.leave
	ret
SpoolSummonsResetPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsAnnouncePaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Announce the paper size to the user

CALLED BY:	SpoolSummonsApply
	
PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsInstance

RETURN:		Nothing

DESTROYED:	AX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ANNOUNCE_PAPER_STR_LEN = MAX_PAPER_STRING_LENGTH + 2*LOCAL_DISTANCE_BUFFER_SIZE

paperTypeStrings	word \
		offset	Strings:PaperInPrinterText,
		offset	Strings:EnvelopeInPrinterText,
		offset	Strings:LabelInPrinterText,
		offset	Strings:PostcardInPrinterText

SpoolSummonsAnnouncePaperSize	proc	near
		uses	bx, cx, dx, di, si, bp, es
		.enter
	;
	; Determine the size the user has selected (or has been pre-
	; selected by the system), and see which pre-defined paper
	; size that matches.
	;
		call	SpoolSummonsGetPaperSize
		and	bp, mask PLP_TYPE	; PageType => BP
		sub	sp, ANNOUNCE_PAPER_STR_LEN
		segmov	es, ss, ax
		mov	di, sp			; buffer => ES:DI
		push	di			; save start of buffer
		call	SpoolConvertPaperSize	; paper size # => AX
	;
	; OK, we've got all of the information we need.
	;	AX = paper size enumeration (-1 for custom)
	;	CX = Width
	;	DX = Height
	;	BP = PageType
	; Now, let's assemble the string. First, copy the preamble.
	;
		mov	si, cs:[paperTypeStrings][bp]
		call	CopyStringsChunk
	;
	; OK, now copy in the paper string (NULL-terminated)
	;
		cmp	ax, -1
		je	customSize
		call	SpoolGetPaperString
	;
	; Finally, set the moniker
	;
setMoniker:
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	cx, es
		pop	dx			; string => CX:DX
		mov	bp, VUM_NOW
		mov	si, offset PrintUI:PrinterPaperSize
		call	ObjCallInstanceNoLock
		add	sp, ANNOUNCE_PAPER_STR_LEN
		
		.leave
		ret
	;
	; We have a custom paper size. First, copy in the custom preamble.
	;
customSize:
		mov	si, offset Strings:CustomSizeText
		call	CopyStringsChunk
	;
	; Now convert the width to ASCII
	;
		push	dx
		mov	dx, cx
		call	LocalGetMeasurementType
		mov	ch, al			; MeasurementType => CH
		mov	cl, DU_INCHES_OR_CENTIMETERS
		clr	ax			; width => DX.AX
		mov	bx, mask LDF_OMIT_UNITS_STRING
		call	LocalDistanceToAscii
		add	di, cx			; add in length of string
		LocalPrevChar esdi		; back up over NULL
	;
	; Append the " x " text
	;
		mov	si, offset Strings:CustomSizeByText
		call	CopyStringsChunk
	;
	; Finally, convert the height to ASCII
	;
		call	LocalGetMeasurementType
		mov	ch, al			; MeasurementType => CH
		mov	cl, DU_INCHES_OR_CENTIMETERS
		pop	dx
		clr	ax			; height => DX.AX
		clr	bx			; LocalDistanceFlags
		call	LocalDistanceToAscii
		jmp	setMoniker
SpoolSummonsAnnouncePaperSize	endp

CopyStringsChunk	proc	near
		uses	ax, cx, ds
		.enter

		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]		; string => DS:SI
		ChunkSizePtr	ds, si, cx
		dec	cx
DBCS <		dec	cx						>
		rep	movsb
		call	MemUnlock

		.leave
		ret
CopyStringsChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Printer UI handling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer UI for this printer.

CALLED BY:	INTERNAL

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		Remove old options UI
		Remove old main UI
		Add new options UI
		Add new main UI

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPrinterUI	proc	near
	class	SpoolSummonsClass
	.enter
	
	; Some set-up work, please
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	push	ds:[di].SSI_currentPrinter

	; First remove the old UI, if necessary
	;
	mov	cx, ds:[di].SSI_backupPrinter	; old printer # => CX
	call	RemovePrinterUIBoth

	; Now add the new UI, if necessary
	;
	pop	cx				; current printer # => CX
	mov	al, mask SSPI_UI_IN_OPTIONS_BOX
	mov	bx, offset PIS_optionsUI
	mov	dx, offset AddPrinterUIOptions
	mov	di, DR_PRINT_GET_OPTIONS_UI
	call	AddPrinterUI

	mov	ax, mask SSPI_UI_IN_DIALOG_BOX
	mov	bx, offset PIS_mainUI
	mov	dx, offset AddPrinterUIMain
	mov	di, DR_PRINT_GET_MAIN_UI
	call	AddPrinterUI

	.leave
	ret
InitPrinterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the printer UI to the default values

CALLED BY:	SpoolSummonsReset

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		To make life easy, we simply remove the existing options
		UI, and re-add new options UI.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetPrinterUI	proc	near
	class	SpoolSummonsClass
	.enter

	; Some set-up work, first
	;	
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	bx, ds:[di].SSI_printerUIState
	tst	bx
	jz	done
	call	MemLock
	call	StuffPrinterUI
	call	MemUnlock
done:
	.leave
	ret
ResetPrinterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SavePrinterUIState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the printer UI state, prior to allowing user to change it

CALLED BY:	SpoolChangeInteractionInitiate

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		carry set on error

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SavePrinterUIState	proc	near
	class	SpoolSummonsClass
	uses	ax, bx, cx, dx
	.enter
	
	; Load the current options
	;
	mov	ax, (size JobParameters)
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	done
	call	EvalPrinterUI
	jc	evalError
	jz	freeMemory
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	ds:[di].SSI_printerUIState, bx
	call	MemUnlock
	clc
done:
	.leave
	ret

	; If there was an evaluation error don't display a message, but
	; be certain to clean up any memory.
evalError:
	jcxz	freeMemory
	xchg	bx, cx
	call	MemFree
	mov	bx, cx
freeMemory:
	call	MemFree
	stc
	jmp	done
SavePrinterUIState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePrinterUIState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete any printer UI state we'd previously saved

CALLED BY:	UTILITY

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeletePrinterUIState	proc	near
	class	SpoolSummonsClass
	.enter
	
	; Clean up any leftover printer UI state
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	clr	bx
	xchg	bx, ds:[di].SSI_printerUIState
	tst	bx
	jz	done
	call	MemFree	
done:
	.leave
	ret
DeletePrinterUIState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the UI (if any) displayed by a printer driver

CALLED BY:	ResetPrinterUI, ResetPrinterUIUser
	
PASS:		DS:*SI	= SpoolSummonsClass instance data
		AL	= SpoolSummonsPrinterInfo record to test
				SSPI_UI_IN_DIALOG_BOX
				SSPI_UI_IN_OPTIONS_BOX
		BX	= Offset in PrinterInfoStruct to place UI
		CX	= Printer number
		DX	= Callback to add child
		DI	= PrintEscCodes (printer driver function)
				DR_ESC_GET_PRINT_UI
				DR_ESC_GET_OPTIONS_UI

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddPrinterUI	proc	near
	driverStrategy	local	fptr.far
	.enter

	; Determine if the new printer has any UI
	;
	cmp	cx, -1				; no printer ??
	je	shortDone			; if so, do nothing
	push	di				; save the driver function
	call	AccessPrinterInfoStruct		; PrinterInfoStruct => DS:DI
	clrdw	ds:[di][bx]			; assume no UI
	test	ds:[di].PIS_info, al		; check for UI
	pop	di				; driver function => DI
shortDone:
	jz	done				; none, so do nothing

	; First we must use the printer driver
	;
	push	bp, bx, cx			; locals, PIS offset, printer #
	push	dx				; save add-routine
	mov	dx, cx				; printer # => DX
	call	SpoolLoadDriver			; information => AX, BX
	pop	si				; add-routine => SI
EC <	ERROR_C	SPOOL_SUMMONS_PRINT_DRIVER_MUST_BE_VALID		>
	xchg	ax, bx				; PState => BX
	push	ax				; save driver handle
	mov	driverStrategy.segment, dx
	mov	driverStrategy.offset, cx
	call	driverStrategy			; generic OD => CX:DX
EC <	tst	di				; function handled ??	>
EC <	ERROR_Z	SPOOL_SUMMONS_ADD_PRINTER_UI_UI_NOT_FOUND		>
	call	MemFree				; free the PState

	; Duplicate the block
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; find the owner (in BX)
	xchg	ax, bx				; owner to AX
	mov	bx, cx
	clr	cx	 			; current thread will run block
	call	ObjDuplicateResource		; duplicate the block
	mov	cx, bx				; block handle => CX

	; Add the UI to the proper child
	;
	mov	ax, MSG_GEN_ADD_CHILD
	call	si				; add the new UI to our tree

	; Call SET_USABLE instead of putting it in the queue, because 
	; RemovePrinterUIBoth may be called before getting to the queued
	; message, causing the interaction to have no parent.
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, cx
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bp, bx
	mov	dx, si

	; Store the various pieces of data
	;
	pop	bx				; handle of driver => BX
	pop	cx				; printer number => CX
	mov	si, offset PrintDialogBox	; SpoolSummonsClass => DS:*SI
	call	AccessPrinterInfoStruct
	mov	ds:[di].PIS_driverHandle, bx	; store the driver handle
	pop	bx				; offset to data in PIS => BX
	mov	ds:[di][bx].chunk, dx		; store the UI OD
	mov	ds:[di][bx].handle, bp
	pop	bp				; local variables => BP
done:
	.leave
	ret
AddPrinterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPrinterUIMain, AddPrinterUIOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually add the UI into a generic tree

CALLED BY:	AddPrinterUI
	
PASS:		DS	= Segment holding PrintDialogBox
		CX:DX	= OD of new UI to add
		AX	= MSG_GEN_ADD_CHILD

RETURN:		Nothing

DESTROYED:	AX, BP, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAIN_INSERTION_POSITION		= 2
OPTIONS_INSERTION_POSITION	= 2

AddPrinterUIMain	proc	near
	mov	si, offset PrintUI:PrintDialogBox
	mov	bp, MAIN_INSERTION_POSITION
	call	ObjCallInstanceNoLock
	ret
AddPrinterUIMain	endp

AddPrinterUIOptions	proc	near
	mov	si, offset PrintUI:PrinterChangeBox
	mov	bp, OPTIONS_INSERTION_POSITION
	call	ObjCallInstanceNoLock

        ;
        ; 1/13/94: For fax stuff, make sure the parent object is usable.
        ;               -- ardeb
        ;
	push    cx, dx, bp
	mov     ax, MSG_GEN_SET_USABLE
	mov     dl, VUM_DELAYED_VIA_UI_QUEUE
	call    ObjCallInstanceNoLock
	pop     cx, dx, bp
	;
	; 1/27/98: ND-000506 - Options dialog too big in CGA.
	; If we're running under CGA, make the printer-specific
	; options a separate dialog so it will fit on screen. -- eca
	;
	push	cx, dx
	call	UserGetDisplayType
	and	ah, mask DT_DISP_SIZE
	cmp	ah, DS_TINY shl (offset DT_DISP_SIZE)
	jne	notCGA					;branch if not CGA
	mov	si, dx
	mov	bx, cx					;^lbx:si <- options UI
	;
	; See if it is an interaction -- if not, we can't make it into
	; a dialog, and hopefully it's too small to matter in CGA.
	;
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment GenInteractionClass
	mov	dx, offset GenInteractionClass		;cx:dx <- ptr to class
	call	ObjMessage
	jnc	notCGA					;branch if not inter.
	;
	; It is an interaction -- make it a dialog
	;
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_DIALOG
	call	ObjMessage
	;
	; Make it modal to match its parent
	;
	mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
	mov	cx, mask GIA_MODAL			;cl <- set MODAL
							;ch <- clear none
	call	ObjMessage
	;
	; Make it a command box to match its parent
	;
	mov	ax, MSG_GEN_INTERACTION_SET_TYPE
	mov	cl, GIT_COMMAND
	call	ObjMessage
	;
	; Give it a name
	;
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle Strings
	mov	dx, offset moreOptionsMoniker
	mov	bp, VUM_NOW
	call	ObjMessage
	;
	; Add the special OK trigger
	;
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, ds:LMBH_handle
	mov	dx, offset PrintUI:CGAMoreOptionsOKTrigger
	mov	bp, 0
	call	ObjMessage
notCGA:
	pop	cx, dx

	ret
AddPrinterUIOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemovePrinterUIBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the printer UI from both dialog boxes

CALLED BY:	InitPrinterUI, SpoolSummonsLoadPrinters

PASS:		DS:*SI	= SpoolSummonsClass instance data
		CX	= Printer # whose UI will be removed

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemovePrinterUIBoth	proc	near
	
	; Remove the options UI
	;
	mov	al, mask SSPI_UI_IN_OPTIONS_BOX
	mov	bx, offset PIS_optionsUI
	mov	dx, offset PrintUI:PrinterChangeBox
	call	RemovePrinterUI

	; Remove the main UI
	;
	mov	al, mask SSPI_UI_IN_DIALOG_BOX
	mov	bx, offset PIS_mainUI
	mov	dx, offset PrintUI:PrintDialogBox
	FALL_THRU	RemovePrinterUI
RemovePrinterUIBoth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemovePrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the UI (if any) displayed by a printer driver)

CALLED BY:	ResetPrinterUI, ResetPrinterUIUser
	
PASS:		DS:*SI	= SpoolSummonsClass instance data
		AL	= SpoolSummonsPrinterInfo record to test
				SSPI_UI_IN_DIALOG_BOX
				SSPI_UI_IN_OPTIONS_BOX
		BX	= Offset in PrinterInfoStruct to UI
		CX	= Printer number
		DX	= Generic parent in segment DS

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemovePrinterUI	proc	near
	uses	cx, si
	.enter

	; Determine if the old printer had UI
	;
	cmp	cx, -1				; no printer ??
	je	done				; if so, do nothing
	call	AccessPrinterInfoStruct		; PrinterInfoStruct => DS:DI
	test	ds:[di].PIS_info, al		; check for UI
	jz	done				; none, so do nothing

	; Must unlink the UI for the generic tree
	;
	push	ds:[di].PIS_driverHandle	; save the driver handle
	mov	si, ds:[di][bx].chunk
	mov	bx, ds:[di][bx].handle		; OD of UI => BX:SI
	push	dx				; save generic parent
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, bx
	mov	dx, si
	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp				; leave links clean
	pop	si				; parent => DS:*SI
	call	ObjCallInstanceNoLock

	; Now free the printer's generic tree & stop using the driver
	;
	pop	bx				; PrinterDriver handle => BX
EC <	call	ECCheckGeodeHandle		; valid handle ??	>
	call	SpoolFreeDriverAndUIBlock
done:
	.leave
	ret
RemovePrinterUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Printer Mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrinterModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the print mode lists

CALLED BY:	INTERNAL

PASS:		DS:*SI	= SpoolSummons instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

outputTable	label	byte
	byte	PRINT_GRAPHICS
	byte	PRINT_TEXT

InitPrinterModes	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter

	; Determine printer's output capabilities
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; access the instance data
	tst	ds:[di].SSI_printDataHan	; loaded a printer yet ?
	jz	nearDone			; no, so do nothing
	clr	bl				; assume no output modes
	test	ds:[di].SSI_printAttrs, mask PCA_TEXT_MODE
	jz	graphicsOK
	or	bl, PRINT_TEXT
graphicsOK:
	test	ds:[di].SSI_printAttrs, mask PCA_GRAPHICS_MODE
	jz	createMask
	or	bl, PRINT_GRAPHICS
createMask:
	and	bl, ds:[di].SSI_printerAttrs	; and in the printer attributes

	; Now set the initial print mode (text or graphics)
	;
	mov	si, offset PrintUI:OutputTypeChoices
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjCallInstanceNoLock		; ListEntryState => CL
	mov_tr	di, ax				; 0 (graphics) or 1 (text) => DI
	test	cs:[outputTable][di], bl	; can we still do this ??
	jnz	almostDone			; no need to reset the value...
	clr	cx				; default to graphics
	test	bl, PRINT_GRAPHICS		; can we do graphics ??
	jnz	setDefault			; yes, so do this
	inc	cx				; default to text
	test	bl, PRINT_TEXT			; can we do text ??
	jnz	setDefault			; yes, so do it!

	; Display an error box
	;
	mov	cx, PCERR_NO_MODE_AVAIL		; no print mode available
	mov	bp, MSG_META_DUMMY		; don't send back a method
	mov	bx, ds:[LMBH_handle]		; OD => BX:SI
	mov	si, offset PrintUI:PrintDialogBox
	mov	ax, MSG_SPOOL_SUMMONS_REMOTE_ERROR
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	stc					; disable the print trigger
nearDone:
	jmp	done				; and we're done

	; Set the default print-mode (graphics or text)
setDefault:
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjCallInstanceNoLock		; send the message
almostDone:
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock		; force the AD to go out

	; Now determine if this list should be usable
	;
	clr	cx				; initally no modes available
	test	bl, PRINT_TEXT			; can we print text ??
	jz	checkGraphics			; no, so jump
	inc	cx				; else increment mode count
checkGraphics:
	test	bl, PRINT_GRAPHICS		; can we print graphics ??
	jz	setStatus			; no, so jump
	inc	cx				; else increment mode count
setStatus:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	cmp	cx, 1
	jle	sendMessage
	mov	ax, MSG_GEN_SET_USABLE
sendMessage:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock		; set the status
	clc					; OK status

	; Enable or disable the print trigger
done:
	call	SSEnableDisablePrinting		; enable or disable!

	.leave
	ret
InitPrinterModes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetOutputType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable the possbile printing modes

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SET_OUTPUT_TYPE)

PASS:		DS:DI	= SpoolSummonsClass specific instance data
		CX	= 0 (graphics) or 1 (text)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

qualityTable	label	byte
	byte	(mask POM_GRAPHICS_HIGH) or (mask POM_TEXT_NLQ)
	byte	(mask POM_GRAPHICS_MEDIUM)
	byte	(mask POM_GRAPHICS_LOW) or (mask POM_TEXT_DRAFT)
	byte	0

SpoolSummonsSetOutputType	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_OUTPUT_TYPE
	.enter

	; Some set-up work
	;
	mov	bl, PRINT_GRAPHICS		; assume we're in graphics mode
	jcxz	setup				; if graphics, jump
	mov	bl, PRINT_TEXT			; else we're in text mode
setup:
	push	{word} ds:[di].SSI_driverType	; save driver type
	push	ds:[di].SSI_printAttrs		; save default choices
	and	bl, ds:[di].SSI_printerAttrs	; and the printer capabilities
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset PrintUI:OutputQualityChoices
	call	ObjCallInstanceNoLock		; current exclusive => AX
	push	ax				; save the exclusive
	
	; Enable or disable (or possible set usable/note) each setting
	;
if	_HIDE_UNAVAILABLE_QUALITY_CHOICE
	clr	bh				; flags => BX
	mov	ax, mask POM_GRAPHICS_HIGH or mask POM_TEXT_NLQ
	mov	si, offset PrintUI:HighEntry	; enable if either bit is set
	call	SetUsableOrNotUsableObject
	mov	ax, mask POM_GRAPHICS_MEDIUM
	mov	si, offset PrintUI:MediumEntry	; enable if bit is set
	call	SetUsableOrNotUsableObject
	mov	ax, mask POM_GRAPHICS_LOW or mask POM_TEXT_DRAFT
	mov	si, offset PrintUI:LowEntry	; enable if either bit is set
	call	SetUsableOrNotUsableObject
else
	mov	bh, mask POM_GRAPHICS_HIGH or mask POM_TEXT_NLQ
	mov	si, offset PrintUI:HighEntry	; enable if either bit is set
	call	EnableOrDisableObject
	mov	bh, mask POM_GRAPHICS_MEDIUM
	mov	si, offset PrintUI:MediumEntry	; enable if bit is set
	call	EnableOrDisableObject
	mov	bh, mask POM_GRAPHICS_LOW or mask POM_TEXT_DRAFT
	mov	si, offset PrintUI:LowEntry	; enable if either bit is set
	call	EnableOrDisableObject
endif

	; Now reset the quality exclusive (if necessary). If there are no
	; quality controls available, then make sure the quality gets reset
	; each time (or else when switching between printers, the default
	; value might not be used).
	;
	pop	di				; restore the old exclusive
	pop	dx				; restore default choices
	pop	ax				; DriverType => AL
	test	dx, mask PCA_QUALITY_CONTROLS	; if no quality controls, always
	jz	choose				; ...reset to default quality
	cmp	di, -1				; no previous exclusive ??
	je	reset				; if so, force reset
	test	bl, cs:qualityTable[di]		; is the old excl still enabled
	jnz	done				; if so, we're done

	; We are going to reset the quality. If the application has not
	; made the quality controls available, then the app gets to choose
	; the default quality (always). Otherwise, the system chooses :)
reset:
if	_OVERRIDE_DEFAULT_PRINT_QUALITY
	mov	dx, DEFAULT_PRINT_QUALITY
endif
	cmp	al, PDT_FACSIMILE
	jne	choose
	mov	dx, DEFAULT_FAX_QUALITY
choose:
	and	dx, mask PCA_DEFAULT_QUALITY	; PrintQualityEnum => DX
	call	ChooseBestOutputMatch		; choose the best fit
	mov	si, offset PrintUI:OutputQualityChoices
	call	SSSetItemSelection
done:
	.leave
	ret
SpoolSummonsSetOutputType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseBestOutputMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose the best default output mode, based upon the
		printer capabilities and the application's desires.

CALLED BY:	SpoolSummonsSetOutputType

PASS: 		AL	= PrinterDriverType
		BL	= PrinterOutputModes (available)
		DX	= PrintQualityEnum (desired)
	
RETURNS:	CX	= 0 (high quality)
			= 1 (medium quality)
			= 2 (low quality)

DESTROYED:	AX, BX, DX, BP

PSEUDO CODE/STRATEGY:
		We know at least 1 of the output modes for this type of
		printing is available.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChooseBestOutputMatch	proc	near
	.enter

	; If the application-desired quality is available, then use it.
	; Othewrwise, keep track of lowest & highest quality found so far.
	;
	mov	bh, al
	mov	ax, PQT_HIGH			; lowest quality so far => AX
	mov	cx, PQT_LOW			; highest quality so far => CX
	mov	bp, ax				; start high and work to low
qualityLoop:
	test	bl, cs:[qualityTable][bp]	; quality available in driver?
	jz	next				; ...no, so go to next
	cmp	bp, dx				; is default quality available?
	je	done
	cmp	dx, PQT_HIGH			; if we're looking for highest
	je	done				; ...quality, we just found it
	mov	ax, bp				; new lowest quality => AX
next:
	inc	bp				; go to next (lower) quality
	cmp	bp, PrintQualityEnum		; are we done ??
	jl	qualityLoop

	; If we want the lowest quality available, that value is stored in AX
	;
	mov	bp, ax
	cmp	dx, PQT_LOW
	je	done

	; Finally, if we want the intermediate quality value, then we must
	; choose either the highest or lowest quality available. If we are
	; faxing, we choose the lowest. Otherwise, we choose the highest.
	;
	cmp	bh, PDT_FACSIMILE
	jne	done
	mov	bp, cx
done:
	mov	cx, bp				; selection => CX

	.leave
	ret
ChooseBestOutputMatch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Page Range Stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetPageFrom/SpoolSummonsSetPageTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the page range is alaways valid

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SET_PAGE_[FROM, TO]

PASS:		DX	= New page value
		DS:DI	= SpoolSummons instance data
		DX	= Page #
		BP	= GenValueStateFlags

RETURN:		Nothing

DESTROYED:	AX, CX, BP, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetPageFrom	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_PAGE_FROM

	test	bp, mask GVSF_OUT_OF_DATE
	jnz	done
	mov	ds:[di].SSI_firstUserPage, dx	; store the first page
	call	AllOrSelectPageRange		; set the all or select flag
	cmp	dx, ds:[di].SSI_lastUserPage	; compare with the last page
	jle	done
	mov	ds:[di].SSI_lastUserPage, dx	; now also the last page
	mov	si, offset PrintUI:PageTo
	call	SSSetIntegerValue		; set the value
done:
	ret
SpoolSummonsSetPageFrom	endp

SpoolSummonsSetPageTo	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_PAGE_TO

	test	bp, mask GVSF_OUT_OF_DATE
	jnz	done
	mov	ds:[di].SSI_lastUserPage, dx	; store the last page
	call	AllOrSelectPageRange		; set the all or select flag
	cmp	dx, ds:[di].SSI_firstUserPage	; compare with the last page
	jge	done
	mov	ds:[di].SSI_firstUserPage, dx	; now also the first page
	mov	si, offset PrintUI:PageFrom
	call	SSSetIntegerValue		; set the value
done:
	ret
SpoolSummonsSetPageTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllOrSelectPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either set the page range to all or select

CALLED BY:	GLOBAL

PASS:		DS:DI	= SpoolSummonsClass instance data (updated)

RETURN:		DS:DI	= SpoolSummonsClass instance data (updated)

DESTROYED:	AX, CX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllOrSelectPageRange	proc	near
	class	SpoolSummonsClass
	uses	dx
	.enter

	; Check the current page conditions
	;
	mov	cx, 1				; assume we need to select
	mov	ax, ds:[di].SSI_firstPage
	cmp	ax, ds:[di].SSI_firstUserPage
	jne	resetMaybe			; if unequal, need select
	mov	ax, ds:[di].SSI_lastPage
	cmp	ax, ds:[di].SSI_lastUserPage
	jne	resetMaybe			; if unequal, need select
	clr	cx				; actually all

	; Do we need to set anything
resetMaybe:
	cmp	cx, ds:[di].SSI_pageExcl	; compare with current value
	je	done				; if equal, do nothing

	; Else reset the stuff
	;
	push	si
	mov	ds:[di].SSI_pageExcl, cx	; store the new state
	mov	si, offset PageChoices		; DS:*SI is the PageChoice
	call	SSSetItemSelection		; make the selection
	pop	si
	mov	di, ds:[si]			; re-dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; acces the instance data

	; Clean up miscellaneous page-dependent choices
done:
	call	PageOrderEnableDisable		; enable/disable page order opts
	call	CollateEnableDisable		; enable/disable collate option

	.leave
	ret
AllOrSelectPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetPageExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps track of the current page exclusive type

CALLED BY:	GLOBAL

PASS:		DS:DI	= SpoolSummons specific instance data
		DS:*SI	= SpoolSummons instance data
		CX	= 0 for All, 1 for Selected

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		If all chosen, ensure first & last page values are the
		ones displayed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetPageExcl	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_PAGE_EXCL
	.enter

	mov	ds:[di].SSI_pageExcl, cx	; store the page exclusive
	tst	cx				; are all pages selected ??
	jnz	done
	mov	dx, ds:[di].SSI_firstPage	; first page => DX
	push	ds:[di].SSI_lastPage		; store the last page
	mov	si, offset PageFrom		; range object => DS:SI
	call	SSSetIntegerValueStatus		; set the value, send status
	pop	dx				; last page => DX
	mov	si, offset PageTo		; range object => DS:SI
	call	SSSetIntegerValueStatus		; set the value, send status
done:
	.leave
	ret
SpoolSummonsSetPageExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Misc Options on Main Dialog Box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetNumCopies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of the number of document copies, and enable/disable
		the proper document choices.

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SET_NUM_COPIES)

PASS:		DS:DI	= SpoolSummons instance data
		DX	= Number of copies (must be <= 255)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_NUMBER_OF_COPIES	= 255

SpoolSummonsSetNumCopies	method	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_SET_NUM_COPIES
	.enter

EC <	cmp	dx, MAX_NUMBER_OF_COPIES	; too big ??		>
EC <	ERROR_G	SPOOL_SUMMONS_SET_NUM_COPIES_TOO_BIG			>
	mov	ds:[di].SSI_numCopies, dl	; store the number of copies
	call	CollateEnableDisable

	.leave
	ret
SpoolSummonsSetNumCopies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollateEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the Collate trigger

CALLED BY:	INTERNAL
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data
		DS:*SI	= SpoolSummonsClass instance data

RETURN:		DS:DI	= SpoolSummonsClass specific instance data (updated)

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:
		* Disable collating for label printing, as it makes no
		  sense.

		* Don't check the # of pages unless the PCA_PAGE_CONTROLS
		  attribute is set, to handle non-WYSIWYG applications like
		  GeoPlanner & GeoDex (as they don't know how many pages
		  will be printed at the time the Print dialog is displayed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CollateEnableDisable	proc	near
	class	SpoolSummonsClass
	.enter

	; Enable or disable the collate trigger
	;	If 1 copy or printing labels, disable
	;	If no page controls but > 1 copy, enable
	;	If more than 1 page & > 1 copy enable
	;	Else disable
	;
	push	si				; save the handle
	mov	cl, ds:[di].SSI_numCopies	; number of copies => CL
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume not enabled...
	cmp	cl, 1				; only one copy
	je	setCollate			; then disable the collate
if 	_LABELS
	test	ds:[di].SSI_flags, mask SSF_PRINTING_TO_LABELS
	jnz	setCollate
endif ;	_LABELS
	test	ds:[di].SSI_printAttrs, mask PCA_PAGE_CONTROLS
	jz	enabled
	mov	cx, ds:[di].SSI_lastUserPage
	cmp	cx, ds:[di].SSI_firstUserPage	; more than one page ??
	jle	setCollate			; if not, disable collate
enabled:
	mov	ax, MSG_GEN_SET_ENABLED		; else we can collate
setCollate:
	mov	si, offset PrintUI:CopyChoiceCollate
	mov	dl, VUM_NOW			; update now
	call	ObjCallInstanceNoLock		; send the method
	
	; Clean up here
	;
	pop	si				; restore the handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; setup DS:DI

	.leave
	ret
CollateEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetCollateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the collate mode on/off

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SET_COLLATE_MODE)

PASS:		DS:DI	= SpoolSummons specific instance data
		CX	= 0 or mask SO_COLLATE
		
RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetCollateMode	method	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_SET_COLLATE_MODE

	; Store the new status
	;
	and	ds:[di].SSI_spoolOptions, not (mask SO_COLLATE)
	or	ds:[di].SSI_spoolOptions, cl
	ret
SpoolSummonsSetCollateMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageOrderEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the page order options

CALLED BY:	AllOrSelectPageRange()

PASS:		*DS:SI	= SpoolSummons object
		DS:DI	= SpoolSummonsInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageOrderEnableDisable	proc	near
	class	SpoolSummonsClass
	.enter
	
	; If there is more than one page to be printed, enable. Else, disable.
	;
	push	si				; save the chunk handle
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume not enabled...
	mov	cx, ds:[di].SSI_lastUserPage
	cmp	cx, ds:[di].SSI_firstUserPage	; more than one page ??
	jle	setStatus
	mov	ax, MSG_GEN_SET_ENABLED		; else we can collate
setStatus:
	mov	si, offset PrintUI:PageOrderOptions
	mov	dl, VUM_NOW			; update now
	call	ObjCallInstanceNoLock		; send the method
	pop	si
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].SpoolSummons_offset	; SpoolSummonsInstance => DS:DI

	.leave
	ret
PageOrderEnableDisable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Retry & Timeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTimeoutRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the timeout & retry fields

CALLED BY:	SpoolSummonsPrinterSelected
	
PASS:		DS:*SI	= SpoolSummonsClass instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitTimeoutRetry	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter

	; Some set-up work
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	bx, di
	mov	cx, ds:[di].SSI_currentPrinter
	call	AccessPrinterInfoStruct		; PrinterInfoStruct => DS:DI
	mov	dx, ds:[di].PIS_timeout		; timeout value => DX
	mov	ds:[bx].SSI_timeout, dx
	clr	ds:[bx].SSI_retries

	; Set the timeout minimum
	;
	mov	si, offset PrintUI:TimeoutValue
	call	SSSetMinimumValue		; set the minimum value, which
	call	SSSetIntegerValue		; is also the default value
	mov	si, offset PrintUI:RetryValue
	clr	dx
	call	SSSetIntegerValue		; set a minimum value

	.leave
	ret
InitTimeoutRetry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetTimeoutRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the timeout & retry values

CALLED BY:	SpoolSummonsReset

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetTimeoutRetry	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter
	
	; Simply stuff the values into the GenValue objects
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	dx, ds:[di].SSI_backupTimeout
	mov	al, ds:[di].SSI_backupRetries
	clr	ah
	mov	si, offset PrintUI:TimeoutValue
	call	SSSetIntegerValue
	mov_tr	dx, ax
	mov	si, offset PrintUI:RetryValue
	call	SSSetIntegerValue

	.leave
	ret
ResetTimeoutRetry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the timeout value selected by the user

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_TIMEOUT)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		DX	= Time (in seconds)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetTimeout	method dynamic	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_SET_TIMEOUT
	.enter

	mov	ds:[di].SSI_timeout, dx

	.leave
	ret
SpoolSummonsSetTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the retry value selected by the user

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_RETRY)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		DX	= Maximum # of retries

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetRetry	method dynamic	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_SET_RETRY
	.enter

	mov	ds:[di].SSI_retries, dl

	.leave
	ret
SpoolSummonsSetRetry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		PrintToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrintToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Print-To-File options

CALLED BY:	SpoolSummonsPrinterSelected
	
PASS:		DS:*SI	= SpoolSummonsClass instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPrintToFile	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter

	; Enable/disable the printer output types (printer, file)
	;
	mov	di, ds:[si]			; dereference the chunk handle
	add	di, ds:[di].SpoolSummons_offset	; access instance data
	mov	bl, ds:[di].SSI_printerInfo

	mov	bh, mask SSPI_CAPABLE_TO_FILE
	mov	si, offset PrintToFileEntry
	call	EnableOrDisableObject

	not	bl				; enable if bit is not set
	mov	bh, mask SSPI_PRINT_TO_FILE
	mov	si, offset PrintToPrinterEntry
	call	EnableOrDisableObject
	not	bl

	; Set the default for printing to file or not
	;
	clr	cx				; assume printer
	test	bl, (mask SSPI_PRINT_TO_FILE) or (mask SSPI_DEF_PRINT_TO_FILE)
	jz	setExcl
	inc	cx
setExcl:
	mov	si, offset PrintToOptionsList
	call	SSSetItemSelectionStatus	; make selection, send status

	.leave
	ret
InitPrintToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetPrintToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the Print-to-File functionality

CALLED BY:	SpolSummonsReset

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetPrintToFile	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter
	
	; Reset the print-to-file option
	;
	mov	di, ds:[si]			; dereference the chunk handle
	add	di, ds:[di].SpoolSummons_offset	; access instance data
	mov	al, ds:[di].SSI_backupFlags
	clr	cx
	test	al, mask SSF_PRINTING_TO_FILE
	jz	setStatus
	inc	cx				; cx <- 1 if print-to-file
setStatus:
	mov	si, offset PrintToOptionsList
	call	SSSetItemSelectionStatus

	.leave
	ret
ResetPrintToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetPrintToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set or clear the print to file option

CALLED BY:	UI (MSG_SPOOL_SUMMONS_SET_PRINT_TO_FILE)
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data
		CL	= 0 (print to printer) or 1 (print to file)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetPrintToFile	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_PRINT_TO_FILE
	.enter

	; Store the state on an actual change
	;
	mov	ax, mask SSF_PRINTING_TO_FILE
	mov	bh, al
	and	ds:[di].SSI_flags, not (mask SSF_PRINTING_TO_FILE or \
					mask SSF_HAVE_FILE_NAME)
	jcxz	common
	or	ds:[di].SSI_flags, al

	; Enable/disable any necessary groups
common:
	mov	bl, ds:[di].SSI_flags
	not	bl
	mov	si, offset PrintUI:TimeoutRetryGroup
	call	EnableOrDisableObject

	; Now set these things usable/not usable. We do things in this
	; order to avoid having both triggers usable at the same time,
	; possible causing the dialog box to become too wide
	;
	mov	bh, 0xff			; opposite flags => BX
	mov	si, offset PrintOKTrigger
	call	SetUsableOrNotUsableObject

	not	bx				; flags => BX
	mov	si, offset PrintToFileTrigger
	call	SetUsableOrNotUsableObject

	.leave
	ret
SpoolSummonsSetPrintToFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Paper Size & Layout Changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the PaperSize information, by setting the
		system defaults

CALLED BY:	GLOBAL

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPaperSize	proc	near
	class	SpoolSummonsClass
	uses	si
	.enter
	
	; Grab the default page size
	;
	sub	sp, size PageSizeReport
	mov	bp, sp
	push	ds
	segmov	ds, ss, dx
	mov	si, bp
	call	SpoolGetDefaultPageSizeInfo

	; Now set the size of the PageSizeControl
	;
	mov	ax, MSG_PZC_SET_PAGE_SIZE
	pop	ds
	mov	si, offset PrinterPageSizeControl
	call	ObjCallInstanceNoLock
	add	sp, size PageSizeReport

	.leave
	ret
InitPaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPaperSizeMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum width for the printer's paper

CALLED BY:	SpoolChangeInteractionInitiate

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, IS, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPaperSizeMaxWidth	proc	far
		class	SpoolSummonsClass
	
		; Grab the width, and tell the PageSizeControl about it
		;
		mov	di, ds:[si]
		add	di, ds:[di].SpoolSummons_offset
		mov	cx, ds:[di].SSI_currentPrinter
		call	AccessPrinterInfoStruct	; PrinterInfoStruct => DS:DI

		mov	ax, MSG_PZC_SET_MAXIMUM_WIDTH
		mov	cx, ds:[di].PIS_maxWidth
		clr	dx			; maximum width => DX:CX
		mov	si, offset PrinterPageSizeControl
		GOTO	ObjCallInstanceNoLock
SetPaperSizeMaxWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to the report of a page size change

CALLED BY:	SpoolSummonsApply

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		CX	= Width
		DX	= Height
		BP	= PageLayout
		
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPaperSize	proc	near
	.enter

	sub	sp, size PageSizeReport
	mov	bp, sp
	mov	dx, ss
	mov	ax, MSG_PZC_GET_PAGE_SIZE
	mov	si, offset PrinterPageSizeControl
	call	ObjCallInstanceNoLock
	mov	cx, ss:[bp].PSR_width.low
	mov	dx, ss:[bp].PSR_height.low
	mov	bp, ss:[bp].PSR_layout
	add	sp, size PageSizeReport

	.leave
	ret
SpoolSummonsGetPaperSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*****		Error handling routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsRemoteError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle error box requests from the SpoolPrintControl

CALLED BY:	EXTERNAL (MSG_SPOOL_SUMMONS_REMOTE_ERROR)
	
PASS:		DS:DI	= SpoolSummons specific instance data
		CX	= PrintControlErrors
		DX	= Printer number (if needed by error message)
		BP	= Method to send to myself on completion
			  (won't be sent back to caller!)

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsRemoteError	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_REMOTE_ERROR
	.enter

	; Convert printer number if necessary
	;
	mov_tr	ax, bp				; method => AX
	mov	dx, ds:[di].SSI_currentPrinter	; printer => DX
	call	UISpoolErrorBox			; display the box...

	.leave
	ret
SpoolSummonsRemoteError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UISpoolErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the spool process to put up a DB for us

CALLED BY:	INTERNAL
		SpoolSummons Object in various places

PASS:		DS	= PrintUI segment pointer (segment of block whose
			  owner's app object is to be contacted; must be
			  block holding the SpoolSummons if AX is not
			  MSG_META_DUMMY)
		CX	= PrintControlErrors enum
		DX	= Printer number (if needed by error message)
		AX	= Method to send back to myself on completion

RETURN:		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	5/17/90		Added real error box usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STRING_BUFFER_SIZE = 100

FarUISpoolErrorBox proc far
	call	UISpoolErrorBox
	ret
FarUISpoolErrorBox endp

UISpoolErrorBox	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	; Get the correct arguments
	;
	sub	sp, STRING_BUFFER_SIZE		; allocate a small buffer
	mov	bp, sp				; buffer in SS:BP
	push	ax				; save the method to send back
	mov	bx, handle SpoolErrorBlock
	call	MemLock		; segment handle => ES
	mov	es, ax
	pop	ax				; restore method to send back

	; Hack here -- check for non-ensemble product
	;
	call	IsEnsemble
	jc	ensemble
	cmp	cx, PCERR_NO_PRINTERS
	jnz	msg2
	mov	di, offset ErrorNoPrintersGeneric
	jmp	gotErrorChunk
msg2:
	cmp	cx, PCERR_FAIL_FILE_CREATE
	jne	ensemble
	mov	di, offset ErrorFailFileCreateGeneric
	jmp	gotErrorChunk

	; Display normal error message
ensemble:
	cmp	cx, PCERR_EXTERNAL		; external message ??
	je	external
	mov	di, offset ErrorArray
	mov	di, es:[di]			; dereference the chunk
	add	di, cx				; go to the correct error
	mov	cx, es:[di]+2			; ErrorArgumentType
	call	ErrorGetFirstArgument		; first argument => CX:DX
	mov	di, es:[di]			; error string chunk => DI
gotErrorChunk:
	mov	di, es:[di]			; dereference string chunk
	mov	bx, offset PreferenceManagerName
	mov	bx, es:[bx]			; dereference string chunk

	; Put up a standard dialog box...
	;
showDialog:
	sub	sp, size GenAppDoDialogParams
	mov	bp, sp				; SS:BP holds the structure
	mov	ss:[bp].SDP_customFlags, 
			CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
	mov	ss:[bp].SDP_customString.high, es
	mov	ss:[bp].SDP_customString.low, di
	mov	ss:[bp].SDP_stringArg1.high, cx
	mov	ss:[bp].SDP_stringArg1.low, dx
	mov	ss:[bp].SDP_stringArg2.high, es
	mov	ss:[bp].SDP_stringArg2.low, bx
	;ss:[bp].SDP_customTriggers not needed for GIT_NOTIFICATION
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	mov	ss:[bp].GADDP_message, ax	; store the AD
	cmp	ax, MSG_META_DUMMY
	je	noResponse
	mov	ss:[bp].GADDP_finishOD.handle, bx
	mov	ss:[bp].GADDP_finishOD.chunk, offset PrintDialogBox
callApp:
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	MemOwner			; application owner => BX
	call	GeodeGetAppObject		; application => BX:SI
	mov	di, mask MF_FIXUP_DS		; not a call
	call	ObjMessage			; put up the dialog box

	; Clean up (stack and unlock the strings resource)
	;
	add	sp, (size GenAppDoDialogParams) + STRING_BUFFER_SIZE
	mov	bx, handle SpoolErrorBlock
	call	MemUnlock
	stc					; set the carry flag

	.leave
	ret

	; Handle external error message type
external:
	mov	es, dx
	xchg	di, ax				; error message => ES:DI
	mov	ax, MSG_META_DUMMY
	jmp	showDialog

noResponse:
	mov	ss:[bp].GADDP_finishOD.handle, 0
	mov	ss:[bp].GADDP_finishOD.chunk, 0
	jmp	callApp
UISpoolErrorBox	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	IsEnsemble

DESCRIPTION:	See if this is normal Ensemble running

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	carry - set if ensemble

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/28/93		Initial version

------------------------------------------------------------------------------@
IsEnsemble	proc	near	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	segmov	ds, cs
	mov	si, offset uiString
	mov	cx, cs
	mov	dx, offset productNameString
	mov	bp, mask IFRF_READ_ALL
	call	InitFileReadString			;bx = buffer
	jc	done

	call	MemLock
	mov	es, ax
	clr	di
	mov	si, offset ensembleString
	mov	cx, length ensembleString
SBCS <	repe	cmpsb							>
DBCS <	repe	cmpsw							>
	pushf
	call	MemFree
	popf
	stc
	jz	done
	clc

done:
	.leave
	ret

IsEnsemble	endp

uiString		char	"ui", 0
productNameString	char	"productName", 0
if	DBCS_PCGEOS
ensembleString		wchar	"Ensemble", 0
else
ensembleString		char	"Ensemble", 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorGetFirstArgument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the first string argument (if any) for the specific
		error case

CALLED BY:	UISpoolErrorBox
	
PASS:		DS	= PrintUI segment
		CX	= ErrorArgumentType
		DX	= Printer number (if needed by ErrorArgumentType)
		SS:BP	= STRING_BUFFER_SIZE byte buffer

RETURN:		CX:DX	= Error argument #1

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_PRINT_CATEGORY_LENGTH	= 50

if	DBCS_PCGEOS
ssDeviceString		wchar	"device", 0
ssDriverString		wchar	"driver", 0
ssDriverIniString	char	"driver", 0
else
ssDeviceString	char	"device", 0
ssDriverString	char	"driver", 0
endif

ErrorGetFirstArgument	proc	near
	uses	ax, bx, di, si, bp, es
	.enter

	; Nothing to do
	;
	mov	ax, cx				; argument type => AX
	mov	bx, dx				; additional info => BX
	clr	dx				; assume no argument
	tst	cx				; no argument
	jz	done				; we're done

	; Assume corrupt INI file
	;
	mov	cx, cs				; code segment to CX
	mov	dx, offset SpoolSummonsCode:ssDeviceString
	cmp	ax, EAT_DEVICE_FIELD
	je	done
	mov	dx, offset SpoolSummonsCode:ssDriverString
	cmp	ax, EAT_DRIVER_FIELD
	je	done

	; Else we have to go grab a string
	;
	push	ds				; save the object segment
	mov	si, offset PrintUI:PrintDialogBox
	call	SSOpenPrintStrings		; lock the strings block
	mov	dx, bx				; printer mumber => DX
	call	SpoolSummonsGetPrinterCategory	; printer name => DS:SI
	segmov	es, ss, di
	mov	di, bp				; buffer => ES:DI
	CheckHack <ErrorArgumentType lt 256>
	mov	es:[di], ah			; NULL initial buffer
	cmp	ax, EAT_PRINTER_NAME		; use the name of the printer ??
	je	printerName			; yes, so do that work
	ConvPrinterNameToIniCat
EC <	cmp	ax, EAT_DRIVER_NAME		; must be driver name	>
EC <	ERROR_NE PC_ILLEGAL_ARGUMENT_TYPE				>
	mov	cx, cs				; CX:DX is the key to grab
SBCS <	mov	dx, offset SpoolSummonsCode:ssDriverString		>
DBCS <	mov	dx, offset SpoolSummonsCode:ssDriverIniString		>
	mov	bp, (GEODE_NAME_SIZE + 1) or INITFILE_INTACT_CHARS
	call	InitFileReadString		; string => ES:DI
	ConvPrinterNameDone
cleanUp:
	pop	ds				; SpoolSummons => DS:*SI
	mov	si, offset PrintUI:PrintDialogBox
	call	SSClosePrintStrings		; unlock the strings block
	mov	cx, es
	mov	dx, di				; string => CX:DX
done:
	.leave
	ret

	; Just use the printer (category) name
printerName:
	mov	cx, MAX_PRINT_CATEGORY_LENGTH	; # of bytes to copy (at most)
	rep	movsb				; copy the bytes
	mov	di, bp				; ES:DI points to string
	jmp	cleanUp				; finish up
ErrorGetFirstArgument	endp

SpoolSummonsCode	ends
