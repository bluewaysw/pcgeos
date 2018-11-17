COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS	
MODULE:		ResEdit/Main
FILE:		mainManager.asm

AUTHOR:		Cassie Hartzog, Sep 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/25/92		Initial revision


DESCRIPTION:
	
		
	$Id: mainManager.asm,v 1.1 97/04/04 17:13:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;                       Common GEODE stuff
;------------------------------------------------------------------------------

include localizeGeode.def
include localizeConstant.def
include localizeErrors.def
include localizeGlobal.def
include localizeMacro.def
include localizeProcess.def
include localizeDocument.def
include localizeContent.def

include Internal/fileInt.def		; for FileFullAccessFlags
include	Objects/inputC.def		; for MSG_META_KBD_CHAR
include	initfile.def

;------------------------------------------------------------------------------
;                       Code
;------------------------------------------------------------------------------

include mainProcess.asm
include mainList.asm
include mainBatch.asm
