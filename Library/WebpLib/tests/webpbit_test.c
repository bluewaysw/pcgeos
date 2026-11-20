#include <assert.h>
#include <stdio.h>

#define WEBP_HOST_TEST
#include "../webpbit.c"

typedef struct {
    const byte *currentP;
    const byte *endP;
    dword value;
    byte range;
    sbyte bits;
    byte eof;
} ReferenceReader;

static void
ReferenceLoad(ReferenceReader *readerP)
{
    dword bits;
    dword remaining;

    remaining = readerP->endP - readerP->currentP;
    if (remaining >= 4) {
        bits = ((dword)readerP->currentP[0] << 16) |
               ((dword)readerP->currentP[1] << 8) |
               readerP->currentP[2];
        readerP->currentP += 3;
        readerP->value = bits | (readerP->value << 24);
        readerP->bits += 24;
    } else if (remaining != 0) {
        readerP->bits += 8;
        readerP->value = *readerP->currentP++ |
                         (readerP->value << 8);
    } else if (!readerP->eof) {
        readerP->value <<= 8;
        readerP->bits += 8;
        readerP->eof = TRUE;
    } else {
        readerP->bits = 0;
    }
}

static void
ReferenceInit(ReferenceReader *readerP, const byte *dataP, word size)
{
    readerP->currentP = dataP;
    readerP->endP = dataP + size;
    readerP->value = 0;
    readerP->range = 254;
    readerP->bits = -8;
    readerP->eof = FALSE;
    ReferenceLoad(readerP);
}

static word
ReferenceGet(ReferenceReader *readerP, word probability)
{
    word bit;
    byte range;
    byte split;
    byte value;
    byte shift;

    if (readerP->bits < 0) {
        ReferenceLoad(readerP);
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

static void
CheckLength(word length)
{
    byte data[2064];
    byte input[WEBP_INPUT_BUFFER_SIZE];
    TestFile file;
    WebPDecoder decoder;
    WebPBoolReader actual;
    ReferenceReader expected;
    dword random;
    word i;

    random = 0x12345678UL;
    for (i = 0; i < sizeof(data); i++) {
        random = random * 1664525UL + 1013904223UL;
        data[i] = (byte)(random >> 24);
    }
    memset(input, 0, sizeof(input));
    file.dataP = data;
    file.size = sizeof(data);
    file.position = 0;
    decoder.source = &file;
    decoder.inputH = input;
    decoder.inputP = input;
    WebPBoolInit(&decoder, &actual, 7, length, TRUE);
    ReferenceInit(&expected, data + 7, length);

    random = 0x87654321UL;
    for (i = 0; i < 30000 && !actual.eof; i++) {
        word probability;
        word actualBit;
        word expectedBit;

        random = random * 1103515245UL + 12345;
        probability = (word)((random >> 24) | 1);
        actualBit = WebPBoolGet(&decoder, &actual, probability);
        expectedBit = ReferenceGet(&expected, probability);
        assert(actualBit == expectedBit);
        assert(actual.value == expected.value);
        assert(actual.range == expected.range);
        assert(actual.bits == expected.bits);
        assert(actual.eof == expected.eof);
    }
    assert(actual.eof);
}

int
main(void)
{
    CheckLength(2047);
    CheckLength(2048);
    CheckLength(2049);
    puts("webpbit_test: ok");
    return 0;
}
