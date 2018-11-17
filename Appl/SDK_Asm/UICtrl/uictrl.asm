COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UICtrl (Sample PC GEOS application)
FILE:		uictrl.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the UICtrl application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: uictrl.asm,v 1.1 97/04/04 16:32:27 newdeal Exp $

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

include object.def
include graphics.def
include gstring.def

include geoworks.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/vTextC.def

include uitsctrl.def		;Definition file for UI controller

;------------------------------------------------------------------------------
;			UI controller
;------------------------------------------------------------------------------

include uitsctrl.asm

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

UICProcessClass	class	GenProcessClass

UICProcessClass	endc

idata	segment
	UICProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		uictrl.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

main	segment resource
main	ends

