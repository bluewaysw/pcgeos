COMMENT @-----------------------------------------------------------------------


	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		winFieldClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLFieldClass		Open look Field class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	8/89		Motif extensions, more documentation
	Doug	11/89		Updated to new class structure, moved SpecBuild
				here from GenFieldClass.
	atw	6/90		Changed to use VM files for BG bitmaps
	Joon	7/92		PM extensions


DESCRIPTION:

	$Id: cwinField.asm,v 2.260 94/10/14 16:17:24 dlitwin Exp $

-------------------------------------------------------------------------------@


	******************************************************************
	* DO NOT INCLUDE OR ADD CODE TO THIS FILE, IT IS OFFICIALLY DEAD *
	******************************************************************

	;
	; This file has been broken out into:
	;	cwinFieldCommon.asm
	;	cwinFieldInit.asm
	;	cwinFieldOther.asm
	;	cwinFieldUncommon.asm
