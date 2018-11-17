COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI
FILE:		uiManager.asm

AUTHOR:		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------


DESCRIPTION:

	$Id: uiManager.asm,v 1.1 97/04/04 16:06:26 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include iconGeode.def

include uiConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

idata	segment
	BMOContentClass
	ColorTriggerClass
	ColorListItemClass
	AddIconInteractionClass
	SmartTextClass
	FormatViewInteractionClass
	StopImportTriggerClass
idata	ends


include uiManager.rdef

;------------------------------------------------------------------------------
;			Included code
;------------------------------------------------------------------------------

include	uiColor.asm
include uiNewClasses.asm
