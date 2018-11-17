COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Inbox-Specific Functions
FILE:		inboxManager.asm

AUTHOR:		Adam de Boor, May 9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/9/94		Initial revision


DESCRIPTION:
		

	$Id: inboxManager.asm,v 1.1 97/04/05 01:20:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include	Internal/geodeStr.def
include thread.def
include file.def
include fileEnum.def
include	Objects/vTextC.def
include	system.def
include	initfile.def
include	timer.def


include	inboxConstant.def
include	inboxVariable.def

include inboxApplicationList.asm
include inboxAppToken.asm
include inboxControlPanel.asm
include inboxDetails.asm
include	inboxInit.asm
include inboxMessageList.asm
include inboxRegister.asm
include inboxFetch.asm
include	inboxTransWin.asm
include	inboxUtils.asm
