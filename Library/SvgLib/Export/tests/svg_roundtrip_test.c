/*
 * Run from the repository root:
 * cc -std=c89 -Wall -Wextra -Werror Library/SvgLib/Export/svgWriter.c \
 *   Library/SvgLib/Import/svgDash.c Library/SvgLib/Import/svgPathSyntax.c \
 *   Library/SvgLib/Export/tests/svg_roundtrip_test.c -o /tmp/svg_roundtrip_test
 * /tmp/svg_roundtrip_test
 */
#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "../../svgLimits.h"
#include "../svgWriter.h"
#include "../../Import/svgDash.h"
#include "../../Import/svgPathSyntax.h"

typedef struct
{
    char data[4096];
    unsigned short length;
    SvgWriterTagCounter counter;
} Capture;

typedef struct
{
    SvgWriterTagCounter counter;
    int tooLarge;
} LimitSink;

static int
CaptureWrite(void *userData, const char *data, SvgWriterU16 byteCount)
{
    Capture *captureP;

    captureP = (Capture *)userData;
    if (byteCount > sizeof(captureP->data) - captureP->length - 1 ||
        !SvgWriterCountTags(&captureP->counter, data, byteCount,
                            SVG_TEXT_MAX_SIZE - 1)) return 0;
    memcpy(captureP->data + captureP->length, data, byteCount);
    captureP->length += byteCount;
    captureP->data[captureP->length] = 0;
    return 1;
}

static int
LimitWrite(void *userData, const char *data, SvgWriterU16 byteCount)
{
    LimitSink *sinkP;

    sinkP = (LimitSink *)userData;
    if (!SvgWriterCountTags(&sinkP->counter, data, byteCount,
                            SVG_TEXT_MAX_SIZE - 1))
    {
        sinkP->tooLarge = 1;
        return 0;
    }
    return 1;
}

static int
GetAttr(const char *tagP, const char *name, const char **valuePP,
        unsigned short *lengthP)
{
    const char *p;
    const char *endP;
    size_t nameLength;

    *valuePP = (void*)0;
    *lengthP = 0;
    endP = strchr(tagP, '>');
    if (endP == (void*)0) return 0;
    nameLength = strlen(name);
    for (p = tagP; p + nameLength + 2 < endP; p++)
    {
        if ((p == tagP || p[-1] == ' ' || p[-1] == '\n') &&
            !memcmp(p, name, nameLength) &&
            p[nameLength] == '=' && p[nameLength + 1] == '"')
        {
            *valuePP = p + nameLength + 2;
            p = *valuePP;
            while (p < endP && *p != '"') p++;
            if (p == endP) return 0;
            *lengthP = (unsigned short)(p - *valuePP);
            return 1;
        }
    }
    return 0;
}

static int
ParseTagDash(const char *tagP, unsigned long width,
             SvgDashPattern *patternP)
{
    const char *arrayP;
    const char *offsetP;
    unsigned short arrayLength;
    unsigned short offsetLength;

    if (!GetAttr(tagP, "stroke-dasharray", &arrayP, &arrayLength)) return 0;
    GetAttr(tagP, "stroke-dashoffset", &offsetP, &offsetLength);
    return SvgDashParse(arrayP, arrayLength, offsetP, offsetLength,
                        width, patternP);
}

