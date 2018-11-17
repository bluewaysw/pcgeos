COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainManager.asm

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial version
	don	5/92		Moved stuff into new files

DESCRIPTION:
	Manager file for the main module of Impex

	$Id: mainManager.asm,v 1.1 97/04/04 23:54:57 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include impexGeode.def
include impexThreadProcess.def


;------------------------------------------------------------------------------
;			Module Dependent stuff
;------------------------------------------------------------------------------

include	mainConstant.def
include	mainVariable.def


;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include mainEntry.asm
include mainExport.asm
include mainImport.asm
include mainMetafile.asm
include mainThread.asm
include mainUtils.asm
include mainC.asm
