COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatDynamic.asm

AUTHOR:		Don Reeves, February 10, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/10/90		Initial revision


DESCRIPTION:
	Respond to all actions involving the RepeatDynamicList.

	$Id: repeatDynamic.asm,v 1.1 97/04/04 14:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	RDCurrentSelect		word	-1	; the current select item
idata	ends

udata	segment
	repeatChangeIndex	word		; the current index value
	repeatEvents		byte		; true if there are any events
udata	ends



RepeatCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatGetEventMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates & returns a moniker to represent a RepeatEvent

CALLED BY:	UI (MSG_LIST_REQUEST_ENTRY_MONIKER)

PASS:		DS	= DGroup
		CX:DX	= RepeatDynamicList block:handle
		BP	= Entry # of requested moniker 

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatGetEventMoniker	proc	far
	
	; Access the requested RepeatStruct
	;
	mov	si, dx				; GenDynamicList chunk => SI
	mov	ax, ds:[repeatMapGroup]		; get the RepeatMap group #
	mov	di, ds:[repeatMapItem]		; get the RepeatMap item #
	tst	ax				; a repeat map group ??
	jz	emptyMoniker			; no, so display emtpy moniker
	call	GP_DBLockDerefDI		; lock the map
	tst	es:[di].RMH_numItems		; any events ??
	jnz	regularMoniker			; create a regular moniker
	call	DBUnlock			; else unlock RepeatMap

	; Create a "No Repeat Events" moniker
emptyMoniker:
	mov	bx, handle DataBlock		; string resource handle => BX
	call	MemLock				; segment => AX
	mov	es, ax
assume	es:DataBlock
	mov	dx, es:[noRepeats]		; string => ES:DX
assume	es:nothing
	clr	ax				; know what to unlock...
	jmp	sendMoniker			; send of the moniker

	; Access the correct block
regularMoniker:
EC <	cmp	bp, es:[di].RMH_numItems	; check number of items	>
EC <	ERROR_GE	GET_REPEAT_EVENT_MONIKER_BAD_EVENT_NUM		>
	mov	bx, bp				; Entry number => BX
	shl	bx, 1
	shl	bx, 1				; Size RMS = 4 bytes
	add	bx, size RepeatMapHeader	; total offset => BX
EC <	cmp	bx, es:[di].RMH_size					>
EC <	ERROR_GE	GET_REPEAT_EVENT_MONIKER_BAD_SIZE		>
	mov	di, es:[di][bx].RMS_item	; RepeatStruct item => DI
	call	DBUnlock			; Unlock the RepeatMap
	call	GP_DBLockDerefDI		; lock the RepeatStruct
	mov	dx, di				; dereference the handle
	add	dx, offset RES_data		; string => ES:DX

	; Now set the moniker
sendMoniker:
	push	ax				; save clean-up flag
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, es				; string => CX:DX
	call	ObjMessage_repeat_call		; send message to list
	pop	cx				; unlock "boolean" => CX

	; Now clean up and exit. If CX=0, unlock DB block. Else unlock strings.
	;
	jcxz	noRepeatDone			; if none, unlock string block
	call	DBUnlock			; unlock database segment
	jmp	done				; and exit...
noRepeatDone:
	mov	bx, handle DataBlock		; string resource handle => BX
	call	MemUnlock			; unlock the block
done:
	ret
RepeatGetEventMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSelectEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to different RepeatEvents (List Entries) being
		selected, and enabling/disabling the Change & Delete triggers

CALLED BY:	UI (MSG_REPEAT_SELECT_EVENT)

PASS:		DS, ES	= DGroup
		CX	= New entry number

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSelectEvent	proc	far

	; Store the new entry number, and disable/enable the triggers
	;	
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assumme disable triggers
	cmp	ds:[repeatEvents], FALSE	; are there any events??
	je	setState			; if not, do nothing
	mov	bx, cx				; new entry to BX
	xchg	cx, ds:[RDCurrentSelect]	; swap old/new selections
	cmp	bx, -1				; now nothing selected?
	je	setState			; if so, must disable all
	mov	ax, MSG_GEN_SET_ENABLED		; else must enable everything

	; Now set the triggers either enabled or disabled
