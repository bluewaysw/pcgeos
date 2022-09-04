COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain (common code for specific ui's)
FILE:		cmainUtils.asm

ROUTINES:
	Name				Description
	----				-----------
GLB	OpenDispatchPassiveButton	Translate a MSG_PASSIVE_BUTTON
GLB	OLResidentProcessGenChildren	apply callback routine to generic kids
GLB	OLResidentProcessGenChildrenFromDI
GLB	OLResidentProcessGenChildrenClrRegs
GLB	OLResidentProcessVisChildren	apply callback routine to visible kids

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		additional documentation, Motif extensions
	Doug	9/26/89		Updated documentation

DESCRIPTION:
	General purpose specific UI utility routines, available to any routine
	or method in the specific UI library.

 	$Id: cmainUtils.asm,v 2.12 94/11/10 15:24:54 adam Exp $

-------------------------------------------------------------------------------@

Resident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfKeyboardRequired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfKeyboardRequired	proc	far	uses	ax
	.enter
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_NO_KEYBOARD
	jnz	required
	push	ds
	mov	ax, segment kbdRequired
	mov	ds, ax
	tst_clc	ds:[kbdRequired]
	pop	ds
	jz	exit
required:
	stc
exit:
	.leave
	ret
CheckIfKeyboardRequired	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenDispatchPassiveButton

DESCRIPTION:	Dispatch a MSG_PASSIVE_BUTTON by sending out the generic
		method to the object passed

CALLED BY:	GLOBAL

PASS:
	*ds:si - object to send translation to
	ax, cx, dx, bp - MSG_PASSIVE_BUTTON data

RETURN:
	none

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

OpenDispatchPassiveButton	proc	far
	call	FlowTranslatePassiveButton
	GOTO	ObjCallInstanceNoLock

OpenDispatchPassiveButton	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertKeyToMethod

DESCRIPTION:	This procedure performs a table lookup on the passed key
		and passed table of shortcuts&methods, and returns the
		appropriate method if any.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		es:di	= table of shortcuts&methods (see below)
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		cx, dx, bp = same
		if does finds shortcut in table:
			carry set
			ax = method
			di = offset into table (can be used to decide which
				category a shortcut falls into)

		else (does not find)
			carry clear

DESTROYED:	ax, bx, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version (from John's CallKeyBinding)

------------------------------------------------------------------------------@

ConvertKeyToMethod	proc	far
	;get size of table and save for after look-up

	push	ds, cx, dx, bp, si
	segmov	ds, es			;set ds:si = table
	mov	si, di
	lodsw				;ax = # of entries in table
	mov	bx, ax			;Save # of entries in bx.
	mov	di, si			;Save ptr to table start in di.
	call	FlowCheckKbdShortcut	;search table
	jnc	done			;skip to end if not found...

	shl	bx, 1			;bx <- size of shortcut table.
	push	si			;save offset for below
	add	si, bx			;si = offset to method value
	add	si, di			;es:si <- pointer into method list.
	mov	ax, ds:[si]
	pop	di			;return offset in di
	stc				;return flag: found in table

done:
	pop	ds, cx, dx, bp, si	;Restore instance.
	ret
ConvertKeyToMethod	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLResidentProcessGenChildren
FUNCTION:	OLResidentProcessGenChildrenFromDI
FUNCTION:	OLResidentProcessGenChildrenClrRegs

DESCRIPTION:	These utility routines are called by objects
		in the specific UI which need to process all of 
		their generic children.

		OLResidentProcessGenChildrenFromDI
			- starts with child DI (0 means first)

		OLResidentProcessGenChildrenClrRegs
			-clears ax, cx, dx, bp before calling

		*REMEMBER: THIS ROUTINE MUST STAY INSIDE THE Resident RESOURCE,
		because that is where all of the callback routines are located.
		Also, if this were moved out of resident, we could not pass
		bx without wasting lots of time.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		bx	= offset to callback routine, in Resident segment
		ax, cx, dx, bp = data to pass

RETURN:		ax, cx, dx, bp, carry flag = return data

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

.assert (@CurSeg eq Resident)

OLResidentProcessGenChildrenClrRegs	proc	far
	mov	ax, 0			;faster than "clr ax", etc.
	mov	cx, ax
	mov	dx, ax
	mov	bp, ax
	FALL_THRU	OLResidentProcessGenChildren
OLResidentProcessGenChildrenClrRegs	endp

OLResidentProcessGenChildren	proc	far
	clr	di			;start with first child
	FALL_THRU	OLResidentProcessGenChildrenFromDI
OLResidentProcessGenChildren	endp

OLResidentProcessGenChildrenFromDI	proc	far
	push	cs:[ZeroFromHell]	;push a 0
	push	di			;push starting child #

	mov	di, offset GI_link
	push	di			;push offset to LinkPart

	push	cs			;push call-back routine
	push	bx

	mov	bx, offset Gen_offset		; Use the generic linkage
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		; Go process the children
						;(DO NOT use GOTO!)
	ret
OLResidentProcessGenChildrenFromDI	endp

ZeroFromHell	label	word
	dw	0		;I bet Microsoft couldn't do this!


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLResidentProcessVisChildren

DESCRIPTION:	These utility routines are called by objects
		in the specific UI which need to process all of 
		their generic children.

		*REMEMBER: THIS ROUTINE MUST STAY INSIDE THE Resident RESOURCE,
		because that is where all of the callback routines are located.
		Also, if this were moved out of resident, we could not pass
		bx without wasting lots of time.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		bx	= offset to callback routine, in Resident segment
		ax, cx, dx, bp = data to pass

RETURN:		ax, cx, dx, bp, carry flag = return data

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

.assert (@CurSeg eq Resident)

OLResidentProcessVisChildren	proc	far
	clr	di			;start with first child
	push	di			;
	push	di			;push starting child #

	mov	di, offset VI_link
	push	di			;push offset to LinkPart

	push	cs			;push call-back routine
	push	bx

	mov	bx, offset Vis_offset		; Use the generic linkage
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren		; Go process the children
						;(DO NOT use GOTO!)
	ret
OLResidentProcessVisChildren	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBroadcastForDefaultFocus_callBack

DESCRIPTION:	Call back routine supplied by OpenWinStartBroadcastForDefFocus

CALLED BY:	ObjCompProcessChildren (as call-back)

PASS:		*ds:si	= child
		*es:di	= composite
		ax	= MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS
		cx, dx, bp = OD and info about other objects in window which
				have HINT_DEFAULT_FOCUS if any.

RETURN:		carry clear (to continue broadcast)
		cx, dx, bp = OD and info on this object (or child) if it
			has hint

DESTROYED:	ax, bx, di, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		Initial version

------------------------------------------------------------------------------@

.assert (@CurSeg eq Resident)

OLBroadcastForDefaultFocus_callBack	proc	far
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

EC <	call	VisCheckVisAssumption	; Make sure vis data exists >

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	done			;skip if not...

	;send broadcast method to this object. Will send on to kids if any

	push	ax			;save method
	call	ObjCallInstanceNoLockES
	pop	ax

done:
	clc				;continue broadcast
	ret
OLBroadcastForDefaultFocus_callBack	endp

Resident ends
