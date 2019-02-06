#ifndef __IMPJPEG_H
#define __IMPJPEG_H

#include <product.h>
#include <geos.h>
#include <vm.h>
#include "IMPBMP/ibcommon.h"
#include <htmldrv.h>

VMBlockHandle
JpegImport(TCHAR *file,
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

VMBlockHandle
FJpegImport(TCHAR *file,
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
