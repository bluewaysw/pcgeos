COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntVariable.asm

AUTHOR:		Gene Anderson, Apr 17, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/17/91		Initial revision

DESCRIPTION:
	Variables for the Nimbus Font Converter.

	$Id: ninfntVariable.asm,v 1.1 97/04/04 16:16:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;
; Font filename template.
;
destFilename	char "xxxx1234.FNT", 0

;
; Class definition is stored in the application's idata resource here.
;
	NimbusFontInstallProcessClass	mask CLASSF_NEVER_SAVED
	FontInstallListClass
	VisRectangleClass

;
; Everything between 'SaveStart' and 'SaveEnd' will be save to/restored
; from the state file.
; NOTE:	Everything is saved/restored in word sized nuggets, therefore
;	this stuff MUST be a multiple of two!
SaveStart	label	word	;START of data saved to state file

SaveEnd		label	word	;END of data saved to state file

;
; NimbusVersionTag{[23]X,ZSoft} contain the font file tags for comparison
; to the first 4 bytes in the files.
;
NimbusVersionTag2X	dword	(NIMBUS_TAG_V2)
NimbusVersionTag3X	dword	(NIMBUS_TAG_V3)
NimbusVersionTagZSoft	dword	(NIMBUS_TAG_ZSOFT)

;
; NimbusConvertedFlag let's us know whether or not we've converted
; anything.
NimbusConvertFlag	byte	(FALSE)

;
; NimbusRestartFlag let's us know whether or not to force a system
; shutdown.
NimbusRestartFlag	byte	(FALSE)


idata	ends

udata	segment

;
; Temporary buffer to hold the currently selected directory to
; process for font files.
;
NimbusSelectedPath		char	PATH_BUFFER_SIZE dup (?)

;
; Handle for the currently selected directory to process for font files.
;
NimbusSelectedPathHandle	hptr	(?)

;
; Handle to temporarily allocated block to hold the font file header.
;
NimbusTagBlockHandle		hptr	(?)

;
; FontIDs value to check for in FileEnum() callback
;
checkFontID	FontIDs
checkFontName	char FONT_NAME_LEN dup(?)
checkError	NimbusError

udata	ends

