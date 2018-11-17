COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool/UI
FILE:		uiPrintControl.asm

ROUTINES:
	Name					Description
	----					-----------
Section #1 - Object creation & destruction
    MSG	PrintControlUpdateSpecBuild		MSG_SPEC_BUILD_BRANCH handler
    MSG	PrintControlVisUnbuild			MSG_SPEC_UNBUILD handler
    INT	PrintControlCleanUp			Removes any created UI

Section #2: Changing PrintControl instance data
    MSG	PrintControlSetAttrs			MSG_PRINT_CONTROL handler
    MSG	PrintControlGetAttrs			MSG_PRINT_CONTROL handler
    MSG	PrintControlSetTotalPageRange		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetTotalPageRange		MSG_PRINT_CONTROL handler
    MSG	PrintControlSetSelectedPageRange	MSG_PRINT_CONTROL handler
    MSG	PrintControlGetSelectedPageRange	MSG_PRINT_CONTROL handler
    MSG	PrintControlSetDocSize			MSG_PRINT_CONTROL handler
    MSG	PrintControlGetDocSize			MSG_PRINT_CONTROL handler
    MSG	PrintControlSetExtendedDocSize		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetExtendedDocSize		MSG_PRINT_CONTROL handler
    MSG	PrintControlSetDocMargins		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetDocMargins		MSG_PRINT_CONTROL handler
    MSG	PrintControlSetAppPrintUI		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetAppPrintUI		MSG_PRINT_CONTROL handler
    MSG	PrintControlSetOutput			MSG_PRINT_CONTROL handler
    MSG	PrintControlGetOutput			MSG_PRINT_CONTROL handler
    MSG	PrintControlSetDefaultPrinter		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetDefaultPrinter		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetPrinterMode		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetPaperSize		MSG_PRINT_CONTROL handler
    MSG	PrintControlGetPrinterMargins		MSG_PRINT_CONTROL handler
    MSG	PrintControlCalcDocumentDimensions	MSG_PRINT_CONTROL handler
    MSG	PrintControlVerifyDocMargins		MSG_PRINT_CONTROL handler
    MSG	PrintControlVerifyDocSize		MSG_PRINT_CONTROL handler
    MSG	PrintControlVerifyError			MSG_PRINT_CONTROL handler

Section #3: Handlers & routines for printing
    MSG	PrintControlInitiatePrint		PRINT_CONTROL handler
    INT	InitializeDialogBox			Initializes the print dialog box
    MSG	PrintControlPrint			MSG_PRINT_CONTROL handler
    MSG	PrintControlSpoolingUpdate		MSG_PRINT_CONTROL handler
    MSG	PrintControlSetDocName			MSG_PRINT_CONTROL handler
    MSG	PrintControlPrintingCompleted		MSG_PRINT_CONTROL handler
    MSG	PrintControlPrintingCancelled		MSG_PRINT_CONTROL handler
    MSG	PrintControlVerifyPrint			MSG_PRINT_CONTROL handler
    INT	StartPrintJob				Sends print job to the spooler

    INT	PrintGetDocumentInfo			Fill in JobParameters
    INT	PrintGetApplicationName			Obtain the application name
    INT	PrinterGetPortInfo			Obtain printer port information
    INT	PrinterGetBaudRate			- baud rate
    INT	PrinterGetParity			- parity
    INT	PrinterGetWordLength			- word length
    INT	PrinterGetStopBits			- stop bits
    INT	PrinterGetHandshake			- handshake modes
    INT	PrinterGetControlBits			- control bits
    INT	PrintRequestUIOptions			Obtain any printer UI options
    INT	PrintCreateSpoolFile			Create the spool file
    INT	PrintRequestDocName			Have document name request sent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Don	2/90		Much added functionality
	Don	1/92		Documentation, new methods, general clean-up

DESCRIPTION:

	$Id: uiPrintControl.asm,v 1.2 98/02/17 03:56:00 gene Exp $

------------------------------------------------------------------------------@

PrintControlCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the PrintControl object

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		*DS:SI	= PrintControlControlClass object
		DS:DI	= PrintControlControlClassInstance
		CX:DX	= GenControlBuildInfo

RETURN:		Nothing

DESTROYED:	CX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetInfo	method dynamic 	PrintControlClass,
						MSG_GEN_CONTROL_GET_INFO
		.enter
	;
	; Note whether we're in address-control mode.
	; 
		call	PCIsAddrControl

		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset PC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb
		jnc	done			; => not for address control
	;
	; Turn off child shme if in address control.
	; 
		mov	di, dx
		mov	es:[di].GCBI_childCount, length PC_addrCtrlChildList
		mov	es:[di].GCBI_childList.offset, 
				offset PC_addrCtrlChildList
		mov	es:[di].GCBI_childList.segment,
				vseg PC_addrCtrlChildList
		mov	es:[di].GCBI_dupBlock, handle PrintDialogBox
		mov	es:[di].GCBI_featuresCount, 0
		ornf	es:[di].GCBI_flags, 
			mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST

done:

		.leave
		ret
PrintControlGetInfo	endm

PC_dupInfo	GenControlBuildInfo		<
		mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED,
						; GCBI_flags
		PC_initFileKey,			; GCBI_initFileKey
		PC_gcnList,			; GCBI_gcnList
		length PC_gcnList,		; GCBI_gcnCount
		0,				; GCBI_notificationList
		0,				; GCBI_notificationCount
		PCName,				; GCBI_controllerName

		handle PrintControlUI,		; GCBI_dupBlock
		PC_childList,			; GCBI_childList
		length PC_childList,		; GCBI_childCount
		PC_featuresList,		; GCBI_featuresList
		length PC_featuresList,		; GCBI_featuresCount
		PRINTC_DEFAULT_FEATURES,		; GCBI_features

		handle PrintControlToolboxUI,	; GCBI_toolBlock
		PC_toolList,			; GCBI_toolList
		length PC_toolList,		; GCBI_toolCount
		PC_toolFeaturesList,		; GCBI_toolFeaturesList
		length PC_toolFeaturesList,	; GCBI_toolFeaturesCount
		PRINTC_DEFAULT_TOOLBOX_FEATURES,; GCBI_toolFeatures
		0,				; GCBI_helpContext
		0>				; GCBI_reserved

PC_initFileKey		char	"printControl", 0

PC_gcnList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, GAGCNLT_MODAL_WIN_CHANGE>

PC_addrCtrlChildList	GenControlChildInfo \
		<offset PrintDialogBox, 0, mask GCCF_ALWAYS_ADD>

PC_childList		GenControlChildInfo \
			<offset PrintTrigger, mask PRINTCF_PRINT_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset FaxTrigger, mask PRINTCF_FAX_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

PC_featuresList		GenControlFeaturesInfo \
			<offset FaxTrigger, FaxTriggerName, 0>,
			<offset PrintTrigger, PrintTriggerName, 0>

PC_toolList		GenControlChildInfo \
			<offset PrintToolTrigger, mask PRINTCTF_PRINT_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset FaxToolTrigger, mask PRINTCTF_FAX_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

PC_toolFeaturesList	GenControlFeaturesInfo \
			<offset FaxToolTrigger, FaxTriggerToolName, 0>,
			<offset PrintToolTrigger, PrintTriggerToolName, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCGenControlGetNormalFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to make sure we stay user-initiatable even in address-
		control mode (where we support no features)

CALLED BY:	MSG_GEN_CONTROL_GET_NORMAL_FEATURES
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
RETURN:		ax	= current normal feature set
		cx	= required normal features
		dx	= prohibited normal features
		bp	= normal features supported by controller
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCGenControlGetNormalFeatures method dynamic PrintControlClass, 
				MSG_GEN_CONTROL_GET_NORMAL_FEATURES
		call	PCIsAddrControl
		jc	hackFeatures
		
		mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
		mov	di, offset PrintControlClass
		GOTO	ObjCallSuperNoLock

hackFeatures:
		clr	dx, ax
		dec	ax
		mov	cx, ax
		mov	bp, ax
		ret
PCGenControlGetNormalFeatures endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate either the normal or toolbox UI

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGenerateUI	method dynamic	PrintControlClass,
					MSG_GEN_CONTROL_GENERATE_UI,
					MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
		.enter

		; First call our superclass
		;
		push	ax
		mov	di, offset PrintControlClass
		call	ObjCallSuperNoLock

		; Add ourselves to the global GCN list
		;
		mov	ax, GCNSLT_INSTALLED_PRINTERS
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListAdd
		pop	ax

		; When operating in address-control mode, automatically
		; initialize our UI.
		
		push	ax
		mov	ax, TEMP_PRINT_CONTROL_ADDRESS_CONTROL
		call	ObjVarFindData
		pop	ax
		jnc	done

		mov	cl, ds:[bx].TPACD_driverType

		cmp	ax, MSG_GEN_CONTROL_GENERATE_UI
		jne	done			; => didn't generate "summons"
		
		call	addExpandWidth		; make us expand to fit
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GI_comp.CP_firstChild.handle
		mov	di, ds:[di].GI_comp.CP_firstChild.chunk
		xchg	si, di			; ^lbx:si <- SpoolSummons
						; *ds:di <- PrintControl

		; make sure the interaction fills the width of the send
		; control's dialog

		call	ObjSwapLock
		call	addExpandWidth
		call	ObjSwapUnlock

		push	cx
		call	InitializeDialogBox
		pop	cx

		mov	ax, MSG_SPOOL_SUMMONS_SET_DRIVER_TYPE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret

addExpandWidth:
		push	bx, cx
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		clr	cx
		call	ObjVarAddData
		pop	bx, cx
		retn
PrintControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCPrintCannotPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the SpoolSummons thinks it cannot print

CALLED BY:	MSG_PRINT_CANNOT_PRINT
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
		cx	= PrintControlError to put up
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCPrintCannotPrint method dynamic PrintControlClass, MSG_PRINT_CANNOT_PRINT
		.enter
		push	cx
		call	PCIsAddrControl
		jnc	dismissBox
	;
	; Address control: tell the address control that its address is invalid
	;
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_STATE
		clr	cx
		call	PCCallAddressControl

putUpError:
	;
	; Tell the user why s/he's hosed.
	;
		pop	cx
		mov	ax, MSG_META_DUMMY		; no response, thanks
		call	FarUISpoolErrorBox
		.leave
		ret

dismissBox:
	;
	; When not an address control, the inability to print keeps the
	; box from coming up.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	FarPCCallSummons
		jmp	putUpError
PCPrintCannotPrint endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCGenControlTweakDuplicatedUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If PrintControl is operating in address-control mode, adjust
		the duplicated SpoolSummons object to conform to our
		needs.

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
		cx	= handle of duplicated UI block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCGenControlTweakDuplicatedUi method dynamic PrintControlClass, 
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
		.enter
		mov	bx, cx			; save child block handle
		mov	di, offset PrintControlClass
		call	ObjCallSuperNoLock
		
		call	PCIsAddrControl
		jnc	done
	;
	; Now adjust the "dialog box" to be a control group, instead.
	; 
		push	si
		call	ObjSwapLock

		mov	si, offset PrintDialogBox
		mov	ax, MSG_GEN_INTERACTION_SET_TYPE
		mov	cl, GIT_ORGANIZATIONAL
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
		mov	cl, GIV_SUB_GROUP
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
		mov	cx, (mask GIA_MODAL or \
				mask GIA_NOT_USER_INITIATABLE) shl 8
		call	ObjCallInstanceNoLock
	;
	; Nuke the moniker -- we don't want it any more, thanks; it looks weird
	; 
		clr	cx
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock
	;
	; Set not-usable those parts of the dialog that are inappropriate for
	; this use:
	; 	- the Print/Fax/Print to File triggers
	; 
		push	si
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	si, offset PrintTriggerGroup
		call	ObjCallInstanceNoLock
		pop	si
		
		call	ObjSwapUnlock
	;
	; Make sure any application-ui is added.
	; 
		pop	di		; *ds:di <- PC
					; ^lbx:si = summons
		call	PCAddAppUI
done:
		.leave
		ret
PCGenControlTweakDuplicatedUi		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCGenControlDestroyUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If in address-control mode, remove any app-ui from the
		duplicated summons.

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCGenControlDestroyUi method dynamic PrintControlClass, 
				MSG_GEN_CONTROL_DESTROY_UI
		call	PCIsAddrControl
		jnc	done
		
		mov	ax, ATTR_PRINT_CONTROL_APP_UI
		call	ObjVarFindData
		jnc	done
		
		push	si
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	si
done:
		mov	di, offset PrintControlClass
		mov	ax, MSG_GEN_CONTROL_DESTROY_UI
		GOTO	ObjCallSuperNoLock
PCGenControlDestroyUi endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Watch for GAGCNLT_MODAL_WIN_CHANGE, & re-check wether
		print completion message should be sent out.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_NOTIFY

		cx:dx	- GCN notification type

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintNotify	method	PrintControlClass, MSG_META_NOTIFY
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	toSuper
	cmp	dx, GWNT_MODAL_WIN_CHANGE
	je	modalWinChange
toSuper:
	mov	di, offset PrintControlClass
	GOTO	ObjCallSuperNoLock

modalWinChange:
	FALL_THRU	CheckUpOnPrintCompletionMessage
PrintNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckUpOnPrintCompletionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if printing is now complete

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrintControlClass object

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Doug	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckUpOnPrintCompletionMessage	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter

	; Are we in the middle of printing? If so, continue until done
	;
	call	PCAccessTemp			; access the local data
	tst	ds:[di].TPCI_jobParHandle	; JobParameters handle ??
	jnz	done				; yes, so do nothing
	tst	ds:[di].TPCI_holdUpCompletionCount
	jnz	done				; Wait for anyone else...

	; Are we in the middle of a DETACH? If so, then now is
	; the time to destroy our children and clean up.
	;
	mov	ax, DETACH_DATA
	call	ObjVarFindData
	jnc	enabled?
	call	PCDestroySummons
	call	ObjEnableDetach

	; Are we enabled (i.e. is it even possible for the user to interact
	; with the print dialog?)
