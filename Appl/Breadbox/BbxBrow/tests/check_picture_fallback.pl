#!/usr/bin/env perl
# Run the real image loader/failure handlers with host event/resource shims.
# This checks ownership and ordering, not GEOS scheduling or image decoding.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $file, '<:raw', $_[0] or die "$!: $_[0]";
    local $/;
    return <$file>;
}
sub method {
    my ($text, $name, $args) = @_;
    $text =~ /^\@method URLTextClass, \Q$name\E\n\{(.*?)^}/ms
        or die "Cannot find $name\n";
    return "static void $name($args)\n{\n$1}\n";
}
sub goc_to_c {
    my ($code) = @_;
    $code =~ s/\@(?:call|send(?:\s*,forceQueue)?)\s+[^:;]+::\s*(MSG_\w+)\(/$1(/g;
    $code =~ s/\@ifdef (\w+)/#ifdef $1/g;
    $code =~ s/\@else/#else/g;
    $code =~ s/\@endif/#endif/g;
    $code =~ s{//[^\n]*}{}g;
    $code =~ s/\(int\)i/(short)i/g; # GEOS int is 16-bit.
    return $code;
}
my $root = "$FindBin::Bin/../../../..";
my $source = read_source("$FindBin::Bin/../urltext/URLTEXT.goc");
my $header = read_source("$root/CInclude/html4par.goh");
my $class = read_source("$root/Library/Breadbox/Html4Par/htmlclas/htmlclas.goc");
my $import = read_source("$FindBin::Bin/../htmlview/ImportG.goc");
$header =~ /(typedef struct \{\s*\/\*\*\* Fields filled in by parser:.*?} HTMLimageData;)/s
    or die "Cannot find image record\n";
my $image_type = $1;
$source =~ /(typedef struct \{\s*word index;.*?} URLTextRequestGraphic;)/s
    or die "Cannot find fetch request\n";
my $request_type = $1;
$source =~ /^(Boolean LOCAL ProcessSingleGraphic\(.*?^})/ms
    or die "Cannot find loader\n";
my $loader = $1;
$class =~ /^(void LOCAL IMarkAllImagesUnresolved\(.*?^})/ms
    or die "Cannot find attachment reset\n";
my $reset = $1;
$import =~ /else \{\s*(#if PROGRESS_DISPLAY\s*if\(request.importProgressData.IPD_cacheItem.*?MSG_URL_TEXT_INTERNAL_GRAPHIC_FAILED\(\s*request.name, request.imageGeneration\);)\s*}/s
    or die "Cannot find final import failure cleanup\n";
my $failure = $1;
my $harness = <<'C';
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned short word, NameToken, WordFlags, VMFileHandle, VMBlockHandle;
typedef unsigned int dword, optr, MemHandle, ObjCacheToken;
typedef int Boolean;
typedef char TCHAR;
typedef struct { word XYS_width, XYS_height; } XYSize;
typedef struct { short XYO_x, XYO_y; } XYOffset;
typedef struct { short P_x, P_y; } Point;
typedef struct { word WWF_frac, WWF_int; } WWFixed;
#define LOCAL
#define _pascal
#define TRUE 1
#define FALSE 0
#define NAME_POOL_NONE 0
#define NullHandle 0
#define NullOptr 0
#define OCT_NULL 0
#define OCT_GSTRING 1
#define TEXT_ADDRESS_PAST_END 0xffffffffU
#define HTML_STATIC_BUF 128
#define HTMLV_OBJECT_CACHE 1
#define MIME_MAXBUF 32
#define ULM_CACHE 0
#define ULM_ALWAYS 1
#define URB_RF_NOCACHE 0x100
#define URL_RET_FILE 1
#define URL_RET_PROGRESS 2
#define URL_RET_PROGRESS_ABORT 3
#define URL_RET_MESSAGE 4
#define URL_RET_ABORTED 5
#define URLRequestGetRet(v) ((v) & 255)
#define EC(x)
#define _TEXT(s) s
#define OptrToHandle(v) (v)
#define OptrToChunk(v) 0
#define pself (&text)
static const optr oself = 1;
#define self 1
#define JAVASCRIPT_SUPPORT 1
C
$harness .= $image_type . "\n" . $request_type . "\n";
$harness .= <<'C';
typedef struct { optr HTI_imageArray, HTI_namePool, UTI_frame;
    dword UTI_imageGeneration; word UTI_doomed; } URLTextInstance;
typedef struct { Boolean IAD_completeGraphic; } ImageAdditionalData;
typedef struct { NameToken url; TCHAR mimeType[MIME_MAXBUF], curHTML[128];
    word retType; optr htmlMsg, extraData; } URLFetchResult;
typedef struct { word LPD_importSync, LPD_sem; void *LPD_callback;
    optr LPD_textObj, LPD_request; NameToken LPD_nameT;
    char LPD_mimeType[MIME_MAXBUF]; } LoadProgressData;
typedef word proc_LoadProgressCallback(void);
typedef struct { NameToken IPD_nameT; dword IPD_cacheItem;
    word IPD_firstLine, IPD_lastLine; } ImportProgressData;
#define _ImportProgressParams_ ImportProgressData *importProgressDataP
#define _LoadProgressParams_ LoadProgressData *loadProgressDataP
#define ObjDerefVis(obj) (&text)
#define ARRAY 1
#define EXTRA 100
#define RESULT 200
#define PROGRESS 300
#define LIMIT 48
static optr namePool = 1;
static URLTextInstance text;
static HTMLimageData images[4];
static word count, arrayLocks, extraLocks[LIMIT], resultLocks[LIMIT], progressLocks;
static URLTextRequestGraphic extras[LIMIT];
static URLFetchResult results[LIMIT];
static ImportProgressData progressData;
static char names[2][LIMIT][128];
static unsigned refs[2][LIMIT], nextName[2], unsupported[LIMIT];
static struct { NameToken url; unsigned refs; Boolean cached, complete; } caches[LIMIT];
static struct { optr extra; NameToken url; word mode; } fetches[LIMIT];
static struct { NameToken name; dword imageGeneration; ImportProgressData importProgressData;
    Boolean temporary; } imports[LIMIT];
static unsigned fetched, imported, pending, completed, events, freedProgress, deleted;
static Boolean G_stopped, caching, failQueue;
static Boolean progressDisplay = TRUE;
static word progressMinHeight;
static unsigned pool_index(optr pool) { assert(pool == 1 || pool == 2); return pool-1; }
static NameToken NamePoolTokenize(optr pool, const char *s, Boolean required)
{
    unsigned k = pool_index(pool), i;
    (void)required;
    if(!*s) return 0;
    for(i = 1; i <= nextName[k]; i++)
        if(!strcmp(names[k][i], s)) { refs[k][i]++; return (word)i; }
    i = ++nextName[k]; assert(i < LIMIT && strlen(s) < 128);
    strcpy(names[k][i], s); refs[k][i] = 1; return (word)i;
}
static void NamePoolUseToken(optr pool, NameToken token)
{ unsigned k = pool_index(pool); assert(token && refs[k][token]); refs[k][token]++; }
static void NamePoolReleaseToken(optr pool, NameToken token)
{ unsigned k = pool_index(pool); if(token) { assert(refs[k][token]); refs[k][token]--; } }
static void NamePoolCopy(optr pool, TCHAR *buf, word len, NameToken token, TCHAR **out)
{
    unsigned k = pool_index(pool), n = strlen(names[k][token])+1;
    assert(token && refs[k][token]);
    (void)buf; (void)len;
    *out = malloc(n); assert(*out);
    memcpy(*out, names[k][token], n);
}
static void NamePoolDestroyIfDynamic(char *s) { free(s); }
static Boolean NamePoolTestEqual(optr pool, NameToken t, const char *s)
{ return !strcmp(names[pool_index(pool)][t], s); }
static void *MemLock(MemHandle h)
{
    if(h == ARRAY) { arrayLocks++; return images; }
    if(h >= RESULT && h < RESULT+LIMIT) { resultLocks[h-RESULT]++; return &results[h-RESULT]; }
    assert(h == PROGRESS); progressLocks++; return &progressData;
}
static void MemUnlock(MemHandle h)
{
    if(h == ARRAY) { assert(arrayLocks); arrayLocks--; }
    else if(h >= RESULT && h < RESULT+LIMIT) { assert(resultLocks[h-RESULT]); resultLocks[h-RESULT]--; }
    else { assert(h == PROGRESS && progressLocks); progressLocks--; }
}
static void MemFree(MemHandle h)
{
    if(h >= RESULT && h < RESULT+LIMIT) assert(!resultLocks[h-RESULT]);
    else { assert(h == PROGRESS && !progressLocks); freedProgress++; }
}
static word ChunkArrayGetCount(optr array) { assert(array == ARRAY && arrayLocks); return count; }
static void *ChunkArrayElementToPtr(optr array, word i, word *size)
{ assert(array == ARRAY && arrayLocks && i < count); if(size) *size = sizeof(images[i]); return &images[i]; }
static optr URLFetchExtraMemoryAlloc(word size)
{ assert(size == sizeof(extras[0]) && fetched < LIMIT-1); return EXTRA+fetched; }
static void URLFetchExtraMemoryLock(optr h) { assert(h >= EXTRA && h < EXTRA+LIMIT); extraLocks[h-EXTRA]++; }
static URLTextRequestGraphic *URLFetchExtraMemoryDeref(optr h)
{ assert(extraLocks[h-EXTRA]); return &extras[h-EXTRA]; }
static void URLFetchExtraMemoryUnlock(optr h) { assert(extraLocks[h-EXTRA]); extraLocks[h-EXTRA]--; }
static void URLFetchExtraMemoryFree(optr h) { assert(!extraLocks[h-EXTRA]); }
static void MSG_URL_TEXT_INC_PENDING(void) { assert(!arrayLocks); pending++; }
static void MSG_URL_TEXT_DEC_PENDING(void) { assert(pending); if(!--pending) completed++; }
static word MSG_HTML_TEXT_GET_IMAGE_COUNT(void) { return text.HTI_imageArray ? count : 0; }
static Boolean MSG_HTML_TEXT_GET_IMAGE(word i, HTMLimageData *p)
{ assert(text.HTI_imageArray && i < count); *p = images[i]; return TRUE; }
static void MSG_HTML_TEXT_MARK_IMAGE_RESOLVING(word i)
{ images[i].flags &= ~(HTML_IDF_RESOLVED | HTML_IDF_BROKEN | HTML_IDF_SIZE_DIRTY); images[i].flags |= HTML_IDF_RESOLVING; }
static void MSG_HTML_TEXT_MARK_IMAGE_UNRESOLVED(word i)
{ images[i].flags &= ~(HTML_IDF_RESOLVED | HTML_IDF_RESOLVING | HTML_IDF_BROKEN | HTML_IDF_SIZE_DIRTY); }
static void MSG_HTML_TEXT_MARK_IMAGE_BROKEN(word i)
{ MSG_HTML_TEXT_MARK_IMAGE_UNRESOLVED(i); images[i].flags |= HTML_IDF_RESOLVED | HTML_IDF_BROKEN; }
static void MSG_HTML_TEXT_INVALIDATE_IMAGE(void *p, word i, word first, word last)
{ (void)p; (void)i; (void)first; (void)last; }
static void MSG_HTML_TEXT_FIRE_EVENT(word evt, word type, word i)
{ (void)evt; (void)type; (void)i; events++; }
#define HTML_EVENT_ERROR 1
#define HTML_EVENT_OBJECT_IMAGE 1
static void MSG_HTML_TEXT_ANIMATIONS_ON(void) {}
static void MSG_HTML_TEXT_LAYOUT_STOP(void) {}
static optr MSG_URL_FRAME_FIND_REAL_FRAME(void) { return 4; }
static NameToken MSG_URL_FRAME_GET_URL(void) { return NamePoolTokenize(1, "http://site/page", FALSE); }
static ObjCacheToken MSG_URL_FRAME_GET_CACHE_TOKEN(void) { return 1; }
static word MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS(void) { return caching; }
static void MSG_URL_FRAME_COMPLETE_URL(TCHAR **s)
{
    char *absolute;
    const char *relative = *s;
    if(strstr(relative, "://")) return;
    while(!strncmp(relative, "./", 2)) relative += 2;
    absolute = malloc(strlen(relative)+13); assert(absolute);
    strcpy(absolute, "http://site/"); strcat(absolute, relative);
    free(*s); *s = absolute;
}
static ObjCacheToken new_cache(NameToken url, Boolean complete, Boolean cached)
{
    unsigned i;
    for(i = 1; i < LIMIT; i++) if(!caches[i].refs) break;
    assert(i < LIMIT); caches[i].url = url; caches[i].refs = 1;
    caches[i].complete = complete; caches[i].cached = cached;
    return i;
}
static void ObjCacheUnlockItem(ObjCacheToken oct)
{
    assert(oct && caches[oct].refs);
    caches[oct].refs--;
}
static void ObjCacheLockItem(ObjCacheToken oct, void *vf, void *vc, ImageAdditionalData *iad, word size)
{
    (void)vf; (void)vc; (void)size; assert(caches[oct].refs); caches[oct].refs++;
    if(iad) iad->IAD_completeGraphic = caches[oct].complete;
}
static ObjCacheToken ObjCacheFindURL(word type, NameToken url, Boolean lock, Boolean expire)
{
    unsigned i;
    (void)type; (void)expire; assert(lock && !arrayLocks);
    for(i = 1; i < LIMIT; i++) if(caches[i].refs && caches[i].cached && caches[i].url == url) {
        caches[i].refs++; return i;
    }
    return OCT_NULL;
}
static void IReplaceGraphic(optr obj, ObjCacheToken oct, HTMLimageData *p, word i, word first, word last)
{
    (void)obj; (void)first; (void)last; assert(!arrayLocks && caches[oct].refs);
    caches[oct].refs++; p->HID_cacheToken = oct; p->HID_vmf = p->HID_vmb = 1;
    p->flags &= ~(HTML_IDF_RESOLVING | HTML_IDF_BROKEN); p->flags |= HTML_IDF_RESOLVED;
    images[i] = *p;
}
static Boolean ImageURLGetUnsupportedFormat(NameToken url) { return unsupported[url]; }
static word LoadGraphicProgressCallback(void) { return 0; }
static void MSG_URL_TEXT_GRAPHIC_FETCHED(MemHandle);
static void URLFetchRequest(NameToken url, word mode, MemHandle post, NameToken referer,
    optr obj, void (*msg)(MemHandle), optr extra
#if PROGRESS_DISPLAY
    , LoadProgressData *progressP
#endif
    )
{
    (void)post; (void)referer; (void)obj; (void)msg;
#if PROGRESS_DISPLAY
    (void)progressP;
#endif
    assert(!arrayLocks && pending && fetched < LIMIT);
    fetches[fetched].extra = extra; fetches[fetched].url = url; fetches[fetched++].mode = mode;
}
static Boolean ImportThreadRequestImportGraphic(optr obj, NameToken name, TCHAR *mime,
    TCHAR *file, Boolean temporary, ObjCacheToken owner
#if PROGRESS_DISPLAY
    , LoadProgressData *progressP
#endif
    )
{
    (void)obj; (void)mime; (void)file; (void)owner;
#if PROGRESS_DISPLAY
    (void)progressP;
#endif
    assert(!arrayLocks && pending && imported < LIMIT);
    if(failQueue) return FALSE;
    imports[imported].name = name; imports[imported].imageGeneration = text.UTI_imageGeneration;
    imports[imported++].temporary = temporary; return TRUE;
}
static void AssumeGraphic(char *mime) { (void)mime; }
static void FileDelete(char *name) { (void)name; deleted++; }
static void ImportRemoveProgressDataFromQueue(MemHandle h) { assert(h == PROGRESS); }
static void ThreadPSem(word sem) { (void)sem; }
static void ThreadVSem(word sem) { (void)sem; }
static void MSG_URL_TEXT_INTERNAL_REPLACE_LIKE_GRAPHICS(ObjCacheToken, NameToken, word, word);
static void MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS(NameToken);
static void MSG_URL_TEXT_INTERNAL_GRAPHIC_FAILED(NameToken, dword);
C
$harness .= goc_to_c($loader) . "\n" . goc_to_c($reset) . "\n";
for my $entry (
    ['MSG_URL_TEXT_PROCESS_GRAPHICS', 'Boolean forceLoad'],
    ['MSG_URL_TEXT_GRAPHIC_FETCHED', 'MemHandle urlFetchMem'],
    ['MSG_URL_TEXT_INTERNAL_GRAPHIC_FAILED', 'NameToken url, dword generation'],
    ['MSG_URL_TEXT_INTERNAL_REPLACE_LIKE_GRAPHICS', 'ObjCacheToken oct, NameToken url, word invalFrom, word invalTo'],
    ['MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS', 'NameToken url'],
    ['MSG_URL_TEXT_CHANGE_GRAPHIC', 'word i, NameToken url'],
    ['MSG_URL_TEXT_STOP', 'void']) {
    $harness .= goc_to_c(method($source, @$entry));
}
$harness .= "#if PROGRESS_DISPLAY\n" . goc_to_c(method($source,
    'MSG_URL_TEXT_IMPORT_GRAPHIC_PROGRESS', 'MemHandle importProgressData'));
$harness .= goc_to_c(method($source, 'MSG_URL_TEXT_LOAD_GRAPHIC_PROGRESS', 'LoadProgressData *loadProgressDataP')) . "#endif\n";
$harness .= "static void final_failure(unsigned i)\n{\n";
$harness .= "    struct { NameToken name; dword imageGeneration; ImportProgressData importProgressData; } request;\n";
$harness .= "    request.name = imports[i].name; request.imageGeneration = imports[i].imageGeneration;\n    request.importProgressData = imports[i].importProgressData;\n";
$harness .= goc_to_c($failure) . "\n}\n";
$harness .= <<'C';
static void init(void)
{
    memset(&text, 0, sizeof(text)); memset(images, 0, sizeof(images));
    memset(names, 0, sizeof(names)); memset(refs, 0, sizeof(refs));
    memset(caches, 0, sizeof(caches)); memset(imports, 0, sizeof(imports));
    memset(unsupported, 0, sizeof(unsupported)); memset(nextName, 0, sizeof(nextName));
    text.HTI_imageArray = ARRAY; text.HTI_namePool = 2; text.UTI_frame = 4;
    text.UTI_imageGeneration = 1; count = fetched = imported = pending = completed = events = 0;
    freedProgress = deleted = 0; G_stopped = failQueue = FALSE; caching = TRUE;
}
static void add_image(const char *primary, const char *fallback)
{
    HTMLimageData *p = &images[count++]; assert(count <= 4);
    p->imageURL = NamePoolTokenize(2, primary, FALSE);
    if(fallback) { p->svgFile = NamePoolTokenize(2, fallback, FALSE); p->flags = HTML_IDF_PICTURE_FALLBACK; }
}
static void fetch_done(unsigned i, word ret)
{
    URLFetchResult *r = &results[i]; assert(i < fetched);
    memset(r, 0, sizeof(*r)); r->url = fetches[i].url; r->retType = ret;
    r->extraData = fetches[i].extra; strcpy(r->mimeType, "image/webp"); strcpy(r->curHTML, "download.tmp");
    NamePoolUseToken(1, r->url); MSG_URL_TEXT_GRAPHIC_FETCHED(RESULT+i);
}
static void import_done(unsigned i, Boolean success, Boolean cancel)
{
    ObjCacheToken oct;
    assert(i < imported);
    if(cancel) {
        if(imports[i].importProgressData.IPD_cacheItem)
            ObjCacheUnlockItem(imports[i].importProgressData.IPD_cacheItem);
        MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS(imports[i].name);
    } else if(success) {
        oct = new_cache(imports[i].name, TRUE, FALSE);
        MSG_URL_TEXT_INTERNAL_REPLACE_LIKE_GRAPHICS(oct, imports[i].name, 0, 0xffff);
    } else final_failure(i);
    MSG_URL_TEXT_DEC_PENDING();
}
static void reload(void)
{
    unsigned i;
    text.UTI_imageGeneration++;
    for(i = 0; i < count; i++) {
        if(images[i].HID_cacheToken) ObjCacheUnlockItem(images[i].HID_cacheToken);
        NamePoolReleaseToken(1, images[i].HID_resolvedURL);
    }
    IMarkAllImagesUnresolved(ARRAY);
}
static void cleanup(void)
{
    unsigned i, k;
    assert(!pending && !arrayLocks && !progressLocks);
    for(i = 0; i < count; i++) {
        if(images[i].HID_cacheToken) ObjCacheUnlockItem(images[i].HID_cacheToken);
        NamePoolReleaseToken(1, images[i].HID_resolvedURL);
        NamePoolReleaseToken(2, images[i].imageURL); NamePoolReleaseToken(2, images[i].svgFile);
    }
    for(i = 1; i < LIMIT; i++) if(caches[i].cached) ObjCacheUnlockItem(i);
    for(i = 0; i < LIMIT; i++) {
        assert(!caches[i].refs && !extraLocks[i] && !resultLocks[i]);
        for(k = 0; k < 2; k++) assert(!refs[k][i]);
    }
}
static void load_success(unsigned f)
{ fetch_done(f, URL_RET_FILE); import_done(imported-1, TRUE, FALSE); }
static void check(void)
{
    NameToken t, primary;
    ObjCacheToken oct;
    unsigned old;
#if PROGRESS_DISPLAY
    LoadProgressData stream;
#endif
    assert(sizeof(word) == 2 && sizeof(dword) == 4);
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    assert(fetched == 1 && pending == 1); load_success(0);
    assert(fetched == 1 && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED)); cleanup();

    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    primary = images[0].imageURL; fetch_done(0, URL_RET_FILE); import_done(0, FALSE, FALSE);
    assert(fetched == 2 && pending == 1 && !completed && images[0].imageURL == primary);
    assert(!strcmp(names[0][images[0].HID_resolvedURL], "http://site/fallback.jpg"));
    load_success(1); assert(completed == 1 && (images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED)); cleanup();

    init(); add_image("primary.webp", "./primary.webp"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, 99); assert(fetched == 1 && !pending && (images[0].flags & HTML_IDF_BROKEN)); cleanup();
    init(); add_image("primary.webp", "fallback.png"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, URL_RET_FILE); import_done(0, FALSE, FALSE); fetch_done(1, URL_RET_FILE); import_done(1, FALSE, FALSE);
    assert(fetched == 2 && !pending && (images[0].flags & HTML_IDF_BROKEN)); cleanup();

    init(); add_image("shared.webp", "one.jpg"); add_image("shared.webp", "two.png"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    assert(fetched == 1); fetch_done(0, 99); assert(fetched == 3 && pending == 2 && !completed);
    assert(images[0].HID_resolvedURL != images[1].HID_resolvedURL); load_success(1); fetch_done(2, 99);
    assert(!(images[0].flags & HTML_IDF_BROKEN) && (images[1].flags & HTML_IDF_BROKEN)); cleanup();
    init(); add_image("shared.webp", "same.jpg"); add_image("shared.webp", "same.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, 99); assert(fetched == 2 && pending == 1); load_success(1); cleanup();

    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, URL_RET_ABORTED); assert(fetched == 1 && !pending && !(images[0].flags & HTML_IDF_BROKEN)); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    G_stopped = TRUE; MSG_URL_TEXT_STOP(); G_stopped = FALSE; fetch_done(0, 99);
    assert(fetched == 1 && !pending && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED)); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, URL_RET_FILE); import_done(0, FALSE, TRUE); assert(fetched == 1); cleanup();

    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, URL_RET_FILE); old = text.UTI_imageGeneration; reload(); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    assert(imports[0].imageGeneration == old && images[0].HID_resolvedURL == imports[0].name);
    import_done(0, FALSE, FALSE); assert(fetched == 2 && pending == 1 && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED));
    load_success(1); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    reload(); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE); fetch_done(0, URL_RET_FILE);
    assert(!imported && fetched == 2 && pending == 1); load_success(1); cleanup();

    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, 99); load_success(1); reload(); MSG_URL_TEXT_PROCESS_GRAPHICS(TRUE);
    assert(fetched == 3 && fetches[2].mode == ULM_ALWAYS);
    assert(!strcmp(names[0][fetches[2].url], "http://site/primary.webp")); load_success(2); cleanup();
    init(); add_image("primary.webp", "old.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    t = NamePoolTokenize(1, "new.png", FALSE); MSG_URL_TEXT_CHANGE_GRAPHIC(0, t);
    fetch_done(0, 99); fetch_done(1, 99); assert(fetched == 2 && (images[0].flags & HTML_IDF_BROKEN)); cleanup();

    init(); add_image("ordinary.jpg", (void *)0); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    fetch_done(0, 99); assert(fetched == 1 && (images[0].flags & HTML_IDF_BROKEN)); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); t = NamePoolTokenize(1, "http://site/primary.webp", FALSE);
    oct = new_cache(t, TRUE, TRUE); NamePoolReleaseToken(1, t); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    assert(!fetched && images[0].HID_cacheToken == oct && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED)); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); t = NamePoolTokenize(1, "http://site/fallback.jpg", FALSE);
    oct = new_cache(t, TRUE, TRUE); NamePoolReleaseToken(1, t); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE); fetch_done(0, 99);
    assert(fetched == 1 && images[0].HID_cacheToken == oct && !pending); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); t = NamePoolTokenize(1, "http://site/primary.webp", FALSE);
    unsupported[t] = TRUE; NamePoolReleaseToken(1, t); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    assert(fetched == 1 && !strcmp(names[0][fetches[0].url], "http://site/fallback.jpg")); load_success(0); cleanup();

    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    failQueue = TRUE; fetch_done(0, URL_RET_FILE); assert(fetched == 2 && pending == 1); failQueue = FALSE; load_success(1); cleanup();
    init(); add_image("svg", "http://site/inline.svg"); images[0].flags = HTML_IDF_INLINE_SVG;
    MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE); assert(!fetched && imported == 1); import_done(0, FALSE, FALSE);
    assert(!deleted && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED)); cleanup();
