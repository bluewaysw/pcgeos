COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		libManager.asm

AUTHOR: 	Jenny Greenwood, 2 September 1992

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:

	This is the main include file for the library module of the 
	Template translation library

	$Id: libManager.asm,v 1.1 97/04/07 11:40:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	templateGeode.def		; this includes the .def files

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; REENTRANT_CODE must be set either TRUE or FALSE before
; transLibEntry.asm is included.


REENTRANT_CODE	equ	FALSE		; this library needs a
					; semaphore around it because
					; it uses global variables
;
; IMPORT_OPTIONS_EXIST and EXPORT_OPTIONS_EXIST must be set either
; TRUE or FALSE before transUI.asm is included.
;
IMPORT_OPTIONS_EXIST	equ	FALSE
EXPORT_OPTIONS_EXIST	equ	FALSE

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	libFormat.asm			; Template format info
include	transLibEntry.asm		; library entry point
include	transUI.asm			; TransGetImportUI & TransGetExportUI
include	textCommonMain.asm		; udata and error handler

