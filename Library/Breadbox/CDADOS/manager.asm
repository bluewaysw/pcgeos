COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Dirk Lausecker 1997 -- All Rights Reserved

PROJECT:	MM-Projekt
MODULE:		Driver Template
FILE:		Manager.asm

AUTHOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	17.07.97	Initial revision


DESCRIPTION:
	This is the manager file for the driver-template.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Include Files
;-----------------------------------------------------------------------------

;
include	geos.def
include	resource.def
include	ec.def
include	driver.def
include	system.def

;include	Internal/interrup.def

;include        CDAError.def


;-----------------------------------------------------------------------------
;		Source files for driver
;-----------------------------------------------------------------------------
	.ioenable
include     CDAMain.asm
include     CDAStrat.asm
