COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file assembles the User/ module of the UserInterface.

	$Id: userManager.asm,v 1.1 97/04/07 11:45:51 newdeal Exp $

------------------------------------------------------------------------------@

_User		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		uiGeode.def

include		sem.def		; for genUtils.asm  (UserDoDialog)

include		timer.def
include		timedate.def
include 	initfile.def
include		system.def
include		thread.def
include		disk.def	;required by FlowSendFileChange
include		char.def	;required by keyboardMap.def
include		gcnlist.def
include		dbase.def

include		Internal/log.def
include		Internal/fileInt.def
include		Internal/diskInt.def	; for UserLoadApplication
include		Internal/kbdMap.def
include		Internal/geodeStr.def
include		Internal/grWinInt.def
include		Internal/heapInt.def
include		Internal/specUI.def
include		Internal/objInt.def	; for ObjAssocVMFile, ObjDisassocVMFile
include		Internal/harrint.def	; for Remote Clipboard Xfer

include		Internal/heapInt.def	; for TPD_stackBot used in UserDoDialog

UseDriver 	Internal/kbdDr.def
UseDriver	Internal/mouseDr.def
UseDriver	Internal/videoDr.def
UseDriver	Internal/taskDr.def
UseDriver	Internal/powerDr.def

UseLib		net.def
UseLib		wav.def

	DecodeProtocol

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

AUTO_BUSY	=	0		; Abandoned until further notice
include		userMacro.def
include		userConstant.def
include		userVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include		userManager.rdef

include		userLibrary.asm
include		userMain.asm
include		userScreen.asm
include		userUtils.asm
include		userDialog.asm

; UserTransferClass files
;
include		userTransfer.asm
include		userQuick.asm

; FlowClass files
;
include		userFlow.asm
include		userFlowGrabLow.asm
include		userFlowInput.asm
include		userFlowMisc.asm
include		userFlowUtils.asm
include		userListUtils.asm
include		userStrings.asm

; Title screen
;
;include	userTitleScreen.asm

;
; C stubs
;
include		userC.asm

;
; Save 10 most recently opened doc
;
include		userDocumentSave.asm
end

