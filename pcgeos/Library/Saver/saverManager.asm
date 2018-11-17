COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverManager.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	
		

	$Id: saverManager.asm,v 1.1 97/04/07 10:44:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include	stdapp.def
include library.def
include thread.def
include backgrnd.def
include timer.def
include Objects/inputC.def
include	Objects/vTextC.def
include initfile.def

include	saverConstant.def

UseLib	net.def
UseLib	Internal/im.def

DefLib	saver.def


include	saver.rdef

include saverApplication.asm
include saverBitmap.asm
include	saverCrypt.asm
include saverFades.asm
include saverInput.asm
include	saverPassword.asm
include saverRandom.asm
include saverStrings.asm
include saverUtils.asm
include saverVector.asm
include saverC.asm
