/*******************************************************************
* PNG export.
* Started in 03/2025 by MeyerK for the FreeGEOS project.
*
* The code itself was written from scratch - relying heavily
* on ChatGPT for the PNG-specific parts, again.
*******************************************************************/

/* Includes */
#include <extgraph.h>
#include <pnglib.h>
#include "common.h"

/********************************************************************
* forward declarations for internal functions
********************************************************************/

/* returns FALSE on error */
#define FILE_WRITE_CHECKED(file, buffer, size) (FileWrite((file), (buffer), (size), FALSE) == (size))

/* Chunk Writing Functions */
PngError _pascal writePngHeader(FileHandle file);
PngError _pascal writeIHDRChunk(FileHandle file, pngIHDRData* ihdrData);
PngError _pascal writePLTEChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, BMType bmptype, BMFormat bitform, pngIHDRData* ihdrData);
PngError _pascal writeIDATChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, pngIHDRData* ihdrData, BMType bmptype, BMFormat bitform);
PngError _pascal writeIENDChunk(FileHandle file);

/* Processing Functions */
static Boolean _pascal unpackPackBits(byte *src, word srcSize, byte *dest, word destSize);
dword _pascal calculateScanlineBufferSize(dword width, BMFormat bitform);
word _pascal calcBytesPerPixel(pngIHDRData* ihdrData);
byte _pascal getFilterForScanline(byte* scanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth);
void _pascal filterScanline(byte* scanlinePtr, byte* filteredScanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth);
Boolean _pascal deflateScanline(void *filteredScanlinePtr, word scanlineSize, z_stream *zstrm, FileHandle file, dword *idatChunkSize, dword *crc);

/* Utility Functions */
word _pascal mapGEOSToPNGColorType(BMType bmptype);

/*********************************************************************
* Export a GEOS bitmap block to PNG and stream the required chunks.
*********************************************************************/
PngError _pascal _export pngExportBitmapFHandle(VMFileHandle srcfile, VMBlockHandle bmpblock, FileHandle destfile)
{
    dword width = 0;
    dword height = 0;
    BMType bmptype = 0;
    BMFormat bitform = 0;
    SizeAsDWord size_xy = 0;
    PngError stat = PE_NO_ERROR;
    EGError egStat = EGE_NO_ERROR;
    pngIHDRData ihdrData = {0};
    Boolean hasMask = FALSE;

    /* Determine bitmap size */
    size_xy = BmpGetBitmapSize(srcfile, bmpblock, &egStat);
    if (egStat != EGE_NO_ERROR) {
        return PE_INVALID_BITMAP;
    }
    width = DWORD_WIDTH(size_xy);
    height = DWORD_HEIGHT(size_xy);

    /* Determine type */
    bmptype = BmpGetBitmapType(srcfile, bmpblock, &egStat);
    if (egStat != EGE_NO_ERROR) {
        return PE_INVALID_BITMAP;
    }
    bitform = bmptype & BMT_FORMAT;

    /* Set up ihdrData - we will need it a lot */
    /* Determine color type from GEOS format */
    ihdrData.colorType = mapGEOSToPNGColorType(bmptype);

    /* Determine bit depth based on BMFormat */
    hasMask = (bmptype & BMT_MASK) ? TRUE : FALSE;

    switch (bitform)
    {
        case BMF_MONO:  ihdrData.bitDepth = hasMask ? 8 : 1; break;
        case BMF_4BIT:  ihdrData.bitDepth = hasMask ? 8 : 4; break;
        case BMF_8BIT:  ihdrData.bitDepth = 8; break;
        case BMF_24BIT: ihdrData.bitDepth = 8; break; /* 8 bits per channel in truecolor */
        default:        return PE_INVALID_BITMAP; /* Unsupported format */
    }

    /* Set PNG standard fields */
    ihdrData.width = swapEndian(width);
    ihdrData.height = swapEndian(height);
    ihdrData.compressionMethod = 0; /* Default PNG compression method */
    ihdrData.filterMethod = 0; /* PNG allows adaptive filtering, default is 0 */
    ihdrData.interlaceMethod = 0; /* No interlacing */

    /* start writing chunks */
    if ((stat = writePngHeader(destfile)) != PE_NO_ERROR) {
        return stat;
    }

    /* Write IHDR chunk */
    if ((stat = writeIHDRChunk(destfile, &ihdrData)) != PE_NO_ERROR) {
        return stat;
    }

    /* Write PLTE chunk (if applicable) */
    if ((stat = writePLTEChunk(destfile, srcfile, bmpblock, bmptype, bitform, &ihdrData)) != PE_NO_ERROR) {
        return stat;
    }

    /* Write IDAT chunk (handles scanline processing, filtering and compression) */
    if ((stat = writeIDATChunk(destfile, srcfile, bmpblock, &ihdrData, bmptype, bitform)) != PE_NO_ERROR) {
        return stat;
    }

    /* Write IEND chunk */
    if ((stat = writeIENDChunk(destfile)) != PE_NO_ERROR) {
        return stat;
    }

    return stat;
}


