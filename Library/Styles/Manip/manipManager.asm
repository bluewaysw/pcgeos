COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code to assemble the Manip module.

	$Id: manipManager.asm,v 1.1 97/04/07 11:15:24 newdeal Exp $

------------------------------------------------------------------------------@


;---------------------------------------------------------------------------
;	Common Geode stuff
;---------------------------------------------------------------------------

include	stylesGeode.def
include	stylesGlobal.def

include	system.def
include vm.def
include thread.def

include Internal/threadIn.def

;---------------------------------------------------------------------------
;	Code
;---------------------------------------------------------------------------

include		manipUtils.asm
include		manipDescribe.asm
include		manipGet.asm
include		manipModify.asm
include		manipDelete.asm
include		manipDefine.asm
include		manipChange.asm
include		manipCopy.asm
include		manipTrans.asm
include		manipSaveRecall.asm

