COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver	
FILE:		modemManager.asm

AUTHOR:		Jennifer Wu, Mar 14, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/95		Initial revision

DESCRIPTION:
	Include files for modem driver

	$Id: modemManager.asm,v 1.1 97/04/18 11:47:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;			Include Files
;---------------------------------------------------------------------------

include geos.def
include	geode.def
include	resource.def
include timer.def
include heap.def
include localize.def
include system.def
include sem.def
include char.def
include file.def
include initfile.def
include driver.def
include thread.def
ifdef HANGUP_LOG
include timedate.def
endif

include	ec.def
include assert.def

include Internal/heapInt.def
include	Internal/im.def
include	Objects/processC.def


DefDriver Internal/modemDr.def

include modem.def

;---------------------------------------------------------------------------
;			Source files for driver
;---------------------------------------------------------------------------

include modemStrategy.asm
include modemAdmin.asm
include modemSend.asm
include modemParse.asm

if ERROR_CHECK
include modemEC.asm				
endif

