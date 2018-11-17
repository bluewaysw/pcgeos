
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Graphics Printer Print Drivers
FILE:		grpr9Styles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial revision


DC_ESCRIPTION:
	This file contains all the style setting routines for the grpr 9-pin
	driver.
		
	$Id: grpr9Styles.asm,v 1.1 97/04/18 11:55:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRCondensed.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSROverline.asm
include	Styles/stylesSRDblWidth.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRSubSuperScript.asm
include	Styles/stylesSRUnderline.asm

SetShadow	proc	near
SetItalic	label	near
SetOutline	label	near
SetStrikeThru	label	near
SetReverse	label	near
SetDblHeight	label	near
SetQuadHeight	label	near
SetFuture	label	near
ResetShadow	label	near
ResetItalic	label	near
ResetOutline	label	near
ResetStrikeThru	label	near
ResetReverse	label	near
ResetDblHeight	label	near
ResetQuadHeight	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetShadow	endp
