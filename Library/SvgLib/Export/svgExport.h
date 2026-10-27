#ifndef __SVG_EXPORTEXP_H_
#define __SVG_EXPORTEXP_H_

#include <geos.h>
#include <heap.h>
#include <lmem.h>
#include <library.h>
#include <graphics.h>
#include <gstring.h>
#include <file.h>
#include <color.h>
#include <localize.h>
#include <Ansi/string.h>
#include <resource.h>
#include <system.h>

#include <xlatLib.h>
#include <svgLib.h>

#include "svgWriter.h"
#include "svgLimits.h"

#define SVG_EXPORT_INVALID_OPCODE  0xff
#define SVG_EXPORT_OPCODE_SIZE     1
#define SVG_EXPORT_WORD_SIZE       2
#define SVG_EXPORT_POINT_SIZE      4
#define SVG_EXPORT_COMMENT_HEADER_SIZE             3
#define SVG_EXPORT_POLY_HEADER_SIZE                3
#define SVG_EXPORT_FILL_POLYGON_HEADER_SIZE        4
#define SVG_EXPORT_CUSTOM_LINE_STYLE_HEADER_SIZE   5
#define SVG_EXPORT_MAX_POINT_COUNT       4096
#define SVG_EXPORT_ELEMENT_BUFFER_SIZE \
    (SVG_EXPORT_FILL_POLYGON_HEADER_SIZE + \
     (SVG_EXPORT_MAX_POINT_COUNT * SVG_EXPORT_POINT_SIZE))
#define SVG_EXPORT_TRACE_OPCODES     1

typedef enum
{
    SVG_OPCODE_SUPPORTED_RENDERING,
    SVG_OPCODE_SUPPORTED_STATE,
    SVG_OPCODE_IGNORABLE_METADATA,
    SVG_OPCODE_UNSUPPORTED_RENDERING
} SvgExportOpcodeClass;

typedef enum
{
    SVG_GEOMETRY_NONE,
    SVG_GEOMETRY_MOVE,
    SVG_GEOMETRY_LINE,
    SVG_GEOMETRY_CURVE,
    SVG_GEOMETRY_CLOSE
} SvgExportGeometryType;

typedef struct
{
    Boolean subpathOpen;
    Boolean hasData;
    PointWWFixed lastPoint;
    PointWWFixed subpathStart;
} SvgExportPathBuilder;

/*
 * ATTENTION: GrGetLineStyle() cannot return a saved custom dash array.
 * Mirror only that unavailable state here. Remove this side stack if the
 * graphics API gains a custom-dash getter.
 */
typedef struct
{
    word pairCount;
    word skipCount;
    word pattern[MAX_DASH_ARRAY_PAIRS * 2];
} SvgExportDashState;

typedef struct
{
    FileHandle svgFile;
    SvgWriter writer;
    SvgWriterTagCounter tagCounter;
    Boolean tagTooLarge;
    RectDWord bounds;
    WWFixedAsDWord lineWidth;
    RGBColorAsDWord lineColor;
    RGBColorAsDWord fillColor;
    LineJoin lineJoin;
    LineEnd lineCap;
    WWFixedAsDWord miterLimit;
    LineStyle lineStyle;
    word dashPairCount;
    word dashSkipCount;
    word dashPattern[MAX_DASH_ARRAY_PAIRS * 2];
    RegionFillRule fillRule;
    MemHandle bufferHeapH;
    ChunkHandle scratchChunkH;
    word scratchCapacity;
    ChunkHandle dashStackChunkH;
    word dashStackCapacity;
    word dashStackDepth;
    word requiredDashStackDepth;
    const byte *elementDataP;
    word elementSize;
} SvgExportContext;

Boolean _pascal SvgExportInitWriter(SvgExportContext *context);
void _pascal SvgExportInitCountingWriter(SvgExportContext *context);
Boolean _pascal SvgExportWriteHeader(SvgExportContext *context);
Boolean _pascal SvgExportWriteFooter(SvgExportContext *context);
Boolean _pascal SvgExportWriteLineElement(SvgExportContext *context, const PointWWFixed *startPoint, const PointWWFixed *endPoint, const TransMatrix *tm);
Boolean _pascal SvgExportWriteRectElement(SvgExportContext *context, const PointWWFixed *corner1, const PointWWFixed *corner3, Boolean includeStroke, Boolean includeFill, Boolean filled, const TransMatrix *tm);
Boolean _pascal SvgExportWriteRoundRectElement(SvgExportContext *context, const PointWWFixed *corner1, const PointWWFixed *corner3, word radiusX, word radiusY, Boolean includeStroke, Boolean includeFill, Boolean filled, const TransMatrix *tm);
Boolean _pascal SvgExportWritePolygonBegin(SvgExportContext *context,
                                            Boolean closeShape);
Boolean _pascal SvgExportWritePolygonPoint(SvgExportContext *context,
                                            const PointWWFixed *point);
Boolean _pascal SvgExportWritePolygonEnd(SvgExportContext *context,
                                          Boolean filled,
                                          RegionFillRule fillRule,
                                          const TransMatrix *tm);
