COMMENT @----------------------------------------------------------------------

	Copyright (c) Globalpc 1999 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		
FILE:		parentcManager.asm

AUTHOR:		

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:

	$Id: heapManager.asm,v 1.1 97/04/05 01:13:56 newdeal Exp $

------------------------------------------------------------------------------@

;--------------------------------------
;	Include files
;--------------------------------------

include geos.def
include geode.def
include resource.def
include lmem.def
include	file.def
include vm.def
include hugearr.def
include initfile.def
include heap.def
include gstring.def
include ec.def

UseLib	config.def
UseLib Objects/vTextC.def

include parentc.def
include parentControl.rdef

;-------------------------------------

include parentControl.asm
include parentcURLs.asm

;-------------------------------------


end
