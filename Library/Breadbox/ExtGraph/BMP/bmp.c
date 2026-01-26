#include "extgraph.h"
#include <geos.h>
#include <vm.h>
#include <timer.h>
#include <ec.h>
#include <graphics.h>
#include <gstring.h>
#include <color.h>
#include <heap.h>
#include <Ansi/string.h>
#include <hugearr.h>


/***************************************************************************/

Boolean
extGrFillMosaicLineReal(GStateHandle gstate, Rectangle *rect, int end, Boolean vert,
	VMFileHandle file, VMBlockHandle block, EGMosaicSourceType srctype, EGError *error,
	word bmpSizeX)
{
	Boolean clipStat = FALSE;
	sword localPos, startPos, stepPoints/*, bandWidth*/;
	sword blockStart, blockCount, checkCount, checkStart;

	srctype++;

	if(vert)
	{
		localPos = rect->R_bottom;
		stepPoints = rect->R_bottom - rect->R_top;
//		bandWidth = rect->R_right - rect->R_left;
		blockStart = rect->R_top;
	}
	else
	{
		localPos = rect->R_right;
		stepPoints = rect->R_right - rect->R_left;
//		bandWidth = rect->R_bottom - rect->R_top;
		blockStart = rect->R_left;
	}

	checkStart = blockStart;
	checkCount = blockCount = 1;

	startPos = localPos;

	while((localPos < end) && (localPos >= startPos))
	{
		sword toDo, toDoDone;

		toDo = (end - localPos + stepPoints - 1) / stepPoints;

		if(toDo > blockCount)
			toDo = blockCount;

		toDoDone = toDo;

		if(vert)
		{
			word loopCount;

			loopCount = 0;
			while(loopCount < toDo)
			{
				word loopCount2 = 0;
				word toDo2 = (rect->R_right-rect->R_left + bmpSizeX - 1) / bmpSizeX;
				while(loopCount2 < toDo2) {
					GrDrawHugeBitmap(gstate, rect->R_left+loopCount2*bmpSizeX, localPos + (loopCount * stepPoints), file, block);
					loopCount2++;
				}

				loopCount++;
			}
		}
		else
		{
			word loopCount;

			loopCount = 0;
			while(loopCount < toDo)
			{
				GrDrawHugeBitmap(gstate, localPos + (loopCount * stepPoints), rect->R_top, file, block);

				loopCount++;
			}
		}

		// check this block
		while(toDo)
		{
			sword testEnd = localPos + toDo * stepPoints;
			if(testEnd > end)
				testEnd = end;

			if(vert)
			{
				if(GrTestRectInMask(gstate,
					rect->R_left, localPos,
					rect->R_right - 1,
					testEnd - 1) == TRRT_IN)
					break;
			}
			else
			{
				if(GrTestRectInMask(gstate,
					localPos, rect->R_top,
					testEnd - 1,
					rect->R_bottom - 1) == TRRT_IN)
					break;
			}

			clipStat = TRUE;
			toDo --;
		}

		checkCount += toDo;

		if(checkCount > blockCount)
		{
			blockCount = checkCount;
			blockStart = checkStart;
		}


		localPos += stepPoints * toDoDone;

		if(toDo != toDoDone)
		{
			checkCount = 0;
			checkStart = localPos;
		}
	}

	if(error)
		*error = EGE_NO_ERROR;

	return(clipStat);
}

/***************************************************************************/

