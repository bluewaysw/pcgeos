COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		Article/articleManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the text class for the
	Studio application.

	$Id: articleManager.asm,v 1.1 97/04/04 14:38:29 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include studioGeode.def
include studioConstant.def
include studioDocument.def

UseLib Objects/styles.def
UseLib Objects/vTextC.def

include studioArticle.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include articleArticle.asm
