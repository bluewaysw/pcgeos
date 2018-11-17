COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomInfo.asm

AUTHOR:		Don Reeves, April 26, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/26/91		Initial revision

DESCRIPTION:
	Device info for the Complete Communicator fax board

	The file "printerDriver.def" should be included before this one
		
	$Id: ccomremInfo.asm,v 1.1 97/04/18 11:52:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Complete Communicator fax board
;----------------------------------------------------------------------------

ccomDeviceInfo	segment	resource

	; info blocks

ccomInfoStruct	PrinterInfo <		; ---- PrinterType -------------
				< PT_RASTER, BMF_MONO >,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_CUSTOM,
				SC_NO_SCSI,
				RC_NO_RS232C,
				CC_NO_CENTRONICS,
				FC_NO_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
			      	PS_PDL,
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,
					; ---- Mode Info Offsets -------
			     	offset ccomStdRes, ; graphics low resolution
			     	NULL,		   ; graphics medium
			     	offset ccomHiRes,  ; graphics high
			     	NULL,		   ; text draft
			     	NULL,		   ; text NLQ
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
				PS_NORMAL,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					; ---- Paper Width ------
			     	612,
			     	FaxDialogBox,		; Main UI
				ServerGroup,		; Options UI
			     	offset UIEvalPrintUI	; eval routine
			    >


;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

ccomStdRes	GraphicsProperties < FAX_HORIZ_RES,	; xres
				     FQ_STANDARD,	; yres
				     1,  		; band height
                                     1,			; buffer height
                                     1,			; #interleaves
                                     BMF_MONO,		; color format
				     NULL >		; color correction

ccomHiRes	GraphicsProperties < FAX_HORIZ_RES,	; xres
				     FQ_FINE,		; yres
				     1,			; band height
                                     1,			; buffer height
                                     1, 		; #interleaves
                                     BMF_MONO,		; color format
				     NULL >		; color correction

ccomDeviceInfo	ends
