COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Localize/Document
FILE:		documentManager.asm

AUTHOR:		Cassie Hartzog, Sep 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/25/92		Initial revision


DESCRIPTION:
	
	This file includes all the other document code files.

	$Id: documentManager.asm,v 1.1 97/04/04 17:14:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;------------------------------------------------------------------------------
;                       Common GEODE stuff
;------------------------------------------------------------------------------

include	localizeGeode.def
include	localizeConstant.def
include	localizeGlobal.def
include	localizeMacro.def
include	localizeErrors.def
include	localizeDocument.def
include	localizeContent.def
include	localizeText.def
include	localizeLoc.def
include localizeProcess.def

include input.def
include	Objects/inputC.def
include graphics.def
include gstring.def
include Internal/videoDr.def		; for EditableBitmap definition
include localize.def

;------------------------------------------------------------------------------
;                       Idata
;------------------------------------------------------------------------------

idata	segment
	ResEditDocumentClass
	ResEditContentClass
	ResEditGenDocumentControlClass
if	not DBCS_PCGEOS
	ResEditFileSelectorClass
	ResEditImpTextClass
endif	; not DBCS_PCGEOS
idata	ends

;------------------------------------------------------------------------------
;                       Code
;------------------------------------------------------------------------------


if	not DBCS_PCGEOS
include	documentImpExp.asm
endif	; not DBCS_PCGEOS
include documentPatch.asm
include	documentOpenClose.asm

include documentPath.asm
include	documentSourceView.asm
include	documentTransView.asm
include	documentDB.asm
include	documentList.asm
include documentParse.asm
include documentResource.asm
include documentUpdate.asm
include documentBuild.asm
include	documentMisc.asm
include	documentMnemonic.asm
include	documentSearch.asm
include	documentClipboard.asm
include	documentUtilities.asm
include	documentKeyboard.asm
include documentInitfile.asm
include documentPrint.asm
include documentCount.asm
include	documentDraw.asm