static void
CheckEmittedShapes(void)
{
    Capture capture;
    SvgWriter writer;
    SvgWriterStyle style;
    SvgWriterPoint a;
    SvgWriterPoint b;
    SvgWriterPoint c;
    SvgWriterPoint d;
    SvgWriterRect rect;
    SvgWriterArc arc;
    SvgDashPattern dash;
    const char *tagP;
    const char *valueP;
    unsigned short length;
    char syntax[256];

    memset(&capture, 0, sizeof(capture));
    memset(&style, 0, sizeof(style));
    memset(&rect, 0, sizeof(rect));
    memset(&arc, 0, sizeof(arc));
    SvgWriterInit(&writer, CaptureWrite, &capture);
    style.includeStroke = 1;
    style.lineWidth = 0x00020000L;
    style.miterLimit = 0x00040000L;
    a.x = 0;
    a.y = 0;
    b.x = 0x001e0000L;
    b.y = 0;
    c.x = 0x000a0000L;
    c.y = 0x000a0000L;
    d.x = 0x00140000L;
    d.y = 0;

    assert(SvgWriterEmitHeader(&writer, 0, 0, 30, 30));
    style.dashCount = 2;
    style.dashValues[0] = 0x00080000L;
    style.dashValues[1] = 0x00080000L;
    assert(SvgWriterEmitLine(&writer, &a, &b, &style, (void*)0));
    style.dashCount = 4;
    style.dashValues[0] = 0x00060000L;
    style.dashValues[1] = 0x00040000L;
    style.dashValues[2] = 0x00020000L;
    style.dashValues[3] = 0x00040000L;
    style.hasDashOffset = 1;
    style.dashOffset = 0x00040000L;
    assert(SvgWriterEmitLine(&writer, &a, &c, &style, (void*)0));
    style.dashCount = 0;
    style.hasDashOffset = 0;
    assert(SvgWriterEmitLine(&writer, &b, &c, &style, (void*)0));
    style.lineWidth = 0x00001000L;
    style.dashCount = 2;
    style.dashValues[0] = 0x00004000L;
    style.dashValues[1] = 0x00004000L;
    style.hasDashOffset = 1;
    style.dashOffset = 0x00002000L;
    assert(SvgWriterEmitLine(&writer, &a, &d, &style, (void*)0));
    style.lineWidth = 0x00020000L;
    style.dashCount = 0;
    style.hasDashOffset = 0;
    rect.x = 0;
    rect.y = 0;
    rect.width = 0x00140000UL;
    rect.height = 0x000a0000UL;
    assert(SvgWriterEmitRect(&writer, &rect, 0, &style, (void*)0));
    assert(SvgWriterEmitEllipse(&writer, &c, 0x00050000L,
                                0x00030000L, &style, (void*)0));
    assert(SvgWriterEmitPolygonBegin(&writer, 0));
    assert(SvgWriterEmitPolygonPoint(&writer, &a));
    assert(SvgWriterEmitPolygonPoint(&writer, &b));
    assert(SvgWriterEmitPolygonEnd(&writer, &style, (void*)0));
    assert(SvgWriterEmitCubic(&writer, &a, &b, &c, &d,
                              &style, (void*)0));
    arc.start = d;
    arc.end = a;
    arc.middle = a;
    arc.radiusX = 0x000a0000L;
    arc.radiusY = 0x00050000L;
    assert(SvgWriterEmitArc(&writer, &arc, &style, (void*)0));
    assert(SvgWriterEmitFooter(&writer));
    assert(!SvgWriterFailed(&writer));
    assert(strstr(capture.data, "<svg ") != (void*)0);
    assert(strstr(capture.data, "<rect ") != (void*)0);
    assert(strstr(capture.data, "<ellipse ") != (void*)0);

    tagP = strstr(capture.data, "<line ");
    assert(tagP != (void*)0 && ParseTagDash(tagP, 0x00020000UL, &dash));
    assert(dash.pairCount == 1 && dash.skip == 0 &&
           dash.values[0] == 4 && dash.values[1] == 4);
    tagP = strstr(tagP + 1, "<line ");
    assert(tagP != (void*)0 && ParseTagDash(tagP, 0x00020000UL, &dash));
    assert(dash.pairCount == 2 && dash.skip == 2 &&
           dash.values[0] == 3 && dash.values[1] == 2 &&
           dash.values[2] == 1 && dash.values[3] == 2);
    tagP = strstr(tagP + 1, "<line ");
    assert(tagP != (void*)0 &&
           !ParseTagDash(tagP, 0x00020000UL, &dash));
    tagP = strstr(tagP + 1, "<line ");
    assert(tagP != (void*)0 && ParseTagDash(tagP, 0x00000f00UL, &dash));
    assert(dash.pairCount == 1 && dash.skip == 2 &&
           dash.values[0] == 4 && dash.values[1] == 4);
    assert(SvgDashParse("1 2 3", 5, (void*)0, 0,
                        0x00010000UL, &dash) == 0);
    assert(SvgDashParse("0 2", 3, (void*)0, 0,
                        0x00010000UL, &dash) == 0);
    assert(SvgDashParse("3 2", 3, "130", 3,
                        0x00010000UL, &dash) == 0);
    assert(SvgDashParse("3 2", 3, "6", 1,
                        0x00010000UL, &dash) == 0);
    assert(SvgDashParse("1 2 3 4 5 6 7 8 9 10", 20,
                        (void*)0, 0, 0x00010000UL, &dash));
    assert(dash.pairCount == 5);
    assert(!SvgDashParse("1 2 3 4 5 6 7 8 9 10 11 12", 26,
                         (void*)0, 0, 0x00010000UL, &dash));

    tagP = strstr(capture.data, "<polyline ");
    assert(tagP != (void*)0 && GetAttr(tagP, "points", &valueP, &length));
    assert(length < sizeof(syntax));
    memcpy(syntax, valueP, length);
    syntax[length] = 0;
    assert(SvgPointsDataIsValid(syntax));
    tagP = strstr(capture.data, "<path ");
    assert(tagP != (void*)0 && GetAttr(tagP, "d", &valueP, &length));
    assert(length < sizeof(syntax));
    memcpy(syntax, valueP, length);
    syntax[length] = 0;
    assert(SvgPathDataIsValid(syntax));
    tagP = strstr(tagP + 1, "<path ");
    assert(tagP != (void*)0 && GetAttr(tagP, "d", &valueP, &length));
    assert(length < sizeof(syntax));
    memcpy(syntax, valueP, length);
    syntax[length] = 0;
    assert(SvgPathDataIsValid(syntax));
}

