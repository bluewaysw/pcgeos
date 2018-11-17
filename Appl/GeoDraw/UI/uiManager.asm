COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UI
FILE:		uiManager.asm

AUTHOR:		Steve Scholl

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl	2/92        Initial revision.

DESCRIPTION:
	$Id: uiManager.asm,v 1.1 97/04/04 15:51:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include drawGeode.def
UseLib spell.def

include uiConstant.def
include drawDocument.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiDrawApplication.asm
include uiMain.asm
include uiTemplate.asm
include uiGifImage.asm
