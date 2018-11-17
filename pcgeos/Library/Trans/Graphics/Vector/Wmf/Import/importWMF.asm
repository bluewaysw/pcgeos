COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importWMF.asm

AUTHOR:		Maryann Simmons, Jul 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/13/92		Initial revision


DESCRIPTION:
	
		

	$Id: importWMF.asm,v 1.1 97/04/07 11:24:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportCode 	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportWMF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the Windows Metafile( WMF ) file  into a GSTRING.

CALLED BY:	
PASS:		BX:	- handle of WMF File
		DI:	- handle of VMFile(open) to create GString in

RETURN:		DX:CX	- created transfer Item 		
		AX	- TransError
		BX	- Handle of text error String if ax = TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportWMF	proc	near
		uses	si,di,bp,ds
		metaInfo local MetafileInfo
		.enter

		; Read WMF header info
		;
		call	ReadWmfHeader		; BX => WMF file
		jc	done			; unable to read header
		mov	metaInfo.MI_numObjects,ax
		mov	metaInfo.MI_outfile, di
		push	bx			; WMF file		

		; Create Huge Array to hold the Object List. This
		; will use the VM file as workspace
		;
		mov	bx,di			; BX <= VM File
		clr	cx,di			; CX=0=> variable size el
		call	HugeArrayCreate
		mov	metaInfo.MI_objectList, di
		mov	metaInfo.MI_currObjs,0
		mov	metaInfo.MI_freeObjs,0

		; Create GString 
		;
		mov	cl,GST_VMEM
		call	GrCreateGString		; DI <= GString
						; SI <= VM block handle
		; Initialize to the WMF Device-Context default 
		; attributes
		;
		call	SetAttrToDefaultDC	; pass DI => GSTATE

		pop	bx			; WMF File
		push	si			; save VM Block Handle
nextOp:
		; Parse the input file, calling the appropriate
		; handler for each Metafile record in the input file
		;
		call	GetNextOpcode		; AX => Vector Opcode
						; DXCX => Size of record
		jc	exit			; unable to read opcode
		call	MapOpcodeToRoutineTableOffset
		cmp	ax, INVALID_WMF_OPCODE	; AX <= offset to routine
		je	invalidOpcode		; opcode not found
		call	CallGStringRoutine	; call corresponding GString
		jc	exit			;  routine
		cmp	ax,VECTOR_EOF		; check for End of File
		jne	nextOp			; also keep track of num op?

		; No more WMF information, end Gstring and exit
		;
		call	GrEndGString
		clr	cx			; DX:CX <= TransferItem
		mov	ax,TE_NO_ERROR		; successful import
exit:
		pop	dx			; VM block handle
done:
		.leave
		ret
invalidOpcode:
		mov	ax,TE_INVALID_FORMAT	; unrecognized opcode
		jmp	exit
ImportWMF	endp 


					;offset params	name
OpcodeLookUpTable	word	\
		    	0x0000,		; 0	0	EOF
		    	0x001e,		; 2   	0	SaveDC
		    	0x0035,		; 4   	0	RealizePalette
		    	0x0037,		; 6	var	SetPaletteEntries
		    	0x00f7,		; 8	var	CreatePalette
		    	0x0102,		; a	2	SetBkMode
		    	0x0103,		; c	2	SetMapMode
		    	0x0104,		; e	2	SetROP2
		    	0x0105,		; 10	?	SetRelAbs
		    	0x0106,		; 12	2	SetPolyFillMode
		    	0x0107,		; 14	2	SetStretchBltMode
		    	0x0108,		; 16	2	SetTextCharacterExtra
		    	0x0127,		; 18	0	RestoreDC
		    	0x012c,		; 1a	var	SelectClipRegion
		    	0x012d,		; 1c	var	SelectObject
		    	0x012e,		; 1e	2	SetTextAlign
		    	0x0139,		; 20	4?	ResizePalette
		    	0x0142,		; 22	var	CreateDIBPatternBrush
		    	0x01f0,		; 24	var	DeleteObject
		    	0x01f9,		; 26	var	CreatePatternBrush20
		    	0x0201,		; 28	4	SetBkColor
		    	0x0209,		; 2a	4	SetTextColor
		    	0x020a,		; 2c	4	SetTextJustification
		    	0x020b,		; 2e	4	SetWindowOrg
		    	0x020c,		; 30	4	SetWindowExt
		    	0x020d,		; 32	4	SetViewportOrg
		    	0x020e,		; 34	4	SetViewportExt
		    	0x020f,		; 36	4	OffsetWindowOrg
		    	0x0211,		; 38	4	OffsetViewportOrg
 		    	0x0213,		; 3a	4	LineTo
		    	0x0214,		; 3c	4	MoveTo
		    	0x0220,		; 3e	4	OffsetClipRegion
		    	0x0231,		; 40	4	SetMapperFlags
		    	0x0234,		; 42	var	SelectPalette
		    	0x02fa,		; 44	var	CreatePenIndirect
		    	0x02fb,		; 46	var	CreateFontIndirect
		    	0x02fc,		; 48	var	CreateBrushIndirect
		    	0x0324,		; 4a	var	Polygon
		    	0x0325,		; 4c	var	PolyLine
		    	0x0400,		; 4e	8	ScaleWindowExt
		    	0x0412,		; 50	8	ScaleViewportExt
		    	0x0415,		; 52	8	ExcludeClipRect
		    	0x0416,		; 54	8	IntersectClipRect
		    	0x0418,		; 56	8	Ellipse	
		    	0x0419,		; 58	8	FloodFill
		    	0x041b,		; 5a	8	Rectangle
		    	0x041f,		; 5c	8	SetPixel
		    	0x0436,		; 5e	var	AnimatePalette
		    	0x0521,		; 61	var	TextOut
		    	0x0538,		; 62	var	PolyPolygon
		    	0x061c,		; 64	12	RoundRect
		    	0x061d,		; 66	12	PatBlt
		    	0x0626,		; 68	var	Escape
		    	0x062f,		; 6a	var	DrawText
		    	0x06ff,		; 6c	var	CreateRegion
		    	0x0817,		; 6c	16	Arc
		    	0x081a,		; 6e	16	Pie
		    	0x0830,		; 70	16	Chord
		    	0x0922,		; 72	var	BitBlt20
		    	0x0940,		; 74	var	BitBlt30	
		    	0x0A32,		; 76	var	ExtTextOut
		    	0x0b23,		; 78	var	StretchBlt20
		    	0x0b41,		; 7a	var	StretchBlt30
		    	0x0d33,		; 7c	var	SetDIBBitsToDevice
		    	0x0f43		; 7e	var	StretchDIBBits


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextOpcode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the next WMF opcode	

CALLED BY:	ImportWMF
PASS:		BX	- WMF FileHandle
RETURN:		AX	- Vector Opcode
		DXCX	- Size in words of record

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		* may need to adjust size of record for function specific
		 records
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextOpcode	proc	near
		uses	ds
		metaRecord local MetafileRecord
		.enter

		segmov 	ds, ss, dx	
		lea	dx, metaRecord
		clr	al
		mov	cx, size MetafileRecord	; each opcode is one word
		call	FileRead
		jc	fileReadError

		; return opcode and size of record
		;
		mov	ax, metaRecord.MR_function
		movdw	dxcx, metaRecord.MR_size
exit:
		.leave
		ret
fileReadError:
		mov	ax, TE_FILE_READ
		jmp	exit
GetNextOpcode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAttrToDefaultDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call appropriate GrSet* routines to set up the attributes
		to be the default Device Context Attributes.

