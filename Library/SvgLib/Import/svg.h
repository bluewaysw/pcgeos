/* Private definitions shared by the SvgLib importer modules. */

#ifndef __SVG_IMPORT_H
#define __SVG_IMPORT_H

#include <svgLib.h>

#include "svgLimits.h"

#include "Import/svgRendererCore.h"

#define SVG_COLOR_NAME_LEN              32
#define SVG_IO_BUF_SIZE                 1024
#define SVG_TEXT_INITIAL_SIZE           1024
#define SVG_POINTS_INITIAL_CAPACITY     128
#define MAX_SVG_POINTS                  4096
#define SVG_GROUP_NESTING_MAX           16
#define SVG_XFORM_GSTACK_MAX            16
#define SVG_STYLE_GSTACK_MAX            17
#define SVG_STYLE_APPROX_JOIN_SEG_THRESHOLD 12

#define WWFIXED_ONE ((WWFixedAsDWord)(1UL << 16))
#define GrAddWWFixed(a,b) ((WWFixedAsDWord)((sdword)(a) + (sdword)(b)))
#define GrSubWWFixed(a,b) ((WWFixedAsDWord)((sdword)(a) - (sdword)(b)))

typedef struct {
    Boolean fillSet, strokeSet, swSet;
    char fillVal[64], strokeVal[64];
    WWFixedAsDWord strokeWidth;
    Boolean frSet;
    byte fr;
    Boolean lcSet;
    byte lc;
    Boolean ljSet;
    byte lj;
    Boolean mlSet;
    WWFixedAsDWord miterLimit;
    Boolean colorSet;
    char colorVal[64];
    Boolean visible;
} SvgGroupStyle;

typedef enum {
    SVG_SCRATCH_OK,
    SVG_SCRATCH_ALLOCATION_FAILED,
    SVG_SCRATCH_LIMIT_EXCEEDED
} SvgScratchFailure;

typedef struct {
    byte SNC_r;
    byte SNC_g;
    byte SNC_b;
    char SNC_name[SVG_COLOR_NAME_LEN + 1];
} SvgNamedColor;

typedef struct {
    WWFixedAsDWord x;
    WWFixedAsDWord y;
} SvgWWPoint;

typedef struct {
    WWFixedAsDWord a, b, c, d, e, f;
} SvgMatrix;

typedef struct _SVGScratch {
    MemHandle tagH;
    char *tagP;
    word tagCapacity;
    MemHandle dbH;
    char *dbP;
    word dbCapacity;
    MemHandle ptsH;
    Point *ptsP;
    word ptsCapacity;
    MemHandle ptsWWFH;
    SvgWWPoint *ptsWWFP;
    word ptsWWFCapacity;
    SvgScratchFailure failure;
    Boolean unsupportedElement;
} SVGScratch;

typedef struct {
    MemHandle ioH;
    char *ioP;
    word bytes;
    word pos;
    Boolean inTag;
    Boolean inQuote;
    char quoteCh;
    word tagLen;
} SvgScanCtx;

typedef enum {
    SVG_SCAN_TAG,
    SVG_SCAN_EOF,
    SVG_SCAN_TRUNCATED,
    SVG_SCAN_IO_ERROR,
    SVG_SCAN_NO_INPUT,
    SVG_SCAN_OUT_OF_MEMORY,
    SVG_SCAN_LIMIT_EXCEEDED
} SvgScanResult;

typedef enum {
    SVG_ATTR_MISSING,
    SVG_ATTR_VALID,
    SVG_ATTR_MALFORMED,
    SVG_ATTR_TOO_LONG
} SvgAttrResult;

typedef enum {
    SVG_PAR_ALIGN_MIN,
    SVG_PAR_ALIGN_MID,
    SVG_PAR_ALIGN_MAX
} SvgParAlign;

/* One heap-allocated context makes SvgLib reentrant and keeps stacks small. */
typedef struct {
    GStateHandle gstate;
    SvgRendererState renderer;
    ColorQuad rendererLineColor;
    ColorQuad rendererAreaColor;
    WWFixedAsDWord rendererLineWidth;
    Boolean rendererLineColorDirty;
    Boolean rendererAreaColorDirty;
    Boolean rendererLineWidthDirty;
    Boolean rendererScaleDirty;

    Boolean viewInitialized;
    WWFixedAsDWord viewMinX, viewMinY, viewWidth, viewHeight;
    WWFixedAsDWord viewportWidth, viewportHeight;
    word outputWidth, outputHeight;
    WWFixedAsDWord scaleX, scaleY, addX, addY, inversePowerOfTwo;
    Boolean preserveNone, preserveSlice;
    SvgParAlign preserveX, preserveY;

    MemHandle transformStackH;
    word transformDepth;
    MemHandle styleStackH;
    word styleDepth;
    FileHandle logFile;
    char logBuffer[384];
    char logTime[64];

    char work1[192];
    char work2[96];
    char work3[64];
    char work4[64];
} SvgImportContext;

