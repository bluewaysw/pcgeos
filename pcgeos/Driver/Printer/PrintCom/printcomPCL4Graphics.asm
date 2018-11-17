
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		printcomPCL4Graphics.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial laserjet revision
	Dave	1/21/92		2.0 PCL 4 driver revision


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver graphics mode support

	$Id: printcomPCL4Graphics.asm,v 1.1 97/04/18 11:51:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsPrintSwathPCL4.asm
include	Graphics/graphicsSendBitmapPCL4.asm
include	Graphics/graphicsSendBitmapCompressedPCL4.asm
include	Graphics/graphicsAdjustForResolution.asm