CALLED BY:	ImportWMF	
PASS:		DI	- GString		
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

		The Device Context Defaults are as follows:
			   
				Background Color	White
				BackGroundMode		Opaque
				Brush			WHITE_BRUSH
			IGNORE=>BrushOrigin		(0,0)
		  ?? 16 color??	ColorPalette		DEFAULT_PALETTE
				CurrentPenPosition	(0,0)
				DrawingMode		R2_COPYPEN
 ??(FID_DTC_URW_ROMAN for now)?? Font			SYSTEM_FONT
				InterCharacter spacing  0

		???????????   =>MappingMode		MM_TEXT

				Pen			BLACK_PEN
 ?? Why not supported??         PolygonFilling mode	ALTERNATE
 ?? Why not supported??DO WE???	Stretching mode		BLACKONWHITE

				Text color		BLACK
			IGNORE=>Viewport Extent		(1,1)
			IGNORE=>Viewport origin		(0,0)
			IGNORE=>Window Extent		(1,1)
			IGNORE=>Window origin		(0,0)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	*   for SetBKMode and Color, have to just keep track
		and color area before drawing dashed line or hatch
	*    default palette num entries 16 256

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefaultWMFColorTable16 	byte \
		0, 0x00, 0x00, 0x00,
		1, 0x00, 0x00, 0x80,
      		2, 0x00, 0x80, 0x00,
      		3, 0x00, 0x80, 0x80,
      		4, 0x80, 0x00, 0x00,
      		5, 0x80, 0x00, 0x80,
      		6, 0x80, 0x80, 0x00,
      		7, 0x80, 0x80, 0x80,
      		8, 0xC0, 0xC0, 0xC0,
       		9, 0x00, 0x00, 0xFF,
      		10,0x00, 0xFF, 0x00,
      		11,0x00, 0xFF, 0xFF,
      		12,0xFF, 0x00, 0x00,
      		13,0xFF, 0x00, 0xFF,
      		14,0xFF, 0xFF, 0x00,
      		15,0xFF, 0xFF, 0xFF

SetAttrToDefaultDC	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		metaInfo local MetafileInfo
		.enter inherit

		; set background mode and color for broken lines
                ; and hatch patterns.  The default setting causes
                ; the background in of any broken lines or hatches
                ; to be white, regardless of current color.
		;
		movdw	metaInfo.MI_bkColor, WHITE
		mov	metaInfo.MI_bkMode, OPAQUE

		; Region Filling Rule defaults to odd even rule
		; which corresponds to the WMF ALTERNATE polyFillMode
		;
		mov	metaInfo.MI_polyFillMode, RFR_ODD_EVEN 
		mov	metaInfo.MI_pointSize, DEFAULT_POINT_SIZE
	
;		mov	cx, 16			; default 16 entry palette
;		mov	dx, cs
;		mov	si, offset DefaultWMFColorTable16	
;		call	GrSetPalette

		clr	ax, bx			; current pen position = (0,0)
		call	GrMoveTo

		; for now just default font stuff- should be SYSTEM_FONT
		mov	cx, FID_DTC_URW_ROMAN	; use for default font
		mov	dx, DEFAULT_POINT_SIZE	; DX.AH => point size( 12.0)
		call	GrSetFont

		.leave
		ret
SetAttrToDefaultDC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapOpcodeToRoutineTableOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps a vector opcode to a Routine Table offset.

CALLED BY:	ImportWMF	- WMF Vector Translation Library
PASS:		AX		- Vector Opcode
RETURN:		AX		- offset into Jump Table
					- or -
				  INVALID_WMF_OPCODE (-1) if opcode not
				  found.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapOpcodeToRoutineTableOffset	proc	near
		uses	cx,di,es
		.enter
		
		; scan the opcode table for the word sized opcode
		; passed in ax
		;
		segmov	es, cs			; compares ax to es:di
		mov	di, offset ( cs:OpcodeLookUpTable )
		mov	cx, length OpcodeLookUpTable ; repeat count in CX 
		cld				; clear direction flags
		repnz	scasw			; look up the opcode
		mov	ax, INVALID_WMF_OPCODE
		jnz	exit			; opcodeNotFound

		; The scan leaves di one word past the matched opcode.
		; The corresponding offset into the routine jump table,
		; then, is determined by getting the offset into the 
		; opcode table : ( (DI-2) - (offset OpcodeLookupTable)),
		; multiplying that by 3 ( there are 2 bytes per opcode
		; table entry and 6 per Jump Table entry.) giving the offset
		; into the Jump Table. This jump table relative offset is
		; added to the location of the Jump table to get the 
		; desired location of the routine call.
		;
		sub	di, ( 2 + offset (cs:OpcodeLookUpTable) )
		mov	ax, di
		shl	di, 1			; multiply by 2
		add	di, ax			; + 1 add = multiply by 3
		mov	ax, di			; return offset in bx
exit:
		.leave
		ret
MapOpcodeToRoutineTableOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallGStringRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the handler routine for a WMF opcode, which will in
		most cases( specifically those not involving object manipulation)
		then call the corresponding GString routine with the appropriate
	        parameters.  	

CALLED BY:	ImportWMF

PASS:		AX		- Offset into Jump table
		BX		- input stream (WMF FileHandle)	
		DXCX		- size of record	
		SS:BP		- stack frame metaInfo

RETURN:		AX		- TransError if carry set
				- VECTOR_EOF if end of file encountered	
DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallGStringRoutine	proc	near
		; TODO add check for 0 args
		subdw	dxcx, 3		; already read opcode and size
		shldw	dxcx		; want num bytes = words*2

		add	ax, offset (cs:VectorRoutineJumpTable)
		jmp	ax

VectorRoutineJumpTable	label 	near			;offset into table:
			DefVectorCall	WmfEOF			; 0
			DefVectorCall	WmfSaveDC		; 6
			DefVectorCall	WmfRealizePalette	; c
			DefVectorCall	WmfSetPaletteEntries	; 12
			DefVectorCall	WmfCreatePalette	; 18
			DefVectorCall	WmfSetBkMode		; 1e
			DefVectorCall	WmfSetMapMode		; 24
			DefVectorCall	WmfSetROP2		; 2a
			DefVectorCall	WmfSetRelAbs		; 30
			DefVectorCall	WmfSetPolyFillMode	; 36
			DefVectorCall	WmfSetStretchBltMode	; 3c
			DefVectorCall	WmfSetTextCharacterExtra; 42
			DefVectorCall	WmfRestoreDC		; 48
			DefVectorCall	WmfSelectClipRegion	; 4e
			DefVectorCall	WmfSelectObject		; 54
			DefVectorCall	WmfSetTextAlign		; 5a
			DefVectorCall	WmfResizePalette	; 60
			DefVectorCall	WmfCreateDIBPatternBrush; 66
			DefVectorCall	WmfDeleteObject		; 6c
			DefVectorCall	WmfCreatePatternBrush20	; 72
			DefVectorCall	WmfSetBkColor		; 78
			DefVectorCall	WmfSetTextColor		; 7e
			DefVectorCall	WmfSetTextJustification	; 84
			DefVectorCall	WmfSetWindowOrg		; 8a
			DefVectorCall	WmfSetWindowExt		; 90
			DefVectorCall	WmfSetViewportOrg	; 96
			DefVectorCall	WmfSetViewportExt	; 9c
			DefVectorCall	WmfOffsetWindowOrg	; a2
			DefVectorCall	WmfOffsetViewportOrg	; a8
			DefVectorCall	WmfLineTo		; ae
			DefVectorCall	WmfMoveTo		; b4
			DefVectorCall	WmfOffsetClipRegion	; ba
			DefVectorCall	WmfSetMapperFlags	; c0
			DefVectorCall	WmfSelectPalette	; c6
			DefVectorCall	WmfCreatePenIndirect	; cc
			DefVectorCall	WmfCreateFontIndirect	; d2
			DefVectorCall	WmfCreateBrushIndirect	; d8
			DefVectorCall	WmfPolygon		; de
			DefVectorCall	WmfPolyLine		; e4
			DefVectorCall	WmfScaleWindowExt	; ea
			DefVectorCall	WmfScaleViewportExt	; f0
			DefVectorCall	WmfExcludeClipRect	; f6
			DefVectorCall	WmfIntersectClipRect	; fc
			DefVectorCall	WmfEllipse		; 102
			DefVectorCall	WmfFloodFill		; 108
			DefVectorCall	WmfRectangle		; 10e
			DefVectorCall	WmfSetPixel		; 114
			DefVectorCall	WmfAnimatePalette	; 11a
			DefVectorCall	WmfExtTextOut		; 120
			DefVectorCall	WmfPolyPolygon		; 126
			DefVectorCall	WmfRoundRect		; 12c
			DefVectorCall	WmfPatBlt		; 132
			DefVectorCall	WmfEscape		; 138
			DefVectorCall	WmfDrawText		; 13e
			DefVectorCall	WmfCreateRegion		; 144
			DefVectorCall	WmfArc			; 14a
			DefVectorCall	WmfPie			; 150
			DefVectorCall	WmfChord		; 156
			DefVectorCall	WmfBitBlt20		; 15c
			DefVectorCall	WmfBitBlt30		; 162
			DefVectorCall	WmfSetDIBitsToDevice	; 168
			DefVectorCall	WmfStretchDiBits	; 16e
			DefVectorCall	WmfStretchBlt20		; 174
			DefVectorCall	WmfStretchBlt30		; 17a

