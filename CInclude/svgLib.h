#ifndef __SVG_LIB_H
#define __SVG_LIB_H

#include <graphics.h>
#include <vm.h>
#include <xlatLib.h>

typedef Boolean _pascal SvgProgressCallback(word percent);

TransError _export _pascal
SvgImport(FileHandle sourceFile,
          VMFileHandle destinationFile,
          VMChain *resultChainP,
          /* SVG viewport in generated GString coordinates, if requested. */
          RectDWord *boundsP,
          SvgProgressCallback *callback,
          /* Optional live flag: nonzero cancels between tags.
           * Keep storage valid and cancellation set until return.
           * Cancellation frees partial output and returns TE_ERROR. */
          const volatile Boolean *cancelP);

TransError _export _pascal
SvgExport(FileHandle outputFile,
          VMFileHandle sourceFile,
          VMChain sourceChain);

Boolean _export _pascal
SvgCheckHeader(FileHandle sourceFile);

#endif