#if PROGRESS_DISPLAY
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE); fetch_done(0, URL_RET_FILE);
    progressData.IPD_cacheItem = OCT_NULL; progressData.IPD_nameT = imports[0].name;
    MSG_URL_TEXT_IMPORT_GRAPHIC_PROGRESS(PROGRESS);
    assert(fetched == 1 && !(images[0].flags & HTML_IDF_PICTURE_FALLBACK_USED));
    oct = new_cache(imports[0].name, FALSE, FALSE); imports[0].importProgressData.IPD_cacheItem = oct;
    caches[oct].refs++; progressData.IPD_cacheItem = oct; progressData.IPD_nameT = imports[0].name;
    MSG_URL_TEXT_IMPORT_GRAPHIC_PROGRESS(PROGRESS); assert(fetched == 1 && images[0].HID_cacheToken == oct);
    import_done(0, FALSE, FALSE); assert(!caches[oct].refs && fetched == 2 && pending == 1); load_success(1); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE); fetch_done(0, URL_RET_FILE);
    oct = new_cache(imports[0].name, FALSE, FALSE); imports[0].importProgressData.IPD_cacheItem = oct;
    caches[oct].refs++; progressData.IPD_cacheItem = oct; progressData.IPD_nameT = imports[0].name;
    reload(); text.HTI_imageArray = 0; MSG_URL_TEXT_IMPORT_GRAPHIC_PROGRESS(PROGRESS);
    assert(freedProgress == 1 && caches[oct].refs == 1); import_done(0, FALSE, FALSE); cleanup();
    init(); add_image("primary.webp", "fallback.jpg"); MSG_URL_TEXT_PROCESS_GRAPHICS(FALSE);
    memset(&stream, 0, sizeof(stream)); stream.LPD_request = fetches[0].extra; stream.LPD_nameT = fetches[0].url;
    reload(); MSG_URL_TEXT_LOAD_GRAPHIC_PROGRESS(&stream); assert(!imported && extras[0].progressCanceled);
    fetch_done(0, URL_RET_PROGRESS); assert(!pending && fetched == 1); cleanup();
#endif
    puts("Picture fallback: retry, cache, locks, generations and ownership passed.");
}
int main(void) { check(); return 0; }
C
my $tmp = tempdir(CLEANUP => 1);
for my $progress (0, 1) {
    open my $file, '>', "$tmp/check.c" or die $!;
    print $file "#define PROGRESS_DISPLAY $progress\n", $harness;
    close $file or die $!;
    system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', '-Wno-unused-function',
           '-Wno-unused-variable', '-Wno-unused-but-set-variable',
           "$tmp/check.c", '-o', "$tmp/check") == 0 or die "Host compilation failed\n";
    system("$tmp/check") == 0 or die "Picture fallback checks failed\n";
}
