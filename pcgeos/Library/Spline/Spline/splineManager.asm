COMMENT @**********************************************************************

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spline library
FILE:		splineManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial Version

DESCRIPTION:
	This file manages the .asm files that implement the VisSpline object

RCS STAMP:
	$Id: splineManager.asm,v 1.1 97/04/07 11:09:04 newdeal Exp $

******************************************************************************@

include splineGeode.def
include splineVariables.def

;******************************************************************************
; 	Storage area (in dgroup) for the CLASS RECORD of VisSplineClass
;******************************************************************************

SplineClassStructures	segment resource
	VisSplineClass
SplineClassStructures	ends


;******************************************************************************
;			Code to implement this object
;******************************************************************************

include splineAttrs.asm
include splineControls.asm
include splineData.asm
include splineDragRect.asm
include	splineDragSelect.asm
include splineDraw.asm
include splineEC.asm
include	splineEndSelect.asm
include splineGoto.asm
include splineGState.asm
include splineGString.asm
include splineInsertDelete.asm
include splineKeyboard.asm
include splineMarker.asm
include splineMath.asm
include splineMethods.asm
include splineMode.asm
include	splinePtr.asm
include	splineOperate.asm
include splineScratch.asm
include splineSplitJoin.asm
include	splineStartSelect.asm
include splineTarget.asm
include splineUI.asm
include splineUndo.asm
include splineUtils.asm
include splineVisBounds.asm

SplineUtilCode	segment

include splineCutPaste.asm
include splineSuspend.asm

SplineUtilCode	ends



