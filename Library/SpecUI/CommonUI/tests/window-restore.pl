#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

sub source {
    open my $file, '<', "$FindBin::Bin/../CWin/$_[0]" or die $!;
    local $/;
    return <$file>;
}

# Execute the actual caller instructions. Native conversion is a stub with
# its documented register-clobbering and ratio-to-pixel contracts.
sub run {
    my ($code, $reg, $convert, $built) = @_;
    my (@stack, $zero, $carry);
    for (split /\n/, $code) {
        s/;.*//;
        s/^\s+|\s+$//g;
        next if $_ eq '';
        if (/^push\s+(.+)$/) {
            push @stack, [map { $reg->{$_} } split /,\s*/, $1];
        } elsif (/^pop\s+(.+)$/) {
            @{$reg}{split /,\s*/, $1} = @{pop @stack};
        } elsif (/^call\s+ConvertSpecWinSizePairsToPixels$/) {
            $convert->();
            @{$reg}{qw(ax bp)} = (0xdead, 0xbeef);
        } elsif (/^call\s+UpdateWinPosSize$/) {
            @{$reg}{qw(ax cx dx bp)} = (1, 2, 3, 4);
        } elsif (/^test\s+(ax|cl), mask SA_REALIZABLE$/) {
            $zero = !(($1 eq 'cl' ? $reg->{cx} & 0xff : $reg->{ax}) & 0x40);
        } elsif (/^call\s+VisCheckIfSpecBuilt$/) { $carry = $built;
        } elsif (/^jz\s+cont$/) { last if $zero;
        } elsif (/^jnc\s+cont$/) { last unless $carry;
        } else { die "unhandled restore instruction $_\n"; }
    }
    die "unbalanced restore stack\n" if @stack;
}

my $geometry = source('cwinGeometry.asm');
$geometry =~ /OpenWinUpdateGeometry\s+method[^\n]*\n(.*?)\bcall\s+VisGetSize/s
    or die "geometry entry missing\n";
my $setup = $1;
$setup =~ s/^if 0\r?\n.*?^endif\r?\n//msg;

# Closing can leave mixed pixel positions and ratio sizes in VI_bounds.
# Exercise both reported sizes, plus repeated normal half-size windows.
for my $ratio ([0x82de, 0x81c7], [0x8200, 0x8200]) {
    my @bounds = (0, 0, 640, 480);
    my $encoded = 0;
    for my $cycle (1 .. 3) {
        @bounds = (10, 20, @$ratio);
        $encoded = 1;
        my %reg = (ax => 0x1234, bp => 0x5678);
        run($setup, \%reg, sub {
            return unless $encoded;
            # Only the native routine's contract is under test here.
            $bounds[2] = $bounds[0] + int(($ratio->[0] & 0x3fff) * 1000 / 1024);
            $bounds[3] = $bounds[1] + int(($ratio->[1] & 0x3fff) * 800 / 1024);
            $encoded = 0;
        }, 1);
        die "geometry reads encoded bounds on restore $cycle\n" if $encoded;
        die "restore lost message/frame registers\n"
            unless $reg{ax} == 0x1234 && $reg{bp} == 0x5678;
        die "invalid restored size\n" if
            (($bounds[2] - $bounds[0]) | ($bounds[3] - $bounds[1])) & 0x8000;
    }
}

my $misc = source('cwinClassMisc.asm');
$misc =~ /OLWinSpecSetAttrs\s+method[^\n]*\n(.*?)^cont:/ms
    or die "realizable attribute handler missing\n";
my $guard = $1;
for my $message (0, 0x40, 0x1234, 0xffff) {
    for my $attrs (0, 0x40, 0x2000, 0x4000, 0x2040) {
        for my $built (0, 1) {
            my %reg = (ax => $message, cx => $attrs, dx => 1, bp => 2);
            my $converted = 0;
            run($guard, \%reg, sub { $converted++ }, $built);
            die "wrong realizable attribute guard\n"
                unless $converted == (($attrs & 0x40) && $built ? 1 : 0);
            die "attribute handler lost arguments\n" unless
                $reg{cx} == $attrs && $reg{dx} == 1 && $reg{bp} == 2;
        }
    }
}
print "window restore caller checks passed\n";
