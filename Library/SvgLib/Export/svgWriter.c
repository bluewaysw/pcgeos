#include "svgWriter.h"

int
SvgWriterCountTags(SvgWriterTagCounter *counter, const char *data,
                   SvgWriterU16 byteCount, SvgWriterU16 maximumLength)
{
    SvgWriterU16 index;
    char ch;

    for (index = 0; index < byteCount; index++)
    {
        ch = data[index];
        if (!counter->inTag)
        {
            if (ch == '<')
            {
                counter->inTag = 1;
                counter->inQuote = 0;
                counter->length = 0;
            }
            continue;
        }
        if (!counter->inQuote && ch == '>')
        {
            counter->inTag = 0;
            continue;
        }
        if (counter->length >= maximumLength)
        {
            return 0;
        }
        counter->length++;
        if (counter->inQuote)
        {
            if (ch == counter->quote) counter->inQuote = 0;
        }
        else if (ch == '"' || ch == '\'')
        {
            counter->inQuote = 1;
            counter->quote = ch;
        }
    }
    return 1;
}

#if defined(__GEOS__)
extern int _pascal
SvgExportInvokeSink(SvgWriterSink *sink,
                     void *userData,
                     const char *data,
                     SvgWriterU16 byteCount);
#endif

#define SVG_WRITER_FIXED_ONE ((SvgWriterU32)65536L)

static int
SvgWriterFormatFixedMagnitude(SvgWriterU32 magnitude,
                           SvgWriterU16 negative,
                           SvgWriterU16 fractionDigits,
                           char *buffer,
                           SvgWriterU16 bufferSize,
                           SvgWriterU16 *length);

static SvgWriterU16
SvgWriterTextLength(const char *text)
{
    SvgWriterU16 length;

    if (text == (void*)0)
    {
        return 0;
    }

    length = 0;
    while ((text[length] != '\0') && (length != 0xffff))
    {
        length++;
    }
    return length;
}

static int
SvgWriterWriteFixed(SvgWriter *writer,
                 SvgWriterFixed value,
                 SvgWriterU16 fractionDigits)
{
    char number[24];
    SvgWriterU16 length;

    if (!SvgWriterFormatFixed(value, fractionDigits, number,
                           sizeof(number), &length))
    {
        return 0;
    }
    return SvgWriterWrite(writer, number, length);
}

static int
SvgWriterWriteUFixed(SvgWriter *writer,
                  SvgWriterU32 value,
                  SvgWriterU16 fractionDigits)
{
    char number[24];
    SvgWriterU16 length;

    if (!SvgWriterFormatFixedMagnitude(value, 0, fractionDigits, number,
                                    sizeof(number), &length))
    {
        return 0;
    }
    return SvgWriterWrite(writer, number, length);
}

