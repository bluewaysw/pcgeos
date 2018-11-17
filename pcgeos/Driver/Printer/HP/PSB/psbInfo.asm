
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript bitmap driver
FILE:		psbInfo.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision

DESCRIPTION:
	This file contains the device information for the PostScript
	Other Printers Supported by this resource:

	$Id: psbInfo.asm,v 1.1 97/04/18 11:52:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	PostScript (bitmap)
;----------------------------------------------------------------------------

psbInfo	segment	resource

	; info blocks

psbInfoStruct	PrinterInfo < < 0,BMF_MONO,PT_RASTER>,; PrinterType 
			      < 0,0,1,1,0,0 >,	; PrinterConnection: 
			      PS_DUMB_RASTER, 	; PrinterSmart
						; Mode Info Offsets
			      offset psblowRes, ; offset to mode info
			      offset psbmedRes,	; offset to mode info
			      offset psbhiRes,	; offset to mode info
			      0,		; offset to mode info
			      0,		; offset to mode info
						; Paper Margins
			      18,18,		; left/top margin
			      18,18, 		; right/bottom margin
			      < 0,PS_NORMAL,1,0,1 >, ; PrinterFeedOptions
			      PS_LEGAL,		; largest paper accepted.
			    >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

psblowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
				     LO_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

psbmedRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
				     MED_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

psbhiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
				     HI_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

psbInfo	ends
