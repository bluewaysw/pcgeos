COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiManager.asm
FILE:		uiManager.asm

AUTHOR:		Gene Anderson, May 11, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/11/92		Initial revision

DESCRIPTION:
	

	$Id: uiManager.asm,v 1.1 97/04/07 11:12:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	spreadsheetGeode.def
include Objects/SSheet/sCtrlC.def

include uiConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include uiManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include uiUtils.asm
include uiEditBar.asm
include uiSort.asm
include uiChooseFunction.asm
include uiDefineName.asm
include uiChooseName.asm
include uiWidth.asm
include uiHeight.asm
include uiEdit.asm
include uiHeader.asm
include uiBorder.asm
include uiBorderColor.asm
include uiRecalc.asm
include uiOptions.asm
include uiNotes.asm
include uiFill.asm
include uiChart.asm