Boolean
extGrFillMosaicLine(GStateHandle gstate, Rectangle *rect, int end, Boolean vert,
	EGError *error)
{
	Boolean clipStat = FALSE;
	sword localPos, startPos, stepPoints, bandWidth;
	sword blockStart, blockCount, checkCount, checkStart;

	if(vert)
	{
		localPos = rect->R_bottom;
		stepPoints = rect->R_bottom - rect->R_top;
		bandWidth = rect->R_right - rect->R_left;
		blockStart = rect->R_top;
	}
	else
	{
		localPos = rect->R_right;
		stepPoints = rect->R_right - rect->R_left;
		bandWidth = rect->R_bottom - rect->R_top;
		blockStart = rect->R_left;
	}

	checkStart = blockStart;
	checkCount = blockCount = 1;

	startPos = localPos;

	while((localPos < end) && (localPos >= startPos))
	{
		sword toDo, toDoDone;

		toDo = (end - localPos + stepPoints - 1) / stepPoints;

		if(toDo > blockCount)
			toDo = blockCount;

		toDoDone = toDo;

		if(vert)
		{
			GrBitBlt(gstate, rect->R_left, blockStart,
				rect->R_left, localPos,
				bandWidth, stepPoints * toDo,
				BLTM_COPY);
		}
		else
		{
			GrBitBlt(gstate, blockStart, rect->R_top,
				localPos, rect->R_top,
				stepPoints * toDo, bandWidth,
				BLTM_COPY);
		}

		// check this block
		while(toDo)
		{
			sword testEnd = localPos + toDo * stepPoints;
			if(testEnd > end)
				testEnd = end;

			if(vert)
			{
				if(GrTestRectInMask(gstate,
					rect->R_left, localPos,
					rect->R_right - 1,
					testEnd - 1) == TRRT_IN)
					break;
			}
			else
			{
				if(GrTestRectInMask(gstate,
					localPos, rect->R_top,
					testEnd - 1,
					rect->R_bottom - 1) == TRRT_IN)
					break;
			}

			clipStat = TRUE;
			toDo --;
		}

		checkCount += toDo;

		if(checkCount > blockCount)
		{
			blockCount = checkCount;
			blockStart = checkStart;
		}


		localPos += stepPoints * toDoDone;

		if(toDo != toDoDone)
		{
			checkCount = 0;
			checkStart = localPos;
		}
	}

	if(error)
		*error = EGE_NO_ERROR;

	return(clipStat);
}

/***************************************************************************/

SizeAsDWord _pascal _export
BmpGetBitmapSize(VMFileHandle file, VMBlockHandle block, EGError *error)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle mem;
	byte *ptr;
