#!/usr/bin/env perl
# Execute the actual parser, public import and MIME adapter with host stubs.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub function {
    my ($file, $name) = @_;
    open my $in, '<:raw', "$FindBin::Bin/$file" or die $!;
    my $source = do { local $/; <$in> };
    $source =~ /\n(?:TransError|ImpBmpStatus)[^;{]*?\b\Q$name\E\([^;{]*\)\s*(?:#endif\s*)?\{/s
        or die "Missing $name\n";
    my ($start, $end, $depth) = ($-[0], $+[0], 1);
    while ($depth && $end < length $source) {
        my $c = substr($source, $end++, 1);
        $depth += ($c eq '{') - ($c eq '}');
    }
    die "Unclosed $name\n" if $depth;
    my $body = substr($source, $start, $end - $start);
    # ImpSVG has two signatures selected by PROGRESS_DISPLAY.
    $body = "\n#if PROGRESS_DISPLAY\n$body" if $name eq 'ImpSVG';
    return $body;
}

my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/check.c" or die $!;
print {$out} <<'C';
#include <assert.h>
#include <stdio.h>
#include <string.h>
typedef unsigned short word, MemHandle, FileHandle, VMFileHandle;
typedef word VMBlockHandle, GStateHandle, AllocWatcherHandle, MimeRes;
typedef unsigned long dword, VMChain;
typedef long sdword;
typedef short sword;
typedef char TCHAR;
typedef sword Boolean;
typedef int TransError, ImpBmpStatus, SvgScanResult;
typedef struct { sdword RD_left, RD_top, RD_right, RD_bottom; } RectDWord;
typedef struct { char unused; } SvgImportContext, SvgMatrix, ImportProgressData;
typedef struct { word XYS_width, XYS_height; } XYSize;
typedef struct { sword P_x, P_y; } Point;
typedef struct { Boolean IAD_completeGraphic; XYSize IAD_size;
                 word IAD_type; Point IAD_origin; } ImageAdditionalData;
typedef struct { VMBlockHandle IBP_bitmap; VMFileHandle IBP_dest;
                 word IBP_status; } ImpBmpParams;
typedef struct { word MS_mimeFlags; } MimeStatus;
typedef struct { MemHandle ioH; char *ioP; } SvgScanCtx;
typedef struct {
    MemHandle tagH, dbH, ptsH, ptsWWFH;
    char *tagP, *dbP, *ptsP, *ptsWWFP;
    word failure;
    Boolean unsupportedElement;
} SVGScratch;
#define _pascal
#define _export
#define FALSE 0
#define TRUE 1
#define TE_NO_ERROR 0
#define TE_ERROR 1
#define TE_INVALID_FORMAT 2
#define TE_OUT_OF_MEMORY 3
#define TE_METAFILE_CREATION_ERROR 4
#define TE_FILE_TOO_LARGE 5
#define TE_IMPORT_NOT_SUPPORTED 6
#define IBS_NO_ERROR 0
#define IBS_UNKNOWN_FORMAT 1
#define IBS_NO_MEMORY 2
#define IBS_IMPORT_STOPPED 3
#define MIME_STATUS_ABORT 0x8000
#define IAD_TYPE_GSTRING 1
#define NullHandle 0
#define HF_DYNAMIC 0
#define HAF_ZERO_INIT 0
#define GST_VMEM 0
#define GSKT_LEAVE_DATA 0
#define GSSPT_BEGINNING 0
#define FILE_ACCESS_R 0
#define FILE_DENY_W 0
#define FILE_POS_END 0
#define FILE_POS_START 1
#define FILE_POS_RELATIVE 2
#define SVG_IO_BUF_SIZE 1024
#define SVG_GROUP_NESTING_MAX 16
#define SVG_SCRATCH_OK 0
#define SVG_SCAN_TAG 0
#define SVG_SCAN_EOF 1
#define SVG_SCAN_OUT_OF_MEMORY 2
#define SVG_SCAN_LIMIT_EXCEEDED 3
#define SVG_SCAN_TRUNCATED 4
#define LOG_INIT(c) ((void)(c))
#define LOG_START(c) ((void)(c))
#define LOG_END(c) ((void)(c))
#define LOG_STR(c,k,v) ((void)(c))
#define LOG_FILE(c,k,v) ((void)(c))
#define LOG_DWORD(c,k,v) ((void)(c))
#define LOG_STR_HEAD(c,k,v,n) ((void)(c))
#define VMCHAIN_MAKE_FROM_VM_BLOCK(b) ((VMChain)(b))
#define VMCHAIN_GET_VM_BLOCK(c) ((VMBlockHandle)(c))
typedef Boolean SvgProgressCallback(word percent);
typedef Boolean pcfm_SvgProgressCallback(word percent, SvgProgressCallback *cb);
static Boolean ProcCallFixedOrMovable_pascal(word pct, SvgProgressCallback *cb)
{ return cb(pct); }
static union { void *align; char bytes[2048]; } blocks[4];
static int present[4], locks[4], allocations, chainLive, scans, rendered;
static int cancelAfter, progressCalls, callbackAbortAt, closed;
static volatile Boolean *writerP;
static MimeStatus *mimeWriterP;
static MemHandle MemAlloc(word size, word flags, word allocFlags)
{
    int i;
    (void)flags; (void)allocFlags;
    assert(size <= sizeof(blocks[0].bytes));
    for (i = 0; i < 4 && present[i]; i++) {}
    assert(i < 4);
    present[i] = 1; allocations++;
    memset(blocks[i].bytes, 0, sizeof(blocks[i].bytes));
    return (MemHandle)(i + 1);
}
static void *MemLock(MemHandle h)
{ assert(h && present[h-1] && !locks[h-1]); locks[h-1]++; return blocks[h-1].bytes; }
static void MemUnlock(MemHandle h)
{ assert(h && present[h-1] && locks[h-1] == 1); locks[h-1]--; }
static void MemFree(MemHandle h)
{ assert(h && present[h-1] && !locks[h-1]); present[h-1] = 0; }
static dword FilePos(FileHandle file, dword offset, word mode)
{ (void)file; (void)offset; return mode == FILE_POS_END ? 100 : (dword)scans; }
static FileHandle FileOpen(TCHAR *file, word flags)
{ (void)file; (void)flags; return 1; }
static void FileClose(FileHandle file, Boolean noErrors)
{ (void)file; (void)noErrors; closed++; }
static GStateHandle GrCreateGString(VMFileHandle file, word type, VMBlockHandle *blockP)
{ (void)file; (void)type; assert(!chainLive); chainLive = 1; *blockP = 7; return 8; }
static void GrEndGString(GStateHandle gs) { (void)gs; }
static void GrSetGStringPos(GStateHandle gs, word type, word pos)
{ (void)gs; (void)type; (void)pos; }
static void GrGetGStringBoundsDWord(GStateHandle gs, word state, word control, RectDWord *boundsP)
{ (void)gs; (void)state; (void)control; memset(boundsP, 0, sizeof(*boundsP));
  boundsP->RD_right = boundsP->RD_bottom = 20; }
static void GrDestroyGString(GStateHandle gs, word state, word mode)
{ (void)gs; (void)state; (void)mode; }
static void VMFreeVMChain(VMFileHandle file, VMChain chain)
{ (void)file; assert(chain == 7 && chainLive); chainLive = 0; }
#define SvgRendererInit(c,g) ((void)(c), (void)(g))
#define SvgViewReset(c) ((void)(c))
#define SvgViewInitDefault(c) ((void)(c))
#define SvgXformStackInit(c) ((void)(c), TRUE)
#define SvgStyleStackInit(c) ((void)(c), TRUE)
#define SvgXformStackFree(c) ((void)(c))
#define SvgStyleStackFree(c) ((void)(c))
#define SvgStyleGroupPush(c,t) ((void)(c), (void)(t), TRUE)
#define SvgStyleGroupPop(c) ((void)(c))
#define SvgXformGroupPop(c) ((void)(c))
#define SvgViewInitFromSvgTag(c,t) ((void)(c), (void)(t), TRUE)
#define SvgXformParseAttrUser(c,t,m) ((void)(c), (void)(t), (void)(m), TRUE)
#define SvgXformGroupPush(c,t) ((void)(c), (void)(t), TRUE)
#define SvgTagDisplayNone(c,t) ((void)(c), (void)(t), FALSE)
#define SvgTagIsOneOf(t,n,c) ((void)(t), (void)(n), (void)(c), FALSE)
#define SvgStyleElementIsVisible(c,t) ((void)(c), (void)(t), TRUE)
static Boolean SvgScratchInit(SVGScratch *scP)
{ scP->tagH = MemAlloc(32, 0, 0); return TRUE; }
static void SvgScratchFree(SVGScratch *scP)
{ if (scP->tagP) MemUnlock(scP->tagH); MemFree(scP->tagH); }
static TransError SvgScratchError(const SVGScratch *scP)
{ assert(!scP->failure); return TE_NO_ERROR; }
static void SvgParserScanInit(SvgScanCtx *scanP)
{ memset(scanP, 0, sizeof(*scanP)); }
static SvgScanResult SvgParserScanNextTag(SvgImportContext *c, FileHandle f,
                                         SvgScanCtx *scanP, SVGScratch *scP)
{
    static const char *tags[] = {"svg", "rect/", "rect/", "/svg"};
    (void)c; (void)f;
    assert(scanP->ioP && !scP->tagP);
    if (scans == 4) return SVG_SCAN_EOF;
    scP->tagP = MemLock(scP->tagH);
    strcpy(scP->tagP, tags[scans++]);
    return SVG_SCAN_TAG;
}
static Boolean SvgParserTagIs(const char *tagP, const char *nameP)
{ word n = (word)strlen(nameP); return !strncmp(tagP, nameP, n) &&
  (tagP[n] == 0 || tagP[n] == '/'); }
static Boolean SvgTagSelfCloses(const char *tagP)
{ return tagP[strlen(tagP)-1] == '/'; }
static Boolean shape(SvgImportContext *c, const char *t, SVGScratch *scP)
{ (void)c; (void)t; (void)scP; rendered++;
  if (rendered == cancelAfter) {
      if (writerP) *writerP = TRUE;
      if (mimeWriterP) mimeWriterP->MS_mimeFlags |= MIME_STATUS_ABORT;
  }
  return TRUE; }
#define SvgShapeHandleLine shape
#define SvgShapeHandleRect shape
#define SvgShapeHandleEllipse shape
#define SvgShapeHandleCircle shape
#define SvgShapeHandlePolyline(c,t,s,v) ((void)(v), shape(c,t,s))
#define SvgShapeHandlePolygon(c,t,s,v) ((void)(v), shape(c,t,s))
#define SvgPathHandle(c,t,s,e) (*(e) = shape(c,t,s), TRUE)
C
print {$out} function('../svg.goc', 'SvgImportParse');
print {$out} function('../svgApi.goc', 'SvgImport');
print {$out} function('../../../Breadbox/ImpGraph/MAIN/impgraph.goc', 'ImpSVG');
print {$out} <<'C';
static Boolean progress(word percent)
{ assert(percent <= 100); return ++progressCalls == callbackAbortAt; }
static void reset(void)
{ int i; for (i = 0; i < 4; i++) assert(!present[i] && !locks[i]);
  assert(!chainLive); allocations = scans = rendered = progressCalls = closed = 0;
  cancelAfter = callbackAbortAt = 0; writerP = (void*)0; mimeWriterP = (void*)0; }
int main(void)
{
    volatile Boolean cancel, otherCancel;
    VMChain chain;
    int mode;
    TransError status;
    ImageAdditionalData iad;
    ImpBmpParams params;
    VMBlockHandle bitmap;
    Boolean compacted;
    dword used;
    MimeStatus mime;
    for (mode = 0; mode < 6; mode++) {
        reset(); cancel = mode == 5 ? -1 :
                          (mode == 0 || mode == 1 ? TRUE : FALSE); chain = 99;
        writerP = &cancel; cancelAfter = mode == 2 ? 1 : 0;
        callbackAbortAt = mode == 3 ? 2 : 0;
        status = SvgImport(1, 2, &chain, (void*)0, mode == 3 || mode == 4 ? progress : (void*)0,
                           mode == 0 || mode == 3 ? (void*)0 : &cancel);
        if ((mode >= 1 && mode <= 3) || mode == 5) {
            assert(status == TE_ERROR && !chain && !chainLive);
            assert(rendered == (mode == 2 ? 1 : 0));
            if (mode == 1 || mode == 5) assert(!allocations && !scans);
            if (mode == 2) assert(scans == 2 && !progressCalls);
        } else {
            assert(status == TE_NO_ERROR && chain == 7 && rendered == 2);
            if (mode == 4) assert(progressCalls == 4);
            VMFreeVMChain(2, chain);
        }
    }
    /* Another import's cancellation cannot affect this import. */
    reset(); cancel = FALSE; otherCancel = FALSE; writerP = &otherCancel; cancelAfter = 1;
    assert(SvgImport(1, 2, &chain, (void*)0, (void*)0, &cancel) == TE_NO_ERROR);
    assert(otherCancel == TRUE && !cancel && rendered == 2);
    VMFreeVMChain(2, chain);
    reset(); mime.MS_mimeFlags = 0; mimeWriterP = &mime; cancelAfter = 1;
    assert(ImpSVG("test.svg", 2, &iad, 0, 0, &used, FALSE, &params, &compacted, &bitmap,
#if PROGRESS_DISPLAY
                  (void*)0,
#endif
                  &mime) == IBS_IMPORT_STOPPED);
    assert(!bitmap && !params.IBP_bitmap && !iad.IAD_completeGraphic && !used);
    assert(closed == 1 && scans == 2 && rendered == 1);
    reset();
    puts("SVG cancellation, callback compatibility and cleanup checks passed");
    return 0;
}
C
close $out or die $!;
for my $progress (0, 1) {
    system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror',
           "-DPROGRESS_DISPLAY=$progress", "$dir/check.c", '-o', "$dir/check") == 0
        or die "Compile failed\n";
    system("$dir/check") == 0 or die "Cancellation check failed\n";
}