enabled?:
	mov	ax, MSG_GEN_GET_ENABLED
	call	ObjCallInstanceNoLock
	jnc	dispatch			; no, dispatch to show done.

	; Is the dialog box still up? If so, continue until done
	;
	mov	ax, MSG_GEN_APPLICATION_GET_MODAL_WIN
	call	GenCallApplication
	tst	cx				; if there's a modal window
	jnz	done				; up, not done.

	; Send the print completion event, if one exists
dispatch:
	call	DispatchPrintCompletionEvent	; Dispach it, if there
done:
	.leave
	ret
CheckUpOnPrintCompletionMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DispatchPrintCompletionEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatch an event

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrintControlClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Doug	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DispatchPrintCompletionEvent	proc	far
	uses	es
	.enter
	mov	ax, TEMP_PRINT_COMPLETION_EVENT	; If no completion message,
	call	ObjVarFindData			; nothing to do.
	jnc	done
	mov	cx, ds:[bx].TPCED_event		; get stored message
	mov	dx, ds:[bx].TPCED_messageFlags
	mov	ax, MSG_META_DISPATCH_EVENT	; dispatch completion msg
	mov	di, segment PrintControlClass
	mov	es, di
	mov	di, offset PrintControlClass
	call	ObjCallSuperNoLock
	mov	ax, TEMP_PRINT_COMPLETION_EVENT	; delete stored message
	call	ObjVarDeleteData
done:
	.leave
	ret
DispatchPrintCompletionEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlScanFeatureHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the feature hints to find required & prohibited features

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_SCAN_FEATURE_HINTS)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
		CX	= GenControlUIType
		DX:BP	= GenControlScanInfo

RETURN:		Nothing

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlScanFeatureHints	method dynamic	PrintControlClass,
				MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
		.enter

		; First we call our superclass to fill structure
		;
		mov	di, offset PrintControlClass
		call	ObjCallSuperNoLock

		; If fax drivers are available, we're set. Else, we
		; need to prohibit the fax feature or tool
		;
		call	PCAccessTemp
		test	ds:[di].TPCI_status, mask PSF_FAX_AVAILABLE
		jnz	done			; if available, we're done
		mov	ax, mask PRINTCF_FAX_TRIGGER
		cmp	cx, GCUIT_NORMAL
		je	prohibit
		mov	ax, mask PRINTCTF_FAX_TRIGGER
prohibit:
		mov	es, dx			; GenControlScanInfo => ES:BP
		or	es:[bp].GCSI_appProhibited, ax
done:
		.leave
		ret
PrintControlScanFeatureHints	endm

PrintControlCommon ends

;---

PrintControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize those parts of our instance data that are non-zero

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCMetaInitialize method dynamic PrintControlClass, MSG_META_INITIALIZE
		mov	ds:[di].PCI_attrs, PrintControlAttrs <>
		mov	ds:[di].PCI_startPage, 1
		mov	ds:[di].PCI_endPage, 1
		mov	ds:[di].PCI_endUserPage, 0x7fff
		mov	ds:[di].PCI_defPrinter, -1
		mov	di, offset PrintControlClass
		GOTO	ObjCallSuperNoLock
PCMetaInitialize endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove any additional application-defined UI

CALLED BY:	GLOBAL (MSG_META_DETACH)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
		ES	= Segment of PrintControlClass

		CX, DX, BP = detach data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlDetach	method dynamic	PrintControlClass,
					MSG_META_DETACH,
					MSG_SPEC_UNBUILD

		; Destroy the Print dialog box, unless we are in
		; the middle of printing. If that's the case, then
		; we increment the detach count and do nothing (if
		; we are DETACHing).
		;
		push	ax, cx, dx, bp		; save message and data
		call	PCDestroySummons	; free the spool summons object
		jnc	removeFromGCN
		pop	ax, cx, dx, bp
		cmp	ax, MSG_SPEC_UNBUILD
		je	continue
		call	ObjInitDetach
continue:
		push	ax, cx, dx, bp

		; Remove ourselves from the global GCN list
removeFromGCN:
		mov	ax, GCNSLT_INSTALLED_PRINTERS
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListRemove

		; Call our superclass to finish things up
		;
		pop	ax, cx, dx, bp		; restore message
		mov	di, offset PrintControlClass
		GOTO	ObjCallSuperNoLock
PrintControlDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to InteractionCommand's

CALLED BY:	GLOBAL (MSG_GEN_GUP_INTERACTION_COMMAND)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
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

PrintControlGenGupInteractionCommand	method dynamic	PrintControlClass,
					MSG_GEN_GUP_INTERACTION_COMMAND

		; If we are dimissing, ensure we destroy Print & Options UI
		;
		CheckHack <IC_NULL eq 0>
		CheckHack <IC_DISMISS eq 1>
		cmp	cx, IC_DISMISS		; jump if not IC_NULL nor
		ja	callSuperClass		; ...IC_DISMISS

		push	ax, cx, dx, bp
		call	PCIsAddrControl
		jc	tellPrinterChangeBox

		call	PCCallSummons		; send DISMISS to Print DB
popCallSuper:
		pop	ax, cx, dx, bp
callSuperClass:
		mov	di, offset PrintControlClass
		GOTO	ObjCallSuperNoLock

tellPrinterChangeBox:
	;
	; In the address-control case, the summons isn't a dialog, but the
	; PrinterChangeBox is, so we tell it, rather than telling the
	; dialog and relying on it to tell the change box.
	; 
		push	si
		call	PCGetSummons
		jnc	tellPrinterChangeBoxDone
		mov	si, offset PrinterChangeBox
		push	ax
		call	PCObjMessageSend
		pop	ax
		mov	si, offset PrintFileDialogBox
		call	PCObjMessageSend
tellPrinterChangeBoxDone:
		pop	si
		jmp	popCallSuper
PrintControlGenGupInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlPrinterInstalledRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Be notified that a printer has been installed or removed

CALLED BY:	GLOBAL (MSG_PRINTER_INSTALLED_REMOVED)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlPrinterInstalledRemoved	method dynamic	PrintControlClass,
					MSG_PRINTER_INSTALLED_REMOVED
		.enter

		; don't need to rebuild UI if addr control, as features don't
		; change...
		call	PCIsAddrControl
		jc	done

		; All we're interested in knowing is whether or not
		; any fax drivers have been installed or removed.
		;
		call	PCAccessTemp
		call	PCCheckForFax		; check for status change
		jz	done			; if no change, jump

		; We need to re-evaluate the features available for
		; this PrintControl object. Send message via queue, else
		; we'll get deadlock in trying to access the GCN block.
		;
		mov	bx, ds:[LMBH_handle]	; PrintControl OD => ^lBX:SI
		mov	ax, MSG_GEN_CONTROL_REBUILD_NORMAL_UI
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		
		mov	ax, MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		

		; Tell the SpoolSummons object about the change
done:
		mov	ax, MSG_PRINTER_INSTALLED_REMOVED
		call	PCCallSummons		; call the SpoolSummons object

		.leave
		ret
PrintControlPrinterInstalledRemoved	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Section #2: Changing PrintControl instance data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current application print attributes

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_ATTRS)

PASS: 		DS:*SI	= PrintControl object
		DS:DI	= PrintControlInstance
		CX	= PrintControlAttrs

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetAttrs	method 	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_SET_ATTRS
	.enter

	; Store the new attributes
	;
EC <	test	cx, not PrintControlAttrs	; check for illegal bits >
EC <	ERROR_NZ	PC_SET_ATTRS_INVALID_ATTRIBUTES		>
	mov	ds:[di].PCI_attrs, cx		; store the attributes
	mov	ax, MSG_SPOOL_SUMMONS_SET_PRINT_ATTRS
	call	PCCallSummons

	.leave
	ret
PrintControlSetAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current application-defined print attributes

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_ATTRS)

PASS: 		DS:DI	= PrintControlInstance

RETURN:		CX	= PrintControlAttrs

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetAttrs	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_GET_ATTRS
	.enter

	mov	cx, ds:[di].PCI_attrs

	.leave
	ret
PrintControlGetAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetTotalPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the the first & last page numbers in a document

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE)

PASS:		DS:*SI	= PrintControl object
 		DS:DI	= PrintControlInstance
		CX	= First page
		DX	= Last page

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetTotalPageRange	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	.enter

	; Store the new values - reset the print group if necessary
	;
EC <	cmp	dx, cx				; last must be > than first >
EC <	ERROR_B	PC_SET_TOTAL_PAGE_LAST_LESS_THAN_FIRST			>
	cmp	cx, ds:[di].PCI_startPage
	jne	callSpoolSummons
	cmp	dx, ds:[di].PCI_endPage
callSpoolSummons:
	pushf					; save the current flags
	mov	ds:[di].PCI_startPage, cx
	mov	ds:[di].PCI_endPage, dx
	mov	ax, MSG_SPOOL_SUMMONS_SET_PAGE_RANGE
	call	PCCallSummons

	; Also reset the user page range (if range is different)
	;
	popf					; restore flags
	je	done				; if no change, do nothing
	mov	cx, ds:[di].PCI_startUserPage
	mov	dx, ds:[di].PCI_endUserPage
	mov	ax, MSG_SPOOL_SUMMONS_SET_USER_PAGE_RANGE
	call	PCCallSummons
done:
	.leave
	ret
PrintControlSetTotalPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetTotalPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current total page range

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE)

PASS: 		DS:DI	= PrintControlInstance

RETURN:		CX	= First page (>= 1)
		DX	= Last page (>= First page)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetTotalPageRange	method dynamic PrintControlClass,
				MSG_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE
	.enter

	mov	cx, ds:[di].PCI_startPage
	mov	dx, ds:[di].PCI_endPage

	.leave
	ret
PrintControlGetTotalPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetSelectedPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selected range of pages to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_SELECTED_PAGE_RANGE)

PASS: 		DS:*SI	= PrintControl object
		DS:DI	= PrintControlInstance
		CX	= Starting page
		DX	= Ending page

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetSelectedPageRange	method dynamic PrintControlClass,
				MSG_PRINT_CONTROL_SET_SELECTED_PAGE_RANGE
	.enter

EC <	cmp	dx, cx				; last must be > first	>
EC <	ERROR_B	PC_SET_SELECTED_PAGE_LAST_LESS_THAN_FIRST		>
	mov	ds:[di].PCI_startUserPage, cx
	mov	ds:[di].PCI_endUserPage, dx
	mov	ax, MSG_SPOOL_SUMMONS_SET_USER_PAGE_RANGE
	call	PCCallSummons

	.leave
	ret
PrintControlSetSelectedPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetSelectedPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the user-selected range of pages to print

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE)

PASS: 		DS:*SI	= PrintControl object
 		DS:DI	= PrintControlInstance

RETURN:		CX	= Starting page
		DX	= Ending page

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetSelectedPageRange	method	PrintControlClass,
			MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	uses	ax, bp
	.enter

	mov	cx, ds:[di].PCI_startUserPage	; assume no address control
	mov	dx, ds:[di].PCI_endUserPage

if not LIMITED_FAX_SUPPORT
	;
	; If there's an address control, we must ask it what the pages are;
	; that's how the user is expected to select them in this world.
	;
	mov	ax, MSG_MSAC_GET_PAGE_RANGE
	call	PCCallAddressControl
	jc	done
endif

	mov	ax, MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE
	call	PCCallSummons
done:
	.leave
	ret
PrintControlGetSelectedPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetMailboxObjectType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're associated with an address control, ask it for
		the object type and transaction handle for the current print
		job

CALLED BY:	MSG_PRINT_GET_MAILBOX_OBJECT_TYPE
PASS:		*ds:si	= PrintControl object
		ds:di	= PrintControlInstance
RETURN:		carry set if print request not from a MailboxSendControl
			ax, bp = destroyed
		carry clear if MailboxObjectType returned:
			ax	= MailboxObjectType
			bp	= transaction handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCPrintControlGetMailboxObjectType method dynamic PrintControlClass, 
				MSG_PRINT_GET_MAILBOX_OBJECT_TYPE
		uses	dx
		.enter
		mov	ax, MSG_MSAC_GET_OBJECT_TYPE
		call	PCCallAddressControl
		cmc
		.leave
		ret
PCPrintControlGetMailboxObjectType		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the document size to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DOC_SIZE)

PASS: 		DS:DI	= PrintControlInstance
		CX	= Document width
		DX	= Document height

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDocSize	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_SET_DOC_SIZE
	.enter

	clr	bx				; clear high word of size
	movdw	ds:[di].PCI_docSizeInfo.PSR_width, bxcx
	movdw	ds:[di].PCI_docSizeInfo.PSR_height, bxdx

	.leave
	ret
PrintControlSetDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size of the document to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_DOC_SIZE

PASS: 		DS:DI	= PrintControlInstance

RETURN:		CX	= Document width
		DX	= Document height

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetDocSize	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_GET_DOC_SIZE
	.enter

EC <	tst	ds:[di].PCI_docSizeInfo.PSR_width.high			>
EC <	ERROR_NZ PC_GET_DOC_SIZE_DIMENSION_IS_32_BIT_VALUE		>
EC <	tst	ds:[di].PCI_docSizeInfo.PSR_height.high			<
EC <	ERROR_NZ PC_GET_DOC_SIZE_DIMENSION_IS_32_BIT_VALUE		>
	mov	cx, ds:[di].PCI_docSizeInfo.PSR_width.low
	mov	dx, ds:[di].PCI_docSizeInfo.PSR_height.low

	.leave
	ret
PrintControlGetDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetExtendedDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the document size to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_EXTENDED_DOC_SIZE)

PASS: 		DS:DI	= PrintControlInstance
		DX:BP	= PCDocSizeParams

RETURN:		Nothing

DESTROYED:	BX, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetExtendedDocSize	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_EXTENDED_DOC_SIZE
	.enter

	mov	es, dx				; PCDocSizeParams => ES:BP
	movdw	bxsi, es:[bp].PCDSP_width
	movdw	ds:[di].PCI_docSizeInfo.PSR_width, bxsi
	movdw	bxsi, es:[bp].PCDSP_height
	movdw	ds:[di].PCI_docSizeInfo.PSR_height, bxsi

	.leave
	ret
PrintControlSetExtendedDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetExtendedDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size of the document to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_EXTENDED_DOC_SIZE

PASS: 		DS:DI	= PrintControlInstance
		DX:BP	= PCDocSizeParams (empty)

RETURN:		DX:BP	= PCDocSizeParams (filled)

DESTROYED:	BX, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetExtendedDocSize	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_EXTENDED_DOC_SIZE
	.enter

	mov	es, dx				; PCDocSizeParams => ES:BP
	movdw	bxsi, ds:[di].PCI_docSizeInfo.PSR_width
	movdw	es:[bp].PCDSP_width, bxsi	; store the width
	movdw	bxsi, ds:[di].PCI_docSizeInfo.PSR_height	
	movdw	es:[bp].PCDSP_height, bxsi	; store the height

	.leave
	ret
PrintControlGetExtendedDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDocMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the document margins, so PrintControl can determine
		if the printer can fully display the passed document

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DOC_MARGINS)
	
PASS:		DS:DI	= PrintControlInstance
		DX:BP	= PCMarginParams

RETURN:		Nothing

DESTROYED:	BX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDocMargins	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_DOC_MARGINS
	.enter

	; Store this data away
	;
	mov	es, dx
	mov	bx, es:[bp].PCMP_left
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_left, bx
	mov	bx, es:[bp].PCMP_top
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_top, bx
	mov	bx, es:[bp].PCMP_right
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_right, bx
	mov	bx, es:[bp].PCMP_bottom
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_bottom, bx

	.leave
	ret
PrintControlSetDocMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetDocMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the document margins set by the application.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_DOC_MARGINS)
	
PASS:		DS:DI	= PrintControlInstance
		DX:BP	= PCMarginParams (empty)

RETURN:		DX:BP	= PCMarginParams (filled)

DESTROYED:	BX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetDocMargins	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_DOC_MARGINS
	.enter

	; Copy the data in the structure
	;
	mov	es, dx				; PCMarginParams => ES:BP
	mov	bx, ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_left
	mov	es:[bp].PCMP_left, bx
	mov	bx, ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_top
	mov	es:[bp].PCMP_top, bx
	mov	bx, ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_right
	mov	es:[bp].PCMP_right, bx
	mov	bx, ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_bottom
	mov	es:[bp].PCMP_bottom, bx

	.leave
	ret
PrintControlGetDocMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDocSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the document size to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO)

PASS: 		DS:DI	= PrintControlInstance
		DX:BP	= PageSizeReport

RETURN:		Nothing

DESTROYED:	BX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDocSizeInfo	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO
	uses	cx
	.enter

	segmov	es, ds
	add	di, offset PCI_docSizeInfo	; destination => ES:DI
	mov	ds, dx
	mov	si, bp				; source => DS:SI
	mov	cx, size PageSizeReport
	rep	movsb

	.leave
	ret
PrintControlSetDocSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetDocSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size of the document to be printed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO

PASS: 		DS:DI	= PrintControlInstance
		DX:BP	= PageSizeReport buffer

RETURN:		DX:BP	= PageSizeReport filled

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetDocSizeInfo	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO
	.enter

	mov	si, di
	add	si, offset PCI_docSizeInfo	; source => DS:SI
	mov	es, dx
	mov	di, bp				; destination => ES:DI
	mov	cx, size PageSizeReport
	rep	movsb

	.leave
	ret
PrintControlGetDocSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the output of the PC - destination of the print method

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_OUTPUT)

PASS: 		DS:*SI	= PrintControl instance data
		DS:DI	= PrintControl specific instance data
		CX:DX	= New Output Descriptor

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetOutput	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_OUTPUT
	.enter

	; Store the passed information
	;
	mov	ds:[di].PCI_output.handle, cx	; store the block handle
	mov	ds:[di].PCI_output.chunk, dx	; store the chunk handle
	
	.leave
	ret
PrintControlSetOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current OD of the PrintControl object

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_OUTPUT)

PASS:		DS:DI	= PrintControl specific instance data

RETURN:		CX:DX	= Output Descriptor

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetOutput	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_OUTPUT
	.enter

	mov	cx, ds:[di].PCI_output.handle	; block handle => CX
	mov	dx, ds:[di].PCI_output.chunk	; chunk handle => DX

	.leave
	ret
PrintControlGetOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDocNameOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the output of the PrintControl to receive
		MSG_PRINT_GET_DOC_NAME.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DOC_NAME_OUTPUT)

PASS: 		DS:*SI	= PrintControl instance data
		DS:DI	= PrintControl specific instance data
		CX:DX	= New Output Descriptor

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDocNameOutput	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_DOC_NAME_OUTPUT
	.enter

	; Store the passed information
	;
	mov	ds:[di].PCI_docNameOutput.handle, cx	; store the block handle
	mov	ds:[di].PCI_docNameOutput.chunk, dx	; store the chunk handle
	
	.leave
	ret
PrintControlSetDocNameOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetDocNameOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current OD of the PrintControl object

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_DOC_NAME_OUTPUT)

PASS:		DS:DI	= PrintControl specific instance data

RETURN:		CX:DX	= Output Descriptor

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetDocNameOutput	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_DOC_NAME_OUTPUT
	.enter

	mov	cx, ds:[di].PCI_docNameOutput.handle	; block handle => CX
	mov	dx, ds:[di].PCI_docNameOutput.chunk	; chunk handle => DX

	.leave
	ret
PrintControlGetDocNameOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the application-default printer

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER)
	
PASS:		DS:*SI	= PrintControl object
		DS:DI	= PrintControlInstance
		CX	= Printer number

RETURN:		Nothing

DESTROYED:	AX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDefaultPrinter	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER
	.enter

	; Store the passed information
	;
	mov	ds:[di].PCI_defPrinter, cx	; store the default printer
	mov	ax, MSG_SPOOL_SUMMONS_SET_DEFAULT_PRINTER
	call	PCCallSummons

	.leave
	ret
PrintControlSetDefaultPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the application-default printer

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER)
	
PASS: 		DS:DI	= PrintControlInstance

RETURN:		CX	= Printer number

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetDefaultPrinter	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_DEFAULT_PRINTER
	.enter

	; Store the passed information
	;
	mov	cx, ds:[di].PCI_defPrinter	; get the default printer

	.leave
	ret
PrintControlGetDefaultPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetPrinterMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current printer mode (if box is up)

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_PRINT_MOE)
	
PASS:		DS:*SI	= PrintControl object

RETURN:		CL	= PrinterMode or 0 if none is yet selected

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetPrinterMode	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_PRINT_MODE
	.enter

	; Verify that we're in the middle of printing
	;
EC <	call	PCAccessTemp			; access local data	>
EC <	tst	ds:[di].TPCI_fileHandle		; open print file ??	>
EC <	ERROR_Z CANNOT_CALL_THIS_FUNCTION_WHILE_NOT_PRINTING		>

	; Now request summons to provide selected mode
	;
	clr	cl				; assume the DB is not up
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINT_MODE
	call	PCCallSummons			; send the method on...

	.leave
	ret
PrintControlGetPrinterMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetPaperSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the paper size for the currently selected printer

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO)

PASS: 		DS:*SI	= PrintControl instance data
		DX:BP	= PageSizeReport buffer

RETURN:		DX:BP	= PageSizeReport filled

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This is really only useful when an application is in the
		middle of printing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/25/90		Initial version
	Don	4/16/91		Works with any printer now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetPaperSizeInfo	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO
	uses	ax
	.enter

	; Determine if we want the current printer or not
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_PAPER_SIZE_INFO
	call	PCCallSummons			; return various pieces of info

	.leave
	ret
PrintControlGetPaperSizeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the paper size for the currently selected printer

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_PAPER_SIZE)

PASS: 		DS:*SI	= PrintControl instance data

RETURN:		AX:CX	= Paper width
		BP:DX	= Paper height

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This is really only useful when an application is in the
		middle of printing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/25/90		Initial version
	Don	4/16/91		Works with any printer now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetPaperSize	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_GET_PAPER_SIZE
	.enter

	; Determine if we want the current printer or not
	;
	sub	sp, (size PageSizeReport)
	mov	dx, ss
	mov	bp, sp
	mov	ax, MSG_SPOOL_SUMMONS_GET_PAPER_SIZE_INFO
	call	PCCallSummons			; return various pieces of info
	mov	bx, bp				; PageSizeReport => SS:BX
	movdw	axcx, ss:[bx].PSR_width
	movdw	bpdx, ss:[bx].PSR_height
	add	sp, (size PageSizeReport)

	.leave
	ret
PrintControlGetPaperSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlGetPrinterMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the margins used by the current printer

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_GET_PRINTER_MARGINS)
	
PASS:		DS:*SI	= PrintControl instance data
		DX	= TRUE  - set document margins to follow printer margins
			= FALSE - don't do this

RETURN:		AX	= Left margin
		CX	= Top margin
		DX	= Right margin
		BP	= Bottom margin

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlGetPrinterMargins	method	PrintControlClass,
				MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
	.enter

	; Grab the margins from the SpoolSummons
	;
EC <	cmp	dx, TRUE			; verify the boolean	>
EC <	je	doneEC				; if valid, jump	>
EC <	cmp	dx, FALSE			; verify the boolean	>
EC <	ERROR_NE PC_GET_PRINT_MARGINS_BOOLEAN_NOT_PASSED		>
EC <doneEC:								>
	mov	di, dx
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINTER_MARGINS
	call	PCForceCallSummons		; returns ax, cx, dx, bp
	tst	di				; copy margin values ??
	jz	done				; if FALSE, we're done
	mov	di, ds:[si]			; dereference the instance data
	add	di, ds:[di].PrintControl_offset
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_left, ax
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_top, cx
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_right, dx
	mov	ds:[di].PCI_docSizeInfo.PSR_margins.PCMP_bottom, bp
done:
	.leave
	ret
PrintControlGetPrinterMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlCalcDocDimmensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the printable page size and the margins for the
		specified printer, and sets the application's document
		margins and size

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS)
	
PASS:		DS:*SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
		DX:BP	= PageSizeReport buffer
		
RETURN:		DX:BP	= PageSizeReport filled, except that the margins
			  are already subtracted from the dimensions of
			  the page & the orientation is taken into account.

DESTROYED:	BX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LABEL_MARGINS		equ	72 / 8		; 1/8"

PrintControlCalcDocDimensions	method	dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS
	uses	ax, cx
	.enter

	; Grab the current paper size & margins
	;
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO
	call	ObjCallInstanceNoLock

	; See if the user wants a rotated document
	;
	mov	di, ds:[si]
	add	di, ds:[di].PrintControl_offset
	mov	es, dx				; PageSizeReport => ES:BP
	test	ds:[di].PCI_attrs, mask PCA_FORCE_ROTATION
	jz	doneRotationCheck
	xchgdw	es:[bp].PSR_width, es:[bp].PSR_height, ax
	mov	ax, es:[bp].PSR_margins.PCMP_left
	xchg	es:[bp].PSR_margins.PCMP_top, ax
	mov	es:[bp].PSR_margins.PCMP_left, ax
	mov	ax, es:[bp].PSR_margins.PCMP_right
	xchg	es:[bp].PSR_margins.PCMP_bottom, ax
	mov	es:[bp].PSR_margins.PCMP_right, ax
doneRotationCheck:
		
if	_LABELS
	; If the paper type is PT_LABEL, then the margins are assumed to
	; be 1/8" (as the margins are placed inside of each label, rather
	; than on the paper holding the labels). For NIKE, we need to make
	; the left & right margins 1/4", to account for labels that may
	; extend out to the edge of the paper, and hence be limited by
	; the printable area.
	;
	test	es:[bp].PSR_layout, PT_LABEL
	jz	doneLabels
	mov	ax, LABEL_MARGINS
	mov	es:[bp].PSR_margins.PCMP_left, ax
	mov	es:[bp].PSR_margins.PCMP_right, ax
	mov	es:[bp].PSR_margins.PCMP_top, ax
	mov	es:[bp].PSR_margins.PCMP_bottom, ax
doneLabels:
endif
	; Set the document size info
	;
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO
	call	ObjCallInstanceNoLock

	; Now return the desired values
	;
	clr	cx
	mov	ax, es:[bp].PSR_margins.PCMP_left
	add	ax, es:[bp].PSR_margins.PCMP_right
	subdw	es:[bp].PSR_width, cxax
	mov	ax, es:[bp].PSR_margins.PCMP_top
	add	ax, es:[bp].PSR_margins.PCMP_bottom
	subdw	es:[bp].PSR_height, cxax

	.leave
	ret
PrintControlCalcDocDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlCheckIfDocWillFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the document will fit on the page

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
		CX	= TRUE to generate warning message, FALSE otherwise

RETURN:		AX	= TRUE if the document will fit, FALSE otherwise

DESTROYED:	CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlCheckIfDocWillFit	method dynamic	PrintControlClass,
				MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT
	.enter

	; Get the current document size & page size
	;
