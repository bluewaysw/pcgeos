COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Motif/Win (specific code for Motif)
FILE:		winClassSpec.asm

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Split off from cwinClass.asm
	Eric	1/90		Contents of file moved to cwinClassCUAS.asm
				so can be shared by all CUA_STYLE UIs.

DESCRIPTION:
	This file contains OLWinClass-related code which is specific to
	Motif. See cwinClass.asm for class declaration and method table.

	$Id: winClassSpec.asm,v 1.1 97/04/07 11:03:13 newdeal Exp $

-------------------------------------------------------------------------------@

Build segment resource

Build	ends

;------------------------------

CommonFunctional segment resource

CommonFunctional ends

