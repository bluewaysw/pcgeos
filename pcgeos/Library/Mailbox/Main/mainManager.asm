COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainManager.asm

AUTHOR:		Adam de Boor, Jun  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 1/94		Initial revision


DESCRIPTION:
	
		

	$Id: mainManager.asm,v 1.1 97/04/05 01:21:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include system.def
include driver.def
include thread.def

UseDriver	Internal/serialDr.def

include mainVariable.def
include Outbox/outboxConstant.def

include mainLibrary.asm
include mainNotify.asm
include	mainProcess.asm
include mainThread.asm
