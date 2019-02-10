#ifndef __IMP_BMP_H
#define __IMP_BMP_H

#include <geos.h>
#include "IMPBMP/ibcommon.h"

ImpBmpStatus _pascal Imp_BmpProcessFile(ImpBmpParams *params,
												ImpBmpFormat format);

ImpBmpFormat _pascal Imp_BmpTestFile(FileHandle file);

#endif
