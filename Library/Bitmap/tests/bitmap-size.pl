#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

# Execute the source routine's integer sizing instructions, without GEOS.
open my $asm, '<', "$FindBin::Bin/../bitmap.asm" or die $!;
local $/;
my $source = <$asm>;
$source =~ /VisBitmapCheckBitmapSize\s+proc(.*?)VisBitmapCheckBitmapSize\s+endp/s
    or die "size routine missing\n";
my $routine = $1;
$routine =~ /\bcmp\s+cl,\s*BMF_24BIT(.*?)\bmov\s+ax,\s*65535/s
    or die "sizing instructions missing\n";
my @code = ('cmp cl, BMF_24BIT', split /\n/, $1);
my %labels;
for my $i (0 .. $#code) {
    $code[$i] =~ s/;.*//;
    $code[$i] =~ s/^\s+|\s+$//g;
    $labels{$1} = $i if $code[$i] =~ /^(\w+):$/;
}
open my $header, '<', "$FindBin::Bin/../../../CInclude/graphics.h" or die $!;
my %format = (<$header> =~ /^#define\s+(BMF_\w+)\s+(\d+)/mg);

sub estimate {
    my ($width, $height, $fmt) = @_;
    my ($value, $saved, $carry, $zero) = ($width * $height, 0, 0, 0);
    for (my $pc = 0; $pc < @code; $pc++) {
        my $op = $code[$pc];
        next if $op eq '' || $op =~ /:$/;
        if ($op =~ /^cmp\s+cl,\s*(BMF_\w+)$/) {
            $zero = $fmt == $format{$1};
            $carry = $fmt < $format{$1};
        } elsif ($op =~ /^cmp\s+dx,\s*0400h$/) {
            $carry = ($value >> 16) < 0x400;
        } elsif ($op =~ /^(je|jne|jc|jae|jmp)\s+(\w+)$/) {
            my ($jump, $label) = ($1, $2);
            next unless $jump eq 'jmp' || ($jump eq 'je' && $zero) ||
                ($jump eq 'jne' && !$zero) || ($jump eq 'jc' && $carry) ||
                ($jump eq 'jae' && !$carry);
            return undef if $label eq 'tooLarge';
            $pc = $labels{$label} // die "unknown label $label\n";
        } elsif ($op =~ /^movdw\s+cxbx,\s*dxax$/) {
            $saved = $value;
        } elsif ($op =~ /^shldw\s+dxax$/) {
            $carry = ($value & 0x80000000) != 0;
            $value = ($value << 1) & 0xffffffff;
        } elsif ($op =~ /^adddw\s+dxax,\s*cxbx$/) {
            $value += $saved;
            $carry = $value > 0xffffffff;
            $value &= 0xffffffff;
        } elsif ($op =~ /^shrdw\s+dxax$/) {
            $value >>= 1;
        } elsif ($op =~ /^mov_tr\s+bx,\s*dx$/) {
            return $value >> 16;
        } else {
            die "unhandled sizing instruction: $op\n";
        }
    }
    die "sizing routine did not finish\n";
}

# Pixel, KB, 64 MB and 32-bit-overflow boundaries, plus reproducible samples.
my @dimensions = ([1, 1], [871, 1024], [32767, 32767], [65535, 65535]);
for my $height (340, 341, 342, 21844, 21845, 21846, 65535) {
    push @dimensions, [1024, $height];
}
srand 72;
push @dimensions, [1 + int rand 65535, 1 + int rand 65535] for 1 .. 1000;
for my $case (@dimensions) {
    for my $fmt (qw(BMF_MONO BMF_4BIT BMF_8BIT BMF_24BIT)) {
        my $bits = { BMF_MONO => 1, BMF_4BIT => 4,
                     BMF_8BIT => 8, BMF_24BIT => 24 }->{$fmt};
        my $kb = int($case->[0] * $case->[1] * $bits / 8192);
        my $actual = estimate(@$case, $format{$fmt});
        die "wrong size for @$case $fmt\n" unless $kb >= 65536 ?
            !defined $actual : defined $actual && $actual == $kb;
    }
}
print "bitmap size checks passed\n";
