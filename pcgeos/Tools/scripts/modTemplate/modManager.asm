COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks @year -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		@Appl -- @Mod
FILE:		@modManager.asm

AUTHOR:		@fullname, @fulldate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	@irev

DESCRIPTION:
	Manager for this module.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_@Mod = 1

;------------------------------------------------------------------------------
;	Include definitions.
;------------------------------------------------------------------------------
include	geos.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
include	@modVariable.def

;------------------------------------------------------------------------------
;	Here comes the code...
;------------------------------------------------------------------------------
@Mod	segment	resource

include	@modMain.asm		; Main code file for this module.

@Mod	ends