CallGStringRoutine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadWmfHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the Wmf File Header, skipping over the additional
		Aldus header, if any. 

CALLED BY:	ImportWMF	
PASS:		BX	- WMF file		
RETURN:		AX	- Maximum number of objects present at the same
			  time. This will dictate the size of the chunk 
			  array created to hold the objects
			- or TransError if carry set
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* TODO: Need to figure out significance of Aldus header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadWmfHeader	proc	near
		uses	cx,dx,di,ds
		fileInfo local	WMFFileInfo
		.enter 

		; first read in a DWORD to see if file also has an Aldus
		; Placeable header, in which case must seek past (18 bytes).
		; The key value is :  0x9ac6cdd7 or 0xd7cdc69a 
		;
		clr	al		; so FileRead returns errors
		mov	cx, 4		; CX =>num bytes to read
		segmov	ds, ss		; DS:DX => buffer to read into
		lea	dx, fileInfo
		call	FileRead	; BX => fileHandle
		jc	readError	; FileError => AX

		mov	di, dx		; compare with Aldus Key 
		cmp	ds:[di], ALDUS_HDR_KEY1
		jne	AldusKey2
		add	di, 2		; look at next word
		cmp	ds:[di], ALDUS_HDR_KEY2
		jne	AldusKey2	; compare with second key
		jmp	AldusHeader	; file contains Aldus Header
AldusKey2:
		mov	di, dx		; set rewind amount to beginning of
		movdw	cxdx, -4	; file, assuming no Aldus header
		cmp	ds:[di], ALDUS_HDR_KEY2
		jne	filePos
		add	di, 2
		cmp	ds:[di], ALDUS_HDR_KEY1
		jne	filePos
AldusHeader:	; seek past Aldus header
		;
		clr	cx		; CXDX <= offset from current pos
		mov	dx, SIZE_ALDUS_HDR - 4  ; already read 4 bytes
filePos:
		mov	al, FILE_POS_RELATIVE
		call	FilePos		; BX => FileHandle
		clr	al

		; Read in WMF FileHeader
		;
		lea	dx, fileInfo 	; DS:DX => buffer
		add	dx, offset WFI_hdr	
		mov	cx, size WMFFileHeader 
		call	FileRead
		jc	readError
		mov	ax, fileInfo.WFI_hdr.WMF_numObjects		
exit:
		.leave
		ret
readError:
		mov	ax, TE_FILE_READ
		jmp	exit
ReadWmfHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MetaFindFreeObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the Object to see if it is free, this is 
		denoted by a NULL in the upper word of the routine
		field.	
	
CALLED BY:	Call back routine supplied to HugeArrayEnum	
PASS:		DS:DI	- pointer to Object
		AX	- element size
		CX	- num elements looked at so far
RETURN:		carry set to end
		DX:AX	- element number to replace

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MetaFindFreeObj	proc	far
		uses	bx,si,di,bp
		.enter

		tst	ds:[di].MO_routine.high
		jnz	notFree
		clr	dx		
		mov	ax,cx		; DX:AX <= element number
		stc			; this object is free
done:
		.leave
		ret
notFree:
		inc	cx		; num elements looked at
		clc			; clear carry, have not yet found free slot
		jmp	done
MetaFindFreeObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfEOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flags end of the Vector input . Free up Object list.

CALLED BY:	
PASS:		DI	- GState
		
RETURN:		AX	- VECTOR_EOF
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		assumes there is an object list to delete
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfEOF	proc	near
		metaInfo local MetafileInfo
		uses bx,di
		.enter inherit

		; Free up ObjectList
		;
		mov	bx, metaInfo.MI_outfile
		mov	di, metaInfo.MI_objectList
		call	HugeArrayDestroy
		
		; return End of File
		mov	ax, VECTOR_EOF

		.leave
		ret
WmfEOF	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetRelAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetRelAbs	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfSetRelAbs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- Gstate 
			- pointer to stream(file)?
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Params:
			y4	: int  -coord of arcs ending point-
					does not have to lie on arc
			x4	: int  - ""
			y3	: int  -coord of arcs starting point-
					does not have to lie on arc
			x3	: int  - ""
			y2	: int  - logical coord of lower right
			x2	: int	""
			y1	: int  - logical coord of upper left
			x1	: int  - "" 
					
		The center of the  Arc is the Center of the Bounding box
		specified by (x1,Y1(ul)), (x2,y2(lr)). The arc is drawn
	        counter clockwise using current pen .
		    GrDrawArc takkes the following:
		ArcParams	struct
    		AP_close 	ArcCloseType	; how the arc should be closed
    		AP_left		sword		; ellipse bounding box: left
    		AP_top		sword		;               top
   		AP_right	sword		;      		right
    		AP_bottom	sword		;      		bottom
    		AP_angle1	sword		; start angle for arc
    		AP_angle2	sword		; ending angle for arc
		ArcParams	ends


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		??? Our stuff in radians,deg??

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfArc	proc	near
;	uses	ax,bx,cx,dx,si,di,ds
;	arcParams local	ArcParams
;	.enter
; get params
;	segmov	ds,ss,si
;	lea	si,arcParams
; convert starting and end points to start angle and end angle
; units ?? 
;	call	GrDrawArc		; takes- di = GState
					;  ds:si = ArcParams:
		uses cx,dx,ds
		.enter
	
		WmfReadParameters

		.leave
		ret
WmfArc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfChord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
			Params:
			y4	: int  -coord of arcs ending point-
					does not have to lie on arc
			x4	: int  - ""
			y3	: int  -coord of arcs starting point-
					does not have to lie on arc
			x3	: int  - ""
			y2	: int  - logical coord of lower right
			x2	: int	""
			y1	: int  - logical coord of upper left
			x1	: int  - "" 
					
		The center of the  Arc is the Center of the Bounding box
		specified by (x1,Y1(ul)), (x2,y2(lr)). The arc is drawn
	        counter clockwise using current pen .
		    GrDrawArc takkes the following:
		ArcParams	struct
    		AP_close 	ArcCloseType	; how the arc should be closed
    		AP_left		sword		; ellipse bounding box: left
    		AP_top		sword		;               top
   		AP_right	sword		;      		right
    		AP_bottom	sword		;      		bottom
    		AP_angle1	sword		; start angle for arc
    		AP_angle2	sword		; ending angle for arc
		ArcParams	ends

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfChord	proc	near
	;uses	ax,bx,cx,dx,si,di,bp
	;.enter	
	; get params
	; convert endpoints to angles
	; make sure get chord, not pie
	;call	GrFillArc			;ds:si is ArcParams struct
		uses cx,dx,ds
		.enter
	
		WmfReadParameters

		.leave
		ret