setState:
	mov	si, offset RepeatBlock:RepeatChangeTrigger
	call	RepeatSetState			; set state of CHANGE trigger
	mov	si, offset RepeatBlock:RepeatDeleteTrigger
	call	RepeatSetState			; set state of DELETE trigger
	ret
RepeatSelectEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatChangeEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to the CHANGE button action

CALLED BY:	UI (MSG_REPEAT_CHANGE_EVENT)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatChangeEvent	proc	far

	; Obtain the current RepeatStruct
	;
	call	RepeatMapIndexToStruct
	mov	ds:[repeatChangeIndex], bx	; store the index value
	GOTO	RepeatChangeEventLow		; open the dialog box
RepeatChangeEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDeleteEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the currently selected RepeatEvent

CALLED BY:	UI (MSG_REPEAT_DELETE_EVENT)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatDeleteEvent	proc	far
	
	; Obtain the correct repeat ID
	;
	call	RepeatMapIndexToStruct
	mov	cx, bx				; repeat ID => CX
	call	RepeatDelete			; remove the sucker

	; Disable the triggers to prevent spurious delete/change requests
	;
	mov	cx, -1				; select the -1th entry
	clr	bp				; pass no flags
	GOTO	RepeatSelectEvent		; send the "method"
RepeatDeleteEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatMapIndexToStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the RepeatStruct corresponding to RDCurrentSelect

CALLED BY:	RepeatChangeEvent, RepeatSelectEvent

PASS:		DS	= DGroup

RETURN:		AX	= Selected RepeatStruct : group #
		DI	= Selected RepeatStruct : item #
		BX	= Selected RepeatStruct : index value

DESTROYED:	BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatMapIndexToStruct	proc	near
	.enter

	; Obtain the current RepeatStruct
	;
	mov	ax, ds:[repeatMapGroup]		; get the RepeatMap group #
	mov	di, ds:[repeatMapItem]		; get the RepeatMap item #
	call	GP_DBLockDerefDI		; lock the map
	mov	bp, ds:[RDCurrentSelect]	; Entry number => BP
	shl	bp, 1
	shl	bp, 1				; Size RMS = 4 bytes
	add	bp, size RepeatMapHeader	; total offset => BP
EC <	cmp	bp, es:[di].RMH_size					>
EC <	ERROR_GE	REPEAT_DYNAMIC_COMMON_BAD_SIZE			>
	mov	bx, es:[di][bp].RMS_indexValue	; Index value => BX
	mov	di, es:[di][bp].RMS_item	; RepeatStruct item => DI
	call	DBUnlock			; Unlock the RepeatMap

	.leave
	ret
RepeatMapIndexToStruct	endp

RepeatCode	ends



CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatGetNumEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the numbers of repeat event entries

CALLED BY:	UTILITY
	
PASS:		DS	= DGroup

RETURN:		CX	= Number of events

DESTROYED:	AX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatGetNumEvents	proc	far
	.enter

EC <	VerifyDGroupDS				; verify DGroup		>
	mov	ax, ds:[repeatMapGroup]		; get the RepeatMap group #
	mov	di, ds:[repeatMapItem]		; get the RepeatMap item #
	tst	ax				; no map group ??
	jz	noEvents
	call	GP_DBLockDerefDI		; lock the map item
	mov	cx, es:[di].RMH_numItems
	call	DBUnlock			; unlock the map item
	mov	ds:[repeatEvents], TRUE		; assume we have some events
	tst	cx				; are there any repeat events?
	jnz	done
noEvents:
	mov	ds:[repeatEvents], FALSE	; no events at all
	mov	cx, 1				; use the "No Event" moniker
done:
	.leave
	ret
RepeatGetNumEvents	endp

CommonCode	ends
