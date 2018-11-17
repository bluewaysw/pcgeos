COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VObj (Sample PC GEOS application)
FILE:		vobjManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

DESCRIPTION:

IMPORTANT:

RCS STAMP:
	$Id: vobjManager.asm,v 1.1 97/04/04 16:33:56 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include Objects/winC.def
include Objects/inputC.def			; Required for mouse input

include assert.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;
; Include our definitions here so that we can use the classes in ui.def as
; our superclasses.
;
include vobj.def

;
; There must be an instance of every class in idata.
;
idata	segment
	VObjProcessClass	mask CLASSF_NEVER_SAVED
idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
include		vobj.rdef		;include compiled UI definitions

;
; Include the class implementations
;
include	vobjContent.asm
include	vobj.asm