static int
SvgWriterWriteU32(SvgWriter *writer, SvgWriterU32 value)
{
    char reversed[10];
    char number[10];
    SvgWriterU16 count;
    SvgWriterU16 index;

    count = 0;
    do
    {
        reversed[count++] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    for (index = 0; index < count; index++)
    {
        number[index] = reversed[count - index - 1];
    }
    return SvgWriterWrite(writer, number, count);
}

static int
SvgWriterWriteI32(SvgWriter *writer, SvgWriterI32 value)
{
    SvgWriterU32 magnitude;

    if (value < 0)
    {
        if (!SvgWriterWriteText(writer, "-"))
        {
            return 0;
        }
        magnitude = (SvgWriterU32)(-(value + 1));
        magnitude++;
    }
    else
    {
        magnitude = (SvgWriterU32)value;
    }
    return SvgWriterWriteU32(writer, magnitude);
}

static int
SvgWriterWriteColor(SvgWriter *writer,
                 SvgWriterU16 red,
                 SvgWriterU16 green,
                 SvgWriterU16 blue)
{
    static const char digits[] = "0123456789ABCDEF";
    char color[7];

    color[0] = '#';
    color[1] = digits[(red >> 4) & 0x0f];
    color[2] = digits[red & 0x0f];
    color[3] = digits[(green >> 4) & 0x0f];
    color[4] = digits[green & 0x0f];
    color[5] = digits[(blue >> 4) & 0x0f];
    color[6] = digits[blue & 0x0f];
    return SvgWriterWrite(writer, color, sizeof(color));
}

static int
SvgWriterStyleIsValid(const SvgWriterStyle *style)
{
    if (style == (void*)0)
    {
        return 0;
    }
    if (style->dashCount > SVG_WRITER_MAX_DASH_VALUES)
    {
        return 0;
    }
    return 1;
}

static int
SvgWriterWriteStyle(SvgWriter *writer, const SvgWriterStyle *style)
{
    const char *cap;
    const char *join;
    const char *fillRule;
    SvgWriterU16 index;

    if (!SvgWriterStyleIsValid(style))
    {
        return 0;
    }

    if (style->includeStroke != 0)
    {
        if (!SvgWriterWriteText(writer, " stroke=\"") ||
            !SvgWriterWriteColor(writer, style->lineRed,
                              style->lineGreen, style->lineBlue) ||
            !SvgWriterWriteText(writer, "\" stroke-width=\"") ||
            !SvgWriterWriteFixed(writer, style->lineWidth, 2) ||
            !SvgWriterWriteText(writer, "\" stroke-linecap=\""))
        {
            return 0;
        }

        cap = "butt";
        if (style->lineCap == SVG_WRITER_CAP_ROUND)
        {
            cap = "round";
        }
        else if (style->lineCap == SVG_WRITER_CAP_SQUARE)
        {
            cap = "square";
        }
        if (!SvgWriterWriteText(writer, cap) ||
            !SvgWriterWriteText(writer, "\" stroke-linejoin=\""))
        {
            return 0;
        }

        join = "miter";
        if (style->lineJoin == SVG_WRITER_JOIN_ROUND)
        {
            join = "round";
        }
        else if (style->lineJoin == SVG_WRITER_JOIN_BEVEL)
        {
            join = "bevel";
        }
        if (!SvgWriterWriteText(writer, join) ||
            !SvgWriterWriteText(writer, "\" stroke-dasharray=\""))
        {
            return 0;
        }

        if (style->dashCount == 0)
        {
            if (!SvgWriterWriteText(writer, "none"))
            {
                return 0;
            }
        }
        else
        {
            for (index = 0; index < style->dashCount; index++)
            {
                if ((index != 0) && !SvgWriterWriteText(writer, " "))
                {
                    return 0;
                }
                if (!SvgWriterWriteFixed(writer, style->dashValues[index], 2))
                {
                    return 0;
                }
            }
        }

        if (!SvgWriterWriteText(writer, "\" stroke-miterlimit=\"") ||
            !SvgWriterWriteFixed(writer, style->miterLimit, 2) ||
            !SvgWriterWriteText(writer, "\""))
        {
            return 0;
        }
        if ((style->dashCount != 0) && (style->hasDashOffset != 0))
        {
            if (!SvgWriterWriteText(writer, " stroke-dashoffset=\"") ||
                !SvgWriterWriteFixed(writer, style->dashOffset, 2) ||
                !SvgWriterWriteText(writer, "\""))
            {
                return 0;
            }
        }
    }
    else if (!SvgWriterWriteText(writer, " stroke=\"none\""))
    {
        return 0;
    }

    if (style->includeFill != 0)
    {
        if (!SvgWriterWriteText(writer, " fill=\""))
        {
            return 0;
        }
        if (style->filled != 0)
        {
            if (!SvgWriterWriteColor(writer, style->fillRed,
                                  style->fillGreen, style->fillBlue))
            {
                return 0;
            }
        }
        else if (!SvgWriterWriteText(writer, "none"))
        {
            return 0;
        }

        fillRule = (style->fillRule == SVG_WRITER_FILL_EVENODD) ?
                   "evenodd" : "nonzero";
        if (!SvgWriterWriteText(writer, "\" fill-rule=\"") ||
            !SvgWriterWriteText(writer, fillRule) ||
            !SvgWriterWriteText(writer, "\""))
        {
            return 0;
        }
    }
    else if (!SvgWriterWriteText(writer, " fill=\"none\""))
    {
        return 0;
    }

    return 1;
}

static int
SvgWriterWriteMatrix(SvgWriter *writer, const SvgWriterMatrix *matrix)
{
    if (matrix == (void*)0)
    {
        return 1;
    }
    if ((matrix->a == 0x00010000L) && (matrix->b == 0) &&
        (matrix->c == 0) && (matrix->d == 0x00010000L) &&
        (matrix->e == 0) && (matrix->f == 0))
    {
        return 1;
    }

    return SvgWriterWriteText(writer, " transform=\"matrix(") &&
           SvgWriterWriteFixed(writer, matrix->a, 6) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, matrix->b, 6) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, matrix->c, 6) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, matrix->d, 6) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, matrix->e, 6) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, matrix->f, 6) &&
           SvgWriterWriteText(writer, ")\"");
}

