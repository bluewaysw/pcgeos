COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiManager.asm

AUTHOR:		Adam de Boor, May  9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/94		Initial revision


DESCRIPTION:
	
		

	$Id: uiManager.asm,v 1.1 97/04/05 01:19:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def
include uiConstant.def
include uiMacro.def

include win.def
include Internal/grWinInt.def
include Internal/window.def
include	timer.def
include	timedate.def
include system.def
include	Mailbox/vmtree.def
include	Mailbox/filedd.def
include	Objects/vTextC.def
include	Internal/patch.def
include	Internal/fontDr.def
include Internal/threadIn.def

UseLib	spool.def
UseLib	Internal/spoolInt.def

DefLib	Mailbox/trItem.def
include	initfile.def
include thread.def
include	Internal/heapInt.def

.warn -private
include	uiMain.rdef
.warn @private

include uiVariable.def

include	uiSendControl.asm
include uiSendDialog.asm
include	uiAddressControl.asm
include	uiApplication.asm
include	uiStrings.asm
include uiEMOM.asm
include	uiPoofDialog.asm
include uiSpoolAddress.asm
include uiProgressBox.asm
include uiProgressGauge.asm
include uiC.asm
include uiOutboxControl.asm
