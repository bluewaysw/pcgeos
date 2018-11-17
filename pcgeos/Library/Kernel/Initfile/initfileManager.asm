COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Initfile
FILE:		initfileManager.asm

AUTHOR:		Cheng, Nov 22, 1989

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial revision

DESCRIPTION:
	This file assembles the Initfile module of the Kernel Library
		

	$Id: initfileManager.asm,v 1.1 97/04/05 01:17:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include graphics.def
include	sem.def
include	char.def
include localize.def
include	input.def
include	timedate.def
include	initfile.def
include	lmem.def
include Internal/geodeStr.def		;includes: geode.def
include Internal/dos.def
include Internal/interrup.def
include Internal/initInt.def

;--------------------------------------
include	chunkarr.def
include initfileConstant.def	;BOOT constants
include initfileVariable.def	;sets up its own segments
;-------------------------------------

include		initfileHigh.asm
include		initfileConstruct.asm
include		initfileLow.asm
include		initfileEC.asm
include		initfileHash.asm

include		initfileC.asm

end








