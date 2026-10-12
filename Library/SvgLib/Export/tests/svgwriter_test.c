#include <string.h>

#include "../svgWriter.h"
#include "../../svgLimits.h"

static int
CheckTagLimit(void)
{
    SvgWriterTagCounter counter;
    char tag[SVG_TEXT_MAX_SIZE + 2];
    unsigned index;

    memset(&counter, 0, sizeof(counter));
    tag[0] = '<';
    for (index = 1; index < SVG_TEXT_MAX_SIZE; index++) tag[index] = 'x';
    tag[10] = '\n';
    tag[20] = '"';
    tag[30] = '>';
    tag[40] = '"';
    tag[SVG_TEXT_MAX_SIZE] = '>';
    if (!SvgWriterCountTags(&counter, tag, 101,
                             SVG_TEXT_MAX_SIZE - 1) ||
        !SvgWriterCountTags(&counter, tag + 101,
                             SVG_TEXT_MAX_SIZE - 100,
                             SVG_TEXT_MAX_SIZE - 1) ||
        counter.length != SVG_TEXT_MAX_SIZE - 1 || counter.inTag)
    {
        return 0;
    }
    memset(&counter, 0, sizeof(counter));
    tag[SVG_TEXT_MAX_SIZE] = 'x';
    tag[SVG_TEXT_MAX_SIZE + 1] = '>';
    return !SvgWriterCountTags(&counter, tag,
                                SVG_TEXT_MAX_SIZE + 2,
                                SVG_TEXT_MAX_SIZE - 1);
}

typedef struct
{
    char data[1024];
    SvgWriterU16 length;
    SvgWriterU16 calls;
    SvgWriterU16 failAtCall;
} TestSink;

static int
TestWrite(void *userData, const char *data, SvgWriterU16 byteCount)
{
    TestSink *sink;

    sink = (TestSink*)userData;
    sink->calls++;
    if (((sink->failAtCall != 0) &&
         (sink->calls >= sink->failAtCall)) ||
        (byteCount > sizeof(sink->data) - sink->length))
    {
        return 0;
    }
    memcpy(sink->data + sink->length, data, byteCount);
    sink->length += byteCount;
    return 1;
}

static int
CheckFixed(SvgWriterFixed value, SvgWriterU16 digits, const char *expected)
{
    char output[24];
    SvgWriterU16 length;

    if (!SvgWriterFormatFixed(value, digits, output,
                           sizeof(output), &length))
    {
        return 0;
    }
    return (length == strlen(expected)) &&
           (memcmp(output, expected, length) == 0);
}

static int
SinkMatches(const TestSink *sink, const char *expected)
{
    return (sink->length == strlen(expected)) &&
           (memcmp(sink->data, expected, sink->length) == 0);
}

static int
CheckLine(void)
{
    static const char expected[] =
        "  <line x1=\"1.5\" y1=\"-2\" x2=\"3\" y2=\"4.25\""
        " stroke=\"#112233\" stroke-width=\"1\""
        " stroke-linecap=\"butt\" stroke-linejoin=\"miter\""
        " stroke-dasharray=\"none\" stroke-miterlimit=\"4\""
        " fill=\"none\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint start;
    SvgWriterPoint end;
    SvgWriterStyle style;
    SvgWriterMatrix matrix;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    memset(&matrix, 0, sizeof(matrix));
    SvgWriterInit(&writer, TestWrite, &sink);
    start.x = 0x00018000L;
    start.y = -0x00020000L;
    end.x = 0x00030000L;
    end.y = 0x00044000L;
    style.lineWidth = 0x00010000L;
    style.miterLimit = 0x00040000L;
    style.lineRed = 0x11;
    style.lineGreen = 0x22;
    style.lineBlue = 0x33;
    style.includeStroke = 1;
    matrix.a = 0x00010000L;
    matrix.d = 0x00010000L;

    if (!SvgWriterEmitLine(&writer, &start, &end, &style, &matrix))
    {
        return 0;
    }
    return (sink.length == sizeof(expected) - 1) &&
           (memcmp(sink.data, expected, sink.length) == 0);
}

