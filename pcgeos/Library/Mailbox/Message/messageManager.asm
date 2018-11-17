COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Message Utilities
FILE:		messageManager.asm

AUTHOR:		Adam de Boor, Apr 21, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/21/94		Initial revision


DESCRIPTION:
	Utility routines for message manipulation.
	
	Functions specific to the inbox or outbox are found in those
	respective modules.

	$Id: messageManager.asm,v 1.1 97/04/05 01:20:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

UseDriver	Internal/mbTrnsDr.def
UseDriver	Internal/mbDataDr.def
UseLib		Objects/vTextC.def
include		timedate.def

include	messageConstant.def
include messageVariable.def

include messageControlPanel.asm
include messageDetails.asm
include messageGlyph.asm
include messageInfo.asm
include messageList.asm
include messageMoniker.asm
include	messageRegister.asm
include	messageSendableNotifyDialog.asm
include messageUtils.asm
include messageC.asm
