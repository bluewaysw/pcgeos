COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Body
FILE:		bodyManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: bodyManager.asm,v 1.1 97/04/04 18:07:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include grobjGeode.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------

include bodyConstant.def
;include bodyMacro.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
;include	bodyVariable.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include bodyClass.asm
include	bodyObjArray.asm
include	bodyMouse.asm
include bodyProcessChildren.asm
include	bodyGroup.asm
include bodyUtils.asm
include bodyPriorityList.asm
include	body.asm
include	bodyKeyboard.asm
include	bodySelectionList.asm
include	bodySortableArray.asm
include bodyCutCopyPaste.asm
include bodyAlign.asm
include bodyUI.asm
include bodyAttr.asm
include bodyTransfer.asm
include bodyImpex.asm
include bodyC.asm

if	INCLUDE_TEST_CODE
include	bodyTest.asm
endif
