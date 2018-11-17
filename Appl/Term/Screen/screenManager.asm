COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen
FILE:		screenManager.asm

AUTHOR:		Dennis Chow, September 8, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 8/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: screenManager.asm,v 1.1 97/04/04 16:55:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Screen = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	screenInclude.def

include hugearr.def
if USE_FEP
include	Internal/fepDr.def
endif

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata segment
include	screenVariable.def
idata ends

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------

Screen segment resource

include	screenMain.asm		; externally called routines
include screenLocal.asm		; internally called routines

Screen ends

	end
