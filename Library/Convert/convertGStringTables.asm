COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert Library
FILE:		convertGStringTables.asm

AUTHOR:		Jim DeFrisco, Oct 12, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/12/92	Initial revision

DESCRIPTION:
	Tables used by the code in convertGString.asm	
		

	$Id: convertGStringTables.asm,v 1.1 97/04/04 17:52:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GStringCode	segment	resource

PlayElemTable	label	nptr.near
			; codes 0-9

		dw	offset PEEndString	; GR_END_STRING
		dw	offset PEComment	; GR_COMMENT
		dw	offset PENoArgs		; GR_NULL_OP
		dw	offset PEComment	; GR_ESCAPE
		dw	offset PENoArgs		; GR_SAVE_STATE
		dw	offset PENoArgs		; GR_RESTORE_STATE
		dw	offset PENoArgs		; GR_NEW_PAGE
		dw	offset PERotate		; GR_APPLY_ROTATION=5
		dw	offset PETransScale	; GR_APPLY_SCALE
		dw	offset PETransScale	; GR_APPLY_TRANSLATION

			; codes 10-19

		dw	offset PETMatrix	; GR_SET_TRANSFORM
		dw	offset PETMatrix	; GR_APPLY_TRANSFORM
		dw	offset PENoArgs		; GR_SET_NULL_TRANSFORM
		dw	offset PETwoCoords 	; GR_DRAW_LINE=11
		dw	offset PEOneCoordTo 	; GR_DRAW_LINE_TO
		dw	offset PETwoCoords 	; GR_DRAW_RECT
		dw	offset PEOneCoordTo	; GR_DRAW_RECT_TO
		dw	offset PEDrawHalfLine 	; GR_DRAW_HLINE
		dw	offset PEDrawHalfLine	; GR_DRAW_HLINE_TO
		dw	offset PEDrawHalfLine	; GR_DRAW_VLINE

			; codes 20-29

		dw	offset PEDrawHalfLine 	; GR_DRAW_VLINE_TO
		dw	offset PEError		; GR_DRAW_ROUND_RECT
		dw	offset PEError		; GR_DRAW_ROUND_RECT_TO
		dw	offset PEOneCoord 	; GR_DRAW_POINT=21
		dw	offset PENoArgs		; GR_DRAW_POINT_CP
		dw	offset PEBitmap		; GR_DRAW_BITMAP
		dw	offset PEBitmap		; GR_DRAW_BITMAP_CP
		dw	offset PEDataPtr    	; GR_DRAW_BITMAP_PTR
		dw	offset PEDataOptr    	; GR_DRAW_BITMAP_OPTR
		dw	offset PEDrawChar 	; GR_DRAW_CHAR

			; codes 30-39

		dw	offset PEDrawChar	; GR_DRAW_CHAR_CP
		dw	offset PEDrawText 	; GR_DRAW_TEXT
		dw	offset PEDrawText	; GR_DRAW_TEXT_CP
		dw	offset PETextField    	; GR_DRAW_TEXT_FIELD 
		dw	offset PEDataPtr	; GR_DRAW_TEXT_PTR
		dw	offset PEPolyCoord	; GR_DRAW_POLYLINE=31
		dw	offset PETwoCoords	; GR_DRAW_ELLIPSE
		dw	offset PEError		; GR_DRAW_ARC
		dw	offset PEPolyCoord	; GR_DRAW_SPLINE
		dw	offset PEPolyCoord	; GR_DRAW_POLYGON

			; codes 40-49

		dw	offset PETwoCoords	; GR_FILL_RECT
		dw	offset PEOneCoordTo 	; GR_FILL_RECT_TO
		dw	offset PEError		; GR_FILL_ROUND_RECT
		dw	offset PEError		; GR_FILL_ROUND_RECT_TO
		dw	offset PEError		; GR_FILL_ARC
		dw	offset PEPolyCoord	; GR_FILL_POLYGON
		dw	offset PETwoCoords 	; GR_FILL_ELLIPSE=41
		dw	offset PEByteAttr	; GR_SET_DRAW_MODE
		dw	offset PEOneCoord 	; GR_REL_MOVE_TO
		dw	offset PEOneCoord 	; GR_MOVE_TO

			; codes 50-59

		dw	offset PE3ByteAttr	; GR_SET_LINE_COLOR
		dw	offset PEByteAttr	; GR_SET_LINE_MASK
		dw	offset PEByteAttr	; GR_SET_LINE_COLOR_MAP
		dw	offset PELineWidth	; GR_SET_LINE_WIDTH
		dw	offset PEByteAttr	; GR_SET_LINE_JOIN
		dw	offset PEByteAttr	; GR_SET_LINE_END
		dw	offset PELineAttr	; GR_SET_LINE_ATTR
		dw	offset PEDWordAttr	; GR_SET_MITER_LIMIT
		dw	offset PELineStyle	; GR_SET_LINE_STYLE=53
		dw	offset PE3ByteAttr	; GR_SET_AREA_COLOR

			; codes 60-69

		dw	offset PEByteAttr	; GR_SET_AREA_MASK
		dw	offset PEByteAttr	; GR_SET_AREA_COLOR_MAP
		dw	offset PEAreaAttr	; GR_SET_AREA_ATTR=57
		dw	offset PE3ByteAttr	; GR_SET_TEXT_COLOR
		dw	offset PEByteAttr	; GR_SET_TEXT_MASK
		dw	offset PEByteAttr	; GR_SET_TEXT_COLOR_MAP
		dw	offset PEWordAttr	; GR_SET_TEXT_STYLE
		dw	offset PEWordAttr	; GR_SET_TEXT_MODE
		dw	offset PESpacePad	; GR_SET_TEXT_SPACE_PAD
		dw	offset PETextAttr	; GR_SET_TEXT_ATTR

			; codes 70-79

		dw	offset PESetFont	; GR_SET_FONT=65
		dw	offset PENoArgs    	; GR_SET_STRING_BOUNDS
		dw	offset PEWordAttr    	; GR_CREATE_PALETTE 
		dw	offset PEWordAttr    	; GR_DESTROY_PALETTE 
		dw	offset PEWordAttr    	; GR_SET_PALETTE_ENTRY 
		dw	offset PEWordAttr    	; GR_SET_PALETTE 
		dw	offset PELineWidth	; GR_SET_BORDER_WIDTH
		dw	offset PEByteAttr	; GR_SET_BORDER_JOIN
		dw	offset PEByteAttr    	; GR_SET_LINE_COLOR_INDEX
		dw	offset PECustomMask	; GR_SET_CUSTOM_LINE_MASK

			; codes 80-87

		dw	offset PEByteAttr	; GR_SET_AREA_COLOR_INDEX
		dw	offset PECustomMask	; GR_SET_CUSTOM_AREA_MASK
		dw	offset PEByteAttr	; GR_SET_TEXT_COLOR_INDEX
		dw	offset PECustomMask	; GR_SET_CUSTOM_TEXT_MASK=72
		dw	offset PECustomStyle	; GR_SET_CUSTOM_LINE_STYLE
		dw	offset PEWordAttr	; GR_SET_TRACK_KERN
		dw	offset PENoArgs		; GR_INIT_DEFAULT_TRANSFORM
		dw	offset PENoArgs		; GR_SET_DEFAULT_TRANSFORM
		dw	offset PEClipRect	; GR_SET_CLIP_RECT
		dw	offset PEClipRect	; GR_SET_DOC_CLIP_RECT


