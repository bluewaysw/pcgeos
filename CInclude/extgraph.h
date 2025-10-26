#ifndef __EXTGRAPH_H
#define __EXTGRAPH_H

#include <geos.h>
#include <gstring.h>
#include <graphics.h>

typedef dword SizeAsDWord;
#define DWORD_WIDTH(val)		((word) (val))
#define DWORD_HEIGHT(val) 		((word) ((val) >> 16))
#define MAKE_SIZE_DWORD(width,height) 	((((dword) (height)) << 16) | (word)(width))

typedef enum {
	EGE_NO_ERROR,
	EGE_WRONG_COORDINATES_X,
	EGE_WRONG_COORDINATES_Y,
	EGE_BLOCK_LOCKING_FAILURE,
	EGE_ILLEGAL_BITMAP_SIZE,
	EGE_BITMAP_NO_PALETTE,
	EGE_ILLEGAL_MOSIAC_SRC_TYPE,
	EGE_CANT_CREATE_BITMAP,
	EGE_ILLEGAL_PALETTE_ENTRIES,
	EGE_PALETTE_INCOMPATIBLE
} EGError;

typedef enum {
	EGMST_BITMAP,
	EGMST_GSTRING
} EGMosaicSourceType;

/*************************************************************
*       PALETTE FUNCTIONS
*************************************************************/

MemHandle _pascal _export
PalParseGString(GStateHandle gstring, word palsize);

void _pascal _export
PalQuantPalette(RGBValue *srcpal, word srcsize,
                RGBValue *destpal, word destsize);

EGError _pascal _export
PalGStateCreateBmpPalette(GStateHandle gstate,
	VMFileHandle bmfile, VMBlockHandle bmblock);

/*************************************************************
*       BITMAP FUNCTIONS
*************************************************************/

EGError _pascal _export
BmpFillBitmapMosaic(GStateHandle gstate, VMFileHandle file, VMBlockHandle block,
            sword x1, sword y1, sword x2, sword y2,
			sword off_x, sword off_y, Boolean clip);

SizeAsDWord _pascal _export
BmpGetBitmapSize(VMFileHandle file, VMBlockHandle block, EGError *error);

BMType _pascal _export
BmpGetBitmapType(VMFileHandle file, VMBlockHandle block, EGError *error);

BMCompact _pascal _export
BmpGetBitmapCompact(VMFileHandle file, VMBlockHandle block, EGError *error);

word _pascal _export
BmpGetBitmapPalette(VMFileHandle file, VMBlockHandle block,
	RGBValue *pal, word size, EGError *error);

VMBlockHandle _pascal _export
BmpGStringToBitmap(VMFileHandle srcfile, VMBlockHandle gsblock,
			VMFileHandle destfile, BMType bmtype, EGError *error);

EGError _pascal _export
BmpSetBitmapPalette(VMFileHandle file, VMBlockHandle block,
					RGBValue *palptr, byte start, word count);

EGError _pascal _export
BmpSetBitmapPaletteEntry(VMFileHandle file, VMBlockHandle block,
					byte red, byte green, byte blue, byte entry);

/* fast bitmap manipulation working for
 * BMF_MONO, BMF_4BIT, BMF_24BIT non-MASK and MASK */
EGError _pascal _export
BmpRotate90(VMFileHandle file, VMBlockHandle *blockPtr);

EGError _pascal _export
BmpRotate180(VMFileHandle file, VMBlockHandle *blockPtr);

EGError _pascal _export
BmpRotate270(VMFileHandle file, VMBlockHandle *blockPtr);

EGError _pascal _export
BmpFlipVertical(VMFileHandle file, VMBlockHandle *blockPtr);

EGError _pascal _export
BmpFlipHorizontal(VMFileHandle file, VMBlockHandle *blockPtr);


/*************************************************************
*       COMMON GRAPHICS FUNCTIONS
*************************************************************/

EGError _pascal _export
ExtGrFillMosaic(GStateHandle gstate, VMFileHandle file, VMBlockHandle block,
            sword x1, sword y1, sword x2, sword y2,
			sword off_x, sword off_y, Boolean clip,
			EGMosaicSourceType srctype);

SizeAsDWord _pascal _export
ExtGrGetGStringSize(VMFileHandle file, VMBlockHandle block, EGError *error);

EGError _pascal _export
ExtGrDrawGString(GStateHandle gstate, sword x, sword y, VMFileHandle file, VMBlockHandle block);

#endif /* __EXTGRAPH_H */