EC <	jcxz	errorDone						>
EC <	cmp	cx, TRUE						>
EC <	ERROR_NE PC_MUST_PASS_TRUE_OR_FALSE				>
EC <errorDone:								>
	sub	sp, 2 * (size PageSizeReport)
	mov	dx, ss
	mov	bp, sp
	push	cx
	mov	ax, MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO
	call	ObjCallInstanceNoLock
	add	bp, size PageSizeReport
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO
	call	ObjCallInstanceNoLock
	pop	cx

	; Now perform the comparison work
	;
	push	ds, si
	mov	ds, dx
	mov	si, bp
	sub	si, size PageSizeReport
	mov	di, bp
	call	WillDocumentFit			; TRUE/FALSE/1 => AX
	cmp	ax, 1
	jne	continue
	mov	ax, TRUE
continue:
	pop	ds, si
	add	sp,  2 * (size PageSizeReport)
	jcxz	done				; if no message, we're done
	tst	ax
	jnz	done				; if we fit, display no message

	; Else display a message to the user
	;
	mov	ax, MSG_SPOOL_SUMMONS_REMOTE_ERROR
	mov	cx, PCERR_DOC_WONT_FIT
	mov	bp, MSG_META_DUMMY		; no method back
	call	PCCallSummons			; call the SpoolSummons object
	clr	ax				; return FALSE
done:
	.leave
	ret
PrintControlCheckIfDocWillFit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetFirstPageOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the height of the current cover page.

CALLED BY:	MSG_PRINT_GET_FIRST_PAGE_OFFSET
PASS:		*ds:si	= PrintControlClass object
		ds:di	= PrintControlClass instance data
		ds:bx	= PrintControlClass object (same as *ds:si)
		es 	= segment of PrintControlClass
		ax	= message #
RETURN:		dx	= height of the last 
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintGetFirstPageOffset		method dynamic PrintControlClass, 
					MSG_PRINT_GET_FIRST_PAGE_OFFSET
		uses	ax, cx, bp
		.enter
	
		mov	ax, MSG_MSAC_GET_EXTRA_TOP_SPACE
		call	PCCallAddressControl
		jc	exit			;carry set if success.
		clr	dx		
exit:
		.leave
		
		ret
		
PrintGetFirstPageOffset 	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Section #3: Handlers & routines for printing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlInitiatePrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate a "new" dialog box

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_INITIATE_PRINT)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Don	2/90		Updated to move to spooler
	Don	11/93		Changed to use more general message

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlInitiatePrint	method PrintControlClass,
				MSG_PRINT_CONTROL_INITIATE_PRINT

		; Display all printer drivers
		;
		mov	cl, PDT_PRINTER
		FALL_THRU	PrintControlInitiateOutputUI
PrintControlInitiatePrint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlInitiateOutputUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the display of one of the "output" dialog boxes
		(currently either Printing or Faxing)

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI)

PASS:		*DS:SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance
		CL	= PrinterDriverType

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 1/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlInitiateOutputUI	method	PrintControlClass,
				MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI

		; First, see if we are already printing by checking
		; if there is a JobParameters handle in our temporary
		; instance data.
		;
		call	PCAccessTemp
		tst	ds:[di].TPCI_jobParHandle
		jz	continue
error:
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
done:
		ret

		; Are we enabled (i.e. is it even possible for the user
		; to interact with the print dialog?)
continue:
		push	cx
		mov	ax, MSG_GEN_GET_ENABLED
		call	ObjCallInstanceNoLock
		pop	cx
		jnc	error

		; Build the dialog box, if this is the first time it
		; has been displayd
		;
		call	PCIsAddrControl
		jc	done

		mov	bx, ds:[di].TPCI_currentSummons.handle
		tst	bx			
		jnz	displayBox		; if non-zero, box exists
		push	cx
		call	PCBuildSummons		; else build the dialog...
		call	InitializeDialogBox	; and initialize the sucker
		pop	cx

		; Set the type of print dialog to be displayed, and
		; bring it up
displayBox:
		mov	si, ds:[di].TPCI_currentSummons.chunk
		mov	ax, MSG_SPOOL_SUMMONS_SET_DRIVER_TYPE
		call	PCObjMessageSend
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	PCObjMessageSend
		mov	ax, MSG_GEN_BRING_TO_TOP
		call	PCObjMessageSend

		ret
PrintControlInitiateOutputUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeDialogBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the spool print control

CALLED BY:	PrintControlInitiatePrint

PASS:		BX:SI	= SpoolSummonsClass object
		DS:*DI	= PrintControl instance data
		CL	= PrinterDriverType

RETURN:		DS:DI	= TempPrintCtrlInstance

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitializeDialogBox	proc	far
	class	PrintControlClass
	uses	si
	.enter

	; Access the important data
	;
	push	di				; PrintControl chunk handle
	mov	di, ds:[di]			; dereference the handle
	add	di, ds:[di].PrintControl_offset
	push	ds:[di].PCI_startUserPage
	push	ds:[di].PCI_endUserPage		; save start & end user pages
	push	ds:[di].PCI_startPage
	push	ds:[di].PCI_endPage		; save start & end page range
	push	ds:[di].PCI_defPrinter		; save the default printer #
	mov	cx, ds:[di].PCI_attrs		; attributes => CX

	; Now send this information to the SpoolDialogBox
	;
	mov	ax, MSG_SPOOL_SUMMONS_SET_PRINT_ATTRS
	call	PCObjMessageSend		; send over the attributes

	pop	cx				; restore the default printer
	mov	ax, MSG_SPOOL_SUMMONS_SET_DEFAULT_PRINTER
	call	PCObjMessageSend

	pop	cx, dx				; start & end page => CX, DX
	mov	ax, MSG_SPOOL_SUMMONS_SET_PAGE_RANGE
	call	PCObjMessageSend

	pop	cx, dx				; start & end user pages
	mov	ax, MSG_SPOOL_SUMMONS_SET_USER_PAGE_RANGE
	call	PCObjMessageSend

	mov	ax, MSG_SPOOL_SUMMONS_INITIALIZE_UI_LEVEL
	call	PCObjMessageSend		; initialize the UI level

	; Clean up
	;
	pop	si
	call	PCAccessTemp			; TempPrintCtrlInstance => DS:DI

	.leave
	ret
InitializeDialogBox	endp

PCObjMessageSend	proc	near
	mov	di, mask MF_FIXUP_DS
	GOTO	PCObjMessage
PCObjMessageSend	endp

PCObjMessageCall	proc	near
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	FALL_THRU PCObjMessage
PCObjMessageCall	endp

PCObjMessage	proc	near
	call	ObjMessage
	ret
PCObjMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually print a document

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_PRINT)

PASS:		DS:*SI	= PrintControl instance data
		ES	= Segment of the PrintControlClass

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, SI, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Don	3/90		Incorporates the print spooler

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlPrint	method dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_PRINT

	; Are we already printing ?  If so, exit
	;
	call	PCAccessTemp			; access the local data
	tst	ds:[di].TPCI_jobParHandle	; are we already spooling ??
	jnz	done				; ...if so, exit now

	; Allocate memory for a JobParameters structure
	;
	mov	ax, size JobParameters		; bytes to allocate
	mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
		    ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8))
	call	MemAlloc			; allocate the block
	mov	es, ax
	clr	bp				; ES:BP is the JobParamters
	mov	ds:[di].TPCI_jobParHandle, bx	; store the JobPar block handle
	and	ds:[di].TPCI_status, not (mask PSF_ABORT or \
					  mask PSF_RECEIVED_COMPLETED or \
					  mask PSF_RECEIVED_NAME or \
					  mask PSF_VERIFIED)
SBCS <	mov	{byte} es:[bp].JP_fname, 0	; Create NULL name for spoolfile>
DBCS <	mov	{wchar} es:[bp].JP_fname, 0	; Create NULL name for spoolfile>
	mov	es:[bp].JP_size, (size JobParameters)

	; Now handle all the verification chores
	;
	call	PrintRequestUIOptions
	jc	abortPrint
	call	MemUnlock			; unlock the JobParameters
	call	PrintRequestAppVerify
	jc	done
	mov	cx, TRUE			; keep on printing!
	mov	di, ds:[si]			; dereference chunk handle
	add	di, ds:[di].PrintControl_offset
	GOTO	PrintControlVerifyCompleted

	; We have some sort of problem. Abort, abort
	;
abortPrint	label	near
	call	MemFree				; free the job parameters
	mov	ax, MSG_MSAC_PRINTING_CANCELED
	call	PCCallAddressControl
	call	PCAccessTemp
	call	PrintMarkAppNotBusy		; mark app not busy (if needed)
	clr	ds:[di].TPCI_jobParHandle	; not in middle of job now
done:
	call	CheckUpOnPrintCompletionMessage	; See if we should send out
	ret					; completion message
PrintControlPrint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlVerifyCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received when the application decides to allow the printing
		to occur, or to reject it altogether.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_VERIFY_COMPLETED)

PASS:		DS:*SI	= PrintControlClass object 
		DS:DI	= PrintControlClassInstance
		CX	= TRUE  - continue print job
			= FALSE - abandon print job

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlVerifyCompleted	method	PrintControlClass,
				 MSG_PRINT_CONTROL_VERIFY_COMPLETED

	; See if we continue to print or not. If so, bring down the
	; print dialog box.
	;
	mov	dx, ds:[di].PCI_attrs		; get PrintControlAttrs
	call	PCAccessTemp			; local data => DS:DI
	mov	bx, ds:[di].TPCI_jobParHandle	; JobParameters handle => BX
	cmp	cx, FALSE			; abort printing ??
	je	abortPrint			; yes, so jump

	; We need to bring down the print dialog box, and possibly mark
	; the application as busy.
	;
	push	bx, si
	call	PrintMarkAppBusy		; mark application busy
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, ds:[di].TPCI_currentSummons.handle
	mov	si, ds:[di].TPCI_currentSummons.chunk
	call	PCObjMessageCall
	pop	bx, si

	; Now fill in most of the structure (BX, BP, SI preserved by all)
	;
	call	MemLock				; else re-lock JobParameters
	mov	es, ax
	clr	bp				; ES:BP is the JobParamters
	call	PrintRequestDocName
	call	PrintGetApplicationName
	call	PrintGetPrinterInfo
	jc	abortPrint			; if get info error, abort
	call	PrintCreateSpoolFile		; returns AX & DI
	jc	abortPrint			; if file creation error, abort

	; Create graphics string
	;
	call	PrintCreateProgressDB		; create progress box, if needed
	call	MemUnlock			; unlock the JobParameters
	mov	bp, di				; gstring => BP
	call	PCAccessTemp			; access the local data
	mov	ds:[di].TPCI_fileHandle, ax	; save the spool file handle
	mov	ds:[di].TPCI_gstringHandle, bp	; save the gstring handle

	; Send the print method to the OD
	;
	mov	ax, MSG_PRINT_START_PRINTING
	mov	bx, offset PCI_output
	call	PCSendToOutputOD
	ret
PrintControlVerifyCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlReportProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display information about the status of a print job as the
		application spools the data.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_REPORT_PROGRESS)
	
PASS:		DS:*SI	= PrintControl object
		DS:DI	= PrintControlInstance
		CX	= PCProgressType
				PCPT_PAGE
					DX 	= Page number
				PCPT_PERCENT
					DX	= Percentage compeleted
				PCPT_TEXT
					DX:BP	= Text message to display 

RETURN:		AX	= TRUE (continue printing)
			= FALSE (abort printing)

DESTROYED:	BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

progressUpdate	nptr.near	ProgressUpdatePage,
				ProgressUpdatePercent,
				ProgressUpdateText

PrintControlReportProgress	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_REPORT_PROGRESS
	.enter

	; Let's parse of what we need to do
	;
EC <	cmp	cx, PCProgressType		; check for valid type	>
EC <	ERROR_AE PC_ILLEGAL_PC_PROGRESS_TYPE				>
EC <	test	cx, 0x1				; must be even		>
EC <	ERROR_NZ PC_ILLEGAL_PC_PROGRESS_TYPE				>

	call	PCAccessTemp			;TempPrintCtrlInstance => DS:DI
	mov	ax, FALSE			; assume we've aborted
	test	ds:[di].TPCI_status, mask PSF_ABORT
	jnz	done				; if assumption correct, jump
	mov	bx, cx
	mov	ax, cs:[progressUpdate][bx]	; function address => AX
	mov	bx, ds:[di].TPCI_progressBox.handle
	tst	bx				; is a progress box even up??
	jz	keepPrinting			; nope, so just keep printing
	call	ax				; call the update function
keepPrinting:	
	mov	ax, TRUE			; and continue printing
done:
	.leave
	ret
PrintControlReportProgress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlSetDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the name of the document into the JobParameters field,
		for later use by the spooler.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_SET_DOC_NAME)
	
PASS:		DS:*SI	= PrintControlClass instance data
		CX:DX	= Buffer containing the document name

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlSetDocName	method	dynamic	PrintControlClass,
					MSG_PRINT_CONTROL_SET_DOC_NAME
	uses	cx, dx, bp
	.enter

	; Access the JobParameters structure
	;
	call	PCAccessTemp			; access my local variables
	mov	bx, ds:[di].TPCI_jobParHandle	; job handle => BX
	tst	bx				; valid handle ??
	jz	done				; no, so do nothing
	push	ds, si, di			; save pointer to LPCD
	push	ds:[di].TPCI_progressBox.handle	; save object block handle
	call	MemLock				; lock the structure
	mov	es, ax
	mov	di, offset JP_documentName	; buffer => ES:DI
	
	; Now copy the string
	;
	mov	ds, cx
	mov	si, dx				; string => DS:SI
	mov	cx, FILE_LONGNAME_LENGTH+1	; maximum string size
