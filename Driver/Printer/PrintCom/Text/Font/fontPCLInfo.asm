
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		fontPCLInfo.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/2/92		Initial revision 


DESCRIPTION:

	$Id: fontPCLInfo.asm,v 1.1 97/04/18 11:49:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fontIDTab	label	word
	word	FID_DTC_URW_ROMAN
	word	FID_DTC_URW_SANS
	word	FID_DTC_URW_MONO
	word	FID_DTC_CENTURY_SCHOOLBOOK
	word	FID_DTC_BROADWAY
	word	FID_DTC_COOPER_C_BLACK
	word	FID_DTC_FRANKLIN_GOTHIC
	word	FID_DTC_UNIVERSITY_ROMAN
	word	FID_DTC_PRESTIGE_ELITE
	word	FID_DTC_GARAMOND
	word	FID_DTC_OPTIMA
	word	FID_DTC_BODONI
	word	FID_INVALID			;table terminator

typefaceTab	label	word
	word	5		;Times-Roman
	word	4		;Helv
	word	3		;Courier
	word	23		;Century Schoolbook
	word	21		;Broadway
	word	19		;Cooper Black
	word	6		;Letter Gothic
	word	24		;University Roman
	word	8		;Prestige Elite
	word	18		;Garamond
	word	17		;Optima
	word	22		;Bodoni
	word	0		;Line Printer
