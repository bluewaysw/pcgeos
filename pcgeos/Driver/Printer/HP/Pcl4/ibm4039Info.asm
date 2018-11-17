
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PCL 4 download font driver
FILE:		ibm4039Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/93		Initial revision from laserdwn downLoadInfo.asm

DESCRIPTION:
	This file contains the device information for the IBM 4039
	Other Printers Supported by this resource:

	$Id: ibm4039Info.asm,v 1.1 97/04/18 11:52:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	HP download font set common to IBM 4039 LaserPrinter
;----------------------------------------------------------------------------

ibm4039Info	segment	resource

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
				PS_DOES_FONTS,	
					;-------Custom Entry Routine-------
				PrintEnterIBMPJL,
					;-------Custom Exit Routine-------
				PrintExitPJL,		
					; ---- Mode Info Offsets -------
				offset ibm4039lowRes,
				offset ibm4039medRes,
				offset ibm4039hiRes,
				NULL,	
				offset ibm4039nlq,
                                        ; ---- Font Geometry -----------
                                ibm4039FontGeometry,
                                        ; ---- Symbol Set list -----------
                                offset ibm4039SymbolSets,
					; ---- PaperMargins ------------
				< PR_MARGIN_LEFT,	; Tractor Margins
				0, 
				PR_MARGIN_RIGHT,
				0 >,
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
				OD_DUPLEXSO,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				612,			; paper width (points).
				Pcl4MainDialogBox,	; Main UI
				Pcl4OptionsDialogBox,	; Options UI
				PrintEvalDuplex		; UI eval routine.
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

ibm4039lowRes  GraphicsProperties < LO_RES_X_RES,      ; xres
                                     LO_RES_Y_RES,      ; yres
                                     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format

ibm4039medRes  GraphicsProperties < MED_RES_X_RES,     ; xres
                                     MED_RES_Y_RES,     ; yres
                                     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format

ibm4039hiRes   GraphicsProperties < HI_RES_X_RES,      ; xres
                                     HI_RES_Y_RES,      ; yres
                                     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color format


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

ibm4039nlq	label	word
		nptr	ibm4039_10CPI
		word	0			; table terminator

ibm4039SymbolSets label   word
        word    offset pr_codes_SetASCII7       ;ASCII 7 bit
        word    offset pr_codes_SetIBM437       ;IBM code page 437
        word    offset pr_codes_SetIBM850       ;IBM code page 850
        word    NULL                            ;no IBM code page 860
        word    NULL                            ;no IBM code page 863
        word    NULL                            ;no IBM code page 865
        word    offset pr_codes_SetRoman8       ;Roman-8
        word    offset pr_codes_SetWindows      ;MS windows
        word    offset pr_codes_SetVentura      ;Ventura Int'l
        word    offset pr_codes_SetLatin1       ;ECMA-94 Latin 1

;----------------------------------------------------------------------------
;	Font Structures
;----------------------------------------------------------------------------

ibm4039_10CPI	label	word

ibm4039FontGeometry	DownloadProperties	< HP_III_MAX_SOFT_FONTS,
						HP_III_MAX_POINTSIZE >


ibm4039Info	ends
