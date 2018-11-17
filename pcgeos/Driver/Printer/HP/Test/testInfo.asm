COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Test Printer Driver
FILE:		testInfo.asm

AUTHOR:		Don Reeves, July 10, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/10/94		Initial revision (from Dave)

DESCRIPTION:

	$Id: testInfo.asm,v 1.1 97/04/18 11:52:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	HP internal font set common to all deskjets.
;----------------------------------------------------------------------------

testInfo	segment	resource

	; info blocks

PrinterInfo		 <		; ---- PrinterType -------------
				< PT_RASTER,
				BMF_MONO >,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_RS232C,
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
				offset deskjetdjlowRes,
				offset deskjetdjmedRes,
				offset deskjetdjhiRes,
				NULL,	
				offset deskjetdjnlq,
                                        ; ---- Font Geometry -----------
                                NULL,
                                        ; ---- Symbol Set list -----------
                                offset deskjetdjSymbolSets,
					; ---- PaperMargins ------------
				< PR_MARGIN_LEFT,	; Tractor Margins
				PR_MARGIN_TRACTOR, 
				PR_MARGIN_RIGHT,
				PR_MARGIN_TRACTOR >,
				< PR_MARGIN_LEFT,	; ASF Margins
				PR_MARGIN_TOP, 	
				PR_MARGIN_RIGHT,
				PR_MARGIN_BOTTOM >,
					; ---- PaperInputOptions -------
				< MF_MANUAL1,
				TF_NO_TRACTOR,
				ASF_TRAY3 >,
					; ---- PaperOutputOptions ------
				< OC_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				612,			; paper width (points).
				MainUIGroup,		; Main UI
				OptionsUIGroup,		; Options UI
				0			; UI eval routines.
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

deskjetdjlowRes  GraphicsProperties < LO_RES_X_RES,      ; xres
                                     LO_RES_Y_RES,      ; yres
                                     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format

deskjetdjmedRes  GraphicsProperties < MED_RES_X_RES,     ; xres
                                     MED_RES_Y_RES,     ; yres
                                     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format

deskjetdjhiRes   GraphicsProperties < HI_RES_X_RES,      ; xres
                                     HI_RES_Y_RES,      ; yres
                                     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

deskjetdjSymbolSets label   word
        word    offset pr_codes_SetASCII7       ;ASCII 7 bit
        word    offset pr_codes_SetIBM437       ;IBM code page 437
        word    offset pr_codes_SetIBM850       ;IBM code page 850
        word    NULL                            ;no IBM code page 860
        word    NULL                            ;no IBM code page 863
        word    NULL                            ;no IBM code page 865
        word    offset pr_codes_SetRoman8       ;Roman-8
        word    NULL			        ;no MS windows
        word    NULL			        ;no Ventura Int'l
        word    offset pr_codes_SetLatin1       ;ECMA-94 Latin 1

deskjetdjnlq	label	word

testInfo	ends
