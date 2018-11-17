COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE: 	Calculator Accessory -- Manager
FILE:		calc.asm

AUTHOR:		Adam de Boor, Mar 13, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/13/90		Initial revision


DESCRIPTION:
	Main file for calculator application.


	$Id: calcManager.asm,v 1.1 97/04/04 14:47:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	calc.def
include calcVariable.def

include gstring.def
include char.def
include input.def

include Objects/inputC.def

ifdef GCM
	include calc.grdef
else
	include	calc.rdef
endif

; Code resources

include	calcEngine.asm
include	calcMath.asm
include	calcDisplay.asm
include calcProcess.asm
include calcTrigger.asm
