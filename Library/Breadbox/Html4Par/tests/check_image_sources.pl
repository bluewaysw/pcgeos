#!/usr/bin/env perl
# Compile the actual image selectors and picture/image handlers with host stubs.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $file, '<:raw', $_[0] or die "$!: $_[0]";
    local $/;
    return <$file>;
}
sub function {
    my ($text, $name) = @_;
    $text =~ /^(?:[A-Za-z_][^\n]*\b)?\Q$name\E\([^;{]*\)\s*\{/m
        or die "Cannot find $name\n";
    my $start = $-[0];
    my $end = $+[0];
    my $depth = 1;
    while ($depth && $end < length($text)) {
        my $c = substr($text, $end++, 1);
        $depth += ($c eq '{') - ($c eq '}');
    }
    die "Unclosed $name\n" if $depth;
    return substr($text, $start, $end - $start);
}
my $root = "$FindBin::Bin/../../../..";
my $source = read_source("$FindBin::Bin/../htmlpars/opentags.goc");
my $parser = read_source("$FindBin::Bin/../htmlpars/htmlpars.goc");
my $browser = read_source("$root/Appl/Breadbox/BbxBrow/urlframe/FRFETCH.goc");
my $header = read_source("$FindBin::Bin/../internal.h");
$header =~ /^#define HTML_IMAGE_SELECT_SMALLEST ([01])$/m or die "Missing policy\n";
my $default = $1;
my $harness = <<'C';

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned short word;
typedef unsigned int dword;
typedef dword WWFixedAsDWord;
typedef int Boolean;
typedef word NameToken;
typedef char TCHAR;
typedef struct { const char *key, *value; } Param;
typedef Param *optr;
typedef struct { optr paramArray; word spec; } TagOpenArguments;
typedef Boolean proc_HTMLImageMimeSupported(char *mimeP);
typedef Boolean pcfm_HTMLImageMimeSupported(char *mimeP, void *callbackP);
typedef struct {
    word viewportWidth;
    proc_HTMLImageMimeSupported *mimeSupported;
    Boolean inPicture;
    NameToken pictureSource;
} HTMLImageSourceState;
typedef char FileLongName[40];
#define MIME_MAXBUF 128
#define _TEXT(s) s
#define LOCAL
#define _pascal
#define _export
#define TRUE 1
#define FALSE 0
#define NAME_POOL_NONE 0
#define STRCMPSB strcmp
#define STRLENSB strlen
#define ATOISB atoi
#define IS_SRCSET_SPACE(c) \
    ((c) == ' ' || (c) == '\t' || (c) == '\n' || (c) == '\f' || (c) == '\r')
static HTMLImageSourceState imageSourceState;
static optr NamePool, assocTypeDriver;
static char names[64][128];
static unsigned refs[64], nextToken, supportWebp;
static word currentFlags, G_imageCount, G_imageLimit = 200;
static int c2;
static char *GetParamValue(optr p, const char *key)
{
    for(; p && p->key; p++)
        if(!strcmp(p->key, key)) return (char *)p->value;
    return (char *)0;
}
static NameToken NamePoolTokenizeLenDOS(optr pool, char *s, word n, Boolean required)
{
    (void)pool; (void)required;
    if(!n) n = (word)strlen(s);
    assert(n < sizeof(names[0]) && nextToken + 1 < 64);
    nextToken++;
    memcpy(names[nextToken], s, n);
    names[nextToken][n] = 0;
    refs[nextToken] = 1;
    return (NameToken)nextToken;
}
#define NamePoolTokenizeDOS(pool, s, required) NamePoolTokenizeLenDOS(pool, s, 0, required)
static void NamePoolReleaseToken(optr pool, NameToken token)
{
    (void)pool;
    assert(token && refs[token]);
    refs[token]--;
}
static int LocalCmpStringsNoCase(const char *a, const char *b, unsigned n)
{
    unsigned i;
    for(i = 0; i < n; i++)
        if(tolower((unsigned char)a[i]) != tolower((unsigned char)b[i])) return 1;
    return 0;
}
static Boolean NameAssocFindAssociation(optr a, const char *mime, char *driver,
    unsigned n, Boolean insensitive, void *unused)
{
    (void)a; (void)driver; (void)n; (void)insensitive; (void)unused;
    return !strcmp(mime, "image/jpeg") || !strcmp(mime, "image/gif") ||
           !strcmp(mime, "image/png") || !strcmp(mime, "image/svg+xml") ||
           (supportWebp && !strcmp(mime, "image/webp"));
}
static Boolean ProcCallFixedOrMovable_pascal(char *mime, void *callback)
{
    return ((proc_HTMLImageMimeSupported *)callback)(mime);
}
/* GEOS LocalAsciiToFixed consumes a decimal mantissa, not its exponent. */
static dword LocalAsciiToFixed(char *p, char **end)
{
    double value = 0, place = .1;
    while(isdigit((unsigned char)*p)) value = value * 10 + (*p++ - '0');
    if(*p == '.') {
        p++;
        while(isdigit((unsigned char)*p)) {
            value += (*p++ - '0') * place;
            place /= 10;
        }
    }
    *end = p;
    return value >= 32768 ? 0xffffffffU : (dword)(value * 65536 + .5);
}
typedef struct { word XYS_width, XYS_height; } XYSize;
typedef struct {
    struct { word WBF_frac, WBF_int; } VTCA_pointSize;
    word VTCA_fontID, VTCA_extendedStyles;
} VisTextCharAttr;
typedef struct {
    NameToken name, imageURL, imageALT, usemap, svgFile;
    word flags, pos, len, formElementIndex, hspace, vspace;
    XYSize size, HID_size;
    struct { int P_x, P_y; } HID_pos;
} HTMLimageData;
typedef struct { word HIGV_imageIndex; } HTMLimageGraphicVariable;
typedef struct {
    XYSize VTG_size;
    word VTG_type;
    struct { struct {
        word VTGV_manufacturerID, VTGV_type, VTGV_privateData[4];
    } VTGD_variable; } VTG_data;
} VisTextGraphic;
static struct { word TTBH_graphicElements, TTBH_graphicRuns; } header, *ttbh = &header;
static struct { word HCD_hardMinWidth, HCD_minHeight; } insertCellData;
static VisTextCharAttr currentCS;
static HTMLimageData captured;
static VisTextGraphic graphic;
#define TAG_FLUSH_TEXT 1
#define CA_NULL_ELEMENT 0xffff
#define DEFAULT_IMAGE_LIMIT 200
#define C_GRAPHIC 1
#define C_SUBSTITUTE 1
#define VTES_NOWRAP 1
#define FID_DTC_URW_MONO 1
#define HTML_IDF_INLINE_SVG 16
#define HTML_IDF_PICTURE_FALLBACK 32
#define HTML_FI_INLINE_SVG 1
static struct { struct { word HTBHO_fileInfo; } HTBH_other; } hheader, *htbh = &hheader;
#define HTML_IDF_SUBMIT 2
#define HTML_IDF_ISMAP 4
#define HTML_LEN_GET_UNIT(n) ((n) & 0xc000)
#define HTML_LEN_PIXEL 0
#define DEFAULT_IMAGE_HEIGHT 20
#define DEFAULT_IMAGE_WIDTH 20
#define VTGT_VARIABLE 1
#define HTML_VARGRAPH_MFGID 1
#define HTML_VARGRAPH_TYPE_IMAGE 1
#define IMAGE_HEIGHT_FUDGE_FACTOR 2
#define HTA_IMAGE_ARRAY 1
static Boolean InitFileReadInteger(char *category, char *key, word *v)
{ (void)category; (void)key; (void)v; return TRUE; }
static void AddParaCond(void) {}
static void GetCharacterBase(VisTextCharAttr *a) { memset(a, 0, sizeof(*a)); }
static word AddText(VisTextCharAttr *a, char *s) { (void)a; (void)s; return 0; }
static word ParseMultiLength(char *s, word unused) { (void)unused; return (word)atoi(s); }
static word AppendToHypertextArray(word type, HTMLimageData *id)
{ (void)type; captured = *id; return G_imageCount; }
static void AddAttrRun(word elements, word runs, VisTextGraphic *g, word pos)
{ (void)elements; (void)runs; (void)pos; graphic = *g; }

#define SPEC_TABLE 1
#define SPEC_TR 2
#define SPEC_TD 3
#define SPEC_IMG 4
#define TAG_IS_PAR_STYLE 1
#define HTML_MAXTABLE 16
#define HTML_EVENT_OBJECT_IMAGE 1
#define OptrToChunk(v) 0
#define LMemDeref(v) ((void *)(v))
typedef struct { char *name; word ca, pa, spec, flags; } HTMLStylesTable;
typedef struct { struct { word HTD_width, HTD_cellpadding, HTD_cellspacing; } tableData; } TableStackElement;
static TableStackElement tables[HTML_MAXTABLE + 1];
optr tableStackO = (optr)tables;
static word tableDepth, eventCalls;
static int STRCMPISB(char *a, char *b)
{
    while(*a && *b && tolower((unsigned char)*a) == tolower((unsigned char)*b)) { a++; b++; }
    return *a || *b;
}
static optr IDupLMem(optr params) { return params; }
static word EnclosingCount(word spec, void *unused) { (void)spec; (void)unused; return tableDepth; }
static void ParseEvents(optr params, word type, word index)
{
    (void)type; (void)index;
    if(GetParamValue(params, "ONLOAD")) eventCalls++;
}
void Open_IMG(TagOpenArguments *arg);
static void OpenTag(word spec, HTMLStylesTable *style, optr params)
{
    TagOpenArguments arg;
    (void)style;
    if(spec == SPEC_TABLE) tableDepth++;
    if(spec == SPEC_IMG) { arg.spec = spec; arg.paramArray = params; Open_IMG(&arg); }
}
static void CloseTag(word spec, HTMLStylesTable *style, optr params)
{
    (void)style; (void)params;
    if(spec == SPEC_TABLE) tableDepth--;
}
C
$harness .= function($browser, 'FrameImageMimeSupported') . "\n";
for my $name (qw(ParseSrcsetDensity SelectSrcsetCandidate ClearPicture
                 PictureBeforeTag PictureText TakePictureSource
                 PictureMediaMatches Open_PICTURE Open_SOURCE CanParseImage
                 ParseImage Open_IMG)) {
    $harness .= function($source, $name) . "\n";
}
$harness =~ s/\@ifdef (\w+)/#ifdef $1/g;
$harness =~ s/\@else/#else/g;
$harness =~ s/\@endif/#endif/g;
$harness =~ s/static insideHere/static int insideHere/g;
$harness =~ s{//[^\n]*}{}g;
$harness .= <<'C';

static void releaseImage(void)
{
    if(captured.name) NamePoolReleaseToken(NamePool, captured.name);
    if(captured.imageURL) NamePoolReleaseToken(NamePool, captured.imageURL);
    if(captured.imageALT) NamePoolReleaseToken(NamePool, captured.imageALT);
    if(captured.usemap) NamePoolReleaseToken(NamePool, captured.usemap);
    if(captured.svgFile && (captured.flags & HTML_IDF_PICTURE_FALLBACK))
        NamePoolReleaseToken(NamePool, captured.svgFile);
    memset(&captured, 0, sizeof(captured));
}
static void checkLeaks(void)
{
    unsigned i;
    ClearPicture();
    for(i = 1; i <= nextToken; i++) assert(!refs[i]);
    nextToken = 0;
}
static void candidate(char *set, char *src, word width, const char *expected)
{
    word n = 999;
    char *p = SelectSrcsetCandidate(set, src, width, &n);
    if(expected) assert(p && n == strlen(expected) && !memcmp(p, expected, n));
    else assert(!p && !n);
}
static void image(Param *params, const char *expected)
{
    TagOpenArguments arg;
    word count, events;
    arg.paramArray = params; arg.spec = SPEC_IMG;
    count = G_imageCount; events = eventCalls;
    Open_IMG(&arg);
    assert(G_imageCount == count + 1 && !tableDepth);
    assert(!strcmp(names[captured.imageURL], expected));
    assert(!imageSourceState.inPicture && !imageSourceState.pictureSource);
    assert(!(captured.flags & HTML_IDF_INLINE_SVG));
    if(captured.flags & HTML_IDF_PICTURE_FALLBACK) {
        assert(captured.svgFile);
        if(!GetParamValue(params, "SRCSET"))
            assert(!strcmp(names[captured.svgFile], GetParamValue(params, "SRC")));
    } else {
        assert(!captured.svgFile);
    }
    if(GetParamValue(params, "WIDTH")) {
        assert(captured.size.XYS_width == 40 && captured.size.XYS_height == 20);
        assert(captured.hspace == 2 && captured.vspace == 3);
        assert(!strcmp(names[captured.imageALT], "Selected picture"));
        assert(!strcmp(names[captured.usemap], "#map"));
        assert(captured.flags & HTML_IDF_ISMAP);
        assert(graphic.VTG_size.XYS_width == 44);
        assert(eventCalls == events + 1);
    }
    releaseImage();
}
static void unitChecks(void)
{
    TagOpenArguments arg;
    NameToken token;
    char transientURL[] = "selected";
    Param offered[] = {{"SRCSET", 0}, {0, 0}};
    Param typed[] = {{"TYPE", "image/jpeg"}, {"SRCSET", "typed"}, {0, 0}};
    Param fallback[] = {{"SRC", "fallback"}, {0, 0}};
    Param aligned[] = {{"SRC", "fallback"}, {"ALIGN", "left"},
        {"WIDTH", "40"}, {"HEIGHT", "20"}, {"HSPACE", "2"}, {"VSPACE", "3"},
        {"ALT", "Selected picture"}, {"USEMAP", "#map"}, {"ISMAP", ""},
        {"ONLOAD", "loaded()"}, {0, 0}};
    char mimeLong[140];
    Param news[8][4] = {
        {{"TYPE", "image/webp"}, {"MEDIA", "(max-width: 420px)"}, {"SRCSET", "news.webp?width=640"}, {0, 0}},
        {{"TYPE", "image/webp"}, {"MEDIA", "(max-width: 767px)"}, {"SRCSET", "news.webp?width=768"}, {0, 0}},
        {{"TYPE", "image/webp"}, {"MEDIA", "(max-width: 1023px)"}, {"SRCSET", "news.webp?width=960"}, {0, 0}},
        {{"TYPE", "image/webp"}, {"MEDIA", "(min-width: 1024px)"}, {"SRCSET", "news.webp?width=1280"}, {0, 0}},
        {{"TYPE", "image/jpeg"}, {"MEDIA", "(max-width: 420px)"}, {"SRCSET", "news.jpg?width=640"}, {0, 0}},
        {{"TYPE", "image/jpeg"}, {"MEDIA", "(max-width: 767px)"}, {"SRCSET", "news.jpg?width=768"}, {0, 0}},
        {{"TYPE", "image/jpeg"}, {"MEDIA", "(max-width: 1023px)"}, {"SRCSET", "news.jpg?width=960"}, {0, 0}},
        {{"TYPE", "image/jpeg"}, {"MEDIA", "(min-width: 1024px)"}, {"SRCSET", "news.jpg?width=1280"}, {0, 0}}
    };
    Param newsImage[] = {{"SRC", "news.jpg?width=1280"}, {0, 0}};
    word widths[] = {0, 400, 640, 800, 1024};
    word i, j, webp;
    const char *expected[2][5] = {
        {"news.jpg?width=1280", "news.jpg?width=640", "news.jpg?width=768", "news.jpg?width=960", "news.jpg?width=1280"},
        {"news.jpg?width=1280", "news.webp?width=640", "news.webp?width=768", "news.webp?width=960", "news.webp?width=1280"}
    };
    Param smallSet[] = {{"SRCSET", "large 1280w, small 320w, medium 640w"},
        {"MEDIA", "(min-width: 400px)"}, {0, 0}};
    Param later[] = {{"SRCSET", "later 100w"}, {0, 0}};
    Param ownSet[] = {{"SRC", "fallback"},
        {"SRCSET", "large 1280w, small 320w, medium 640w"}, {0, 0}};
    Param invalidSet[] = {{"SRC", "fallback"}, {"SRCSET", "invalid 0w"}, {0, 0}};
    Param noSrc[] = {{"ALT", "Source supplies the URL"}, {0, 0}};
    offered[0].value = transientURL;
    arg.paramArray = offered;
    assert(sizeof(word) == 2 && sizeof(dword) == 4);
    candidate("large 1280w, small 320w, medium 640w", "src", 400, HTML_IMAGE_SELECT_SMALLEST ? "small" : "medium");
    candidate("large 1280w, small 320w, medium 640w", "src", 640, HTML_IMAGE_SELECT_SMALLEST ? "small" : "medium");
    candidate("small 320w, medium 640w, large 1280w", "src", 2000, HTML_IMAGE_SELECT_SMALLEST ? "small" : "large");
    candidate("large 1280w, small 320w", "src", 0, "small");
    candidate("first 640w, second 640w", 0, 640, "first");
    candidate("  bare?width=640\t", "src", 640, "bare?width=640");
    candidate("bad 0w, bad -1w, bad 4294967296w, bad 12ww", 0, 640, 0);
    candidate("huge 4294967295w, small 640w", 0, 65535, HTML_IMAGE_SELECT_SMALLEST ? "small" : "huge");
    candidate("density .5x, width 640w", "src", 400, "width");
    candidate("two 2x, low .75x", "src", 400, "low");
    candidate("two 2x", "src", 400, "src");
    candidate("two 2x, one 1x", "src", 400, "one");
    candidate("bad 1.x, bad 0x", 0, 400, 0);
    candidate("low .5e0x, two 2x", 0, 400, "low");
    assert(PictureMediaMatches(0, 0) && PictureMediaMatches("", 0));
    assert(PictureMediaMatches(" ( MAX-width : 420 PX ) \t", 420));
    assert(!PictureMediaMatches("(max-width:420px)", 421));
    assert(PictureMediaMatches("(min-width:1024px)", 1024));
    assert(!PictureMediaMatches("(min-width:1024px)", 1023));
    assert(!PictureMediaMatches("(max-width:420px)", 0));
    assert(!PictureMediaMatches("(min-width:4294967296px)", 400));
    assert(PictureMediaMatches("(max-width:4294967295px)", 400));
    assert(!PictureMediaMatches("(max-width:4px) junk", 400));
    assert(!PictureMediaMatches("(max-width:4px) and (min-width:0px)", 400));
    assert(!PictureMediaMatches("(width:400px)", 400));
    assert(!PictureMediaMatches("(max-width:-1px)", 400));
    assert(!PictureMediaMatches("(", 400));
    assert(!PictureMediaMatches("(max-width", 400));
    assert(!PictureMediaMatches("(max-width:", 400));
    assert(!PictureMediaMatches("(max-width:4p", 400));
    assert(!PictureMediaMatches("(max-width:4px", 400));
    assert(FrameImageMimeSupported(" Image/JPEG \t"));
    assert(FrameImageMimeSupported("image/png"));
    assert(FrameImageMimeSupported("image/gif"));
    assert(FrameImageMimeSupported("image/svg+xml"));
    assert(!FrameImageMimeSupported("image/webp"));
    assert(!FrameImageMimeSupported("text/plain"));
    assert(!FrameImageMimeSupported("image/jpeg; charset=x"));
    memset(mimeLong, 'x', sizeof(mimeLong)); mimeLong[139] = 0;
    assert(!FrameImageMimeSupported(mimeLong));
    imageSourceState.mimeSupported = FrameImageMimeSupported;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    token = imageSourceState.pictureSource;
    assert(token && refs[token] == 1 && !G_imageCount);
    strcpy(transientURL, "changed");
    PictureBeforeTag("!", TRUE); PictureText(" \t\r\n");
    PictureBeforeTag("source", TRUE); PictureBeforeTag("ImG", TRUE);
    assert(imageSourceState.pictureSource == token);
    image(fallback, "selected"); assert(!refs[token]);
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    PictureBeforeTag("div", TRUE); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    PictureText("unexpected"); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    Open_PICTURE(&arg); assert(!imageSourceState.inPicture); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    currentFlags = TAG_FLUSH_TEXT;
    assert(ParseImage(fallback, CA_NULL_ELEMENT, TRUE, FALSE) == CA_NULL_ELEMENT);
    assert(!imageSourceState.inPicture && !imageSourceState.pictureSource);
    currentFlags = 0; checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    G_imageLimit = G_imageCount;
    assert(ParseImage(fallback, CA_NULL_ELEMENT, TRUE, FALSE) == CA_NULL_ELEMENT);
    assert(!imageSourceState.inPicture && !imageSourceState.pictureSource);
    G_imageLimit = 200; checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    token = imageSourceState.pictureSource;
    assert(ParseImage(fallback, 0, FALSE, FALSE) != CA_NULL_ELEMENT);
    assert(imageSourceState.pictureSource == token); releaseImage();
    assert(ParseImage(fallback, CA_NULL_ELEMENT, TRUE, TRUE) != CA_NULL_ELEMENT);
    assert(imageSourceState.pictureSource == token);
    assert((captured.flags & HTML_IDF_INLINE_SVG) &&
           !(captured.flags & HTML_IDF_PICTURE_FALLBACK));
    releaseImage();
    ClearPicture(); assert(!refs[token]); checkLeaks();
    imageSourceState.mimeSupported = 0;
    arg.paramArray = typed;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    assert(!imageSourceState.pictureSource); checkLeaks();
    arg.paramArray = offered;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    image(aligned, "changed"); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    arg.paramArray = aligned; arg.spec = SPEC_IMG;
    tableDepth = HTML_MAXTABLE;
    Open_IMG(&arg);
    assert(!strcmp(names[captured.imageURL], "changed"));
    assert(!imageSourceState.inPicture && !imageSourceState.pictureSource);
    assert(tableDepth == HTML_MAXTABLE);
    tableDepth = 0; releaseImage(); checkLeaks();
    imageSourceState.viewportWidth = 640;
    image(ownSet, HTML_IMAGE_SELECT_SMALLEST ? "small" : "medium");
    image(invalidSet, "fallback"); checkLeaks();
    arg.paramArray = offered;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    image(noSrc, "changed"); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    ParseImage(ownSet, CA_NULL_ELEMENT, TRUE, NAME_POOL_NONE);
    assert(!strcmp(names[captured.imageURL], "changed"));
    assert(captured.flags & HTML_IDF_PICTURE_FALLBACK);
    assert(!strcmp(names[captured.svgFile], HTML_IMAGE_SELECT_SMALLEST ? "small" : "medium"));
    releaseImage(); checkLeaks();
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    ParseImage(invalidSet, CA_NULL_ELEMENT, TRUE, NAME_POOL_NONE);
    assert(!strcmp(names[captured.imageURL], "changed"));
    assert(!strcmp(names[captured.svgFile], "fallback"));
    releaseImage(); checkLeaks();
    arg.paramArray = smallSet;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    arg.paramArray = later; Open_SOURCE(&arg);
    image(fallback, HTML_IMAGE_SELECT_SMALLEST ? "small" : "medium");
    checkLeaks();
    imageSourceState.viewportWidth = 399;
    arg.paramArray = smallSet;
    Open_PICTURE(&arg); Open_SOURCE(&arg);
    assert(!imageSourceState.pictureSource);
    arg.paramArray = later; Open_SOURCE(&arg);
    image(fallback, "later"); checkLeaks();
    /* Source ordering and breakpoints from tagesschau.de's top teaser. */
    imageSourceState.mimeSupported = FrameImageMimeSupported;
    for(webp = 0; webp < 2; webp++) {
        supportWebp = webp;
        for(i = 0; i < 5; i++) {
            imageSourceState.viewportWidth = widths[i];
            Open_PICTURE(&arg);
            for(j = 0; j < 8; j++) {
                arg.paramArray = news[j];
                Open_SOURCE(&arg);
            }
            image(newsImage, expected[webp][i]);
            checkLeaks();
        }
    }
}

int main(void)
{
    unitChecks();
    puts(HTML_IMAGE_SELECT_SMALLEST ? "smallest-source checks passed" :
                                     "viewport-source checks passed");
    return 0;
}
C
# Verify the GEOS-only handoff and parser cleanup boundaries.
my $named = function($parser, 'HandleNamedTag');
$named =~ /PictureBeforeTag\(tag, openTag\)/ or die "Missing tag hook\n";
my $core = function($parser, 'ParseHTMLFileWithImageSources');
$core =~ /viewportWidth = imageSourcesP->viewportWidth/ or die "Missing width snapshot\n";
$core =~ /PictureText\(buf\)/ or die "Missing text hook\n";
$core =~ /ClearPicture\(\);[^;]*FinishTransferItem\(\)/s or die "Late token release\n";
$core =~ /cleanupExit:\s*ClearPicture\(\)/ or die "Missing failure cleanup\n";
my $tags = read_source("$FindBin::Bin/../htmlpars/parstags.goc");
function($tags, 'OpenTag') !~ /PictureBeforeTag/ or die "Synthetic tag hook\n";
function($tags, 'CloseTag') =~ /if\(spec == SPEC_PICTURE\)\s*ClearPicture\(\)/
    or die "Missing picture close hook\n";
my $frame = function($browser, 'ParseFrameHTML');
$frame =~ /MSG_URL_TEXT_GET_IMAGE_SOURCE_WIDTH/ or die "Missing width handoff\n";
$frame !~ /MSG_HTML_TEXT_GET_VIEW_OBJ|MSG_GEN_VIEW_GET_VISIBLE_RECT/ or die "View query\n";
my $text = read_source("$root/Appl/Breadbox/BbxBrow/urltext/URLTEXT.goc");
$text =~ /\@method URLTextClass, MSG_URL_TEXT_GET_IMAGE_SOURCE_WIDTH\n\{(.*?)^}/ms
    or die "Missing width getter\n";
my $getter = $1;
$getter =~ /HTS_VIEW_NOT_OPENED.*?\? 0 : textP->HTI_viewWidth/s or die "Unguarded width\n";
my $tmp = tempdir(CLEANUP => 1);
for my $policy ($default, 1 - $default) {
    open my $file, '>', "$tmp/check.c" or die $!;
    print $file "#define HTML_IMAGE_SELECT_SMALLEST $policy\n", $harness;
    close $file or die $!;
    system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror',
           '-Wno-unused-parameter', "$tmp/check.c", '-o', "$tmp/check") == 0
        or die "Host compilation failed\n";
    system("$tmp/check") == 0 or die "Image-source checks failed\n";
}
