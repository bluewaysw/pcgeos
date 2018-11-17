
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportTables.asm

AUTHOR:		Jim DeFrisco, 21 Feb 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This file contains various data tables needed by the Export module.
		

	$Id: exportTables.asm,v 1.1 97/04/07 11:25:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource

;-------------------------------------------------------------------------
;		Output element emit routine table
;-------------------------------------------------------------------------

		; table of extraction routines
emitRouts	label	nptr
		nptr	offset ExportCode:EmitDrawLine	  ; DrawLine
		nptr	offset ExportCode:EmitDrawLineTo  ; DrawLineTo
		nptr	offset ExportCode:EmitDrawLineTo  ; DrawRelLineTo
		nptr	offset ExportCode:EmitDrawLine	  ; DrawHLine
		nptr	offset ExportCode:EmitDrawLineTo  ; DrawHLineTo
		nptr	offset ExportCode:EmitDrawLine	  ; DrawVLine
		nptr	offset ExportCode:EmitDrawLineTo  ; DrawVLineTo
		nptr	offset ExportCode:EmitPolyline	  ; DrawPolyline
		nptr	offset ExportCode:EmitDrawArc	  ; Arc
		nptr	offset ExportCode:EmitDrawArc	  ; Arc3Point
		nptr	offset ExportCode:EmitDrawArc	  ; Arc3PtTo
		nptr	offset ExportCode:EmitDrawArc	  ; RelArc3PtTo
		nptr	offset ExportCode:EmitDrawRect	  ; DrawRect
		nptr	offset ExportCode:EmitDrawRect	  ; DrawRectTo
		nptr	offset ExportCode:EmitDrawRoundRect ; DrawRRect
		nptr	offset ExportCode:EmitDrawRoundRect ; DrawRRectTo
		nptr	offset ExportCode:EmitPolyline	  ; Spline
		nptr	offset ExportCode:EmitPolyline	  ; SplineTo
		nptr	offset ExportCode:EmitCurve	  ; Curve
		nptr	offset ExportCode:EmitCurve	  ; CurveTo
		nptr	offset ExportCode:EmitCurve	  ; RelCurveTo
		nptr	offset ExportCode:EmitDrawEllipse ; DrawEllipse
		nptr	offset ExportCode:EmitPolyline	  ; DrawPolygon
		nptr	offset ExportCode:EmitFillRect    ; DrawPoint
		nptr	offset ExportCode:EmitFillRect	  ; DrawPointCP
		nptr	offset ExportCode:EmitPolyline    ; BrushPolyline
		nptr	offset ExportCode:EmitTextStub	  ; DrawChar
		nptr	offset ExportCode:EmitTextStub	  ; DrawCharCP
		nptr	offset ExportCode:EmitTextStub	  ; DrawText
		nptr	offset ExportCode:EmitTextStub	  ; DrawTextCP
		nptr	offset ExportCode:EmitTextFieldStub ; DrawTextField
		nptr	offset ExportCode:EmitNothing		; DrawTextPtr
		nptr	offset ExportCode:EmitNothing		; DrawTextOPtr
		nptr	offset ExportCode:EmitDrawPath	  ; DrawPath 
		nptr	offset ExportCode:EmitFillRect	  ; FillRect
		nptr	offset ExportCode:EmitFillRect	  ; FillRectTo
		nptr	offset ExportCode:EmitFillRoundRect ; FillRRect
		nptr	offset ExportCode:EmitFillRoundRect ; FillRRectTo
		nptr	offset ExportCode:EmitFillArc	  ; FillArc
		nptr	offset ExportCode:EmitPolygon	  ; FillPolygon
		nptr	offset ExportCode:EmitFillEllipse ; FillEllipse
		nptr	offset ExportCode:EmitFillPath	  ; FillPath 
		nptr	offset ExportCode:EmitFillArc	  ; FillArc3Pt
		nptr	offset ExportCode:EmitFillArc	  ; FillArc3PtTo
		nptr	offset ExportCode:EmitBitmapStub  ; FillBitmap
		nptr	offset ExportCode:EmitBitmapStub  ; FillBitmapCP
		nptr	offset ExportCode:EmitNothing		; FillBitmpOPtr
		nptr	offset ExportCode:EmitNothing	  	; FillBitmapPtr
		nptr	offset ExportCode:EmitBitmapStub  ; DrawBitmap
		nptr	offset ExportCode:EmitBitmapStub  ; DrawBitmapCP
		nptr	offset ExportCode:EmitNothing		;DrawBitmapOPtr
		nptr	offset ExportCode:EmitNothing		; DrawBitmapPtr

ExportCode	ends

ExportPath	segment	resource

;-------------------------------------------------------------------------
;		Path contruction code snippets
;-------------------------------------------------------------------------

		; table of extraction routines