void
SvgWriterInit(SvgWriter *writer,
                 SvgWriterSink *sink,
                 void *userData)
{
    if (writer == (void*)0)
    {
        return;
    }

    writer->sink = sink;
    writer->userData = userData;
    writer->failed = 0;
}

int
SvgWriterFailed(const SvgWriter *writer)
{
    return ((writer == (void*)0) || (writer->failed != 0));
}

int
SvgWriterWrite(SvgWriter *writer,
            const char *data,
            SvgWriterU16 byteCount)
{
    if ((writer == (void*)0) || (writer->sink == (void*)0) ||
        (data == (void*)0) || (writer->failed != 0))
    {
        return 0;
    }
    if (byteCount == 0)
    {
        return 1;
    }
#if defined(__GEOS__)
    if (!SvgExportInvokeSink(writer->sink, writer->userData,
                              data, byteCount))
#else
    if (!writer->sink(writer->userData, data, byteCount))
#endif
    {
        writer->failed = 1;
        return 0;
    }
    return 1;
}

int
SvgWriterWriteText(SvgWriter *writer, const char *text)
{
    if (text == (void*)0)
    {
        return 0;
    }
    return SvgWriterWrite(writer, text, SvgWriterTextLength(text));
}

int
SvgWriterFormatFixed(SvgWriterFixed value,
                  SvgWriterU16 fractionDigits,
                  char *buffer,
                  SvgWriterU16 bufferSize,
                  SvgWriterU16 *length)
{
    SvgWriterU32 magnitude;
    SvgWriterU16 negative;

    negative = (value < 0) ? 1 : 0;
    if (negative != 0)
    {
        magnitude = (SvgWriterU32)(-(value + 1));
        magnitude++;
    }
    else
    {
        magnitude = (SvgWriterU32)value;
    }
    return SvgWriterFormatFixedMagnitude(magnitude, negative, fractionDigits,
                                      buffer, bufferSize, length);
}

static int
SvgWriterFormatFixedMagnitude(SvgWriterU32 magnitude,
                           SvgWriterU16 negative,
                           SvgWriterU16 fractionDigits,
                           char *buffer,
                           SvgWriterU16 bufferSize,
                           SvgWriterU16 *length)
{
    char integerDigits[10];
    char fraction[6];
    SvgWriterU32 integerPart;
    SvgWriterU32 fractionPart;
    SvgWriterU32 product;
    SvgWriterU16 integerCount;
    SvgWriterU16 fractionCount;
    SvgWriterU16 outputLength;
    SvgWriterU16 index;
    SvgWriterU16 carry;

    if ((buffer == (void*)0) || (length == (void*)0) ||
        (bufferSize == 0) || (fractionDigits > 6))
    {
        return 0;
    }

    integerPart = magnitude >> 16;
    fractionPart = magnitude & 0xffff;
    fractionCount = fractionDigits;
    for (index = 0; index < fractionDigits; index++)
    {
        product = fractionPart * 10;
        fraction[index] = (char)('0' + (product >> 16));
        fractionPart = product & 0xffff;
    }

    product = fractionPart * 10;
    carry = ((product >> 16) >= 5) ? 1 : 0;
    index = fractionCount;
    while ((carry != 0) && (index != 0))
    {
        index--;
        if (fraction[index] == '9')
        {
            fraction[index] = '0';
        }
        else
        {
            fraction[index]++;
            carry = 0;
        }
    }
    if (carry != 0)
    {
        integerPart++;
    }
    while ((fractionCount != 0) &&
           (fraction[fractionCount - 1] == '0'))
    {
        fractionCount--;
    }
    if ((integerPart == 0) && (fractionCount == 0))
    {
        negative = 0;
    }

    integerCount = 0;
    do
    {
        integerDigits[integerCount++] =
            (char)('0' + (integerPart % 10));
        integerPart /= 10;
    } while (integerPart != 0);

    outputLength = negative + integerCount;
    if (fractionCount != 0)
    {
        outputLength += 1 + fractionCount;
    }
    if (outputLength >= bufferSize)
    {
        return 0;
    }

    index = 0;
    if (negative != 0)
    {
        buffer[index++] = '-';
    }
    while (integerCount != 0)
    {
        buffer[index++] = integerDigits[--integerCount];
    }
    if (fractionCount != 0)
    {
        buffer[index++] = '.';
        for (integerCount = 0; integerCount < fractionCount; integerCount++)
        {
            buffer[index++] = fraction[integerCount];
        }
    }
    buffer[index] = '\0';
    *length = index;
    return 1;
}

