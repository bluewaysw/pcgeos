COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Lib/Spool/UI
FILE:		uiPrintControlUtils.asm

AUTHOR:		Don Reeves, March 30, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/90/89		Initial revision


DESCRIPTION:
	Utility routines needed in the print control module
		
	$Id: uiPrintControlUtils.asm,v 1.1 97/04/07 11:10:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintControlCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCAccessTemp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the PrintControl local variables

CALLED BY:	INTERNAL

PASS:		DS:*SI	= PrintControl instance data

RETURN:		DS:DI	= TempPrintCtrlInstance

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCAccessTemp	proc	far
	uses	ax, bx
	.enter

	; Find the variable data
	;
	mov	ax, TEMP_PRINT_CONTROL_INSTANCE
	call	ObjVarFindData
	jnc	allocate
	mov	di, bx				; TempPrintCtrlInstance => DS:DI
done:
	.leave
	ret

	; Allocate the variable data
allocate:
	push	cx
	mov	cx, size TempPrintCtrlInstance
	call	ObjVarAddData			; add data & initialize to zero
	mov	di, bx				; TempPrintCtrlInstance => DS:DI
	call	PCCheckForFax			; set/clear fax attribute
	pop	cx
	jmp	done				; we're outta here
PCAccessTemp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCheckForFax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if there are any fax drivers available

CALLED BY:	INTERNAL

PASS:		DS:DI	= TempPrintCtrlInstance

RETURN:		Zero	= Set if no change from earlier status
			= Clear if change

DESTROYED:	AX, CL

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Sets/clears the FAX attribute in TPCI_status

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCCheckForFax	proc	far
	
	; Check for fax drivers, & clear/set the fax attribute
	;
	mov	cx, PDT_FACSIMILE	; PrinterDriverType => CL
	call	SpoolGetNumPrinters	; number of faxes => AX
	mov	cl, ds:[di].TPCI_status
	and	ds:[di].TPCI_status, not (mask PSF_FAX_AVAILABLE)
	tst	ax
	jz	done
	or	ds:[di].TPCI_status, mask PSF_FAX_AVAILABLE
done:
	xor	cl, ds:[di].TPCI_status
	and	cl, mask PSF_FAX_AVAILABLE	; zero set if no change
	ret					; zero clear if status change
PCCheckForFax	endp


PrintControlCommon ends

;---

PrintControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCDestroyTemp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the PrintControl local variables

CALLED BY:	INTERNAL

PASS:		DS:*SI	= PrintControl instance data

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCDestroyTemp	proc	near
	uses	ax
	.enter

	; Remove the variable data
	;
	mov	ax, TEMP_PRINT_CONTROL_INSTANCE
	call	ObjVarDeleteData

	.leave
	ret
PCDestroyTemp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCIsAddrControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the print control is associated with a 
		MailboxSpoolAddressControl

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= PrintControl object
RETURN:		carry set if it's associated with an address control
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCIsAddrControl	proc	far
		uses	ax, bx
		.enter
		mov	ax, TEMP_PRINT_CONTROL_ADDRESS_CONTROL
		call	ObjVarFindData
		.leave
		ret
PCIsAddrControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCallAddressControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're associated with a MailboxSpoolAddressControl, call it
		with the passed message and our identification

CALLED BY:	(INTERNAL) StartPrintJob, 
			   PrintControlPrintingCanceled
PASS:		ax	= message to call on the thing
		cx	= data to pass to it
		*ds:si	= PrintControl
RETURN:		carry set if associated with print control
			ax, cx, dx, bp = from message
		carry clear if not associated with print control
			ax, cx, dx, bp = unchanged
DESTROYED:	nothing
SIDE EFFECTS:	depends on the message delivered

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCallAddressControl proc	far
		uses	bx, si, di
		.enter
		push	ax
		mov	ax, TEMP_PRINT_CONTROL_ADDRESS_CONTROL
		call	ObjVarFindData
		pop	ax
		jnc	done
		
		mov	bp, si
		mov	dx, ds:[LMBH_handle]
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle
		call	PCObjMessageCall
		stc
done:
		.leave
		ret
PCCallAddressControl endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCBuildSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the building of the SpoolSummons dialog box for
		this PrintControl object

CALLED BY:	PrintControl - GLOBAL
	
PASS:		DS:*SI	= PrintControl instance data

