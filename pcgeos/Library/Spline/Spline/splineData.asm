COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spline Edit object
FILE:		splineData.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version


DESCRIPTION:	

	This file contains tables of constant data -- jump tables,
	Arcsine tables, etc.  

	$Id: splineData.asm,v 1.1 97/04/07 11:09:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -unreach		; ignore "unreachable code" warnings in this file



SplinePtrCode	segment

; based on the SplineMode etype 
SplinePtrCalls 	label word
    NearProc	SplinePtrCreateCommon
    NearProc	SplinePtrBeginnerSplineCreate
    NearProc	SplinePtrCreateCommon
    NearProc	SplineMoveCommon
    NearProc	SplineMoveCommon
    NearProc	StubCLC		; inactive

.assert ($-SplinePtrCalls eq SplineMode*2)

StubCLC	proc near
	clc
	ret
StubCLC	endp


ErrorStubSPC	proc	near
EC <	ERROR ILLEGAL_CALL_TABLE_VALUE	>
NEC <	ret				>
ErrorStubSPC	endp


; based on half of the ActionType.

SplineMoveCalls 	label nptr
    NearProc	SplineMoveAnchor
    NearProc	SplineMoveSegment
    NearProc	SplineMoveControl
    NearProc	SplinePtrMoveRectangle

.assert ($-SplineMoveCalls eq ActionType-2)

;-----------------------------------------------------------------------------
; To add a SplineOperateType, 2 routines are required. 
; The first is a setup routine, which can be one of:
;
;	SplineSaveCXDXToSD
;	SplineCheckCanDraw
;	SplineCheckCanDrawAndSaveCXDX	
;	StubCLC
;
;	These routines either set or clear the carry depending on
;whether to go ahead with the processing or not.
;
;	The 2nd routine is the actual processing routine.  These
;routines are divided up into 2 code resources -- the more commonly
;used ones in the first resource, and the less commonly used in the
;2nd.  The processing routines can return SDF_STOP_ENUMERATION in the
;scratch data (SD_flags) to stop processing.  
;-----------------------------------------------------------------------------
 

; These calls are made before any SplineOperate... operation

SplineOperateSetupCalls	label	nptr
    NearProc	SplineSaveCXDXToSD	; SOT_ADD_DELTAS
    NearProc	SplineSaveCXDXToSD	; SOT_UPDATE_CONTROLS_FROM_ANCHOR 
    NearProc	StubCLC			; SOT_UPDATE_AUTO_SMOOTH_CONTROLS
    NearProc	SplineCheckCanDrawAndSaveCXDX
					; SOT_DRAW_FOR_SELECTION_RECTANGLE
    NearProc	SplineSaveCXDXToSD	; SOT_CHECK_POINT_AGAINST_VIS_BOUNDS
    NearProc	SplineCheckCanDraw	; SOT_DRAW
    NearProc	SplineCheckCanDraw		; SOT_ERASE
    NearProc	SplineCheckCanDrawAndSaveCXDX	; SOT_INVALIDATE

    NearProc	SplineCheckCanDraw	; SOT_DRAW_AS_DRAWN
    NearProc	SplineCheckCanDrawAndSaveCXDX
					; SOT_ERASE_BEGINNER_ANCHOR_MOVE 

.assert ($-SplineOperateSetupCalls eq PTR_CODE_OPERATE_TYPES)

; OperateCodeCalls:
    NearProc	SplineSaveCXDXToSD	; SOT_MODIFY_INFO_FLAGS

    NearProc	StubCLC			; SOT_DELETE_POINT
    NearProc	StubCLC			; SOT_COPY_TO_UNDO
    NearProc	StubCLC			; SOT_SUBDIVIDE
    NearProc 	StubCLC			; SOT_SELECT_ANCHOR_IF...
    NearProc	StubCLC			; SOT_ADD_NEXT_..
    NearProc	StubCLC			; SOT_ADD_PREV...
    NearProc 	SplineSaveCXDXToSD	; SOT_POINT_ON_SEG...
    NearProc 	SplineSaveCXDXToSD	; SOT_POINT_AT_CXDX
    NearProc	StubCLC			; SOT_SELECT_POINT
    NearProc	SplineSaveCXDXToSD	; SOT_TRANFORM_POINT
    NearProc	StubCLC			; SOT_ADD_TO_NEW
    NearProc	SplineSaveCXDXToSD	; SOT_GET_LENGTHS
    NearProc	SplineSaveCXDXToSD	; SOT_REMOVE_EXTRA_CONTROLS
    NearProc	SplineSaveCXDXToSD	; SOT_INSERT_IN_ARRAY
    NearProc	SplineSaveCXDXToSD	; SOT_TOGGLE_INFO_FLAGS
    NearProc	SplineSaveCXDXToSD	; SOT_GET_SMOOTHNESS
    NearProc	SplineSaveCXDXToSD	; SOT_GET_NUM_CONTROLS
    NearProc	StubCLC			; SOT_ADD_CONTROLS_CONFORM