#ifdef __GEOS__
#pragma code_seg("svgarc_TEXT")
#endif
int
SvgWriterNormalizeArcAngles(SvgWriterI16 startAngle,
                         SvgWriterI16 endAngle,
                         SvgWriterU16 *normalizedStart,
                         SvgWriterU16 *normalizedEnd,
                         SvgWriterU16 *sweepDegrees,
                         SvgWriterU16 *fullCircle)
{
    SvgWriterI32 start;
    SvgWriterI32 difference;
    SvgWriterI32 sweep;

    if ((normalizedStart == (void*)0) ||
        (normalizedEnd == (void*)0) ||
        (sweepDegrees == (void*)0) ||
        (fullCircle == (void*)0))
    {
        return 0;
    }
    start = (SvgWriterI32)startAngle % 360;
    if (start < 0)
    {
        start += 360;
    }
    difference = (SvgWriterI32)endAngle - (SvgWriterI32)startAngle;
    sweep = difference % 360;
    if (sweep < 0)
    {
        sweep += 360;
    }
    *normalizedStart = (SvgWriterU16)start;
    *sweepDegrees = (SvgWriterU16)sweep;
    *normalizedEnd = (SvgWriterU16)((start + sweep) % 360);
    *fullCircle = ((difference != 0) && (sweep == 0)) ? 1 : 0;
    return 1;
}
#ifdef __GEOS__
#pragma code_seg()
#endif

