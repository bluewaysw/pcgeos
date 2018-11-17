COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		red64Stream.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/20/92	Initial revision


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream for the Redwood project

	$Id: red64Stream.asm,v 1.1 97/04/18 11:55:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Stream/DMA/dmaDataOutRedwood.asm
include Stream/DMA/dmaWaitTillReady.asm
include	Stream/streamSendCodeOutRedwood.asm
include	Stream/streamGetStatusRedwood.asm
include	Stream/streamStatusPacketInRedwood.asm
include	Stream/streamControlByteOutRedwood.asm
