#include <assert.h>
#include <stdio.h>

#define WEBP_HOST_TEST
#include "../webpbit.c"
#include "../webpriff.c"
#include "../webpdsp.c"
#include "../webpvp8.c"
#include "../webpapi.c"

/* Exercise the actual MIME importer with host file/watcher/progress stubs. */
#ifndef PROGRESS_DISPLAY
#define PROGRESS_DISPLAY 1
#endif
#define FILE_ACCESS_R 0
#define FILE_DENY_W 0
#define MIME_STATUS_ABORT 1
#define VMCHAIN_MAKE_FROM_VM_BLOCK(bitmapH) (bitmapH)
typedef char TCHAR;
typedef word AllocWatcherHandle;
typedef struct { word XYS_width, XYS_height; } XYSize;
typedef struct { XYSize IAD_size; Boolean IAD_completeGraphic; }
    ImageAdditionalData;
typedef struct { VMBlockHandle IBP_bitmap; } ImpBmpParams;
typedef struct { void *IPD_callback; } ImportProgressData;
typedef struct { word MS_mimeFlags; } MimeStatus;
typedef enum {
    IBS_NO_ERROR, IBS_UNKNOWN_FORMAT, IBS_SYS_ERROR, IBS_WRONG_FILE,
    IBS_NO_MEMORY, IBS_IMPORT_STOPPED
} ImpBmpStatus;

static TestFile *hostSourceP;
static dword hostReserved;
static Boolean hostReserveAllowed;
static MimeStatus hostMimeStatus;
static WebPResult hostNextError;
static Boolean hostCancelAfterRow;
static word hostCloseCount;

#define FileOpen(file, flags) ((void)(file), (void)(flags), hostSourceP)
#define FileClose(file, flags) \
    ((void)(file), (void)(flags), hostCloseCount++)

static Boolean
AllocWatcherAllocate(AllocWatcherHandle watcherH, dword amount)
{
    (void)watcherH;
    if (!hostReserveAllowed) {
        return FALSE;
    }
    hostReserved += amount;
    return TRUE;
}

static void
AllocWatcherFree(AllocWatcherHandle watcherH, dword amount)
{
    (void)watcherH;
    assert(hostReserved >= amount);
    hostReserved -= amount;
}

static void
VMFreeVMChain(VMFileHandle fileH, VMBlockHandle bitmapH)
{
    (void)fileH;
    free(bitmapH->pixelsP);
    free(bitmapH);
}

static WebPResult
HostImportNext(WebPImportHandle decoderH, word *firstLineP, word *lineCountP)
{
    WebPResult result;

    result = WebPImportNext(decoderH, firstLineP, lineCountP);
    if (hostCancelAfterRow) {
        hostMimeStatus.MS_mimeFlags |= MIME_STATUS_ABORT;
    }
    return hostNextError != WEBP_RESULT_OK ? hostNextError : result;
}

#define WebPImportNext HostImportNext
#include "../../Breadbox/ImpGraph/IMPBMP/impwebp.goc"
#undef WebPImportNext

