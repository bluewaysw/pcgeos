COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		File Data Driver
FILE:		fileddManager.asm

AUTHOR:		Chung Liu, Oct 11, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/11/94   	Initial revision


DESCRIPTION:
	Hub of the pluralist doctrine, where all get included.
		

	$Id: fileddManager.asm,v 1.1 97/04/18 11:41:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Include files
;

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

UseLib ui.def
UseLib mailbox.def

DefDriver Internal/mbDataDr.def

include Mailbox/filedd.def
include filedd.asm		;just so mkmf won't get confused.
include fileddConstant.def
include fileddVariable.def
include fileddEntry.asm
include fileddRead.asm
include fileddWrite.asm
include fileddCode.asm
include fileddUtils.asm
include fileddBody.asm