/*********************************************************************
* Chunk writing functions
**********************************************************************/

/*********************************************************************
* Write the canonical PNG file signature at the current file offset.
*********************************************************************/
PngError _pascal writePngHeader(FileHandle file)
{
    /* make sure we are at the beginning of the file */
    FilePos(file, 0, FILE_POS_START);

    /* Write the PNG signature to the file */
    if (!FILE_WRITE_CHECKED(file, PNG_SIGNATURE, sizeof(PNG_SIGNATURE))) {
        return PE_WRITE_PROBLEM; /* Failed to write signature */
    }

    return PE_NO_ERROR; /* Successfully wrote PNG header */
}

/*********************************************************************
* Emit the IHDR chunk header and payload using the prepared metadata.
*********************************************************************/
PngError _pascal writeIHDRChunk(FileHandle file, pngIHDRData* ihdrData)
{
    pngChunkHeader ihdrHeader = {0};
    dword crc = 0;

    /* Prepare IHDR chunk header */
    ihdrHeader.length = swapEndian(sizeof(pngIHDRData));
    ihdrHeader.type = swapEndian(PNG_CHUNK_IHDR);

    /* Write IHDR chunk header */
    if (!FILE_WRITE_CHECKED(file, &ihdrHeader, sizeof(ihdrHeader))) {
        return PE_WRITE_PROBLEM; /* Failed to write IHDR header */
    }

    /* Initialize CRC calculation */
    crc = crc32(0, (byte *)&ihdrHeader.type, sizeof(ihdrHeader.type));
    crc = crc32(crc, (byte *)ihdrData, sizeof(*ihdrData));

    /* Write IHDR data */
    if (!FILE_WRITE_CHECKED(file, ihdrData, sizeof(pngIHDRData))) {
        return PE_WRITE_PROBLEM; /* Failed to write IHDR data */
    }

    /* Write CRC at the end of the IHDR chunk */
    crc = swapEndian(crc);
    if (!FILE_WRITE_CHECKED(file, &crc, sizeof(crc))) {
        return PE_WRITE_PROBLEM; /* Failed to write IHDR CRC */
    }

    return PE_NO_ERROR;
}

/*********************************************************************
* Emit a PLTE chunk for paletted images, loading palette data as needed.
*********************************************************************/
PngError _pascal writePLTEChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, BMType bmptype, BMFormat bitform, pngIHDRData* ihdrData)
{
    pngChunkHeader header = {0};
    dword crc = 0;
    word i = 0;
    word numEntries = 0;
    RGBValue *palPtr = NULL;
    MemHandle palMem = NullHandle;
    EGError bmpErr = EGE_NO_ERROR;
    byte rgb[3] = {0};
    Boolean stat = PE_NO_ERROR;

    if ((bmptype & BMT_PALETTE) && ihdrData && (ihdrData->colorType == PNG_COLOR_TYPE_PALETTE))
    {
        numEntries = (bitform == BMF_4BIT) ? 16 : 256;
        palMem = MemAlloc((sizeof(RGBValue) * numEntries), HF_SWAPABLE, HAF_ZERO_INIT);

        if (!palMem) {
            stat = PE_OUT_OF_MEMORY;
            goto exit;
        }

        palPtr = (RGBValue*) MemLock(palMem);
        if (!palPtr) {
            stat = PE_BLOCK_LOCK_FAILURE;
            goto exit;
        }

        /* Get palette of this bitmap */
        BmpGetBitmapPalette(srcfile, bmpblock, palPtr, numEntries, &bmpErr);
        if (bmpErr != EGE_NO_ERROR) {
            stat = PE_PALETTE_RETRIEVAL_FAILURE;
            goto exit;
        }

        /* Write chunk header */
        header.length = swapEndian((dword)(numEntries * 3));  /* Each entry is 3 bytes (RGB) */
        header.type = swapEndian((dword)PNG_CHUNK_PLTE);

        if (!FILE_WRITE_CHECKED(file, &header, sizeof(header))) {
            stat = PE_WRITE_PROBLEM;
            goto exit;
        }

        /* Initialize CRC calculation */
        crc = crc32(0, (byte *)&header.type, sizeof(header.type));

        /* Write palette data and update CRC per byte */
        for (i = 0; i < numEntries; i++)
        {
            rgb[0] = palPtr[i].RGB_red;
            rgb[1] = palPtr[i].RGB_green;
            rgb[2] = palPtr[i].RGB_blue;

            if (!FILE_WRITE_CHECKED(file, rgb, 3)) {
                stat = PE_WRITE_PROBLEM;
                goto exit;
            }

            crc = crc32(crc, rgb, 3); /* Update CRC correctly for each RGB triplet */
        }

        /* Finalize CRC */
        crc = swapEndian(crc);
        if (!FILE_WRITE_CHECKED(file, &crc, sizeof(crc))) {
            stat = PE_WRITE_PROBLEM;
            goto exit;
        }
    }

exit:
    if (palMem) MemFree(palMem);
    return stat;
}