static int
CheckSinkFailure(void)
{
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint start;
    SvgWriterPoint end;
    SvgWriterStyle style;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    sink.failAtCall = 3;
    SvgWriterInit(&writer, TestWrite, &sink);
    start.x = 0;
    start.y = 0;
    end.x = 0x00010000L;
    end.y = 0x00010000L;
    style.includeStroke = 1;
    if (SvgWriterEmitLine(&writer, &start, &end, &style, (void*)0))
    {
        return 0;
    }
    if (SvgWriterEmitFooter(&writer))
    {
        return 0;
    }
    return SvgWriterFailed(&writer) && (sink.calls == 3);
}

static int
CheckTransformedLine(void)
{
    static const char expected[] =
        "  <line x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\""
        " stroke=\"none\" fill=\"none\""
        " transform=\"matrix(2 0.5 -0.25 3 4.000015 -5.25)\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint start;
    SvgWriterPoint end;
    SvgWriterStyle style;
    SvgWriterMatrix matrix;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    memset(&matrix, 0, sizeof(matrix));
    SvgWriterInit(&writer, TestWrite, &sink);
    start.x = 0;
    start.y = 0;
    end.x = 0x00010000L;
    end.y = 0x00010000L;
    matrix.a = 0x00020000L;
    matrix.b = 0x00008000L;
    matrix.c = -0x00004000L;
    matrix.d = 0x00030000L;
    matrix.e = 0x00040001L;
    matrix.f = -0x00054000L;

    if (!SvgWriterEmitLine(&writer, &start, &end, &style, &matrix))
    {
        return 0;
    }
    return (sink.length == sizeof(expected) - 1) &&
           (memcmp(sink.data, expected, sink.length) == 0);
}

static int
CheckArcAngles(void)
{
    SvgWriterU16 start;
    SvgWriterU16 end;
    SvgWriterU16 sweep;
    SvgWriterU16 full;

    if (!SvgWriterNormalizeArcAngles(-90, 90, &start, &end,
                                  &sweep, &full) ||
        (start != 270) || (end != 90) || (sweep != 180) || full)
    {
        return 0;
    }
    if (!SvgWriterNormalizeArcAngles(350, 10, &start, &end,
                                  &sweep, &full) ||
        (start != 350) || (end != 10) || (sweep != 20) || full)
    {
        return 0;
    }
    if (!SvgWriterNormalizeArcAngles(45, 45, &start, &end,
                                  &sweep, &full) ||
        (start != 45) || (end != 45) || (sweep != 0) || full)
    {
        return 0;
    }
    if (!SvgWriterNormalizeArcAngles(-180, 180, &start, &end,
                                  &sweep, &full) ||
        (start != 180) || (end != 180) || (sweep != 0) || !full)
    {
        return 0;
    }
    return SvgWriterNormalizeArcAngles(180, 0, &start, &end,
                                    &sweep, &full) &&
           (start == 180) && (end == 0) && (sweep == 180) && !full;
}

static int
CheckRects(void)
{
    static const char expectedRect[] =
        "  <rect x=\"-32768\" y=\"-1.5\" width=\"65535\" height=\"2.5\""
        " stroke=\"none\" fill=\"none\""
        " transform=\"matrix(0 1 -1 0 5 -6)\" />\n";
    static const char expectedRound[] =
        "  <rect x=\"-3\" y=\"4\" width=\"5\" height=\"7\""
        " rx=\"1.5\" ry=\"2.25\" stroke=\"none\" fill=\"#123456\""
        " fill-rule=\"evenodd\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterRect rect;
    SvgWriterStyle style;
    SvgWriterMatrix matrix;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    memset(&matrix, 0, sizeof(matrix));
    SvgWriterInit(&writer, TestWrite, &sink);
    rect.x = (SvgWriterFixed)(-2147483647L - 1L);
    rect.y = -0x00018000L;
    rect.width = 0xffff0000UL;
    rect.height = 0x00028000UL;
    rect.radiusX = 0;
    rect.radiusY = 0;
    matrix.b = 0x00010000L;
    matrix.c = -0x00010000L;
    matrix.e = 0x00050000L;
    matrix.f = -0x00060000L;
    if (!SvgWriterEmitRect(&writer, &rect, 0, &style, &matrix) ||
        !SinkMatches(&sink, expectedRect))
    {
        return 0;
    }

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    SvgWriterInit(&writer, TestWrite, &sink);
    rect.x = -0x00030000L;
    rect.y = 0x00040000L;
    rect.width = 0x00050000UL;
    rect.height = 0x00070000UL;
    rect.radiusX = 0x00018000UL;
    rect.radiusY = 0x00024000UL;
    style.fillRed = 0x12;
    style.fillGreen = 0x34;
    style.fillBlue = 0x56;
    style.includeFill = 1;
    style.filled = 1;
    style.fillRule = SVG_WRITER_FILL_EVENODD;
    return SvgWriterEmitRect(&writer, &rect, 1, &style, (void*)0) &&
           SinkMatches(&sink, expectedRound);
}

