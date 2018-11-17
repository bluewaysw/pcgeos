
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM late model 24-pin Print Driver
FILE:		printcomIBMPPDS24Styles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial epson revision
	Dave	11/1/91		PPDS24 revision
	Dave	5/92		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the style setting routines for the PPDS24 24-pin
	driver.
		
	$Id: printcomIBMPPDS24Styles.asm,v 1.1 97/04/18 11:51:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRDblHeight.asm
include	Styles/stylesSRDblWidth.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRShadow.asm
include	Styles/stylesSROutline.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRSubSuperScript.asm
include	Styles/stylesSRUnderline.asm

SetOverline	proc	near
SetCondensed	label	near
SetReverse	label	near
SetQuadHeight	label	near
SetFuture	label	near
SetStrikeThru	label	near
ResetStrikeThru	label	near
ResetOverline	label	near
ResetCondensed	label	near
ResetReverse	label	near
ResetQuadHeight	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetOverline	endp


