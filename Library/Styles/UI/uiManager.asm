COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Styles Library
FILE:		UI/uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:

	$Id: uiManager.asm,v 1.1 97/04/07 11:15:20 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include stylesGeode.def

include gstring.def
include Objects/gCtrlC.def

DefLib Objects/styles.def

include Internal/prodFeatures.def

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiStyleSheet.asm

