COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/30/92   	Initial version.

DESCRIPTION:
	

	$Id: prefManager.asm,v 1.1 97/04/04 17:50:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef	TOC_ONLY
include configGeode.def 

include	prefConstant.def
include prefVariable.def

include prefTimeDateControl.rdef

PrefCode	segment	resource

include prefBooleanGroup.asm
include prefClass.asm
include prefDialog.asm
include prefDynamicList.asm
include prefIniDynamicList.asm
include prefInitFile.asm
include prefInteraction.asm
include prefItemGroup.asm
include prefPortItem.asm
include	prefStringItem.asm
include prefTocList.asm
include prefUtils.asm
include prefValue.asm
include prefTrigger.asm
include prefVideo.asm

if ERROR_CHECK
include	prefEC.asm
endif

PrefCode	ends

PrefUncommon	segment	resource

include prefTitledGlyph.asm
include prefContainer.asm
include	prefControl.asm
include	prefTimeDateControl.asm
include prefText.asm
include prefColorSelector.asm

PrefUncommon	ends
endif