KernRoutTable	label	fptr.far
		fptr	GrEndGString		; GR_END_STRING
		fptr	GrComment		; GR_COMMENT
		fptr	GrComment		; GR_NULL_OP
		fptr	GrEscape		; GR_ESCAPE
		fptr	GrSaveState		; GR_SAVE_STATE
		fptr	GrRestoreState		; GR_RESTORE_STATE
		fptr	GrNewPage		; GR_NEW_PAGE
		fptr	GrApplyRotation		; GR_APPLY_ROTATION=5
		fptr	GrApplyScale		; GR_APPLY_SCALE
		fptr	GrApplyTranslation	; GR_APPLY_TRANSLATION

			; codes 10-19

		fptr	GrSetTransform		; GR_SET_TRANSFORM
		fptr	GrApplyTransform	; GR_APPLY_TRANSFORM
		fptr	GrSetNullTransform		; GR_SET_NULL_TRANSFORM
		fptr	GrDrawLine	 	; GR_DRAW_LINE=11
		fptr	GrDrawLineTo	 	; GR_DRAW_LINE_TO
		fptr	GrDrawRect	 	; GR_DRAW_RECT
		fptr	GrDrawRectTo		; GR_DRAW_RECT_TO
		fptr	GrDrawHLine 		; GR_DRAW_HLINE
		fptr	GrDrawHLineTo		; GR_DRAW_HLINE_TO
		fptr	GrDrawVLine		; GR_DRAW_VLINE

			; codes 20-29

		fptr	GrDrawVLineTo	 	; GR_DRAW_VLINE_TO
		fptr	GrDrawRect		; GR_DRAW_ROUND_RECT
		fptr	GrDrawRect		; GR_DRAW_ROUND_RECT_TO
		fptr	GrDrawPoint 		; GR_DRAW_POINT=21
		fptr	GrDrawPointAtCP		; GR_DRAW_POINT_CP
		fptr	GrDrawBitmap		; GR_DRAW_BITMAP
		fptr	GrDrawBitmapAtCP	; GR_DRAW_BITMAP_CP
		fptr	GrDrawBitmap    	; GR_DRAW_BITMAP_PTR
		fptr	GrDrawBitmap    	; GR_DRAW_BITMAP_OPTR
		fptr	GrDrawChar	 	; GR_DRAW_CHAR

			; codes 30-39

		fptr	GrDrawCharAtCP		; GR_DRAW_CHAR_CP
		fptr	GrDrawText	 	; GR_DRAW_TEXT
		fptr	GrDrawTextAtCP		; GR_DRAW_TEXT_CP
		fptr	GrDrawTextField   	; GR_DRAW_TEXT_FIELD 
		fptr	GrDrawText		; GR_DRAW_TEXT_PTR
		fptr	GrDrawPolyline		; GR_DRAW_POLYLINE=31
		fptr	GrDrawEllipse		; GR_DRAW_ELLIPSE
		fptr	GrDrawRect		; GR_DRAW_ARC
		fptr	GrDrawSpline		; GR_DRAW_SPLINE
		fptr	GrDrawPolygon		; GR_DRAW_POLYGON

			; codes 40-49

		fptr	GrFillRect		; GR_FILL_RECT
		fptr	GrFillRectTo	 	; GR_FILL_RECT_TO
		fptr	GrFillRect		; GR_FILL_ROUND_RECT
		fptr	GrFillRect		; GR_FILL_ROUND_RECT_TO
		fptr	GrFillRect		; GR_FILL_ARC
		fptr	GrFillPolygon		; GR_FILL_POLYGON
		fptr	GrFillEllipse	 	; GR_FILL_ELLIPSE=41
		fptr	GrSetMixMode		; GR_SET_DRAW_MODE
		fptr	GrRelMoveTo		; GR_REL_MOVE_TO
		fptr	GrMoveTo	 	; GR_MOVE_TO

			; codes 50-59

		fptr	GrSetLineColor		; GR_SET_LINE_COLOR
		fptr	GrSetLineMask		; GR_SET_LINE_MASK
		fptr	GrSetLineColorMap	; GR_SET_LINE_COLOR_MAP
		fptr	GrSetLineWidth		; GR_SET_LINE_WIDTH
		fptr	GrSetLineJoin		; GR_SET_LINE_JOIN
		fptr	GrSetLineEnd		; GR_SET_LINE_END
		fptr	GrSetLineAttr		; GR_SET_LINE_ATTR
		fptr	GrSetMiterLimit		; GR_SET_MITER_LIMIT
		fptr	GrSetLineStyle		; GR_SET_LINE_STYLE=53
		fptr	GrSetAreaColor		; GR_SET_AREA_COLOR

			; codes 60-69

		fptr	GrSetAreaMask		; GR_SET_AREA_MASK
		fptr	GrSetAreaColorMap	; GR_SET_AREA_COLOR_MAP
		fptr	GrSetAreaAttr		; GR_SET_AREA_ATTR=57
		fptr	GrSetTextColor		; GR_SET_TEXT_COLOR
		fptr	GrSetTextMask		; GR_SET_TEXT_MASK
		fptr	GrSetTextColorMap	; GR_SET_TEXT_COLOR_MAP
		fptr	GrSetTextStyle		; GR_SET_TEXT_STYLE
		fptr	GrSetTextMode		; GR_SET_TEXT_MODE
		fptr	GrSetTextSpacePad	; GR_SET_TEXT_SPACE_PAD
		fptr	GrSetTextAttr		; GR_SET_TEXT_ATTR

			; codes 70-79

		fptr	GrSetFont		; GR_SET_FONT=65
		fptr	GrSetGStringBounds    	; GR_SET_STRING_BOUNDS
		fptr	GrCreatePalette    	; GR_CREATE_PALETTE 
		fptr	GrDestroyPalette    	; GR_DESTROY_PALETTE 
		fptr	GrSetPaletteEntry   	; GR_SET_PALETTE_ENTRY 
		fptr	GrSetPalette    	; GR_SET_PALETTE 
		fptr	GrSetLineWidth		; GR_SET_BORDER_WIDTH
		fptr	GrSetLineJoin		; GR_SET_BORDER_JOIN
		fptr	GrSetLineColor		; GR_SET_LINE_COLOR_INDEX
		fptr	GrSetLineMask		; GR_SET_CUSTOM_LINE_MASK

			; codes 80-87

		fptr	GrSetAreaColor		; GR_SET_AREA_COLOR_INDEX
		fptr	GrSetAreaMask		; GR_SET_CUSTOM_AREA_MASK
		fptr	GrSetTextColor		; GR_SET_TEXT_COLOR_INDEX
		fptr	GrSetTextMask		; GR_SET_CUSTOM_TEXT_MASK=72
		fptr	GrSetLineStyle		; GR_SET_CUSTOM_LINE_STYLE
		fptr	GrSetTrackKern		; GR_SET_TRACK_KERN
		fptr	GrInitDefaultTransform	; GR_INIT_DEFAULT_TRANSFORM
		fptr	GrSetDefaultTransform	; GR_SET_DEFAULT_TRANSFORM
		fptr	GrSetClipRect		; GR_SET_CLIP_RECT
		fptr	GrSetWinClipRect	; GR_SET_DOC_CLIP_RECT


combineTable	label	PathCombineType
		word	0, PCT_NULL, 0, PCT_NULL
		word	PCT_REPLACE, PCT_REPLACE, PCT_REPLACE, PCT_REPLACE


GStringCode	ends
