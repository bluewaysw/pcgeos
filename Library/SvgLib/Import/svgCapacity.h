#ifndef SVG_CAPACITY_H
#define SVG_CAPACITY_H

typedef enum {
    SVG_CAPACITY_NO_GROWTH,
    SVG_CAPACITY_GROW,
    SVG_CAPACITY_LIMIT
} SvgCapacityResult;

SvgCapacityResult SvgCapacityPlan(unsigned long currentCapacity,
                                  unsigned long neededUnits,
                                  unsigned long initialCapacity,
                                  unsigned long maximumCapacity,
                                  unsigned long unitSize,
                                  unsigned long maximumBytes,
                                  unsigned long *capacityP,
                                  unsigned long *bytesP);

#endif
