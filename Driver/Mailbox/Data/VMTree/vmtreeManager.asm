COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeManager.asm

AUTHOR:		Chung Liu, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 3/94   	Initial revision


DESCRIPTION:
	
		

	$Id: vmtreeManager.asm,v 1.1 97/04/18 11:41:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include lmem.def
include driver.def
include system.def
include file.def
include drive.def
include disk.def
include	assert.def
include	dbase.def
include Internal/harrint.def		;for FixupHugeArrayChain
include hugearr.def

UseLib ui.def
UseLib mailbox.def
DefDriver Internal/mbDataDr.def

include Mailbox/vmtree.def
include vmtreeConstant.def
include vmtreeVariable.def

include vmtreeStack.asm
include vmtreeEntry.asm
include vmtreeCode.asm
include vmtreeRead.asm
include vmtreeWrite.asm
include vmtreeUtils.asm




