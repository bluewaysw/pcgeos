#include <assert.h>
#include <stdio.h>

#include "../svgRendererCore.h"

int
main(void)
{
    SvgRendererState state;
    SvgRendererPoint points[] = {
        { 0, 0 }, { 1, 1 }, { 2, 2 }, { 2, 2 }, { 8, 4 }
    };
    SvgRendererPoint polygonLoop[] = {
        { 0, 0 }, { 8, 0 }, { 8, 8 }, { 0, 0 }
    };
    SvgRendererPoint wrapped[] = {
        { (SvgRendererSWord)-30000, (SvgRendererSWord)-30000 }
    };
    SvgRendererWord count;

    assert(SvgRendererCoreChooseDivisor(8191, 0) == 1);
    assert(SvgRendererCoreChooseDivisor(8192, 0) == 2);
    assert(SvgRendererCoreChooseDivisor(16383, 0) == 2);
    assert(SvgRendererCoreChooseDivisor(16384, 0) == 4);

    SvgRendererCoreInit(&state, 7);
    state.coordinateDivisor = 2;
    state.worldMinX = 0;
    state.worldMinY = 0;
    state.worldMaxX = 16000;
    state.worldMaxY = 12000;

    count = SvgRendererCoreCompact(points, 5, &state);
    assert(count == 3);
    assert(points[0].x == 0 && points[0].y == 0);
    assert(points[1].x == 1 && points[1].y == 1);
    assert(points[2].x == 4 && points[2].y == 2);

    count = SvgRendererCoreCompact(polygonLoop, 4, &state);
    assert(count == 4);

    count = SvgRendererCoreCompact(wrapped, 1, &state);
    assert(count == 1);
    assert(wrapped[0].x == 8000 && wrapped[0].y == 6000);
    assert(SvgRendererCoreCoordinate(&state, -24576, state.worldMinX,
                                     state.worldMaxX) == -12288);
    assert(SvgRendererCoreCoordinate(&state, -24577, state.worldMinX,
                                     state.worldMaxX) == 8000);
    state.worldMinX = -1000;
    assert(SvgRendererCoreCoordinate(&state, -25576, state.worldMinX,
                                     state.worldMaxX) == -12788);
    assert(SvgRendererCoreCoordinate(&state, -25577, state.worldMinX,
                                     state.worldMaxX) == 8000);

    assert(state.fillRule == 7);
    SvgRendererCoreSetFillRule(&state, 9);
    assert(state.fillRule == 9);
    assert(SvgRendererCoreBeginPath(&state));
    assert(!SvgRendererCoreBeginPath(&state));
    assert(!SvgRendererCoreEndPath(&state));
    assert(SvgRendererCoreEndPath(&state));
    assert(!SvgRendererCoreEndPath(&state));

    puts("svgrenderer_test: ok");
    return 0;
}
