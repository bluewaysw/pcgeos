
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diablo Daisy Wheel Print Driver
FILE:		diabloStyles.asm

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
	This file contains all the style setting routines for the Diablo Daisy
	Wheel driver.
		
	$Id: diabloStyles.asm,v 1.1 97/04/18 11:56:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesGet.asm
include	Styles/stylesSet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRUnderline.asm

SetStrikeThru	proc	near
SetCondensed	label	near
SetSubscript	label	near
SetSuperscript	label	near
SetNLQ		label	near
SetOutline	label	near
SetReverse	label	near
SetShadow	label	near
SetDblWidth	label	near
SetDblHeight	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetCondensed	label	near
ResetSubscript	label	near
ResetSuperscript label	near
ResetNLQ	label	near
ResetStrikeThru	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetShadow	label	near
ResetDblWidth	label	near
ResetDblHeight	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
	clc			;screen off bogus errors.
	ret
SetStrikeThru	endp

