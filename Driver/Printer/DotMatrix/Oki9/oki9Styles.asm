
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Okidata Print Driver
FILE:		oki9Styles.asm

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
	This file contains all the style setting routines for the oki9 
	driver.
		
	$Id: oki9Styles.asm,v 1.1 97/04/18 11:53:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Styles/stylesGet.asm
include Styles/stylesSet.asm
include Styles/stylesTest.asm
include	Styles/stylesSRSubscript.asm
include	Styles/stylesSRSuperscript.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRUnderline.asm


SetStrikeThru	proc	near
SetCondensed	label	near
SetShadow	label	near
SetOutline	label	near
SetReverse	label	near
SetDblWidth	label	near
SetDblHeight	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetStrikeThru	label	near
ResetCondensed	label	near
ResetShadow	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetDblWidth	label	near
ResetDblHeight	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
	ret
SetStrikeThru	endp

