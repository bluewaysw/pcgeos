COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Studio
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the user interface definition for the
	Studio application.

	$Id: uiManager.asm,v 1.1 97/04/04 14:40:01 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include studioGeode.def
UseLib  spell.def
include studioConstant.def
include studioDocument.def
include studioApplication.def
include studioProcess.def
include studioDisplay.def
include studioGrObjHead.def
include studioControl.def

include gstring.def

UseLib Objects/styles.def
UseLib Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

idata	segment
	StudioLocalPageNameControlClass
idata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include UI/uiPageName.asm
