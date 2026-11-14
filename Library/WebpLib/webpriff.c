/*
 * RIFF/WebP container parser.
 * Container behavior follows RFC 9649.
 */

#ifdef WEBP_HOST_TEST
#include "tests/webptest.h"
#else
#include "webpint.h"
#endif

#if ERROR_CHECK
Warnings webpWarnings;
#endif

static WebPResult
WebPRead(FileHandle source, dword position, void *dataP, word size)
{
    if (FilePos(source, position, FILE_POS_START) != position) {
        return WEBP_ERROR_READ;
    }
    if (FileRead(source, dataP, size, FALSE) != size) {
        return WEBP_ERROR_READ;
    }
    return WEBP_RESULT_OK;
}

static dword
WebPGetDWord(const byte *dataP)
{
    return (dword)dataP[0] | ((dword)dataP[1] << 8) |
           ((dword)dataP[2] << 16) | ((dword)dataP[3] << 24);
}

static word
WebPGetWord(const byte *dataP)
{
    return (word)dataP[0] | ((word)dataP[1] << 8);
}

WebPResult _pascal
WebPParseContainer(FileHandle source, WebPDecoder *decoderP)
{
    byte header[12];
    byte chunkHeader[8];
    byte frameHeader[10];
    byte extended[10];
    dword fileSize;
    dword riffSize;
    dword position;
    dword chunkSize;
    dword paddedSize;
    dword chunkType;
    dword canvasWidth;
    dword canvasHeight;
    word haveVP8;
    word haveVP8X;
    word metadataFlags;
    word metadataSeen;
    dword frameTag;

    fileSize = FileSize(source);
    if (fileSize < sizeof(header)) {
        return WEBP_ERROR_WRONG_FORMAT;
    }
    if (WebPRead(source, 0, header, sizeof(header)) != WEBP_RESULT_OK) {
        return WEBP_ERROR_READ;
    }
    if (WebPGetDWord(header) != WEBP_FOURCC('R', 'I', 'F', 'F') ||
        WebPGetDWord(header + 8) != WEBP_FOURCC('W', 'E', 'B', 'P')) {
        return WEBP_ERROR_WRONG_FORMAT;
    }

    riffSize = WebPGetDWord(header + 4);
    if (riffSize < 4 || riffSize > 0xfffffff7UL) {
        return WEBP_ERROR_CORRUPT;
    }
    decoderP->riffEnd = riffSize + 8;
    if (decoderP->riffEnd > fileSize) {
        return WEBP_ERROR_CORRUPT;
    }

    position = 12;
    haveVP8 = haveVP8X = FALSE;
    metadataFlags = metadataSeen = 0;
    canvasWidth = canvasHeight = 0;
    while (position < decoderP->riffEnd) {
        if (decoderP->riffEnd - position < sizeof(chunkHeader)) {
            return WEBP_ERROR_CORRUPT;
        }
        if (WebPRead(source, position, chunkHeader,
                     sizeof(chunkHeader)) != WEBP_RESULT_OK) {
            return WEBP_ERROR_READ;
        }
        chunkType = WebPGetDWord(chunkHeader);
        chunkSize = WebPGetDWord(chunkHeader + 4);
        if (chunkSize > 0xfffffffeUL) {
            return WEBP_ERROR_CORRUPT;
        }
        paddedSize = chunkSize + (chunkSize & 1);
        position += sizeof(chunkHeader);
        if (paddedSize > decoderP->riffEnd - position) {
            return WEBP_ERROR_CORRUPT;
        }

        if (chunkType == WEBP_FOURCC('V', 'P', '8', 'X')) {
            if (position != 20 || haveVP8X || chunkSize != 10) {
                return WEBP_ERROR_CORRUPT;
            }
            if (WebPRead(source, position, extended,
                         sizeof(extended)) != WEBP_RESULT_OK) {
                return WEBP_ERROR_READ;
            }
            haveVP8X = TRUE;
            if (extended[0] & 0x10) {
                EC_WARNING(WEBP_WARNING_ALPHA_NOT_SUPPORTED);
                return WEBP_ERROR_UNSUPPORTED;
            }
            if (extended[0] & 0x02) {
                EC_WARNING(WEBP_WARNING_ANIMATION_NOT_SUPPORTED);
                return WEBP_ERROR_UNSUPPORTED;
            }
            if (extended[0] & 0xc1) {
                return WEBP_ERROR_CORRUPT;
            }
            metadataFlags = extended[0] & 0x2c;
            canvasWidth = 1 + (dword)extended[4] +
                          ((dword)extended[5] << 8) +
                          ((dword)extended[6] << 16);
            canvasHeight = 1 + (dword)extended[7] +
                           ((dword)extended[8] << 8) +
                           ((dword)extended[9] << 16);
        } else if (chunkType == WEBP_FOURCC('V', 'P', '8', ' ')) {
            if (haveVP8) {
                return WEBP_ERROR_CORRUPT;
            }
            if (chunkSize < sizeof(frameHeader)) {
                return WEBP_ERROR_CORRUPT;
            }
            if (WebPRead(source, position, frameHeader,
                         sizeof(frameHeader)) != WEBP_RESULT_OK) {
                return WEBP_ERROR_READ;
            }
            haveVP8 = TRUE;
            decoderP->vp8Start = position;
            decoderP->vp8Length = chunkSize;
            frameTag = (dword)frameHeader[0] |
                       ((dword)frameHeader[1] << 8) |
                       ((dword)frameHeader[2] << 16);
            if (frameTag & 1) {
                EC_WARNING(WEBP_WARNING_PREDICTED_FRAME_NOT_SUPPORTED);
                return WEBP_ERROR_UNSUPPORTED;
            }
            if (((frameHeader[0] >> 1) & 7) > 3) {
                EC_WARNING(WEBP_WARNING_VP8_PROFILE_NOT_SUPPORTED);
                return WEBP_ERROR_UNSUPPORTED;
            }
            if (!(frameHeader[0] & 0x10)) {
                EC_WARNING(WEBP_WARNING_HIDDEN_FRAME_NOT_SUPPORTED);
                return WEBP_ERROR_UNSUPPORTED;
            }
            if (frameHeader[3] != 0x9d || frameHeader[4] != 0x01 ||
                frameHeader[5] != 0x2a) {
                return WEBP_ERROR_CORRUPT;
            }
            decoderP->width = WebPGetWord(frameHeader + 6) & 0x3fff;
            decoderP->height = WebPGetWord(frameHeader + 8) & 0x3fff;
            if (decoderP->width == 0 || decoderP->height == 0) {
                return WEBP_ERROR_CORRUPT;
            }
            if (decoderP->width > WEBP_MAX_DIMENSION ||
                decoderP->height > WEBP_MAX_DIMENSION) {
                return WEBP_ERROR_IMAGE_TOO_LARGE;
            }
            decoderP->firstPartitionLength = frameTag >> 5;
            if (decoderP->firstPartitionLength >= chunkSize - 10) {
                return WEBP_ERROR_CORRUPT;
            }
        } else if (chunkType == WEBP_FOURCC('V', 'P', '8', 'L')) {
            EC_WARNING(WEBP_WARNING_LOSSLESS_NOT_SUPPORTED);
            return WEBP_ERROR_UNSUPPORTED;
        } else if (chunkType == WEBP_FOURCC('A', 'L', 'P', 'H')) {
            EC_WARNING(WEBP_WARNING_ALPHA_NOT_SUPPORTED);
            return WEBP_ERROR_UNSUPPORTED;
        } else if (chunkType == WEBP_FOURCC('A', 'N', 'I', 'M') ||
                   chunkType == WEBP_FOURCC('A', 'N', 'M', 'F')) {
            EC_WARNING(WEBP_WARNING_ANIMATION_NOT_SUPPORTED);
            return WEBP_ERROR_UNSUPPORTED;
        } else if (chunkType == WEBP_FOURCC('I', 'C', 'C', 'P')) {
            if (haveVP8) {
                return WEBP_ERROR_CORRUPT;
            }
            metadataSeen |= 0x20;
        } else if (chunkType == WEBP_FOURCC('E', 'X', 'I', 'F')) {
            metadataSeen |= 0x08;
        } else if (chunkType == WEBP_FOURCC('X', 'M', 'P', ' ')) {
            metadataSeen |= 0x04;
        }

        if (chunkSize & 1) {
            byte padding;

            if (WebPRead(source, position + chunkSize,
                         &padding, 1) != WEBP_RESULT_OK) {
                return WEBP_ERROR_READ;
            }
            if (padding != 0) {
                return WEBP_ERROR_CORRUPT;
            }
        }
        position += paddedSize;
    }

    if (!haveVP8 || position != decoderP->riffEnd ||
        metadataFlags != metadataSeen) {
        return WEBP_ERROR_CORRUPT;
    }
    if (haveVP8X &&
        (canvasWidth != decoderP->width ||
         canvasHeight != decoderP->height)) {
        return WEBP_ERROR_CORRUPT;
    }
    decoderP->rowBytes = decoderP->width * 3;
    decoderP->mbWidth = (decoderP->width + 15) >> 4;
    decoderP->mbHeight = (decoderP->height + 15) >> 4;
    return WEBP_RESULT_OK;
}
