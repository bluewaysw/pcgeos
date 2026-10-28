/*
 * VP8 pixel conversion derived from SimpleWebP commit
 * d1a728a1f8ec7348ca2a5039b6dd813b83986fbb.
 */

#ifdef WEBP_HOST_TEST
#include "tests/webptest.h"
#else
#include "webpint.h"
#endif

static byte
WebPClipRGB(sdword value)
{
    if (value < 0) {
        return 0;
    }
    if (value > 16383) {
        return 255;
    }
    return (byte)(value >> 6);
}

void _pascal
WebPYUVToRGB(byte y, byte u, byte v, byte *rgbP)
{
    sdword yHigh;

    yHigh = ((sdword)y * 19077) >> 8;
    rgbP[0] = WebPClipRGB(yHigh + (((sdword)v * 26149) >> 8) - 14234);
    rgbP[1] = WebPClipRGB(yHigh - (((sdword)u * 6419) >> 8) -
                          (((sdword)v * 13320) >> 8) + 8708);
    rgbP[2] = WebPClipRGB(yHigh + (((sdword)u * 33050) >> 8) - 17685);
}
