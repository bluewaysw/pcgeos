#ifndef SVG_DASH_H
#define SVG_DASH_H

#define SVG_DASH_MAX_PAIRS 5

typedef struct
{
    unsigned short pairCount;
    unsigned char skip;
    unsigned char values[SVG_DASH_MAX_PAIRS * 2];
} SvgDashPattern;

/* Lengths and width are unsigned 16.16 values. Zero means solid fallback. */
int SvgDashParse(const char *arrayP, unsigned short arrayLength,
                 const char *offsetP, unsigned short offsetLength,
                 unsigned long width, SvgDashPattern *patternP);

#endif