static int
CheckEllipseAndCubic(void)
{
    static const char expected[] =
        "  <ellipse cx=\"-0.5\" cy=\"0.5\" rx=\"32767.5\" ry=\"1.5\""
        " stroke=\"none\" fill=\"none\" />\n"
        "  <path d=\"M -2 -1 C -1.5 0 1.5 2 3 -4\""
        " stroke=\"none\" fill=\"none\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint center;
    SvgWriterPoint start;
    SvgWriterPoint control1;
    SvgWriterPoint control2;
    SvgWriterPoint end;
    SvgWriterStyle style;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    SvgWriterInit(&writer, TestWrite, &sink);
    center.x = -0x00008000L;
    center.y = 0x00008000L;
    if (!SvgWriterEmitEllipse(&writer, &center, 0x7fff8000L,
                           0x00018000L, &style, (void*)0))
    {
        return 0;
    }
    start.x = -0x00020000L;
    start.y = -0x00010000L;
    control1.x = -0x00018000L;
    control1.y = 0;
    control2.x = 0x00018000L;
    control2.y = 0x00020000L;
    end.x = 0x00030000L;
    end.y = -0x00040000L;
    return SvgWriterEmitCubic(&writer, &start, &control1, &control2,
                           &end, &style, (void*)0) &&
           SinkMatches(&sink, expected);
}

static int
CheckArcs(void)
{
    static const char expected[] =
        "  <path d=\"M 10 0 A 10 5 0 0 0 -10 0\""
        " stroke=\"none\" fill=\"none\" />\n"
        "  <path d=\"M 10 0 A 10 5 0 1 0 0 -5 Z\""
        " stroke=\"none\" fill=\"none\" />\n"
        "  <path d=\"M 0 0 L 10 0 A 10 5 0 0 0 10 0 Z\""
        " stroke=\"none\" fill=\"#ABCDEF\" fill-rule=\"evenodd\" />\n"
        "  <path d=\"M 10 0 A 10 5 0 0 0 -10 0"
        " A 10 5 0 0 0 10 0\" stroke=\"none\" fill=\"none\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterArc arc;
    SvgWriterStyle style;

    memset(&sink, 0, sizeof(sink));
    memset(&arc, 0, sizeof(arc));
    memset(&style, 0, sizeof(style));
    SvgWriterInit(&writer, TestWrite, &sink);
    arc.start.x = 0x000a0000L;
    arc.end.x = -0x000a0000L;
    arc.middle.x = -0x000a0000L;
    arc.radiusX = 0x000a0000L;
    arc.radiusY = 0x00050000L;
    arc.sweep = 0;
    arc.closeType = SVG_WRITER_ARC_OPEN;
    if (!SvgWriterEmitArc(&writer, &arc, &style, (void*)0))
    {
        return 0;
    }
    arc.end.x = 0;
    arc.end.y = -0x00050000L;
    arc.largeArc = 1;
    arc.closeType = SVG_WRITER_ARC_CHORD;
    if (!SvgWriterEmitArc(&writer, &arc, &style, (void*)0))
    {
        return 0;
    }
    arc.end.x = 0x000a0000L;
    arc.end.y = 0;
    arc.largeArc = 0;
    arc.closeType = SVG_WRITER_ARC_PIE;
    style.fillRed = 0xab;
    style.fillGreen = 0xcd;
    style.fillBlue = 0xef;
    style.includeFill = 1;
    style.filled = 1;
    style.fillRule = SVG_WRITER_FILL_EVENODD;
    if (!SvgWriterEmitArc(&writer, &arc, &style, (void*)0))
    {
        return 0;
    }
    memset(&style, 0, sizeof(style));
    arc.closeType = SVG_WRITER_ARC_OPEN;
    arc.fullCircle = 1;
    return SvgWriterEmitArc(&writer, &arc, &style, (void*)0) &&
           SinkMatches(&sink, expected);
}

