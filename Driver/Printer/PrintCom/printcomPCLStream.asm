COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomPCLStream.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/18/92		Initial revision


DESCRIPTION:
	This file contains some common routine to read from/write to the
	stream for PCL printers.

	$Id: printcomPCLStream.asm,v 1.1 97/04/18 11:50:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Stream/streamWrite.asm
include	Stream/streamWriteByte.asm
include	Stream/streamSendCodeOut.asm
include	Stream/streamHexToASCII.asm
include	Stream/streamPCLCommand.asm
