
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		toshiba 24-pin Print Driver
FILE:		toshiba24Styles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	5/92		Initial 2.0 version


DC_ESCRIPTION:
	This file contains all the style setting routines for the toshiba 24-pin
	driver.
		
	$Id: toshiba24Styles.asm,v 1.1 97/04/18 11:53:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRCondensed.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRUnderline.asm
include	Styles/stylesSRShadow.asm
include	Styles/stylesSRDblWidth.asm

SetStrikeThru	proc	near
SetSubscript	label	near
SetSuperscript	label	near
SetOutline	label	near
SetReverse	label	near
SetDblHeight	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetSubscript	label	near
ResetSuperscript label	near
ResetStrikeThru	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetDblHeight	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetStrikeThru	endp