static int
EmitPolyline(SvgWriter *writer, unsigned count, unsigned extra)
{
    SvgWriterPoint point;
    SvgWriterStyle style;
    unsigned index;

    memset(&style, 0, sizeof(style));
    style.includeStroke = 1;
    style.lineWidth = 0x00010000L;
    style.miterLimit = 0x00040000L;
    point.x = 0;
    point.y = 0;
    if (!SvgWriterEmitPolygonBegin(writer, 0)) return 0;
    for (index = 0; index < count; index++)
    {
        point.x = index == count - 1 ?
                  (extra == 0 ? 0 :
                   (extra == 1 ? 0x000a0000L :
                    (extra == 2 ? 0x00640000L : 0x03e80000L))) : 0;
        if (!SvgWriterEmitPolygonPoint(writer, &point)) return 0;
    }
    return SvgWriterEmitPolygonEnd(writer, &style, (void*)0);
}

static void
CheckTagBoundary(void)
{
    Capture capture;
    LimitSink sink;
    SvgWriter writer;
    const char *tagP;
    const char *endP;
    unsigned base;
    unsigned count;
    unsigned extra;
    FILE *fileP;
    char sentinel[4];

    memset(&capture, 0, sizeof(capture));
    SvgWriterInit(&writer, CaptureWrite, &capture);
    assert(EmitPolyline(&writer, 2, 0));
    tagP = strchr(capture.data, '<');
    endP = strchr(tagP, '>');
    assert(endP != (void*)0);
    base = (unsigned)(endP - tagP - 1);
    assert(base < SVG_TEXT_MAX_SIZE - 1);

    count = 2 + (SVG_TEXT_MAX_SIZE - 1 - base) / 4;
    extra = (SVG_TEXT_MAX_SIZE - 1 - base) % 4;
    memset(&sink, 0, sizeof(sink));
    SvgWriterInit(&writer, LimitWrite, &sink);
    assert(EmitPolyline(&writer, count, extra));
    assert(!sink.tooLarge && sink.counter.length == 8191);

    fileP = tmpfile();
    assert(fileP != (void*)0 && fwrite("KEEP", 1, 4, fileP) == 4);
    count = 2 + (SVG_TEXT_MAX_SIZE - base) / 4;
    extra = (SVG_TEXT_MAX_SIZE - base) % 4;
    memset(&sink, 0, sizeof(sink));
    SvgWriterInit(&writer, LimitWrite, &sink);
    assert(!EmitPolyline(&writer, count, extra));
    assert(sink.tooLarge);
    rewind(fileP);
    assert(fread(sentinel, 1, 4, fileP) == 4 &&
           memcmp(sentinel, "KEEP", 4) == 0);
    assert(fgetc(fileP) == EOF);
    fclose(fileP);
}

int
main(void)
{
    CheckEmittedShapes();
    CheckTagBoundary();
    puts("SvgLib shared-source round-trip checks passed");
    return 0;
}