/*********************************************************************
* Compress bitmap rows and write the IDAT chunk containing image data.
*********************************************************************/
PngError _pascal writeIDATChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, pngIHDRData* ihdrData, BMType bmptype, BMFormat bitform)
{
    void *scanlinePtr = NULL;
    word scanlineSize = 0;
    dword pngRowBytes = 0;
    dword scanlineSizeWithFilterByte = 0;
    dword idatChunkSize = 0;
    dword idatChunkPos = 0;
    dword crc = 0;
    z_stream zstrm = {0};
    Boolean zstrmInited = FALSE;
    word y = 0;
    pngChunkHeader idatHeader = {0};
    PngError stat = PE_NO_ERROR; /* the concept is: if anything fails, this is set to FALSE */

    MemHandle filteredScanlineHan = NullHandle;
    MemHandle prevScanlineHan = NullHandle;
    MemHandle pngScanlineHan = NullHandle;
    MemHandle unpackedScanlineHan = NullHandle;
    byte *filteredScanlinePtr = NULL;
    byte *prevScanlinePtr = NULL;
    byte *pngScanlinePtr = NULL;
    byte *unpackedScanlinePtr = NULL;
    word bytesPerPixel = calcBytesPerPixel(ihdrData);
    Boolean hasMask = (bmptype & BMT_MASK) ? TRUE : FALSE;
    dword width = swapEndian(ihdrData->width);
    dword height = swapEndian(ihdrData->height);
    word maskBytesPerRow = hasMask ? (word)((width + 7) >> 3) : 0;
    BMCompact compact = BMC_UNCOMPACTED;
    Boolean isPackBits = FALSE;
    dword geosPixelRowBytes = 0;
    dword unpackedRowBytes = 0;
    RGBValue *palettePtr = NULL;
    MemHandle paletteHan = NullHandle;
    word paletteEntries = 0;

    if (bytesPerPixel == 0) {
        stat = PE_OTHER_ERROR; /* Invalid format */
        goto exit;
    }

    {
        EGError compactErr = EGE_NO_ERROR;
        compact = BmpGetBitmapCompact(srcfile, bmpblock, &compactErr);
        if (compactErr != EGE_NO_ERROR)
        {
            stat = PE_INVALID_BITMAP;
            goto exit;
        }
        isPackBits = (compact == BMC_PACKBITS);
    }

    switch (bitform)
    {
        case BMF_MONO:
            geosPixelRowBytes = (width + 7) >> 3;
            break;
        case BMF_4BIT:
            geosPixelRowBytes = (width + 1) >> 1;
            break;
        case BMF_8BIT:
            geosPixelRowBytes = width;
            break;
        case BMF_24BIT:
            geosPixelRowBytes = width * 3;
            break;
        default:
            stat = PE_OTHER_ERROR;
            goto exit;
    }

    unpackedRowBytes = maskBytesPerRow + geosPixelRowBytes;

    if (isPackBits)
    {
        if (unpackedRowBytes == 0 || unpackedRowBytes > 0xFFFF)
        {
            stat = PE_OTHER_ERROR;
            goto exit;
        }

        unpackedScanlineHan = MemAlloc((word)unpackedRowBytes, HF_SWAPABLE, HAF_ZERO_INIT);
        if (!unpackedScanlineHan)
        {
            stat = PE_OUT_OF_MEMORY;
            goto exit;
        }

        unpackedScanlinePtr = MemLock(unpackedScanlineHan);
        if (!unpackedScanlinePtr)
        {
            stat = PE_BLOCK_LOCK_FAILURE;
            goto exit;
        }
    }

    /* Load palette if needed for conversion (masked paletted bitmaps expand to RGBA) */
    if (hasMask && (bitform == BMF_4BIT || bitform == BMF_8BIT))
    {
        EGError palErr;
        paletteEntries = (bitform == BMF_4BIT) ? 16 : 256;
        paletteHan = MemAlloc((word)(sizeof(RGBValue) * paletteEntries), HF_SWAPABLE, HAF_ZERO_INIT);
        if (!paletteHan)
        {
            stat = PE_OUT_OF_MEMORY;
            goto exit;
        }

        palettePtr = (RGBValue*)MemLock(paletteHan);
        if (!palettePtr)
        {
            stat = PE_BLOCK_LOCK_FAILURE;
            goto exit;
        }

        palErr = EGE_NO_ERROR;
        BmpGetBitmapPalette(srcfile, bmpblock, palettePtr, paletteEntries, &palErr);
        if (palErr != EGE_NO_ERROR)
        {
            stat = PE_PALETTE_RETRIEVAL_FAILURE;
            goto exit;
        }
    }

    /* Calculate PNG row bytes */
    switch (ihdrData->colorType)
    {
        case PNG_COLOR_TYPE_GREY:
        case PNG_COLOR_TYPE_PALETTE:
            pngRowBytes = ((width * ihdrData->bitDepth) + 7) >> 3;
            break;
        case PNG_COLOR_TYPE_RGB:
            pngRowBytes = width * 3 * (ihdrData->bitDepth / 8);
            break;
        case PNG_COLOR_TYPE_GREY_ALPHA:
            pngRowBytes = width * 2 * (ihdrData->bitDepth / 8);
            break;
        case PNG_COLOR_TYPE_RGBA:
            pngRowBytes = width * 4 * (ihdrData->bitDepth / 8);
            break;
        default:
            stat = PE_OTHER_ERROR;
            goto exit;
    }

    if (pngRowBytes == 0)
    {
        stat = PE_OTHER_ERROR;
        goto exit;
    }

    scanlineSizeWithFilterByte = pngRowBytes + 1; /* +1 for PNG filter byte */
    if (scanlineSizeWithFilterByte == 1) {
        stat = PE_OTHER_ERROR; /* Invalid format or scanline too small */
        goto exit;
    }

    /* Allocate memory for the output scanline buffer and previous scanline buffer */
    filteredScanlineHan = MemAlloc((word)scanlineSizeWithFilterByte, HF_SWAPABLE, HAF_ZERO_INIT);
    if (!filteredScanlineHan) {
        stat = PE_OUT_OF_MEMORY; /* Memory allocation failed */
        goto exit;
    }

    prevScanlineHan = MemAlloc((word)pngRowBytes, HF_SWAPABLE, HAF_ZERO_INIT);
    if (!prevScanlineHan) {
        stat = PE_OUT_OF_MEMORY; /* Memory allocation failed */
        goto exit;
    }

    pngScanlineHan = MemAlloc((word)pngRowBytes, HF_SWAPABLE, HAF_ZERO_INIT);
    if (!pngScanlineHan) {
        stat = PE_OUT_OF_MEMORY;
        goto exit;
    }

    /* Lock the memory */
    filteredScanlinePtr = MemLock(filteredScanlineHan);
    if (!filteredScanlinePtr) {
        stat = PE_BLOCK_LOCK_FAILURE; /* Memory lock failed */
        goto exit;
    }

    prevScanlinePtr = MemLock(prevScanlineHan);
    if (!prevScanlinePtr) {
        stat = PE_BLOCK_LOCK_FAILURE; /* Memory lock failed */
        goto exit;
    }

    pngScanlinePtr = MemLock(pngScanlineHan);
    if (!pngScanlinePtr) {
        stat = PE_BLOCK_LOCK_FAILURE;
        goto exit;
    }

    /* Initiate IDAT chunk */
    idatHeader.length = 0; /* Placeholder for size */
    idatHeader.type = swapEndian(PNG_CHUNK_IDAT);

    /* Store position of IDAT chunk size field */
    idatChunkPos = FilePos(file, 0, FILE_POS_RELATIVE);

    /* Write IDAT chunk header (size will be updated later) */
    if (!FILE_WRITE_CHECKED(file, &idatHeader, sizeof(idatHeader))) {
        stat = PE_WRITE_PROBLEM; /* Failed to write chunk header */
        goto exit;
    }

    /* Initialize CRC calculation */
    crc = crc32(0, (byte *)&idatHeader.type, sizeof(idatHeader.type));

    /* Initialize Zlib */
    zstrm.zalloc = Z_NULL;
    zstrm.zfree = Z_NULL;
    zstrm.opaque = Z_NULL;
    if (deflateInit(&zstrm, Z_DEFAULT_COMPRESSION) != Z_OK) {
        stat = PE_OTHER_ERROR; /* Compression initialization failed */
        goto exit;
    } else {
        zstrmInited = TRUE;
    }

    /* Loop through all scanlines */
    for (y = 0; y < height; y++)
    {
        if (HAL_COUNT(HugeArrayLock(srcfile, bmpblock, y, &scanlinePtr, &scanlineSize)))
        {
            byte *srcPtr = (byte *)scanlinePtr;
            byte *rowPtr = srcPtr;
            byte *maskPtr = NULL;
            byte *pixelPtr = NULL;
            byte *dst = pngScanlinePtr;
            dword x;

            if (isPackBits)
            {
                if (!unpackPackBits(srcPtr, scanlineSize, unpackedScanlinePtr, (word)unpackedRowBytes))
                {
                    HugeArrayUnlock(scanlinePtr);
                    stat = PE_OTHER_ERROR;
                    break;
                }

                rowPtr = unpackedScanlinePtr;
            }

            maskPtr = rowPtr;
            pixelPtr = maskPtr + maskBytesPerRow;

            switch (ihdrData->colorType)
            {
                case PNG_COLOR_TYPE_GREY:
                case PNG_COLOR_TYPE_PALETTE:
                {
                    /* Copy pixel data directly, ignoring mask (there is none) */
                    memcpy(dst, pixelPtr, (word)pngRowBytes);
                    break;
                }

                case PNG_COLOR_TYPE_RGB:
                {
                    memcpy(dst, pixelPtr, (word)pngRowBytes);
                    break;
                }

                case PNG_COLOR_TYPE_GREY_ALPHA:
                {
                    dword maskIndex = 0;
                    byte bitMask = 0x80;
                    byte *src = pixelPtr;

                    for (x = 0; x < width; x++)
                    {
                        byte pixelValue = (src[ x >> 3 ] >> (7 - (x & 7))) & 0x1;
                        dst[0] = pixelValue ? 0xFF : 0x00;

                        dst[1] = (maskPtr[maskIndex] & bitMask) ? 0xFF : 0x00;

                        dst += 2;

                        bitMask >>= 1;
                        if (bitMask == 0)
                        {
                            bitMask = 0x80;
                            maskIndex++;
                        }
                    }
                    break;
                }

                case PNG_COLOR_TYPE_RGBA:
                {
                    dword maskIndex = 0;
                    byte bitMask = 0x80;
                    for (x = 0; x < width; x++)
                    {
                        byte alpha = (maskPtr[maskIndex] & bitMask) ? 0xFF : 0x00;

                        switch (bitform)
                        {
                            case BMF_24BIT:
                            {
                                byte *src = pixelPtr + (x * 3);
                                dst[0] = src[0];
                                dst[1] = src[1];
                                dst[2] = src[2];
                                dst[3] = alpha;
                                break;
                            }
                            case BMF_8BIT:
                            {
                                byte index = pixelPtr[x];
                                RGBValue color = palettePtr[index];
                                dst[0] = color.RGB_red;
                                dst[1] = color.RGB_green;
                                dst[2] = color.RGB_blue;
                                dst[3] = alpha;
                                break;
                            }
                            case BMF_4BIT:
                            {
                                byte packed = pixelPtr[x >> 1];
                                byte index = (x & 1) ? (packed & 0x0F) : (packed >> 4);
                                RGBValue color = palettePtr[index];
                                dst[0] = color.RGB_red;
                                dst[1] = color.RGB_green;
                                dst[2] = color.RGB_blue;
                                dst[3] = alpha;
                                break;
                            }
                            default:
                                dst[0] = dst[1] = dst[2] = 0;
                                dst[3] = alpha;
                                break;
                        }

                        dst += 4;

                        bitMask >>= 1;
                        if (bitMask == 0)
                        {
                            bitMask = 0x80;
                            maskIndex++;
                        }
                    }
                    break;
                }
            }

            /* Apply best PNG filter using prepared PNG scanline data */
            filterScanline(pngScanlinePtr, filteredScanlinePtr, prevScanlinePtr, (word)pngRowBytes, bytesPerPixel, ihdrData->bitDepth);

            /* Update prevScanline with the PNG data for next iteration */
            memcpy(prevScanlinePtr, pngScanlinePtr, (word)pngRowBytes);

            /* Deflate and append to IDAT chunk */
            if (!deflateScanline(filteredScanlinePtr, (word)scanlineSizeWithFilterByte, &zstrm, file, &idatChunkSize, &crc))
            {
                HugeArrayUnlock(scanlinePtr);
                stat = PE_OTHER_ERROR; /* Compression failed */
                break;
            }

            /* Unlock source scanline */
            HugeArrayUnlock(scanlinePtr);
        }
        else
        {
            break; /* whatever the reason, this is a REGULAR exit... */
        }
    }

    /* Update IDAT chunk length */
    idatHeader.length = swapEndian(idatChunkSize);
    FilePos(file, idatChunkPos, FILE_POS_START);
    if (!FILE_WRITE_CHECKED(file, &idatHeader.length, sizeof(idatHeader.length))) {
        stat = PE_WRITE_PROBLEM; /* Failed to update chunk length */
        goto exit;
    }
    FilePos(file, 0, FILE_POS_END);

    /* Write CRC at the end of the IDAT chunk */
    crc = swapEndian(crc);
    if (!FILE_WRITE_CHECKED(file, &crc, sizeof(crc))) {
        stat = PE_WRITE_PROBLEM; /* Failed to write CRC */
        goto exit;
    }

exit:
    /* Finalize deflation */
    if (zstrmInited == TRUE) deflateEnd(&zstrm);
    if (filteredScanlineHan) MemFree(filteredScanlineHan);
    if (prevScanlineHan) MemFree(prevScanlineHan);
    if (pngScanlineHan) MemFree(pngScanlineHan);
    if (unpackedScanlineHan) MemFree(unpackedScanlineHan);
    if (palettePtr) MemUnlock(paletteHan);
    if (paletteHan) MemFree(paletteHan);

    return stat;
}

