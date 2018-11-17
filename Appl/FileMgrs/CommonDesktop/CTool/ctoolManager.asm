COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ctoolManager.asm

AUTHOR:		Adam de Boor, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/25/92		Initial revision


DESCRIPTION:
	Manager for installable-tool module
		

	$Id: ctoolManager.asm,v 1.1 97/04/04 15:02:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

if INSTALLABLE_TOOLS
;------------------------------------------------------------------------------
;	Module-specific includes
;------------------------------------------------------------------------------

include ctoolToolTrigger.def
include ctoolVariable.def

include	chunkarr.def
include file.def
include fileEnum.def
include library.def
include Internal/geodeStr.def

;------------------------------------------------------------------------------
;	Code
;------------------------------------------------------------------------------

include ctoolProcess.asm
include ctoolToolMgr.asm
include ctoolToolTrigger.asm

endif
