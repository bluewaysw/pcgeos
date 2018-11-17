COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Localize/UI
FILE:		uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	9/92		Initial version

DESCRIPTION:
	This file contains the user interface definition for the
	ResEdit application.

	$Id: uiManager.asm,v 1.1 97/04/04 17:13:38 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include localizeGeode.def			; geode declarations
include localizeConstant.def			; structure definitions
include localizeGlobal.def			; global definitions
include localizeMacro.def			; macro definitions
include localizeProcess.def
include localizeDocument.def
include localizeContent.def
include localizeText.def

include graphics.def
include gstring.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

