COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	User Interface
MODULE:		InterApplication Communication Protocol
FILE:		iacpManager.asm

AUTHOR:		Adam de Boor, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/12/92	Initial revision


DESCRIPTION:
	Inter-Application Communication Protocol manager
		

	$Id: iacpManager.asm,v 1.1 97/04/07 11:47:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		uiGeode.def

include 	initfile.def
include		lmem.def
include		sem.def		; for genUtils.asm  (UserDoDialog)
include		system.def
include		thread.def
include		file.def
include		fileEnum.def
include		Internal/heapInt.def	; for TPD_dataAX
include		assert.def
UseLib		mailbox.def

DefLib		iacp.def

;------------------------------------------------------------------------------
;	Include definitions for this module.
;------------------------------------------------------------------------------

include		iacpConstant.def
include		iacpVariable.def

;------------------------------------------------------------------------------
;	Include code
;------------------------------------------------------------------------------

include		iacpConnect.asm
include		iacpMain.asm
include		iacpUtils.asm
include		iacpC.asm
include		iacpEC.asm