RETURN:		DS:*DI	= PrintControl instance data
		BX:SI	= SpoolSummons OD

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCBuildSummons	proc	near
	class	PrintControlClass
	.enter

	; Generate the UI for the controller so we're sure we're on the
	; active list and will be told when to destroy this summons we're
	; about to create -- ardeb 3/11/93
	; 
	
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarFindData
	jnc	notBuiltYet
	tst	ds:[bx].TGCI_childBlock
	jnz	builtAlready
notBuiltYet:
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
builtAlready:

	; First, make sure that controller is updating its own enable status,
	; or child dialogs won't be enabled if they are brought up directly
	; (such as via IACP)	-- Doug 12/18/92
	;
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock

	; First duplicate the entire PrintUI block
	;
	mov	cx, handle PrintDialogBox	; block handle => CX
	mov	dx, offset PrintDialogBox	; chunk handle => DX
	mov	bp, offset TPCI_currentSummons	; offset in LPCD => BP
	push	si, si
	call	PCDuplicateBlock		; new OD => BX:SI

	pop	di				; *ds:di <- PC
	call	PCAddAppUI


	; set dialog usable, now (it was not-usable so it could be added as
	; a child of the controller if associated with an address control)
	; 		-- ardeb 10/27/94

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	PCObjMessageSend
	pop	di				; PC handle => DI

	.leave
	ret
PCBuildSummons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCAddAppUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obey the ATTR_PRINT_CONTROL_APP_UI hint, if present

CALLED BY:	(INTERNAL) PCBuildSummons, PCGenControlTweakDuplicatedUI
PASS:		^lbx:si	= summons
		*ds:di	= PrintControl
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCAddAppUI proc	far
	.enter
	; Add any application-defined print group; Find position where to add
	; (Note:  app-defined group is added before the object we look for here)
	;
	push	di
	mov	cx, bx
	mov	dx, offset PrintUI:PrintTriggerGroup
	mov	ax, MSG_GEN_FIND_CHILD
	call	PCObjMessageCall		; returns child number in BP

	; Now actually add in the group if necessary
	;
	pop	ax				; restore PrintControl chunk	
	push	bx, si				; save new object block OD
	mov_tr	si, ax
	mov	ax, ATTR_PRINT_CONTROL_APP_UI
	call	ObjVarFindData			; data => DS:BX
	jnc	done				; if no extra UI, we're done
	mov	cx, ds:[bx].handle
	mov	dx, ds:[bx].chunk
EC <	mov	bx, cx							>
EC <	mov	si, dx				; OD => BX:SI		>
EC <	call	ECCheckLMemOD			; check the OD		>
	pop	bx, si				; new object block OD => BX:SI
	mov	ax, MSG_GEN_ADD_CHILD
	call	PCObjMessageCall

	; Set the group usable
	;
	push	bx, si
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	PCObjMessageCall
done:			
	pop	bx, si				; new object block OD => BX:SI
	.leave
	ret
PCAddAppUI endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCDestroySummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up all linkage

CALLED BY:	PrintControlVisUnbuild, PrintControlDetach
	
PASS:		DS:*SI	= PrintControlClass instance data

RETURN:		Carry	= Set (if in the middle of printing)

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCDestroySummons	proc	far
	class	PrintControlClass
	.enter

	; Let's first take care of the Print dialog box. If we are
	; in the middle of printing, then do nothing.
	;
	call	PCAccessTemp		; local data => DS:DI
	tst	ds:[di].TPCI_jobParHandle
	stc
	jnz	exit
	clr	cx, dx
	xchg	cx, ds:[di].TPCI_currentSummons.handle
	xchg	dx, ds:[di].TPCI_currentSummons.chunk
	jcxz	done			; if no block, do nothing

	; Remove any application-defined print group
	;
	push	si			; save PrintControl chunk
	mov	ax, ATTR_PRINT_CONTROL_APP_UI
	call	ObjVarFindData		; data => DS:BX
	mov	bp, bx			; OD => DS:BP
	mov	bx, cx
	mov	si, dx			; parent => BX:SI
	jnc	freeDuplicate		; if not found, jump
	call	PCRemoveObjectFromTree	; remove an app-defined objects
	
	; Clean up the SpoolSummons object
freeDuplicate:
	mov	ax, MSG_SPOOL_SUMMONS_CLEAN_UP
	call	PCObjMessageCall
	call	PCSetNotUsable		; set dialog box not usable

	; Remove from window list
	;
	push	bx, si
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListParams
	pop	bx, si

	; Free the duplicate block now
	;
	mov	ax, MSG_META_BLOCK_FREE
	call	PCObjMessageSend
	pop	si
	
	; Finally, remove my local instance data
