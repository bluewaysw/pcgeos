COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		Article/articleManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the text class for the
	GeoWrite application.

	$Id: articleManager.asm,v 1.1 97/04/04 15:57:13 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include writeGeode.def
include writeConstant.def
include writeDocument.def

UseLib Objects/styles.def
UseLib Objects/vTextC.def

include writeArticle.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include articleArticle.asm
