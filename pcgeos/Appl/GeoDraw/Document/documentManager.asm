COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentManager.asm

AUTHOR:		Steve Scholl

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl    2/9/92        Initial revision.

DESCRIPTION:
	$Id: documentManager.asm,v 1.1 97/04/04 15:51:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include drawGeode.def
include documentConstant.def
include ../UI/uiConstant.def		; for DrawTemplateWizardClass
include	drawDocument.def
include drawGrObjBody.def
include document12XConversionConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include documentManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include documentBody.asm
include	documentDocument.asm
include	documentConvert.asm
include documentUtils.asm
include documentPrint.asm
include documentDisplay.asm

if      ERROR_CHECK
include documentErrorCheck.asm
endif