typedef Boolean _pascal
pcfm_SvgProgressCallback(word percent, void *callback);

const char *SvgParserSkipWS(const char *p);
const char *SvgParserSkipCommaWS(const char *p);
Boolean SvgParserTagIs(const char *tag, const char *name);
Boolean SvgParserGetAttrBounded(const char *tag, const char *name,
                                char *out, word outSize);
SvgAttrResult SvgParserGetAttrSpan(const char *tag, const char *name,
                                   const char **valuePP, word *lengthP,
                                   word maximumBytes);
void SvgParserScanInit(SvgScanCtx *c);
SvgScanResult SvgParserScanNextTag(SvgImportContext *contextP, FileHandle fh,
                                   SvgScanCtx *c, SVGScratch *sc);
Boolean SvgParseGetInlineStyleProp(SvgImportContext *contextP,
                                   const char *tag, const char *prop,
                                   char *out, word outSize);

Boolean SvgScratchInit(SVGScratch *sc);
void SvgScratchFree(SVGScratch *sc);
Boolean SvgScratchEnsureTagCapacity(SVGScratch *sc, word neededBytes);
Boolean SvgScratchEnsurePathBuf(SVGScratch *sc, word neededBytes);
Boolean SvgScratchEnsurePointCapacity(SVGScratch *sc, word neededPoints);
Boolean SvgScratchEnsureWWPointCapacity(SVGScratch *sc, word neededPoints);

Boolean SvgUtilAsciiNoCaseEq(const char *a, const char *b);
word SvgUtilHexNibble(char c);
word SvgUtilHexByte(const char *p);
Boolean SvgUtilExpandShortHex(const char *s, word *r, word *g, word *b);
Boolean SvgUtilParseRGBFunc(const char *s, word *r, word *g, word *b);
Boolean SvgUtilKeyEqNoCase(const char *kb, const char *ke, const char *prop);
const char *SvgUtilParseWWFixed16_16(const char *s, WWFixedAsDWord *out);
Boolean SvgUtilIsNumStart(char c);

WWFixedAsDWord SvgGeomMakeWWFixedFromInt(int v);
sword SvgGeomWWFixedToSWordRound(WWFixedAsDWord w);
WWFixedAsDWord SvgGeomWWSqrt(WWFixedAsDWord a);
WWFixedAsDWord SvgGeomWWAbs(WWFixedAsDWord x);
WWFixedAsDWord SvgGeomWWMin(WWFixedAsDWord a, WWFixedAsDWord b);
WWFixedAsDWord SvgGeomWWMax(WWFixedAsDWord a, WWFixedAsDWord b);
WWFixedAsDWord SvgGeomWWAtan2Deg(WWFixedAsDWord y, WWFixedAsDWord x);

Boolean SvgStyleStackInit(SvgImportContext *contextP);
void SvgStyleStackFree(SvgImportContext *contextP);
void SvgStyleApplyStrokeAndFill(SvgImportContext *contextP, const char *tag);
void SvgStyleApplyStrokeWidth(SvgImportContext *contextP, const char *tag,
                              const SvgMatrix *worldMP);
void SvgStyleApplyFillRule(SvgImportContext *contextP, const char *tag);
void SvgStyleApplyStrokeCapJoin(SvgImportContext *contextP, const char *tag);
Boolean SvgStyleHasStroke(SvgImportContext *contextP, const char *tag);
Boolean SvgStyleHasFill(SvgImportContext *contextP, const char *tag);
Boolean SvgStyleElementIsVisible(SvgImportContext *contextP, const char *tag);
Boolean SvgStyleIsLineJoinExplicit(SvgImportContext *contextP,
                                   const char *tag);
Boolean SvgStyleGroupStrokeWidthGet(SvgImportContext *contextP,
                                    WWFixedAsDWord *outW);
Boolean SvgStyleGroupMiterLimitGet(SvgImportContext *contextP,
                                   WWFixedAsDWord *outLimit);
