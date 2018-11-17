COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomHex0Stream.asm

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
	stream

	$Id: printcomHex0Stream.asm,v 1.1 97/04/18 11:50:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Stream/streamWrite.asm
include	Stream/streamWriteByte.asm
include	Stream/streamSendCodeOut.asm
include	Stream/streamHexToASCIILeading0.asm
