#!/usr/bin/env perl
# Compile the actual capture code with host I/O shims; no GEOS runtime needed.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

my $tmp = tempdir(CLEANUP => 1);
open my $source, '<', "$FindBin::Bin/../htmlpars/htmlpars.goc" or die $!;
local $/;
my $code = <$source>;
$code =~ m{(/\* Inline SVG uses only raw input.*?)(?=int LOCAL HandleTag)}s
    or die "Cannot find capture code\n";
my $capture = $1;
open my $imageSource, '<', "$FindBin::Bin/../htmlpars/opentags.goc" or die $!;
my $imageCode = <$imageSource>;
$imageCode =~ /^(Boolean _pascal CanParseImage\(.*?^})/ms
    or die "Cannot find image admission check\n";
my $admission = $1;
my $root = "$FindBin::Bin/../../../..";
my $lifetime = '';
for my $entry (
    ["$FindBin::Bin/../htmlclas/htmlclas.goc", 'void _export FreeHTMLTransferItem'],
    ["$root/Appl/Breadbox/BbxBrow/navigate/NAVCACHE.goc", 'Boolean LOCAL ObjCacheRemoveEntry'],
    ["$root/Appl/Breadbox/BbxBrow/navigate/NAVCACHE.goc", 'Boolean LOCAL ObjCacheCheckPersist'],
    ["$root/Appl/Breadbox/BbxBrow/navigate/NAVCACHE.goc", 'Boolean ObjCacheLockItem'],
    ["$root/Appl/Breadbox/BbxBrow/navigate/NAVCACHE.goc", 'void ObjCacheUnlockItem']) {
    open my $file, '<', $entry->[0] or die $!;
    my $text = <$file>;
    $text =~ /^(\Q$entry->[1]\E\(.*?^})/ms or die "Cannot find $entry->[1]\n";
    $lifetime .= "$1\n";
}