SBCS <	rep	movsb				; copy the bytes	>
DBCS <	rep	movsw				; copy the bytes	>
	call	MemUnlock			; unlock the JobParameters

	; Also copy the string into the progess box, if necessary
	;
	pop	cx				; progress object block handle
	jcxz	doneProgress
	mov	si, offset ProgressUI:ProgressDocument
	push	ds, dx				; save the document name
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
assume	ds:Strings
	mov	dx, ds:[progressAppDivider]	; string => DS:DX
	call	PCAppendText			; append the text
	call	MemUnlock
assume	ds:dgroup
	pop	ds, dx				; document name => DS:DX
	call	PCAppendText

doneProgress:
	pop	ds, si, di			; TempPrintCtrlInstance =>DS:DI
	or	ds:[di].TPCI_status, mask PSF_RECEIVED_NAME
	call	StartPrintJob			; start printing ?
done:
	.leave
	ret
PrintControlSetDocName	endp

PCAppendText	proc	near
	uses	bx, cx
	.enter

	mov	bx, cx				; GenText object => BX:SI
	mov	bp, dx
	mov	dx, ds				; string => DX:BP
	clr	cx				; string is NULL terminated
	mov	ax, MSG_VIS_TEXT_APPEND		; append the text to the end
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
PCAppendText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlPrintingCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notification that printing is completed

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_PRINTING_COMPLETED)

PASS:		ES	= Segment of PrintControlClass
		DS:*SI	= PrintControlClass instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Don	3/90		Modified to use true spooler

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlPrintingCompleted	method PrintControlClass,
				MSG_PRINT_CONTROL_PRINTING_COMPLETED
	.enter

	; Clean up the progress dialog box & the busy cursor
	;
	push	si				; save PC object chunk
	call	PCAccessTemp			; TempPrintCtrlInstance => DS:DI
						; Hold up completion event
						;   for IACP until the very
						;   end.
	inc	ds:[di].TPCI_holdUpCompletionCount
	call	PrintDestroyProgressDB		; destroy progress dialog box
	call	PrintMarkAppNotBusy		; mark app not busy

	; Destroy the gstring
	;
	push	di				; save temp instance data
	clr	si
	xchg	si, ds:[di].TPCI_gstringHandle	; gstring handle => SI
	mov	di, si				
	call	GrEndGString			; end the gstring
	mov	dl, GSKT_LEAVE_DATA		; leave data alone
	clr	di				; no associated GState
	call	GrDestroyGString		; and destroy the handle
	pop	si				; restore temp instance data
	cmp	ax, GSET_DISK_FULL		; check to see if disk filled
	je	diskFullError			; handle error.

	; Close the file
	;
	clr	bx
	xchg	bx, ds:[si].TPCI_fileHandle	; file handle => BX
	mov	al, FILE_NO_ERRORS		; close that file now
	call	FileClose

	; Get the remaining pieces of information
	;
	mov	ax, mask PSF_VERIFIED		; assume verification OK
	mov	bx, ds:[si].TPCI_jobParHandle	; job handle => BX
	test	ds:[si].TPCI_status, mask PSF_ABORT
	pop	si				; PrintControl => DS:*SI
	jnz	release				; if aborted, release job
	call	MemLock				; lock the block
	mov	es, ax
	clr	bp				; ES:BP => JobParameters
	push	bx				; save the block handle
	call	PrintGetDocumentInfo		; PrintStatusFlags => AL
	pop	bx				; job handle => BX
	call	MemUnlock			; unlock the JobParameters

	; Now go to release the print job
release:
	call	PCAccessTemp			; locals => DS:DI
	or	al, mask PSF_RECEIVED_COMPLETED
	or	ds:[di].TPCI_status, al
	call	StartPrintJob			; start the job now ?
done:
	call	PCAccessTemp			; locals => DS:DI
	dec	ds:[di].TPCI_holdUpCompletionCount
	call	CheckUpOnPrintCompletionMessage	; See if we should send out

	.leave
	ret

	; disk filled up when gstring was being created.  Abort the print job,
	; which means deleting the spool file, and biffing the spool job block.
	; Also, put up a box for the user to tell him/her what is going on...
	;
diskFullError:
	pop	si				; PC object => *DS:SI
	push	ds, si				; save object
	call	PrintControlPrintingCancelled
	pop	ds, si				; restore object

	; Display error message for the user
	;
	mov	bp, MSG_META_DUMMY		; method to return (none)
	mov	cx, PCERR_DISK_FULL		; error type
	mov	ax, MSG_SPOOL_SUMMONS_REMOTE_ERROR
	call	PCCallSummons			; call over to the summons
	jmp	done
PrintControlPrintingCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlPrintingCancelled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel a print job request in progress

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_PRINTING_CANCELLED)
	
PASS:		DS:*SI	= PrintControl instance data

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlPrintingCancelled	method	PrintControlClass,
				MSG_PRINT_CONTROL_PRINTING_CANCELLED

	; Destroy the gstring
	;
	push	ds:[LMBH_handle], si
	call	PCAccessTemp			; access the local variables
	call	PrintDestroyProgressDB		; destroy progress dialog box
	call	PrintMarkAppNotBusy		; mark app not busy
	clr	si
	xchg	si, ds:[di].TPCI_gstringHandle	; gstring handle => SI
	tst	si
	jz	closeFile
	push	di				; save temp instance data
	clr	di				; no associated GState
	mov	dl, GSKT_LEAVE_DATA		; leave data alone
	call	GrDestroyGString		; and destroy the handle
	pop	di				; restore temp instance data

	; Close the file
closeFile:
	clr	bx
	xchg	bx, ds:[di].TPCI_fileHandle	; file handle => BX
	tst	bx
	jz	deleteFile
	clr	al
	call	FileClose			; close the file

	; Delete the spool file
deleteFile:
	clr	bx
	xchg	bx, ds:[di].TPCI_jobParHandle	; job handle => BX
	tst	bx				; job still here ??
	jz	done				; nope, so leave
	call	MemLock				; lock the JobParameters
	mov	ds, ax
	mov	dx, offset JP_fname		; DS:DX => filename
	call	FilePushDir			; save the current directory
	mov	ax, SP_SPOOL			; change to the spool directory
	call	FileSetStandardPath		; as one of the standard paths
	call	FileDelete			; delete this spool file
	call	FilePopDir			; return to original directory
	call	MemFree				; free the JobParameters block

	; Clean up
done:
	pop	bx, si
	call	MemDerefDS			; PrintControl object => *DS:SI

	; Tell any associated MailboxSpoolAddressControl
	
	push	bp				; necessary?
	mov	ax, MSG_MSAC_PRINTING_CANCELED
	call	PCCallAddressControl
	pop	bp

	call	CheckUpOnPrintCompletionMessage	; See if we should send out
	ret					; completion message
PrintControlPrintingCancelled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlVerifyPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The document size/margin verification has occurred, and the
		user has decided to go ahead

CALLED BY:	UI (MSG_PRINT_CONTROL_VERIFY_*)
	
PASS:		DS:DI	= PrintControl specific instance data
		CX:DX	= OD of GenTrigger in verify dialog box
		AX	= Method passed

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlVerifyPrint	method	PrintControlClass,
				MSG_PRINT_CONTROL_VERIFY_PRINT,
				MSG_PRINT_CONTROL_VERIFY_SCALE,
				MSG_PRINT_CONTROL_VERIFY_CANCEL

	; Free the verify dialog box, as we're done with it
	;
	push	ax, si
	mov	bx, cx
	mov	si, offset SizeVerifyDialogBox	; OD of verify box => BX:SI
	call	PCSetNotUsable			; first set it not usable...
	mov	ax, MSG_META_BLOCK_FREE
	call	PCObjMessageSend		; ...then free the block

	; Set the proper bit (ignore scaling for now)
	;
	pop	ax, si
	call	PCAccessTemp
	or	ds:[di].TPCI_status, mask PSF_VERIFIED
	cmp	ax, MSG_PRINT_CONTROL_VERIFY_CANCEL
	jne	doPrinting
	or	ds:[di].TPCI_status, mask PSF_ABORT

	; Else try to print the job now (set/clear scaling flag)
doPrinting:
	mov	bx, ds:[di].TPCI_jobParHandle
	tst	bx
	jz	done
	cmp	ax, MSG_PRINT_CONTROL_VERIFY_PRINT
	je	startJob
	call	MemLock
	mov	es, ax
	or	es:[JP_spoolOpts], mask SO_SCALE	
	call	MemUnlock
startJob:
	call	StartPrintJob			; now print (maybe)
done:	
	.leave
	ret
PrintControlVerifyPrint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeVerifyDialogUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clean up if the verify dialog is up on detach

CALLED BY:	MSG_META_UPDATE_WINDOW
PASS:		*ds:si	= SizeVerifyDialogClass object
		ds:di	= SizeVerifyDialogClass instance data
		ds:bx	= SizeVerifyDialogClass object (same as *ds:si)
		es 	= segment of SizeVerifyDialogClass
		ax	= message #
		cx	= UpdateWindowFlags
		dl	= VisUpdateMode
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SizeVerifyDialogUpdateWindow	method dynamic SizeVerifyDialogClass, 
					MSG_META_UPDATE_WINDOW
	test	cx, mask UWF_DETACHING
	jz	callSuper
	push	ax, cx, dx
	mov	ax, MSG_PRINT_CONTROL_VERIFY_CANCEL
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset AlertCancelPrintingTrigger
	call	GenCallParent
	pop	ax, cx, dx
callSuper:
	mov	di, offset SizeVerifyDialogClass
	GOTO	ObjCallSuperNoLock
SizeVerifyDialogUpdateWindow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartPrintJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the print job off to the spooler

CALLED BY:	PrintControlPrintingCompleted
		PrintControlSetDocName
	
PASS:		*DS:SI	= PrintControl object
		DS:DI	= TempPrintCtrlInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartPrintJob	proc	near
	class	PrintControlClass
	uses	bp
	.enter

	; Are we truly ready to print ?
	;
	mov	al, ds:[di].TPCI_status
	and	al, READY_TO_RELEASE_JOB	; check only those bits
	xor	al, READY_TO_RELEASE_JOB	; ensure all are set
	jnz	exit				; if all not set, fail

	; Send the job to the spooler
	;
	clr	bx
	xchg	bx, ds:[di].TPCI_jobParHandle	; job handle => BX

	test	ds:[di].TPCI_status, mask PSF_ABORT
	jnz	free

	; Call associated MailboxSpoolAddressControl, if there is one.
	; 
	mov	cx, bx
	push	bp
	mov	ax, MSG_MSAC_PRINTING_COMPLETE
	call	PCCallAddressControl
	pop	bp
	jc	done				; => is one, so all done here


	push	si				; save PC chunk handle
	call	MemLock				; lock the block
	mov_tr	dx, ax
	clr	si				; JobParameters => DX:SI
	call	SpoolAddJob			; returns CX => Job handle
	pop	si				; PrintControl => *DS:SI
	push	bx				; save JobParameters handle
	mov	ax, MSG_PRINT_NOTIFY_PRINT_JOB_CREATED
	mov	bx, offset PCI_output
	mov	bp, cx				; JobID => BP
	call	PCSendToOutputOD		; send the message
	call	PCAccessTemp			; access the local variables
	pop	bx				; restore JobParameters handle
free:
	call	MemFree				; free the job block

	; Now see if we need to deal with an aborted print job
	;
	test	ds:[di].TPCI_status, mask PSF_ABORT
	jz	done				; no linked jobs, so we're done
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	mov	bx, ds:[LMBH_handle]		; PC OD => BX:SI
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	call	CheckUpOnPrintCompletionMessage	; See if we should send out
exit:						; completion message
	.leave
	ret
StartPrintJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintControlAbortPrintJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to abort the current print job. All the data structures
		will be freed when either MSG_PC_PRINTING_COMPLETED or
		MSG_PC_PRINTING_CANCELLED is called.

CALLED BY:	GLOBAL (MSG_PRINT_CONTROL_ABORT_PRINT_JOB)

PASS:		DS:*SI	= PrintControlClass object
		DS:DI	= PrintControlClassInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlAbortPrintJob	method dynamic PrintControlClass,
				MSG_PRINT_CONTROL_ABORT_PRINT_JOB
	.enter

	; Set the "abort" flag
	;
	call	PCAccessTemp			; TempPrintCtrlInstance => DS:DI
	or	ds:[di].TPCI_status, mask PSF_ABORT

	.leave
	ret
PrintControlAbortPrintJob	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetDocumentInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain all the document information

CALLED BY:	PrintControlPrint

PASS:		ES:BP	= JobParamters structure
		DS:*SI	= PrintControl instance data

RETURN:		AX	= PrintStatusFlags
				mask PSF_VERIFIED (or 0)
		ES:BP 	= JobParameters structure
				JP_numPages
				JP_printMode
				JP_paperSize
				JP_paperPath
				JP_docWidth
				JP_docHeight
				JP_spoolType
				JP_customWidth (if necessary)
				JP_customHeight (if necessary)

DESTROYED:	AH, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetDocumentInfo	proc	near
	class	PrintControlClass
	uses	bp, si, es
	.enter

	; Get the document size information
	;
	mov	ax, MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO
	mov	bx, bp				; JobParameters => ES:BX
	mov	dx, es
	add	bp, offset JP_docSizeInfo	; PageSizeReport => DX:BP
	call	ObjCallInstanceNoLock

	; Grab the values from the SpoolSummons
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE
	mov	di, ds:[si]
	add	di, ds:[di].PrintControl_offset
	test	ds:[di].PCI_attrs, mask PCA_PAGE_CONTROLS
	jnz	callSummons
	mov	ax, MSG_SPOOL_SUMMONS_GET_PAGE_RANGE
