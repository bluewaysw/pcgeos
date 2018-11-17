COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Init
FILE:		localInit.asm

AUTHOR:		Gene Anderson, Dec  3, 1990

ROUTINES:
	Name			Description
	----			-----------
	LocalInit		Initialization routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/ 3/90	Initial revision

DESCRIPTION:
	Initialization and Exit routines for localization driver

	$Id: localInit.asm,v 1.1 97/04/05 01:16:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization routine for localization driver
CALLED BY:	LocalStrategy()

PASS:		ds - dgroup
RETURN:		carry - set if error
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 3/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalInit	proc	far	uses ds
	.enter
if	FULL_EXECUTE_IN_PLACE

;	The LocalStrings resource is supposed to be preloaded, but isn't on
;	full-XIP systems, so bring it into memory now (this is done because
;	LockStringsDS does a MemThreadGrab on the block, which fails if
;	the block is discarded).

	mov	bx, handle LocalStrings
	call	MemLock
	call	MemUnlock
endif
	call	DateTimeInitFormats		;do some format initialization
PZ <	call	GengoNameInit			;init for Gengo date format >
PZ <	call	KinsokuCharsInit		;init for kinsoku chars	>
	call	NumericInitFormats		;numeric, printer size init
	call	InitQuotes			;quotes init
	call	InitTimezone			;init timezone info
	clc					;<- indicate no error

	.leave
	ret
LocalInit	endp

ObscureInitExit	ends
