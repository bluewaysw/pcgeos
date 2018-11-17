COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Spool/UI
FILE:		uiSpoolSummonsUtils.asm

AUTHOR:		Don Reeves, April 24, 1991

ROUTINES:
	Name				Description
	----				-----------
    EXT	SSEnableDisablePrinting		Enable/disable the print triggers
    EXT	SSSetIntegerValue		Set a GenValue value, send no apply
    EXT	SSSetIntegerValueApply		Set a GenValue value, send apply msg
    EXT	SSSetMinimumValue		Set a GenValue minimum value (integer)
    EXT SSSetMaximumValue		Set a GenValue maximum value (integer)
    EXT	SSSetItemSelection		Set selection for a GenItemGroup
    EXT	SSSetItemSelectionStatus	Set selection for same, send status
    EXT	SSEnableOrDisable		Enable or disable object, based on mask
    EXT	SSUsableOrNotUsable		Set usable or not object, based on mask
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/24/91		Initial revision
	Don	1/16/92		Improved documentation, added routine

DESCRIPTION:
	Contains utility routines to be used by the SpoolSummonsClass
		
	$Id: uiSpoolSummonsUtils.asm,v 1.1 97/04/07 11:10:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEnableDisablePrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or diable the printer trigger

CALLED BY:	GLOBAL
	
PASS:		DS	= Segment of PrintUI
		Carry	= Clear (enable) or Set (disable)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSEnableDisablePrinting	proc	near
	uses	bx, si
	pushf
	.enter

	; Set up the mask, and then enable/disable the triggers
	;
	mov	bx, (1 shl 8) or 1		; mask = 1
	adc	bx, 0				; flag = 1 (on) or 2 (off)	
	mov	si, offset PrintUI:PrintOKTrigger
	call	EnableOrDisableObject
	mov	si, offset PrintUI:PrintToFileTrigger
	call	EnableOrDisableObject	

	.leave
	popf
	ret
SSEnableDisablePrinting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSetIntegerValue, SSSetMinimumValue, SSSetMaximumValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a GenValue object with an integer value (or minimum
		or maximum).

CALLED BY:	INTERNAL

PASS:		*DS:SI	= GenValueClass object
		DX	= Value

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSSetIntegerValueStatus	proc	near
	uses	ax, cx, dx, bp
	.enter

	call	SSSetIntegerValue
EC <	push	bx							>
EC <	mov	ax, ATTR_GEN_VALUE_STATUS_MSG				>
EC <	call	ObjVarFindData						>
EC <	ERROR_NC SPOOL_SUMMONS_EXPECTED_ATTR_STATUS_MSG			>
EC <	pop	bx							>
	mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock

	.leave
	ret
SSSetIntegerValueStatus	endp

SSSetIntegerValue	proc	near
	push	ax
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	GOTO	SSSetValueCommon, ax
SSSetIntegerValue	endp

SSSetMinimumValue	proc	near
	push	ax
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	GOTO	SSSetValueCommon, ax
SSSetMinimumValue	endp

SSSetMaximumValue	proc	near
	push	ax
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	FALL_THRU	SSSetValueCommon, ax
SSSetMaximumValue	endp

SSSetValueCommon	proc	near
	uses	cx, dx, bp
	.enter

	clr	cx				; no fraction
	clr	bp				; "determinate" value
	call	ObjCallInstanceNoLock

	.leave
	FALL_THRU_POP	ax
	ret
SSSetValueCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSetItemSelection, SSSetItemSelectionStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection for a GenItemSelection object. If "Status"
		called, ask for the status message to be sent in return.

CALLED BY:	INTERNAL

PASS:		*DS:SI	= GenItemSelectionClass object
		CX	= Identifier

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSSetItemSelectionStatus	proc	near
	push	ax, cx, dx, bp
	call	SSSetItemSelection
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	ret
SSSetItemSelectionStatus	endp

SSSetItemSelection		proc	near
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; list is "determinate"
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	ret
SSSetItemSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableOrDisableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable an object passed, dependent upon flags

CALLED BY:	GLOBAL
	
PASS:		DS:*SI	= Object
		BL	= Flags
		BH	= Mask

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnableOrDisableObject	proc	near
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	bl, bh
	jz	setStatus
	mov	ax, MSG_GEN_SET_ENABLED
setStatus:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret
EnableOrDisableObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUsableOrNotUsableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a generic object USABLE or NOT_USABLE

CALLED BY:	GLOBAL

