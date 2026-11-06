#!/usr/bin/env perl
# Compile the actual buffer allocator, scanline wrapper and cleanup with host stubs.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub function {
    my ($file, $name) = @_;
    open my $in, '<:raw', "$FindBin::Bin/../code/$file" or die $!;
    local $/;
    my $source = <$in>;
    $source =~ /^\w[^\n]*\b\Q$name\E\s*\([^;{]*\)\s*\{/m or die "Missing $name\n";
    my ($start, $end, $depth) = ($-[0], $+[0], 1);
    while ($depth && $end < length $source) {
        my $c = substr($source, $end++, 1);
        $depth += ($c eq '{') - ($c eq '}');
    }
    die "Unclosed $name\n" if $depth;
    return substr($source, $start, $end - $start);
}

my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/check.c" or die $!;
print {$out} <<'C';
#include <assert.h>
#include <stdio.h>
#include <string.h>
typedef unsigned short word;
typedef unsigned long dword;
typedef word MemHandle;
typedef unsigned int JDIMENSION;
typedef int Boolean;
typedef unsigned char *JSAMPROW;
typedef JSAMPROW *JSAMPARRAY;
typedef struct {
    word width_in_blocks, DCT_scaled_size, v_samp_factor;
} jpeg_component_info;
typedef struct {
    struct { JSAMPARRAY buffer[3]; MemHandle bufferH[3]; word rowgroup_ctr; } main;
    struct { JSAMPARRAY color_buf[3]; int methods[3], rowgroup_height[3]; } upsample;
    jpeg_component_info *comp_info;
    int num_components, min_DCT_scaled_size, error, global_state;
} TestDecoder;
typedef TestDecoder *j_decompress_ptr;
#define _pascal
#define NullHandle 0
#define MAX_COMPONENTS 3
#define HF_SWAPABLE 0x10
#define HAF_ZERO_INIT 0x80
#define JERR_MEMFULL 1
#define JERR_BAD_BUFFER_MODE 2
#define JERR_BAD_STATE 3
#define DSTATE_SCANNING 205
#define NU_FULL_US 1
#define PUSHDS
#define POPDS
#define GeodeLoadDGroup(x) ((void)0)
static union { void *align; unsigned char bytes[65536]; } storage[3][2];
static JSAMPROW fixedRows[3][32];
static unsigned blockSize[3], current[3], locked[3], frees, failAlloc, failLock;
static unsigned reads, decodeFail, verifyData;
static void *lastP[3];
static void set_error(j_decompress_ptr cinfo, int error) { cinfo->error = error; }
static MemHandle MemAlloc(word size, word flags, word allocFlags)
{
    unsigned slot;
    assert(flags == HF_SWAPABLE && allocFlags == HAF_ZERO_INIT);
    for (slot = 0; slot < 3 && blockSize[slot]; slot++) {}
    assert(slot < 3);
    if (failAlloc == slot+1) return 0;
    blockSize[slot] = size;
    memset(storage[slot][current[slot]].bytes, 0, size);
    return (MemHandle)(slot+1);
}
static void *MemLock(MemHandle handle)
{
    unsigned slot = handle-1;
    assert(handle && handle <= 3 && blockSize[slot] && !locked[slot]);
    if (failLock == handle) return (void *)0;
    locked[slot] = 1;
    return storage[slot][current[slot]].bytes;
}
static void MemUnlock(MemHandle handle)
{
    unsigned slot = handle-1;
    assert(handle && handle <= 3 && locked[slot]);
    locked[slot] = 0;
    memcpy(storage[slot][1-current[slot]].bytes,
           storage[slot][current[slot]].bytes, blockSize[slot]);
    memset(storage[slot][current[slot]].bytes, 0xa5, blockSize[slot]);
    current[slot] = 1-current[slot]; /* force relocation after every call */
}
static void MemFree(MemHandle handle)
{
    unsigned slot = handle-1;
    assert(handle && handle <= 3 && blockSize[slot] && !locked[slot]);
    blockSize[slot] = 0;
    frees++;
}
static void freeall(j_decompress_ptr cinfo) { (void)cinfo; }
static JDIMENSION jpeg_read_scanlines_a(j_decompress_ptr cinfo,
                                       JSAMPARRAY scanlines, JDIMENSION max_lines)
{
    JSAMPARRAY rowsP;
    unsigned ci, i, width, rows;
    (void)scanlines; (void)max_lines;
    for (ci = 0; ci < (unsigned)cinfo->num_components; ci++) {
        rowsP = cinfo->main.buffer[ci];
        width = cinfo->comp_info[ci].width_in_blocks * 8;
        rows = cinfo->comp_info[ci].v_samp_factor * 8;
        assert(locked[ci] && rowsP == (JSAMPARRAY)storage[ci][current[ci]].bytes);
        assert(rowsP != lastP[ci]);
        lastP[ci] = rowsP;
        for (i = 0; i < rows; i++) {
            assert(rowsP[i] == (JSAMPROW)(rowsP + rows) + i * width);
            assert(rowsP[i] + width <= storage[ci][current[ci]].bytes + blockSize[ci]);
            if (verifyData) assert(rowsP[i][width-1] == (unsigned char)(i+ci*32));
            rowsP[i][width-1] = (unsigned char)(i+ci*32);
        }
        if (cinfo->upsample.methods[ci] == NU_FULL_US) {
            assert(cinfo->upsample.color_buf[ci] == rowsP +
                   cinfo->main.rowgroup_ctr * cinfo->upsample.rowgroup_height[ci]);
        } else {
            assert(cinfo->upsample.color_buf[ci] == fixedRows[ci]);
        }
    }
    reads++;
    return decodeFail ? 0 : 1;
}
C
print {$out} function('init.c', 'jinit_d_main_controller'), "\n";
print {$out} function('main.c', 'fjpeg_read_scanlines'), "\n";
print {$out} function('main.c', 'fjpeg_destroy_decompress'), "\n";
print {$out} <<'C';
int main(void)
{
    TestDecoder decoder;
    jpeg_component_info comps[3] = {{256,8,2},{128,8,1},{128,8,1}};
    unsigned scenario, call, ci, savedReads, savedFrees;
    j_decompress_ptr cinfo = &decoder;
    for (scenario = 0; scenario < 4; scenario++) {
        memset(cinfo, 0, sizeof(*cinfo));
        assert(!fjpeg_read_scanlines(cinfo, (void *)0, 1));
        assert(cinfo->error == JERR_BAD_STATE);
        cinfo->global_state = DSTATE_SCANNING;
        cinfo->comp_info = comps;
        cinfo->num_components = scenario == 1 ? 1 : 3; /* grayscale too */
        comps[0].v_samp_factor = scenario == 0 ? 2 : 1;
        cinfo->min_DCT_scaled_size = 8;
        for (ci = 0; ci < 3; ci++) {
            cinfo->upsample.methods[ci] = (scenario == 2 ||
                (ci == 0 && scenario != 3)) ? NU_FULL_US : 2;
            cinfo->upsample.rowgroup_height[ci] = comps[ci].v_samp_factor;
            cinfo->upsample.color_buf[ci] = fixedRows[ci];
            lastP[ci] = (void *)0;
            assert(!locked[ci] && !blockSize[ci]);
        }
        verifyData = decodeFail = 0;
        jinit_d_main_controller(cinfo, 0);
        for (ci = 0; ci < (unsigned)cinfo->num_components; ci++) {
            assert(cinfo->main.bufferH[ci] && !locked[ci] && !cinfo->main.buffer[ci]);
        }
        for (call = 0; call < 5; call++) {
            cinfo->main.rowgroup_ctr = call/2; /* retain partial row groups */
            decodeFail = call == 4;
            assert(fjpeg_read_scanlines(cinfo, (void *)0, 1) == !decodeFail);
            for (ci = 0; ci < (unsigned)cinfo->num_components; ci++) {
                assert(!locked[ci] && !cinfo->main.buffer[ci]);
                if (cinfo->upsample.methods[ci] == NU_FULL_US)
                    assert(!cinfo->upsample.color_buf[ci]);
            }
            verifyData = 1;
        }
        savedReads = reads;
        for (failLock = 1; failLock <= (unsigned)cinfo->num_components; failLock++) {
            assert(!fjpeg_read_scanlines(cinfo, (void *)0, 1));
            assert(reads == savedReads && cinfo->error == JERR_MEMFULL);
            for (ci = 0; ci < 3; ci++) {
                assert(!locked[ci] && !cinfo->main.buffer[ci]);
                if (cinfo->upsample.methods[ci] == NU_FULL_US)
                    assert(!cinfo->upsample.color_buf[ci]);
            }
        }
        failLock = 0;
        fjpeg_destroy_decompress(cinfo);
        for (ci = 0; ci < 3; ci++) assert(!cinfo->main.bufferH[ci] && !blockSize[ci]);
        savedFrees = frees;
        fjpeg_destroy_decompress(cinfo);
        assert(frees == savedFrees);
    }
    for (failAlloc = 1; failAlloc <= 3; failAlloc++) {
        savedFrees = frees;
        jinit_d_main_controller(cinfo, 0);
        assert(!cinfo->main.bufferH[failAlloc-1] && cinfo->error == JERR_MEMFULL);
        savedReads = reads;
        assert(!fjpeg_read_scanlines(cinfo, (void *)0, 1) && reads == savedReads);
        for (ci = 0; ci < 3; ci++) assert(!locked[ci] && !cinfo->main.buffer[ci]);
        fjpeg_destroy_decompress(cinfo);
        assert(frees == savedFrees+failAlloc-1);
        for (ci = 0; ci < 3; ci++) assert(!cinfo->main.bufferH[ci] && !blockSize[ci]);
    }
    failAlloc = 0;
    for (call = 0; call < 3; call++) {
        for (ci = 0; ci < 3; ci++) {
            comps[ci].width_in_blocks = 256;
            comps[ci].v_samp_factor = ci == call ? 4 : 1;
        }
        /* 64 KB of pixels plus pointers cannot fit, for any component. */
        jinit_d_main_controller(cinfo, 0);
        assert(!cinfo->main.bufferH[call] && cinfo->error == JERR_MEMFULL);
        savedReads = reads;
        assert(!fjpeg_read_scanlines(cinfo, (void *)0, 1) && reads == savedReads);
        fjpeg_destroy_decompress(cinfo);
        for (ci = 0; ci < 3; ci++) assert(!locked[ci] && !blockSize[ci]);
    }
    puts("FJPEG movable buffer checks passed");
    return 0;
}
C
close $out or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', "$dir/check.c", '-o', "$dir/check") == 0
    or die "Compilation failed\n";
system("$dir/check") == 0 or die "Checks failed\n";
