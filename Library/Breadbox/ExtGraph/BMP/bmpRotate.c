#include "extgraph.h"
#include <geos.h>
#include <vm.h>
#include <hugearr.h>
#include <ec.h>

byte
bmpGet1Bit(byte *dataPtr, word index)
{
	return dataPtr[index / 8] & (0x80 >> (index % 8));
}

byte
bmpGet4Bit(byte *dataPtr, word index)
{
	return (dataPtr[index / 2] & (0xF0 >> ((index % 2) * 4))) >> ((index % 2) ? 0 : 4);
}

void
bmpSet1Bit(byte *dataPtr, word index, byte data)
{
	if(data)
	{
		dataPtr[index / 8] |=  (0x80 >> (index % 8));
	}
	else
	{
		dataPtr[index / 8] &=  ~(0x80 >> (index % 8));
	}
}

void
bmpSet4Bit(byte *dataPtr, word index, byte data)
{
	data <<= 4;

	dataPtr[index / 2] &= (0x0F << ((index % 2) * 4));
	dataPtr[index / 2] |= (data >> ((index % 2) * 4));
}

EGError
bmpFlipBuffer(byte *dataPtr, BMType dataType, word pixels)
{
	word loopCount = 0;

	while(loopCount < (pixels / 2))
	{
		// swap the pixels here
		switch(dataType)
		{
			case BMF_MONO:
				{
					byte data1, data2;

					data1 = bmpGet1Bit(dataPtr, loopCount);
					data2 = bmpGet1Bit(dataPtr, pixels - loopCount - 1);

					bmpSet1Bit(dataPtr, loopCount, data2);
					bmpSet1Bit(dataPtr, pixels - loopCount - 1, data1);
				}
				break;

			case BMF_4BIT:
				{
					byte data1, data2;

					data1 = bmpGet4Bit(dataPtr, loopCount);
					data2 = bmpGet4Bit(dataPtr, pixels - loopCount - 1);

					bmpSet4Bit(dataPtr, loopCount, data2);
					bmpSet4Bit(dataPtr, pixels - loopCount - 1, data1);
				}
				break;

			case BMF_8BIT:
				{
					byte tempValue;

					tempValue = dataPtr[loopCount];
					dataPtr[loopCount] = dataPtr[pixels - loopCount - 1];
					dataPtr[pixels - loopCount - 1] = tempValue;
				}
				break;

			case BMF_24BIT:
				{
					RGBValue tempValue;

					tempValue = ((RGBValue*) dataPtr)[loopCount];
					((RGBValue*) dataPtr)[loopCount] = ((RGBValue*) dataPtr)[pixels - loopCount - 1];
					((RGBValue*) dataPtr)[pixels - loopCount - 1] = tempValue;
				}
				break;
		}

		loopCount++;
	}

	return EGE_NO_ERROR;
}

EGError
bmpFlipLines(VMFileHandle file, VMBlockHandle block, word start, word lines,
	Boolean vert, Boolean horiz, word pixels, BMType bmtype)
{
	word loopCount;

	/* flip mask */
	loopCount = 0;
	do
	{
		byte *elemPtr1, *elemPtr2;
		word elemSize, elemSize1, elemSize2, elemSize3, elemSize4;
		word loopCount2;
		word line1, line2;

		line1 = line2 = start + loopCount;
		if(vert)
		{
			line2 = start + lines - loopCount - 1;
		}

		HugeArrayLock(file, block, line1, (void**) &elemPtr1, &elemSize1);
		HugeArrayLock(file, block, line2, (void**) &elemPtr2, &elemSize2);

		HugeArrayUnlock(elemPtr1);
		HugeArrayUnlock(elemPtr2);

		elemSize = elemSize1;
		if(elemSize < elemSize2)
		{
			elemSize = elemSize2;
			if (elemSize != elemSize1)
			    HugeArrayResize(file, block, line1, elemSize);
		}
		else
		{
			if (elemSize != elemSize2)
			    HugeArrayResize(file, block, line2, elemSize);
		}

		HugeArrayLock(file, block, line1, (void**) &elemPtr1, &elemSize3);
		HugeArrayLock(file, block, line2, (void**) &elemPtr2, &elemSize4);

		loopCount2 = 0;
		while(loopCount2 < elemSize)
		{
			byte swapByte;

			swapByte = elemPtr1[loopCount2];
			elemPtr1[loopCount2] = elemPtr2[loopCount2];
			elemPtr2[loopCount2] = swapByte;

			loopCount2++;
		}

		if(horiz)
		{
			word offset = 0;

			if(bmtype & BMT_MASK)
			{
				offset = (pixels + 7) / 8;

				bmpFlipBuffer(elemPtr1, bmtype & BMF_MONO, pixels);

				if(vert)
				{
					bmpFlipBuffer(elemPtr2, bmtype & BMF_MONO, pixels);
				}
			}

			bmpFlipBuffer(elemPtr1 + offset, bmtype & BMT_FORMAT, pixels);

			if(vert)
			{
				bmpFlipBuffer(elemPtr2 + offset, bmtype & BMT_FORMAT, pixels);
			}
		}

		HugeArrayDirty(elemPtr1);
		HugeArrayDirty(elemPtr2);
		HugeArrayUnlock(elemPtr1);
		HugeArrayUnlock(elemPtr2);

		elemSize = elemSize1;
		if(elemSize < elemSize2)
		{
		    if (elemSize != elemSize2)
			HugeArrayResize(file, block, line2, elemSize);
		}
		else
		{
			elemSize = elemSize2;
			if (elemSize != elemSize1)
			    HugeArrayResize(file, block, line1, elemSize);
		}

		loopCount++;
	}
	while((vert ? (lines / 2) : lines) > loopCount);

    return EGE_NO_ERROR;
}

