COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Gif Translation Library
FILE:		libManager.asm

AUTHOR:		Maryann Simmons, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/12/92		Initial revision


DESCRIPTION:
	
	This is the main include file for the library module of the 
	gif library	

	$Id: libManager.asm,v 1.1 97/04/07 11:27:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	gifGeode.def			; this includes the .def files
include libExport.rdef

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; REENTRANT_CODE must be set either TRUE or FALSE before transLibEntry.asm
; is included.
;
REENTRANT_CODE		equ	FALSE		; this library needs a
						; semaphore around it since
						; it uses global variables
;
; IMPORT_OPTIONS_EXIST and EXPORT_OPTIONS_EXIST must be set either
; TRUE or FALSE before transUI.asm is included.
;
IMPORT_OPTIONS_EXIST	equ	FALSE
EXPORT_OPTIONS_EXIST	equ	TRUE

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	libFormat.asm			; gif format info
include	libMain.asm			; contains GetExport/Import/Options
include transUI.asm			; contains GetExport/Import/UI	
include	transLibEntry.asm		; library point entry












