#include "svgDash.h"

static int
SvgDashIsSpace(char c)
{
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

static int
SvgDashIsDigit(char c)
{
    return c >= '0' && c <= '9';
}

static const char *
SvgDashSkipSpace(const char *p, const char *endP)
{
    while (p < endP && SvgDashIsSpace(*p)) p++;
    return p;
}

static int
SvgDashParseNumber(const char **valuePP, const char *endP,
                   unsigned long *fixedP)
{
    const char *p;
    unsigned long integer;
    unsigned long fraction;
    unsigned long scale;
    unsigned long fractionalPart;
    int haveDigit;

    p = *valuePP;
    if (p < endP && *p == '+') p++;
    integer = 0;
    fraction = 0;
    scale = 1;
    haveDigit = 0;
    while (p < endP && SvgDashIsDigit(*p))
    {
        haveDigit = 1;
        if (integer > (32767UL - (unsigned long)(*p - '0')) / 10UL)
            return 0;
        integer = integer * 10UL + (unsigned long)(*p++ - '0');
    }
    if (p < endP && *p == '.')
    {
        p++;
        while (p < endP && SvgDashIsDigit(*p))
        {
            haveDigit = 1;
            if (scale == 1000000UL) return 0;
            fraction = fraction * 10UL + (unsigned long)(*p++ - '0');
            scale *= 10UL;
        }
    }
    if (!haveDigit) return 0;

    /* Match the importer's WWFixed parser's 1/256 fractional precision. */
    fractionalPart = (((fraction << 8) + (scale >> 1)) / scale) << 8;
    *fixedP = (integer << 16) + fractionalPart;
    if (*fixedP > 0x7fffffffUL) return 0;
    *valuePP = p;
    return 1;
}

static int
SvgDashFactor(unsigned long length, unsigned long width,
              unsigned char *factorP)
{
    unsigned long quotient;
    unsigned long remainder;

    quotient = length / width;
    remainder = length % width;
    if (remainder >= (width + 1UL) / 2UL) quotient++;
    if (quotient == 0 || quotient > 255UL) return 0;
    *factorP = (unsigned char)quotient;
    return 1;
}

int
SvgDashParse(const char *arrayP, unsigned short arrayLength,
             const char *offsetP, unsigned short offsetLength,
             unsigned long width, SvgDashPattern *patternP)
{
    const char *p;
    const char *endP;
    const char *numberEndP;
    unsigned long value;
    unsigned long quotient;
    unsigned long remainder;
    unsigned short count;
    unsigned char skip;

    if (arrayP == (void*)0 || patternP == (void*)0 ||
        width == 0 || width > 0x7fffffffUL) return 0;
    p = SvgDashSkipSpace(arrayP, arrayP + arrayLength);
    endP = arrayP + arrayLength;
    while (endP > p && SvgDashIsSpace(endP[-1])) endP--;
    if (endP - p == 4 &&
        (p[0] == 'n' || p[0] == 'N') &&
        (p[1] == 'o' || p[1] == 'O') &&
        (p[2] == 'n' || p[2] == 'N') &&
        (p[3] == 'e' || p[3] == 'E')) return 0;

    count = 0;
    while (p < endP)
    {
        if (count == SVG_DASH_MAX_PAIRS * 2) return 0;
        if (!SvgDashParseNumber(&p, endP, &value) ||
            !SvgDashFactor(value, width, &patternP->values[count])) return 0;
        count++;
        numberEndP = p;
        p = SvgDashSkipSpace(p, endP);
        if (p < endP && *p == ',')
        {
            p = SvgDashSkipSpace(p + 1, endP);
            if (p == endP) return 0;
        }
        else if (p < endP && p == numberEndP) return 0;
    }
    if (count == 0 || (count & 1)) return 0;

    skip = 0;
    if (offsetP != (void*)0)
    {
        p = SvgDashSkipSpace(offsetP, offsetP + offsetLength);
        endP = offsetP + offsetLength;
        if (!SvgDashParseNumber(&p, endP, &value) ||
            SvgDashSkipSpace(p, endP) != endP) return 0;
        if (value != 0)
        {
            quotient = value / width;
            remainder = value % width;
            if (remainder >= (width + 1UL) / 2UL) quotient++;
            if (quotient == 0 || quotient > 127UL) return 0;
            skip = (unsigned char)quotient;
        }
    }
    if (skip > (unsigned char)(patternP->values[0] +
                               patternP->values[1])) return 0;
    patternP->pairCount = count / 2;
    patternP->skip = skip;
    return 1;
}
