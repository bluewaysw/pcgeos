#ifndef __SVG_RENDERER_CORE_H
#define __SVG_RENDERER_CORE_H

typedef unsigned short SvgRendererWord;
typedef signed short SvgRendererSWord;

typedef struct {
    SvgRendererSWord x;
    SvgRendererSWord y;
} SvgRendererPoint;

typedef struct {
    SvgRendererWord fillRule;
    SvgRendererWord pathDepth;
    SvgRendererWord coordinateDivisor;
    SvgRendererSWord worldMinX;
    SvgRendererSWord worldMinY;
    SvgRendererSWord worldMaxX;
    SvgRendererSWord worldMaxY;
} SvgRendererState;

void SvgRendererCoreInit(SvgRendererState *stateP,
                         SvgRendererWord windingRule);
SvgRendererWord SvgRendererCoreChooseDivisor(SvgRendererSWord width,
                                              SvgRendererSWord height);
SvgRendererSWord SvgRendererCoreCoordinate(const SvgRendererState *stateP,
                                            SvgRendererSWord value,
                                            SvgRendererSWord worldMinimum,
                                            SvgRendererSWord worldMaximum);
SvgRendererWord SvgRendererCoreCompact(SvgRendererPoint *pointsP,
                                       SvgRendererWord count,
                                       const SvgRendererState *stateP);
void SvgRendererCoreSetFillRule(SvgRendererState *stateP,
                                SvgRendererWord fillRule);
int SvgRendererCoreBeginPath(SvgRendererState *stateP);
int SvgRendererCoreEndPath(SvgRendererState *stateP);

#endif
