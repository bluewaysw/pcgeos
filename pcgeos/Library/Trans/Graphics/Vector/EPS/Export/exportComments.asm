
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportComments.asm

AUTHOR:		Jim DeFrisco, 14 Feb 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This file contains the comments that go in the front of the file 
	according to the Adobe's Document Structuring Conventions for 
	EPS files.
		
	These comments are in lmem chunks to make it east to add the 
	parameters that follow them.

	$Id: exportComments.asm,v 1.1 97/04/07 11:25:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PSCode	segment	resource

;startDSC	label	char
;----------------------------------------------------------------------
;	Header
;----------------------------------------------------------------------

printFileID	char	"%!PS-Adobe-3.0", NL
epsFileID	char	"%!PS-Adobe-3.0 EPSF-3.0", NL

boundBox	char	"%%BoundingBox: "
creatorComment	char	"%%Creator: "
creationDate	char	"%%CreationDate: "
docData		char	"%%DocumentData: Clean7Bit", NL
level2		char	"%%LanguageLevel: 2", NL
extensionKey	char	"%%Extensions:"
cmykSupport	char	" CMYK"
dpsSupport	char	" DPS"
compositeSupport char	" Composite"
fileSupport	char	" FileSystem"
orientPortrait	char	"%%Orientation: Portrait", NL
orientLandscape char	"%%Orientation: Landscape", NL
numPages	char	"%%Pages: "
atendToken	char	"(atend)", NL
ascendOrder	char	"%%PageOrder: Ascend", NL
descendOrder	char	"%%PageOrder: Descend", NL
requirements	char	"%%Requirements: numcopies("
reqCollate	char	" collate", NL
titleComment	char	"%%Title: "

endComments	char	"%%EndComments",NL

ForceRef	orientPortrait
ForceRef	orientLandscape
ForceRef	atendToken

;----------------------------------------------------------------------
;	General Body Comments
;----------------------------------------------------------------------

lineContinue	char	"%%+ "
beginPreview	char	"%%BeginPreview: "
endPreview	char	"%%EndPreview", NL
beginObject	char	"%%BeginObject: "
endObject	char	"%%EndObject", NL

ForceRef	lineContinue
ForceRef	beginPreview
ForceRef	endPreview
ForceRef	beginObject
ForceRef	endObject

lineObject	char	" Stroke", NL 	; these object names should
areaObject	char	" Filled", NL		;  remain the same size
bitmapObject	char	" Bitmap", NL
textObject	char	" String", NL

;----------------------------------------------------------------------
;	Document Setup
;----------------------------------------------------------------------

;beginPSSetup	label	byte

endProlog	char	"%%EndProlog", NL
beginSetup	char	"%%BeginSetup", NL


endSetup	char	"%%EndSetup", NL

;endPSSetup	label	byte
;----------------------------------------------------------------------
;	Pages
;----------------------------------------------------------------------

pageNumber	char	"%%Page: "

beginPageSetup	char	"%%BeginPageSetup", NL
endPageSetup	char	"%%EndPageSetup", NL
pageTrailer	char	"%%PageTrailer", NL

;----------------------------------------------------------------------
;	Document Trailer
;----------------------------------------------------------------------

epsTrailer	char	"%%Trailer", NL, "%%EOF", NL
printTrailer	char	"%%Trailer", NL, C_CTRL_D


PSCode	ends
