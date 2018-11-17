
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		QuietJet Print Driver
FILE:		quietjetStyles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	6/23/92		Initial 2.0 revision


DC_ESCRIPTION:
	This file contains all the style setting routines for the QuietJet
	driver.
		
	$Id: quietjetStyles.asm,v 1.1 97/04/18 11:52:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



;-----------------------------------------------------------------------
;               Jump Tables for setting text styles
;-----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetXXXXXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a text style

CALLED BY:	INTERNAL
		SetStyle

PASS:		--

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Styles/stylesSet.asm
include	Styles/stylesGet.asm
include	Styles/stylesTest.asm
include	Styles/stylesSRNLQ.asm
include	Styles/stylesSRUnderline.asm
include	Styles/stylesSRBold.asm

SetSubscript	proc	near
SetSuperscript	label	near
SetCondensed	label	near
SetItalic	label	near
SetDblWidth	label	near
SetDblHeight	label	near
SetStrikeThru	label	near
SetShadow	label	near
SetOutline	label	near
SetReverse	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetSubscript	label	near
ResetSuperscript label	near
ResetCondensed	label	near
ResetItalic	label	near
ResetDblWidth	label	near
ResetDblHeight	label	near
ResetStrikeThru	label	near
ResetShadow	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetQuadHeight	label	near
ResetOverline	label	near
ResetFuture	label	near
		clc		;screen off any passed error.
		ret
SetSubscript	endp