static void
TestFinalImport(TestFile *sourceP)
{
    ImageAdditionalData iad;
    ImpBmpParams params;
    ImportProgressData progress;
    Boolean compacted;
    VMBlockHandle bitmapH;
    dword usedMem;
    ImpBmpStatus status;
    word test;

    hostSourceP = sourceP;
    for (test = 0; test < 7; test++) {
        memset(&iad, 0, sizeof(iad));
        memset(&params, 0, sizeof(params));
        progress.IPD_callback = &progress;
        hostCloseCount = 0;
        hostReserveAllowed = test != 1;
        hostMimeStatus.MS_mimeFlags = test == 2 ? MIME_STATUS_ABORT : 0;
        hostCancelAfterRow = test == 3;
        hostNextError = test == 4 ? WEBP_ERROR_CORRUPT : WEBP_RESULT_OK;
        if (test == 5) {
            sourceP->size--;
        }
        if (test == 6) {
            ((byte *)sourceP->dataP)[0] = 'X';
        }
        status = ImpWebP((TCHAR *)0, (void *)0, &iad, 0, &usedMem,
                          &params, &compacted, &bitmapH,
#if PROGRESS_DISPLAY
                          &progress,
#endif
                          &hostMimeStatus);
        assert(hostMemoryBlocks == 0 && hostCloseCount == 1);
        if (test == 0) {
            assert(status == IBS_NO_ERROR && bitmapH != NullHandle);
            assert(iad.IAD_completeGraphic && compacted);
            assert(bitmapH == params.IBP_bitmap);
            assert(bitmapH->nextLine == iad.IAD_size.XYS_height);
            assert(progress.IPD_callback ==
                   (PROGRESS_DISPLAY ? (void *)0 : &progress));
            assert(usedMem == (dword)iad.IAD_size.XYS_width *
                               iad.IAD_size.XYS_height * 3);
            assert(hostReserved == usedMem);
            VMFreeVMChain((void *)0, bitmapH);
            AllocWatcherFree(0, usedMem);
        } else {
            assert(status == (test == 1 ? IBS_NO_MEMORY :
                              test == 2 || test == 3 ? IBS_IMPORT_STOPPED :
                              test == 6 ? IBS_UNKNOWN_FORMAT : IBS_WRONG_FILE));
            assert(bitmapH == NullHandle && params.IBP_bitmap == NullHandle);
            assert(!iad.IAD_completeGraphic && usedMem == 0);
            assert(progress.IPD_callback == &progress);
        }
        assert(hostReserved == 0);
        if (test == 5) {
            sourceP->size++;
        }
        if (test == 6) {
            ((byte *)sourceP->dataP)[0] = 'R';
        }
    }
}

static void
FillPackBitsInput(byte *dataP, word size, word pattern)
{
    word index;

    for (index = 0; index < size; index++) {
        if (pattern == 0) {
            dataP[index] = (byte)(index * 37 + index / 127);
        } else if (pattern == 1) {
            dataP[index] = (byte)((index / 3) * 29);
        } else if (index % 17 < 5) {
            dataP[index] = (byte)(index / 17);
        } else {
            dataP[index] = (byte)(index * 53 + index / 11);
        }
    }
}

static void
TestOverlappingPackBits(void)
{
    static const word sizes[] = {
        1, 2, 3, 4, 126, 127, 128, 129, 130,
        255, 256, 257, WEBP_MAX_DIMENSION * 3
    };
    byte *expectedP;
    byte *separateP;
    byte *overlapAllocationP;
    byte *overlapP;
    byte *decodedP;
    HostBitmap bitmap;
    word size;
    word gap;
    word separateSize;
    word overlapSize;
    word pattern;
    word test;

    size = WEBP_MAX_DIMENSION * 3;
    gap = WEBP_PACKBITS_GAP(size);
    expectedP = (byte *)malloc(size);
    separateP = (byte *)malloc(size + gap);
    overlapAllocationP = (byte *)malloc(size + gap + 2);
    decodedP = (byte *)malloc(size);
    assert(expectedP != (void *)0);
    assert(separateP != (void *)0);
    assert(overlapAllocationP != (void *)0);
    assert(decodedP != (void *)0);
    overlapP = overlapAllocationP + 1;

    for (pattern = 0; pattern < 3; pattern++) {
        for (test = 0; test < sizeof(sizes) / sizeof(sizes[0]); test++) {
            size = sizes[test];
            gap = WEBP_PACKBITS_GAP(size);
            FillPackBitsInput(expectedP, size, pattern);
            separateSize = WebPPackBits(separateP, expectedP, size);

            memset(overlapAllocationP, 0xa5, size + gap + 2);
            memcpy(overlapP + gap, expectedP, size);
            overlapSize = WebPPackBits(overlapP, overlapP + gap, size);
            assert(overlapSize == separateSize);
            assert(overlapSize <= size + ((size + 127) >> 7));
            assert(memcmp(overlapP, separateP, overlapSize) == 0);
            assert(overlapP[-1] == 0xa5);
            assert(overlapP[size + gap] == 0xa5);

            memset(&bitmap, 0, sizeof(bitmap));
            memset(decodedP, 0, size);
            bitmap.height = 1;
            bitmap.rowBytes = size;
            bitmap.pixelsP = decodedP;
            assert(HugeArrayAppend((void *)0, &bitmap, overlapSize,
                                   overlapP) == 0);
            assert(memcmp(decodedP, expectedP, size) == 0);
        }
    }

    free(decodedP);
    free(overlapAllocationP);
    free(separateP);
    free(expectedP);
}