.assert ($-SplineOperateSetupCalls eq SplineOperateType)


; These are all the various procedures that can be called by
; the "SplineOperate..." procedures.  These procedures MUST be
; in the same order as the SplineOperateTypes enumerated type.

SplineOperateCalls	label	word
    NearProc 	SplineAddDeltas
    NearProc	SplineUpdateControlsFromAnchor
    NearProc	SplineUpdateAutoSmoothControls
    NearProc	SplineDrawPointForDragRect
    NearProc	SplineAddPointToBoundingBox
    NearProc	SplineDrawPointCommon
    NearProc	SplineErasePointCommon
    NearProc	SplineInvalCurve
    NearProc	SplineDrawPointAsItThinksItsDrawn
    NearProc	SplineCheckBeginnerAnchorMove

.assert ($-SplineOperateCalls eq PTR_CODE_OPERATE_TYPES)

SplinePtrCode	ends

SplineOperateCode	segment

SplineOperateCodeCalls 	label word

    NearProc	SplineModifyInfoFlags
    NearProc	SplineDeletePoint
    NearProc	SplineCopyPointToUndo
    NearProc	SplineSubdivideCurveHigh
    NearProc	SplineSelectAnchorIfHandleFilled
    NearProc	SplineAddNextControl
    NearProc	SplineAddPrevControl
    NearProc	SplineCheckHitSegment
    NearProc	SplineCheckHitPoint
    NearProc	SplineSelectPoint
    NearProc	SplineTransformPoint
    NearProc	SplineAddToNew
    NearProc	SplineStoreLengthOfCurve
    NearProc	SplineRemoveExtraControls
    NearProc	SplineInsertInArray
    NearProc	SplineToggleInfoFlags
    NearProc	SplineGetSmoothness
    NearProc	SplineGetNumControls
    NearProc	SplineAddControlsConform


.assert ($-SplineOperateCodeCalls eq SplineOperateType-PTR_CODE_OPERATE_TYPES)

SplineOperateCode	ends

SplineSelectCode	segment

SplineEndMoveControlTable	label	word
    NearProc	ErrorStubSSC
    NearProc	ErrorStubSSC
    NearProc	SplineEndMoveControlCreate
    NearProc	ErrorStubSSC
    NearProc	SplineEndMoveControlEdit
    NearProc	ErrorStubSSC

.assert ($-SplineEndMoveControlTable eq SplineMode*2)

; based on SplineSelectType
SplineSelectCalls	label nptr
    NearProc	StubSSC
    NearProc	SplineSelectAnchor
    NearProc	SplineSelectSegment
    NearProc	SplineSelectControl
    NearProc	SplineSelectNothing
    NearProc	SplineSelectNothing

.assert ($-SplineSelectCalls eq SplineSelectType *2)

; Mode-based calls for MSG_META_DRAG_SELECT
; based on the SplineMode etype

SplineDragSelectCalls	label nptr
    NearProc	StubSSC			; beginner polyline create
    NearProc	StubSSC			; beginner spline create
    NearProc	SplineDSAdvancedCreate
    NearProc	SplineDSEditModes
    NearProc	SplineDSEditModes
    NearProc	StubSSC			; inactive

.assert ($-SplineDragSelectCalls eq SplineMode*2)

SplineBeginMoveCalls 	label word
    NearProc	SplineBeginMoveAnchor
    NearProc	SplineBeginMoveSegment
    NearProc	SplineBeginMoveControl
    NearProc	SplineDSDragRectangle


ErrorStubSSC	proc	near
EC <	ERROR 	ILLEGAL_SPLINE_MODE	>
	ret
ErrorStubSSC	endp

StubSSC	proc 	near
	ret
StubSSC	endp