void _near copypix(byte *p1, word x1, byte *p2, word x2, BMFormat bmform)
{
	switch(bmform)
	{
	  case BMF_MONO:
		bmpSet1Bit(p2, x2, bmpGet1Bit(p1, x1));
		break;

	  case BMF_4BIT:
		bmpSet4Bit(p2, x2, bmpGet4Bit(p1, x1));
		break;

	  case BMF_8BIT:
		p2[x2] = p1[x1];
        break;

	  case BMF_24BIT:
        ((RGBValue*)p2)[x2].RGB_red = ((RGBValue*)p1)[x1].RGB_red;
        ((RGBValue*)p2)[x2].RGB_green = ((RGBValue*)p1)[x1].RGB_green;
        ((RGBValue*)p2)[x2].RGB_blue = ((RGBValue*)p1)[x1].RGB_blue;
		break;
	}
}

/*
 * 270 deg CCW: (x,y) -> (srcheight-y-1,x)
 * 90 deg CCW: (x,y) -> (y,srcwidth-x-1)
 */
void
bmpRot270(VMFileHandle file, VMBlockHandle src, VMBlockHandle dst,
    word srcwidth, word srcheight, BMType bmtype)
{
    word x,y;
    word x1,y1,x2,y2;
	byte *elemPtr1, *elemPtr2;
	word elemSize1, elemSize2;
    BMFormat bmform = bmtype & BMT_FORMAT;
    word offset1 = 0, offset2 = 0;

    if(bmtype & BMT_MASK)               // Masks at the beginning of each line?
    {
	  offset1 = (srcwidth + 7) / 8;
      offset2 = (srcheight + 7) / 8;
    }

    for(y1=0; y1<srcheight; y1=y2)
    {
      if(y1+64>srcheight) y2=srcheight; else y2=y1+64;

      for(x1=0; x1<srcwidth; x1=x2)
      {
        if(x1+64>srcwidth) x2=srcwidth; else x2=x1+64;

        HugeArrayLock(file, src, y1, (void**) &elemPtr1, &elemSize1);
        for(y=y1; y<y2; y++,HugeArrayNext((void**) &elemPtr1, &elemSize1))
        {
          HugeArrayLock(file, dst, x1, (void**) &elemPtr2, &elemSize2);
          for(x=x1; x<x2; x++,HugeArrayNext((void**) &elemPtr2, &elemSize2))
          {
            copypix(elemPtr1+offset1, x, elemPtr2+offset2, srcheight-y-1, bmform);
            if(offset1)
              copypix(elemPtr1, x, elemPtr2, srcheight-y-1, BMF_MONO);
            HugeArrayDirty(elemPtr2);
          }
          HugeArrayUnlock(elemPtr2);
        }
        HugeArrayUnlock(elemPtr1);
      }
    }
}

void
bmpRot90(VMFileHandle file, VMBlockHandle src, VMBlockHandle dst,
    word srcwidth, word srcheight, BMType bmtype)
{
    sword x,y;
    sword x1,y1,x2,y2;
	byte *elemPtr1, *elemPtr2;
	word elemSize1, elemSize2;
    BMFormat bmform = bmtype & BMT_FORMAT;
    word offset1 = 0, offset2 = 0;

    if(bmtype & BMT_MASK)               // Masks at the beginning of each line?
    {
	  offset1 = (srcwidth + 7) / 8;
      offset2 = (srcheight + 7) / 8;
    }

    for(y1=0; y1<srcheight; y1=y2)
    {
      if(y1+64>srcheight) y2=srcheight; else y2=y1+64;

      for(x1=0; x1<srcwidth; x1=x2)
      {
        if(x1+64>srcwidth) x2=srcwidth; else x2=x1+64;

        HugeArrayLock(file, src, y1, (void**) &elemPtr1, &elemSize1);
        for(y=y1; y<y2; y++,HugeArrayNext((void**) &elemPtr1, &elemSize1))
        {
          HugeArrayLock(file, dst, srcwidth-x2, (void**) &elemPtr2, &elemSize2);
          for(x=x2-1; (int)x>=(int)x1; x--,HugeArrayNext((void**)
	  					&elemPtr2, &elemSize2))
          {
            copypix(elemPtr1+offset1, x, elemPtr2+offset2, y, bmform);
            if(offset1)
              copypix(elemPtr1, x, elemPtr2, y, BMF_MONO);
            HugeArrayDirty(elemPtr2);
          }
          HugeArrayUnlock(elemPtr2);
        }
        HugeArrayUnlock(elemPtr1);
      }
    }
}