$lifetime =~ s{//[^\n]*}{}g; # Existing GEOS code uses C++ comments.
open my $test, '>', "$tmp/check.c" or die $!;
print $test <<'C';
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <time.h>
typedef unsigned short word;
typedef int Boolean;
typedef FILE *FileHandle;
typedef void *MemHandle;
typedef unsigned short NameToken;
typedef char TCHAR;
typedef char PathName[260];
#define LOCAL
#define _pascal
#define TAG_FLUSH_TEXT 8
#define DEFAULT_IMAGE_LIMIT 200
Boolean CanParseImage(void);
static word currentFlags, G_imageCount, G_imageLimit;
static int configuredLimit = -1;
static int InitFileReadInteger(const char *categoryP, const char *keyP, word *valueP)
{
    (void)categoryP; (void)keyP;
    if(configuredLimit<0) return 1;
    *valueP = (word)configuredLimit;
    return 0;
}
#define TRUE 1
#define FALSE 0
#define _TEXT(s) s
#define STRCMPISB strcasecmp
#define STRNCMPISB strncasecmp
#define STRLENSB strlen
#define STRCPYSB strcpy
#define HF_DYNAMIC 0
#define HAF_ZERO_INIT 0
#define FILE_CREATE_ONLY 0
#define FCF_NATIVE 0
#define FILE_ACCESS_RW 0
#define FILE_DENY_RW 0
#define SP_TEMP_FILES 0
#define NullOptr 0
#define CA_NULL_ELEMENT 65535
#define HTML_IMAGE_INDEX_NONE 65535
#define NAME_POOL_NONE 0
static int NamePool, lc, G_abortParse, G_hitAllocLimit;
static const unsigned char *inputP;
static unsigned long reads, writes, written, serial;
static long failAfter = -1, abortAfter = -1;
static int failCreate, failClose, rejectImage, failToken;
static char ownedPath[260], createdPath[260];
static unsigned long fileCount;
static char recoveredTag[14];
static int recoveredClosing;
static int HandleNamedTag(MemHandle heap, char *tagP, int closing,
                           int c, int tooLong)
{
    (void)heap; (void)c; (void)tooLong;
    strcpy(recoveredTag, tagP);
    recoveredClosing = closing;
    return 999;
}
static int HTMLgetcLow(void)
{
    if(abortAfter>=0 && (long)reads>=abortAfter)
        G_abortParse = 1;
    reads++;
    return *inputP ? *inputP++ : EOF;
}
static int HTMLgetc(void) { return lc = HTMLgetcLow(); }
static MemHandle MemAlloc(size_t size, int flags, int init)
{ (void)flags; (void)init; return calloc(1, size); }
static void *MemLock(MemHandle mem) { return mem; }
static void MemUnlock(MemHandle mem) { (void)mem; }
static void MemFree(MemHandle mem) { free(mem); }
static void FileConstructFullPath(char **pathP, size_t size, int disk,
                                  const char *tail, int drive)
{
    (void)disk; (void)tail; (void)drive;
    assert(size>strlen(getenv("SVG_TEST_DIR")));
    strcpy(*pathP, getenv("SVG_TEST_DIR"));
    *pathP += strlen(*pathP);
}
static FileHandle FileCreateTempFile(char *pathP, int flags, int attrs)
{
    FILE *fileP;
    (void)flags; (void)attrs;
    if(failCreate) return 0;
    sprintf(pathP+strlen(pathP), "/%08lu.TMP", ++serial);
    strcpy(createdPath, pathP);
    fileP = fopen(pathP, "wb");
    assert(fileP);
    fileCount++;
    return fileP;
}
static word FileWrite(FileHandle fileP, const void *bytesP, word count, int flag)
{
    (void)flag;
    writes++;
    assert(count<=1024);
    if(failAfter>=0 && (long)written+count>failAfter) return 0;
    written += count;
    return (word)fwrite(bytesP, 1, count, fileP);
}
static int FileClose(FileHandle fileP, int flag)
{ (void)flag; return fclose(fileP) || failClose; }
static int FileDelete(const char *pathP)
{
    assert(remove(pathP)==0);
    fileCount--;
    return 0;
}
static NameToken NamePoolTokenize(int pool, const char *nameP, int required)
{
    (void)pool; (void)required;
    if(failToken) return 0;
    strcpy(ownedPath, nameP);
    return 1;
}
static void NamePoolReleaseToken(int pool, NameToken token)
{ (void)pool; (void)token; }
static word ParseImage(int params, word element, int name, NameToken file)
{
    (void)params; (void)element; (void)name;
    assert(file==1);
    return rejectImage || !CanParseImage() ? HTML_IMAGE_INDEX_NONE : 0;
}
C
print $test $admission, $capture;
print $test <<'C';
/* Actual page/cache destructor code below, with a two-image VM fixture. */
#define _export
#define EC(x)
#define EC_ERROR_IF(test, code)
#define COMPILE_OPTION_HUGE_ARRAY_REGIONS 1
#define VMCHAIN_GET_VM_BLOCK(chain) (chain)
#define VMCHAIN_MAKE_FROM_VM_BLOCK(block) (block)
#define HTML_FI_INLINE_SVG 2
#define HTML_IDF_INLINE_SVG 16
#define OCDF_TYPE_MASK 3
#define OCT_TEXTOBJ 0
#define OCT_GSTRING 1
#define OCDF_NOCACHE 128
#define OptrToHandle(obj) ((MemHandle)&pageHeader)
#define OptrToChunk(obj) (obj)
#define ConstructOptr(handle, chunk) (chunk)
typedef word VMFileHandle, VMBlockHandle, VMChain, optr, ObjCacheToken;
typedef word T_regionArrayHandle;
typedef struct { word VLTRAE_region; } VisLargeTextRegionArrayElement;
typedef struct {
    struct { word HTBHO_fileInfo; VMChain HTBHO_namePoolToUse; } HTBH_other;
    VMChain HTBH_arrayBlock, HTBH_regionArrayLink;
} HypertextTransferBlockHeader;
typedef struct { word HABH_imageArray; } HypertextArrayBlockHeader;
typedef struct { word flags; NameToken svgFile; } HTMLimageData;
typedef struct {
    ObjCacheToken oct;
    NameToken url;
    word OCD_flags, vmfIndex, OCD_data, lockCount, auxdata;
} objCacheData;
static HypertextTransferBlockHeader pageHeader = {{2, 3}, 2, 0};
static HypertextArrayBlockHeader imageHeader = {2};
static HTMLimageData pageImages[2] = {{16, 1}, {16, 2}};
static char pagePaths[2][260];
static objCacheData cacheItem;
static VMFileHandle cacheFiles[1] = {1};
static optr objCacheArray = 1, objCachePool = 3;
static word chainsFreed, entriesRemoved;
static void *VMLock(VMFileHandle file, VMBlockHandle block, MemHandle *memP)
{ (void)file; (void)block; *memP = &pageHeader; return &pageHeader; }
static void *VMLockChainifiedLMemBlock(VMFileHandle file, VMBlockHandle block,
                                      MemHandle *memP)
{ (void)file; (void)block; *memP = &imageHeader; return &imageHeader; }
static void VMUnlock(MemHandle mem) { (void)mem; }
static void VMUnlockChainifiedLMemBlock(MemHandle mem) { (void)mem; }
static optr NamePoolVMLoad(VMFileHandle file, VMChain chain)
{ (void)file; (void)chain; return 3; }
static void NamePoolVMUnload(optr pool) { (void)pool; }
static void NamePoolCopy(optr pool, char *bufP, word size, NameToken token,
                          char **nameP)
{ (void)pool; (void)bufP; (void)size; *nameP = pagePaths[token-1]; }
static void NamePoolDestroyIfDynamic(char *nameP) { (void)nameP; }
static word ChunkArrayGetCount(optr array) { assert(array==2); return 2; }
static void *ChunkArrayElementToPtr(optr array, word index, word *sizeP)
{ assert(array==2 && index<2); *sizeP = sizeof(HTMLimageData); return pageImages+index; }
static word RegionArrayGetCount(T_regionArrayHandle array) { (void)array; return 0; }
static void RegionLock(T_regionArrayHandle array, word index,
                        VisLargeTextRegionArrayElement **regionP, word *sizeP)
{ (void)array; (void)index; (void)regionP; (void)sizeP; assert(0); }
static void RegionUnlock(void *regionP) { (void)regionP; }
static void DBFreeUngrouped(VMFileHandle file, word region)
{ (void)file; (void)region; assert(0); }
static void VMFreeVMChain(VMFileHandle file, VMChain chain)
{ (void)file; (void)chain; assert(fileCount==0); chainsFreed++; }
static void ChunkArrayDelete(optr array, void *entryP)
{ assert(array==1 && entryP==&cacheItem); entriesRemoved++; }
static void ObjCacheGrab(void) { }
static void ObjCacheRelease(void) { }
static word ObjCacheFindEntryByToken(ObjCacheToken token, objCacheData **entryP)
{ assert(token==cacheItem.oct); *entryP = &cacheItem; return 0; }
C
print $test $lifetime;
print $test <<'C';
static void check(const char *svgP, const char *tagP, int success,
                  const char *tailP)
{
    char *htmlP, *outputP;
    size_t length = strlen(svgP), tagLength = strlen(tagP);
    FILE *fileP;
    int c;
    htmlP = malloc(length+strlen(tailP)+1);
    assert(htmlP);
    strcpy(htmlP, svgP);
    strcat(htmlP, tailP);
    reads = writes = written = 0;
    G_abortParse = G_hitAllocLimit = 0;
    ownedPath[0] = createdPath[0] = 0;
    inputP = (const unsigned char *)htmlP+1+tagLength;
    c = *inputP++;
    c = HandleInlineSVG(0, (char *)tagP, c);
    if(success) {
        assert(c==tailP[0]);
        assert(!strcmp((const char *)inputP, tailP+1));
        assert(fileCount==1);
        assert(written==length);
        assert(writes==(length+1023)/1024);
        assert(strstr(ownedPath, ".TMP"));
        outputP = malloc(length+1);
        assert(outputP);
        fileP = fopen(ownedPath, "rb");
        assert(fileP);
        assert(fread(outputP, 1, length+1, fileP)==length);
        assert(!memcmp(outputP, svgP, length));
        assert(fclose(fileP)==0);
        free(outputP);
        FileDelete(ownedPath);
    } else {
        assert(fileCount==0);
        if(createdPath[0]) assert(access(createdPath, F_OK)!=0);
        if(*tailP && !G_abortParse) {
            assert(c==tailP[0]);
            assert(!strcmp((const char *)inputP, tailP+1));
        }
    }
    free(htmlP);
}
static void checkLifetime(void)
{
    word i, pass;
    FILE *fileP;
    for(pass=0; pass<2; pass++) {
        for(i=0; i<2; i++) {
            inputP = (const unsigned char *)"/>";
            assert(HandleInlineSVG(0, "svg", *inputP++)==EOF);
            strcpy(pagePaths[i], ownedPath);
        }
        assert(fileCount==2);
        memset(&cacheItem, 0, sizeof(cacheItem));
        cacheItem.oct = 1;
        cacheItem.lockCount = 1; /* frame's page reference */
        cacheItem.OCD_flags = pass ? OCDF_NOCACHE : OCT_TEXTOBJ;
        ObjCacheLockItem(1, 0, 0, 0, 0); /* import's source reference */
        assert(cacheItem.lockCount==2);
        assert(ObjCacheRemoveEntry(&cacheItem));
        assert(fileCount==2);
        ObjCacheUnlockItem(1); /* detach frame while import is pending */
        assert(cacheItem.lockCount==1 && fileCount==2);
        for(i=0; i<2; i++) {
            fileP = fopen(pagePaths[i], "rb");
            assert(fileP && fclose(fileP)==0); /* direct source reimport */
        }
        ObjCacheUnlockItem(1); /* import completes */
        if(!pass) {
            assert(fileCount==2); /* parsed cache retains source files */
            ObjCacheLockItem(1, 0, 0, 0, 0); /* restore parsed item */
            ObjCacheUnlockItem(1);
            assert(fileCount==2);
            assert(!ObjCacheCheckPersist(&cacheItem)); /* no restart persistence */
            assert(!ObjCacheRemoveEntry(&cacheItem)); /* eviction */
        }
        assert(fileCount==0);
        assert(entriesRemoved==pass+1 && chainsFreed==pass+1);
        for(i=0; i<2; i++) assert(access(pagePaths[i], F_OK)!=0);
    }
}
int main(void)
{
    unsigned long i;
    char *largeP;
    clock_t start;
    unsigned int boundary;
    static const char *boundaries[] = {"p", "div", "table", "img", "br", "span", "body"};
    check("<svg><rect width='1' height='1'/></svg>", "svg", 1, "AFTER");
    check("<SvG\r\n data-x='\xc3\xa4\r\n'><g/></SvG>", "SvG", 1, "AFTER");
    check("<svg/>", "svg", 1, "AFTER");
    check("<svg><svg/><svg><svg/></svg></svg>", "svg", 1, "AFTER");
    check("<svg x='</svg>' y=\"<svg/>\"><g/></svg>", "svg", 1, "AFTER");
    check("<svg><!-- </svg><svg/> --><g/></svg>", "svg", 1, "AFTER");
    check("<svg><![CDATA[</svg><svg/><!--]]>text</svg>", "svg", 1, "AFTER");
    check("<svg><?pi x='</svg>' ?><!DOCTYPE svg [<!ENTITY x '</svg>'>]></svg>",
          "svg", 1, "AFTER");
    check("<svg><svgish/></svg>", "svg", 1, "AFTER");
    check("<svg><rect/>", "svg", 0, "");
    check("<svg><!-- </svg>", "svg", 0, "");
    check("<svg><![CDATA[</svg>", "svg", 0, "");
    check("<svg a='unterminated </svg>", "svg", 0, "");
    /* The malformed delimiter is returned to the HTML tag handler. */
    inputP = (const unsigned char *)"attr <p>AFTER";
    assert(HandleInlineSVG(0, "svg", ' ')== '<');
    assert(!strcmp((const char *)inputP, "p>AFTER"));
    assert(fileCount==0);
    for(boundary=0; boundary<sizeof(boundaries)/sizeof(boundaries[0]); boundary++) {
        char html[80];
        sprintf(html, "><rect/><%s class='after'>AFTER", boundaries[boundary]);
        inputP = (const unsigned char *)html+1;
        assert(HandleInlineSVG(0, "svg", '>')==999);
        assert(!strcmp(recoveredTag, boundaries[boundary]));
        assert(!recoveredClosing);
        assert(!strcmp((const char *)inputP, "class='after'>AFTER"));
        assert(fileCount==0);
    }
    inputP = (const unsigned char *)"<rect/></body>AFTER";
    assert(HandleInlineSVG(0, "svg", '>')==999);
    assert(!strcmp(recoveredTag, "body") && recoveredClosing);
    assert(fileCount==0);
    check("<svg><foreignObject><div><p>HTML</p></div></foreignObject></svg>",
          "svg", 1, "AFTER");
    check("<svg><title><span>text</span></title><desc><p>text</p></desc></svg>",
          "svg", 1, "AFTER");
    check("<svg><paragraph/><divine/><image/></svg>", "svg", 1, "AFTER");
    failCreate = 1;
    check("<svg/>", "svg", 0, "AFTER");
    failCreate = 0;
    failAfter = 0;
    check("<svg/>", "svg", 0, "AFTER");
    failAfter = -1;
    failClose = 1;
    check("<svg/>", "svg", 0, "AFTER");
    failClose = 0;
    failToken = 1;
    check("<svg/>", "svg", 0, "AFTER");
    failToken = 0;
    rejectImage = 1;
    check("<svg/>", "svg", 0, "AFTER");
    rejectImage = 0;
    abortAfter = 8;
    check("<svg><g><rect/></g></svg>", "svg", 0, "AFTER");
    abortAfter = -1;
    largeP = malloc(128*1024+12);
    assert(largeP);
    strcpy(largeP, "<svg>");
    memset(largeP+5, 'x', 128*1024);
    strcpy(largeP+5+128*1024, "</svg>");
    check(largeP, "svg", 1, "AFTER");
    failAfter = 1500;
    check(largeP, "svg", 0, "AFTER");
    failAfter = -1;
    free(largeP);
    /* Rejected images must be scanned without creating backing files. */
    G_imageCount = G_imageLimit = DEFAULT_IMAGE_LIMIT;
    check("<svg><rect/></svg>", "svg", 0, "AFTER");
    assert(!createdPath[0] && !writes);
    check("<svg><!-- </svg> --><svg/><foreignObject><p>text</p></foreignObject></svg>",
          "svg", 0, "AFTER");
    assert(!createdPath[0] && !writes);
    currentFlags = TAG_FLUSH_TEXT;
    G_imageCount = G_imageLimit = 0;
    check("<svg/>", "svg", 0, "AFTER");
    assert(!createdPath[0] && !writes);
    currentFlags = 0;
    configuredLimit = 0;
    check("<svg/>", "svg", 0, "AFTER");
    assert(!createdPath[0] && !writes);
    configuredLimit = -1;
    assert(CanParseImage() && G_imageLimit==DEFAULT_IMAGE_LIMIT);
    G_imageLimit = 1;
    assert(CanParseImage());
    G_imageCount = 1;
    assert(!CanParseImage());
    G_imageCount = 0;
    G_imageLimit = DEFAULT_IMAGE_LIMIT;
    checkLifetime();
    start = clock();
    for(i=0; i<200; i++)
        check("<svg><rect width='1' height='1'/></svg>", "svg", 1, "AFTER");
    printf("capture and page-lifetime checks passed; 200 icons: %.3f host seconds\n",
           (double)(clock()-start)/CLOCKS_PER_SEC);
    return 0;
}
C
close $test or die $!;
my $cc = $ENV{CC} // 'cc';
system($cc, '-std=c89', '-Wall', '-Wextra', '-Werror', "$tmp/check.c", '-o', "$tmp/check") == 0
    or die "Compilation failed\n";
$ENV{SVG_TEST_DIR} = $tmp;
system("$tmp/check") == 0 or die "Capture check failed\n";

# Optional DOS-friendly fixtures for the runtime checks described in TechDocs.
if(@ARGV) {
    @ARGV == 2 && $ARGV[0] eq '--fixtures' or die "Usage: $0 [--fixtures DIR]\n";
    my $dir = $ARGV[1];
    mkdir $dir unless -d $dir;
    my $icon = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><rect width="12" height="12" fill="blue"/></svg>';
    my %pages = (
        'nosvg.htm' => ('<p>Ordinary HTML <b>text</b> &amp; content.</p>' x 200),
        'one.htm' => $icon,
        'many.htm' => ($icon x 200),
        'large.htm' => '<svg xmlns="http://www.w3.org/2000/svg"><!--'.('x' x (128*1024)).'--><rect width="100" height="80"/></svg>',
        'self.htm' => '<svg xmlns="http://www.w3.org/2000/svg"/>',
        'nested.htm' => '<svg xmlns="http://www.w3.org/2000/svg"><svg><rect width="20" height="20"/></svg></svg>',
        'comment.htm' => '<svg xmlns="http://www.w3.org/2000/svg"><!-- </svg><svg/> --><rect width="20" height="20"/></svg>',
        'cdata.htm' => '<svg xmlns="http://www.w3.org/2000/svg"><desc><![CDATA[</svg><svg/>]]>&lt;/svg&gt;</desc><rect width="20" height="20"/></svg>',
        'broken.htm' => '<svg><rect width="20" height="20"/><p>Recovered HTML.</p>',
        'unclosed.htm' => '<svg><rect width="20" height="20"/>',
    );
    for my $name (sort keys %pages) {
        open my $file, '>:raw', "$dir/$name" or die $!;
        print $file '<html><body><p>Before.</p>', $pages{$name},
                    '<p>After.</p></body></html>';
        close $file or die $!;
    }
    print "Runtime fixtures written to $dir\n";
}
