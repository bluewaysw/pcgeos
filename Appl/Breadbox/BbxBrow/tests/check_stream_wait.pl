#!/usr/bin/env perl
# Execute BLOCK's comparison instructions on an x86-64 host.
# GEOS interrupt control and ThreadBlockOnQueue are not exercised here.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $file, '<:raw', $_[0] or die $!;
    local $/;
    my $text = <$file>;
    $text =~ s/\r\n/\n/g;
    return $text;
}

my $asm = read_source("$FindBin::Bin/../ASMTOOLS/asmtoolsManager.asm");
$asm =~ /BLOCK\s+proc\s+far\s+([^\n]+).*?INT_OFF\s+push\s+ds, si\s+(.*?)^doBlock:/ms
    or die "Cannot extract atomic wait predicate\n";
my ($params, $predicate) = ($1, $2);
$params eq 'queueP:fptr, flag:fptr, bytesAvailP:fptr, preReadOffsetP:fptr, needed:word'
    or die "Unexpected BLOCK parameters\n";
my $source = read_source("$FindBin::Bin/../urltext/URLTEXT.goc");
$source =~ /Block\(&\(loadProgressDataP->LPD_emptyQueue\),\s*&loadProgressDataP->LPD_fileDone,\s*&loadProgressDataP->LPD_bytesAvail,\s*&loadProgressDataP->LPD_preReadOffset, bufSize\)/
    or die "Caller does not pass the wait inputs\n";

# Map far-pointer loads to the host ABI; keep the 16-bit arithmetic intact.
$predicate =~ s/;[^\n]*//g;
$predicate =~ s/lds\s+si, flag/mov r8, rdi/g;
$predicate =~ s/lds\s+si, bytesAvailP/mov r8, rsi/g;
$predicate =~ s/lds\s+si, preReadOffsetP/mov r8, r10/g;
$predicate =~ s/ds:\[si(\+2)?\]/'WORD PTR [r8' . ($1 || '') . ']'/ge;
$predicate =~ s/tst\s+(ax|dx)/test $1, $1/g;
$predicate =~ s/\bneeded\b/cx/g;

my $tmp = tempdir(CLEANUP => 1);
open my $assembly, '>', "$tmp/wait.s" or die $!;
print $assembly ".intel_syntax noprefix\n.text\n.global ShouldBlock\nShouldBlock:\nmov r10, rdx\n";
print $assembly $predicate;
print $assembly "doBlock:\nmov eax, 1\nret\nskipBlock:\nxor eax, eax\nret\n.section .note.GNU-stack,\"\",\@progbits\n";
close $assembly or die $!;
open my $test, '>', "$tmp/check.c" or die $!;
print $test <<'C';
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
extern int ShouldBlock(uint16_t *, uint32_t *, uint32_t *, uint16_t);
int main(void)
{
    uint16_t done = 0;
    uint32_t available = 5, offset = 2;
    /* Reader needs four bytes. Producer appends and wakes before queueing. */
    assert(ShouldBlock(&done, &available, &offset, 4));
    available += 3;
    assert(!ShouldBlock(&done, &available, &offset, 4));
    available = 0; offset = 0;
    assert(ShouldBlock(&done, &available, &offset, 512));
    done = 1;
    assert(!ShouldBlock(&done, &available, &offset, 512));
    done = 0; available = 65541;
    assert(!ShouldBlock(&done, &available, &offset, 65535));
    offset = 65536;
    assert(!ShouldBlock(&done, &available, &offset, 5));
    assert(ShouldBlock(&done, &available, &offset, 6));
    available = 65536; offset = 1;
    assert(!ShouldBlock(&done, &available, &offset, 65535));
    offset = 65537;
    assert(ShouldBlock(&done, &available, &offset, 1));
    puts("Stream wait: lost wakeup, completion and 32-bit boundaries passed.");
    return 0;
}
C
close $test or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror',
       "$tmp/check.c", "$tmp/wait.s", '-o', "$tmp/check") == 0
    or die "Host compilation failed\n";
system("$tmp/check") == 0 or die "Stream wait check failed\n";
