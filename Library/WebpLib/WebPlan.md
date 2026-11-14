# Validated implementation plan: static lossy WebP support

## Summary

Add a small C API library, webplib.lib, and integrate it with ImpGraph so PC/GEOS Ensemble can display static lossy WebP images incrementally.

The decoder will support RIFF/WEBP containers containing a single VP8 keyframe, including VP8X files with ignored ICC, EXIF, and XMP metadata. It will reject VP8L, alpha, and animation deterministically. Container behavior follows [RFC 9649](https://www.rfc-editor.org/rfc/rfc9649.html), and VP8 decoding follows [RFC 6386](https://www.rfc-editor.org/rfc/rfc6386.html).

The design is width-bounded: compressed input is buffered, only one macroblock is retained, reconstructed pixels use rolling row caches, and one RGB row is written directly to a GEOS HugeBitmap. No complete compressed, YUV, or RGB image is allocated in conventional memory.

Repository validation confirmed:

- GrCreateBitmapRaw creates the required BMF_24BIT | BMT_COMPLEX HugeBitmap.
- HugeArrayLock, HugeArrayDirty, and HugeArrayUnlock support direct row output.
- A 24-bit GEOS bitmap row is exactly width times three bytes.
- PNG already establishes the required unlock-before-VM-write pattern.
- FJPEG establishes the existing 2048-pixel practical limit.
- webplib.geo must be added to the Ensemble product file tree, not merely linked from ImpGraph.
- it must also be added to the GEOS.INI template so that its mime type is detected under HTMLView/mimeDrivers and the image forwarded to ImpGraph
- it must also be added to altSrcCacheExts, with the canonical WebP extension for DOS file systems (8.3):
IMAGE.WEBP => IMAGE.WEB

## Steps

Work in two steps:
1) create the needed files and folders first, integrate into ImpGraph and bbxensem.filetree as well as the Installed/Makefile. Create all of the needed function signatures and APIs first. The idea of the first step is to have a compiling but non-functional library. In case the second step should fail, it will be easier for subsequent runs to pick up and complete the work.
2) In the second step, "fill in the blanks", add the funcion bodies and make the library functional.

## Scope and public interface

Version one supports:

- Static RIFF/WEBP files.
- Plain VP8 chunks and VP8X containers containing one VP8 image.
- VP8 keyframes, profiles 0 through 3.
- One, two, four, or eight coefficient partitions.
- Segmentation, skip probabilities, intra 4x4 and 16x16 modes, chroma prediction, inverse transforms, and quantization.
- Disabled, simple, and normal loop filters.
- Centered bilinear chroma upsampling and integer BT.601 YUV-to-RGB conversion.
- ICCP, EXIF, XMP, and bounded unknown chunks skipped without interpreting their contents.

Version one rejects with WEBP_ERROR_UNSUPPORTED:

- VP8L lossless data.
- ALPH chunks or a VP8X alpha flag.
- ANIM, ANMF, or a VP8X animation flag.
- Multiple image payloads.
- Encoding, cropping, scaling, and color-profile application.

Limits are 2048 pixels in either dimension and 6144 RGB bytes per row. Every allocation must be smaller than 32 KB.

Expose the incremental API needed by ImpGraph. Also add a convenience whole-file conversion function that uses the incremental API under the hood (as seen in the PNG Library) that could later be used in Graphics Viewer or an Impex module.

```c
typedef MemHandle WebPImportHandle;

typedef enum {
    WEBP_RESULT_OK = 0,
    WEBP_RESULT_DONE,
    WEBP_ERROR_WRONG_FORMAT,
    WEBP_ERROR_UNSUPPORTED,
    WEBP_ERROR_CORRUPT,
    WEBP_ERROR_READ,
    WEBP_ERROR_OUT_OF_MEMORY,
    WEBP_ERROR_IMAGE_TOO_LARGE,
    WEBP_ERROR_BAD_STATE
} WebPResult;

typedef struct {
    word width;
    word height;
} WebPImageInfo;

WebPResult _pascal _export
WebPImportBegin(
    FileHandle source,
    VMFileHandle destination,
    WebPImportHandle *decoder,
    VMBlockHandle *bitmap,
    WebPImageInfo *info
);

WebPResult _pascal _export
WebPImportNext(
    WebPImportHandle decoder,
    word *firstLine,
    word *lineCount
);

void _pascal _export
WebPImportDestroy(WebPImportHandle decoder);
```