/*********************************************************************
* Select and apply the optimal PNG filter for the provided scanline.
*********************************************************************/
PngError _pascal writeIENDChunk(FileHandle file)
{
    pngChunkHeader iendHeader = {0};
    dword crc = {0};

    /* Prepare IEND chunk header */
    iendHeader.length = 0; /* IEND has no data */
    iendHeader.type = swapEndian(PNG_CHUNK_IEND);

    /* Write IEND chunk header */
    if (!FILE_WRITE_CHECKED(file, &iendHeader, sizeof(iendHeader))) {
        return PE_WRITE_PROBLEM; /* Failed to write IEND header */
    }

    /* Calculate CRC for IEND chunk */
    crc = crc32(0, (byte *)&iendHeader.type, sizeof(iendHeader.type));
    crc = swapEndian(crc);

    /* Write CRC at the end of the IEND chunk */
    if (!FILE_WRITE_CHECKED(file, &crc, sizeof(crc))) {
        return PE_WRITE_PROBLEM; /* Failed to write IEND CRC */
    }

    return PE_NO_ERROR;
}

/*********************************************************************
* The "worker" functions
*********************************************************************/

/*********************************************************************
* Feed a filtered scanline into zlib and append the output to IDAT.
*********************************************************************/
byte _pascal getFilterForScanline(byte* scanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth)
{
    word filterTypes[] = {PNG_FILTER_NONE, PNG_FILTER_SUB, PNG_FILTER_UP, PNG_FILTER_AVERAGE, PNG_FILTER_PAETH};
    word bestFilter = PNG_FILTER_NONE;
    dword bestSum = 0xFFFFFFFF; /* Large initial value */
    word i = 0;
    word x = 0;
    dword sum = 0;
    MemHandle testBufferMem = NullHandle;
    byte *testBuffer = NULL;
    byte *in = scanlinePtr;
    byte *prev = prevScanlinePtr;
    byte left, above, aboveLeft = 0;
    word pixelWidth = (bitDepth < 8) ? 1 : bytesPerPixel; /* Use pixel width for packed formats */

    /* **Ensure first scanline is always FILTER_NONE** */
    if (!prevScanlinePtr)
    {
        return PNG_FILTER_NONE;
    }

    /* **Allocate test buffer dynamically** */
    testBufferMem = MemAlloc(scanlineSize + 1, HF_SWAPABLE, HAF_ZERO_INIT);
    if (!testBufferMem) {
        return PE_OUT_OF_MEMORY; /* Memory allocation failed */
    }

    testBuffer = (byte *)MemLock(testBufferMem);
    if (!testBuffer)
    {
        MemFree(testBufferMem);
        return PNG_FILTER_NONE; /* Memory lock failed */
    }

    /* **Determine the best filter** */
    for (i = 0; i < 5; i++)
    {
        sum = 0;
        testBuffer[0] = (byte)filterTypes[i];

        switch (filterTypes[i])
        {
            case PNG_FILTER_NONE:
                for (x = 0; x < scanlineSize; x++)
                    testBuffer[x + 1] = in[x];
                break;

            case PNG_FILTER_SUB:
                for (x = 0; x < scanlineSize; x++)
                {
                    left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                    testBuffer[x + 1] = in[x] - left;
                }
                break;

            case PNG_FILTER_UP:
                for (x = 0; x < scanlineSize; x++)
                {
                    above = prev[x];
                    testBuffer[x + 1] = in[x] - above;
                }
                break;

            case PNG_FILTER_AVERAGE:
                for (x = 0; x < scanlineSize; x++)
                {
                    left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                    above = prev[x];
                    testBuffer[x + 1] = in[x] - ((left + above) / 2);
                }
                break;

            case PNG_FILTER_PAETH:
                for (x = 0; x < scanlineSize; x++)
                {
                    left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                    above = prev[x];
                    aboveLeft = (x >= pixelWidth) ? prev[x - pixelWidth] : 0;
                    testBuffer[x + 1] = in[x] - paethPredictor(left, above, aboveLeft);
                }
                break;
        }

        /* **Compute absolute sum of filtered values** */
        for (x = 1; x < scanlineSize + 1; x++) /* Ignore first byte (filter type) */
        {
            sum += abs((sword)testBuffer[x]);
        }

        /* **Choose the best filter** */
        if (sum < bestSum)
        {
            bestSum = sum;
            bestFilter = filterTypes[i];
        }
    }

    /* **Free dynamically allocated buffer** */
    if (testBufferMem) MemFree(testBufferMem);

    return bestFilter;
}


