#!/usr/bin/env perl
# Run the actual path-rendering boundary and cleanup with heap checks.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $in, '<:raw', "$FindBin::Bin/../$_[0]" or die $!;
    return do { local $/; <$in> };
}
my $header = read_source('svg.h');
my $parser = read_source('svg.goc');
my $path = read_source('svgPath.goc');
my ($scratch) = $header =~ /(typedef struct _SVGScratch \{.*?\} SVGScratch;)/s;
my ($cleanup) = $parser =~ /(void SvgScratchFree\(.*?)(?=Boolean SvgScratchEnsureTagCapacity)/s;
my ($finish) = $path =~ /(    if \(buildingCompound\) \{.*?\n\})\s*\z/s;
die "Missing scratch code\n" unless $scratch && $cleanup && $finish;

my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/check.c" or die $!;
print {$out} <<'C';
#include <assert.h>
#include <stddef.h>
#include <string.h>
typedef unsigned short word, MemHandle;
typedef int Boolean, SvgScratchFailure;
typedef struct { short x, y; } Point;
typedef struct { long x, y; } SvgWWPoint;
#define SVG_SCRATCH_OK 0
#define LOGF(args) ((void)0)
C
print {$out} $scratch;
print {$out} <<'C';
static unsigned char storage[4][sizeof(SvgWWPoint)];
static int present[4], locked[4], rendered, expectedFill, expectedStroke;
static void MemUnlock(MemHandle h)
{
    assert(h >= 1 && h <= 4 && present[h-1] && locked[h-1]);
    locked[h-1] = 0;
}
static void MemFree(MemHandle h)
{
    assert(h >= 1 && h <= 4 && present[h-1] && !locked[h-1]);
    present[h-1] = 0;
}
static void SvgRendererEndPath(SVGScratch *sc, Boolean fill, Boolean stroke)
{
    int i;
    assert(!sc->tagP && !sc->dbP && !sc->ptsP && !sc->ptsWWFP);
    for (i = 0; i < 4; i++) {
        assert(!locked[i]);
        /* Model output allocations reusing the old unlocked addresses. */
        memset(storage[i], 0xa5, sizeof(storage[i]));
    }
    assert(fill == expectedFill && stroke == expectedStroke);
    rendered++;
}
C
print {$out} $cleanup;
print {$out} <<'C';
static Boolean finish(SVGScratch *sc, Boolean buildingCompound,
                      Boolean valid, Boolean pathHasStroke)
{
    SVGScratch *contextP = sc; /* renderer shim also checks cleared pointers */
    Boolean pathHasFill = 1;
C
print {$out} $finish, "\n";
print {$out} <<'C';
#define INIT(h,p,c,t,i) \
    state = states % 3; states /= 3; \
    present[i] = state != 0; locked[i] = state == 2; \
    sc.h = present[i] ? i+1 : 0; \
    sc.p = locked[i] ? (t *)storage[i] : (void*)0; \
    sc.c = present[i] ? 1 : 0
int main(void)
{
    SVGScratch sc;
    int mask, mode, states, state, i, result;
    for (mask = 0; mask < 81; mask++) {
        for (mode = 0; mode < 16; mode++) {
            memset(&sc, 0, sizeof(sc));
            states = mask;
            INIT(tagH, tagP, tagCapacity, char, 0);
            INIT(dbH, dbP, dbCapacity, char, 1);
            INIT(ptsH, ptsP, ptsCapacity, Point, 2);
            INIT(ptsWWFH, ptsWWFP, ptsWWFCapacity, SvgWWPoint, 3);
            sc.failure = (mode >> 3) & 1;
            expectedFill = (mode >> 1) & 1;
            expectedStroke = expectedFill && ((mode >> 2) & 1);
            rendered = 0;
            result = finish(&sc, mode & 1, expectedFill, (mode >> 2) & 1);
            assert(result == (expectedFill && !sc.failure));
            assert(rendered == (mode & 1));
            SvgScratchFree(&sc);
            SvgScratchFree(&sc);
            for (i = 0; i < 4; i++) assert(!present[i] && !locked[i]);
        }
    }
    return 0;
}
C
close $out or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', "$dir/check.c",
       '-o', "$dir/check") == 0 or die "Compile failed\n";
system("$dir/check") == 0 or die "Scratch check failed\n";
print "SVG path scratch checks passed (1296 cases)\n";

# Execute conversion/emission and point insertion, moving unlocked blocks.
my ($emit) = $path =~ /(static Boolean\s+SvgPathEmitSubpath\(.*?)(?=Boolean SvgPathHandle)/s;
my ($add) = $path =~ /(static void SvgPathAddPt\(.*?)(?=static Boolean)/s;
my ($ensure) = $parser =~ /(Boolean SvgScratchEnsurePointCapacity\(.*?)(?=static Boolean\s+SvgTagSelfCloses)/s;
my $shapes = read_source('svgShape.goc');
die "Missing emission code\n" unless $emit && $add && $ensure;
open $out, '>', "$dir/emit.c" or die $!;
print {$out} <<'C';
#include <assert.h>
#include <stddef.h>
#include <string.h>
#include "svgCapacity.h"
typedef unsigned short word, MemHandle;
typedef short sword;
typedef int Boolean, SvgScratchFailure;
typedef long WWFixedAsDWord;
typedef struct { sword P_x, P_y; } Point;
typedef struct { WWFixedAsDWord x, y; } SvgWWPoint;
typedef struct { WWFixedAsDWord a, b, c, d, e, f; } SvgMatrix;
#define FALSE 0
#define TRUE 1
#define SVG_SCRATCH_OK 0
#define SVG_SCRATCH_ALLOCATION_FAILED 1
#define SVG_SCRATCH_LIMIT_EXCEEDED 2
#define SVG_POINTS_INITIAL_CAPACITY 128
#define MAX_SVG_POINTS 4096
#define HF_DYNAMIC 0
#define HAF_ZERO_INIT 0
#define LOGF(args) ((void)contextP)
#define LOG_STR(c,l,v) ((void)(c))
/* Integer arithmetic suffices for identity-transform lock-lifetime checks. */
#define GrAddWWFixed(a,b) ((a)+(b))
#define GrMulWWFixed(a,b) ((a)*(b))
#define SvgGeomWWFixedToSWordRound(x) ((sword)(x))
C
print {$out} $scratch;
print {$out} <<'C';
typedef SVGScratch SvgImportContext;
static union { SvgWWPoint ww[16]; Point pts[16]; char text[256]; } blocks[4][2];
static int present[4], locked[4], bank[4], shape, rendered;
static SVGScratch *active;
static void *MemLock(MemHandle h)
{
    assert(present[h-1] && !locked[h-1]);
    locked[h-1] = 1;
    return &blocks[h-1][bank[h-1]];
}
static void MemUnlock(MemHandle h)
{
    int i = h-1;
    assert(present[i] && locked[i]);
    locked[i] = 0;
    memcpy(&blocks[i][1-bank[i]], &blocks[i][bank[i]], sizeof(blocks[i][0]));
    memset(&blocks[i][bank[i]], 0xa5, sizeof(blocks[i][0]));
    bank[i] = 1-bank[i];
}
static void MemFree(MemHandle h)
{
    assert(present[h-1] && !locked[h-1]);
    present[h-1] = 0;
}
#define MemAlloc(bytes,flags,alloc) ((MemHandle)0)
#define MemReAlloc(h,bytes,alloc) ((MemHandle)0)
static Boolean SvgScratchEnsureCapacityCommon(SVGScratch *, MemHandle *,
    void **, word *, word, word, word, word);
static void render(Point *ptsP, word count)
{
    word i;
    assert(locked[0] && locked[2] && !locked[3] && !active->ptsWWFP);
    assert(locked[1] == !shape);
    if (shape) assert(!active->dbP);
    assert(count == 3);
    for (i = 0; i < count; i++) {
        assert(ptsP[i].P_x == i+1 && ptsP[i].P_y == 2*(i+1));
    }
    rendered++;
}
#define SvgRendererPolygon(c,p,n,f,s) ((void)(f), (void)(s), render(p,n))
#define SvgRendererPolyline(c,p,n) render(p,n)
#define SvgStyleForceRoundJoinForSegments(c,t,n) ((void)(t), TRUE)
#define SvgStyleRestoreForcedJoin(c,t,f) ((void)(t), (void)(f))
static Boolean SvgShapeParsePoints(SvgImportContext *contextP, const char *text,
                                   SVGScratch *sc, word *npP)
{
    (void)contextP;
    assert(text == sc->dbP && locked[1] && locked[3]);
    *npP = 3;
    return TRUE;
}
C
print {$out} $cleanup, $ensure, $add, $emit;
for my $name ('Polyline', 'Polygon') {
    my ($body) = $shapes =~ /(Boolean SvgShapeHandle$name\(.*?)(?=\nBoolean |\z)/s;
    my ($parsed) = $body =~ /(    if \(!SvgShapeParsePoints\(.*?)(?=    fillPresent)/s;
    my ($guard) = $body =~ /(    if \(np <= [12].*?return FALSE;)/s;
    my ($tail) = $body =~ /(    if \(np > [12]\)\s*\{.*)/s;
    die "Missing $name boundary\n" unless $parsed && $guard && $tail;
    print {$out} "static Boolean check$name(SVGScratch *sc, Boolean fillPresent, Boolean strokePresent)\n{\n";
    print {$out} <<'C';
    SvgImportContext *contextP = sc;
    const char *tag = sc->tagP;
    SvgMatrix worldM = { 1, 0, 0, 1, 0, 0 };
    WWFixedAsDWord X, Y, Xp, Yp;
    word np, i;
    Boolean forcedRoundJoin, emitted = FALSE;
C
    print {$out} $parsed, $guard, "\n", $tail;
}
print {$out} <<'C';
static void init(SVGScratch *sc)
{
    int i;
    memset(sc, 0, sizeof(*sc));
    active = sc;
    rendered = 0;
    for (i = 0; i < 4; i++) { present[i] = locked[i] = 1; bank[i] = 0; }
    sc->tagH = 1; sc->tagP = blocks[0][0].text;
    sc->dbH = 2; sc->dbP = blocks[1][0].text;
    sc->ptsH = 3; sc->ptsP = blocks[2][0].pts; sc->ptsCapacity = 16;
    sc->ptsWWFH = 4; sc->ptsWWFP = blocks[3][0].ww; sc->ptsWWFCapacity = 16;
    for (i = 0; i < 3; i++) { sc->ptsWWFP[i].x = i+1; sc->ptsWWFP[i].y = 2*(i+1); }
}
int main(void)
{
    SVGScratch sc;
    SvgMatrix worldM = { 1, 0, 0, 1, 0, 0 };
    int mode, pass, i;
    word np;
    for (mode = 0; mode < 4; mode++) {
        init(&sc);
        shape = 0;
        for (pass = 0; pass < 2; pass++) {
            np = 3;
            assert(SvgPathEmitSubpath(&sc, sc.tagP, &sc, &np, mode & 1,
                                     &worldM, (mode >> 1) & 1, TRUE));
            assert(np == 0 && !locked[3] && !sc.ptsWWFP);
            /* The actual insertion/helper must reacquire the moved block. */
            for (i = 0; i < 3; i++) SvgPathAddPt(&sc, &sc, &np, i+1, 2*(i+1));
            assert(sc.ptsWWFP == blocks[3][bank[3]].ww);
        }
        assert(rendered == 2);
        SvgScratchFree(&sc);
        for (shape = 1; shape <= 2; shape++) {
            init(&sc);
            if (shape == 1) assert(checkPolyline(&sc, mode & 1, (mode >> 1) & 1) == (mode != 0));
            else assert(checkPolygon(&sc, mode & 1, (mode >> 1) & 1) == (mode != 0));
            assert(rendered == (shape == 1 ? !!(mode & 1) + !!(mode & 2) : (mode != 0)));
            SvgScratchFree(&sc);
        }
    }
    /* Failed point-buffer growth leaves scratch cleanup responsible for locks. */
    init(&sc);
    shape = 0;
    sc.ptsCapacity = 0;
    np = 3;
    assert(!SvgPathEmitSubpath(&sc, sc.tagP, &sc, &np, TRUE, &worldM, TRUE, TRUE));
    assert(sc.failure == SVG_SCRATCH_ALLOCATION_FAILED && !rendered);
    SvgScratchFree(&sc);
    return 0;
}
C
close $out or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', "-I$FindBin::Bin/..",
       "$dir/emit.c", "$FindBin::Bin/../svgPathSyntax.c", '-o', "$dir/emit") == 0
    or die "Emission compile failed\n";
system("$dir/emit") == 0 or die "Emission scratch check failed\n";
print "SVG emission relocation, relock and cleanup checks passed\n";
