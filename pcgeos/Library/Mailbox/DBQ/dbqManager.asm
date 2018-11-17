COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		DBGroupAndItem Queue
FILE:		dbqManager.asm

AUTHOR:		Adam de Boor, Apr 7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/7/94		Initial revision


DESCRIPTION:
	DBGroupAndItem queue implementation.
		
	Each item stored in a queue has a reference count associated with it.
	When an item is allocated, its reference count begins at 1. When it
	is added to a queue, its reference count is incremented. When someone
	calls DBQGetItem, its reference count is incremented. When someone
	calls DBQDoneWithItem, DBQRemove, or DBQFree, its reference count
	is decremented. When the count reaches 0, the appropriate routine
	is called and the item is freed.

	$Id: dbqManager.asm,v 1.1 97/04/05 01:19:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def
include hugearr.def

include	dbqConstant.def

include	dbqCode.asm
include dbqEC.asm