API behavior:

- Begin requires all output pointers, initializes their handles to NullHandle, seeks the source to zero, validates the container and VP8 header, allocates decoder storage, and creates the raw HugeBitmap. It does not decode macroblocks.
- A failed Begin releases every allocation and VM chain created internally.
- Next initializes lineCount to zero, decodes exactly one macroblock row, and returns OK with one contiguous finalized line range. The last row is also returned as OK; the following call returns DONE with zero lines.
- A decoding error makes the decoder terminal. Later Next calls return BAD_STATE.
- No memory handle remains locked when a public function returns.
- Destroy is safe for NullHandle and frees decoder storage only. It never closes the caller-owned source or frees a bitmap returned by a successful Begin.
- After successful Begin, the caller owns the bitmap and must free an unwanted partial bitmap with VMFreeVMChain.
- The source handle must remain open and must not be used concurrently until decoding is destroyed. Its final file position is unspecified.

Document this ownership contract in CInclude/webplib.h and TechDocs/Markdown/Routines/WebPImport.md.

## Decoder implementation

Create Library/WebpLib with webplib.gp, local.mk, webplib.rev, webpint.h, and five focused C modules:

- webpapi.c: exported state machine, allocation, cleanup, bitmap creation, and HugeArray output.
- webpriff.c: RIFF, VP8X, chunk, and uncompressed VP8 frame-header parsing.
- webpbit.c: buffered reads, Boolean arithmetic decoding, and token-partition switching.
- webpvp8.c: frame probabilities, modes, coefficients, macroblock reconstruction, and row control.
- webpdsp.c: prediction, transforms, filters, chroma upsampling, and RGB conversion.

Build webplib.lib as a single C API library depending only on geos and ansic. Use XCCOMFLAGS += -zu. Export the three incremental entry points and use tokenchars "WEBP".

