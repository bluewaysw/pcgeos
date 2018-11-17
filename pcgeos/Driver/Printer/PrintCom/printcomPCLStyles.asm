
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Print Driver
FILE:		printcomPCLStyles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/22/92		Initial revision from laserjetStyles.asm


DC_ESCRIPTION:
	This file contains all the style setting routines for the PCL 4
	driver.
		
	$Id: printcomPCLStyles.asm,v 1.1 97/04/18 11:50:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Styles/stylesGet.asm
include Styles/stylesSet.asm
include Styles/stylesTest.asm
include	Styles/stylesSRBold.asm
include	Styles/stylesSRItalic.asm
include	Styles/stylesSRUnderline.asm

SetCondensed	proc	near
SetSubscript	label	near
SetSuperscript	label	near
SetNLQ		label	near
SetDblWidth	label	near
SetDblHeight	label	near
SetStrikeThru	label	near
SetShadow	label	near
SetOutline	label	near
SetReverse	label	near
SetQuadHeight	label	near
SetOverline	label	near
SetFuture	label	near
ResetCondensed	label	near
ResetSubscript	label	near
ResetSuperscript label	near
ResetNLQ	label	near
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
SetCondensed	endp

