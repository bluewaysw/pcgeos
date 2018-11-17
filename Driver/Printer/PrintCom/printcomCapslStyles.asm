
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Print Driver
FILE:		printcomCapslStyles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial revision from laserjetStyles.asm


DC_ESCRIPTION:
	This file contains all the style setting routines for the CAPSL
	driver.
		
	$Id: printcomCapslStyles.asm,v 1.1 97/04/18 11:51:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Styles/stylesGet.asm
include Styles/stylesSet.asm
include Styles/stylesTest.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRUnderline.asm
include	Styles/stylesSRShadow.asm
include	Styles/stylesSROutline.asm
include	Styles/stylesSRReverse.asm
include	Styles/stylesSRDblWidth.asm

SetCondensed	proc	near
SetSubscript	label	near
SetSuperscript	label	near
SetNLQ		label	near
SetDblHeight	label	near
SetStrikeThru	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetCondensed	label	near
ResetSubscript	label	near
ResetSuperscript label	near
ResetNLQ	label	near
ResetDblHeight	label	near
ResetStrikeThru	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
		clc		;screen off any passed error.
		ret
SetCondensed	endp

