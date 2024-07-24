COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	NewBASIC
MODULE:		Print
FILE:		printMaster.asm

AUTHOR:		Martin Turon, Jul 7, 1998

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1998/7/7	Initial revision


DESCRIPTION:
	Code for Dealing with GadgetClass
		

	$Id: printManager.asm,v 1.1 98/07/12 05:03:25 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	printInternal.def

idata	segment
PrintControlComponentClass
idata	ends
	
PrintMastCode	segment	Resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform operations that need to happen only once and before
		anything else happens.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1998/5/29	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defaultPrintJobName	TCHAR	"BASIC Gadget", C_NULL

PrintControlComponentInitialize	method dynamic PrintControlComponentClass, 
					MSG_ENT_INITIALIZE

		uses	ax, cx, dx, bp
		.enter
		mov	di, offset PrintControlComponentClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE
		call	ObjCallInstanceNoLock	; cx:dx = default doc size 
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
		call	ObjCallInstanceNoLock

		mov	cx, 1
		mov	dx, 1		; cx:dx = default page count
		mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
		call	ObjCallInstanceNoLock

		mov	cx, cs
		mov	dx, offset defaultPrintJobName
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
		call	ObjCallInstanceNoLock

		.leave
		ret
PrintControlComponentInitialize	endm


PrintMastCode	ends