WmfChord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfDeleteObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the specified object from the object list.
		Currently works for Pens and Brushes

CALLED BY:	CallGStringRoutine
PASS:		DI	- Gstring
		CX	- num bytes to read from WMF file

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* see WmfSelectObject Header

		Deletes a pen,brush,font,bitmap region or palette from
		memory.
		Params:
			hObject		Handle identifies object
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* Assumes this is a valid object to delete, must
			a) exist
			b) not be chosen as current object		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfDeleteObject	proc	near
		metaInfo local MetafileInfo
		uses	ax,bx,cx,dx,ds,si,di
		.enter inherit

		dec	metaInfo.MI_currObjs
		inc	metaInfo.MI_freeObjs
		mov	di, metaInfo.MI_objectList

		; get object to delete
		; 
		segmov	ds,ss
		lea	dx, metaInfo.MI_paramBuffer
		clr	al
		call	FileRead
		jc	error
		mov	ax, {word} metaInfo.MI_paramBuffer
	
		; lock down the specified object
		;
		clr	dx
		mov	bx, metaInfo.MI_outfile
		call	HugeArrayLock
		
		; null out routine field
		; thus marking the entry as free
		;
		; TODO check to make sure 
		;	a) this is a valid object number
		;	b) this object is not currently selected
		mov	ds:[si].MO_routine.high, 0
		call	HugeArrayUnlock
		clc
error:		
		.leave
		ret
WmfDeleteObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState
		DXCX	- num bytes of parameters
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws an ellipse whose center is the center of the
		specified bounding box.  The border is drawn with
		the current pen, the ellipse is filled with the
		current brush.

		* current position not used or updated by routine
		Params:

			y2		- logical coord of lower right
					  of bounding rectangle
			x2		- ""
			y1		- logical coord of upper left
					  of bounding rectangle
			x1		- ""
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfEllipse	proc	near
		metaInfo local MetafileInfo
		uses bx,cx,dx,ds
		.enter
		segmov	ds,ss
		lea	dx, metaInfo.MI_paramBuffer
		clr	al
		call	FileRead
		; AX BX (x1,y1) top left
		; CX DX (x2,y2) right bottom
		mov	dx, {word} metaInfo.[MI_paramBuffer]
		mov	cx, {word} metaInfo.[MI_paramBuffer+2]
		mov	bx, {word} metaInfo.[MI_paramBuffer+4]
		mov	ax, {word} metaInfo.[MI_paramBuffer+6]
		call	GrFillEllipse
		call	GrDrawEllipse
		
		.leave
		ret
WmfEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfExcludeClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Creates a new Clipping Region
			Params:
				y2	int 	lower right
				x2
				y1	int	upper left
				x1

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfExcludeClipRect	proc	near
		uses cx,dx,ds
		.enter
		;*******NOT SUPPORTED**********
		; read past parameters??
		;
		WmfReadParameters

		.leave
		ret
WmfExcludeClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfFloodFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Fills an area of the display surface with the current brush
		Params:
			crColor		-COLOREF color of the boundary
			y		-int point where filling begins
			x


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfFloodFill	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfFloodFill	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfIntersectClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED		
		Creates a new clip region from the existing one and
		rectangle specified
		Params
			y2		- int lower right
			x2
			y1		- int upper left
			x1
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfIntersectClipRect	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfIntersectClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws a line from the current position up to but
		not including the point specified.
		the position is then set to that point. Line is drawn
		with the current pen.
		Params:
			y		- int endpoint for the line
			x		- ""		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfLineTo	proc	near
		uses cx,dx,ds
		.enter

		WmfReadParameters

		; get parameters
		; DI = GState, 
		; CX DX (x2,y2) right bottom
		; updates the pen position???
		; call	GrDrawLineTo

		.leave
		ret
WmfLineTo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Moves the current position to specified x y .
		Params:
			y		- int coord of new position
			x		- ""			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfMoveTo	proc	near
		uses cx,dx,ds
		.enter

		WmfReadParameters

		; DI GState
		; AX BX (x ,y)
		; call	GrMoveTo

		.leave
		ret
WmfMoveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfOffsetClipRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Moves the clipping region by the specified amounts.
		Params:
			y		- int number logical units to move y
			x		- int number logical units to move x
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfOffsetClipRegion	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfOffsetClipRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfOffsetViewportOrg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Modifies the Viewport origin relative to the current origin.
		Params:
			y		- int num device units to add to origin
			x		- ""		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfOffsetViewportOrg	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfOffsetViewportOrg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfOffsetWindowOrg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Modifies the window origin relative to the current values.
		Params:
			y		- int number logical units to add to
					  current origin
			x		- ""		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfOffsetWindowOrg	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfOffsetWindowOrg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfPatBlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a bit pattern by applying specified raster op to the
		select

ed brush.		
		Params:
			dwRop		- dword the raster operation code
				RASTEROPS:
					PATCOPY	    - straight copy
					PATINVERT   - OR
					DSTINVERT   - inverts destination
					BLACKNESS   - output all black
					WHITENESS   - output all white
			nHeight		- int the height of the rectangle
			nWidth		- int the width of the rectangle
			y		- int upper left of rect that will
					  receive pattern
			x		- ""


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfPatBlt	proc	near
		uses cx,dx,ds
		.enter
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfPatBlt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfPie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws a pie shaped wedge by drawing elliptical arc with the
		center and endpoints joined by lines.  Area is filled with
		the selected brush.  	
		Params:
				y4	- int coord of ending point-
					  doesnt have to be on arc
				x4	- ""
				y3	- int coord of starting point-
					  doesnt have to be on arc
				x3	- ""
				y2	- int lower right of bounding
					  rectangle
				x2	- ""
				y1	- int upper left of bounding
					  rectangle 
				x1	- ""
		* routine does not affect the current position	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfPie	proc	near
	;uses	ax,bx,cx,dx,si,di,bp
	;.enter
	; get parameters
	; change from starting/ending angle to starting/ending point
	;
	; ds:si ArcParams
	; di 	GState
	; call	GrFillArc
		uses cx,dx,ds
		.enter
	
		WmfReadParameters

		.leave
		ret
WmfPie	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfRealizePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Maps the system palette entries in the logical palette
		currently selected.		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfRealizePalette	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfRealizePalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfResizePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Changes the size of the palette.
		Param:
			numEntries	int new num entries	
			hPalette	palette to be changed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfResizePalette	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfResizePalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws a rectangle with the current pen and fills it with
		the selected brush.
		Params:
			y2		- int lower right hand corner
			x2		- ""
			y1		- int upper left hand corner
			x1		- ""
		* current position is not updated.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfRectangle	proc	near
	; get parameters
	; DI GState
	; (AX BX) (CX DX) rectangle opposite corners
	; call	GrDrawRect
	; call	GrFillRect
		uses cx,dx,ds
		.enter

		WmfReadParameters

		.leave
		ret
WmfRectangle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfRestoreDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI		-GState
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Restores the device context.
		Param:
			savedDC		- int the DC to be restored
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfRestoreDC	proc	near

	call	GrRestoreState

	ret
WmfRestoreDC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI 		-   GState	
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws a rectangle with rounded corners. The interior is drawn
		with the selected brush, the border with the current pen.
		Params:
				y3	- height of ellipse to draw corners
				x3	- width of ellipse to draw corners
				y2	- lower right of rectangle
				x2	- lower right of rectangle
				y1	- upper left of rectangle
				x1	- upper left of rectangle
		* current position not affected
 
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfRoundRect	proc	near
	; get parameters
	; DI	GState
	; (AX BX) - upper left (CX DX) lower left
	; SI 	radius of rounded corners
	; can they be elliptical or just round?????????
	;call	GrFillRoundRect
	;call	GrDrawRoundRect
		uses cx,dx,ds
		.enter

		WmfReadParameters

		.leave
		ret


WmfRoundRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSaveDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState

RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Save the current state of the specified device content.
		Param??		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSaveDC	proc	near

	call	GrSaveState
	ret

WmfSaveDC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			  WmfScaleViewrtExt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED		
		Modifies the viewport extents relative to currrent values.
		Params:
			Ydenom	- int amount by which to divide y xtent
			Ynum	- int amount to multiply y extent
			Xdenom	- int amount to divide X extent
			Xnum	- int amount to multiply X extent

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfScaleViewportExt	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfScaleViewportExt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfScaleWindowExt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Modifies the window extents relative to the current values.
		Params:
			Ydenom	- int amount by which to divide y xtent
			Ynum	- int amount to multiply y extent
			Xdenom	- int amount to divide X extent
			Xnum	- int amount to multiply X extent
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfScaleWindowExt	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfScaleWindowExt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetBkColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		BX	- WMF File Handle
		DI	- GState
		SS:BP	- MetafileInfo struct
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the Current Background color to the specified color,
		or as close as possible. If the Background mode is
		OPAQUE, this background color is used to fill in the space
		between styled lines, the background for hatch patterns, and
		is used when converting color bitmaps to monochrome and
		vice versa.
	
		There is no way to specify the background color with a 
		GString call, so this information is stored in the
		stack frame, to be used when necessary.

		Params:
			crColor:	- COLORREF- new background color
					  DWORD: RGB0		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetBkColor	proc	near
		metaInfo local MetafileInfo
		uses ax,cx,dx,ds
		.enter	inherit 
		
		segmov	ds,ss		; DS:DX if buffer to read into
		lea	dx, metaInfo.MI_bkColor		
		clr	al
		call	FileRead

		.leave
		ret
WmfSetBkColor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetBkMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		BX	- WMF file
		DI	- GState
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the background mode used with the text and line styles.
		Params:
			nBkMode		- int background mode
						OPAQUE
						TRANSPARENT
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetBkMode	proc	near
		metaInfo local MetafileInfo
		uses cx,dx,ds
		.enter inherit

		segmov	ds,ss		; DS:DX if buffer to read into
		lea	dx, metaInfo.MI_bkMode		
		clr	al
		call	FileRead	; OPAQUE or TRANSPARENT

		.leave
		ret
WmfSetBkMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetMapMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Sets the mapping mode of the specified device context
		Param:
			mMapMode	- int new mapping mode		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetMapMode	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetMapMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetMapperFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Alters the algorithm that the font mapper uses  when it maps
		logical fonts to physical fonts.
		Params:		
			dwFlag		- Dword flag to match aspect height and
					  width to the device
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetMapperFlags	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetMapperFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Sets the pixel at the point specified. The point must be in
		the clipping region.		
		Params:
			crColor		- COLORREF quad- RGB to paint pixel
			y		- point to be set
			x		- point to be set
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetPixel	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetPixel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetPolyFillMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the polygon filling mode.
		Params:
			nPolyFillMode:		- int new filling mode	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetPolyFillMode	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetPolyFillMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetROP2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the current drawing mode used to combine penns and 
		interiors of filled objects  with the colors already
		there.
		Params:
			nDrawMode	int the new drawing mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetROP2	proc	near
		uses cx,dx,ds
		.enter
		
		WmfReadParameters

		.leave
		ret
WmfSetROP2	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetStretchBltMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		DO WE HAVE THIS?????
		Sets the stretching mode for the StretchBlt function.
		Stretching mode determines which scanlines and/or 
		columns are eliminated when the bitmap is contracted
		Params:
		  nStretchMode	-int new stretching mode:
				  BLACKONWHITE:
				     AND in eliminated lines. preserves black
                                     pixels at expense of white ones. ANDS 
 				     eliminated lines and those remaining.
				  COLORONCOLOR:
				     Deletes the eliminated lines, with out
				     trying to preserve the information.
				  WHITEONBLACK:	
				     OR in the eliminated lines. Preserves
				     white pixels at the expense of black
				     pixels.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetStretchBltMode	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetStretchBltMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetTextAlign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the text alignment. the flags are used by TextOut
		and ExtTextOut.
		Params:
			wFlags	- word mask of the following:
					TA_BASELINE
					TA_BOTTOM
					TA_CENTER
					TA_LEFT
					TA_NOUPDATECP
					TA_RIGHT
					TA_TOP
					TA_UPDATECP
			defaults are TA_LEFT,TA_TOP, and TA_NOUPDATECP
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetTextAlign	proc	near
		uses cx,dx,ds
		.enter
		
		WmfReadParameters

		.leave
		ret
WmfSetTextAlign	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetTextCharacterExtra
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the amount of inter-character spacing.
		Params:
			nCharExtra	- int amount of extra space to be
					  added to each character	
		degree = ics/point size * size - may need to take care of
			 negative, less than 1 kerning
		then call GrSetTrackKern... so if someone changes the font/and
			or point size, must recalculate this... therefore
			must save point size as one of the parameters
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetTextCharacterExtra	proc	near
		uses cx,dx,ds
		.enter
		
		WmfReadParameters

		.leave
		ret
WmfSetTextCharacterExtra	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		BX	- WMF file
		DI	- GState		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets the text color.
		Param:
			crColor		- COLORREF- dword 0BGR		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetTextColor	proc	near
		uses ax,bx,cx,dx,ds,si
		metaInfo local MetafileInfo
		.enter	inherit
				
		segmov	ds,ss			
		lea	dx, metaInfo.MI_paramBuffer	
		clr	al			; so errors returned
		call	FileRead				
		jc	error
		mov	si,dx

		; AH = Flag AL =red BL  = Green, BH = blue
		;
		mov	bx, ds:[si+1]
		mov	al, ds:[si+3]
		mov	ah, CF_RGB
		call	GrSetTextColor
error:
		.leave
		ret
WmfSetTextColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetTextJustification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Indicates the text should be justified as specified.
		Params:
			nBreakCount	- int nmber of break chars in line.
			nBreakExtra	- int the total extra space to be added
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetTextJustification	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetTextJustification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetViewportExt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Sets the y and x extents of the specified viewport
		Params:
			y	-int  y extent of viewport
			x	- int x extent of viewport		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetViewportExt	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetViewportExt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetViewportOrg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Sets the y and x origin of the specified viewport
		Params:
			y	 -int  y origin of viewport
			x	- int  x origin of viewport		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetViewportOrg	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetViewportOrg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetWindowOrg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState
		BX	- stream (WMF FileHandle )
		CXDX	- size of prameters in bytes
RETURN:		AX	- TransError if carry set
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		Sets the window origin of the specified device context.
		Params:
			y	- int y coordinate of the new origin
			x	- int x coordinate of the new origin
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetWindowOrg	proc	near
		uses	cx,dx,ds
		.enter
		; get parameters

		WmfReadParameters
		
		.leave
		ret
WmfSetWindowOrg	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetWindowExt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState
		BX	- stream (WMF FileHandle )
		CXDX	- size of prameters in bytes
RETURN:		AX	- TransError if carry set
DESTROYED:	AX		

PSEUDO CODE/STRATEGY:
		Sets the x and y extents of the window associated with
		the device context.
		Params:
			y		- y extent of the window
			x		- x extent of the window
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetWindowExt	proc	near
		uses cx,dx,ds
		.enter
		; *****NOT SUPPORTED *********
		; read over parameters	
		;
		WmfReadParameters

		.leave
		ret
