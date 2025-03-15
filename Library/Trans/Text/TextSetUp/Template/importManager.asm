COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		importManager.asm

AUTHOR: 	Jenny Greenwood, 2 September 1992

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:

	This is the main include file for the import module of the 
	Template translation library

	$Id: importManager.asm,v 1.1 97/04/07 11:40:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	templateGeode.def		; this includes the .def files

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

; TRANS_GET_FORMAT_BUFFER_SIZE is the number of bytes which must be
; read to determine whether a file to be imported is in a format which
; the library supports.
;
TRANS_GET_FORMAT_BUFFER_SIZE	equ	256	; <- change according to library
						; 256 is just the default

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	textCommonImport.asm		; common text import routine
include	importMain.asm			; main interface
