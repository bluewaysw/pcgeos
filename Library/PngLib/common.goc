/*********************************************************************/
#include "common.h"

/*********************************************************************/
byte _pascal paethPredictor(byte a, byte b, byte c)
{
    sword p = a + b - c;
    sword pa = abs(p - a);
    sword pb = abs(p - b);
    sword pc = abs(p - c);

    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
}

/*********************************************************************
    abs function, GEOS probably has one somewhere...
*********************************************************************/
int abs(int x)
{
    return x >= 0 ? x : -x;
}

/*********************************************************************
    swap endianness
*********************************************************************/
unsigned long swapEndian(unsigned long val)
{
    return ((val >> 24) & 0x000000FF) |
           ((val >> 8) & 0x0000FF00) |
           ((val << 8) & 0x00FF0000) |
           ((val << 24) & 0xFF000000);
}