/*********************************************************************
* Expand PackBits-compressed input into a raw scanline buffer.
*********************************************************************/
void _pascal filterScanline(byte* scanlinePtr, byte* filteredScanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth)
{
    word x = 0;
    byte *out = filteredScanlinePtr;
    byte *in = scanlinePtr;
    byte *prev = prevScanlinePtr;
    byte left, above, aboveLeft = 0;
    word pixelWidth = (bitDepth < 8) ? 1 : bytesPerPixel; /* Handle packed formats correctly */

    /* **Get the best filter** */
    out[0] = getFilterForScanline(scanlinePtr, prevScanlinePtr, scanlineSize, bytesPerPixel, bitDepth);

    /* **Apply the best filter** */
    switch (out[0])
    {
        case PNG_FILTER_NONE:
            for (x = 0; x < scanlineSize; x++)
                out[x + 1] = in[x];
            break;

        case PNG_FILTER_SUB:
            for (x = 0; x < scanlineSize; x++)
            {
                left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                out[x + 1] = in[x] - left;
            }
            break;

        case PNG_FILTER_UP:
            for (x = 0; x < scanlineSize; x++)
            {
                out[x + 1] = in[x] - prev[x];
            }
            break;

        case PNG_FILTER_AVERAGE:
            for (x = 0; x < scanlineSize; x++)
            {
                left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                above = prev[x];
                out[x + 1] = in[x] - ((left + above) / 2);
            }
            break;

        case PNG_FILTER_PAETH:
            for (x = 0; x < scanlineSize; x++)
            {
                left = (x >= pixelWidth) ? in[x - pixelWidth] : 0;
                above = prev[x];
                aboveLeft = (x >= pixelWidth) ? prev[x - pixelWidth] : 0;
                out[x + 1] = in[x] - paethPredictor(left, above, aboveLeft);
            }
            break;
    }
}

