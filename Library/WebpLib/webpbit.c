/*
 * Buffered VP8 Boolean reader.
 * Arithmetic behavior is derived from SimpleWebP commit
 * d1a728a1f8ec7348ca2a5039b6dd813b83986fbb.
 */

#ifdef WEBP_HOST_TEST
#include "tests/webptest.h"
#else
#include "webpint.h"
#endif

static word
WebPBoolLoadByte(WebPDecoder *decoderP, WebPBoolReader *readerP)
{
    word halfOffset;
    word wanted;
    dword left;

    if (readerP->next >= readerP->start + readerP->length) {
        readerP->eof = TRUE;
        return 0;
    }
    if (readerP->windowSize == 0 ||
        readerP->next < readerP->windowStart ||
        readerP->next >= readerP->windowStart + readerP->windowSize) {
        left = readerP->start + readerP->length - readerP->next;
        wanted = left > WEBP_INPUT_WINDOW ? WEBP_INPUT_WINDOW : (word)left;
        halfOffset = readerP->token ? WEBP_INPUT_WINDOW : 0;
        if (FilePos(decoderP->source, readerP->next, FILE_POS_START) !=
                readerP->next ||
            FileRead(decoderP->source, decoderP->inputP + halfOffset, wanted,
                     FALSE) !=
                wanted) {
            readerP->eof = TRUE;
            readerP->ioError = TRUE;
            return 0;
        }
        readerP->windowStart = readerP->next;
        readerP->windowSize = wanted;
    }

    halfOffset = readerP->token ? WEBP_INPUT_WINDOW : 0;
    wanted = decoderP->inputP[halfOffset +
                              (word)(readerP->next - readerP->windowStart)];
    readerP->next++;
    return wanted;
}

static void
WebPBoolLoad(WebPDecoder *decoderP, WebPBoolReader *readerP)
{
    dword remaining;
    dword bits;

    remaining = readerP->start + readerP->length - readerP->next;
    if (remaining >= 4) {
        bits = (dword)WebPBoolLoadByte(decoderP, readerP) << 16;
        bits |= (dword)WebPBoolLoadByte(decoderP, readerP) << 8;
        bits |= WebPBoolLoadByte(decoderP, readerP);
        readerP->value = bits | (readerP->value << 24);
        readerP->bits += 24;
    } else if (remaining != 0) {
        readerP->bits += 8;
        readerP->value = WebPBoolLoadByte(decoderP, readerP) |
                         (readerP->value << 8);
    } else if (!readerP->eof) {
        readerP->value <<= 8;
        readerP->bits += 8;
        readerP->eof = TRUE;
    } else {
        readerP->bits = 0;
    }
}

void _pascal
WebPBoolInit(WebPDecoder *decoderP, WebPBoolReader *readerP,
             dword start, dword length, Boolean token)
{
    readerP->start = start;
    readerP->length = length;
    readerP->next = start;
    readerP->windowStart = 0;
    readerP->windowSize = 0;
    readerP->value = 0;
    readerP->range = 254;
    readerP->bits = -8;
    readerP->eof = FALSE;
    readerP->ioError = FALSE;
    readerP->token = token;
    WebPBoolLoad(decoderP, readerP);
}

word _pascal
WebPBoolGet(WebPDecoder *decoderP, WebPBoolReader *readerP, word probability)
{
    word bit;
    byte range;
    byte split;
    byte value;
    byte shift;

    if (readerP->bits < 0) {
        WebPBoolLoad(decoderP, readerP);
    }
    range = readerP->range;
    split = (byte)(((dword)range * probability) >> 8);
    value = (byte)(readerP->value >> readerP->bits);
    bit = value > split;
    if (bit) {
        range -= split;
        readerP->value -= ((dword)split + 1) << readerP->bits;
    } else {
        range = split + 1;
    }
    shift = 0;
    while (range < 128) {
        range <<= 1;
        shift++;
    }
    readerP->bits -= shift;
    readerP->range = range - 1;
    return bit;
}

word _pascal
WebPBoolGetValue(WebPDecoder *decoderP, WebPBoolReader *readerP,
                 word bitCount)
{
    word value;

    value = 0;
    while (bitCount--) {
        value |= WebPBoolGet(decoderP, readerP, 128) << bitCount;
    }
    return value;
}