done:
	call	PCDestroyTemp		; destroy my local data
	clc
exit:
	.leave
	ret
PCDestroySummons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCDuplicateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the passed resource, and make the new OD a child
		of the passed PrintControl object

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= PrintControl object
		CX	= Resource to duplicate
		DX	= Chunk of root of GenTree in resource
		BP	= Offset in TempPrintCtrlInstance to store OD

RETURN:		BX:SI	= OD of root of GenTree in duplicated resource

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCDuplicateBlock	proc	near
	uses	ax, cx, dx, di, bp
	.enter

	; Duplicate the block, and hook it into our tree
	;
	mov	bx, ds:[LMBH_handle]		; PC block handle => BX
	call	MemOwner			; find the owner (in BX)
	xchg	ax, bx				; owner to AX
	mov	bx, cx
	clr	cx				; have current thread run block
	call	ObjDuplicateResource		; duplicate the block
	mov	cx, bx				; block handle => CX
	call	GenAddChildUpwardLinkOnly

	; Store the OD in the TempPrintCtrlInstance
	;
	cmp	bp, -1
	je	updateOD
	call	PCAccessTemp			; local data => DS:DI
	mov	ds:[di][bp].handle, cx
	mov	ds:[di][bp].chunk, dx

	; Update all of the OD references
	;
updateOD:
	mov	bx, cx
	xchg	si, dx
	mov	cx, ds:[LMBH_handle]		; want CX:DX to be the PC
	mov	bp, PCPT_PRINT_CTRL
	mov	ax, MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT
	push	cx, dx				; save OD of PrintControl object
	call	PCObjMessageCall

	; Set the output for the duplicated block
	;
	mov	di, si
	call	ObjLockObjBlock			; lock the duplicated block
	mov	ds, ax				; segment => DS
	pop	bx, si
	call	ObjBlockSetOutput		; set the output object
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	xchg	bx, cx				; exchange new & PC handle
	call	MemDerefDS			; resource holding PC => DS
	mov	bx, cx
	mov	si, di				; duplicated block OD => BX:SI

	.leave
	ret
PCDuplicateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCForceCallSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the SpoolSummons object owned by the PrintControl object
		with the passed method. Force the SpoolSummons to be built
		out if none exists.

CALLED BY:	PrintControl - GLOBAL
	
PASS:		DS:*SI	= PrintControl instance data
		AX	= Method to send
		CX, DX, BP	=  Data to send

RETURN:		AX, CX, DX, BP	= Return values

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCForceCallSummons	proc	near
	; Do we already have a SpoolSummons built out ??
	;
	push	di
	call	PCIsAddrControl
	jc	doCall			; => is address control, ui generated,
					;  so we have the summons

	call	PCAccessTemp			; access local data
	tst	ds:[di].TPCI_currentSummons.handle	; is there a summons ??
	jnz	doCall				; yes, so don't worry

	; Else we must built out the dialog box
	;
	push	ax, bx, cx, dx, di, bp
	call	PCBuildSummons			; build out the summons
	mov	si, di				; PrintControl => DS:*SI
	pop	ax, cx, cx, dx, di, bp
doCall:
	pop	di
	FALL_THRU	PCCallSummons		; do the calling
PCForceCallSummons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCallSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a method over to the summons class

CALLED BY:	PrintControl - GLOBAL

PASS:		DS:*SI	= PrintControl instance data
		AX	= Method to send
		CX, DX, BP	= Data to send		

RETURN:		Carry	= Set if method was sent
			  {AX, CX, DX, BP} = Return values
			= Clear if no SpoolSummons built out yet

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCCallSummons	proc	near
	uses	bx, di, si
	class	PrintControlClass
	.enter

	call	PCGetSummons
	jnc	done

	call	PCObjMessageCall
	stc						; set carry
done:
	.leave
	ret
PCCallSummons	endp

FarPCCallSummons proc far
	call	PCCallSummons
	ret
FarPCCallSummons endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCGetSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the optr of the current summons, if we have one

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= PrintControl
RETURN:		carry set if summons exists:
			^lbx:si	= SpoolSummons object
		carry clear if summons doesn't exist:
			bx	= 0
			si	= 0?
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCGetSummons proc	near
	uses	di
	class	PrintControlClass
	.enter
	call	PCIsAddrControl
	jnc	useTempData
	
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GI_comp.CP_firstChild
	jmp	haveSummons

