#!/usr/bin/env perl
# Host-only check: perl check_cookie_parse.pl [pre-change git revision]
# Extract production code and stub GEOS storage. ASAN=1 enables address checks.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

my $file = 'Library/Cookies/Cookies.goc';
open my $input, '<', "$FindBin::Bin/../Cookies.goc" or die "$!\n";
my $source = do { local $/; <$input> };
close $input;
$source =~ s/\r\n/\n/g;
my $old;
if (@ARGV) {
    die "Usage: $0 [pre-change git revision]\n" unless @ARGV == 1;
    open my $git, '-|', 'git', '-C', "$FindBin::Bin/../../..",
        'show', "$ARGV[0]:$file" or die "$!\n";
    $old = do { local $/; <$git> };
    close $git or die "Cannot read baseline revision\n";
    $old =~ s/\r\n/\n/g;
}

sub function {
    my ($text, $name) = @_;
    $text =~ /^((?:static [^\n]+\n|void (?:EXPORT )?)\Q$name\E\s*\(.*?^\})/msg
        or die "Cannot extract $name\n";
    return $1;
}

sub path_function {
    my ($text, $name) = @_;
    my $set = function($text, 'CookieSet');
    $set =~ /(    if \(!path\b.*?)(?=    if \(!domain\))/s
        or die "Cannot extract default path\n";
    return "static void $name(char *anchorPath, const char *path)\n" .
        "{ CookieStruct result, *cp = &result;\n" .
        "char *q, *s, saveChar1, saveChar2;\n$1" .
        "strcpy(storedPath, cp->CS_path);\n}\n";
}

my $dir = tempdir(CLEANUP => 1);
open my $c, '>', "$dir/check.c" or die "$!\n";
print {$c} <<'C';
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#define _pascal
#define EXPORT
#define TRUE 1
#define FALSE 0
#define C_NULL '\0'
#define C_SPACE ' '
#define STRLENSB strlen
#define STRCHRSB strchr
#define HLMALLOCSTR(dest, src) strcpy(dest, src)
#define HLMALLOCSTRDBCS(dest, src) strcpy(dest, src)
typedef int Boolean;
typedef unsigned short word;
typedef char TCHAR;
typedef struct { char CS_path[256]; } CookieStruct;
static int cookieList = 1, calls, gotSecure, failures, parserChecks, pathChecks;
static const char *nullString = "";
static const char *gotName, *gotValue, *gotExpires, *gotPath, *gotDomain;
static char storedPath[256];
static void CookieSet(char *anchorPath, char *anchorHost, const char *name,
    const char *value, const char *expires, const char *path,
    const char *domain, Boolean secure)
{
    (void)anchorPath;
    (void)anchorHost;
    calls++;
    gotName = name;
    gotValue = value;
    gotExpires = expires;
    gotPath = path;
    gotDomain = domain;
    gotSecure = secure;
}
C
$source =~ m{(/\* Delimiters for HTScanCookie.*?)(?=#define TOLOWER)}s
    or die "Cannot extract scanner definitions\n";
print {$c} $1;
for my $name (qw(HTScanSearchReservedWord IsCookieDelimiter HTScanCookie StripTrailingSpaces)) {
    my $body = function($source, $name);
    die "Baseline helper $name differs\n"
        if defined($old) && function($old, $name) ne $body;
    print {$c} "$body\n";
}
print {$c} function($source, 'CookieParse'), "\n", path_function($source, 'DefaultPath');
if (defined $old) {
    my $parser = function($old, 'CookieParse');
    $parser =~ s/\bCookieParse\b/CookieParseOld/;
    print {$c} "#define COMPARE\n$parser\n", path_function($old, 'DefaultPathOld');
}
print {$c} do { local $/; <DATA> };
close $c or die "$!\n";
my @sanitize = $ENV{ASAN} ? ('-fsanitize=address,undefined') :
    ('-fsanitize=undefined', '-fsanitize-undefined-trap-on-error');
system($ENV{CC} || 'cc', '-std=c89', '-Wall', '-Wextra', '-Werror', '-g',
    @sanitize, '-fno-omit-frame-pointer',
    "$dir/check.c", '-o', "$dir/check") == 0 or die "Compile failed\n";
system("$dir/check") == 0 or die "Cookie checks failed\n";

__DATA__
static int same(const char *a, const char *b)
{
    return a && b ? strcmp(a, b) == 0 : a == b;
}

static void checkParser(const char *header, const char *name, const char *value,
    const char *expires, const char *path, const char *domain, int secure,
    int fixed)
{
    char text[256];
    int baseline, matches;
    for (baseline = 0; baseline < 2; baseline++) {
#ifndef COMPARE
        if (baseline) break;
#endif
        strcpy(text, header);
        calls = gotSecure = 0;
        gotName = gotValue = gotExpires = gotPath = gotDomain = NULL;
#ifdef COMPARE
        if (baseline) CookieParseOld("/dir/page", "example.com", text);
        else
#endif
        CookieParse("/dir/page", "example.com", text);
        matches = calls == (name != NULL) && same(gotName, name) &&
            same(gotValue, value) && same(gotExpires, expires) &&
            same(gotPath, path) && same(gotDomain, domain) && gotSecure == secure;
        if (matches != !(baseline && fixed)) {
            fprintf(stderr, "%s parser mismatch: %s\n",
                baseline ? "Baseline" : "Current", header);
            failures++;
        }
    }
    parserChecks++;
}

static void checkPath(const char *request, const char *path,
    const char *expected, int fixed)
{
    char text[256];
    int baseline, matches;
    for (baseline = 0; baseline < 2; baseline++) {
#ifndef COMPARE
        if (baseline) break;
#endif
        strcpy(text, request);
#ifdef COMPARE
        if (baseline) DefaultPathOld(text, path);
        else
#endif
        DefaultPath(text, path);
        matches = strcmp(storedPath, expected) == 0;
        if (matches != !(baseline && fixed) || strcmp(text, request)) {
            fprintf(stderr, "%s path mismatch or modified request: %s\n",
                baseline ? "Baseline" : "Current", request);
            failures++;
        }
    }
    pathChecks++;
}

int main(void)
{
    unsigned long seed = 1;
    int i, j, length;
    char fuzz[128], *textP;
    const char *alphabet = "nv=;/ ?\t\r\nPathSecureDomainExpires0123";
#define P checkParser
    P("n=v", "n", "v", NULL, NULL, NULL, 0, 0);
    P("n=", "n", "", NULL, NULL, NULL, 0, 0);
    P("n=; Path=/", "n", "", NULL, "/", NULL, 0, 0);
    P("n=a=b==", "n", "a=b==", NULL, NULL, NULL, 0, 0);
    P("n=\"quoted=value\"; Path=/", "n", "\"quoted=value\"", NULL, "/", NULL, 0, 0);
    P("n=v;", "n", "v", NULL, NULL, NULL, 0, 0);
    P("n=v; Path=/dir", "n", "v", NULL, "/dir", NULL, 0, 0);
    P("n=v; Path=", "n", "v", NULL, "", NULL, 0, 0);
    P("n=v; Domain=example.com", "n", "v", NULL, NULL, "example.com", 0, 0);
    P("n=v; Domain=", "n", "v", NULL, NULL, "", 0, 0);
    P("n=v; Secure", "n", "v", NULL, NULL, NULL, 1, 0);
    P("n=v; Expires=Wed, 09 Jun 2038 10:18:14 GMT; Path=/; Secure",
        "n", "v", "Wed, 09 Jun 2038 10:18:14 GMT", "/", NULL, 1, 0);
    P("n=v; Expires=", "n", "v", "", NULL, NULL, 0, 0);
    P("n=v; Path=/first; Path=/last", "n", "v", NULL, "/last", NULL, 0, 0);
    P("n=v; path=/; domain=.example.com; secure", "n", "v", NULL, "/", ".example.com", 1, 0);
    P("n=v; Path= /dir  ; Domain= example.com  ", "n", "v", NULL, "/dir", "example.com", 0, 0);
    P("n=v; Unknown=x", "n", "v", NULL, NULL, NULL, 0, 0);
    P("n=v; Max-Age=3600", "n", "v", NULL, NULL, NULL, 0, 0);
    P("Path=Secure", "Path", "Secure", NULL, NULL, NULL, 0, 0);
    P("", NULL, NULL, NULL, NULL, NULL, 0, 0);
    P("=", NULL, NULL, NULL, NULL, NULL, 0, 0);
    P("broken", "broken", "", NULL, NULL, NULL, 0, 0);
    P("n=v; SameSite=Lax; Path=/", "n", "v", NULL, "/", NULL, 0, 1);
    P("n=v; HttpOnly; Secure", "n", "v", NULL, NULL, NULL, 1, 1);
    P("n=v; Secure; Path=/", "n", "v", NULL, "/", NULL, 1, 1);
    P("n=v; Max-Age=3600; Domain=example.com; Path=/; Secure",
        "n", "v", NULL, "/", "example.com", 1, 1);
    P("n=v; HttpOnly; SameSite=None; Secure; Path=/; Domain=example.com",
        "n", "v", NULL, "/", "example.com", 1, 1);
    P("n=v; pAtH = /dir ; DOMAIN = example.com ; Secure",
        "n", "v", NULL, "/dir", "example.com", 1, 1);
    P("n=v;;; Path=/", "n", "v", NULL, "/", NULL, 0, 1);
    P("n=v; Unknown=a=b; Path=/", "n", "v", NULL, "/", NULL, 0, 1);
#define D checkPath
    D("/", NULL, "/", 0);
    D("/dir/page", NULL, "/dir", 0);
    D("/dir/", NULL, "/dir", 0);
    D("/dir/sub/page", NULL, "/dir/sub", 0);
    D("/dir/page?next=/other/file", NULL, "/dir", 0);
    D("/dir/page?x=1", NULL, "/dir", 0);
    D("/page", "/", "/", 0);
    D("/page?x=/other", "/custom", "/custom", 0);
    D("/dir/page", "/custom/", "/custom/", 0);
    D("/page", NULL, "/", 1);
    D("/page?next=/other/file", NULL, "/", 1);
    D("/?next=/other/file", NULL, "/", 1);
    D("", NULL, "/", 1);
    D("page", NULL, "/", 1);
    D("/dir/page", "", "/dir", 1);
    D("/dir/page", "relative", "/dir", 1);
    D("/page", "relative", "/", 1);
    D("/dir/page?next=/other/file", "", "/dir", 1);
    cookieList = 0;
    P("n=v; Path=/", NULL, NULL, NULL, NULL, NULL, 0, 0);
    cookieList = 1;
    /* Place each NUL at the buffer end so ASan detects reads past it. */
    for (i = 0; i < 10000; i++) {
        seed = (seed * 1664525UL + 1013904223UL) & 0xffffffffUL;
        length = seed % sizeof(fuzz);
        textP = fuzz + sizeof(fuzz) - length - 1;
        for (j = 0; j < length; j++) {
            seed = (seed * 1664525UL + 1013904223UL) & 0xffffffffUL;
            textP[j] = alphabet[seed % strlen(alphabet)];
        }
        textP[length] = '\0';
        CookieParse("/dir/page", "example.com", textP);
    }
    printf("%d parser cases, %d path cases, 10000 malformed inputs: %s",
        parserChecks, pathChecks, failures ? "FAIL" : "PASS");
#ifdef COMPARE
    printf(" (baseline compatibility and intended differences checked)");
#endif
    puts("");
    return failures != 0;
}
