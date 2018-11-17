COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file assembles the general-purpose Visible objects used
	by the specific UI.

	$Id: visManager.asm,v 1.1 97/04/07 11:44:33 newdeal Exp $

------------------------------------------------------------------------------@

_Vis		= 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include		uiGeode.def

include		timedate.def	
include		gstring.def
include		chunkarr.def
include		font.def

include		Internal/grWinInt.def
include		Internal/heapInt.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include		visMacro.def
include		visConstant.def
include		visVariable.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

;	
; VisClass	
;  
include		visClass.asm

include		visUtilsClass.asm
include		visUtilsResident.asm
		
include		visSpec.asm
include		visSpecUtils.asm
		
include		visEmpty.asm
include		visGeometry.asm		
;		
; VisCompClass		
;  
include		visComp.asm
include		visCompGeometry.asm

; VisContentClass
include		visContentClass.asm
include		visContentCommon.asm

end
