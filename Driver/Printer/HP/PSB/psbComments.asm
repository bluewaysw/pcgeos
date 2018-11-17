
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript (bitmap) Printer driver
FILE:		psbComments.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/91		Initial revision


DESCRIPTION:
	This file contains the comments that go in the front of the file 
	according to the Adobe's Document Structuring Conventions for 
	EPS files.
		
	These comments are in lmem chunks to make it east to add the 
	parameters that follow them.

	$Id: psbComments.asm,v 1.1 97/04/18 11:52:07 newdeal Exp $

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
numPages	char	"%%Pages: "
titleComment	char	"%%Title: "

requirements	char	"%%Requirements: numcopies("
endComments	char	"%%EndComments",NL

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