/*********************************************************************
* Map GEOS bitmap format flags to the corresponding PNG color type.
*********************************************************************/
Boolean _pascal deflateScanline(void *filteredScanlinePtr, word scanlineSize, z_stream *zstrm, FileHandle file, dword *idatChunkSize, dword *crc)
{
    int ret = 0;
    dword compressedSize = 0;
    MemHandle outBufferMem = NullHandle;
    byte *outBuffer = NULL;
    Boolean stat = TRUE;

    /* Allocate memory for the output buffer */
    outBufferMem = MemAlloc(PNG_CHUNK_SIZE_OUT, HF_SWAPABLE, HAF_ZERO_INIT);
    if (!outBufferMem) {
        stat = FALSE; /* Memory allocation failed */
        goto exit;
    }

    outBuffer = (byte *)MemLock(outBufferMem);
    if (!outBuffer) {
        stat = FALSE; /* Memory lock failed */
        goto exit;
    }

    /* Set input for deflation */
    zstrm->next_in = (byte *)filteredScanlinePtr;
    zstrm->avail_in = scanlineSize;

    /* Deflate and append to IDAT chunk */
    do
    {
        zstrm->next_out = outBuffer;
        zstrm->avail_out = PNG_CHUNK_SIZE_OUT;

        ret = deflate(zstrm, Z_SYNC_FLUSH); /* Ensure all output is flushed */
        if (ret != Z_OK && ret != Z_STREAM_END)
        {
            stat = FALSE; /* Compression failed */
            goto exit;
        }

        /* Calculate the number of compressed bytes */
        compressedSize = PNG_CHUNK_SIZE_OUT - zstrm->avail_out;

        /* Write compressed data to the file */
        if (!FILE_WRITE_CHECKED(file, outBuffer, compressedSize))
        {
            stat = FALSE; /* Writing failed */
            goto exit;
        }

        /* Update CRC and chunk size */
        *crc = crc32(*crc, outBuffer, compressedSize);
        *idatChunkSize += compressedSize;

    } while (zstrm->avail_in > 0);

exit:
    /* Free memory */
    if (outBufferMem) MemFree(outBufferMem);
    return stat;
}

