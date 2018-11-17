

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common print routines
FILE:		red64Buffer.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/93	initial version

DESCRIPTION:

	$Id: red64Buffer.asm,v 1.1 97/04/18 11:55:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Buffer/bufferCreateRedwood.asm	;PrLoadBandBuffer routine
include Buffer/bufferDestroy.asm        ;PrDestroyPrintBuffers routine
include	Buffer/bufferLoadBandRedwood.asm	;PrLoadBandBuffer routine
include Buffer/bufferScanFracBand.asm	;PrScanBandBuffer routine
include Buffer/bufferSendOutputRedwood.asm	;PrSendOutputBuffer routine
include Buffer/bufferClearBand.asm	;PrClearBandBuffer routine
