COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		cond.asm

AUTHOR:		Adam de Boor, Sep  6, 1989

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 6/89		Initial revision


DESCRIPTION:
	This file is designed to test the conditional assembly facilities
	in Esp
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

biff	segment


if @CurSeg eq biff
   %out segment compare worked
endif
foop	proc	far
	ret
foop	endp

morf	proc	far
	ret
.assert	TYPE @CurProc eq TYPE foop

ifidn @CurProc, <morf>
	%out idn of CurProc worked
endif

morf	endp

check	macro	stmt
stmt
	%out stmt worked
else
	%out stmt didn't work
endif
	endm

check	<if 1>
check	<ife 0>
check	<ifb <>>
check	<ifnb <hick>>
check	<ifdef morf>
check	<ifndef whiffle>

GStringElements	etype byte, 0, 1

GraphicsSym	macro	routine, constant
	global	routine:far
constant	enum	GStringElements
endm

GraphicsSym	GrDrawLine, 		GR_DRAW_LINE
GraphicsSym	GrPolyLine, 		GR_POLY_LINE
GraphicsSym	GrFillPolygon, 		GR_FILL_POLY
GraphicsSym	GrFillEllipse, 		GR_FILL_ELPS
GraphicsSym	GrDrawEllipse,		GR_DRAW_ELPS
GraphicsSym	GrDrawPixel, 		GR_DRAW_PIXEL
GraphicsSym	GrHorizLine, 		GR_HORIZ_LINE
GraphicsSym	GrVertLine, 		GR_VERT_LINE
GraphicsSym	GrDrawRect, 		GR_DRAW_RECT
GraphicsSym	GrDrawFrame, 		GR_DRAW_FRAME
GraphicsSym	GrDrawBitmap, 		GR_DRAW_BITMAP

GraphicsSym	GrPutChar, 		GR_PUT_CHAR
GraphicsSym	GrPutCharAt,		GR_PUT_CHAR_AT
GraphicsSym	GrPutString, 		GR_PUT_STRING
GraphicsSym	GrPutStringAt,		GR_PUT_STRING_AT

GraphicsSym	GrSetFont,		GR_SET_FONT

GraphicsSym	GrSetLineColor,		GR_SET_LINE_COLOR
GraphicsSym	GrSetAreaColor, 	GR_SET_AREA_COLOR
GraphicsSym	GrSetTextColor, 	GR_SET_TEXT_COLOR

GraphicsSym	GrSetLineDrawMask,	GR_SET_LINE_DRAW_MASK
GraphicsSym	GrSetAreaDrawMask,	GR_SET_AREA_DRAW_MASK
GraphicsSym	GrSetTextDrawMask,	GR_SET_TEXT_DRAW_MASK

GraphicsSym	GrSetLineColorMapMode,	GR_SET_LINE_COLOR_MAP_MODE
GraphicsSym	GrSetAreaColorMapMode,	GR_SET_AREA_COLOR_MAP_MODE
GraphicsSym	GrSetTextColorMapMode,	GR_SET_TEXT_COLOR_MAP_MODE

GraphicsSym	GrSetTextStyle, 	GR_SET_TEXT_STYLE
GraphicsSym	GrSetTextMode,		GR_SET_TEXT_MODE

GraphicsSym	GrSetTextSpacePad,	GR_SET_TEXT_SPACE_PAD

GraphicsSym	GrSetDrawMode, 		GR_SET_DRAW_MODE
GraphicsSym	GrSetPenPos, 		GR_SET_PEN_POS

GraphicsSym	GrDraw,			GR_DRAW
GraphicsSym	GrTerminateStr		GR_TERMINATE_STR
GraphicsSym	GrComment	        GR_COMMENT

GraphicsSym	GrDrawBitmapAt,		GR_DRAW_BITMAP_AT
GraphicsSym	GrDrawRectAt,		GR_DRAW_RECT_AT
GraphicsSym	GrSetRelPenPos,		GR_SET_REL_PEN_POS
GraphicsSym	GrSaveState,		GR_SAVE_STATE
GraphicsSym	GrRestoreState,		GR_RESTORE_STATE
GraphicsSym	GrDrawArc,		GR_DRAW_ARC
GraphicsSym	GrFillArc,		GR_FILL_ARC

