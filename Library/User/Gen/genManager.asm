COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the Gen/ module of the UserInterface.

	$Id: genManager.asm,v 1.1 97/04/07 11:44:59 newdeal Exp $

------------------------------------------------------------------------------@

_Gen		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		uiGeode.def

include		sem.def	; for genUtils.asm  (UserDoDialog)
include		graphics.def
include		chunkarr.def
include		initfile.def
include		disk.def
UseLib		mailbox.def

DefLib		iacp.def

include		Internal/specUI.def
include		Internal/geodeStr.def
include		Internal/grWinInt.def	; for genUtils.asm (WinForEach)
include		Internal/window.def	; for GeodeWinFlags (genField.asm)
include		Internal/diskInt.def	; for genPathUtils.asm
include		Internal/objInt.def	; for genApplication.asm (ObjRetrieve..)
include		Internal/heapInt.def	; for genAppMisc.asm (GenApplicationGCNListSend)
include 	Internal/patch.def	; for MULTI_LANGUAGE stuff


UseDriver	Internal/videoDr.def
UseDriver	Internal/powerDr.def	; for GenFieldCheckIfExitPermitted

include		Objects/vTextC.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		genMacro.def
include		genConstant.def
include		genVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		genClassMisc.asm
include		genClassCommon.asm
include		genClassBuild.asm

include		genUtils.asm
include		genGlyphDisplay.asm
include		genTrigger.asm
include		genInteraction.asm
include		genTextEdit.asm
include		genView.asm
include		genContent.asm
include		genDisplay.asm
include		genDisplayControl.asm
include		genPrimary.asm
include		genActive.asm

include		genAppMisc.asm
include		genAppAttDet.asm
include		genAppCommonIACP.asm

include		genField.asm
include		genScreen.asm
include		genSystem.asm
include		genGadget.asm
include		genUIDocumentControl.asm
include		genAppDocumentControl.asm
include		genDocument.asm
include		genFileSelector.asm
include		genControl.asm

include		genPathUtils.asm
include		genBooleanGroup.asm
include		genItemGroup.asm
include		genDynamicList.asm
include		genItem.asm
include		genBoolean.asm
include		genValue.asm
include		genToolGroup.asm
include		genPenInputControl.asm

;
; C stubs
;
include		genC.asm

end