/*********************************************************************
*********************************************************************/
Boolean _pascal unpackPackBits(byte *src, word srcSize, byte *dest, word destSize)
{
    word srcPos = 0;
    word destPos = 0;

    while ((srcPos < srcSize) && (destPos < destSize))
    {
        signed char control = (signed char)src[srcPos++];

        if (control >= 0)
        {
            word count = (word)control + 1;

            if ((srcPos + count) > srcSize || (destPos + count) > destSize)
            {
                return FALSE;
            }

            memcpy(dest + destPos, src + srcPos, count);
            srcPos += count;
            destPos += count;
        }
        else if (control >= -127)
        {
            word count = (word)(1 - control);

            if (srcPos >= srcSize || (destPos + count) > destSize)
            {
                return FALSE;
            }

            memset(dest + destPos, src[srcPos++], count);
            destPos += count;
        }
        else
        {
            /* control == -128 -> no-op per PackBits specification */
        }
    }

    return (destPos == destSize);
}

/*********************************************************************
*********************************************************************/
word _pascal mapGEOSToPNGColorType(BMType bmptype)
{
    switch (bmptype & BMT_FORMAT)
    {
        case BMF_MONO:
            return (bmptype & BMT_MASK) ? PNG_COLOR_TYPE_GREY_ALPHA : PNG_COLOR_TYPE_GREY; /* grayscale or grayscale+alpha */

        case BMF_4BIT:
        case BMF_8BIT:
            return (bmptype & BMT_MASK) ? PNG_COLOR_TYPE_RGBA : PNG_COLOR_TYPE_PALETTE; /* Indexed palette or expanded RGBA */

        case BMF_24BIT:
            return (bmptype & BMT_MASK) ? PNG_COLOR_TYPE_RGBA : PNG_COLOR_TYPE_RGB; /* RGB or RGBA */

        default:
            return 0xFFFF; /* Invalid format */
    }
}