WmfSetWindowExt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfAnimatePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Replaces entries in the specified palette.		
		Params:
			entries		- points to the array of palette
					  entries to replace with
			numentries	- word	number of entries in the
					  palette to be animated
			start		- word first entry to be animated
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfAnimatePalette	proc	near
		uses cx,dx,ds
		.enter
		
		WmfReadParameters
		
		.leave
		ret
WmfAnimatePalette	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfBitBlt30
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Moves a 3.0 version  bitmap from the source to destination
		Params:
			raster op	- word the raster op to be performed
			SY		- source origin
			SX		- source origin
			DYE		- y- extent of destination
			DXE		- x- extent of destination
			DY		- y origin of destination
			DX		- x origin of destination
			BitmapInfo	- BITMAPINFO data structure
			bits		- DIB bits
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version
p
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfBitBlt30	proc	near
		uses	cx,dx,ds
		.enter
		; get parameters
		; call dib library
	
		WmfReadParameters 

		.leave
		ret
WmfBitBlt30	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfBitBlt20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Moves a 3.0 version  bitmap from the source to destination
		Params:
			raster op	- word the raster op to be performed
			SY		- int source origin
			SX		- int source origin
			DYE		- int y- extent of destination
			DXE		- int x- extent of destination
			DY		- int y origin of destination
			DX		- int x origin of destination
			bmWidth		- width in pixels
			bmHeight	- height in pixels
			bmWidthBytes	- num bytes in each line
			bmPlanes	- num color planes in bitmap
			bmBitsPixel	- num adjacent color bits 
			bits		- DIB bits

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfBitBlt20	proc	near
		uses	cx,dx,ds		
		.enter		
		; get parameters		
		; call dib library
	
		WmfReadParameters 

		.leave
		ret
WmfBitBlt20	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfAddObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:		

CALLED BY:	
PASS:		ES:SI	- pointer to object
		CX	- size of Object		
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	9/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfAddObject	proc	near
	metaInfo local MetafileInfo
	uses	ax,bx,cx,dx,si,di,bp
	.enter inherit

		; Now add the object to the Huge Array ObjectList
		mov	di, metaInfo.MI_objectList
		mov	bx, metaInfo.MI_outfile
		; We know what the max number of objects is in existence
		; at one time, but for now, since the Huge array
		; is a dynamic structure, append the new object to the
		; end of the huge array, unless freeObjs is non-zero, 
		; indicating that an object has been deleted, in which case
		; the new object should not be appended, but should be 
		; put in the first available slot, freed up by a previous
		; object having been deleted.  
		tst	metaInfo.MI_freeObjs
		jnz	findFreeObjEntry

		; just append to HugeArray
		push	bp
		mov	bp, es
		call	HugeArrayAppend		; bp:si is buffer
		pop	bp
exit:		clc
		.leave
		ret

findFreeObjEntry:
		dec 	metaInfo.MI_freeObjs
		push	cx			; size
		push	bx			; file
		push	di			; Huge Array
		push	cs			; call back routine
		mov	cx, offset MetaFindFreeObj
		push	cx
		clr	cx,dx			; element to start at
		push	cx,dx			
		mov	dx, metaInfo.MI_currObjs
		push	cx,dx			; number to process
		call	HugeArrayEnum		; ret;el num to insert object
		pop	cx
		push	bp
		mov	bp, es
		clr	si
		call 	HugeArrayReplace	; DX:AX -> free object entry
		pop	bp
		jmp	exit

WmfAddObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreateBrushIndirect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	
CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a brush with the specified style,color and pattern.
		Params:
			logBrush	- LOGBRUSH struct:
			word	lbStyle
				BS_DIBPATTERN 	5
				BS_HATCHED	2
				BS_HOLLOW	1
				BS_PATTERN	3
				BS_SOLID	0
			COLORREF lbcolor
				if lbStyle = BS_HOLLOW or BS_PATTERN:
					ignore lbcolor
				if lbstyle = BS_DIBPATTERN:
					low word of lbColor specifies if 
					colors field of bitmap is RGB entries
					or indices into palette.
					 DIB_PAL_COLORS 1 indices into palette
					 DIB_RGB_COLORS	0 literal RGB values
			int	lbHatch
				if lbstyle is BS_DIBPATTERN lbhatch = handle
					to packed DIB
				if lbstyle is BS_HATCHED, lbhatch specifies
					the orientation of the lines used for
					the hatch.
						HS_HORIZONTAL0 - 1
						HS_VERTICAL  1 - 0
						HS_FDIAGONAL 2 - 3
						HS_BDIAGONAL 3 - 2
						HS_CROSS     4 - ?
						HS_DIAGCROSS 5 - ?
				if lbstyle is BS_PATTERN lbhatch = handle to
					bitmap defining the pattern
				if lbstyle is BS_SOLID or BS_HOLLOW lbhatch
					is ignored.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreateBrushIndirect	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		metaInfo local MetafileInfo
		.enter inherit

		inc	metaInfo.MI_currObjs

		; read parameters into param buffer
		;
		segmov	ds,ss			
		lea	dx, metaInfo.MI_paramBuffer	
		clr	al			; so errors returned
		call	FileRead				
		jc	exit
		mov 	di, dx	
		cmp	ds:[di].LB_style, BS_SOLID
		je	solidBrush
		cmp	ds:[di].LB_style, BS_HATCHED
		je	hatchBrush
		cmp	ds:[di].LB_style, BS_HOLLOW
		je	solidBrush
		cmp	ds:[di].LB_style, BS_PATTERN
		je	exit
		cmp	ds:[di].LB_style, BS_DIBPATTERN
		je	exit
		jmp	exit
hatchBrush:	
		mov	ax, size MetaPatternObj + size MetaRoutine
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
                push	bx
		mov	es,ax	
		clr	si
		mov	es:[si].MO_routine.high, vseg  WmfSetBrushPattern
		mov	es:[si].MO_routine.low,  offset   WmfSetBrushPattern
		add	si, size MetaRoutine
		mov	es:[si].MPB_type, PT_SYSTEM_HATCH

		mov	al, SDM_HORIZONTAL
		cmp	ds:[di].LB_hatch, HS_HORIZONTAL
		je	setHatch
		mov	al, SDM_VERTICAL
		cmp	ds:[di].LB_hatch, HS_VERTICAL
		je	setHatch
		mov	al, SDM_DIAG_NE
		cmp	ds:[di].LB_hatch, HS_BDIAGONAL
		je	setHatch
		mov	al, SDM_DIAG_NW
		cmp	ds:[di].LB_hatch, HS_FDIAGONAL
		je	setHatch
		; for now just set these to diags
		cmp	ds:[di].LB_hatch, HS_CROSS
		je	setHatch
		cmp	ds:[di].LB_hatch, HS_DIAGCROSS
		je	setHatch
		jmp	notSupported
setHatch:
		mov	es:[si].MPB_pattern, al
		mov	cx, size MetaPatternObj + size MetaRoutine
		jmp	addObject
solidBrush:
		; allocate MetaBrush 
		;
		mov	ax, size MetaBrushObj + size MetaRoutine
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
                push	bx
		mov	es,ax	
		clr	si
		mov	es:[si].MO_routine.high, vseg WmfSetBrushSolid
		mov	es:[si].MO_routine.low, offset WmfSetBrushSolid
		add	si, size MetaRoutine
		mov	es:[si].MB_areaAttrs.AA_mapMode, 
				( CMT_DITHER shl offset CMM_MAP_TYPE) 
		mov	es:[si].MB_areaAttrs.AA_mask, SDM_100

		mov	es:[si].MB_areaAttrs.AA_colorFlag, CF_RGB
		mov	cl, ds:[di].LB_colorRed
		mov	es:[si].MB_areaAttrs.AA_color.RGB_red,cl
		mov	cl, ds:[di].LB_colorGreen
		mov	es:[si].MB_areaAttrs.AA_color.RGB_green, cl
		mov	cl,  ds:[di].LB_colorBlue
		mov	es:[si].MB_areaAttrs.AA_color.RGB_blue, cl
		mov	cx, size MetaBrushObj + size MetaRoutine
