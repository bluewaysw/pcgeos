#ifndef __IMPPNG_H
#define __IMPPNG_H

#include "IMPBMP/ibcommon.h"
#include <pnglib.goh>

VMBlockHandle
PngImport(
    TCHAR *file,
    VMFileHandle vmf,
    XYSize *picsize,
    MimeRes resolution,
    AllocWatcherHandle watcher,
    dword *usedMem, 
#if SCANLINE_COMPRESS
    Boolean scanlineCompress, 
#endif
    Boolean *p_completeGraphic
#if PROGRESS_DISPLAY
    , _ImportProgressParams_
#endif  
    , MimeStatus *mimeStatus
);

#endif
