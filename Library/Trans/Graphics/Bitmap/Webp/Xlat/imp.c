/*
 * WebP import translator.
 */

#include <geos.h>
#include <file.h>
#include <graphics.h>
#include <vm.h>
#include <webplib.h>
#include <xlatLib.h>

#define WEBP_HEADER_SIZE 12

dword _pascal
ImportProcedure(ImportFrame *frame, VMChain *chain)
{
    WebPImportHandle decoderH;
    VMBlockHandle bitmap;
    WebPImageInfo info;
    WebPResult result;
    word firstLine;
    word lineCount;

    *chain = 0;
    decoderH = NullHandle;
    bitmap = NullHandle;

    result = WebPImportBegin(frame->IF_sourceFile,
                             frame->IF_transferVMFile,
                             &decoderH, &bitmap, &info);
    while (result == WEBP_RESULT_OK) {
        result = WebPImportNext(decoderH, &firstLine, &lineCount);
    }
    WebPImportDestroy(decoderH);

    if (result == WEBP_RESULT_DONE) {
        *chain = VMCHAIN_MAKE_FROM_VM_BLOCK(bitmap);
        return TE_NO_ERROR | (((dword)CIF_BITMAP) << 16);
    }
    if (bitmap != NullHandle) {
        VMFreeVMChain(frame->IF_transferVMFile,
                      VMCHAIN_MAKE_FROM_VM_BLOCK(bitmap));
    }
    switch (result) {
    case WEBP_ERROR_READ:
        return TE_FILE_READ;
    case WEBP_ERROR_OUT_OF_MEMORY:
        return TE_OUT_OF_MEMORY;
    case WEBP_ERROR_IMAGE_TOO_LARGE:
        return TE_FILE_TOO_LARGE;
    case WEBP_ERROR_WRONG_FORMAT:
    case WEBP_ERROR_UNSUPPORTED:
    case WEBP_ERROR_CORRUPT:
        return TE_INVALID_FORMAT;
    default:
        return TE_IMPORT_ERROR;
    }
}

word _pascal
TestFile(FileHandle file)
{
    byte header[WEBP_HEADER_SIZE];
    word size;

    FilePos(file, 0, FILE_POS_START);
    size = FileRead(file, header, sizeof(header), FALSE);
    FilePos(file, 0, FILE_POS_START);

    if (size != sizeof(header) ||
        header[0] != 'R' || header[1] != 'I' ||
        header[2] != 'F' || header[3] != 'F' ||
        header[8] != 'W' || header[9] != 'E' ||
        header[10] != 'B' || header[11] != 'P') {
        return NO_IDEA_FORMAT;
    }
    return TE_NO_ERROR;
}