addObject:
		clr	si
		call	WmfAddObject
notSupported:
freeBuffer:
		pop	bx
		call	MemFree			; free Object block
exit:		clc
		.leave
		ret
WmfCreateBrushIndirect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetBrushSolid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	called when a solid brush drawing object is selected.

CALLED BY:	CallGStringRoutine
PASS:		DI	- GState
		DS:SI   - AreaAttr
RETURN:		nothing		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetBrushSolid	proc	far
		uses	ax
		.enter
		
		; Set AreaPattern to solid
		mov	al, PT_SOLID
		call	GrSetAreaPattern
		call	GrSetAreaAttr
		.leave
		ret
WmfSetBrushSolid	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetBrushPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		DI	- GState
		DS:SI	- pointer to arguments		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	9/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetBrushPattern	proc	far
	uses	ax
	.enter
	
	mov	al, ds:[si].MPB_type
	mov	ah, ds:[si].MPB_pattern
	Call	GrSetAreaPattern
	.leave
	ret
WmfSetBrushPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreateDIBPatternBrush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a brush with pattern specified by the DIB specified.
		Params:
			type		- BS_PATTERN or BS_DIBPATTERN
			Usage		- Palette or RGB- DIB_RGB_COLORS
						  or DIB_PAL_COLORS
			BitmapInfo	- BITMAPINFO structure
			bits		- actual DIB bits
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreateDIBPatternBrush	proc	near
		uses	cx,dx,ds
		.enter
		; get parameters
		; add to chunk array
		;	call	DIB Library??
		
		WmfReadParameters 

		.leave
		ret
WmfCreateDIBPatternBrush	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreateFontIndirect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a font object as specified.
		Params:
			logFont		- LOGFONT struct:
						int	lfHeight
						int 	lfWidth
						int	lfEscapement
						int	lfOrientation
						int	lfWeight
						byte	lfItalic
						byte	lfUnderline
						byte	lfStrikeOut
						byte	lfCharSet
						byte	lfOutPrecision
						byte	lfClipPrecision
						byte	lfQuality
						byte	lfPitchAndFamily
						byte	lfFaceName array
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreateFontIndirect	proc	near
		uses	cx,dx,ds
		.enter
		; get params
		; add to chunk array
	
		WmfReadParameters 

		.leave
		ret
WmfCreateFontIndirect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreatePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Creates a logical color palette.
		Params:
			logPalette	- LOGPALETTE struct:
						palVersion	word
						palNumEntries	word
						palpalEntry[] PaletteEntry
						  RGB triple and a flag byte
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreatePalette	proc	near
		uses	cx,dx,ds
		.enter
		; get parameters

		; DI	GState
		; CX	num entries to set
		; DX:SI pointer to buffer of cx entries of type SetPalElement:
		;       SetPalElement = struct	
    		;	SPE_entry	byte	    ; palette entry number
    		;	SPE_color	RGBValue <> ; color to set that entry
		; call	GrSetPalette
		
		WmfReadParameters

		.leave
		ret
WmfCreatePalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreatePatternBrush20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a brush pattern as specified by Device Dependent
		Bitmap.
		Params:
			bmWidth		- bitmap width
			bmHeight	- bitmap height
			bmWidthBytes	- bytes per line
			bmPlanes	- num color planes
			bmBitsPixel	- num bits/pixel
			bmBits		- pointer to bit values
			bits		- actual bits of pattern
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreatePatternBrush20	proc	near
		uses	cx,dx,ds
		.enter
		; get params
		; call dib library??
		; add to chunk array
		
		WmfReadParameters

		.leave
		ret
WmfCreatePatternBrush20	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreatePenIndirect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a logical pen with specified style,width, and color.
		Params:
			logPen		- LOGPEN struct
						lopnStyle	word
						lopnWidth	POINT
						lopnColor	COLORREF
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreatePenIndirect	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		metaInfo local MetafileInfo
		.enter inherit

		inc	metaInfo.MI_currObjs
		; read parameters into param buffer
		;
		segmov	ds,ss			
		lea	dx, metaInfo.MI_paramBuffer	
		clr	al			; so errors returned
		call	FileRead				
		jc	exit

		; allocate MetaPen 
		;
		mov	ax, size MetaPenObj + size MetaRoutine
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
                push	bx
		mov	es,ax	
		clr	si
		mov	es:[si].MO_routine.high, vseg GrSetLineAttr
		mov	es:[si].MO_routine.low, offset GrSetLineAttr
		add	si, size MetaRoutine
		mov	al, SDM_100	
		mov	es:[si].MP_lineAttrs.LA_mask, al

		; How to handle NULL and INSIDEFRAME???
		mov 	di, dx	
		mov	al, LS_SOLID
		cmp	ds:[di].LP_style,PS_NULL
		jae	setStyle
		mov	ax, ds:[di].LP_style
setStyle:
		mov	es:[si].MP_lineAttrs.LA_style, al
		mov	es:[si].MP_lineAttrs.LA_mapMode, 
				( CMT_DITHER shl offset CMM_MAP_TYPE) 
		mov	es:[si].MP_lineAttrs.LA_colorFlag, CF_RGB
		mov	cl, ds:[di].LP_colorRed
		mov	es:[si].MP_lineAttrs.LA_color.RGB_red,cl
		mov	cl, ds:[di].LP_colorGreen
		mov	es:[si].MP_lineAttrs.LA_color.RGB_green, cl
		mov	cl,  ds:[di].LP_colorBlue
		mov	es:[si].MP_lineAttrs.LA_color.RGB_blue, cl
		
		; defaults for these???
		mov	es:[si].MP_lineAttrs.LA_end, LE_BUTTCAP
		mov	es:[si].MP_lineAttrs.LA_join, LJ_MITERED

		; if ax= 0 should be 1 pixel???

		mov	ax, ds:[di].LP_width.x
		clr	bx
		movdw	es:[si].MP_lineAttrs.LA_width, axbx

		; Now add the object to the Huge Array ObjectList

		clr	si
		mov	cx, size MetaPenObj + size MetaRoutine
		call	WmfAddObject
freeBuffer:
		pop	bx
		call	MemFree			; free Object block
exit:		clc
		.leave
		ret
WmfCreatePenIndirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfCreateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfCreateRegion	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfCreateRegion	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws formatted text in the rectangle specified.
		Params:
			format		- method of formatting text
			count		- int number bytes in string
			rectangle	- structure defining area where
					  text is to be defined
					  RECT:
						int left 
						int right
						int top
						int bottom
			string		- array containing the string
						
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Descriptionpp
	----	----		-----------

	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfDrawText	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfDrawText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		BX	- stream (WMF FileHandle for now)
		DXCX	- size of parameters in bytes
RETURN:		AX	- TransError if carry set		
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		Allows access to facilities not directly available through 
		GDL.
		Params:	
			escape number	- number identifying escape
			count		- number bytes of information
			input data	- information

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfEscape	proc	near
		uses	cx,dx,si,bp,ds
		.enter


		sub	sp,cx		; make room on stack for params
		mov	bp,sp		; DS:[BP] = parameters
		push	cx		; save size of params
		segmov	ds,ss		; DS:DX if buffer to read into
		mov	dx,bp		

		clr	al
		; with buffering or check max record size??
		call	FileRead
		pop	dx		; size of params
		jc	errorRead
		mov	cx, ds:[bp].WEP_count
		
		; Check that size of parameter passed in equals
		; sizeof info + count + sizeof escapeNum 
		mov	si,cx
		add	si,5		; 4 bytes for count and code, 1 extra
					; byte to round up for words
		shr	si,1
		push	di		; save GState
		mov	di,dx
		shr	di,1
		cmp	si,di 
		pop	di		; restore GState
		jne	errorRecSize
 
		cmp 	ds:[bp].WEP_escapeNum, MFCOMMENT
		jne	done		; only escape supported

		lea	si,ds:[bp].WEP_data
		call	GrComment	; DS:SI => pointer to comment