Use the lossy portion of the [pinned SimpleWebP source at commit d1a728a1f8ec7348ca2a5039b6dd813b83986fbb](https://github.com/MikuAuahDark/simplewebp/blob/d1a728a1f8ec7348ca2a5039b6dd813b83986fbb/simplewebp.h) as the initial behavioral donor. Preserve its BSD license and patent grant in dedicated license files and identify derived code in each affected source header. Do not import its allocator, stdio, full-image output, VP8L, alpha, or animation code.

### Container validation

- Require RIFF, a checked 32-bit RIFF size, and WEBP.
- Require the RIFF extent to fit within FileSize. Ignore bytes after the declared RIFF extent.
- Walk chunks using checked dword addition. Reject any header, payload, or padding byte outside the RIFF extent.
- Verify the mandatory zero padding byte after odd-sized chunks.
- Require VP8X to be the first chunk when present and its payload to be exactly 10 bytes.
- Reject alpha or animation immediately from VP8X flags or corresponding chunks.
- Permit ICCP only before image data; permit EXIF, XMP, and unknown chunks after validating their bounds.
- Require metadata-presence flags to agree with encountered standard metadata chunks.
- Require exactly one VP8 payload. VP8L is unsupported; duplicate VP8 payloads are corrupt.
- Validate the VP8 keyframe marker, show-frame bit, start code, profile, first-partition length, dimensions, and reserved color-space value.
- Ignore VP8 scaling hints and output the encoded dimensions.
- For VP8X, require canvas dimensions to equal the VP8 keyframe dimensions.
- Reject zero dimensions or dimensions above 2048 before allocating width-dependent buffers.

### Streaming Boolean readers

Use one 4096-byte swappable input handle divided into independent 2048-byte mode and token windows.

Each logical reader stores only offsets and arithmetic state:

- Partition start and length.
- Absolute position of the next unread byte.
- Boolean-decoder value, range, bit count, and EOF state.

Do not retain pointers after unlocking the input handle.

The mode reader is bounded to the first partition. After the mode header reveals the token-partition count, read and validate the three-byte partition-size table. Reject an oversized declared partition instead of clamping it. The final partition consumes the checked remainder.

All token partitions retain their logical arithmetic state, but only the active partition occupies the token window. Switching at each macroblock row saves the active absolute byte position and refills the selected partition without crossing its boundary.

### Memory layout

Use one fixed, zero-initialized state handle. Embed the current macroblock coefficients, probability tables, quantizers, Boolean-reader states, and constant-sized reconstruction scratch in it.

Use swappable handles for:

- The combined mode/token input windows.
- A context block containing top intra modes, top reconstructed samples, nonzero contexts, and per-column filter information.
- A luma rolling cache.
- A combined U/V rolling cache.
- One RGB output row.

Combining only the proven-small buffers reduces scarce handle use without risking segment overflow. At width 2048:

- The context block remains below 6 KB.
- The largest luma cache is 2048 times 24, or 49152 bytes.
- The combined normal-filter chroma cache is 2 times 1024 times 12, or 24576 bytes.
- The RGB row is 6144 bytes.

Calculate every size as dword, check overflow and the 65536-byte ceiling, then cast to word for MemAlloc. Use HAF_ZERO_INIT and never malloc or free.

### Macroblock-row processing

For each Next call:

1. Select the coefficient partition using mbY modulo the partition count.
2. Reset left mode and coefficient contexts.
3. For each macroblock, read mode data, decode coefficients, reconstruct luma and chroma immediately, update top and left contexts, and store only its filter strength.
4. Filter the completed macroblock row.
5. Convert and write every newly finalized scanline.
6. Rotate the retained cache rows and advance mbY.

Do not allocate the donor's width-sized macroblock-data array.

Use an output delay of max(filterExtraRows, 2). The additional two-line delay is mandatory when filtering is disabled because centered chroma upsampling of the last luma pair requires the next chroma row. The resulting delays are:

- Filter disabled: 2 luma rows.
- Simple filter: 2 luma rows.
- Normal filter: 8 luma rows.

Clamp top, bottom, left, right, and odd-size chroma references. Port the donor's centered bilinear chroma calculation and integer RGB conversion rather than using nearest-neighbor chroma.

For each output line, build width times three RGB bytes, temporarily unlock movable decoder buffers, lock the corresponding HugeArray element, require its size to equal rowBytes, copy, dirty, and unlock it, then reacquire decoder pointers. Never retain a pointer across an unlock.

## ImpGraph and product integration

Add an ImpGraph WebP wrapper modeled on PngImport and include webplib in impgraph.gp.

The wrapper will:

- Open the source and call WebPImportBegin.
- Set IAD dimensions from WebPImageInfo.
- Reserve width times height times three bytes with AllocWatcherAllocate using checked dword arithmetic.
- Call WebPImportNext until DONE, error, or MIME_STATUS_ABORT.
- Publish the exact firstLine through firstLine + lineCount - 1 range after every successful slice.
- Set IAD_completeGraphic only after DONE.
- Set isCompacted to FALSE so the existing caller may use GrCompactBitmap.
- Always destroy the decoder and close the source.
- Free the watcher reservation and partial VM chain unless progress-callback ownership has already transferred the bitmap.
- Preserve a published partial image on abort, mark it incomplete, and return IBS_IMPORT_STOPPED.

Map results as follows:

- Wrong format: IBS_UNKNOWN_FORMAT, permitting MIME fallback.
- Out of memory: IBS_NO_MEMORY.
- User abort: IBS_IMPORT_STOPPED.
- Corrupt, unsupported, read failure, or oversized image: IBS_WRONG_FILE.
- Bad internal state: IBS_SYS_ERROR.

Register image/webp with extension WEBP in MimeDrvInfo. Add WebP as the last probe for declared GIF, JPEG, and PNG content. For declared WebP, try JPEG, PNG, and GIF only when WebP returns WRONG_FORMAT; do not hide a recognized but unsupported or corrupt WebP behind fallback probing.

Add Library/WebpLib/webplib{ec}.geo to Tools/build/product/bbxensem/bbxensem.filetree alongside pnglib so the linked ImpGraph dependency is present in Ensemble images.

## Test and delivery sequence

1. Add the library skeleton, public header, revision file, licensing, and API documentation; build normal and EC variants.
2. Implement RIFF/VP8X and frame-header parsing with a small host-side test covering valid, truncated, overflowed, padded, duplicate, and unsupported containers.
3. Implement buffered Boolean readers and partition switching; compare randomized bit sequences and states against the pinned donor, including refill boundaries at 2047, 2048, and 2049 bytes.
4. Port mode, probability, coefficient, prediction, transform, and quantizer logic; validate every decoded table index before lookup.
5. Add loop filtering, delayed centered chroma upsampling, RGB conversion, and direct HugeBitmap output.
6. Integrate ImpGraph, MIME dispatch, progress, abort, ownership, compaction, and the Ensemble product file tree.
7. Run corruption, allocation-failure, EC, and SWAT leak testing before enabling WebP in the product build.

The decode corpus must cover:

- Plain VP8 and VP8X with ICCP, EXIF, XMP, and bounded unknown chunks.
- Widths and heights 1, 15, 16, 17, 31, 32, 2047, 2048, plus rejection at 2049.
- Profiles 0 through 3 and one, two, four, and eight token partitions.
- Segmentation and skip probabilities enabled and disabled.
- Filter disabled, simple filter, and normal filter.
- Odd dimensions and single-row/single-column images.
- Truncation at every container, partition-table, mode-partition, and token-partition boundary.
- VP8L, alpha, and animation returning UNSUPPORTED without leaked handles.
- Abort after each possible macroblock row, both before and after a progress callback publishes the bitmap.
- Injected failure at every MemAlloc, GrCreateBitmapRaw, HugeArrayLock, FilePos, and FileRead boundary.

For valid images, compare dimensions and RGB output against desktop libwebp. Require no shifted or uninitialized pixels, no macroblock-row seams, and a maximum per-channel difference of two. Separately compare Boolean-reader state and VP8 reconstructed samples exactly with the pinned donor where a host harness can observe them.

Build from the matching Installed directories:

- Run mkmf, pmake depend, and pmake -L 4 full for the new WebpLib geode.
- Regenerate ImpGraph dependencies and build its normal and FJPEG product variants.
- Check git diff --ignore-space-at-eol for intentional changes only.
- Verify BbxBrow displays ordinary static photographic WebP images, progressively publishes rows, still imports mislabeled JPEG/PNG/GIF files, and loads webplib.geo from the assembled Ensemble tree.

## Acceptance criteria and assumptions

The work is complete when:

- Peak conventional-memory use is proportional to width, not height.
- No full compressed stream or complete YUV/RGB image is allocated.
- Every individual allocation is below 64 KB, including at width 2048.
- Each successful Next call performs one macroblock row and returns a precise contiguous output range.
- Centered chroma conversion remains correct with filtering disabled and at odd image edges.
- Unsupported variants fail deterministically before large decoder buffers are allocated.
- All failure and abort paths leave no locked or leaked handles and no orphaned VM chains.
- Output stays within the two-level RGB tolerance against libwebp.
- ImpGraph progress and partial-image ownership match existing MIME-driver conventions.
- webplib.geo is present in the Ensemble product image and BbxBrow displays supported WebP content.

Defaults chosen for version one:

- Only Begin, Next, and Destroy are public; unused probe and convenience exports are deferred.
- Metadata is validated and ignored, not applied or returned.
- Output is always a PackBits-compacted 24-bit complex bitmap.
- SimpleWebP commit d1a728a1f8ec7348ca2a5039b6dd813b83986fbb is the pinned donor baseline.
- VP8L, alpha, animation, scaling, cropping, and encoding remain separate future projects.
