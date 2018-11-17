COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textSelectManager.asm

AUTHOR:		John Wedgwood, Apr 17, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/17/92	Initial revision

DESCRIPTION:
	Manager file for the TextSelect module.

	$Id: textselectManager.asm,v 1.1 97/04/07 11:20:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textstorage.def
include textssp.def
include textattr.def
include textselect.def
include textregion.def
include texttrans.def
include textline.def
include textundo.def	

include Internal/im.def
ifdef	USE_FEP
include Internal/fepDr.def
endif
include system.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	tslConstant.def

;-----------------------------------------------------------------------------
;	Include variables and tables for this module
;-----------------------------------------------------------------------------

include	tslVariables.asm

include tslMain.asm
include tslMisc.asm
include tslUtils.asm

include tslMethodMouse.asm
include tslMethodSelect.asm
include tslMethodFocus.asm
include tslMethodCursor.asm

include tslInvert.asm
include tslCursor.asm
include tslKbdShortcuts.asm