// word defined in the Bitmap structure <graphics.h>
	word width = 0, height = 0;

	ptr = VMLock(file, block, &mem);

	if(ptr)
	{
// kernel dependend bitmap header, definition assumed
		width = *((word*) (&ptr[0x1a]));
		height = *((word*) (&ptr[0x1c]));

		VMUnlock(mem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	if(error)
		*error = stat;

	return(MAKE_SIZE_DWORD(width, height));
}

/***************************************************************************/

BMType _pascal _export
BmpGetBitmapType(VMFileHandle file, VMBlockHandle block, EGError *error)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle mem;
	byte *ptr;
// word defined in the Bitmap structure <graphics.h>
	BMType bmtype;

	ptr = VMLock(file, block, &mem);

	if(ptr)
	{
// kernel dependend bitmap header, definition assumed
		bmtype = ptr[0x1f];

		VMUnlock(mem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	if(error)
		*error = stat;

	return(bmtype);
}

/***************************************************************************/

BMCompact _pascal _export
BmpGetBitmapCompact(VMFileHandle file, VMBlockHandle block, EGError *error)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle mem;
	byte *ptr;
// word defined in the Bitmap structure <graphics.h>
	BMCompact bmcompact;

	ptr = VMLock(file, block, &mem);

	if(ptr)
	{
// kernel dependend bitmap header, definition assumed
		bmcompact = ptr[0x1e];

		VMUnlock(mem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	if(error)
		*error = stat;

	return(bmcompact);
}

/***************************************************************************/

word _pascal _export
BmpGetBitmapPalette(VMFileHandle file, VMBlockHandle block,
	RGBValue *pal, word size, EGError *error)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle mem;
	byte *ptr;
	word offset;
	word palsize;

	ptr = VMLock(file, block, &mem);

	if(ptr)
	{
		BMFormat bmformat;
		RGBValue *palsrc;

		bmformat = ((BMType) ptr[0x1f]) & BMT_FORMAT;

		if(bmformat == BMF_MONO)
		{
			palsize = 2;

			if(size >= 1)
			{
				pal[0].RGB_red = 255;
				pal[0].RGB_green = 255;
				pal[0].RGB_blue = 255;
			}

			if(size >= 2)
			{
				pal[1].RGB_red = 0;
				pal[1].RGB_green = 0;
				pal[1].RGB_blue = 0;
			}
		}
		else
		{
			if(bmformat <= BMF_8BIT)
			{
				offset = *((word*) (ptr + 0x28));
				offset += 0x1a;

				palsize =  *((word*) (ptr + offset));

				offset += 2;

				palsrc = (RGBValue*) (ptr + offset);

				if(palsize < size)
					size = palsize;

				while(size)
				{
					size --;

					pal[size] = palsrc[size];
				}
			}
			else
			{
				palsize = 0;
				stat = EGE_BITMAP_NO_PALETTE;
			}
		}

		VMUnlock(mem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	if(error)
		*error = stat;

	return(palsize);
}

/***************************************************************************/

EGError _pascal _export
BmpFillBitmapMosaic(
	GStateHandle gstate,	// where to put the bitmap mosaic to
    VMFileHandle file,		// vm file containing the bitmap
	VMBlockHandle block,	// block of huge bitmap
    sword x1,				// rectangle to fill with the mosaic
	sword y1,
	sword x2,
	sword y2,
	sword off_x,			// offset from the left top edge of the
							// output rectangle into the area
	sword off_y,
	Boolean clip)			// hard clip at the rectangle boundaries
//*****
{
	return(ExtGrFillMosaic(
		gstate, file, block, x1, y1, x2, y2, off_x, off_y, clip,
		EGMST_BITMAP));
}

/***************************************************************************/

VMBlockHandle _pascal _export
BmpGStringToBitmap(VMFileHandle srcfile, VMBlockHandle gsblock,
			VMFileHandle destfile, BMType bmtype, EGError *error)
{
	EGError stat = EGE_NO_ERROR;
	BMFormat bmformat = bmtype & BMT_FORMAT;
	GStateHandle bmstate;
	word width, height;
	VMBlockHandle bmblock;
	SizeAsDWord size_xy;
	MemHandle palette = 0;
//	RGBValue *palptr;
//	word colortab = 0;

	// get gstring size
	size_xy = ExtGrGetGStringSize(srcfile, gsblock, &stat);
	if(stat != EGE_NO_ERROR)
		goto end;
	width = DWORD_WIDTH(size_xy);
	height = DWORD_HEIGHT(size_xy);

	if((width == 0) || (height == 0))
	{
		stat = EGE_ILLEGAL_BITMAP_SIZE;
		goto end;
	}

	// build palette if needed
	if(bmtype & BMT_PALETTE)
	{
		if((bmformat > BMF_MONO) && (bmformat < BMF_24BIT))
		{
//			colortab = 16;
//			if(bmformat == BMF_8BIT)
//				colortab = 256;

//			palette = PalParseGStringEx(
//				srcfile, gsblock, colortab, !(bmtype & BMT_MASK),
//				&stat);
		}
		else
		{
			stat = EGE_BITMAP_NO_PALETTE;

			goto end;
		}
	}

	if(stat != EGE_NO_ERROR)
	{
		if(palette)
			MemFree(palette);
		goto end;
	}

	/* creating output bitmap */
	bmblock = GrCreateBitmap(bmtype|BMT_COMPLEX,
		width, height, destfile, 0, &bmstate);
	if(!bmblock)
	{
		if(palette)
			MemFree(palette);
		stat = EGE_CANT_CREATE_BITMAP;
		goto end;
	}

	if(bmstate)
		GrDestroyBitmap(bmstate, BMD_LEAVE_DATA);
	else
	{
		if(palette)
			MemFree(palette);

		// destroy vm chain
		VMFreeVMChain(destfile, VMCHAIN_MAKE_FROM_VM_BLOCK(bmblock));

		stat = EGE_BLOCK_LOCKING_FAILURE;
		goto end;
	}

	// save bitmap palette
/*
	if(bmtype & BMT_PALETTE)
	{
		palptr = (RGBValue*) MemLock(palette);

		if(palptr)
		{
			// set bitmap palette
//			stat = BmpSetBitmapPalette(destfile, bmblock,
//				palptr, 0, colortab);

			MemUnlock(palette);
			MemFree(palette);
		}
		else
		{
			MemFree(palette);

			// destroy vm chain
			VMFreeVMChain(destfile, VMCHAIN_MAKE_FROM_VM_BLOCK(bmblock));

			stat = EGE_BLOCK_LOCKING_FAILURE;
			goto end;
		}
	}
*/
	/* writing gstring */
	bmstate = GrEditBitmap(destfile, bmblock, 0);
	if(bmstate)
	{
		GStateHandle gstring = GrLoadGString(srcfile, GST_VMEM, gsblock);

		if(gstring)
		{
			Rectangle bounds;
			sword drawX;
			sword drawY;

			// define color mapping for the final draw
			GrSetAreaColorMap(bmstate, CMT_CLOSEST);
			GrSetTextColorMap(bmstate, CMT_CLOSEST);

			GrGetGStringBounds(gstring, bmstate, 0, &bounds);
			drawX = -bounds.R_left;
			drawY = -bounds.R_top;

				if(bmtype & BMT_MASK)
				{
					word originalBitmapMode = GrGetBitmapMode(bmstate);
					word originalMixMode = GrGetMixMode(bmstate);
					word element = 0;
					Boolean maskDone = FALSE;
					Boolean maskActive = FALSE;

					GrSaveState(bmstate);
					GrSetBitmapMode(bmstate, BM_EDIT_MASK, 0);
					maskActive = (GrGetBitmapMode(bmstate) & BM_EDIT_MASK) ? TRUE : FALSE;

					if(maskActive)
				{
					// Populate the mask by redrawing with MM_SET so painted pixels become opaque
					GrClearBitmap(bmstate);
					GrSetMixMode(bmstate, MM_SET);
					GrSetAreaColor(bmstate, CF_INDEX, 1, 0, 0);
					GrSetLineColor(bmstate, CF_INDEX, 1, 0, 0);
					GrSetTextColor(bmstate, CF_INDEX, 1, 0, 0);

					do
					{
						word drawResult;

					drawResult = GrDrawGString(bmstate, gstring, drawX, drawY, GSC_ATTR, &element);
					if(drawResult == GSRT_FAULT)
					{
						stat = EGE_BLOCK_LOCKING_FAILURE;
						maskDone = TRUE;
						break;
					}
						if(element == GR_SET_MIX_MODE)
						{
							GrSetGStringPos(gstring, GSSPT_SKIP_1, 0);
							continue;
						}

						if((drawResult == GSRT_COMPLETE) || (element == GR_END_GSTRING))
						{
							maskDone = TRUE;
						}
					} while(maskDone == FALSE);
				}

				GrRestoreState(bmstate);
				GrSetBitmapMode(bmstate, originalBitmapMode, 0);
				GrSetMixMode(bmstate, originalMixMode);
				GrSetGStringPos(gstring, GSSPT_BEGINNING, 0);
			}

			// draw image data into the bitmap plane
			if(stat == EGE_NO_ERROR)
			{
				word finalElement = 0;
				GrDrawGString(bmstate, gstring, drawX, drawY, 0, &finalElement);
			}

			GrDestroyGString(gstring, 0, GSKT_LEAVE_DATA);
		}
		else
		{
			stat = EGE_BLOCK_LOCKING_FAILURE;
		}

		GrDestroyBitmap(bmstate, BMD_LEAVE_DATA);
	}
	else
	{
		// free vm chain
		VMFreeVMChain(destfile, VMCHAIN_MAKE_FROM_VM_BLOCK(bmblock));

		stat = EGE_BLOCK_LOCKING_FAILURE;
	}

end:
	if(error)
		*error = stat;

	if(stat != EGE_NO_ERROR)
		bmblock = 0;

	return(bmblock);
}

/***************************************************************************/

typedef ByteEnum BmpMaskType;
#define EGBMT_FULL		1
#define EGBMT_PART		2
#define EGBMT_EMPTY		3

BmpMaskType
BmpCheckMaskType(VMFileHandle file, VMBlockHandle block, SizeAsDWord size)
{
	word loopCount = 0;
	BmpMaskType retValue = EGBMT_FULL;
	word elemSize;
	byte *elemPtr;
	BMType bmType;
	BMCompact bmCompact;

	bmType = BmpGetBitmapType(file, block, 0);
	bmCompact = BmpGetBitmapCompact(file, block, 0);

	if((bmType & BMT_MASK) && (bmCompact == BMC_UNCOMPACTED))
	{
		while(loopCount < DWORD_HEIGHT(size))
		{
			HugeArrayLock(file, block, loopCount/* + DWORD_HEIGHT(size)*/, (void**) &elemPtr, &elemSize);

//			if(elemSize == ((DWORD_WIDTH(size) + 7) / 8))
			{
				word lineLoop;

				/* check line for pixels */
				lineLoop = 0;
				while(lineLoop < ((DWORD_WIDTH(size) + 7) / 8))
				{
					byte byteMask = 0xFF;

					if((lineLoop + 1) == ((DWORD_WIDTH(size) + 7) / 8))
					{
						byte bitMask[] = {0x80, 0x0C0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xFF};

						byteMask = bitMask[DWORD_WIDTH(size) % 8];
					}

					if(elemPtr[lineLoop] & byteMask)
					{
						if((elemPtr[lineLoop] & byteMask) == byteMask)
						{
							if((lineLoop == 0) && (loopCount == 0))
							{
								retValue = EGBMT_FULL;
							}
							else
							{
								if(retValue != EGBMT_FULL)
								{
									retValue = EGBMT_PART;
								}
							}
						}
						else
						{
							retValue = EGBMT_PART;
						}
					}
					else
					{
						if((lineLoop == 0) && (loopCount == 0))
						{
							retValue = EGBMT_EMPTY;
						}
						else
						{
							if(retValue != EGBMT_EMPTY)
							{
								retValue = EGBMT_PART;
							}
						}
					}
					lineLoop++;
				}
			}

			HugeArrayUnlock(elemPtr);
			loopCount++;
		}
	}
	else {
		retValue = EGBMT_PART;
	}

	return retValue;
}


/***************************************************************************/

// is placed in this segment because it mostly equals the
// function BmpFillBitmapMosaic
EGError _pascal _export
ExtGrFillMosaic(
	GStateHandle gstate,	// where to put the bitmap mosaic to
    VMFileHandle file,		// vm file containing the bitmap
	VMBlockHandle block,	// block of huge bitmap
    sword x1,				// rectangle to fill with the mosaic
	sword y1,
	sword x2,
	sword y2,
	sword off_x,			// offset from the left top edge of the
							// output rectangle into the area
	sword off_y,
	Boolean clip,			// hard clip at the rectangle boundaries
	EGMosaicSourceType srctype)	// describes what kind of data
								// is stored in the block to put out
//*****
{
	SizeAsDWord bmp_size;
    sword loopX, loopY;
    word bmpSizeX, bmpSizeY;
	EGError stat = EGE_NO_ERROR;
	sword start_x, start_y;
	Rectangle winBounds;
	Boolean realDraw = FALSE;
	Boolean result;

    if(x1 > x2)
        return(EGE_WRONG_COORDINATES_X);

    if(y1 > y2)
        return(EGE_WRONG_COORDINATES_Y);

    // get bitmap size
	if(srctype == EGMST_BITMAP)
		bmp_size = BmpGetBitmapSize(file, block, &stat);
	else
		if(srctype == EGMST_GSTRING)
			bmp_size = ExtGrGetGStringSize(file, block, &stat);
		else
		{
			return(EGE_ILLEGAL_MOSIAC_SRC_TYPE);
		}

	// as soon as we have transparent bitmaps with a mask we have to redraw (if forced to)
	// as soon as we have transparent empty bitmaps we have to do nothing
	if(srctype == EGMST_BITMAP)
	{
		BmpMaskType maskType;

		maskType = BmpCheckMaskType(file, block, bmp_size);

		if(maskType == EGBMT_EMPTY)
		{
			return EGE_NO_ERROR;
		}

		if(maskType == EGBMT_PART)
		{
			realDraw = TRUE;
		}
	}

	// get window bounds
	GrGetWinBounds(gstate, &winBounds);

    // set clip region if needed
    if(clip)
	{
		GrSaveState(gstate);
        GrSetClipRect(gstate, PCT_INTERSECTION, x1, y1, x2, y2);

		if(winBounds.R_left < x1)
			winBounds.R_left = x1;
		if(winBounds.R_right > x2)
			winBounds.R_right = x2;
		if(winBounds.R_top < y1)
			winBounds.R_top = y1;
		if(winBounds.R_bottom > y2)
			winBounds.R_bottom = y2;
	}

	bmpSizeX = DWORD_WIDTH(bmp_size);
	bmpSizeY = DWORD_HEIGHT(bmp_size);

 	if(stat != EGE_NO_ERROR)
	{
		if(clip)
			GrRestoreState(gstate);
		return(stat);
	}

	if((!bmpSizeX) || (!bmpSizeY))
	{
		if(clip)
			GrRestoreState(gstate);
		return(EGE_ILLEGAL_BITMAP_SIZE);
	}

	if(off_x <= 0)
		start_x = x1 + off_x;
	else
		start_x = x1 - (bmpSizeX - off_x);
	if(start_x > x1)
	{
		if(clip)

			GrRestoreState(gstate);
		return(EGE_WRONG_COORDINATES_X);
	}

	if(off_y <= 0)
		start_y = y1 + off_y;
	else
		start_y = y1 - (bmpSizeY - off_y);
	if(start_y > y1)
	{
		if(clip)
			GrRestoreState(gstate);
		return(EGE_WRONG_COORDINATES_Y);
	}

	loopY = start_y;
    loopX = start_x;
    while(((loopY < y2) && (loopY >= start_y))
		&& ((loopX < x2) && (loopX >= start_x)))
    {
		Boolean visIn;
		Rectangle visRect, outRect;

		// determine the visible rect
		outRect.R_left = loopX;
		outRect.R_top = loopY;
		outRect.R_right = loopX + bmpSizeX;
		outRect.R_bottom = loopY + bmpSizeY;

		visRect = outRect;

		if(visRect.R_left < winBounds.R_left)
			visRect.R_left = winBounds.R_left;
		if(visRect.R_right > winBounds.R_right)
			visRect.R_right = winBounds.R_right;
		if(visRect.R_top < winBounds.R_top)
			visRect.R_top = winBounds.R_top;
		if(visRect.R_bottom > winBounds.R_bottom)
			visRect.R_bottom = winBounds.R_bottom;

		visIn = (GrTestRectInMask(gstate,
					visRect.R_left, visRect.R_top,
					visRect.R_right - 1, visRect.R_bottom - 1)
					== TRRT_IN);

		/* if completly in width */
		if(((visRect.R_right - visRect.R_left) == bmpSizeX) && visIn)
		{
			// move rightward
			// draw image
			if(srctype == EGMST_BITMAP)
				GrDrawHugeBitmap(gstate, loopX, loopY, file, block);
			else
				// no error detection,
				// assume that is is OK! FR_ERROR
				ExtGrDrawGString(gstate, loopX, loopY, file, block);

			loopY += bmpSizeY;

			if(realDraw)
			{
				result = extGrFillMosaicLineReal(gstate, &visRect, x2, FALSE, file, block, srctype, &stat, bmpSizeX);
			}
			else
			{
				result = extGrFillMosaicLine(gstate, &visRect, x2, FALSE, &stat);
			}
			if(!result)
				if((loopY < y2) && (loopY >= start_y))
				{
					if((visRect.R_bottom - visRect.R_top) == bmpSizeY)
					{
						visRect.R_right = x2;

						// if full height of the last line simply copy it
						if(realDraw)
						{
							extGrFillMosaicLineReal(gstate, &visRect, y2,
								TRUE, file, block, srctype, &stat, bmpSizeX);
						}
						else
						{
							extGrFillMosaicLine(gstate, &visRect, y2,
								TRUE, &stat);
						}

						loopY = y2;
					}
				}
		}
		else
			// complete height
			if(((visRect.R_bottom - visRect.R_top) == bmpSizeY) && visIn)
			{
				// move downward
				// draw image
				if(srctype == EGMST_BITMAP)
					GrDrawHugeBitmap(gstate, loopX, loopY, file, block);
				else
					// no error detection,
					// assume that is is OK! FR_ERROR
					ExtGrDrawGString(gstate, loopX, loopY, file, block);

				// fill down
				loopX += bmpSizeX;
				if(realDraw)
				{
					result = extGrFillMosaicLineReal(gstate, &visRect, y2, TRUE, file, block, srctype, &stat, bmpSizeX);
				}
				else
				{
					result = extGrFillMosaicLine(gstate, &visRect, y2, TRUE, &stat);
				}
				if(!result)
					if((loopX < x2) && (loopX >= start_x))
					{
						if((visRect.R_right - visRect.R_left) == bmpSizeX)
						{
							visRect.R_bottom = y2;

							// if full height of the last line simply copy it
							if(realDraw)
							{
								extGrFillMosaicLineReal(gstate, &visRect, x2,
									FALSE, block, file, srctype, &stat, bmpSizeX);
							}
							else
							{
								extGrFillMosaicLine(gstate, &visRect, x2,
									FALSE, &stat);
							}

							loopX = x2;
						}
					}
			}
			else
			{
				// move rightward
				// search source

				int localDestX;

				localDestX = loopX;
				while((localDestX < x2) && (localDestX >= start_x))
				{
					// draw
					if(srctype == EGMST_BITMAP)
						GrDrawHugeBitmap(gstate, localDestX, loopY, file, block);
					else
						// no error detection,
						// assume that is is OK! FR_ERROR
						ExtGrDrawGString(gstate, localDestX, loopY, file, block);

					// check if source

					if(GrTestRectInMask(gstate, localDestX, loopY,
							localDestX + bmpSizeX - 1, loopY + bmpSizeY - 1) == TRRT_IN)
					{
						Rectangle localRect;

						localRect.R_left = localDestX;
						localRect.R_top = loopY;
						localRect.R_right = localDestX + bmpSizeX;
						localRect.R_bottom = loopY + bmpSizeY;

						if(realDraw)
						{
							extGrFillMosaicLineReal(gstate, &localRect, x2, FALSE, file, block, srctype, &stat, bmpSizeX);
						}
						else
						{
							extGrFillMosaicLine(gstate, &localRect, x2, FALSE, &stat);
						}

						localDestX = x2;
					}

					localDestX += bmpSizeX;

				}

				loopY += bmpSizeY;
			}
	}

    // unset the clip region
	if(clip)
		GrRestoreState(gstate);

    // return status OK
    return(EGE_NO_ERROR);
}

/***************************************************************************/

EGError _pascal _export
BmpSetBitmapPalette(VMFileHandle file, VMBlockHandle block,
					RGBValue *palptr, byte start, word count)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle bmmem;
	byte *bmptr;
	word offset;
	word palsize;
	BMType bmtype;
	RGBValue *bmpalptr;

	bmptr = VMLock(file, block, &bmmem);

	if(bmptr)
	{
		bmtype = bmptr[0x1f];

		if((((bmtype & BMT_FORMAT) > BMF_MONO)
			&& ((bmtype & BMT_FORMAT) < BMF_24BIT)) &&
			(bmtype & BMT_PALETTE))
		{
			offset = *((word*)(&bmptr[0x28]));
			palsize = *((word*)(&bmptr[offset + 0x1a]));
			bmpalptr = (RGBValue*) (&bmptr[offset + 0x1c]);

			if((((word)start) + count) > palsize)
				stat = EGE_ILLEGAL_PALETTE_ENTRIES;
			else
				memcpy(&bmpalptr[start], palptr, count * sizeof(RGBValue));
		}
		else
			stat = EGE_BITMAP_NO_PALETTE;

		VMUnlock(bmmem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	return(stat);
}


/***************************************************************************/

EGError _pascal _export
BmpSetBitmapPaletteEntry(VMFileHandle file, VMBlockHandle block,
					byte red, byte green, byte blue, byte entry)
{
	RGBValue color;

	color.RGB_red = red;
	color.RGB_green = green;
	color.RGB_blue = blue;

	return(BmpSetBitmapPalette(file, block, &color, entry, 1));
}

/***************************************************************************/
