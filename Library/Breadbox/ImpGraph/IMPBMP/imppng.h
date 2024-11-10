#ifndef __IMPPNG_H
#define __IMPPNG_H

#include <geos.h>
#include <graphics.h>
#include <gstring.h>
#include <pnglib.goh>
#include "IMPBMP/ibcommon.h"
#include <htmldrv.h>
#include <Ansi/stdlib.h>


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
