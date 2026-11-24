#ifndef __SVG_EXPORTCORE_H_
#define __SVG_EXPORTCORE_H_

typedef signed short SvgWriterI16;
typedef unsigned short SvgWriterU16;
#if defined(__WATCOMC__) && !defined(__386__)
typedef signed long SvgWriterI32;
typedef unsigned long SvgWriterU32;
#else
typedef signed int SvgWriterI32;
typedef unsigned int SvgWriterU32;
#endif

typedef char SvgWriterCheckI16[(sizeof(SvgWriterI16) == 2) ? 1 : -1];
typedef char SvgWriterCheckU16[(sizeof(SvgWriterU16) == 2) ? 1 : -1];
typedef char SvgWriterCheckI32[(sizeof(SvgWriterI32) == 4) ? 1 : -1];
typedef char SvgWriterCheckU32[(sizeof(SvgWriterU32) == 4) ? 1 : -1];

#define SVG_WRITER_MAX_DASH_VALUES 10

#define SVG_WRITER_CAP_BUTT         0
#define SVG_WRITER_CAP_ROUND        1
#define SVG_WRITER_CAP_SQUARE       2

#define SVG_WRITER_JOIN_MITER       0
#define SVG_WRITER_JOIN_ROUND       1
#define SVG_WRITER_JOIN_BEVEL       2

#define SVG_WRITER_FILL_NONZERO     0
#define SVG_WRITER_FILL_EVENODD     1

#define SVG_WRITER_ARC_OPEN         0
#define SVG_WRITER_ARC_CHORD        1
#define SVG_WRITER_ARC_PIE          2

#if defined(__GEOS__)
typedef int _pascal SvgWriterSink(void *userData,
                               const char *data,
                               SvgWriterU16 byteCount);
#else
typedef int SvgWriterSink(void *userData,
                       const char *data,
                       SvgWriterU16 byteCount);
#endif

typedef struct
{
    SvgWriterSink *sink;
    void *userData;
    SvgWriterU16 failed;
} SvgWriter;

typedef struct
{
    SvgWriterU16 length;
    SvgWriterU16 inTag;
    SvgWriterU16 inQuote;
    char quote;
} SvgWriterTagCounter;

int SvgWriterCountTags(SvgWriterTagCounter *counter, const char *data,
                       SvgWriterU16 byteCount, SvgWriterU16 maximumLength);

typedef SvgWriterI32 SvgWriterFixed;

typedef struct
{
    SvgWriterFixed x;
    SvgWriterFixed y;
} SvgWriterPoint;

typedef struct
{
    SvgWriterFixed a;
    SvgWriterFixed b;
    SvgWriterFixed c;
    SvgWriterFixed d;
    SvgWriterFixed e;
    SvgWriterFixed f;
} SvgWriterMatrix;

typedef struct
{
    SvgWriterFixed lineWidth;
    SvgWriterFixed miterLimit;
    SvgWriterU16 lineRed;
    SvgWriterU16 lineGreen;
    SvgWriterU16 lineBlue;
    SvgWriterU16 fillRed;
    SvgWriterU16 fillGreen;
    SvgWriterU16 fillBlue;
    SvgWriterU16 lineCap;
    SvgWriterU16 lineJoin;
    SvgWriterU16 dashCount;
    SvgWriterFixed dashValues[SVG_WRITER_MAX_DASH_VALUES];
    SvgWriterFixed dashOffset;
    SvgWriterU16 hasDashOffset;
    SvgWriterU16 includeStroke;
    SvgWriterU16 includeFill;
    SvgWriterU16 filled;
    SvgWriterU16 fillRule;
} SvgWriterStyle;

typedef struct
{
    SvgWriterFixed x;
    SvgWriterFixed y;
    SvgWriterU32 width;
    SvgWriterU32 height;
    SvgWriterU32 radiusX;
    SvgWriterU32 radiusY;
} SvgWriterRect;

