COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Intelligent VM Storage
FILE:		vmstoreManager.asm

AUTHOR:		Adam de Boor, Apr 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/94		Initial revision


DESCRIPTION:
	Functions and structures for tracking multiple VM files among which
	message bodies may be parceled.
		
	$Id: vmstoreManager.asm,v 1.1 97/04/05 01:20:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include system.def

include	vmstoreConstant.def

include vmstoreInit.asm
include	vmstoreCode.asm

include vmstoreC.asm
