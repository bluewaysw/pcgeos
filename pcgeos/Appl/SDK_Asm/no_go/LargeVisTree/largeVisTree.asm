COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Large Vis Tree Sample Application
FILE:		largeVisTree.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

DESCRIPTION:
	This file contains an application that demonstrates how to implement
	a 32-bit document space using visible objects.

	$Id: largeVisTree.asm,v 1.1 97/04/04 16:34:13 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;
; Standard include files
;
include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include object.def
include	graphics.def
include gstring.def
include	win.def
include lmem.def
include localize.def
include keyboard.def
include mouse.def
include initfile.def
include vm.def
include dbase.def
include timer.def
include timedate.def
include	fileStr.def
include system.def
include font.def
	
;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Object classes defined by this application
;------------------------------------------------------------------------------

include visLargeComp.asm

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
	
;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		largeVisTree.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
	
			
largeVisTree_ProcessClass	class GenProcessClass
largeVisTree_ProcessClass	endc
			
			
idata	segment
	largeVisTree_ProcessClass	mask CLASSF_NEVER_SAVED
		
idata	ends

main	segment resource
	
main	ends

end
