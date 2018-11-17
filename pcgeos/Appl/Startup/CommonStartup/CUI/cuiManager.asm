COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonStartup/CUI
FILE:		CUI/cuiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/92		Initial version

DESCRIPTION:
	This file contains the user interface definition for
	Startup.

	$Id: cuiManager.asm,v 1.1 97/04/04 16:52:23 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cstartupGeode.def


;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include gstring.def				; for monikers in .ui file

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

ifdef ISTARTUP
include uiQuiz.def
include uiQuiz.asm
endif


include cuiMain.rdef