SplineEndMoveCalls 	label word
    NearProc	SplineEndMoveAnchor
    NearProc	SplineEndMoveSegment
    NearProc	SplineEndMoveControl
    NearProc	SplineESDragRectangle


; based on the SplineMode etype 
SplineStartSelectCalls 	label word
    NearProc	SplineSSBeginnerCreate
    NearProc	SplineSSBeginnerSplineCreate
    NearProc	SplineSSCreateModeCommon
    NearProc	SplineSSEditMode
    NearProc	SplineSSEditMode
    NearProc	StubSSC

.assert ($-SplineStartSelectCalls eq SplineMode*2)

; based on the SplineMode etype 
SplineEndSelectCalls 	label word
    NearProc	StubSSC
    NearProc	StubSSC
    NearProc	SplineESAdvancedCreateMode
    NearProc	SplineESEditModes
    NearProc	SplineESEditModes
    NearProc	StubSSC

.assert ($-SplineEndSelectCalls eq SplineMode*2)

SplineSelectInternalCalls	label word
    NearProc	SplineSelectNothing
    NearProc	SplineSelectAnchorInternal
    NearProc	SplineSelectSegmentInternal
    NearProc	SplineSelectControlInternal
    NearProc	SplineSelectNothingInternal
    NearProc	SplineSelectNothingInternal

; based on the SplineMode etype 
SplineSelectSegmentCalls 	label word
    NearProc	ErrorStubSSC		; beginner poly create
    NearProc	ErrorStubSSC		; beginner spline create
    NearProc	ErrorStubSSC		; advanced create
    NearProc	SplineSelectSegmentBeginnerEdit  ; beginner edit
    NearProc	SplineSelectSegmentAdvancedEdit ; advanced edit
    NearProc	ErrorStubSSC


.assert ($-SplineSelectSegmentCalls eq SplineMode*2)

SplineSelectCode	ends

SplineUtilCode	segment

; These procedures are called when the spline goes into a new mode.
; Based on the SplineMode etype 
SplineSetModeCalls		label word
    NearProc	SplineCreateMode
    NearProc	SplineCreateMode
    NearProc	SplineCreateMode
    NearProc	SplineBeginnerEditMode
    NearProc	SplineAdvancedEditMode
    NearProc	SplineInactiveMode

.assert ($-SplineSetModeCalls eq SplineMode*2)

SplineLeaveModeCalls		label word
    NearProc	SplineLeaveCreateMode
    NearProc	SplineLeaveBeginnerSplineCreateMode
    NearProc	SplineLeaveCreateMode
    NearProc	SplineLeaveEditMode
    NearProc	SplineLeaveEditMode
    NearProc	StubSUC

.assert ($-SplineLeaveModeCalls eq SplineMode*2)


SplineUtilCode	ends

SplineObjectCode	segment resource

;******************************************************************************
; Data tables for the UNDO stuff 
;******************************************************************************


