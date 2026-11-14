#!/usr/bin/env perl
# Run actual parser and option handlers with host GEOS shims, not GEOS itself.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $file, '<:raw', $_[0] or die "$!: $_[0]";
    local $/;
    my $text = <$file>;
    $text =~ s/\r\n/\n/g;
    return $text;
}
sub function {
    my ($text, $name) = @_;
    $text =~ /^((?:int|void)\s+(?:LOCAL\s+|_pascal\s+)?\Q$name\E\b[^;{]*\{.*?^})/ms
        or die "Cannot find $name\n";
    return "$1\n";
}
sub host_c {
    my ($text) = @_;
    $text =~ s/^\@(?:ifdef|ifndef|if|else|endif)\b/#$&/mg;
    $text =~ s/#\@/#/g;
    $text =~ s/\@(\w+)/$1/g;
    $text =~ s{//[^\n]*}{}g; # Legacy GEOS sources contain C++ comments.
    return $text;
}
my $root = "$FindBin::Bin/../../../..";
my $parser = read_source("$FindBin::Bin/../htmlpars/htmlpars.goc");
my $tags = read_source("$FindBin::Bin/../htmlpars/opentags.goc");
my $styles = read_source("$FindBin::Bin/../htmlpars/parstags.goc");
my $internal = read_source("$FindBin::Bin/../internal.h");
$internal =~ s{/\*.*?\*/}{}gs;
my $browser = "$root/Appl/Breadbox/BbxBrow";
my $ui = read_source("$browser/UI/menuView.goh");
my $init = read_source("$browser/init/INIT.goc");
my $header = read_source("$browser/htmlview.goh");
my $rare = read_source("$browser/htmlview/UIRare.goc");

die "Toggle is not persisted with HTML settings\n" unless
    $ui =~ /\@object GenBooleanGroupClass HTMLSettingsBoolGroup.*?ATTR_GEN_INIT_FILE_KEY = "htmlSettings";.*?\@ignoreNoScript/s;
die "Wrong toggle identifier\n" unless
    $ui =~ /\@object GenBooleanClass ignoreNoScript.*?GBI_identifier = HTML_IGNORE_NOSCRIPT;/s;
die "Missing startup visibility update\n" unless
    $init =~ /MSG_HMLVP_HTML_OPTIONS_CHANGED\(form, 0, 0\)/;
die "Existing message slot or appended regular-build slot changed\n" unless
    $header =~ /\@if defined\(JAVASCRIPT_SUPPORT\) \|\| defined\(COMPILE_OPTION_AUTO_BROWSE\)\n  \@message \(GEN_BOOLEAN_GROUP_APPLY_MSG\) MSG_HMLVP_HTML_OPTIONS_CHANGED;\n\@endif/ &&
    $header =~ /MSG_HMLVP_DEFAULT_FONT_CHANGED;\n\@if !defined\(JAVASCRIPT_SUPPORT\) && !defined\(COMPILE_OPTION_AUTO_BROWSE\).*?MSG_HMLVP_HTML_OPTIONS_CHANGED;\n\@endif\n\@endc;/s;
for my $options ('options.goh', 'prodbbx.goh') {
    die "Ignore option must default off\n" if
        read_source("$browser/$options") =~ /#\s*define DEFAULT_HTML_OPTIONS[^\n]*(?:\\\n[^\n]*)*HTML_IGNORE_NOSCRIPT/;
}

my $tmp = tempdir(CLEANUP => 1);
open my $out, '>', "$tmp/check.c" or die $!;
print $out <<'C';
#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
typedef unsigned short word;
typedef short sword;
typedef unsigned char byte;
typedef int Boolean;
typedef void *optr, *MemHandle;
typedef word EventHandle, ChunkHandle;
#define LOCAL
#define _pascal
#define TRUE 1
#define FALSE 0
#define NullOptr ((void *)0)
#define CA_NULL_ELEMENT 65535
#define HTML_MAX_BUF 8192
#define HTML_MAXTAG 20
#define PARSE_BUF_LEN 256
#define HTML_PARAM_TAG_SIZE_LIMIT 12288
#define HTML_ATTRIBUTE_SEEN_BYTES 32
#define HTML_SPECIAL_ENTITY_BASE 10000
#define C_NONBRKSPACE 160
#define HAF_STANDARD_LOCK 0
#define HAF_STANDARD 0
#define HF_DYNAMIC 0
#define MGIT_SIZE 0
#define VTPAA_JUSTIFICATION 3
#define STRCMPISB strcasecmp
#define STRCMPSB strcmp
#define STRLENSB strlen
#define STRCPYSB strcpy
#define STRCATSB strcat
#define OptrToHandle(p) (p)
#define LMemDeref(p) ((void *)(p))
#define MemDeref(p) ((void *)(p))
#define MemLock(p) ((void)(p))
#define MemUnlock(p) ((void)(p))
#define MemFree(p) ((void)(p))
#define LMemFree(p) ((void)(p))
static void *unexpected_alloc(void) { assert(0); return (void *)0; }
#define MemAlloc(a,b,c) unexpected_alloc()
#define MemReAlloc(a,b,c) unexpected_alloc()
#define MemGetInfo(a,b) 0
#define ConstructOptr(a,b) unexpected_alloc()
#define ChunkArrayCreate(a,b,c,d) 0
#define ChunkArrayAppend(a,b) unexpected_alloc()
#define HTMLParameterHeapHasRoom(a,b) 1
#define FindHTMLAttribute(a) CA_NULL_ELEMENT
typedef struct { word dummy; } ChunkArrayHeader;
typedef struct { word PSD_which, PSD_attributes; int PSD_rightMargin,
    PSD_leftMargin, PSD_paraMargin; } ParaStyleDelta;
typedef struct { int dummy; } CharStyleDelta;
typedef struct { int VTPA_rightMargin, VTPA_leftMargin, VTPA_paraMargin;
    word VTPA_attributes; } ParaAttr;
typedef struct { word HE_options; } HTMLextra;
static HTMLextra extra, *HTMLext = &extra;
#if defined(JAVASCRIPT_SUPPORT) || defined(COMPILE_OPTION_AUTO_BROWSE)
#define HTML_SCRIPT_SUPPORT 1
#else
#define HTML_SCRIPT_SUPPORT 0
#endif
C
print $out host_c(read_source("$root/CInclude/htmlopt.h"));
print $out join("\n", $internal =~ /^(#define (?:TAG_|PSD_)\w+[^\n]*)/mg), "\n";
$internal =~ /(typedef enum \{\s*SPEC_NONE,.*?} SpecialTagType;)/s or die "Tag enum\n";
print $out "$1\n";
print $out <<'C';
typedef struct { char name[11]; ChunkHandle ca, pa; SpecialTagType spec;
    word flags; } HTMLStylesTable;
typedef struct { word flags, style; SpecialTagType spec;
    ParaStyleDelta delta; CharStyleDelta charDelta; } TagStackElement;
typedef struct { word flags; } TagOpenArguments;
typedef struct { char name[7]; unsigned num, c; } HTMLEntityTable;
typedef struct { char string[5]; } HTMLEntityString;
static HTMLEntityTable xlateTable[1];
static HTMLEntityString EntityStringArray[1];
static TagStackElement stack[40];
static optr tagStackO = stack;
static word tagStackPtr, currentFlags, ignoreTags;
static CharStyleDelta currentCS, parentCS;
static ParaAttr currentS;
static int c2, lc, G_abortParse, sideEffects, scriptCalls;
static const unsigned char *inputP;
static char output[4096];
static const char endScript[] = "</SCRIPT", endStyle[] = "</STYLE";
static void GetCharacterBase(CharStyleDelta *p) { memset(p, 0, sizeof(*p)); }
static void GetParagraphBase(ParaAttr *p) { memset(p, 0, sizeof(*p)); }
static void ApplyCharacterDelta(CharStyleDelta *p, CharStyleDelta *d)
{ (void)p; (void)d; }
static int HTMLgetc(void)
{ lc = *inputP ? *inputP++ : EOF; return lc == '\n' ? '\r' : lc; }
static int TranslateCharNum(unsigned c) { return (int)c; }
static int TranslateCodeChar(char *p) { return atoi(p + 1); }
static int EnclosingCount(SpecialTagType spec, void *p)
{
    word i; int count = 0; (void)p;
    for(i = 0; i < tagStackPtr; i++) if(stack[i].spec == spec) count++;
    return count;
}
C
print $out function($tags, 'Open_NOSCRIPT'), function($styles, 'GetCurrentStyles');
print $out "static HTMLStylesTable table[] = { {\"\",0,0,SPEC_NONE,0},\n";
my $definitions = read_source("$FindBin::Bin/../htmlsty.goh");
for my $name (qw(NOSCRIPT TEMPLATE APPLET SCRIPT STYLE TITLE TEXTAREA IMG META A P SPAN DIV)) {
    $definitions =~ /\{"\Q$name\E",[^\n]*\n\s*(SPEC_\w+),\s*([^,]+),/s
        or die "Cannot find tag $name\n";
    print $out "{\"$name\",0,0,$1,$2},\n";
}
print $out <<'C';
};
#define HTMLStylesChunk table
static word StyleNum(char *name, SpecialTagType *spec)
{
    word i;
    for(i = 1; i < sizeof(table)/sizeof(table[0]); i++)
        if(!strcasecmp(name, table[i].name)) { *spec = table[i].spec; return i; }
    *spec = SPEC_NONE; return 0;
}
static void OpenTag(word style, HTMLStylesTable *entry, optr params)
{
    TagOpenArguments arg; (void)params;
    arg.flags = entry->flags;
    if(entry->spec == SPEC_NOSCRIPT) Open_NOSCRIPT(&arg);
    entry->flags = arg.flags;
    if(entry->spec == SPEC_IMG || entry->spec == SPEC_META) sideEffects++;
    if((arg.flags & (TAG_IS_PAR_STYLE | TAG_IS_CHAR_STYLE)) && tagStackPtr < 40) {
        stack[tagStackPtr].style = style;
        stack[tagStackPtr].spec = entry->spec;
        stack[tagStackPtr++].flags = arg.flags;
    }
    GetCurrentStyles();
}
static void CloseTag(word style, HTMLStylesTable *entry, optr params)
{
    int i; (void)entry; (void)params;
    for(i = tagStackPtr - 1; i >= 0; i--)
        if(stack[i].style == style) { tagStackPtr = (word)i; break; }
    GetCurrentStyles();
}
static int Open_SCRIPT(optr params, int c);
static int HandleInlineSVG(MemHandle h, char *tag, int c)
{ (void)h; (void)tag; assert(0); return c; }
static void PictureBeforeTag(char *tag, Boolean opening) { (void)tag; (void)opening; }
static void PictureText(char *p) { (void)p; }
static void AddParaCond(void) {}
static void AddText(CharStyleDelta *p, char *text)
{ (void)p; assert(strlen(output) + strlen(text) < sizeof(output)); strcat(output, text); }
C
print $out host_c(function($parser, 'GetText'));
print $out host_c(function($parser, 'SkipRawTextContent'));
print $out <<'C';
static int Open_SCRIPT(optr params, int c)
{ (void)params; scriptCalls++; return SkipRawTextContent(endScript, c); }
static int HandleNamedTag(MemHandle, char *, Boolean, int, Boolean);
C
print $out host_c(function($parser, 'HandleTag')),
           host_c(function($parser, 'HandleNamedTag'));
$parser =~ /(        if\(!ignoreTags && !\(currentFlags & TAG_FLUSH_TEXT\)\)\n        \{.*?\n        \})\n        else/s
    or die "Cannot find output path\n";
my $emit = $1;
print $out <<'C';
static void parse(const char *text, word options)
{
    int c; char buf[PARSE_BUF_LEN + HTML_MAXTAG];
    inputP = (const unsigned char *)text; extra.HE_options = options;
    tagStackPtr = currentFlags = ignoreTags = 0;
    G_abortParse = sideEffects = scriptCalls = 0; c2 = ' '; output[0] = 0;
    memset(stack, 0, sizeof(stack));
    c = HTMLgetc();
    while(c != EOF && !G_abortParse) {
        c = GetText(c, 0, buf, FORM_MODE_HTML, (void *)0, (void *)0);
C
print $out $emit;
print $out <<'C';
        if(c == '<') c = HandleTag((void *)0);
        else if(c != EOF) c = HTMLgetc();
    }
}
static word savedOptions;
static int visible, cleared, reloaded;
#define VUM_DELAYED_VIA_APP_QUEUE 0
#define TO_APP_MODEL 0
static void MSG_GEN_SET_NOT_USABLE(int mode) { (void)mode; visible = 0; }
static void MSG_GEN_SET_USABLE(int mode) { (void)mode; visible = 1; }
static void ObjCacheClear(void) { cleared++; }
static EventHandle MSG_URL_DOCUMENT_RELOAD(void) { return 1; }
static void MSG_META_SEND_CLASSED_EVENT(EventHandle evt, int dest)
{ (void)evt; (void)dest; assert(cleared > reloaded); reloaded++; }
static void options_changed(word selectedBooleans, word indeterminateBooleans,
                            word modifiedBooleans)
C
$rare =~ /\@extern method HTMLVProcessClass, MSG_HMLVP_HTML_OPTIONS_CHANGED\n(\{.*?^})/ms
    or die "Cannot find option handler\n";
my $handler = $1;
$handler =~ s/\@(?:call|send|record)\s+\w+::(\w+)\(/$1(/g;
print $out host_c($handler), "\n";
print $out <<'C';
int main(void)
{
    int fast, script, ignore;
    word options;
    const char *blocks[] = {
        "<noscript>hidden<noscript>inner</noscript>outer<img><meta></noscript>after",
        "<noscript><!-- </noscript><noscript> -->hidden</noscript>after",
        "<noscript><span data-x=\"</noscript><noscript>\">hidden</span></noscript>after",
        "<noscript><span data-x='</noscript>'>hidden</span></noscript>after",
        "<noscript><script>'</noscript><noscript>'</script>hidden</noscript>after",
        "<noscript><style>'</noscript><noscript>'</style>hidden</noscript>after",
        "<noscript><title></noscript><noscript></title>hidden</noscript>after",
        "<noscript><textarea></noscript><noscript></textarea>hidden</noscript>after",
        "<noscript><template><noscript>inner</noscript></template>hidden</noscript>after"
    };
    char deep[512];
    unsigned i;
    for(fast = 0; fast < 2; fast++) {
        parse("<template>hidden<template>inner</template>outer</template>after",
              fast ? HTML_READ_FAST : 0);
        assert(!strcmp(output, "after") && !ignoreTags);
        parse("<applet>hidden<applet>inner</applet>outer</applet>after",
              fast ? HTML_READ_FAST : 0);
        assert(!strcmp(output, "after") && !ignoreTags);
        deep[0] = 0;
        for(i = 0; i < 40; i++) strcat(deep, "<div>");
        strcat(deep, "<noscript>hidden</noscript>after");
        parse(deep, HTML_IGNORE_NOSCRIPT | (fast ? HTML_READ_FAST : 0));
        assert(!strcmp(output, "after") && !ignoreTags);
        for(script = 0; script < 2; script++) for(ignore = 0; ignore < 2; ignore++) {
            options = (fast ? HTML_READ_FAST : 0) | (script ? HTML_JAVASCRIPT : 0) |
                      (ignore ? HTML_IGNORE_NOSCRIPT : 0);
            parse("<noscript>fallback<noscript>inner</noscript>outer</noscript>after", options);
            assert(!strcmp(output, (ignore || (HTML_SCRIPT_SUPPORT && script)) ?
                "after" : "fallbackinnerouterafter"));
            assert(ignoreTags == 0 && !(currentFlags & TAG_CUMULATIVE_FLAGS));
            if(ignore || (HTML_SCRIPT_SUPPORT && script)) {
                for(i = 0; i < sizeof(blocks)/sizeof(blocks[0]); i++) {
                    parse(blocks[i], options);
                    assert(!strcmp(output, "after"));
                    assert(!sideEffects && !scriptCalls && !ignoreTags);
                }
                parse("before<noscript>hidden<noscript>inner</noscript>outer", options);
                assert(!strcmp(output, "before") && ignoreTags == 1);
            }
        }
    }
    parse("", HTML_IGNORE_NOSCRIPT);
    ignoreTags = 0xffff;
    inputP = (const unsigned char *)"noscript>hidden";
    assert(HandleTag((void *)0) == EOF);
    assert(G_abortParse && ignoreTags == 0xffff);
    savedOptions = HTML_IGNORE_NOSCRIPT;
    options_changed(savedOptions, 0, 0);
    assert(visible && !cleared && !reloaded && savedOptions == HTML_IGNORE_NOSCRIPT);
    savedOptions |= HTML_JAVASCRIPT;
    options_changed(savedOptions, 0, HTML_JAVASCRIPT);
    assert(visible == !HTML_SCRIPT_SUPPORT && cleared == 1 && reloaded == 1);
    assert(savedOptions & HTML_IGNORE_NOSCRIPT);
    savedOptions &= ~HTML_JAVASCRIPT;
    options_changed(savedOptions, 0, HTML_JAVASCRIPT);
    assert(visible && cleared == 2 && reloaded == 2);
    options_changed(0, 0, HTML_IGNORE_NOSCRIPT);
    assert(visible && cleared == 3 && reloaded == 3);
    options_changed(HTML_MONOCHROME, 0, HTML_MONOCHROME);
    assert(cleared == 3 && reloaded == 3);
    puts("noscript parser and browser options: PASS");
    return 0;
}
C
close $out or die $!;
for my $defines ([], ['-DJAVASCRIPT_SUPPORT=1'], ['-DCOMPILE_OPTION_AUTO_BROWSE=1'],
                 ['-DJAVASCRIPT_SUPPORT=1', '-DCOMPILE_OPTION_AUTO_BROWSE=1']) {
    system('cc', '-std=c89', '-Werror=implicit-function-declaration', @$defines,
           "$tmp/check.c", '-o', "$tmp/check") == 0 or die "Host compilation failed\n";
    system("$tmp/check") == 0 or die "Noscript check failed\n";
}
