#!/usr/bin/env perl
# Check the actual filename seed/retry instructions with clobbered BX.
use strict;
use warnings;
use FindBin;

open my $file, '<:raw', "$FindBin::Bin/../File/fileOpenClose.asm" or die $!;
local $/;
my $source = <$file>;
$source =~ /FileCreateTempFile\s+proc\s+far(.*?)FileCreateTempFile\s+endp/s
    or die "Cannot find FileCreateTempFile\n";
my $proc = $1;
$proc =~ /(mov\s+(?:bx|ss:\w+), di[^\n]*.*?movdw\s+ss:curCount, bxax)/s
    or die "Cannot find filename seed\n";
my $seed = $1;
$proc =~ /(incdw\s+ss:curCount.*?call\s+putHexDWord)/s
    or die "Cannot find collision retry\n";
my $retry = $1;

sub instructions {
    my ($code, $regs, $locals, $buffer, $ticks) = @_;
    for my $line (split /\n/, $code) {
        $line =~ s/;.*//;
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/\s+/ /g;
        next unless length $line;
        if ($line =~ /^mov (bx|di|ss:\w+), (bx|di|ss:\w+)$/) {
            my ($dest, $src) = ($1, $2);
            my $value = $src =~ /^ss:(.*)/ ? $locals->{$1} : $regs->{$src};
            if ($dest =~ /^ss:(.*)/) { $locals->{$1} = $value; }
            else { $regs->{$dest} = $value; }
        } elsif ($line eq 'call TimerGetCount') {
            $regs->{ax} = $ticks & 65535;
            $regs->{bx} = $ticks >> 16;
        } elsif ($line eq 'xor bx, ss:TPD_processHandle') {
            $regs->{bx} ^= 0x58a0;
        } elsif ($line eq 'movdw ss:curCount, bxax') {
            $locals->{curCount} = ($regs->{bx} << 16) | $regs->{ax};
        } elsif ($line eq 'incdw ss:curCount') {
            $locals->{curCount} = ($locals->{curCount} + 1) & 0xffffffff;
        } elsif ($line eq 'call putHexDWord') {
            substr($$buffer, $regs->{di}, 8) = sprintf '%08X', $locals->{curCount};
            $regs->{di} += 8;
        } else { die "Unsupported instruction: $line\n"; }
    }
}

for my $ticks (0x44e, 0x58a0ffff, 0xa75fffff) {
    for my $collisions (0, 1, 3, 200) {
        my $prefix = "C:\\ENSEMBLE\\PRIVDATA\\WASTE\\";
        my $offset = length $prefix;
        my $buffer = $prefix . (' ' x 8) . '.TMP' . "\0" . ('!' x 65536);
        my %regs = (di => $offset, bx => 0, ax => 0);
        my %locals;
        my %names;
        instructions($seed, \%regs, \%locals, \$buffer, $ticks);
        my $initial = $locals{curCount};
        instructions('call putHexDWord', \%regs, \%locals, \$buffer, $ticks);
        for my $attempt (0 .. $collisions) {
            my $expected = $prefix . sprintf('%08X', ($initial + $attempt) & 0xffffffff) . '.TMP';
            my ($name) = split /\0/, $buffer, 2;
            die "Wrong path on retry $attempt: $name\n" unless $name eq $expected;
            die "Repeated filename\n" if $names{$name}++;
            # FileCreateCommon destroys BX; only ERROR_FILE_EXISTS retries.
            $regs{bx} = 0xdead;
            instructions($retry, \%regs, \%locals, \$buffer, $ticks)
                if $attempt < $collisions;
        }
    }
}
print "Temp filename collision checks passed (including counter wrap)\n";
