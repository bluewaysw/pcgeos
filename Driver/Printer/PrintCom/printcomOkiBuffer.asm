

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Oki Microline print routines
FILE:		printcomOkiBuffer.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:

	$Id: printcomOkiBuffer.asm,v 1.1 97/04/18 11:50:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Buffer/bufferCreate.asm		;PrCreatePrintBuffers routine
include	Buffer/bufferDestroy.asm	;PrDestroyPrintBuffers routine
include	Buffer/bufferLoadBand.asm	;PrLoadBandBuffer routine
include Buffer/bufferScanBand.asm	;PrScanBandBuffer routine
include Buffer/bufferOkiSendOutput.asm	;PrSendOutputBuffer routine
					;peculiar to Oki Microline driver
include Buffer/bufferClearOutput.asm	;PrClearOutputBuffer routine
