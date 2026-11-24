#include "svgRendererCore.h"

void
SvgRendererCoreInit(SvgRendererState *stateP, SvgRendererWord windingRule)
{
    stateP->fillRule = windingRule;
    stateP->pathDepth = 0;
    stateP->coordinateDivisor = 1;
    stateP->worldMinX = -32768;
    stateP->worldMinY = -32768;
    stateP->worldMaxX = 32767;
    stateP->worldMaxY = 32767;
}

SvgRendererWord
SvgRendererCoreChooseDivisor(SvgRendererSWord width,
                             SvgRendererSWord height)
{
    long maximum;
    long value;

    maximum = width;
    if (maximum < 0) maximum = -maximum;
    value = height;
    if (value < 0) value = -value;
    if (value > maximum) maximum = value;
    return (maximum > 16383L) ? 4 : ((maximum > 8191L) ? 2 : 1);
}

SvgRendererSWord
SvgRendererCoreCoordinate(const SvgRendererState *stateP,
                          SvgRendererSWord value,
                          SvgRendererSWord worldMinimum,
                          SvgRendererSWord worldMaximum)
{
    /* Repair positive coordinates that wrapped into the negative sword
       range, matching the old Meta renderer. */
    if (value < worldMinimum &&
        (long)worldMinimum - (long)value > 24576L)
    {
        value = worldMaximum;
    }
    return (SvgRendererSWord)(value /
                              (SvgRendererSWord)stateP->coordinateDivisor);
}

SvgRendererWord
SvgRendererCoreCompact(SvgRendererPoint *pointsP, SvgRendererWord count,
                       const SvgRendererState *stateP)
{
    SvgRendererWord source;
    SvgRendererWord destination;
    SvgRendererSWord x;
    SvgRendererSWord y;

    destination = 0;
    for (source = 0; source < count; source++)
    {
        x = SvgRendererCoreCoordinate(stateP, pointsP[source].x,
                                      stateP->worldMinX,
                                      stateP->worldMaxX);
        y = SvgRendererCoreCoordinate(stateP, pointsP[source].y,
                                      stateP->worldMinY,
                                      stateP->worldMaxY);
        if (destination == 0 || pointsP[destination - 1].x != x ||
            pointsP[destination - 1].y != y)
        {
            pointsP[destination].x = x;
            pointsP[destination].y = y;
            destination++;
        }
    }
    return destination;
}

void
SvgRendererCoreSetFillRule(SvgRendererState *stateP,
                           SvgRendererWord fillRule)
{
    stateP->fillRule = fillRule;
}

int
SvgRendererCoreBeginPath(SvgRendererState *stateP)
{
    stateP->pathDepth++;
    return stateP->pathDepth == 1;
}

int
SvgRendererCoreEndPath(SvgRendererState *stateP)
{
    if (stateP->pathDepth == 0) return 0;
    stateP->pathDepth--;
    return stateP->pathDepth == 0;
}
