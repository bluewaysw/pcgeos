COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Canon RGB Printer Driver
FILE:		canonRGBmono2Info.asm

AUTHOR:		David Hunter, June 26, 2000

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/26/2000   	Initial revision from canonRGBmonoInfo.asm


DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	GlobalPC BJC-2000 series Mono Info
;----------------------------------------------------------------------------

mono2Info	segment	resource

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
				NULL,
				offset mono2medRes,
				offset mono2hiRes,
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
				684,			; paper width (points)
				NULL,			; Main UI
				ASF1BinOptionsDialogBox,; Options UI
				PrintEvalCanonRGBOptionsUI; eval routine address
			>

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

mono2medRes	GraphicsProperties < MED_RES_X_RES,		; xres
				     MED_RES_Y_RES,		; yres
				     MED_RES_BAND_HEIGHT,	; band height
				     MED_RES_BUFF_HEIGHT,	; buffer height
				     INTERLEAVE_FACTOR,		; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

mono2hiRes	GraphicsProperties < HI_RES_X_RES,		; xres
				     HI_RES_Y_RES,		; yres
				     HI_RES_BAND_HEIGHT,	; band height
				     HI_RES_BUFF_HEIGHT,	; buffer height
				     INTERLEAVE_FACTOR,		; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

mono2Info	ends