/* Fail each decoder allocation and discard a partial decode as on Stop. */
static void
TestDecoderCleanup(TestFile *sourceP)
{
    WebPImportHandle decoderH;
    VMBlockHandle bitmapH;
    WebPImageInfo info;
    WebPResult result;
    word firstLine;
    word lineCount;
    int failAfter;

    for (failAfter = 0; ; failAfter++) {
        hostFailAfter = failAfter;
        result = WebPImportBegin(sourceP, (void *)0, &decoderH,
                                 &bitmapH, &info);
        hostFailAfter = -1;
        if (result == WEBP_RESULT_OK) {
            result = WebPImportNext(decoderH, &firstLine, &lineCount);
            assert(result == WEBP_RESULT_OK);
            assert(((WebPDecoder *)MemLock(decoderH))->inputP == (void *)0);
            WebPImportDestroy(decoderH);
            free(bitmapH->pixelsP);
            free(bitmapH);
            assert(hostMemoryBlocks == 0);
            break;
        }
        assert(result == WEBP_ERROR_OUT_OF_MEMORY);
        assert(decoderH == NullHandle && bitmapH == NullHandle);
        assert(hostMemoryBlocks == 0);
    }

    /* A short container must fail Begin without leaking its decoder block. */
    sourceP->size--;
    result = WebPImportBegin(sourceP, (void *)0, &decoderH, &bitmapH, &info);
    assert(result == WEBP_ERROR_CORRUPT);
    assert(decoderH == NullHandle && bitmapH == NullHandle);
    assert(hostMemoryBlocks == 0);
    sourceP->size++;
}

int
main(int argc, char **argv)
{
    FILE *inputP;
    FILE *outputP;
    byte *dataP;
    long size;
    TestFile source;
    WebPImportHandle decoder;
    VMBlockHandle bitmap;
    WebPImageInfo info;
    WebPResult result;
    word firstLine;
    word lineCount;
    word expectedLine;

    if (argc != 3) {
        fprintf(stderr, "usage: webpdecode_test input.webp output.rgb\n");
        return 2;
    }
    TestOverlappingPackBits();
    inputP = fopen(argv[1], "rb");
    assert(inputP != (void *)0);
    assert(fseek(inputP, 0, SEEK_END) == 0);
    size = ftell(inputP);
    assert(size > 0);
    assert(fseek(inputP, 0, SEEK_SET) == 0);
    dataP = (byte *)malloc((size_t)size);
    assert(dataP != (void *)0);
    assert(fread(dataP, 1, (size_t)size, inputP) == (size_t)size);
    fclose(inputP);

    source.dataP = dataP;
    source.size = (dword)size;
    source.position = 0;
    TestDecoderCleanup(&source);
    TestFinalImport(&source);
    result = WebPImportBegin(&source, (void *)0, &decoder,
                             &bitmap, &info);
    assert(result == WEBP_RESULT_OK);
    assert(((WebPDecoder *)MemLock(decoder))->inputP == (void *)0);
    expectedLine = 0;
    do {
        result = WebPImportNext(decoder, &firstLine, &lineCount);
        assert(((WebPDecoder *)MemLock(decoder))->inputP == (void *)0);
        if (result == WEBP_RESULT_OK) {
            assert(lineCount != 0);
            assert(firstLine == expectedLine);
            expectedLine += lineCount;
        }
    } while (result == WEBP_RESULT_OK);
    assert(result == WEBP_RESULT_DONE);
    assert(expectedLine == info.height);
    WebPImportDestroy(decoder);
    assert(hostMemoryBlocks == 0);

    outputP = fopen(argv[2], "wb");
    assert(outputP != (void *)0);
    assert(fwrite(bitmap->pixelsP, bitmap->rowBytes,
                  bitmap->height, outputP) == bitmap->height);
    fclose(outputP);
    free(bitmap->pixelsP);
    free(bitmap);

    free(dataP);
    printf("%u %u\n", info.width, info.height);
    return 0;
}
