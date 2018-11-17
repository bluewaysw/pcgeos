COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ico Translation Library		
FILE:		libManager.asm

AUTHOR:		Steve Yegge, May 29th, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/12/92		Initial revision
	steve	5/29/93		grabbed for ico translation

DESCRIPTION:
	
	This is the main include file for the library module of the 
	Ico library	

	$Id: libManager.asm,v 1.1 97/04/07 11:29:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	icoGeode.def			; this includes the .def files
include	libExport.rdef

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

include	libFormat.asm			; Ico format info
include	libMain.asm			; contains GetExport/Import/Options
include	transUI.asm			; contains GetExport/Import/UI
include	transLibEntry.asm		; library entry point












