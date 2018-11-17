COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax 2.2
FILE:		faxprintDeviceInfo.asm

AUTHOR:		Jacob Gabrielson, Mar 10, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	3/10/93   	Initial revision
	AC	9/ 8/93		Changed for Group3
	jdashe	10/19/94	Modified for tiramisu

DESCRIPTION:

	$Id: faxprintDeviceInfo.asm,v 1.1 97/04/18 11:53:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;			Fax Print Device Info
;----------------------------------------------------------------------------


DeviceInfo	segment	resource

faxPrintDeviceInfo	PrinterInfo	\
			<
			;
			;  PrinterType
			;
			< PT_RASTER, BMF_MONO >,
			;
			; PrinterConnections
			;
			< IC_NO_IEEE488,
			CC_CUSTOM,
			SC_NO_SCSI,
			RC_NO_RS232C,
			CC_NO_CENTRONICS,
			FC_NO_FILE,
			AC_NO_APPLETALK >,
			;
			; PrinterSmart
			;
				PS_DUMB_RASTER,
			;
			; Custom entry routine
			;
				NULL,
			;
			; Custom exit routine
			;
				NULL,
			;
			; Mode info (GraphicsProperties) offsets
			;
				offset faxStdRes,	; low
				NULL,			; med
				offset faxFineRes,	; high
				NULL,			; text draft
				NULL,			; text NLQ
			;
			; Font geometry
			;
				NULL,
			;
			; Font symbol set list
			;
                                NULL,
			;
			; PaperMargins
			;
				< PR_MARGIN_LEFT,	; Tractor
				PR_MARGIN_TRACTOR,
				PR_MARGIN_RIGHT,
				PR_MARGIN_TRACTOR >,

				< PR_MARGIN_LEFT,	; Tractor
				PR_MARGIN_TRACTOR,
				PR_MARGIN_RIGHT,
				PR_MARGIN_TRACTOR >,
			;
			; PaperInputOptions
			;
				< MF_NO_MANUAL,
				TF_NO_TRACTOR,
				ASF_TRAY1>,
			;
			; PaperOutputOptions
			;
				< OC_NO_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_OUTPUTBIN1>,
			;
			; PI_paperWidth
			;
				612,			; max. paper size
			;
			; UI stuff
			;
				NULL,			; Main UI
				NULL,			; Options UI
				NULL			; UI eval routine
			>

public faxPrintDeviceInfo

;----------------------------------------------------------------------------
;			      Graphics Modes Info
;----------------------------------------------------------------------------

faxStdRes	GraphicsProperties < \
					FAX_X_RES,	; xres
					FAX_STD_Y_RES,	; yres
					FAX_STD_RES_BAND_HEIGHT,
					FAX_STD_RES_BYTES_COLUMN,
							; bytes/column
					FAX_STD_RES_INTERLEAVE_FACTOR,
							; # interleaves
					BMF_MONO,	; color format
					NULL>		; color correction

faxFineRes	GraphicsProperties < \
					FAX_X_RES,	; xres
					FAX_FINE_Y_RES,	; yres
					FAX_FINE_RES_BAND_HEIGHT,
					FAX_FINE_RES_BYTES_COLUMN, 
							; bytes/column
					FAX_FINE_RES_INTERLEAVE_FACTOR,
							; # interleaves
					BMF_MONO,	; color format
					NULL>		; color correction
DeviceInfo	ends













