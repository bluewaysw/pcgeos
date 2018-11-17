
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Print Drivers
FILE:		printcomEpsonStyles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
	This file contains all the style setting routines for the Epson print
	drivers.
		
	$Id: printcomEpsonStyles.asm,v 1.1 97/04/18 11:50:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRCondensed.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRDblHeight.asm
include	Styles/stylesSRDblWidth.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRSubSuperScript.asm
include	Styles/stylesSRUnderline.asm

SetStrikeThru	proc	near
SetShadow	label	near
SetOutline	label	near
SetReverse	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetStrikeThru	label	near
ResetShadow	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetStrikeThru	endp