/*
 * Generic routine for all operations that have to be performed by first
 * uncompressing the bitmap.
 */

typedef enum {
  BOT_ROT_90,
  BOT_ROT_180,
  BOT_ROT_270,
  BOT_FLIP_H,
} BmpOpType;

EGError
BmpOp(BmpOpType op, VMFileHandle file, VMBlockHandle *blockPtr)
{
    BMType bmtype;
	EGError stat = EGE_NO_ERROR, palerr;
	SizeAsDWord bmsize;
	VMBlockHandle block = *blockPtr;
	VMBlockHandle newBlock;
	BMCompact compact;
    sword width,height;

	/* get bitmap type */
	compact = BmpGetBitmapCompact(file, block, &stat);
	if(stat == EGE_NO_ERROR)
	{
		bmtype = BmpGetBitmapType(file, block, &stat);
	}
	if((stat == EGE_NO_ERROR) && (compact != BMC_UNCOMPACTED))
	{
		newBlock = GrUncompactBitmap(file, block, file);
		if(newBlock && (newBlock != block))
		{
			(*blockPtr) = newBlock;
			VMFreeVMChain(file, VMCHAIN_MAKE_FROM_VM_BLOCK(block));
			block = newBlock;
		}
	}
	if(stat == EGE_NO_ERROR)
	{
		bmsize = BmpGetBitmapSize(file, block, &stat);
	    width = DWORD_WIDTH(bmsize);
	    height = DWORD_HEIGHT(bmsize);
	}

	/* check the type */
	if(stat == EGE_NO_ERROR)
	{
        switch(op)
        {
        case BOT_ROT_90:
        case BOT_ROT_270:
	      newBlock = GrCreateBitmapRaw(bmtype, height, width, file);
	      if(newBlock)
          {
              RGBValue pal[256];
              word palsize;

              /* Transfer palette */
              palsize = BmpGetBitmapPalette(file, block, pal, 256, &palerr);
              if(palsize)
                BmpSetBitmapPalette(file, newBlock, pal, 0, palsize);

              (*blockPtr) = newBlock;

              if(op==BOT_ROT_90)
                bmpRot90(file, block, newBlock, width, height, bmtype);
              else
                bmpRot270(file, block, newBlock, width, height, bmtype);

              VMFreeVMChain(file, VMCHAIN_MAKE_FROM_VM_BLOCK(block));
		      block = newBlock;
	      }
          else
              stat = EGE_CANT_CREATE_BITMAP;
          break;

        case BOT_ROT_180:
		  stat = bmpFlipLines(file, block, 0, height, TRUE, TRUE, width, bmtype);
          break;

        case BOT_FLIP_H:
		  stat = bmpFlipLines(file, block, 0, height, FALSE, TRUE, width, bmtype);
          break;

        default:
          EC_ERROR(-1);
        }
	}

	if(compact != BMC_UNCOMPACTED)
	{
		newBlock = GrCompactBitmap(file, block, file);
		if(newBlock && (newBlock != block))
		{
			(*blockPtr) = newBlock;
			VMFreeVMChain(file, VMCHAIN_MAKE_FROM_VM_BLOCK(block));
			block = newBlock;
		}
	}

	return stat;
}

EGError _pascal _export
BmpRotate90(VMFileHandle file, VMBlockHandle *blockPtr)
{
    return BmpOp(BOT_ROT_90, file, blockPtr);
}

EGError _pascal _export
BmpRotate180(VMFileHandle file, VMBlockHandle *blockPtr)
{
    return BmpOp(BOT_ROT_180, file, blockPtr);
}

EGError _pascal _export
BmpRotate270(VMFileHandle file, VMBlockHandle *blockPtr)
{
    return BmpOp(BOT_ROT_270, file, blockPtr);
}

EGError _pascal _export
BmpFlipVertical(VMFileHandle file, VMBlockHandle *blockPtr)
{
	BMType bmtype;
	EGError stat = EGE_NO_ERROR;
	SizeAsDWord bmsize;
	VMBlockHandle block = *blockPtr;

	/* get bitmap type */
	bmtype = BmpGetBitmapType(file, block, &stat);
	if(stat == EGE_NO_ERROR)
	{
		bmsize = BmpGetBitmapSize(file, block, &stat);
	}

	/* check the type */
	if(stat == EGE_NO_ERROR)
	{
		stat = bmpFlipLines(file, block, 0, DWORD_HEIGHT(bmsize), TRUE, FALSE, DWORD_WIDTH(bmsize), bmtype);
	}

	return stat;
}

EGError _pascal _export
BmpFlipHorizontal(VMFileHandle file, VMBlockHandle *blockPtr)
{
    return BmpOp(BOT_FLIP_H, file, blockPtr);
}
