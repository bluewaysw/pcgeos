COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiControl.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92	Initial version.

DESCRIPTION:
	Common procedures for UI controllers

	$Id: uiControl.asm,v 1.1 97/04/04 17:47:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDupInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the controller's DupInfo table

CALLED BY:

PASS:		cx:dx - location to copy table to
		ds:si - source of table

RETURN:		nothing 

DESTROYED:	cx,ds,si,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDupInfoCommon	proc far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	MovMem	<size GenControlBuildInfo>
	ret
CopyDupInfoCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data block where the children live

CALLED BY:

PASS:		*ds:si - GenControl object

RETURN:		bx - child block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlock	proc near	
	uses	ax
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	bx, ds:[bx].TGCI_childBlock

	.leave
	ret
GetChildBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetItemGroupSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an exclusive item group's setting

CALLED BY:	chart controller code

PASS:		cx - list data to set.
		^lbx:si - list object to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetItemGroupSelection	proc	near	
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageSend
	.leave
	ret

SetItemGroupSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the object not usable

CALLED BY:

PASS:		^lbx:si - object to set not usable
		dl - VisUpdateMode

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjNotUsable	proc near	
	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessageSend
	.leave
	ret
SetObjNotUsable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		^lbx:si - object to set
		dl - VisUpdateMode

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjUsable	proc near	
	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_GEN_SET_USABLE
	call	ObjMessageSend
	.leave
	ret
SetObjUsable	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBooleanGroupState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the boolean group's state

CALLED BY:

PASS:		^lbx:si - object to set
		cx - selected booleans
		dx - indeterminate booleans

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBooleanGroupState	proc near	
	uses ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageSend
	.leave
	ret
SetBooleanGroupState	endp


ObjMessageSend	proc	near	
	uses di
	.enter
	clr	di
	call	ObjMessage
	.leave
	ret
ObjMessageSend	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartControlSetFlagsFromBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert some flags from those sent out from a
		BooleanGroup to a SET/CLEAR form

CALLED BY:	chart controllers

PASS:		cl - bits that are SET
		bp - bits that have changed

RETURN:		cl - bits to SET
		ch - bits to CLEAR

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartControlSetFlagsFromBoolean	proc near
	.enter

	;
	; Determine which bits to SET, and which to CLEAR (XXX:
	; Doesn't take indeterminates into account)
	;

	mov	al, cl
	and	cx, bp			; cl - bits to SET
	not	al
	and	ax, bp
	mov	ch, al			; ch - bits to CLEAR


	.leave
	ret
ChartControlSetFlagsFromBoolean	endp