;
; This table is the value used to start a new UNDO chain when the
; other chain is being UNDONE.  A zero value means that a new undo
; chain has already been created (ie, when REDOING a "delete anchors",
; we send ourselves a MSG_SPLINE_DELETE_ANCHORS, which creates the
; undo chain itself.
;
SplineRedoValues	UndoType	\
	UT_NONE,			; UT_NONE 
	UT_LINE_ATTR,			; UT_LINE_ATTR
	UT_AREA_ATTR,			; UT_AREA_ATTR
	UT_UNDO_MOVE,			; UT_MOVE
	UT_UNDO_MOVE,			; UT_UNDO_MOVE
	UT_UNDO_SUBDIVIDE,		; UT_SUBDIVIDE
	0,				; UT_UNDO_SUBDIVIDE
	UT_UNDO_INSERT_ANCHORS,		; UT_INSERT_ANCHORS
	0,				; UT_UNDO_INSERT_ANCHORS
	UT_UNDO_DELETE_ANCHORS,		; UT_DELETE_ANCHORS
	0,				; UT_UNDO_DELETE_ANCHORS
	0,				; UT_INSERT_CONTROLS
	UT_UNDO_DELETE_CONTROLS,	; UT_DELETE_CONTROLS
	0,				; UT_UNDO_DELETE_CONTROLS
	0,				; UT_ADD_POINT
	0,				; UT_OPEN_CURVE
	0				; UT_CLOSE_CURVE

.assert (size SplineRedoValues eq UndoType)

SplineUndoCalls 	label word
    NearProc	UndoStub			; UT_NONE
    NearProc	SplineUndoLineAttr		; UT_LINE_ATTR
    NearProc	SplineUndoAreaAttr		; UT_AREA_ATTR
    NearProc	SplineUndoMove			; UT_MOVE
    NearProc	SplineUndoMove			; UT_UNDO_MOVE
    NearProc	SplineUndoInsertAnchors		; UT_SUBDIVIDE
    NearProc	SplineRedoSubdivide		; UT_UNDO_SUBDIVIDE
    NearProc	SplineUndoInsertAnchors		; UT_INSERT_ANCHORS
    NearProc	SplineRedoInsertAnchors		; UT_UNDO_INSERT_ANCHORS
    NearProc	SplineUndoDeleteAnchors		; UT_DELETE_ANCHORS
    NearProc	SplineRedoDeleteAnchors		; UT_UNDO_DELETE_CONTROLS
    NearProc	SplineUndoInsertControls	; UT_INSERT_CONTROLS
    NearProc	SplineUndoDeleteControls	; UT_DELETE_CONTROLS
    NearProc	SplineRedoDeleteControls	; UT_UNDO_DELETE_CONTROLS
    NearProc	SplineUndoAddPoint		; UT_ADD_POINT
    NearProc	SplineUndoOpenCurve		; UT_OPEN_CURVE
    NearProc	SplineUndoCloseCurve		; UT_CLOSE_CURVE

.assert ($-SplineUndoCalls eq UndoType)
SplineInitUndoCalls 	label word
    NearProc	UndoError		; UT_NONE
    NearProc	SplineInitUndoLineAttr	; UT_LINE_ATTR
    NearProc	SplineInitUndoAreaAttr	; UT_AREA_ATTR
    NearProc	SplineInitUndoArray	; UT_MOVE
    NearProc	SplineInitUndoStub	; UT_UNDO_MOVE
    NearProc	SplineInitUndoSubdivide	; UT_SUBDIVIDE
    NearProc	SplineInitRedoSubdivide	; UT_UNDO_SUBDIVIDE
    NearProc	SplineInitUndoAndNew	; UT_INSERT_ANCHORS
    NearProc	SplineInitUndoStub	; UT_UNDO_INSERT_ANCHORS
    NearProc	SplineInitUndoAndNew	; UT_DELETE_ANCHORS
    NearProc	SplineInitUndoStub	; UT_UNDO_DELETE_ANCHORS
    NearProc	SplineInitUndoStub	; UT_INSERT_CONTROLS
    NearProc	SplineInitUndoArray	; UT_DELETE_CONTROLS
    NearProc	SplineInitUndoStub	; UT_UNDO_DELETE_CONTROLS
    NearProc	SplineInitUndoArray	; UT_ADD_POINT
    NearProc	SplineInitUndoStub	; UT_OPEN_CURVE
    NearProc	SplineInitUndoStub	; UT_CLOSE_CURVE

.assert ($-SplineInitUndoCalls eq UndoType)



SplineOperateOnUndoCalls 	label word
    NearProc	SplineCopyUndoToPoint
    NearProc	SplineInsertUndoInPoints
    NearProc	SplineAddDeltasToUndoPoint
    NearProc	SplineSelectUndoPoint
    NearProc	SplineExchangeUndoWithPoint
    NearProc	SplineAddUndoToNew

.assert ($-SplineOperateOnUndoCalls eq SplineOperateOnUndoType*2)

UndoStub	proc near
	ret
UndoStub	endp

SplineInitUndoStub	proc	near
	clr	cx
	ret
SplineInitUndoStub	endp

SplineObjectCode	ends

SplineMathCode	segment

; This list is used as a set of initial values for solving the
; point-curve problem.  It goes:
; 0, 1, 1/3, 2/3, 1/2

InitValueList	word	0, 
			0ffffh, 
			5555h,
			0aaaah,
			8000h


; The tangent table is a list of WWFixed values for angles between 0 and
; 89 degrees.  All other values must be found using the appropriate 
; manipulations.

SplineTangentTable 	label word
	WWFix	 0.0000		; tan( 0 )
	WWFix	 0.0175		; tan( 1 )
	WWFix	 0.0349		; tan( 2 )
	WWFix	 0.0524		; tan( 3 )
	WWFix	 0.0699		; tan( 4 )
	WWFix	 0.0875		; tan( 5 )
	WWFix	 0.1051		; tan( 6 )
	WWFix	 0.1228		; tan( 7 )
	WWFix	 0.1405		; tan( 8 )
	WWFix	 0.1584		; tan( 9 )
	WWFix	 0.1763		; tan( 10 )
	WWFix	 0.1944		; tan( 11 )
	WWFix	 0.2126		; tan( 12 )
	WWFix	 0.2309		; tan( 13 )
	WWFix	 0.2493		; tan( 14 )
 	WWFix	 0.2679		; tan( 15 )
	WWFix	 0.2867		; tan( 16 )
	WWFix	 0.3057		; tan( 17 )
	WWFix	 0.3249		; tan( 18 )
	WWFix	 0.3443		; tan( 19 )
	WWFix	 0.3640		; tan( 20 )
	WWFix	 0.3839		; tan( 21 )
	WWFix	 0.4040		; tan( 22 )
	WWFix	 0.4245		; tan( 23 )
	WWFix	 0.4452		; tan( 24 )
	WWFix	 0.4663		; tan( 25 )
	WWFix	 0.4877		; tan( 26 )
	WWFix	 0.5095		; tan( 27 )
	WWFix	 0.5317		; tan( 28 )
	WWFix	 0.5543		; tan( 29 )
	WWFix	 0.5774		; tan( 30 )
	WWFix	 0.6009		; tan( 31 )
	WWFix	 0.6249		; tan( 32 )
	WWFix	 0.6494		; tan( 33 )
	WWFix	 0.6745		; tan( 34 )
	WWFix	 0.7002		; tan( 35 )
	WWFix	 0.7265		; tan( 36 )
	WWFix	 0.7536		; tan( 37 )
	WWFix	 0.7813		; tan( 38 )
	WWFix	 0.8098		; tan( 39 )
	WWFix	 0.8391		; tan( 40 )
	WWFix	 0.8693		; tan( 41 )
	WWFix	 0.9004		; tan( 42 )
	WWFix	 0.9325		; tan( 43 )
	WWFix	 0.9657		; tan( 44 )
	WWFix	 1.0000		; tan( 45 )
	WWFix	 1.0355		; tan( 46 )
	WWFix	 1.0724		; tan( 47 )
	WWFix	 1.1106		; tan( 48 )
	WWFix	 1.1504		; tan( 49 )
	WWFix	 1.1918		; tan( 50 )
	WWFix	 1.2349		; tan( 51 )
	WWFix	 1.2799		; tan( 52 )
	WWFix	 1.3270		; tan( 53 )
	WWFix	 1.3764		; tan( 54 )
	WWFix	 1.4281		; tan( 55 )
	WWFix	 1.4826		; tan( 56 )
	WWFix	 1.5399		; tan( 57 )
	WWFix	 1.6003		; tan( 58 )
	WWFix	 1.6643		; tan( 59 )
	WWFix	 1.7321		; tan( 60 )
	WWFix	 1.8040		; tan( 61 )
	WWFix	 1.8807		; tan( 62 )
	WWFix	 1.9626		; tan( 63 )
	WWFix	 2.0503		; tan( 64 )
	WWFix	 2.1445		; tan( 65 )
	WWFix	 2.2460		; tan( 66 )
	WWFix	 2.3559		; tan( 67 )
	WWFix	 2.4751		; tan( 68 )
	WWFix	 2.6051		; tan( 69 )
	WWFix	 2.7475		; tan( 70 )
	WWFix	 2.9042		; tan( 71 )
	WWFix	 3.0777		; tan( 72 )
	WWFix	 3.2709		; tan( 73 )
	WWFix	 3.4874		; tan( 74 )
	WWFix	 3.7320		; tan( 75 )
	WWFix	 4.0108		; tan( 76 )
	WWFix	 4.3315		; tan( 77 )
	WWFix	 4.7046		; tan( 78 )
	WWFix	 5.1446		; tan( 79 )
	WWFix	 5.6713		; tan( 80 )
	WWFix	 6.3138		; tan( 81 )
	WWFix	 7.1154		; tan( 82 )
	WWFix	 8.1443		; tan( 83 )
	WWFix	 9.5144		; tan( 84 )
	WWFix	11.4300		; tan( 85 )
	WWFix	14.3006		; tan( 86 )
	WWFix	19.0811		; tan( 87 )
	WWFix	28.6363		; tan( 88 )
	WWFix	57.2900		; tan( 89 )

			
SplineMathCode	ends

.warn +unreach






