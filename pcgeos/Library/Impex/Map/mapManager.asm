COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Map
FILE:		mapManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/91		Initial version

DESCRIPTION:
        This file assembles the Map module of Impex library.

	$Id: mapManager.asm,v 1.1 97/04/05 00:20:14 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include impexGeode.def
include impexThreadProcess.def

;------------------------------------------------------------------------------
;			Module Dependent stuff
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include mapCtrl.rdef

ImpexClassStructures	segment	resource
	ImpexMapControlClass            
ImpexClassStructures	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include	mapCtrl.asm