callSummons:
	call	PCCallSummons
EC <	ERROR_NC	PRINT_GET_DOCUMENT_INFO_NO_SPOOL_SUMMONS	>
	sub	dx, cx				; last page - first page
	inc	dx				; account for same page
	mov	es:[bx].JP_numPages, dx		; store the value

	; Get all the print mode stuff
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINT_INFO
	call	PCCallSummons
EC <	ERROR_NC	PRINT_GET_DOCUMENT_INFO_NO_SPOOL_SUMMONS	>
	mov	es:[bx].JP_printMode, cl
	mov	es:[bx].JP_spoolOpts, ch
	mov	es:[bx].JP_retries, dl
	mov	es:[bx].JP_numCopies, dh
	mov	es:[bx].JP_timeout, bp

	; Get the paper size information
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_PAPER_SIZE_INFO
	mov	dx, es
	mov	bp, bx
	add	bp, offset JP_paperSizeInfo	; PageSizeReport buffer => DX:BP
	call	PCCallSummons
EC <	ERROR_NC	PRINT_GET_DOCUMENT_INFO_NO_SPOOL_SUMMONS	>
	mov	bp, bx				; ES:BP => JobParameters

if _HACK_20_FAX

	mov	ax, MSG_SPOOL_SUMMONS_GET_DRIVER_TYPE
	call	PCCallSummons			; PrinterDriverType => CL
	;
	; Here is a hack for faxing under on 20X. Release20X fax printer
	; driver returns margins of 0, so in
	; SpoolSummonsGetPrinterMargins we set the left and right
	; margins to 1/4 inch if they are 0.  However, here we need to
	; have the margins at 0.
	;
	; On the same line of hacks, we're going to set the top margin
	; to be 1/4 inch.
	; 5/6/95 - ptrinh
	;
	cmp	cl, PDT_FACSIMILE		; es:bx => JobParameters
	jne	notFax
	clr	es:[bx].JP_paperSizeInfo.PSR_margins.PCMP_left
	clr	es:[bx].JP_paperSizeInfo.PSR_margins.PCMP_right
	mov	es:[bx].JP_paperSizeInfo.PSR_margins.PCMP_top, 72/4
notFax:
endif
	; Verify the margin and document sizes
	;
	mov	ax, MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT
	mov	cx, FALSE
	call	ObjCallInstanceNoLock
	tst	ax				; check returned value
	mov	ax, mask PSF_VERIFIED
	LONG	jnz	done			; document fits, so we're done

	; Otherwise we don't fit. What sort of output are we creating?
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_DRIVER_TYPE
	call	PCCallSummons			; PrinterDriverType => CL
	mov	al, cl

	; Display the error box, and let the user decide what to do
	;
	mov	cx, handle SizeVerifyDialogBox	; resource handle => CX
	mov	dx, offset SizeVerifyDialogBox	; chunk handle => DX
	mov	bp, -1				; OD not stored anywhere
	call	PCDuplicateBlock		; new resource handle => BX

	; Display the proper text string
	;
	mov	dx, handle SpoolDocWontFitFax
	mov	bp, offset SpoolDocWontFitFax	; text => ^lDX:BP
	cmp	al, PDT_FACSIMILE
	je	setText
	mov	dx, handle SpoolDocWontFitPrint
	mov	bp, offset SpoolDocWontFitPrint	; text => ^lDX:BP
setText:
	push	ax
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	si, offset AlertMessage		; TextObject OD => BX:SI
	clr	cx				; text is NULL terminated
	call	PCObjMessageCall
	pop	ax

	; Remove one of the Cancel trigger
	;
	mov	si, offset AlertCancelPrintingTrigger
	cmp	al, PDT_FACSIMILE
	je	removeTrigger
	mov	si, offset AlertCancelFaxingTrigger
removeTrigger:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	PCObjMessageCall

	; If necessary, change a string to allow the dialog to fit on
	; the screen.
	;
	segmov	es, dgroup, ax
	test	es:[uiOptions], mask SUIO_SIMPLE
	jz	displayToUser			; not simple, so do nothing
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset ShortActualSizeMoniker
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset AlertPrintTrigger
	call	PCObjMessageSend

	; Now display it to the user
displayToUser:
	mov	ax, SST_ERROR
	call	UserStandardSound
	mov	si, offset SizeVerifyDialogBox	; Dialog box OD => BX:SI
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	PCObjMessageCall

	;
	; if detaching, fit dialog didn't come up, pretend we've cancelled
	;
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication		; ax = ApplicationStates
	test	ax, mask AS_DETACHING
	mov	ax, 0				; don't set verify flag
	jz	done
	call	PCSetNotUsable			; set verify box not usable
	mov	ax, MSG_META_BLOCK_FREE
	call	PCObjMessageSend		; free the block
	mov	ax, mask PSF_VERIFIED or mask PSF_ABORT
done:
	.leave
	ret
PrintGetDocumentInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetApplicationName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills the structure eith the application's permanent name

CALLED BY:	PrintControlPrint

PASS: 		ES:BP	= JobParamters structure
		DS:*SI	= PrintControl instance data

RETURN:		ES:BP	= JobParamters
				JP_parent filled in

DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetApplicationName	proc	near
	class	PrintControlClass
	uses	bx, bp, si
	.enter
	
	; Just call to copy the string. Use the JP_parent field as a
	; temporary buffer
	;
.assert	(size GeodeToken) le (size JP_parent)
	add	bp, offset JP_parent
	mov	di, bp				; JP_parent field => ES:DI
	mov	bx, ds:[LMBH_handle]		; handle of block => BX
	call	MemOwner			; process owning block => BX
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo
	mov	ax, {word} es:[di+0].GT_chars
	mov	bx, {word} es:[di+2].GT_chars
	mov	si, {word} es:[di].GT_manufID

	; Now get the proper moniker
	;
	push	bp				; save offset to JP_parent
	mov	dh, DC_TEXT			; DisplayType
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
	mov	cx, ds:[LMBH_handle]		; block in which to load moniker
	clr	di				; allocate a chunk
	push	cx				; handle
	push	bp				; pass VisMonikerSearchFlags
	push	di				; pass unused buffer size
	call	TokenLoadMoniker		; load a moniker; chunk => DI
	pop	bx				; handle
	call	MemDerefDS
	pop	bp				; restore offset to JP_parent
SBCS <	mov	{byte} es:[bp], 0		; assume none (preserve CF)>
DBCS <	mov	{wchar} es:[bp], 0		; assume none (preserve CF)>
	jc	done				; if no moniker, fail

	; Now copy the text into our structure
	;
	mov	ax, di				; LMem handle => AX
	mov	si, ds:[di]			; dereference the handle
	mov	di, bp				; destination => ES:DI
	test	ds:[si].VM_type, mask VMT_GSTRING
	jnz	fail				; a GString?  No text moniker
	add	si, offset VM_data + offset VMT_text
	mov	cx, FILE_LONGNAME_LENGTH + 1	; maximum string length
	LocalCopyNString			; copy the chars
fail:
	call	LMemFree			; free the chunk
done:
	.leave
	ret
PrintGetApplicationName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetPrinterInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain all the printer-related information

CALLED BY:	PrintControlPrint

PASS:		ES:BP	= JobParamters structure
		DS:*SI	= PrintControl instance data

RETURN:		ES:BP 	= JobParameters structure filled in
				JP_printerName
				JP_deviceName
				JP_portInfo

		carry set if error

DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

deviceString	byte	'device', 0
portString	byte	'port', 0

PrintGetPrinterInfo	proc	near
	class	PrintControlClass
	uses	bx, bp
	.enter

	; Let's grab some strings
	;
	push	ds, si
	push	si
	call	PCGetSummons
	pop	si
	push	bx
	call	PCOpenPrintStrings		; sets up DS, DI, CX, DX
	call	SSGetPrinterCategory		; returns the string in DS:SI
	mov	di, bp				; JobParamters => ES:DI 
	; Get the driver name first
	;
	push	di				; save start of JobParameters
	push	si				; save start of category
	add	di, offset JP_printerName	; ES:DI = buffer to fill
	inc	cx				; copy one additional character
	LocalCopyNString			; copy the chars
	pop	si				; restore start of category
	pop	di				; rest. start of JobParameters
	ConvPrinterNameToIniCat

	; Now get the device name
	;
	push	di				; save start of JobParameters
	mov	cx, cs
	mov	dx, offset PrintControlCode:deviceString
	add	di, offset JP_deviceName	; ES:DI = buffer to fill
	mov	bp, (MAX_DEVICE_NAME_SIZE*(size wchar)) or INITFILE_INTACT_CHARS
	call	InitFileReadString		; copy the string
	pop	di				; restore JobParameters
	jc	abort

	; Last, but not least, get the port the printer is connected to
	;
	mov	cx, cs
	mov	dx, offset PrintControlCode:portString
SBCS <	mov	bp, INITFILE_UPCASE_CHARS	; allocate a buffer	>
DBCS <	clr	bp				; allocate a buffer	>
	call	InitFileReadString		; put the string in a buffer
	; Grab the actual information, and clean up
	;
abort:
	pop	dx				; PrintUI resource handle
	jc	exit
	call	PrinterGetPortInfo		; get all the port info
	clc					; no error
exit:
	ConvPrinterNameDone
	pop	ds, si				; restore these registers
	call	PCClosePrintStrings		; unlock the buffer

	.leave
	ret

PrintGetPrinterInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetPortInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the port information

CALLED BY:	PrintGetPrinterInfo

PASS:		ES:DI	= JobParamters structure
		DS:SI	= Printer category string
		BX	= Block handle of port name
		DX	= PrintUI resource handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortInfo	struct
SBCS <	PI_name		char 2 dup(?)					>
DBCS <	PI_name		wchar 2 dup(?)					>
	PI_portType	PrinterPortType
PortInfo	ends

; First 2 characters are enough to distinguish the port type.  Fourth
; character is used (for serial and parallel), to get port #

portTable	PortInfo	\
	<"LP", PPT_PARALLEL>,
	<"CO", PPT_SERIAL>,
	<"CU", PPT_CUSTOM>,
	<"UN", PPT_NOTHING>


baudRateString		char	'baudRate', 0
handShakeString		char	'handshake', 0
parityString		char	'parity', 0
wordLenString		char	'wordLength', 0
stopBitsString		char	'stopBits', 0
stopRemoteString	char	'stopRemote', 0
stopLocalString		char	'stopLocal', 0

PrinterGetPortInfo	proc	near

	.enter

	; Determine if we are printing to a file
	;
	push	ds, si
	xchg	bx, dx				; PrintUI resource handle => BX
	mov	si, offset PrintUI:PrintDialogBox
	mov	ax, MSG_SPOOL_SUMMONS_PRINTING_TO_FILE
	mov	di, mask MF_CALL		; method preserves DX, BP
	call	ObjMessage			; AX = 0 (no) or 1 (yes)

	; Setup some string stuff
	;
	xchg	bx, dx				; handle of port name => BX
	mov_tr	cx, ax				; to file or no" value => CX
	call	MemLock				; lock handle in BX
	mov	ds, ax
	clr	si				; port name now in DS:SI

	; Get the printer port type and number
	;
	push	cx
DBCS <	push	bx							>
	mov	bp, offset portTable
	mov	cx, length portTable
	mov	ax, ds:[si]			; fetch first 2 characters of
						; port name
DBCS <	mov	bx, ds:[si][2]						>
startLoop:
	cmp	ax, {word}cs:[bp].PI_name
if	DBCS_PCGEOS
	jne	notFound
	cmp	bx, {word}cs:[bp].PI_name+2
endif
	je	found
if	DBCS_PCGEOS
notFound:
endif
	add	bp, size PortInfo
	loop	startLoop
EC <	pop	cx				; if not printing to	>
EC <	tst	cx				; ..a file, we're hosed	>
EC <	ERROR_Z	PRINTER_PORT_TYPE_NOT_KNOWN				>
EC <	push	cx							>
found:
DBCS <	pop	bx							>
	mov	bp, cs:[bp].PI_portType		; PrinterPortType

	; attempt to convert the port string to a port number, assuming the
	; port is parallel or serial, which look like LPTn and COMn,
	; respectively.

SBCS <	clr	ah							>
SBCS <	mov	al, ds:[si+3]			; port number character => AL>
DBCS <	mov	ax, ds:[si+6]			; port number character => AX>
	sub	ax, '1'				; account for the ASCII offset
						; '1' => 0, '2' => 1, etc...
	shl	ax, 1				; make it a ParallelPortNum
	pop	cx				; print to file flag
	call	MemFree				; free the string block
	pop	ds, si				; restore the printer category
	tst	cx				; printing to file
	jnz	filePort			; yes, so do it!
	mov	es:[di].JP_portInfo.PPI_type, bp

	; Set up extra parameters based on port type.
	;
	cmp	bp, PPT_SERIAL
	je	serialPort			; yes, so jump
	cmp	bp, PPT_PARALLEL		; check for parallel
	je	parallelPort
	cmp	bp, PPT_CUSTOM
	jne	done

	; For custom port, fetch the port data. Necessary for the
	; printer control panel to find the right list.

	call	PrinterGetCustomPortData
done:
	.leave
	ret

	; Handle the parallel case
	;
parallelPort:
	mov	es:[di].JP_portInfo.PPI_params.PP_parallel.PPP_portNum, ax
	jmp	done

	; Handle the file case - grab path out of file selector
	;