int
SvgWriterEmitHeader(SvgWriter *writer,
                 SvgWriterI32 left,
                 SvgWriterI32 top,
                 SvgWriterU32 width,
                 SvgWriterU32 height)
{
    return SvgWriterWriteText(writer,
                           "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n") &&
           SvgWriterWriteText(writer,
                           "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"\n") &&
           SvgWriterWriteText(writer, "     width=\"") &&
           SvgWriterWriteU32(writer, width) &&
           SvgWriterWriteText(writer, "\" height=\"") &&
           SvgWriterWriteU32(writer, height) &&
           SvgWriterWriteText(writer, "\" viewBox=\"") &&
           SvgWriterWriteI32(writer, left) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteI32(writer, top) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteU32(writer, width) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteU32(writer, height) &&
           SvgWriterWriteText(writer, "\">\n");
}

int
SvgWriterEmitFooter(SvgWriter *writer)
{
    return SvgWriterWriteText(writer, "</svg>\n");
}

int
SvgWriterEmitLine(SvgWriter *writer,
               const SvgWriterPoint *start,
               const SvgWriterPoint *end,
               const SvgWriterStyle *style,
               const SvgWriterMatrix *matrix)
{
    if ((start == (void*)0) || (end == (void*)0) ||
        !SvgWriterStyleIsValid(style))
    {
        return 0;
    }

    return SvgWriterWriteText(writer, "  <line x1=\"") &&
           SvgWriterWriteFixed(writer, start->x, 2) &&
           SvgWriterWriteText(writer, "\" y1=\"") &&
           SvgWriterWriteFixed(writer, start->y, 2) &&
           SvgWriterWriteText(writer, "\" x2=\"") &&
           SvgWriterWriteFixed(writer, end->x, 2) &&
           SvgWriterWriteText(writer, "\" y2=\"") &&
           SvgWriterWriteFixed(writer, end->y, 2) &&
           SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}

int
SvgWriterEmitRect(SvgWriter *writer,
               const SvgWriterRect *rect,
               SvgWriterU16 rounded,
               const SvgWriterStyle *style,
               const SvgWriterMatrix *matrix)
{
    if ((rect == (void*)0) || !SvgWriterStyleIsValid(style))
    {
        return 0;
    }

    if (!SvgWriterWriteText(writer, "  <rect x=\"") ||
        !SvgWriterWriteFixed(writer, rect->x, 2) ||
        !SvgWriterWriteText(writer, "\" y=\"") ||
        !SvgWriterWriteFixed(writer, rect->y, 2) ||
        !SvgWriterWriteText(writer, "\" width=\"") ||
        !SvgWriterWriteUFixed(writer, rect->width, 2) ||
        !SvgWriterWriteText(writer, "\" height=\"") ||
        !SvgWriterWriteUFixed(writer, rect->height, 2) ||
        !SvgWriterWriteText(writer, "\""))
    {
        return 0;
    }
    if (rounded != 0)
    {
        if (!SvgWriterWriteText(writer, " rx=\"") ||
            !SvgWriterWriteUFixed(writer, rect->radiusX, 2) ||
            !SvgWriterWriteText(writer, "\" ry=\"") ||
            !SvgWriterWriteUFixed(writer, rect->radiusY, 2) ||
            !SvgWriterWriteText(writer, "\""))
        {
            return 0;
        }
    }
    return SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}

int
SvgWriterEmitEllipse(SvgWriter *writer,
                  const SvgWriterPoint *center,
                  SvgWriterFixed radiusX,
                  SvgWriterFixed radiusY,
                  const SvgWriterStyle *style,
                  const SvgWriterMatrix *matrix)
{
    if ((center == (void*)0) || !SvgWriterStyleIsValid(style))
    {
        return 0;
    }

    return SvgWriterWriteText(writer, "  <ellipse cx=\"") &&
           SvgWriterWriteFixed(writer, center->x, 2) &&
           SvgWriterWriteText(writer, "\" cy=\"") &&
           SvgWriterWriteFixed(writer, center->y, 2) &&
           SvgWriterWriteText(writer, "\" rx=\"") &&
           SvgWriterWriteFixed(writer, radiusX, 2) &&
           SvgWriterWriteText(writer, "\" ry=\"") &&
           SvgWriterWriteFixed(writer, radiusY, 2) &&
           SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}

int
SvgWriterEmitCubic(SvgWriter *writer,
                const SvgWriterPoint *start,
                const SvgWriterPoint *control1,
                const SvgWriterPoint *control2,
                const SvgWriterPoint *end,
                const SvgWriterStyle *style,
                const SvgWriterMatrix *matrix)
{
    if ((start == (void*)0) || (control1 == (void*)0) ||
        (control2 == (void*)0) || (end == (void*)0) ||
        !SvgWriterStyleIsValid(style))
    {
        return 0;
    }

    return SvgWriterWriteText(writer, "  <path d=\"M ") &&
           SvgWriterWriteFixed(writer, start->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, start->y, 2) &&
           SvgWriterWriteText(writer, " C ") &&
           SvgWriterWriteFixed(writer, control1->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, control1->y, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, control2->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, control2->y, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, end->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, end->y, 2) &&
           SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}

#ifdef __GEOS__
#pragma code_seg("svgarc_TEXT")
#endif
static int
SvgWriterWriteArcCommand(SvgWriter *writer,
                      const SvgWriterArc *arc,
                      const SvgWriterPoint *end,
                      SvgWriterU16 largeArc)
{
    return SvgWriterWriteText(writer, " A ") &&
           SvgWriterWriteFixed(writer, arc->radiusX, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, arc->radiusY, 2) &&
           SvgWriterWriteText(writer, " 0 ") &&
           SvgWriterWriteU32(writer, largeArc ? 1 : 0) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteU32(writer, arc->sweep ? 1 : 0) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, end->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, end->y, 2);
}

