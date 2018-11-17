COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		bigcalcApplication.asm

AUTHOR:		Christian Puscasiu, Mar 23, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	3/23/93   	Initial revision


DESCRIPTION:
	The keyboard accelerator is stored here.
		

	$Id: bigcalcApplication.asm,v 1.1 97/04/04 14:38:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcApplicationAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When running in the CUI, do a few things

CALLED BY:	UI (MSG_META_ATTACH)
	
PASS:		DS:*SI	= BigCalcApplicationClass object
		ES	= Segment of BigCalcApplicationClass
		See docs for MSG_META_ATTACH

RETURN:		See docs for MSG_META_ATTACH

DESTROYED:	See docs for MSG_META_ATTACH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/7/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcApplicationAttach	method dynamic	BigCalcApplicationClass,
						MSG_META_ATTACH
	;
	; If we are in the CUI, we need to:
	; - set the .INI category to "bigcalc0"
	; - wipe out the View menu
	;
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		jne	callSuper
	;
	; Set the .INI category to something unique, so that changes
	; made in the AUI will not affect the CUI
	;
		push	cx, dx, si, bp
		mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
		mov	cx, 9			;'bigcalc0' + NULL
		call	ObjVarAddData
		mov	{word}ds:[bx+0], 'bi'
		mov	{word}ds:[bx+2], 'gc'
		mov	{word}ds:[bx+4], 'al'
		mov	{word}ds:[bx+6], 'c0'
		clr	{byte}ds:[bx+8]
	;
	; Turn off the Options & Convert menus in the CUI
	;
		mov	bx, handle OptionsMenu
		mov	si, offset OptionsMenu
		call	BigCalcProcessSetNotUsable
		mov	bx, handle ConversionMenu
		mov	si, offset ConversionMenu
		call	BigCalcProcessSetNotUsable
		pop	cx, dx, si, bp
	;
	; Complete the MSG_META_ATTACH
	;
callSuper:
		mov	ax, MSG_META_ATTACH
		mov	di, offset BigCalcApplicationClass
		GOTO	ObjCallSuperNoLock
BigCalcApplicationAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcApplicationOptionsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell superclass that our options have changed only
		if we are not launching the application

CALLED BY:	MSG_GEN_APPLICATION_OPTIONS_CHANGED

PASS:		*ds:si	= BigCalcApplicationClass object
		ds:di	= BigCalcApplicationClass instance data
		es 	= segment of BigCalcApplicationClass
		ax	= message #

RETURN:		Nothing

DESTROYED:	Nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		don     2/07/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigCalcApplicationOptionsChanged	method dynamic BigCalcApplicationClass,
					MSG_GEN_APPLICATION_OPTIONS_CHANGED
		.enter
	;
	; Check to see if we are in the middle of launching the app.
	; If so, just swallow the notification
	;
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	done
		mov	di, offset BigCalcApplicationClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
BigCalcApplicationOptionsChanged	endm

ProcessCode	ends