filePort:
	mov	es:[di].JP_portInfo.PPI_type, PPT_FILE
	mov	bx, dx				; PrintUI resource handle => BX
	mov	si, offset PrintFileFileSelector
	mov	dx, es
	lea	bp, es:[di].JP_portInfo.PPI_params.PP_file.FPP_path
	mov	cx, size FPP_path
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	es:[di].JP_portInfo.PPI_params.PP_file.FPP_diskHandle, cx

	; Grab the actual file name
	;
	mov	dx, es
	lea	bp, es:[di].JP_portInfo.PPI_params.PP_file.FPP_fileName
	mov	cx, size FPP_fileName
	mov	si, offset PrintFileNameText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	done

	; Handle the serial case (auugggghhhh) - assign defaults first
	;
serialPort:
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_portNum, ax
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format,
			SerialFormat <0, 0, SP_NONE, 0, SL_8BITS>
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_mode, SM_RAW
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_baud, SB_300
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_flow,
			mask SFC_SOFTWARE	
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_stopRem,
			mask SMC_RTS
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_stopLoc,
			mask SMS_CTS
	
	; Now get any changes from the default values
	;
	call	PrinterGetBaudRate
	call	PrinterGetParity
	call	PrinterGetWordLength
	call	PrinterGetStopBits
	call	PrinterGetHandshake
	call	PrinterGetControlBits
	jmp	done
PrinterGetPortInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetCustomPortData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the custom data for the printer port

CALLED BY:	(INTERNAL) PrinterGetPortInfo
PASS:		es:di	= JobParameters
		ds:si	= printer category
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
customDataStr	char	'customPortData', 0
PrinterGetCustomPortData proc	near
		uses	bp, di
		.enter
	;
	; Zero out the buffer for consistency's sake, in case there aren't
	; the max number of bytes in the ini file.
	;
		lea	di, ss:[JP_portInfo].PPI_params.PP_custom.CPP_info
		mov	cx, size CPP_info/2
		clr	ax
		push	di
		rep	stosw
	if size CPP_info and 1
		.leave
		stosb
	endif
		pop	di
	;
	; Now fetch the data from the ini file, if it's there.
	;
		mov	cx, cs
		mov	dx, offset customDataStr
		mov	bp, size CPP_info
		call	InitFileReadData
		.leave
		ret
PrinterGetCustomPortData endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baud rate for this printer

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer categroy name

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetBaudRate	proc	near
	.enter

	mov	cx, cs
	mov	dx, offset PrintControlCode:baudRateString
	call	InitFileReadInteger		; baud rate => AX
	jc	done				; no data - use default
	mov	bx, ax				; baud rate => BX
	mov	dx, 1
	mov	ax, 49664			; DX:AX = 152,000(serial magic)
	div	bx				; quotient => AX
	cmp	ax, 57				; was it a 2000 baud port ??
	jne	setBaud
	inc	ax				; else adjust baud value
setBaud:
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_baud, ax
done:
	.leave
	ret
PrinterGetBaudRate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetParity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the printer's parity settings

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer category name

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetParity	proc	near
	.enter

	; Now check the bit format
	;
	mov	cx, cs
	mov	dx, offset PrintControlCode:parityString
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	done				; no value - use default
	call	MemLock				; lock the string buffer
	push	es				; save the JobParamters block
	mov	es, ax
SBCS <	mov	bp, 1				; ES:BP points to 2nd char>
DBCS <	mov	bp, 2				; ES:BP points to 2nd char>
	mov	al, SP_NONE shl (offset SF_PARITY)
SBCS <	cmp	{byte} es:[bp], 'o' 		; check for o in "none"	>
DBCS <	cmp	{wchar} es:[bp], 'o' 					>
	je	setParity
	mov	al, SP_ODD shl (offset SF_PARITY)
SBCS <	cmp	{byte} es:[bp], 'd' 		; check for d in "odd"	>
DBCS <	cmp	{wchar} es:[bp], 'd' 					>
	je	setParity
	mov	al, SP_EVEN shl (offset SF_PARITY)
SBCS <	cmp	{byte} es:[bp], 'v' 		; check for v in "even"	>
DBCS <	cmp	{wchar} es:[bp], 'v' 					>
	je	setParity
	mov	al, SP_ONE shl (offset SF_PARITY)
SBCS <	cmp	{byte} es:[bp], 'n' 		; check for n in "one"	>
DBCS <	cmp	{wchar} es:[bp], 'n' 					>
	je	setParity
	mov	al, SP_ZERO shl (offset SF_PARITY)
setParity:
	pop	es
	call	MemFree				; free the buffer in BX
	and	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format,
			not mask SF_PARITY	; clear the old parity
	or	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format, al
done:
	.leave
	ret
PrinterGetParity	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetWordLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the printer's word length

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer category name

RETURN:		Nothing

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetWordLength	proc	near
	.enter

	; Get the word length
	;
	mov	cx, cs
	mov	dx, offset PrintControlCode:wordLenString
	call	InitFileReadInteger		; integer value => AX
	jc	done				; if none, use default
	sub	al, 5				; 5=>0, 6=>1, etc...
	cmp	al, SL_7BITS			; raw or cooked ??
	jne	storeLength			; if not seven bits, RAW
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_mode, SM_COOKED
storeLength:
	and	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format,
			not mask SF_LENGTH	; clear the old word length
	mov	cl, offset SF_LENGTH
	shl	al, cl				; put value into correct pos.
	or	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format, al
done:	
	.leave
	ret
PrinterGetWordLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetStopBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the printer's stop bits info...

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer category name

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetStopBits	proc	near
	uses	ds
	.enter

	; Finally, get the stop bits
	;
	mov	cx, cs
	mov	dx, offset PrintControlCode:stopBitsString
	mov	bp, INITFILE_INTACT_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	done				; if no key, use default
	call	MemLock				; lock the block
	mov	ds, ax				; DS:0 points to string
	cmp	cx, 1				; only one character ??
	jne	setExtra			; no, must be 1.5
SBCS <	cmp	{byte} ds:[0], '1'		; is character a 1 ??	>
DBCS <	cmp	{wchar} ds:[0], '1'		; is character a 1 ??	>
	je	doneStopBits			; yes, so use default
setExtra:
	or	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_format,
			mask SF_EXTRA_STOP	; else set the stop bit
doneStopBits:
	call	MemFree				; free the buffer in BX
done:
	.leave
	ret
PrinterGetStopBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetHandshake
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the handshake type for this printer

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer category name

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetHandshake	proc	near
	.enter

	; Now check out the handshake type
	;
	mov	cx, cs
	mov	dx, offset PrintControlCode:handShakeString
	mov	bp, INITFILE_DOWNCASE_CHARS	; allocate a buffer
	call	InitFileReadString		; string buffer handle => BX
	jc	done				; if none use default
	call	MemLock				; lock the string buffer
	push	es, di				; save the JobParamters block
	mov	es, ax
	clr	di				; ES:DI points to the string
	clr	dh				; assume neither handshake mode
	mov	dl, mask SFC_HARDWARE		; assume hardware
SBCS <	cmp	{byte} es:[di], 'h'		; check for h in "hardware">
DBCS <	cmp	{wchar} es:[di], 'h'		; check for h in "hardware">
	je	oneMode
	mov	dl, mask SFC_SOFTWARE		; assume software
SBCS <	cmp	{byte} es:[di], 's'		; check for s in "software">
DBCS <	cmp	{wchar} es:[di], 's'		; check for s in "software">
	je	oneMode
	clr	dl				; else none
oneMode:
	mov	dh, dl				; we now have 1 handshake mode
SBCS <	mov	al, VC_LF			; search for next string>
DBCS <	mov	ax, C_LINEFEED			; search for next string>
SBCS <	repne	scasb				; string count still in CX>
DBCS <	repne	scasw				; string count still in CX>
	jnz	setHandshake			; if EOS encountered, done 
	mov	dh, mask SFC_HARDWARE or mask SFC_SOFTWARE
setHandshake:
	pop	es, di				; JobParameters => ES:DI
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_flow, dh
	call	MemFree				; free the buffer in BX
done:
	.leave
	ret
PrinterGetHandshake	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterGetControlBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the hardware handshake control bits

CALLED BY:	PrinterGetPortInfo
	
PASS:		ES:DI	= JobParameters
		DS:SI	= Printer category name

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterGetControlBits	proc	near
	.enter

	test	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_flow,
			mask SFC_HARDWARE	; hardware control ??
	jz	done				; no, so do nothing
	mov	cx, cs
	mov	dx, offset PrintControlCode:stopRemoteString
	mov	bp, INITFILE_DOWNCASE_CHARS	; downcase all the characters
	call	InitFileReadString		; get the string
	jc	getLocal			; if failure, try local options
	push	es, di
	call	MemLock				; string segment => AX
	mov	es, ax
	clr	di				; string => ES:DI
	mov	dl, mask SMC_DTR		; assume DTR
SBCS <	cmp	{byte} es:[di], 'd'					>
DBCS <	cmp	{wchar} es:[di], 'd'					>
	je	getNextRemote
	mov	dl, mask SMC_RTS
getNextRemote:
SBCS <	mov	al, VC_LF						>
DBCS <	mov	ax, C_LINEFEED						>
SBCS <	repne	scasb				; scan for string sepearation>
DBCS <	repne	scasw				; scan for string sepearation>
	jnz	setRemote
	mov	dl, mask SMC_RTS or mask SMC_DTR
setRemote:	
	pop	es, di				; JobParameters => ES:DI
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_stopRem, dl

	; Get the stop local options
	;
getLocal:
	mov	cx, cs
	mov	dx, offset PrintControlCode:stopLocalString
	mov	bp, INITFILE_DOWNCASE_CHARS	; downcase all the characters
	call	InitFileReadString		; buffer => BX, chars => CX
	jc	done				; if failure, we're done
	push	es, di				; store the JobParameters
	call	MemLock				; string segment => AX
	mov	es, ax
	clr	di				; string => ES:DI
	clr	dh
localLoop:
	mov	dl, mask SMS_CTS
SBCS <	cmp	{byte} es:[di]+1, 't'		; check for 't' in CTS	>
DBCS <	cmp	{wchar} es:[di]+2, 't'		; check for 't' in CTS	>
	je	intermediateGetLocal
	mov	dl, mask SMS_DCD
SBCS <	cmp	{byte} es:[di]+1, 'c'		; check for 'c' in DCD	>
DBCS <	cmp	{wchar} es:[di]+2, 'c'		; check for 'c' in DCD	>
	je	intermediateGetLocal
	mov	dl, mask SMS_DSR		; else must be 's' in DSR
intermediateGetLocal:
	or	dh, dl				; store bit in DH
SBCS <	mov	al, VC_LF						>
DBCS <	mov	ax, C_LINEFEED						>
SBCS <	repne	scasb				; scan for string separation	>
DBCS <	repne	scasw				; scan for string separation	>
	jz	localLoop			; loop until end of string

	; Store the local options
	;
	pop	es, di				; JobParameters => ES:DI
	mov	es:[di].JP_portInfo.PPI_params.PP_serial.SPP_stopLoc, dh
	call	MemFree				; free the buffer in BX
done:
	.leave
	ret
PrinterGetControlBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintRequestUIOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request the UI options displayed by the printer driver,
		and verify that the application's UI is valid

CALLED BY:	PrintControlPrint
	
PASS:		ES:BP	= JobParameters
		BX	= JobParameters handle
		DS:*SI	= PrintControlClass object

RETURN:		Carry	= Clear (everything OK)
			= Set (problem with options)

DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Will also ask the application if its UI needs to be
		verified. If so, then the application must bring down
		the print dialog box. If not, this routine will request
		that the dialog box come down.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintRequestUIOptions	proc	near
	class	PrintControlClass
	uses	bx, si
	.enter

	; Get the print driver UI (if displayed)
	;
	mov	cx, bx				; JobParameters handle => CX
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINTER_OPTIONS
	call	PCCallSummons			; CX, DX holds options
	call	MemDerefES			; re-dereference JobParameters
	tst	ax				; check for success
	jz	done				; if successful, we're done
	stc					; else fail
done:
	.leave
	ret
PrintRequestUIOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintRequestAppVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request the application to verify that printing should
		ensue, if the application has the VERIFY attribute set

CALLED BY:	PrintControlPrint

PASS:		DS:*SI	= PrintControlClass object

RETURN:		Carry	= Clear (not verification necessary)
			= Set   (application will call back)

DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintRequestAppVerify	proc	near
	class	PrintControlClass
	.enter
	
	; See if the application needs to verify its UI
	;
	mov	di, ds:[si]
	add	di, ds:[di].PrintControl_offset
	test	ds:[di].PCI_attrs, mask PCA_VERIFY_PRINT
	jz	done
	push	bx, si
	mov	ax, MSG_PRINT_VERIFY_PRINT_REQUEST
	mov	bx, offset PCI_output
	call	PCSendToOutputOD		; send the message
	pop	bx, si
	stc					; continue with processing
done:
	.leave
	ret
PrintRequestAppVerify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCreateSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file in which to spool the print job

CALLED BY:	PrintControlPrint
	
PASS:		ES:BP	= JobParameters
		DS:*SI	= PrintControl instance data

RETURN:		AX	= File handle
		DI	= GString handle
		ES:BP	= JobParameters
				JP_fname filled in

		Carry	= Clear (no error)
			- or -
		Carry	= Set (error)

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCreateSpoolFile	proc	near
	uses	bx, bp
	.enter

	; Create a spool file, unless someone has already done it
	;
	mov	dx, es
	push	si				; save PrintControl chunk
	mov	si, offset JP_fname		; filename buffer => DX:SI
	call	SpoolCreateSpoolFile		; file handle => AX
	pop	si				; PC object => DS:*SI
	mov_tr	bx, ax				; file handle => BX
	tst	bx				; clears carry
	jz	error				; if error, notify user

	; Create the GString
	;
	push	si
	mov	cl, GST_STREAM			; signal a stream
	call	GrCreateGString			; Returns gstring => DI
	mov_tr	ax, bx				; file handle => AX
	pop	si

	; Finally, allow the print driver to do something
	;
	push	ax, di
	mov	ax, MSG_SPOOL_SUMMONS_PREPEND_APPEND_PAGE
	mov	cx, DR_PRINT_ESC_PREPEND_PAGE
	mov	dx, di
	call	PCCallSummons
	pop	ax, di
	clc					; no errors