done:	

		clc			; no error

exit:
		add	sp,dx
		.leave
		ret

errorRecSize:
		stc
		mov	ax, TE_INVALID_FORMAT
		jmp	exit
errorRead:		
		mov	ax, TE_FILE_READ
		jmp	exit
WmfEscape	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfExtTextOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Writes a character string within the specified region,
		using the currently selected font.
		The region can be opaque.
		Params:	
			y	- int string's starting point
			x	- int string`s starting point
			count	- length of the string
			options	- rectangle type
			rectangle RECT struct
			string	- byte array of string
			dxarray	- optional word array of inter character 
				  spacing
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfExtTextOut	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfExtTextOut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a polygon with the current line style and color and
		fills it with the current Area style and color.

CALLED BY:	
PASS:		DI	- GState			
		BX	- WMF FileHandle
		CXDX	- num bytes for parameters

RETURN:		AX	- TransError if carryset

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		Draws a polygon or two or more points connected by lines.
		Polygons are filled with current polygon filling mode.
		Polygon is automatically closed- last vertex to first.
		Params:
			count	- number of points
			list o points		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfPolygon	proc	near
		uses	bx,cx,dx,ds,si
		metaInfo local MetafileInfo
		.enter inherit
				
		segmov	ds,ss			
		lea	dx, metaInfo.MI_paramBuffer	
		mov	cx,2			; read word num points

		clr	al			; so errors returned
		call	FileRead				
		jc	errorReadCount
		xchg	dx,bx
		mov	ax,ds:[bx]

		; allocate buffer to hold points
		;
		shl	ax,1			;num bytes
		shl	ax,1			; 4 bytes/point
		push	ax
		mov	cx,ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov	ds,ax
		pop	cx
		push	bx			; save mem handle
		mov	bx,dx			; file handle
		clr	dx
		clr	al			; so errrors returned
		call	FileRead
		jc	errorReadPoints

		; If Background mode is OPAQUE, and a Hatch pattern is specified,
		; must fill in background
		;
		mov	si,dx
		shr	cx,1			; CX =>numPoints
		shr	cx,1			; AL =>fill rule

		cmp	metaInfo.MI_bkMode, TRANSPARENT
		je	fillPoly
		push	cx
		call	GrGetAreaPattern	; AL <= PatternType
		pop	cx
		cmp	ah,  PT_SYSTEM_HATCH	; AH <= SystemHatch or SystemBitmap
		je 	fillHatch
		cmp	ah,  PT_CUSTOM_HATCH	
		jne 	fillPoly
fillHatch:

		call	GrSaveState
		mov	bx, metaInfo.MI_bkColor.high
		mov	ax, metaInfo.MI_bkColor.low
		mov	bh,ah
		mov	ah, CF_RGB
		call	GrSetAreaColor
		call	GrFillPolygon
		call	GrRestoreState
fillPoly:
		mov	al, metaInfo.MI_polyFillMode 
		call	GrFillPolygon		; DI => GSTATE		

		; if a broken( dashed,etc) line is specifed, fill in background
		; first
		call	GrGetLineStyle		; returns al = line style
		cmp	al, LS_SOLID
		je	outlinePoly
		call	GrSaveState
		mov	bx, metaInfo.MI_bkColor.high
		mov	ax, metaInfo.MI_bkColor.low
		mov	bh,ah
		mov	ah, CF_RGB
		call	GrSetLineColor
		; draw outline first in background color
		call	GrDrawPolygon		 
		call	GrRestoreState
outlinePoly:
		call	GrDrawPolygon

		; free up point buffer
		pop	bx
		call	MemFree
		clc

exit:
		.leave
		ret
errorReadPoints:

		pop	bx
		call	MemFree
errorReadCount:
		stc
		mov	ax, TE_FILE_READ
		jmp	exit
WmfPolygon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfPolyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Draws a set of line segments, connecting the points specified.
		Current position is neither used or updated.
		Params:
			count		- number of points
			list of points	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfPolyLine	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfPolyLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfPolyPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a series of closed polygons. The polygons are 
		filled using the current polygon filling mode. The
		polygons may overlap. 
		Params:
			count		- total number of points
			list of polygon counts
					- number of points for each polygon
			list of points		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfPolyPolygon	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfPolyPolygon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSelectClipRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOT SUPPORTED
		Selects the given region as the current clipping region.
		Params:
			hrgn		- HRGN
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSelectClipRegion	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfSelectClipRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSelectPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Selects the logical palette as the current palette.
		Params:
			hPalette	- HPALETTE
			bForceBack	-BOOL		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSelectPalette	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfSelectPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSelectObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects the specified drawing object from the Object
		List and sets it as the current object of that type.
		( currently supported drawing object types are Pens
		 and Brushes).

CALLED BY:	CallGStringRoutine 	
PASS:		DI	- GString	
		CX	- num bytes to read from WMF file
RETURN:		carry set if error		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Params from WMF file:
			hObject		- object to select

		OBJECTS:

			Objects are created by calls to WmfCreate* routines.
		The objects basically drawing tools with specified attributes.
		These objects are not activated upon creation, but are stored
		in an object list, and associated with an id. To actually
		set these attributes, a call to SelectObject, passing the same
		id, must be made. The object ids start at zero, and are intiially 
		assigned to the objects in order of creation. Once an object
		is deleted, however, the next object will fill in that slot and
		get that id number. Any object which is currently selected should not
		be deleted.... but in our system, it doesnt matter.. there
		is currently no check for this.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
pREVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSelectObject	proc	near
		metaInfo local MetafileInfo
		uses	ax,bx,cx,dx,ds,bp,si
		.enter inherit

		; Get the ID of the object to select
		;
		segmov	ds,ss
		lea	dx, metaInfo.MI_paramBuffer
		clr	al
		call	FileRead
		jc	done
		mov	ax, {word} metaInfo.MI_paramBuffer
		
		; check if valid object id
		;
		
		cmp	 ax, metaInfo.MI_numObjects
		jae	error
		clr	dx
		push	bp			; save to access locals
		push	di			; save GString
		
		; Get the object from the HugeArray
		;
		mov	bx, metaInfo.MI_outfile		
		mov	di, metaInfo.MI_objectList
		call	HugeArrayLock

		; Each object consists of a pointer to a routine
		; to call which will 'activate' that object,
		; as well as the parameters to pass to the routine
		;
		pop	di			; restore GState
		movdw	bxax, ds:[si]		; routine segment:offset
		tst	bx		
		jz	invalidRoutine		; invalid object id
		add	si, 4			; DS:SI <= parameters
		call	ProcCallFixedOrMovable

		pop	bp			; restore locals
		call	HugeArrayUnlock
		clc				; no error
done:
		.leave
		ret
invalidRoutine:
		pop	bp			; restore locals
		call	HugeArrayUnlock
error:		stc				; flag error
		jmp	done
WmfSelectObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetDIBitsToDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets bits from a DIB directly on a surface.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetDIBitsToDevice	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfSetDIBitsToDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfSetPaletteEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfSetPaletteEntries	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfSetPaletteEntries	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfStretchBlt20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfStretchBlt20	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfStretchBlt20	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfStretchBlt30
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfStretchBlt30	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfStretchBlt30	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WmfStretchDiBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WmfStretchDiBits	proc	near
		uses	cx,dx,ds
		.enter
		; ****NOT SUPPORTED********
		; read past parameter
		WmfReadParameters 
		.leave
		ret
WmfStretchDiBits	endp


ImportCode	ends




