COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		mainManager.asm

AUTHOR:		Steve Scholl, November 15, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ss      11/15/89        Initial revision.

DESCRIPTION:
	Manager for this module.

	$Id: mainManager.asm,v 1.1 97/04/04 18:05:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include grobjGeode.def

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	mainConstant.def
include mainMacro.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	mainVariable.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
include globalUtils.asm
include largeRect.asm
include strings.asm

if ERROR_CHECK
include	globalErrorUtils.asm
endif
	end


