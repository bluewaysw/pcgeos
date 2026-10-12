# WebPImport

The WebP library incrementally imports static lossy WebP images into a 24-bit
complex HugeBitmap.

## Supported input

The decoder accepts one VP8 keyframe in a RIFF/WEBP container. A VP8X chunk is
accepted when it describes the same canvas and does not request alpha or
animation. ICC, EXIF, XMP, and unknown bounded chunks are validated and
ignored. VP8L, alpha, animation, multiple image payloads, and dimensions above
2048 pixels are rejected.

## WebPImportBegin

WebPImportBegin seeks the source to zero, validates the container and VP8
header, allocates decoder storage, and creates a BMC_PACKBITS
BMF_24BIT | BMT_COMPLEX HugeBitmap. It does not decode macroblocks.

The five arguments are source, destination, decoder, bitmap, and info.
The decoder rejects dimensions above 2048 pixels; there is no pixel-count
admission limit.

All output pointers are required and initialized before parsing. On success,
the caller owns the returned bitmap. On failure, the routine releases all
storage and VM chains it created.

The source and destination handles remain caller-owned. The source must remain
open and must not be used concurrently until WebPImportDestroy. Its final file
position is unspecified.

## WebPImportNext

Each call decodes one macroblock row. WEBP_RESULT_OK returns the exact
contiguous finalized range in firstLine and lineCount. The final range is
returned with WEBP_RESULT_OK; the following call returns WEBP_RESULT_DONE and
zero lines. Finalized RGB scanlines are PackBits-compressed as they are
appended to the bitmap.

After a decoding error, the decoder is terminal and later calls return
WEBP_ERROR_BAD_STATE.

## WebPImportDestroy

WebPImportDestroy accepts NullHandle and releases only decoder storage. It
does not close the source or free a bitmap returned by a successful Begin.
Free an unwanted complete or partial bitmap with VMFreeVMChain.

## Integration and provenance

WebpLib, Graphics Viewer, ImpGraph, the translator, and product packaging were
ported from the first-parent patch of 19c0f33f9b7f6ebeaa56788172b1aa3d133c965f
(origin/split/06-WebP-addition), including its earlier decoder work, license,
patent notice, design notes, and host corpus. Decoder input-buffer fixes came
from the Library/WebpLib portion of 5d95b8735bf373be35bb659196618f5f12591546.
Its browser changes and commits 2661c6961 and 4efba94f3 were omitted.

ImpGraph publishes WebP only after decoding succeeds. It disables the import
progress callback so the existing browser final update replaces the entire
image. Failure or cancellation frees the partial bitmap and any watcher
reservation. Existing browser progress/cache and Html4Par code is unchanged.
The current SVG integrations and ImpGraph exports, protocol, and parameter
structures are retained.
