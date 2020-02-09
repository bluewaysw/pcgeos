COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntStrings.asm

AUTHOR:		Gene Anderson, Apr 26, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/26/91		Initial revision
	JDM	91.05.09	Move StringsUI from UI file.

DESCRIPTION:
	String resources for Nimbus font converter

	$Id: ninfntStrings.asm,v 1.1 97/04/04 16:16:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; NOTE: the order must be the same as the NimbusError enum
;
ErrorStrings	segment	lmem	LMEM_TYPE_GENERAL

abortMsg	chunk.char "Aborting.",0

openErrorMsg	chunk.char "Error opening Nimbus font file.",0

closeErrorMsg	chunk.char "Error closing Nimbus font file.",0

readErrorMsg	chunk.char "Error reading Nimbus font file.",0

createErrorMsg	chunk.char "Error creating PC/GEOS font file.",0

writeErrorMsg	chunk.char "Error writing PC/GEOS font file.",0

memoryErrorMsg	chunk.char "Memory allocation error.",0

badDataErrorMsg	chunk.char "Bad data in Nimbus font file.",0

noCharsErrorMsg	chunk.char "No PC/GEOS characters found in font.",0

charMissingMsg	chunk.char "Missing character in accent composite.",0

noFontIDsMsg	chunk.char "No available font IDs.",0

fontIDInUseMsg	chunk.char "Font already installed.",0

fontExistsMsg	chunk.char "Font already exists in system.",0

ErrorStrings	ends

FIRST_ERROR	equ	abortMsg



StringsUI	segment	lmem	LMEM_TYPE_GENERAL

NimbusFontInstallStubString 	chunk.char \
	"This functionality not yet implemented.",0

NimbusFontInstallAllocFailedString 	chunk.char \
	"Unable to allocate memory block.",0

NimbusFontInstallFileReadErrorString 	chunk.char \
	"Unable to read from file.",0

NimbusFontInstallSetDirectoryFailedString 	chunk.char \
	"Unable to set the current directory.",0

NimbusFontInstallFileIgnoringString 	chunk.char \
	"Unable to open \"\1\" for reading -- ignoring.",0

NimbusFontInstallNameInsertFailedString 	chunk.char \
	"Unable to insert the names into list.",0

NimbusFontInstallNoFontFilesFoundString 	chunk.char \
	"No valid font files were found.  Please try again.",0

NimbusFontInstallConversionCompleteString	chunk.char \
	"Conversion complete.", 0

NimbusFontInstallConfirmFileOverwriteString	chunk.char \
	"The file already exists.  Overwrite?", 0

NimbusFontInstallRestartSystemQueryString	chunk.char \
	"PC/GEOS needs to be restarted for a change to the ",
	"available fonts to take effect.  Do you wish to ",
	"proceed?", 0

NimbusFontInstallNullNameString	chunk.char \
	"You must assign a name to the font.",0


StringsUI	ends