useTempData:
	call	PCAccessTemp				; access local data
	mov	bx, ds:[di].TPCI_currentSummons.handle
	mov	si, ds:[di].TPCI_currentSummons.chunk	

haveSummons:
	tst_clc	bx					; is there a summons ??
	jz	done					; if not, exit now
	stc
done:
	.leave
	ret
PCGetSummons	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCOpenPrintStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the print strings block and lock it

CALLED BY:	GLOBAL

PASS:		DS:*SI	= PrintControl instance data

RETURN:		DS:DI	= Printer strings
		CX	= Length of the strings buffer
		DX	= Current printer (0 -> N-1)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCOpenPrintStrings	proc	near
	uses	ax, bx, si, bp
	.enter

	; Call over to the SpoolSummons for the info
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINTER_STRINGS
	call	PCCallSummons

	; Now set-up the registers
	;
	call	PCAccessTemp			; access the local data
	mov	ds:[di].TPCI_printBlockHan, dx	; store the block handle
	mov	bx, dx
	call	MemLock				; lock the block
	mov	ds, ax
	clr	di				; DS:DI is the print strings
	mov	dx, bp				; current printer => DX

	.leave
	ret
PCOpenPrintStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCClosePrintStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access the print strings block and unlock it

CALLED BY:	GLOBAL

PASS:		DS:*SI	= PrintControl instance data

RETURN:		Nothing

DESTROYED:	Nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCClosePrintStrings	proc	near
	uses	bx, di
	.enter

	pushf
	call	PCAccessTemp			; access the local variables
	mov	bx, ds:[di].TPCI_printBlockHan	; block handle => BX
	call	MemFree				; free the block
	popf

	.leave
	ret
PCClosePrintStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCAddObjectToTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an object to a generic tree

CALLED BY:	EXTERNAL

PASS:		DS:[DI][BP] = OD of object to remove
		BX:SI	= OD of parent

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0
PCAddObjectToTree	proc	far
	.enter
	
	; If there is any UI, add it to the tree
	;
	mov	cx, ds:[di][bp].handle
	mov	dx, ds:[di][bp].chunk
	jcxz	done			; if no UI, we're done
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CompChildFlags <0, CCO_LAST>
	call	PCObjMessageCall	; add as a generic child

	; Now set the new child usable
	;
	mov	bx, cx
	mov	si, dx			; new child OD => BX:SI
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	PCObjMessageSend	; set the UI stuff usable
done:
	.leave
	ret
PCAddObjectToTree	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCRemoveObjectFromTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an object from a generic tree

CALLED BY:	PCDestroySummons()

PASS:		DS:[BP] = OD of object to remove
		BX:SI	= OD of parent

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCRemoveObjectFromTree	proc	near
	
	; First set it not usable (if it exists at all)
	;
	push	bx, si				; save parent OD
	mov	bx, ds:[bp].handle
	mov	si, ds:[bp].chunk
	call	PCSetNotUsable			; set user-group not usable
	
	; Now remove the user-group from the dialog box
	;
	mov	cx, bx
	mov	dx, si				; user group => CX:DX
	pop	bx, si				; parent OD => BX:SI
	mov	ax, MSG_GEN_REMOVE_CHILD	; remove the child
	clr	bp				; don't mark links as dirty
	GOTO	PCObjMessageCall

PCRemoveObjectFromTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCSetNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets an object NOT_USABLE

CALLED BY:	INTERNAL

PASS:		BX:SI	= OD of object

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCSetNotUsable	proc	near
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	GOTO	PCObjMessageCall
PCSetNotUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCSendToOutputOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to one of the two PrintControl output OD's

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PrintControl object
		AX	= Message to send
		BX	= Offset in instance data to OD
		BP	= Data

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI

PSEUDO CODE/STRATEGY:
		Passed to destination:
			CX:DX	= OD of PrintControl object
			BP	= Data passed to this routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCSendToOutputOD	proc	near
	.enter
	
	; Set things up for call to GenProcessAction
	;
	mov	di, ds:[si]
	add	di, ds:[di].PrintControl_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; Send our OD in CX:DX
	push	ds:[di][bx].handle	
	push	ds:[di][bx].chunk		; ...to the OutputDescriptor
	mov	di, mask MF_FIXUP_DS		; MessageFlags => DI
	call	GenProcessAction		; send message to OD

	.leave
	ret
PCSendToOutputOD	endp

PrintControlCode	ends
