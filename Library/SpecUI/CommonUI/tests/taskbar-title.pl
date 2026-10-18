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
# Recognize the original app moniker before copying it.
$source =~ /\tcmp\tcx, ss:\[textMkr\].handle(.*?)copyAppText:/s
    or die "app fallback check missing\n";
my @fallback = ("cmp cx, ss:[textMkr].handle", split /\n/, $1);
for my $title ([99, 64], [99, 80], [100, 64]) {
    my ($zero, $handle) = (0, $title->[0]);
    for (@fallback) {
        s/;.*//;
        next if /^\s*$/;
        if (/cmp\s+cx, ss:\[textMkr\].handle/) { $zero = 99 == $handle;
        } elsif (/cmp\s+dx, ss:\[textMkr\].offset/) { $zero = 64 == $title->[1];
        } elsif (/jne\s+copyAppText/) { last unless $zero;
        } elsif (/clr\s+ss:\[textMkr\].handle/) { $handle = 0;
        } else { die "unhandled fallback instruction $_\n"; }
    }
    die "wrong app fallback\n" unless (!$handle) ==
        ($title->[0] == 99 && $title->[1] == 64);
}

# A copied app caption is also a fallback, but a real long-term document
# title must survive even if its text equals the app name.
$source =~ /; The primary can hold a copy[^\n]*\n\s*;\s*\n(.*?)sizeTitle:/s
    or die "copied app caption check missing\n";
my @caption_check = split /\n/, $1;
for my $document_title (0, 1) {
    for my $title ('GeoDraw', 'GeoDraw Untitled', 'Drawing') {
        my ($zero, $target, $si, $cx) = (0, 'sizeTitle', 0, 0);
        for (@caption_check) {
            s/;.*//;
            next if /^\s*$/;
            if (/tst\s+ss:\[hasDocumentTitle\]/) { $zero = !$document_title;
            } elsif (/jnz\s+sizeTitle/) { last unless $zero;
            } elsif (/mov\s+si, ss:\[appChunk\]/) { $si = 64;
            } elsif (/mov\s+si, ds:\[si\]/) {
                die "wrong app chunk\n" unless $si == 64;
                $si = 100;
            } elsif (/add\s+si, VM_data\+VMT_text/) { $si += 4;
            } elsif (/clr\s+cx/) { $cx = 0;
            } elsif (/call\s+LocalCmpStrings/) {
                die "wrong caption comparison\n" unless $si == 104 && !$cx;
                $zero = $title eq 'GeoDraw';
            } elsif (/LONG je\s+unlockTitle/) {
                $target = 'unlockTitle' if $zero;
            } else { die "unhandled caption instruction $_\n"; }
        }
        my $suppress = !$document_title && $title eq 'GeoDraw';
        die "wrong caption fallback: $document_title $title\n" unless
            $target eq ($suppress ? 'unlockTitle' : 'sizeTitle');
    }
}

# Execute the actual byte sizing and string-writing instructions for SBCS/DBCS.
$source =~ /; Counts passed to LMemInsertAt[^\n]*\n\s*;\s*\n(.*?)unlockTitle:/s
    or die "title insertion missing\n";
my $insertion = $1;
for my $width (1, 2) {
    my @code;
    for (split /\n/, $insertion) {
        s/;.*//;
        next if /^\s*$/;
        if (/^DBCS\s*<(.*?)>/) { next if $width == 1; $_ = $1; }
        s/^\s+|\s+$//g;
        push @code, $_;
    }
    for my $title ('Sketch', 'GeoDraw', 'x' x 1024, "\x{100}\x{4e00}") {
        next if $width == 1 && $title =~ /[^\x00-\xff]/;
        my $format = $width == 1 ? 'C*' : 'v*';
        my $app = 'GeoDraw';
        my %reg = (ds => 1, es => 2, di => 2004, cx => 0);
        my %ptr = ('1:64' => 1000, '2:80' => 2000);
        my %data = (
            1 => "\0" x 1004 . pack($format, unpack('U*', "$app\0")),
            2 => "\0" x 2004 . pack($format, unpack('U*', "$title\0")),
        );
        my @stack;
        my $read = sub {
            my ($op) = @_;
            return $reg{$op} if exists $reg{$op};
            return 64 if $op eq 'ss:[appChunk]';
            return 80 if $op eq 'ss:[textMkr].offset';
            return 4 if $op eq 'VM_data+VMT_text';
            return 3 * $width if $op eq '3 * size TCHAR';
            return ord($1) if $op =~ /^'(.)'$/;
            return $ptr{"$reg{$1}:$reg{$2}"} // die "bad chunk $op\n"
                if $op =~ /^(ds|es):\[(si|di)\]$/;
            die "unknown insertion operand $op\n";
        };
        for (@code) {
            if (/^(mov|add)\s+(\w+),\s*(.+)$/) {
                my ($op, $dest, $value) = ($1, $2, $read->($3));
                $reg{$dest} = ($op eq 'add' ? $reg{$dest} : 0) + $value;
            } elsif (/^shl\s+cx, 1$/) { $reg{cx} *= 2;
            } elsif (/^push\s+cx$/) { push @stack, $reg{cx};
            } elsif (/^pop\s+cx$/) { $reg{cx} = pop @stack;
            } elsif (/^segxchg\s+ds, es$/) { @reg{qw(ds es)} = @reg{qw(es ds)};
            } elsif ($_ eq 'LocalStrLength') {
                $reg{cx} = 0;
                my $pos = $reg{di};
                $reg{cx}++, $pos += $width
                    while substr($data{$reg{es}}, $pos, $width) ne "\0" x $width;
                $reg{di} = $pos + $width;
                $reg{ax} = 0;
            } elsif (/^call\s+LMemInsertAt$/) {
                die "wrong insertion size\n" unless $reg{cx} == (length($title) + 3) * $width;
                die "wrong insertion offset\n" unless $reg{bx} == 4 + length($app) * $width;
                my $base = $ptr{"$reg{ds}:$reg{ax}"};
                substr($data{$reg{ds}}, $base + $reg{bx}, 0) = "\0" x $reg{cx};
                # Move the chunk to catch stale pointers after LMemInsertAt.
                $data{$reg{ds}} = "\0" x 1200 . substr($data{$reg{ds}}, $base);
                $ptr{"$reg{ds}:$reg{ax}"} = 1200;
            } elsif (/^jc\s+unlockTitle$/ || /^appendTitle:$/) {
            } elsif (/^clr\s+ds:\[di\].VM_width$/) {
                substr($data{$reg{ds}}, $reg{di}, 2) = "\0\0";
            } elsif (/^LocalPutChar\s+esdi, ax$/) {
                substr($data{$reg{es}}, $reg{di}, $width) = pack($format, $reg{ax});
                $reg{di} += $width;
            } elsif ($_ eq 'LocalCopyString') {
                my $char;
                do {
                    $char = substr($data{$reg{ds}}, $reg{si}, $width);
                    die "copy past source\n" unless length($char) == $width;
                    substr($data{$reg{es}}, $reg{di}, $width) = $char;
                    $reg{si} += $width;
                    $reg{di} += $width;
                } while ($char ne "\0" x $width);
            } else { die "unhandled insertion instruction $_\n"; }
        }
        my $actual = substr($data{1}, $ptr{'1:64'} + 4);
        die "wrong combined title, character width $width\n"
            unless $actual eq pack($format, unpack('U*', "$app - $title\0"));
        die "unbalanced title insertion stack\n" if @stack;
    }
}
print "taskbar title selection and composition checks passed\n";