typedef struct
{
    SvgWriterPoint center;
    SvgWriterPoint start;
    SvgWriterPoint middle;
    SvgWriterPoint end;
    SvgWriterFixed radiusX;
    SvgWriterFixed radiusY;
    SvgWriterU16 largeArc;
    SvgWriterU16 sweep;
    SvgWriterU16 closeType;
    SvgWriterU16 fullCircle;
} SvgWriterArc;

void SvgWriterInit(SvgWriter *writer,
                      SvgWriterSink *sink,
                      void *userData);
int SvgWriterFailed(const SvgWriter *writer);
int SvgWriterWrite(SvgWriter *writer,
                const char *data,
                SvgWriterU16 byteCount);
int SvgWriterWriteText(SvgWriter *writer, const char *text);

int SvgWriterFormatFixed(SvgWriterFixed value,
                      SvgWriterU16 fractionDigits,
                      char *buffer,
                      SvgWriterU16 bufferSize,
                      SvgWriterU16 *length);
int SvgWriterNormalizeArcAngles(SvgWriterI16 startAngle,
                             SvgWriterI16 endAngle,
                             SvgWriterU16 *normalizedStart,
                             SvgWriterU16 *normalizedEnd,
                             SvgWriterU16 *sweepDegrees,
                             SvgWriterU16 *fullCircle);

int SvgWriterEmitHeader(SvgWriter *writer,
                     SvgWriterI32 left,
                     SvgWriterI32 top,
                     SvgWriterU32 width,
                     SvgWriterU32 height);
int SvgWriterEmitFooter(SvgWriter *writer);
int SvgWriterEmitLine(SvgWriter *writer,
                   const SvgWriterPoint *start,
                   const SvgWriterPoint *end,
                   const SvgWriterStyle *style,
                   const SvgWriterMatrix *matrix);
int SvgWriterEmitRect(SvgWriter *writer,
                   const SvgWriterRect *rect,
                   SvgWriterU16 rounded,
                   const SvgWriterStyle *style,
                   const SvgWriterMatrix *matrix);
int SvgWriterEmitEllipse(SvgWriter *writer,
                      const SvgWriterPoint *center,
                      SvgWriterFixed radiusX,
                      SvgWriterFixed radiusY,
                      const SvgWriterStyle *style,
                      const SvgWriterMatrix *matrix);
int SvgWriterEmitCubic(SvgWriter *writer,
                    const SvgWriterPoint *start,
                    const SvgWriterPoint *control1,
                    const SvgWriterPoint *control2,
                    const SvgWriterPoint *end,
                    const SvgWriterStyle *style,
                    const SvgWriterMatrix *matrix);
int SvgWriterEmitArc(SvgWriter *writer,
                  const SvgWriterArc *arc,
                  const SvgWriterStyle *style,
                  const SvgWriterMatrix *matrix);
int SvgWriterEmitPolygonBegin(SvgWriter *writer,
                           SvgWriterU16 closed);
int SvgWriterEmitPolygonPoint(SvgWriter *writer,
                           const SvgWriterPoint *point);
int SvgWriterEmitPolygonEnd(SvgWriter *writer,
                         const SvgWriterStyle *style,
                         const SvgWriterMatrix *matrix);
int SvgWriterEmitPathBegin(SvgWriter *writer);
int SvgWriterEmitPathMove(SvgWriter *writer,
                       const SvgWriterPoint *point);
int SvgWriterEmitPathLine(SvgWriter *writer,
                       const SvgWriterPoint *point);
int SvgWriterEmitPathCubic(SvgWriter *writer,
                        const SvgWriterPoint *control1,
                        const SvgWriterPoint *control2,
                        const SvgWriterPoint *end);
int SvgWriterEmitPathClose(SvgWriter *writer);
int SvgWriterEmitPathEnd(SvgWriter *writer,
                      const SvgWriterStyle *style,
                      const SvgWriterMatrix *matrix);

#endif
