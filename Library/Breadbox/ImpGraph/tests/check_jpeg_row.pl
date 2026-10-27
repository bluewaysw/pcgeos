#!/usr/bin/env perl
# Exercise the actual JPEG row code with relocation and failure injection.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

open my $in, '<:raw', "$FindBin::Bin/../IMPBMP/impjpeg.goc" or die $!;
my $source = do { local $/; <$in> };
sub part {
    my ($start, $end) = @_;
    my $a = index($source, $start);
    my $b = index($source, $end, $a + length($start));
    die "Missing row code: $start\n" if $a < 0 || $b < 0;
    return substr($source, $a, $b - $a);
}
my $alloc = part('  /* Check the byte count', '  /* Step 6:');
my $read = part('    rowP = MemLock(rowH);', "\n#if SCANLINE_COMPRESS");
my $copy = part('        if (displayClass == DC_GRAY_8)', "\n#if SCANLINE_COMPRESS");
my $failure = part("    else {\n        MemUnlock(rowH);", "\n#if SCANLINE_COMPRESS");
my $error = part('      if (rowH) {', "#if SCANLINE_COMPRESS");
my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/check.c" or die $!;
print {$out} <<'C';
#include <assert.h>
#include <setjmp.h>
#include <stdio.h>
#include <string.h>
typedef unsigned short word;
typedef unsigned long dword;
typedef word MemHandle;
typedef unsigned char JSAMPLE;
typedef JSAMPLE *JSAMPROW;
#define TRUE 1
#define FALSE 0
#define HF_DYNAMIC 0x10
#define HAF_ZERO_INIT 0x80
#define DC_GRAY_8 1
#define DC_COLOR_8 2
#define DC_COLOR_4 3
#define DC_GRAY_1 4
#define ConvertGreyLine check_copy
#define ConvertLine check_copy
#define ConvertLine16Color check_copy
#define MonoDowngrade(d,s,w,l) check_copy(d,s,w)
typedef struct { word output_width, output_components, output_scanline; } TestDecoder;
static TestDecoder info;
static JSAMPROW rowP, lastP;
static MemHandle rowH;
static dword rowSize;
static int flag, scenario;
static unsigned char storage[2][65536], dest[65536];
static unsigned current, locked, allocated, locks, unlocks, frees;
static word bytes;
static jmp_buf errorContext;
static MemHandle MemAlloc(word size, word flags, word allocFlags)
{
    assert(size && !allocated && flags == HF_DYNAMIC && allocFlags == HAF_ZERO_INIT);
    if (scenario == 1) return 0;
    allocated = 1;
    bytes = size;
    memset(storage[current], 0, bytes);
    return 1;
}
static void *MemLock(MemHandle h)
{
    assert(h == 1 && allocated && !locked);
    if (scenario == 2) return (void*)0;
    locked = 1;
    locks++;
    return storage[current];
}
static void MemUnlock(MemHandle h)
{
    assert(h == 1 && allocated && locked);
    locked = 0;
    unlocks++;
    memcpy(storage[1-current], storage[current], bytes);
    memset(storage[current], 0xa5, bytes);
    current = 1-current;
}
static void MemFree(MemHandle h)
{
    assert(h == 1 && allocated && !locked);
    allocated = 0;
    frees++;
}
static unsigned jpeg_read_scanlines(void *decoder, JSAMPROW *rowsP, unsigned count)
{
    assert(decoder == &info && count == 1 && locked && *rowsP == storage[current]);
    assert(*rowsP != lastP); /* every subsequent row must rebind after relocation */
    lastP = *rowsP;
    memset(*rowsP, ++info.output_scanline, bytes);
    if (scenario == 3) longjmp(errorContext, 1);
    return 1;
}
static void *check_copy(void *dstP, const void *srcP, unsigned size)
{
    assert(locked && srcP == storage[current] && size == bytes);
    return memcpy(dstP, srcP, size);
}
#define memcpy check_copy
static void run(word width, word components, int mode)
{
    TestDecoder *cinfo = &info;
    void *lineptr = dest;
    word size;
    int displayClass = components == 1 ? DC_GRAY_8 : 0;
    scenario = mode;
    info.output_width = width;
    info.output_components = components;
    info.output_scanline = 0;
    rowH = 0;
    rowP = lastP = (void*)0;
    flag = FALSE;
    locks = unlocks = frees = 0;
    assert(!allocated && !locked);
    if (setjmp(errorContext)) {
C
print {$out} $error;
print {$out} <<'C';
        assert(!allocated && !locked && frees == 1 && locks == unlocks);
        return;
    }
C
print {$out} $alloc;
print {$out} <<'C';
    size = (word)rowSize;
    while (!flag && info.output_scanline < 3) {
C
print {$out} $read;
print {$out} "    if (scenario != 4) {\n", $copy;
print {$out} <<'C';
        /* Compression, append and progress may run only after releasing the row. */
        assert(!locked && !rowP);
        assert(dest[0] == info.output_scanline && dest[size-1] == info.output_scanline);
        if (scenario == 5) break; /* cancellation after publishing a row */
    }
C
print {$out} $failure;
print {$out} <<'C';
    assert(!allocated && !locked && !rowH && !rowP && locks == unlocks);
    assert(frees == (mode == 1 || !rowSize || rowSize > 0xffffUL ? 0 : 1));
    if (!mode && rowSize && rowSize <= 0xffffUL) assert(info.output_scanline == 3);
    if (mode == 1 || mode == 2 || mode == 4 || !rowSize || rowSize > 0xffffUL) assert(flag);
    if (mode == 1 || mode == 2) assert(!info.output_scanline);
}
int main(void)
{
    int mode;
    for (mode = 0; mode <= 5; mode++) {
        run(2048, 3, mode);
        run(2048, 1, mode);
    }
    run(65535, 1, 0);
    run(0, 3, 0);
    run(65535, 3, 0); /* reject the byte count before truncation */
    puts("ImpGraph movable JPEG row checks passed");
    return 0;
}
C
close $out or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', "$dir/check.c", '-o', "$dir/check") == 0
    or die "Compilation failed\n";
system("$dir/check") == 0 or die "Checks failed\n";