static int
CheckPolygons(void)
{
    static const char expected[] =
        "  <polyline points=\"-1,-2 3,4 \""
        " stroke=\"none\" fill=\"none\" />\n"
        "  <polygon points=\"0,0 5,0 5,5 \""
        " stroke=\"none\" fill=\"#010203\" fill-rule=\"nonzero\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint point;
    SvgWriterStyle style;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    SvgWriterInit(&writer, TestWrite, &sink);
    point.x = -0x00010000L;
    point.y = -0x00020000L;
    if (!SvgWriterEmitPolygonBegin(&writer, 0) ||
        !SvgWriterEmitPolygonPoint(&writer, &point))
    {
        return 0;
    }
    point.x = 0x00030000L;
    point.y = 0x00040000L;
    if (!SvgWriterEmitPolygonPoint(&writer, &point) ||
        !SvgWriterEmitPolygonEnd(&writer, &style, (void*)0))
    {
        return 0;
    }
    style.fillRed = 1;
    style.fillGreen = 2;
    style.fillBlue = 3;
    style.includeFill = 1;
    style.filled = 1;
    point.x = 0;
    point.y = 0;
    if (!SvgWriterEmitPolygonBegin(&writer, 1) ||
        !SvgWriterEmitPolygonPoint(&writer, &point))
    {
        return 0;
    }
    point.x = 0x00050000L;
    if (!SvgWriterEmitPolygonPoint(&writer, &point))
    {
        return 0;
    }
    point.y = 0x00050000L;
    return SvgWriterEmitPolygonPoint(&writer, &point) &&
           SvgWriterEmitPolygonEnd(&writer, &style, (void*)0) &&
           SinkMatches(&sink, expected);
}

static int
CheckStreamedPath(void)
{
    static const char expected[] =
        "  <path d=\"M 1 2 L 3 4 Z \""
        " stroke=\"none\" fill=\"#123456\""
        " fill-rule=\"evenodd\" />\n";
    TestSink sink;
    SvgWriter writer;
    SvgWriterPoint point;
    SvgWriterStyle style;

    memset(&sink, 0, sizeof(sink));
    memset(&style, 0, sizeof(style));
    SvgWriterInit(&writer, TestWrite, &sink);
    style.fillRed = 0x12;
    style.fillGreen = 0x34;
    style.fillBlue = 0x56;
    style.includeFill = 1;
    style.filled = 1;
    style.fillRule = SVG_WRITER_FILL_EVENODD;
    point.x = 0x00010000L;
    point.y = 0x00020000L;
    if (!SvgWriterEmitPathBegin(&writer) ||
        !SvgWriterEmitPathMove(&writer, &point))
    {
        return 0;
    }
    point.x = 0x00030000L;
    point.y = 0x00040000L;
    if (!SvgWriterEmitPathLine(&writer, &point) ||
        !SvgWriterEmitPathClose(&writer) ||
        !SvgWriterEmitPathEnd(&writer, &style, (void*)0))
    {
        return 0;
    }
    return (sink.length == sizeof(expected) - 1) &&
           (memcmp(sink.data, expected, sink.length) == 0);
}

int
main(void)
{
    if (!CheckTagLimit())
    {
        return 14;
    }
    if (!CheckFixed(0x00018000L, 2, "1.5"))
    {
        return 1;
    }
    if (!CheckFixed(-0x00008000L, 2, "-0.5"))
    {
        return 2;
    }
    if (!CheckFixed(0x0000ffffL, 2, "1"))
    {
        return 3;
    }
    if (!CheckFixed(-1L, 2, "0"))
    {
        return 4;
    }
    if (!CheckLine())
    {
        return 5;
    }
    if (!CheckSinkFailure())
    {
        return 6;
    }
    if (!CheckStreamedPath())
    {
        return 7;
    }
    if (!CheckTransformedLine())
    {
        return 8;
    }
    if (!CheckArcAngles())
    {
        return 9;
    }
    if (!CheckRects())
    {
        return 10;
    }
    if (!CheckEllipseAndCubic())
    {
        return 11;
    }
    if (!CheckArcs())
    {
        return 12;
    }
    if (!CheckPolygons())
    {
        return 13;
    }
    return 0;
}
