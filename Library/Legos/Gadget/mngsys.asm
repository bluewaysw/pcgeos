COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mngsys.asm

AUTHOR:		RON, Sep 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/27/95   	Initial revision


DESCRIPTION:
	
		
	$Id: mngsys.asm,v 1.1 98/03/11 04:30:38 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include common.def
include Legos/gadget.def
;include	internal/im.def		; for syspower.asm

GadgetSystemCompsCode	segment	resource

include sysbusy.asm
include sysdisp.asm
;include syspen.asm
include	syssound.asm
include syslanch.asm

GadgetSystemCompsCode	ends
