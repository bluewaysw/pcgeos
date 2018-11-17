COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox-Specific Functions
FILE:		outboxManager.asm

AUTHOR:		Adam de Boor, May 9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/9/94		Initial revision


DESCRIPTION:
		

	$Id: outboxManager.asm,v 1.1 97/04/05 01:21:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include		timedate.def
include		thread.def
include		timer.def
include		sysstats.def
include		sem.def
include		Internal/heapInt.def	; for messing with TPD_stackBot (yech)


UseDriver	Internal/mbTrnsDr.def
UseDriver	Internal/mbDataDr.def
UseLib		Objects/vTextC.def

include	outboxConstant.def
include	outboxVariable.def

include	outboxConfirmation.asm
include outboxControlMessageList.asm
include	outboxControlPanel.asm
include	outboxDetails.asm
include	outboxInit.asm
include outboxMedia.asm
include	outboxMessageList.asm
include	outboxNotify.asm
include	outboxPoofMenu.asm
include	outboxProgress.asm
include	outboxReason.asm
include	outboxRegister.asm
include	outboxSendableConfirmation.asm
include	outboxThread.asm
include	outboxTransmit.asm
include	outboxTransmitQ.asm
include outboxTransportList.asm
include outboxTransportMenu.asm
include outboxTransportMonikerSource.asm
include	outboxTransWin.asm
include	outboxUtils.asm
include	outboxErrorRetry.asm
include outboxC.asm
include outboxFeedbackNote.asm
include outboxFeedbackGlyph.asm