COMMENT @---------------------------------------------------------------------

	DrawGStr	type,arg0,arg1,arg2,arg3

	FUNCTION:
		Creates a graphics string in a data segment, in PC GEOS
		format.
	ARGUMENTS:
		One of the following:  (curly brackets mean if appropriate) 
			GR_DRAW_PIXEL, xcoord, ycoord, color
			GR_HORIZ_LINE, left, ycoord, right
			GR_VERT_LINE,  xcoord, top, bottom
			GR_DRAW_RECT,  left, top, right, bottom
			GR_DRAW_RECT_AT, width,height
			GR_DRAW_FRAME, left, top, right, bottom 
			GR_PUT_CHAR,   xcoord, ycoord, char
			GR_PUT_STRING, xcoord, ycoord, maxchars, <string>
			GR_SET_LINE_COLOR, color {, color2}
			GR_SET_AREA_COLOR, color {, color2}
			GR_SET_TEXT_COLOR, color {, color2}
			GR_SET_LINE_DRAW_MASK, pattern {, patternBytes}
			GR_SET_AREA_DRAW_MASK, pattern {, patternBytes}
			GR_SET_LINE_COLOR_MAP_MODE, mode
			GR_SET_AREA_COLOR_MAP_MODE, mode
			GR_SET_TEXT_COLOR_MAP_MODE, mode
			GR_SET_DRAW_MODE, mode
			GR_DRAW_STRING, address, numArgs {,ax,bx,cx,dx}
			GR_SET_PEN_POS, xcoord, ycoord
			GR_SET_REL_PEN_POS, xoffset, yoffset
			GR_SET_SYS_FONT 
			GR_SET_FONT, fontID, fontSize
			GR_SET_TEXT_STYLE, flags
			GR_SET_TEXT_MODE, flags
			GR_PUT_CHAR_AT, char
			GR_PUT_STRING_AT, <string>
			GR_COMMENT, <string>
	(for bitmaps, define outside GRString)	
	Example:
		DGStr GR_DRAW_BITMAP xpos,ypos,EndBM-StartBM
		StartBM:
			Bitmap <width,height,1,1,0,0>
			db	...		;BM data
		EndBM:

			GR_DRAW_BITMAP, xpos,ypos, bitmap size
			GR_DRAW_BITMAP_AT, bitmap size
			GR_SAVE_STATE		(No parms)
			GR_RESTORE_STATE	(No parms)
			GR_ARC			(?)
			GR_PIE			(?)
			GR_TERMINATE_STR	
	NOTES:
		To add a new graphics routine, just add a conditional that
		checks for the routine's graphics string constant and stores
		the right size (word/byte/string) and number of arguments.
		
------------------------------------------------------------------------------@
DGStr	macro	type, arg0, arg1, arg2, arg3, arg4
	local	endOfStuff		
ifidn	<type>, <GR_TERMINATE_STR>
	dw	0
elseifidn	<type>,<GR_DRAW_BITMAP>
	dw	arg2+endOfStuff-$
	db	type
elseifidn	<type>,<GR_DRAW_BITMAP_AT>
	dw	arg2+endOfStuff-$
	db	type
else
	dw	endOfStuff-$		;length
	db	type			;store the type
endif
	
ifidn	<type>, <GR_DRAW_PIXEL>
	dw	arg0, arg1, arg2
elseifidn	<type>, <GR_HORIZ_LINE>
	dw	arg0, arg1, arg2
elseifidn	<type>, <GR_VERT_LINE>
	dw	arg0, arg1, arg2
elseifidn	<type>, <GR_DRAW_RECT_AT>
	dw	arg0,arg1
elseifidn	<type>, <GR_DRAW_RECT>
 	dw	arg0, arg1, arg2, arg3	
elseifidn	<type>, <GR_DRAW_FRAME>
	dw	arg0, arg1, arg2, arg3	
elseifidn	<type>, <GR_PUT_CHAR>
	dw	arg0, arg1
	db	arg2
elseifidn	<type>, <GR_PUT_STRING>
	dw	arg0, arg1, arg2
	db	arg3, 0
elseifidn	<type>, <GR_SET_LINE_COLOR>
	dw	arg0	
 	if (arg0 and 8000h)
	    	 dw 	arg1
        endif		
elseifidn	<type>, <GR_SET_AREA_COLOR>
	dw	arg0	
 	if (arg0 and 8000h)
	    	 dw 	arg1
        endif		
elseifidn	<type>, <GR_SET_TEXT_COLOR>
	dw	arg0	
 	if (arg0 and 8000h)
	    	 dw 	arg1
        endif		
elseifidn	<type>, <GR_SET_LINE_DRAW_MASK>
	db	arg0	
elseifidn	<type>, <GR_SET_AREA_DRAW_MASK>
	db	arg0	
elseifidn	<type>, <GR_SET_LINE_COLOR_MAP_MODE>
	db	arg0	
elseifidn	<type>, <GR_SET_AREA_COLOR_MAP_MODE>
	db	arg0	
elseifidn	<type>, <GR_SET_TEXT_COLOR_MAP_MODE>
	db	arg0	
elseifidn	<type>, <GR_SET_FONT>
        dw	arg0, arg1
elseifidn	<type>, <GR_SET_TEXT_STYLE>
	dw	arg0
elseifidn	<type>, <GR_SET_TEXT_MODE>
	dw	arg0