Boolean SvgStyleForceRoundJoin(SvgImportContext *contextP, const char *tag);
Boolean SvgStyleForceRoundJoinForSegments(SvgImportContext *contextP,
                                          const char *tag, word count);
void SvgStyleRestoreForcedJoin(SvgImportContext *contextP, const char *tag,
                               Boolean forced);
Boolean SvgStyleGroupPush(SvgImportContext *contextP, const char *tag);
void SvgStyleGroupPop(SvgImportContext *contextP);

void SvgViewReset(SvgImportContext *contextP);
Boolean SvgViewInitFromSvgTag(SvgImportContext *contextP, const char *tag);
void SvgViewInitDefault(SvgImportContext *contextP);
void SvgViewGetMatrix(SvgImportContext *contextP,
                      WWFixedAsDWord *a, WWFixedAsDWord *b,
                      WWFixedAsDWord *c, WWFixedAsDWord *d,
                      WWFixedAsDWord *e, WWFixedAsDWord *f);

Boolean SvgXformStackInit(SvgImportContext *contextP);
void SvgXformStackFree(SvgImportContext *contextP);
void SvgXformApplyPoint(sword *xP, sword *yP, const SvgMatrix *m);
Boolean SvgXformParseAttrUser(SvgImportContext *contextP, const char *tag,
                              SvgMatrix *outUser);
Boolean SvgXformBuildWorld(SvgImportContext *contextP, const char *tag,
                           const SvgMatrix *parentCTM, SvgMatrix *outWorld);
Boolean SvgXformGroupPush(SvgImportContext *contextP, const char *tag);
void SvgXformGroupPop(SvgImportContext *contextP);

Boolean SvgShapeHandleLine(SvgImportContext *contextP, const char *tag,
                           SVGScratch *sc);
Boolean SvgShapeHandlePolyline(SvgImportContext *contextP, const char *tag,
                               SVGScratch *sc, Boolean *validP);
Boolean SvgShapeHandlePolygon(SvgImportContext *contextP, const char *tag,
                              SVGScratch *sc, Boolean *validP);
Boolean SvgShapeHandleRect(SvgImportContext *contextP, const char *tag,
                           SVGScratch *sc);
Boolean SvgShapeHandleEllipse(SvgImportContext *contextP, const char *tag,
                              SVGScratch *sc);
Boolean SvgShapeHandleCircle(SvgImportContext *contextP, const char *tag,
                             SVGScratch *sc);
Boolean SvgPathHandle(SvgImportContext *contextP, const char *tag,
                      SVGScratch *sc, Boolean *emittedP);

void SvgRendererInit(SvgImportContext *contextP, GStateHandle gstate);
void SvgRendererInitViewport(SvgImportContext *contextP, sword width,
                             sword height);
word SvgRendererCompactPoints(SvgImportContext *contextP, Point *pointsP,
                              word count);
void SvgRendererSetLineColor(SvgImportContext *contextP, ColorFlag flag,
                             word redOrIndex, word green, word blue);
void SvgRendererSetAreaColor(SvgImportContext *contextP, ColorFlag flag,
                             word redOrIndex, word green, word blue);
void SvgRendererSetFillRule(SvgImportContext *contextP,
                            RegionFillRule fillRule);
void SvgRendererSetLineWidth(SvgImportContext *contextP,
                             WWFixedAsDWord width);
void SvgRendererSetLineJoin(SvgImportContext *contextP, LineJoin join);
void SvgRendererSetLineEnd(SvgImportContext *contextP, LineEnd end);
void SvgRendererSetMiterLimit(SvgImportContext *contextP,
                              WWFixedAsDWord limit);
void SvgRendererLine(SvgImportContext *contextP, sword x1, sword y1,
                     sword x2, sword y2);
void SvgRendererPolyline(SvgImportContext *contextP, Point *pointsP,
                         word count);
void SvgRendererPolygon(SvgImportContext *contextP, Point *pointsP,
                        word count, Boolean fill, Boolean stroke);
void SvgRendererEllipse(SvgImportContext *contextP, sword cx, sword cy,
                        sword rx, sword ry, Boolean fill, Boolean stroke);
void SvgRendererBeginPath(SvgImportContext *contextP);
void SvgRendererEndPath(SvgImportContext *contextP, Boolean fill,
                        Boolean stroke);

TransError SvgImportParse(SvgImportContext *contextP, FileHandle sourceFile,
                          SvgProgressCallback *callback,
                          const volatile Boolean *cancelP);

#endif
