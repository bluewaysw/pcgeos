#include "../svgCapacity.h"

static int
Expect(unsigned long currentCapacity, unsigned long neededUnits,
       unsigned long initialCapacity, unsigned long maximumCapacity,
       unsigned long unitSize, SvgCapacityResult expected,
       unsigned long expectedCapacity, unsigned long expectedBytes)
{
    unsigned long capacity;
    unsigned long bytes;
    SvgCapacityResult result;

    capacity = 0;
    bytes = 0;
    result = SvgCapacityPlan(currentCapacity, neededUnits, initialCapacity,
                             maximumCapacity, unitSize, 65535UL,
                             &capacity, &bytes);
    return result == expected &&
           (result != SVG_CAPACITY_GROW ||
            (capacity == expectedCapacity && bytes == expectedBytes &&
             bytes != 0));
}

int
main(void)
{
    return !(
        Expect(128, 128, 128, 4096, 8, SVG_CAPACITY_NO_GROWTH, 0, 0) &&
        Expect(128, 129, 128, 4096, 8, SVG_CAPACITY_GROW, 256, 2048) &&
        Expect(128, 4096, 128, 4096, 8, SVG_CAPACITY_GROW, 4096, 32768) &&
        Expect(0, 4097, 128, 4096, 8, SVG_CAPACITY_LIMIT, 0, 0) &&
        Expect(8192, 8192, 1024, 8192, 1,
               SVG_CAPACITY_NO_GROWTH, 0, 0) &&
        Expect(0, 8193, 1024, 8192, 1, SVG_CAPACITY_LIMIT, 0, 0) &&
        Expect(0, 1, 1, 1, 65536UL, SVG_CAPACITY_LIMIT, 0, 0));
}