elseifidn	<type>, <GR_SET_DRAW_MODE>
	db	arg0	
elseifidn	<type>, <GR_DRAW_STRING>
   	dw	arg0
	if (arg1 gt 0)
		dw     	arg2
	endif
	if (arg1 gt 1)		
		dw	arg3
	endif
	if (arg1 gt 2)
		dw	arg4
	endif
	if (arg1 gt 3)
		dw	arg5
	endif
elseifidn	<type>, <GR_SET_PEN_POS>
	dw	arg0, arg1
elseifidn	<type>, <GR_SET_REL_PEN_POS>
	dw	arg0, arg1
elseifidn	<type>, <GR_COMMENT>
	db	arg0, 0
elseifidn	<type>, <GR_PUT_CHAR_AT>
     	db	arg0
elseifidn	<type>, <GR_DRAW_BITMAP>
	dw	arg0,arg1
elseifidn	<type>, <GR_RESTORE_STATE>
elseifidn	<type>, <GR_SAVE_STATE>
elseifidn	<type>, <GR_DRAW_BITMAP_AT>
	dw	arg0
      	db	arg1, 0
elseifidn	<type>, <GR_PUT_STRING_AT>
	dw	arg0
      	db	arg1, 0
elseifidn	<type>, <GR_TERMINATE_STR>
	; Do nothing
else
       	%out Illegal Graphics Command
	.err
endif

endOfStuff	label byte
endm

	DGStr	GR_DRAW_BITMAP, 0, 0
logoBM	label	word
	dw	logoWidth
	dw	logoHeight
	db	1, 1, 0, 0
	db	00000000b, 00001111b, 11111111b, 11000000b, 00000000b
	db	00000000b, 00011111b, 11111111b, 11100000b, 00000000b
	db	00000000b, 11111000b, 00110000b, 01111000b, 00000000b
	db	00000001b, 11100000b, 00110000b, 00011110b, 00000000b
	db	00000011b, 10000000b, 00110000b, 00000111b, 00000000b
	db	00000111b, 00000000b, 01111000b, 00000011b, 10000000b
	db	00001110b, 00000000b, 11111100b, 00000001b, 11000000b
	db	00011100b, 00000000b, 11111100b, 00000000b, 11100000b
	db	00111000b, 00000000b, 11111100b, 00000000b, 01110000b
	db	00110000b, 00000001b, 11111110b, 00000000b, 00110000b
	db	01110000b, 00000011b, 00110011b, 00000000b, 00111000b
	db	01100000b, 00000011b, 00110011b, 00000000b, 00011000b
	db	01100000b, 00000011b, 00110011b, 00000000b, 00011100b
	db	11000000b, 00000111b, 00110011b, 10000000b, 00001100b
	db	11000000b, 00000110b, 00110001b, 10000000b, 00001100b
	db	11000000b, 00001110b, 00110001b, 11000000b, 00001100b
	db	11000000b, 00001100b, 00110000b, 11000000b, 00001100b
	db	11000000b, 00001100b, 00110000b, 11001000b, 00001100b
	db	11000000b, 00011100b, 11111111b, 11111100b, 00001100b
	db	11000000b, 00011000b, 11111111b, 11111100b, 00001100b
	db	11000000b, 00111000b, 00110000b, 01111000b, 00001100b
	db	11000000b, 00110000b, 00110000b, 00110000b, 00001100b
	db	11000000b, 01111111b, 11111111b, 11111000b, 00001100b
	db	11000000b, 01111111b, 11111111b, 11111000b, 00001100b
	db	11000000b, 01100000b, 00000000b, 00011000b, 00001100b
	db	11000000b, 11000000b, 00000000b, 00001100b, 00011100b
	db	01100000b, 11000000b, 00000000b, 00001100b, 00011000b
	db	01100001b, 11000000b, 00000000b, 00001110b, 00011000b
	db	01110011b, 10000000b, 00000000b, 00000111b, 00110000b
	db	00111011b, 10000000b, 00000000b, 00000111b, 00110000b
	db	00011111b, 00000000b, 00000000b, 00000011b, 11110000b
	db	00001111b, 00000000b, 00000000b, 00000011b, 11100000b
	db	00000111b, 00000000b, 00000000b, 00000011b, 11000000b
	db	00000011b, 10000000b, 00000000b, 00000111b, 10000000b
	db	00000001b, 11100000b, 00000000b, 00011111b, 00000000b
	db	00000000b, 11111000b, 00000000b, 01111100b, 00000000b
	db	00000000b, 00111111b, 11111111b, 11110000b, 00000000b
	db	00000000b, 00001111b, 11111111b, 11000000b, 00000000b
logoHeight = 38
logoWidth = 38
	DGStr	GR_TERMINATE_STR

start:
	jmp	endl
	mov	ax, endl-start
endl:
biff	ends
