#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

# Execute the source's title-selection instructions against small object blocks.
open my $asm, '<', "$FindBin::Bin/../CWin/cwinBase.asm" or die $!;
local $/;
my $source = <$asm>;
$source =~ /OLBaseWinSetWindowEntryMoniker\s+method(.*?)getTextMoniker:/s
    or die "title selection missing\n";
my $selection = $1;
$selection =~ s/^.*?LONG\s+jz done\s*//s or die "entry guard missing\n";

for my $ui (qw(CUAS OLS)) {
    my @code;
    for (split /\n/, $selection) {
        s/;.*//;
        next if /^\s*(?:$|\.warn)/;
        if (/^(CUAS|OLS)\s*<(.*?)>/) {
            next unless $1 eq $ui;
            $_ = $2;
        }
        s/^\s+|\s+$//g;
        push @code, $_;
    }
    for my $primary (0, 1) {
        for my $chunk (0, 64) {
            for my $type (0 .. 3) {
                for my $first (0, 65, 0x100) {
                    my %reg = (si => 16, di => 512, cx => 0, dx => 0);
                    my %mem = (
                        'ds:[512].OLWI_type' => $primary,
                        'ds:[16]' => 256, 'ds:[256].Gen_offset' => 32,
                        'ds:[288].GPI_longTermMoniker' => $chunk,
                        'ds:[64]' => 768, 'ds:[768].VM_type' => $type,
                        'ds:[768].VM_data.VMT_text' => $first,
                        'ds:[LMBH_handle]' => 99,
                    );
                    my %constant = (
                        MOWT_PRIMARY_WINDOW => 1, OLWT_BASE_WINDOW => 1,
                        'mask VMT_GSTRING or mask VMT_MONIKER_LIST' => 3,
                    );
                    my $read = sub {
                        my ($operand) = @_;
                        return $reg{$operand} if exists $reg{$operand};
                        $operand =~ s/\[(si|di)\]/'[' . $reg{$1} . ']'/ge;
                        return $mem{$operand} if exists $mem{$operand};
                        return $constant{$operand} if exists $constant{$operand};
                        die "unknown operand $operand\n";
                    };
                    my ($zero, $target) = (0, '');
                    for (@code) {
                        if (/^(mov|add|cmp|test)\s+(.+?),\s*(.+)$/) {
                            my ($op, $left, $right) = ($1, $2, $read->($3));
                            if ($op eq 'mov') { $reg{$left} = $right; }
                            elsif ($op eq 'add') { $reg{$left} += $right; }
                            elsif ($op eq 'cmp') { $zero = $read->($left) == $right; }
                            else { $zero = !($read->($left) & $right); }
                        } elsif (/^(?:tst|LocalIsNull)\s+(.+)$/) {
                            $zero = !$read->($1);
                        } elsif (/^(jne|jnz|jz|jmp)\s+(\w+)$/) {
                            next unless $1 eq 'jmp' || ($1 eq 'jz' ? $zero : !$zero);
                            $target = $2;
                            last;
                        } else { die "unhandled instruction $_\n"; }
                    }
                    my $use_title = $primary && $chunk && !$type && $first;
                    die "wrong selection: $ui $primary $chunk $type $first\n"
                        unless $target eq ($use_title ? 'getIconMoniker' : 'getTextMoniker');
                    die "wrong title address\n" if $use_title &&
                        ($reg{cx} != 99 || $reg{dx} != $chunk);
                }
            }
        }
    }
}
# Follow the window/app fallback and the builder's text-only copy path.
$source =~ /^getTextMoniker:(.*?)^getIconMoniker:/ms
    or die "window/app selection missing\n";
my $fallback = $1;
$source =~ /OLBaseWinCreateCombinationMoniker\s+proc\s+far.*?\.enter\r?\n(.*?)^copyMoniker:/ms
    or die "combination builder missing\n";
my @copy = split /\n/, $1;
for my $case (
    ['ISDesk folder', 'Documents', 'ISDesk', undef, 'Documents'],
    ['browser URL', 'https://example.org/', 'WebMagick', undef, 'https://example.org/'],
    ['browser page title', 'Example Domain', 'WebMagick', undef, 'Example Domain'],
    ['app fallback', undef, 'GeoDraw', undef, 'GeoDraw'],
    ['copied app caption', 'GeoDraw', 'GeoDraw', undef, 'GeoDraw'],
    ['document title', 'GeoDraw', 'GeoDraw', 'Drawing', 'Drawing'],
    ['document named like app', 'GeoDraw', 'GeoDraw', 'GeoDraw', 'GeoDraw'],
    ['missing monikers', undef, undef, undef, undef],
) {
    my ($name, $window, $app, $document, $expected) = @$case;
    my %reg = (cx => 99, dx => 96, bx => 0, di => 0);
    my ($zero, $app_lookup, $copied) = (0, 0, 0);
    my @code = (defined $document ? () : split(/\n/, $fallback),
                'build:', @copy);
    my ($build) = grep { $code[$_] eq 'build:' } 0 .. $#code;
    for (my $pc = 0; $pc < @code; $pc++) {
        local $_ = $code[$pc];
        s/;.*//;
        s/^\s+|\s+$//g;
        next if $_ eq '';
        if (/^mov\s+bp, /) {
        } elsif ($_ eq 'clc' || $_ eq 'stc') {
            $app_lookup = $_ eq 'stc';
        } elsif (/^call\s+GenFindMoniker$/) {
            my $text = $app_lookup ? $app : $window;
            @reg{qw(cx dx)} = defined $text ? (99, $app_lookup ? 80 : 64) : (0, 0);
        } elsif ($_ eq 'build:') {
            @reg{qw(text_handle text_chunk)} = @reg{qw(cx dx)};
        } elsif (/^movdw\s+bxdi, ss:\[(iconMkr|textMkr)\]$/) {
            @reg{qw(bx di)} = $1 eq 'iconMkr' ? (0, 0)
                : @reg{qw(text_handle text_chunk)};
        } elsif (/^tst\s+(cx|bx)$/) {
            $zero = !$reg{$1};
        } elsif (/^jnz\s+getIconMoniker$/) {
            $pc = $build - 1 unless $zero;
        } elsif (/^jnz\s+copyMoniker$/) {
            die "unexpected icon in $name\n" unless $zero;
        } elsif (/^LONG\s+jz\s+done$/) {
            last if $zero;
        } elsif (/^clr\s+ax$/) {
            $copied = 1;
        } else { die "unhandled caption instruction $_\n"; }
    }
    die "wrong copy path: $name\n" unless $copied == defined $expected;
    my %text = (64 => $window, 80 => $app, 96 => $document);
    my $actual = $copied ? $text{$reg{di}} : undef;
    die "wrong caption: $name\n" unless
        defined $actual == defined $expected && (!defined $actual || $actual eq $expected);
}
print "taskbar title selection checks passed\n";
