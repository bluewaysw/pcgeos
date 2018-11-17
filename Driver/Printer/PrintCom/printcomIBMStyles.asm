
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter Print Drivers
FILE:		printcomIBMStyles.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DC_ESCRIPTION:
	This file contains all the style setting routines for the prop 9-pin
	driver.
		
	$Id: printcomIBMStyles.asm,v 1.1 97/04/18 11:50:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRCondensed.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSROverline.asm
include	Styles/stylesSRDblWidth.asm
include	Styles/stylesSRDblHeight.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRSubSuperScript.asm
include	Styles/stylesSRUnderline.asm

SetShadow	proc	near
SetOutline	label	near
SetStrikeThru	label	near
SetReverse	label	near
SetQuadHeight	label	near
SetFuture	label	near
ResetShadow	label	near
ResetOutline	label	near
ResetStrikeThru	label	near
ResetReverse	label	near
ResetQuadHeight	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetShadow	endp