PASS:		*DS:SI	= OD of object
		BX	= Flags 
		AX	= Mask to check

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetUsableOrNotUsableObject	proc	near
	uses	ax, cx, dx, bp
	.enter
	
	test	bx, ax
	mov	ax, MSG_GEN_SET_USABLE
	jnz	setStatus
	mov	ax, MSG_GEN_SET_NOT_USABLE
setStatus:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret
SetUsableOrNotUsableObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSUseVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell a generic object to use a new VisMoniker

CALLED BY:	UTILITY

PASS:		*DS:SI	= Generic object
		CX	= Chunk handle of moniker in same object block

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSUseVisMoniker	proc	near
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		ret
SSUseVisMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate the printer's UI

CALLED BY:	UTILITY

PASS:		*DS:SI	= SpoolSummons class
		BX	= JobParameters handle

RETURN:		CX	= Handle of error message from driver
		Carry	= Set if error
			- or -
		Carry	= Clear
		Zero	= Set if no UI

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EvalPrinterUI	proc	near
		uses	ax
		.enter

		mov	ax, DR_PRINT_EVAL_UI
		call	PrinterUICommon

		.leave
		ret
EvalPrinterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffPrinterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the printer's UI

CALLED BY:	UTILITY

PASS:		*DS:SI	= SpoolSummons class
		BX	= JobParameters handle

RETURN:		CX	= Handle of error message from driver
		Carry	= Set if error
			- or -
		Carry	= Clear
		Zero	= Set if no UI

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffPrinterUI	proc	near
		uses	ax
		.enter

		mov	ax, DR_PRINT_STUFF_UI
		call	PrinterUICommon

		.leave
		ret
StuffPrinterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterUICommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the printer driver to evaulate or stuff the UI state

CALLED BY:	UTILITY

PASS:		*DS:SI	= SpoolSummons object
		BX	= JobParameters handle (locked)
		AX	= DR_PRINT_EVAL_UI or DR_PRINT_STUFF_UI

RETURN:		CX	= Handle of error message from driver
		Carry	= Set if error
			- or -
		Carry	= Clear
		Zero	= Set if no UI

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterUICommon	proc	near
	class	SpoolSummonsClass

jobParamHandle	local	hptr 		push	bx
driverFunction	local	word 		push	ax
driverStrategy	local	fptr.far
		
	uses	bx, dx, dx, bp, di, si, es

	.enter
	
	; Load the driver if we need to do any work
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	cx, ds:[di].SSI_currentPrinter

	cmp	cx, -1				; check for no printer available
	je	errNoMessage

	call	AccessPrinterInfoStruct		; PrinterInfoStruct => DS:DI
	test	ds:[di].PIS_info, mask SSPI_UI_IN_DIALOG_BOX or \
				  mask SSPI_UI_IN_OPTIONS_BOX
	jz	done
	mov	dx, cx				; printer # => DX
	call	SpoolLoadDriver			; data => AX, BX, CX, DX
	jc	errNoMessage			; if error, abort
	push	bx
	mov	driverStrategy.segment, dx
	mov	driverStrategy.offset, cx

	; Set up for call to the print driver, if necessary
	;
	mov	bx, ss:[jobParamHandle]
	call	MemDerefES
	clr	si				; JobParameters => ES:SI
	mov	cx, ds:[di].PIS_mainUI.handle
	mov	dx, ds:[di].PIS_optionsUI.handle
	mov	di, ss:[driverFunction]
	cmp	di, DR_PRINT_STUFF_UI
	jne	callDriver			; if stuffing, don't adjust
	clr	cx				; ...state of main UI
callDriver:
	xchg	ax, bx				; swap PState &
						; JobParameters handles
	call	ss:[driverStrategy]

	;
	; According to my limited understanding of things, the printer
	; driver might have reallocated the JobParameters block, and
	; thus:
	;
EC <	mov	ax, NULL_SEGMENT					>
EC <	mov	es, ax							>
		
	; We're done. Free up all resources
	;
	lahf
	and	ah, not (mask CPU_ZERO)		; clear the Z flag
	sahf
	pop	ax				; driver handle => AX
	pushf					; save carry result
	call	MemFree				; free the PState
	mov_tr	bx, ax				; printer-driver handle => BX
	call	SpoolFreeDriver			; free the driver
	popf					; restore carry result
done:
	.leave
	ret

errNoMessage:
	clr	cx		; indicate no error string
	stc
	jmp	done
PrinterUICommon	endp

SpoolSummonsCode	ends
