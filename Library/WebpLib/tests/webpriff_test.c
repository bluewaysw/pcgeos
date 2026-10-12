#include <assert.h>
#include <stdio.h>

#define WEBP_HOST_TEST
#include "../webpriff.c"

static void
PutDWord(byte *dataP, dword value)
{
    dataP[0] = (byte)value;
    dataP[1] = (byte)(value >> 8);
    dataP[2] = (byte)(value >> 16);
    dataP[3] = (byte)(value >> 24);
}

static word
AddChunk(byte *dataP, word position, dword type,
         const byte *payloadP, word payloadSize)
{
    PutDWord(dataP + position, type);
    PutDWord(dataP + position + 4, payloadSize);
    memcpy(dataP + position + 8, payloadP, payloadSize);
    position += 8 + payloadSize;
    if (payloadSize & 1) {
        dataP[position++] = 0;
    }
    return position;
}

static word
BeginRiff(byte *dataP)
{
    PutDWord(dataP, WEBP_FOURCC('R', 'I', 'F', 'F'));
    PutDWord(dataP + 8, WEBP_FOURCC('W', 'E', 'B', 'P'));
    return 12;
}

static void
FinishRiff(byte *dataP, word size)
{
    PutDWord(dataP + 4, size - 8);
}

static void
MakeVP8(byte *payloadP, word width, word height)
{
    payloadP[0] = 0x30;
    payloadP[1] = payloadP[2] = 0;
    payloadP[3] = 0x9d;
    payloadP[4] = 0x01;
    payloadP[5] = 0x2a;
    payloadP[6] = (byte)width;
    payloadP[7] = (byte)(width >> 8);
    payloadP[8] = (byte)height;
    payloadP[9] = (byte)(height >> 8);
    payloadP[10] = 0;
    payloadP[11] = 0;
}

static WebPResult
Parse(byte *dataP, word size)
{
    TestFile file;
    WebPDecoder decoder;

    memset(&decoder, 0, sizeof(decoder));
    file.dataP = dataP;
    file.size = size;
    file.position = 0;
    return WebPParseContainer(&file, &decoder);
}

int
main(void)
{
    byte data[160];
    byte vp8[12];
    byte vp8x[10];
    byte unknown[1];
    byte lossless[5];
    word position;

    MakeVP8(vp8, 17, 31);
    memset(data, 0, sizeof(data));
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_RESULT_OK);
    assert(Parse(data, position - 1) == WEBP_ERROR_CORRUPT);
    PutDWord(data + 16, 0xffffffffUL);
    assert(Parse(data, position) == WEBP_ERROR_CORRUPT);
    PutDWord(data + 16, sizeof(vp8));
    MakeVP8(vp8, 2049, 31);
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_ERROR_IMAGE_TOO_LARGE);
    MakeVP8(vp8, 17, 31);

    unknown[0] = 0x55;
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('J', 'U', 'N', 'K'), unknown, 1);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_RESULT_OK);
    data[21] = 1;
    assert(Parse(data, position) == WEBP_ERROR_CORRUPT);
    data[21] = 0;

    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_ERROR_CORRUPT);

    memset(lossless, 0, sizeof(lossless));
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', 'L'),
                        lossless, sizeof(lossless));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_ERROR_UNSUPPORTED);

    memset(vp8x, 0, sizeof(vp8x));
    vp8x[4] = 16;
    vp8x[7] = 30;
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', 'X'),
                        vp8x, sizeof(vp8x));
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_RESULT_OK);
    vp8x[0] = 0x20;
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', 'X'),
                        vp8x, sizeof(vp8x));
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_ERROR_CORRUPT);
    vp8x[0] = 0x10;
    position = BeginRiff(data);
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', 'X'),
                        vp8x, sizeof(vp8x));
    position = AddChunk(data, position,
                        WEBP_FOURCC('V', 'P', '8', ' '), vp8, sizeof(vp8));
    FinishRiff(data, position);
    assert(Parse(data, position) == WEBP_ERROR_UNSUPPORTED);

    puts("webpriff_test: ok");
    return 0;
}
