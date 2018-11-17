COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcBuildVariableArgsPCF.asm

AUTHOR:		Christian Puscasiu, May  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 5/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	builds the avriable args PCF
		

  $Id: bigcalcBuildVariableArgsPCF.asm,v 1.1 97/04/04 14:37:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

CalcCode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VaribleArgsInitInstData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initializes the PCF's instance data

CALLED BY:	
PASS:		*ds:si	= VariableArgsPCFClass object
		ds:di	= VariableArgsPCFClass instance data
		ds:bx	= VariableArgsPCFClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		bp	updated
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VaribleArgsInitInstData	method dynamic VariableArgsPCFClass, 
					MSG_PCF_INIT_INST_DATA
	uses	ax, cx, dx
	.enter

	;
	; lock the data
	;
	call	BigCalcLockDataResource
	push	bx

	;
	; dereference the chunk handle
	;
	mov	bp, dx
	mov	bp, es:[bp]

	;
	; first thing is the type which we know is PCFT_VARIABLE_ARGS
	;
	mov	{byte} ds:[di].PCFI_type, PCFT_VARIABLE_ARGS
	inc	bp

	;
	; then the output format
	;
	mov	al, es:[bp]
	inc	bp
	mov	ds:[di].PCFI_resultFormat, al

	mov	ax, es:[bp]
	add	bp, 2
	mov	ds:[di].PCFI_ID, ax

	mov	al, es:[bp]
	inc	bp
	mov	ds:[di].VAPI_minimumNumberArgs, al

	;
	; then is the formula
	;
	mov	bx, es:[bp]
	add	bp, 2
	mov	di, offset GenericVAPCFFormula
	call	PreCannedFunctionInitFormula

	;
	; save pointer to init data
	;
	push	bp

	;
	; now the moniker, dereference the chunk handle of the moniker
	; and put the far ptr in cx:dx
	;
	mov	cx, es
	mov	bp, es:[bp]
	mov	dx, es:[bp]

	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	ObjCallInstanceNoLock

;	mov	cx, ds:[LMBH_handle]
;	mov	dx, offset GenericVAPCFInputNumber
;	mov	si, offset GenericVAPCFGetFromCalcButton
;	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
;	call	ObjCallInstanceNoLock 

	mov	cx, ds:[LMBH_handle]
	mov	dx, offset GenericVAPCFItemGroup
	mov	si, offset GenericVAPCFResetButton
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	call	ObjCallInstanceNoLock
	
	; restore bp and update
	pop	bp
	inc	bp
	inc	bp

	push	bp

	mov	bp, es:[bp]
	mov	dx, es:[bp]
	mov	cx, es

	;
	; set the result text 
	;
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset GenericVAPCFCommon
	call	ObjCallInstanceNoLock

	pop	bp
	inc	bp
	inc	bp

	;
	; now the description
	;
	mov	bp, es:[bp]
	mov	bp, es:[bp]
	mov	dx, es
	clr	cx
	mov	si, offset GenericVAPCFNotes
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock 

	pop	bx
	call	MemUnlock

	.leave
	ret
VaribleArgsInitInstData	endm


CalcCode	ends
