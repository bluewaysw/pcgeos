COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		mainManager.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	

	$Id: mainManager.asm,v 1.1 97/04/04 15:48:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include geocalcGeode.def
include	geocalcDocNote.def

;------------------------------------------------------------------------------
;			Class definition
;------------------------------------------------------------------------------

GeoCalcClassStructures	segment	resource
	GeoCalcProcessClass

;; method PROC_NAME,		CLASS_NAME,    MSG_NAME

GeoCalcClassStructures	ends

;------------------------------------------------------------------------------
;			GeoCalcProcessInstance
;------------------------------------------------------------------------------
idata	segment
procVars	GeoCalcProcessInstance <,		; Meta instance
>
idata	ends


;------------------------------------------------------------------------------
;			Unitialized data
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Code Resources
;------------------------------------------------------------------------------

include	mainInit.asm
include mainProcess.asm