int
SvgWriterEmitArc(SvgWriter *writer,
              const SvgWriterArc *arc,
              const SvgWriterStyle *style,
              const SvgWriterMatrix *matrix)
{
    if ((arc == (void*)0) || !SvgWriterStyleIsValid(style))
    {
        return 0;
    }
    if (arc->closeType > SVG_WRITER_ARC_PIE)
    {
        return 0;
    }

    if (!SvgWriterWriteText(writer, "  <path d=\"M "))
    {
        return 0;
    }
    if (arc->closeType == SVG_WRITER_ARC_PIE)
    {
        if (!SvgWriterWriteFixed(writer, arc->center.x, 2) ||
            !SvgWriterWriteText(writer, " ") ||
            !SvgWriterWriteFixed(writer, arc->center.y, 2) ||
            !SvgWriterWriteText(writer, " L "))
        {
            return 0;
        }
    }
    if (!SvgWriterWriteFixed(writer, arc->start.x, 2) ||
        !SvgWriterWriteText(writer, " ") ||
        !SvgWriterWriteFixed(writer, arc->start.y, 2))
    {
        return 0;
    }
    if (arc->fullCircle != 0)
    {
        if (!SvgWriterWriteArcCommand(writer, arc, &arc->middle, 0) ||
            !SvgWriterWriteArcCommand(writer, arc, &arc->end, 0))
        {
            return 0;
        }
    }
    else if (!SvgWriterWriteArcCommand(writer, arc, &arc->end,
                                    arc->largeArc))
    {
        return 0;
    }
    if ((arc->closeType != SVG_WRITER_ARC_OPEN) &&
        !SvgWriterWriteText(writer, " Z"))
    {
        return 0;
    }
    return SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}
#ifdef __GEOS__
#pragma code_seg()
#endif

int
SvgWriterEmitPolygonBegin(SvgWriter *writer, SvgWriterU16 closed)
{
    return SvgWriterWriteText(writer,
                           closed ? "  <polygon points=\"" :
                                    "  <polyline points=\"");
}

int
SvgWriterEmitPolygonPoint(SvgWriter *writer,
                       const SvgWriterPoint *point)
{
    if (point == (void*)0)
    {
        return 0;
    }
    return SvgWriterWriteFixed(writer, point->x, 2) &&
           SvgWriterWriteText(writer, ",") &&
           SvgWriterWriteFixed(writer, point->y, 2) &&
           SvgWriterWriteText(writer, " ");
}

int
SvgWriterEmitPolygonEnd(SvgWriter *writer,
                     const SvgWriterStyle *style,
                     const SvgWriterMatrix *matrix)
{
    if (!SvgWriterStyleIsValid(style))
    {
        return 0;
    }
    return SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}

int
SvgWriterEmitPathBegin(SvgWriter *writer)
{
    return SvgWriterWriteText(writer, "  <path d=\"");
}

static int
SvgWriterWritePathPoint(SvgWriter *writer,
                     const SvgWriterPoint *point)
{
    if (point == (void*)0)
    {
        return 0;
    }
    return SvgWriterWriteFixed(writer, point->x, 2) &&
           SvgWriterWriteText(writer, " ") &&
           SvgWriterWriteFixed(writer, point->y, 2) &&
           SvgWriterWriteText(writer, " ");
}

int
SvgWriterEmitPathMove(SvgWriter *writer,
                   const SvgWriterPoint *point)
{
    return SvgWriterWriteText(writer, "M ") &&
           SvgWriterWritePathPoint(writer, point);
}

int
SvgWriterEmitPathLine(SvgWriter *writer,
                   const SvgWriterPoint *point)
{
    return SvgWriterWriteText(writer, "L ") &&
           SvgWriterWritePathPoint(writer, point);
}

int
SvgWriterEmitPathCubic(SvgWriter *writer,
                    const SvgWriterPoint *control1,
                    const SvgWriterPoint *control2,
                    const SvgWriterPoint *end)
{
    return SvgWriterWriteText(writer, "C ") &&
           SvgWriterWritePathPoint(writer, control1) &&
           SvgWriterWritePathPoint(writer, control2) &&
           SvgWriterWritePathPoint(writer, end);
}

int
SvgWriterEmitPathClose(SvgWriter *writer)
{
    return SvgWriterWriteText(writer, "Z ");
}

int
SvgWriterEmitPathEnd(SvgWriter *writer,
                  const SvgWriterStyle *style,
                  const SvgWriterMatrix *matrix)
{
    if (!SvgWriterStyleIsValid(style))
    {
        return 0;
    }
    return SvgWriterWriteText(writer, "\"") &&
           SvgWriterWriteStyle(writer, style) &&
           SvgWriterWriteMatrix(writer, matrix) &&
           SvgWriterWriteText(writer, " />\n");
}
