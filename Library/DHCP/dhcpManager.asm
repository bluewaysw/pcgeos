COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		dhcpManager.asm

AUTHOR:		Eric Weber, Jun 28, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/28/95   	Initial revision


DESCRIPTION:
	
		

	$Id: dhcpManager.asm,v 1.1 97/04/04 17:53:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;                          System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include system.def
include library.def
include driver.def
include sem.def
include object.def
include timer.def
include timedate.def
include assert.def
include initfile.def
include thread.def
include medium.def
include sockmisc.def

include Internal/semInt.def
include Internal/heapInt.def

;-----------------------------------------------------------------------------
;                          System Libraries
;-----------------------------------------------------------------------------
UseLib  ui.def
UseLib	sac.def
UseLib	socket.def
UseLib	accpnt.def
UseLib  Internal/netutils.def

;-----------------------------------------------------------------------------
;                        Library Declaration
;-----------------------------------------------------------------------------
DefLib	dhcp.def

;-----------------------------------------------------------------------------
;                        Internal def files
;-----------------------------------------------------------------------------

include	dhcpConstant.def
include dhcpMacro.def

;-----------------------------------------------------------------------------
;			Code files
;-----------------------------------------------------------------------------

include	dhcpMain.asm
include	dhcpUtils.asm
