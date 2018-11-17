COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Localize/Text
FILE:		textManager.asm

AUTHOR:		Cassie Hartzog, Sep 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/92	Initial revision


DESCRIPTION:
	
	This file includes all the other text code files.

	$Id: textManager.asm,v 1.1 97/04/04 17:13:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;                       Common GEODE stuff
;------------------------------------------------------------------------------

include localizeGeode.def
include localizeConstant.def
include localizeGlobal.def
include localizeMacro.def
include localizeErrors.def
include	localizeDocument.def
include localizeContent.def
include localizeText.def
include input.def
include Objects/inputC.def

;------------------------------------------------------------------------------
;                       Idata
;------------------------------------------------------------------------------

idata	segment
	ResEditTextClass
	ResEditGlyphClass
idata	ends

;------------------------------------------------------------------------------
;                       Code
;------------------------------------------------------------------------------

include textDraw.asm
