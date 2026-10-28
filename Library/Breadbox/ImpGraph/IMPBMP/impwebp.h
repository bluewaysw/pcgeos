#ifndef __IMPWEBP_H
#define __IMPWEBP_H

#include "IMPBMP/ibcommon.h"
#include <webplib.h>

#if PROGRESS_DISPLAY
ImpBmpStatus _pascal ImpWebP(TCHAR *file, VMFileHandle vmf,
                     ImageAdditionalData *iad, AllocWatcherHandle watcher,
                     dword *usedMem, ImpBmpParams *params,
                     Boolean *isCompacted, VMBlockHandle *bitmap,
                     ImportProgressData *importProgressDataP,
                     MimeStatus *mimeStatus);
#else
ImpBmpStatus _pascal ImpWebP(TCHAR *file, VMFileHandle vmf,
                     ImageAdditionalData *iad, AllocWatcherHandle watcher,
                     dword *usedMem, ImpBmpParams *params,
                     Boolean *isCompacted, VMBlockHandle *bitmap,
                     MimeStatus *mimeStatus);
#endif

#endif