exit:
	.leave
	ret

	; Error in creating a file - notify user
error:
	mov	ax, MSG_SPOOL_SUMMONS_REMOTE_ERROR
	mov	cx, PCERR_FAIL_FILE_CREATE	; error type
	mov	bp, MSG_META_DUMMY		; method to send...
	call	PCCallSummons			; call over to the summons
	stc
	jmp	exit
PrintCreateSpoolFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintRequestDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request the document name of what is being printed.

CALLED BY:	PrintControlPrint
	
PASS:		DS:*SI	= PrintControl instance data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintRequestDocName	proc	near
	class	PrintControlClass
	uses	bx, si, bp
	.enter

	; Send the request method to the OD
	;
	mov	ax, MSG_PRINT_GET_DOC_NAME
	mov	bx, offset PCI_docNameOutput
	mov	bp, MSG_PRINT_CONTROL_SET_DOC_NAME
	call	PCSendToOutputOD		; send message to output

	.leave
	ret
PrintRequestDocName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCreateProgressDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the progress dialog box up on screen.

CALLED BY:	GLOBAL

PASS:		*DS:SI	= PrintControl object
		ES:BP	= JobParameters

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCreateProgressDB	proc	near
	class	PrintControlClass
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	
	; First duplicate the UI, and then display it to the user
	;
	mov	di, ds:[si]
	add	di, ds:[di].PrintControl_offset
	mov	ax, ds:[di].PCI_attrs		; PrintControlAttrs => AX
	test	ax, mask PCA_SHOW_PROGRESS	; show progress DB ??
	jz	done				; nope, so we're outta here
	push	si, bp, si, ax
	mov	cx, handle ProgressDialogBox	; resource handle => CX
	mov	dx, offset ProgressDialogBox	; chunk handle => DX
	mov	bp, offset TPCI_progressBox
	call	PCDuplicateBlock		; new dialog box OD => BX:SI
	pop	si, ax

	; Set NOT_USABLE things we don't want to display
	;
	call	PCAccessTemp			; TempPrintCtrlInstance => DS:DI
	mov	bx, ds:[di].TPCI_progressBox.handle
	test	ax, mask PCA_PROGRESS_PAGE
	jnz	percent
	push	ax
	mov	si, offset ProgressUI:ProgressPage
	call	PCSetNotUsable
	pop	ax
percent:
	test	ax, mask PCA_PROGRESS_PERCENT
	jnz	onScreen
	mov	si, offset ProgressUI:ProgressPercent
	call	PCSetNotUsable
onScreen:
	mov	si, offset ProgressUI:ProgressDialogBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	PCObjMessageCall

	; Now set the application name text
	;
	pop	bp
	mov	si, offset ProgressUI:ProgressDocument
	mov	dx, es
	add	bp, offset JP_parent		; application name => DX:BP
	call	progressSetTextCommon		; set the text
	; Finally set the initial page to be printed
	;
	pop	si				; PC object => *DS:SI
	mov	ax, MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE
	call	PCCallSummons
	mov	ax, MSG_PRINT_CONTROL_REPORT_PROGRESS
	mov	dx, cx				; first page => DX
	mov	cx, PCPT_PAGE
	call	ObjCallInstanceNoLock		; call the method handler
done:
	.leave
	ret
PrintCreateProgressDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDestroyProgressDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the progress dialog box up on screen.

CALLED BY:	GLOBAL

PASS:		DS:DI	= TempPrintCtrlInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintDestroyProgressDB	proc	near
	uses	di
	.enter
	
	; Destroy the Progress dialog box
	;
	clr	bx				; get objecct block handle
	xchg	bx, ds:[di].TPCI_progressBox.handle
	tst	bx				; any box up ??		
	jz	done
	mov	si, offset ProgressDialogBox	; OD of verify box => BX:SI
	call	PCSetNotUsable			; first set it not usable...
	mov	ax, MSG_META_BLOCK_FREE
	call	PCObjMessageSend		; ...then free the block
done:
	.leave
	ret
PrintDestroyProgressDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintMarkAppBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an application busy while printing

CALLED BY:	INTERNAL

PASS:		DS:DI	= TempPrintCtrlInstance
		DX	= PrintControlAttrs

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintMarkAppBusy	proc	near
	uses	di
	.enter
	
	; Mark the application busy, as needed
	;
	mov	ds:[di].TPCI_attrs, dx		; store these attributes
	test	dx, mask PCA_MARK_APP_BUSY
	jz	done
	mov	bx, ds:[LMBH_handle]		; my block handle => BX
	call	MemOwner			; process owning block => BX
	call	GeodeGetAppObject		; GenApplication obj => BX:SI
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	PCObjMessageCall
done:
	.leave
	ret
PrintMarkAppBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintMarkAppNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an application no longer busy, after printing

CALLED BY:	INTERNAL

PASS:		DS:DI	= TempPrintCtrlInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintMarkAppNotBusy	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	
	; Mark the application busy, as needed
	;
	clr	ax
	xchg	ds:[di].TPCI_attrs, ax		; zero attributes
	test	ax, mask PCA_MARK_APP_BUSY	; was app marked busy ??
	jz	done
	mov	bx, ds:[LMBH_handle]		; my block handle => BX
	call	MemOwner			; process owning block => BX
	call	GeodeGetAppObject		; GenApplication obj => BX:SI
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	PCObjMessageCall
done:
	.leave
	ret
PrintMarkAppNotBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProgressUpdatePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the "page" being printer by the application

CALLED BY:	PrintControlReportProgress

PASS:		*DS:SI	= PrintControl object
		DS:DI	= TempPrintCtrlInstance
		DX	= Page number
		BX	= Handle of ProgressDialogBox

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Create the string "Printing page XX (YY more to go)", where
			XX = current page
			YY = # of pages left to print

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_PROGRESS_PAGE_TEXT_LENGTH	= 64

ProgressUpdatePage	proc	near
	.enter

	; Some set-up work
	;
SBCS <	sub	sp, MAX_PROGRESS_PAGE_TEXT_LENGTH			>
DBCS <	sub	sp, MAX_PROGRESS_PAGE_TEXT_LENGTH*(size wchar)		>
	mov	di, sp
	segmov	es, ss				; text buffer => ES:DI
	push	di				; save start of text
	push	bx				; save Progress DB handle
	mov	bp, dx				; current page number => BP
	mov	ax, MSG_SPOOL_SUMMONS_GET_DRIVER_TYPE
	call	PCCallSummons
	mov	bl, cl				; PrinterDriverType => CL
	mov	ax, MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE
	call	PCCallSummons			; range => CX, DX
	sub	dx, bp
	mov	cl, bl				; PrinterDriverType => CL
	push	dx				; save pages left to go
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
assume	ds:Strings

	; Create the string to display
	;
	mov	si, ds:[progressFaxingString]
	cmp	cl, PDT_FACSIMILE
	je	copyString
	mov	si, ds:[progressPrintingString]
copyString:
	call	PageCopyString			; "Printing/Faxing page "
	call	PageCopyPageNum			; "XX"
	mov	si, ds:[progressPageString2]
	call	PageCopyString			; " ("
	pop	bp
	call	PageCopyPageNum			; "YY"
	mov	si, ds:[progressPageString3]
	call	PageCopyString			; " to go)"
	clr	ax
	LocalPutChar	esdi, ax

	; Now set the text, and clean up
	;
	mov	dx, es
	pop	bx				; restore Progress DB handle
	pop	bp				; text buffer => DX:BP
	mov	si, offset ProgressUI:ProgressPage
	call	progressSetTextCommon		; set the text
	mov	bx, handle Strings
	call	MemUnlock
assume	ds:dgroup
SBCS <	add	sp, MAX_PROGRESS_PAGE_TEXT_LENGTH			>
DBCS <	add	sp, MAX_PROGRESS_PAGE_TEXT_LENGTH*(size wchar)		>

	.leave
	ret
ProgressUpdatePage	endp

PageCopyString	proc	near
	ChunkSizePtr	ds, si, cx
DBCS <	shr	cx, 1				; cx <- length		>
	dec	cx				; ignore NULL terminator
	LocalCopyNString			; copy in string
	ret
PageCopyString	endp

PageCopyPageNum	proc	near
	mov_tr	ax, bp
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii		; create the page
						; number
DBCS <	shl	cx, 1	>
	add	di, cx				; point just after the string
	ret
PageCopyPageNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProgressUpdatePercent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the percentage completed in the Print Progress DB

CALLED BY:	PrintControlReportProgress

PASS:		*DS:SI	= PrintControl object
		DS:DI	= TempPrintCtrlInstance
		DX	= Page number
		BX	= Handle of ProgressDialogBox

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProgressUpdatePercent	proc	near

	; Tell the percentage indicator what to display
	;
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, dx				; value => CX
	clr	bp				; "determinate"
	mov	si, offset ProgressUI:ProgressPercent
	GOTO	PCObjMessageCall
ProgressUpdatePercent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProgressUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text displayed in the Print Progress DB

CALLED BY:	PrintControlReportProgress

PASS:		*DS:SI	= PrintControl object
		DS:DI	= TempPrintCtrlInstance
		DX:BP	= Text to display
		BX	= Handle of ProgressDialogBox

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProgressUpdateText	proc	near
	
	; Tell the text object to display some text
	;
	mov	si, offset ProgressUI:ProgressText
progressSetTextCommon	label	near
	clr	cx				; text is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	GOTO	PCObjMessageCall

ProgressUpdateText	endp


COMMENT @----------------------------------------------------------------------

METHOD:		PrintDispatchEvent

DESCRIPTION:	Intercept messages to be dispatched, watching for the
		"GWNT_SPOOL_PRINTING_COMPLETE" message that the desktop
		uses to know that its IACP message to the desktop is
		"complete".  We change this to mean not just that the
		message arrived, but that the print sequence itself has
		completed (or not possible, or has been canceled), so that
		the desktop need merely wait for the return of its 
		completion message before going on to the next file to
		be printed.  Basically, a Hack :)

PASS:
	*ds:si - instance data
	es - segment of PrintControlClass

	ax - MSG_META_DISPATCH_EVENT

	^hcx	- Event
	dx	- MessageFlags

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/17/92	Initial version
	SH	04/27/94	XIP'ed
------------------------------------------------------------------------------@

PrintDispatchEvent	method	PrintControlClass, MSG_META_DISPATCH_EVENT

	; See if this event should be delayed or not
	;
	push	cx, dx, si
	mov	bx, cx
	mov	si, -1			; preserve event
	mov	ax, SEGMENT_CS		; ax <- vseg if XIP'ed
	push	ax
	mov	ax, offset PrintDispatchEventCallback
	push	ax
	call	MessageProcess
	pop	cx, dx, si
	jc	delayEvent

	; Don't delay, so send the even right away
	;
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	di, offset PrintControlClass
	GOTO	ObjCallSuperNoLock

	; Else save the event away in vardata
delayEvent:
	push	cx			; recorded event
	push	dx			; MessageFlags

	; Dispatch any currently saved event -- weird case...
	;
	call	DispatchPrintCompletionEvent

	; Save away event for later dispatch
	;
	mov	ax, TEMP_PRINT_COMPLETION_EVENT
	mov	cx, size TempPrintCompletionEventData
	call	ObjVarAddData

	pop	ds:[bx].TPCED_messageFlags
	pop	ds:[bx].TPCED_event

	call	CheckUpOnPrintCompletionMessage	; See if we should send out
	ret					; completion message
PrintDispatchEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDisplatEventCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatch an event (maybe)

CALLED BY:	MessageProcess (callback)

PASS:		same as ObjMessage

RETURN:		Carry	= Set (delay)
			= Clear (process now)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Doug	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintDispatchEventCallback	proc	far
	cmp	ax, MSG_META_NOTIFY
	jne	notEvent
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	notEvent
	cmp	dx, GWNT_SPOOL_PRINTING_COMPLETE
	jne	notEvent
	stc
	ret
notEvent:
	clc
	ret
PrintDispatchEventCallback	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	PrintNotifyEnabled
			-- MSG_GEN_NOTIFY_ENABLED for PrintClass

DESCRIPTION:	Handle the controller being set enabled

PASS:
	*ds:si - instance data
	es - segment of PrintClass

	ax - The message

	dl - VisUpdateMode
	dh - NotifyEnabledFlags

RETURN:
	carry set if visual state changed

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version
	Doug	12/29/92	Changed to deal w/controllers not yet resolved

------------------------------------------------------------------------------@
PrintNotifyEnabled	method dynamic	PrintControlClass,
						MSG_GEN_NOTIFY_ENABLED,
						MSG_GEN_NOTIFY_NOT_ENABLED
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	exit			;skip if not usable...

	push	ax, dx
	mov	di, offset PrintControlClass
	call	ObjCallSuperNoLock
	lahf				; keep carry flag in ch
	mov	ch, ah
	pop	ax, dx
	and	dh, not mask NEF_STATE_CHANGING	; clear "this object" bit.

	; if we have any dialogs up, deal with them as well

	call	PCGetSummons
	jnc	afterTools
	push	cx			; preserve saved flags
	call	PCObjMessageSend
	pop	cx
	andnf	ch, mask CPU_CARRY	; keep only the old carry flags
	lahf
	ornf	ch, ah			; OR returned carry flags together

afterTools:
	mov	ah, ch			; return flags kept in ch
	sahf
exit:
	ret

PrintNotifyEnabled	endm

PrintControlCode	ends



