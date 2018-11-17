

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		printcomDotMatrixBuffer.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:

	$Id: printcomDotMatrixBuffer.asm,v 1.1 97/04/18 11:50:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Buffer/bufferCreate.asm		;PrCreatePrintBuffers routine
include	Buffer/bufferDestroy.asm	;PrDestroyPrintBuffers routine
include	Buffer/bufferLoadBand.asm	;PrLoadBandBuffer routine
include Buffer/bufferScanBand.asm	;PrScanBandBuffer routine
include Buffer/bufferSendOutput.asm	;PrSendOutputBuffer routine
include Buffer/bufferClearOutput.asm	;PrClearOutputBuffer routine
