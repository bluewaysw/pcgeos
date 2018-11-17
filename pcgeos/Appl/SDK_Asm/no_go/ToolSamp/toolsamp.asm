COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ToolSamp (Sample PC GEOS application)
FILE:		toolsamp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/92		Initial version

DESCRIPTION:
	This file source code for the ToolSamp application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate the
	GenToolControl object.  In order for it to have some controllers to
	work with, we've set up two displays, each with a GenText, and
	tossed in a few of the Text library UI controllers to manipulate it.

RCS STAMP:
	$Id: toolsamp.asm,v 1.1 97/04/04 16:34:50 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def
include dbase.def

include object.def
include graphics.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/vTextC.def
UseLib Objects/styles.def
UseLib Objects/Text/tCommon.def
UseLib Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

TSProcessClass	class	GenProcessClass
TSProcessClass	endc

idata	segment
	TSProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		toolsamp.rdef		;include compiled UI definitions