/*********************************************************************
* This also respects 16 bit output values that we don't even support
* yet?
*********************************************************************/
word calcBytesPerPixel(pngIHDRData* ihdrData)
{
    word bytesPerPixel = 0;

    /* Determine bytes per pixel based on PNG color type */
    switch (ihdrData->colorType)
    {
        case PNG_COLOR_TYPE_GREY:
            bytesPerPixel = (ihdrData->bitDepth == 8) ? 1 : 2; /* 1 byte for 8-bit, 2 for 16-bit */
            break;
        case PNG_COLOR_TYPE_RGB:
            bytesPerPixel = (ihdrData->bitDepth == 8) ? 3 : 6; /* 3 bytes per pixel for 8-bit, 6 for 16-bit */
            break;
        case PNG_COLOR_TYPE_PALETTE:
            bytesPerPixel = 1; /* 1 byte per pixel (index) */
            break;
        case PNG_COLOR_TYPE_GREY_ALPHA:
            bytesPerPixel = (ihdrData->bitDepth == 8) ? 2 : 4; /* 2 bytes for 8-bit (gray+alpha), 4 for 16-bit */
            break;
        case PNG_COLOR_TYPE_RGBA:
            bytesPerPixel = (ihdrData->bitDepth == 8) ? 4 : 8; /* 4 bytes for 8-bit RGBA, 8 for 16-bit */
            break;
        default:
            bytesPerPixel = 0; /* Unsupported format */
    }

    return bytesPerPixel;
}
