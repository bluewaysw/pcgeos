COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Canon BJC Printer Driver
FILE:		canonBJCmonoInfo.asm

AUTHOR:		Joon Song, Jan 25, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/25/99   	Initial revision


DESCRIPTION:
		
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Canon BJC Mono Info
;----------------------------------------------------------------------------

monoInfo	segment	resource

	; info blocks

PrinterInfo		<		; ---- PrinterType -------------
				< PT_RASTER, BMF_MONO >,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				  CC_NO_CUSTOM,
				  SC_NO_SCSI,
				  RC_NO_RS232C,
				  CC_CENTRONICS,
				  FC_FILE,
				  AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_DUMB_RASTER,
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
					; ---- Mode Info Offsets -------
				offset monolowRes,
				NULL,
				offset monohiRes,
				NULL,
				NULL,
					; ---- Font Geometry -----------
				NULL,
					; ---- Symbol Set list -----------
				NULL,
					; ---- PaperMargins ------------
				< PR_MARGIN_LEFT,	; Tractor Margins
				  PR_MARGIN_TOP,
				  PR_MARGIN_RIGHT,
				  PR_MARGIN_BOTTOM >,
				< PR_MARGIN_LEFT,	; ASF Margins
				  PR_MARGIN_TOP,
				  PR_MARGIN_RIGHT,
				  PR_MARGIN_BOTTOM >,
					; ---- PaperInputOptions -------
				< MF_NO_MANUAL,
				  ASF_TRAY1,
				  TF_NO_TRACTOR >,
					; ---- PaperOutputOptions ------
				< OC_NO_COPIES,
				  PS_REVERSE,
				  OD_SIMPLEX,
				  SO_NO_STAPLER,
				  OS_NO_SORTER,
				  OB_NO_OUTPUTBIN >,
				612,			; paper width (points)
				NULL,			; Main UI
				ASF1BinOptionsDialogBox,; Options UI
				PrintEvalDummyASF	; eval routine address
			>

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

monolowRes	GraphicsProperties < LOW_RES_X_RES,		; xres
				     LOW_RES_Y_RES,		; yres
				     BAND_HEIGHT,		; band height
				     BUFF_HEIGHT,		; buffer height
				     INTERLEAVE_FACTOR,		; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

monohiRes	GraphicsProperties < HI_RES_X_RES,		; xres
				     HI_RES_Y_RES,		; yres
				     BAND_HEIGHT,		; band height
				     BUFF_HEIGHT,		; buffer height
				     INTERLEAVE_FACTOR,		; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

monoInfo	ends