Boolean _pascal SvgExportWriteEllipseElement(SvgExportContext *context,
                                              const WWFixed *cx,
                                              const WWFixed *cy,
                                              const WWFixed *rx,
                                              const WWFixed *ry,
                                              Boolean includeStroke,
                                              Boolean includeFill,
                                              Boolean filled,
                                              const TransMatrix *tm);
Boolean _pascal SvgExportWriteCubicPathElement(SvgExportContext *context,
                                                const PointWWFixed *start,
                                                const PointWWFixed *cp1,
                                                const PointWWFixed *cp2,
                                                const PointWWFixed *end,
                                                const TransMatrix *tm);
Boolean _pascal SvgExportWriteArcElement(SvgExportContext *context,
                                          WWFixedAsDWord cx,
                                          WWFixedAsDWord cy,
                                          WWFixedAsDWord rx,
                                          WWFixedAsDWord ry,
                                          sword startAngleDeg,
                                          sword endAngleDeg,
                                          ArcCloseType closeType,
                                          Boolean filled,
                                          const TransMatrix *tm);
Boolean _pascal SvgExportWritePathBegin(SvgExportContext *context);
Boolean _pascal SvgExportWritePathMove(SvgExportContext *context,
                                        const PointWWFixed *point);
Boolean _pascal SvgExportWritePathLine(SvgExportContext *context,
                                        const PointWWFixed *point);
Boolean _pascal SvgExportWritePathCubic(SvgExportContext *context,
                                         const PointWWFixed *control1,
                                         const PointWWFixed *control2,
                                         const PointWWFixed *end);
Boolean _pascal SvgExportWritePathClose(SvgExportContext *context);
Boolean _pascal SvgExportWritePathEnd(SvgExportContext *context,
                                       Boolean fillPath,
                                       Boolean strokePath,
                                       RegionFillRule fillRule,
                                       const TransMatrix *tm);
Boolean _pascal SvgExportUpdateDrawingState(GStateHandle gstate, SvgExportContext *context);
void _pascal SvgExportPointFromInt(const Point *sourcePoint,
                                    PointWWFixed *targetPoint);
WWFixedAsDWord _pascal SvgExportPackWWFixed(const WWFixed *value);
void _pascal SvgExportCopyPointWWFixed(PointWWFixed *destination, const PointWWFixed *source);
Boolean _pascal SvgExportEnsureScratch(SvgExportContext *context,
                                        word size);
SvgExportOpcodeClass _pascal
SvgExportClassifyOpcode(word elementType);
void* _pascal SvgExportAs(const void *raw, word expectedOpcode);
Boolean _pascal SvgExportIsLineOpcode(word elementType);
Boolean _pascal SvgExportIsRectangleOpcode(word elementType);
Boolean _pascal SvgExportIsRoundRectOpcode(word elementType);
Boolean _pascal SvgExportIsEllipseOpcode(word elementType);
Boolean _pascal SvgExportIsCurveOpcode(word elementType);
Boolean _pascal SvgExportIsArcOpcode(word elementType);
Boolean _pascal SvgExportIsPolygonOpcode(word elementType);
Boolean _pascal SvgExportIsPathOpcode(word elementType);
Boolean _pascal SvgExportIsStyleStateOpcode(word elementType);
word _pascal SvgExportValidateElement(const byte *elementData,
                                       word elementType,
                                       word elementSize);
word _pascal SvgExportReadElement(SvgExportContext *context,
                                   GStateHandle playbackGState,
                                   GStateHandle sourceGState,
                                   word expectedType);
void _pascal SvgExportReleaseElement(SvgExportContext *context);
word _pascal SvgExportDecodeGeometry(
    word elementType,
    const PointWWFixed *currentPosition,
    const byte *elementData,
    word elementSize,
    SvgExportGeometryType *geometryType,
    PointWWFixed *startPoint,
    PointWWFixed *control1,
    PointWWFixed *control2,
    PointWWFixed *endPoint);
void _pascal SvgExportSetWWFixedComponent(
    WWFixed *component,
    WWFixedAsDWord value);
word _pascal SvgExportReadWord(const byte *data, word offset);
sword _pascal SvgExportReadSword(const byte *data, word offset);
void _pascal SvgExportReadWWFixed(const byte *data,
                                   word offset,
                                   WWFixed *value);
Boolean _pascal SvgExportPathBuilderMoveTo(
    SvgExportContext *context,
    SvgExportPathBuilder *builder,
    const PointWWFixed *point);
Boolean _pascal SvgExportPathBuilderLineTo(
    SvgExportContext *context,
    SvgExportPathBuilder *builder,
    const PointWWFixed *startPoint,
    const PointWWFixed *endPoint);
Boolean _pascal SvgExportPathBuilderCurveTo(
    SvgExportContext *context,
    SvgExportPathBuilder *builder,
    const PointWWFixed *startPoint,
    const PointWWFixed *control1,
    const PointWWFixed *control2,
    const PointWWFixed *endPoint);
Boolean _pascal SvgExportPathBuilderClose(
    SvgExportContext *context,
    SvgExportPathBuilder *builder);

#endif
