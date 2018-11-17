COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		nike56Buffer.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	10/94	initial version

DESCRIPTION:

	$Id: nike56Buffer.asm,v 1.1 97/04/18 11:55:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Buffer/bufferCreateNike.asm		;PrLoadBandBuffer routine
include Buffer/bufferDestroyNike.asm		;PrDestroyPrintBuffers routine
include	Buffer/bufferLoadBandNike.asm		;PrLoadBandBuffer routine
include Buffer/bufferScanBandNike.asm		;PrScanBandBuffer routine
include	Buffer/bufferCompressNike.asm		;PrCompressBuffer routine
include Buffer/bufferClearBand.asm		;PrClearBandBuffer routine
include Buffer/bufferCreateRotateNike.asm	;make rotate buffers routine
include Buffer/bufferDestroyRotateNike.asm	;lose rotate buffers routine
