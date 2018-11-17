COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Brother NIKE 56-jet driver
FILE:		nike56BaseInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial version

DESCRIPTION:
	This file contains the device information for the
	narrow carriage printer

	Other Printers Supported by this resource:

	$Id: nike56BaseInfo.asm,v 1.1 97/04/18 11:55:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	
;----------------------------------------------------------------------------

baseInfo	segment	resource

	; info blocks

PrinterInfo		   <  < PT_RASTER,    ; ---- PrinterType -------------
                                BMF_MONO >,
                                        ; ---- PrinterConnections ------
                                < IC_NO_IEEE488,
                                CC_NO_CUSTOM,
                                SC_NO_SCSI,
                                RC_NO_RS232C,
                                CC_NO_CENTRONICS,
                                FC_NO_FILE,
                                AC_NO_APPLETALK >,
                                        ; ---- PrinterSmarts -----------
                                PS_DUMB_RASTER,
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
                                        ; ---- Mode Info Offsets -------
                                offset baseLoRes,
                                offset baseMedRes,
                                offset baseHiRes,
                                NULL,
                                NULL,
                                        ; ---- Font Geometry -----------
                                NULL,
                                        ; ---- Symbol Set list -----------
                                NULL,
                                        ; ---- PaperMargins ------------
                                < PR_MARGIN_LEFT,       ; Tractor Margins
                                PR_MARGIN_TOP,		;in reality there are
                                PR_MARGIN_RIGHT,	;no tractor margins
                                PR_MARGIN_BOTTOM >,
                                < PR_MARGIN_LEFT,       ; ASF Margins
                                PR_MARGIN_TOP,
                                PR_MARGIN_RIGHT,
                                PR_MARGIN_BOTTOM >,
                                        ; ---- PaperInputOptions -------
                                < MF_MANUAL1,
                                TF_NO_TRACTOR,
                                ASF_TRAY1 >,
                                        ; ---- PaperOutputOptions ------
                                < OC_NO_COPIES,
                                PS_REVERSE,
                                OD_SIMPLEX,
                                SO_NO_STAPLER,
                                OS_NO_SORTER,
                                OB_NO_OUTPUTBIN >,
                                        ;
				PR_MAX_PAPER_WIDTH,     ; paper width (points).
				NULL,                   ; Main UI
				NikeOptionsDialogBox,	; Options UI
				PrintEvalNikeOptionsUI	; eval routine
                              >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

baseHiRes	GraphicsProperties < HI_RES_MONO_X_RES,		; xres
				     HI_RES_MONO_Y_RES,		; yres
				     HI_RES_MONO_BAND_HEIGHT,	; band height
                                     HI_RES_MONO_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_MONO,			; color format
				     handle gamma21 >		; color correct

baseMedRes	GraphicsProperties < MED_RES_MONO_X_RES,	; xres
				     MED_RES_MONO_Y_RES,	; yres
				     MED_RES_MONO_BAND_HEIGHT,	; band height
                                     MED_RES_MONO_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

baseLoRes	GraphicsProperties < LO_RES_MONO_X_RES,		; xres
				     LO_RES_MONO_Y_RES,		; yres
				     LO_RES_MONO_BAND_HEIGHT,	; band height
                                     LO_RES_MONO_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_MONO,			; color format
				     NULL >			; color correct

baseInfo	ends