pathRouts	label	nptr
		nptr	offset ExportPath:PathLine	; DrawLine
		nptr	offset ExportPath:PathLineTo  	; DrawLineTo
		nptr	offset ExportPath:PathLineTo  	; DrawRelLineTo
		nptr	offset ExportPath:PathLine	; DrawHLine
		nptr	offset ExportPath:PathLineTo  	; DrawHLineTo
		nptr	offset ExportPath:PathLine	; DrawVLine
		nptr	offset ExportPath:PathLineTo  	; DrawVLineTo
		nptr	offset ExportPath:PathPolyline	; DrawPolyline
		nptr	offset ExportPath:PathArc	; Arc
		nptr	offset ExportPath:PathArc	; Arc3Point
		nptr	offset ExportPath:PathArc	; Arc3PtTo
		nptr	offset ExportPath:PathArc	; RelArc3PtTo
		nptr	offset ExportPath:PathRect	; DrawRect
		nptr	offset ExportPath:PathRect	; DrawRectTo
		nptr	offset ExportPath:PathRoundRect ; DrawRRect
		nptr	offset ExportPath:PathRoundRect ; DrawRRectTo
		nptr	offset ExportPath:PathPolyline	; Spline
		nptr	offset ExportPath:PathPolyline	; SplineTo
		nptr	offset ExportPath:PathCurve	; Curve
		nptr	offset ExportPath:PathCurve	; CurveTo
		nptr	offset ExportPath:PathCurve	; RelCurveTo
		nptr	offset ExportPath:PathEllipse 	; DrawEllipse
		nptr	offset ExportPath:PathPolyline	; DrawPolygon
		nptr	offset ExportPath:PathRect	; DrawPoint
		nptr	offset ExportPath:PathRect	; DrawPointCP
		nptr	offset ExportPath:PathPolyline  ; BrushPolyline
		nptr	offset ExportPath:PathTextStub	; DrawChar
		nptr	offset ExportPath:PathTextStub	; DrawCharCP
		nptr	offset ExportPath:PathTextStub	; DrawText
		nptr	offset ExportPath:PathTextStub	; DrawTextCP
		nptr	offset ExportPath:PathTextFieldStub ; DrawTextField
		nptr	offset ExportPath:PathNothing	; DrawTextPtr

ExportPath	ends

;-------------------------------------------------------------------------
;		Output element object name table
;-------------------------------------------------------------------------

ExportUtils	segment	resource

;objectNameList	label	nptr
		nptr	offset PSCode:lineObject	; DrawLine
		nptr	offset PSCode:lineObject	; DrawLineTo
		nptr	offset PSCode:lineObject	; DrawRelLineTo
		nptr	offset PSCode:lineObject	; DrawHLine
		nptr	offset PSCode:lineObject	; DrawHLineTo
		nptr	offset PSCode:lineObject	; DrawVLine
		nptr	offset PSCode:lineObject	; DrawVLineTo
		nptr	offset PSCode:lineObject	; DrawPolyline
		nptr	offset PSCode:lineObject	; DrawArc
		nptr	offset PSCode:lineObject	; DrawArc3Pt
		nptr	offset PSCode:lineObject	; DrawArc3PtTo
		nptr	offset PSCode:lineObject	; DrawRelArc3PtTo
		nptr	offset PSCode:lineObject	; DrawRect
		nptr	offset PSCode:lineObject	; DrawRectTo
		nptr	offset PSCode:lineObject	; DrawRRect
		nptr	offset PSCode:lineObject	; DrawRRectTo
		nptr	offset PSCode:lineObject	; DrawSpline
		nptr	offset PSCode:lineObject	; DrawSplineTo
		nptr	offset PSCode:lineObject	; DrawCurve
		nptr	offset PSCode:lineObject	; DrawCurveTo
		nptr	offset PSCode:lineObject	; DrawRelCurveTo
		nptr	offset PSCode:lineObject	; DrawEllipse
		nptr	offset PSCode:lineObject	; DrawPolygon
		nptr	offset PSCode:areaObject	; DrawPoint
		nptr	offset PSCode:areaObject	; DrawPointCP
		nptr	offset PSCode:lineObject	; BrushPolyline
		nptr	offset PSCode:textObject	; DrawChar
		nptr	offset PSCode:textObject	; DrawCharCP
		nptr	offset PSCode:textObject	; DrawText
		nptr	offset PSCode:textObject	; DrawTextCP
		nptr	offset PSCode:textObject	; DrawTextField
		nptr	offset PSCode:textObject	; DrawTextPtr
		nptr	offset PSCode:textObject	; DrawTextOPtr
		nptr	offset PSCode:lineObject	; DrawPath
		nptr	offset PSCode:areaObject	; FillRect
		nptr	offset PSCode:areaObject	; FillRectTo
		nptr	offset PSCode:areaObject	; FillRRectTo
		nptr	offset PSCode:areaObject	; FillRRectTo
		nptr	offset PSCode:areaObject	; FillArc
		nptr	offset PSCode:areaObject	; FillPolygon
		nptr	offset PSCode:areaObject	; FillEllipse
		nptr	offset PSCode:areaObject	; FillPath
		nptr	offset PSCode:areaObject	; FillArc3Pt
		nptr	offset PSCode:areaObject	; FillArc3PtTo
		nptr	offset PSCode:bitmapObject	; FillBitmap
		nptr	offset PSCode:bitmapObject	; FillBitmapCP
		nptr	offset PSCode:bitmapObject	; FillBitmapOPtr
		nptr	offset PSCode:bitmapObject	; FillBitmapPtr
		nptr	offset PSCode:bitmapObject	; DrawBitmap
		nptr	offset PSCode:bitmapObject	; DrawBitmapCP
		nptr	offset PSCode:bitmapObject	; DrawBitmapOPtr
		nptr	offset PSCode:bitmapObject	; DrawBitmapPtr

ExportUtils	ends
