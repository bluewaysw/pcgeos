#!/usr/bin/env perl
# Run from any directory: perl Library/SpecUI/CommonUI/tests/taskbar-menu.pl
# Execute the actual capability-selection instructions, without running GEOS.
use strict;
use warnings;
use FindBin;

sub read_file {
    open my $fh, '<', $_[0] or die "$!\n";
    local $/;
    my $s = <$fh>;
    $s =~ s/\r//g;
    return $s;
}
my $root = "$FindBin::Bin/../../../..";
my $base = read_file("$FindBin::Bin/../CWin/cwinBase.asm");
my %mask;
for my $source (
    read_file("$root/Include/Internal/SpecUI/olWinClass.def"),
    read_file("$FindBin::Bin/../cConstant.def"),
    read_file("$FindBin::Bin/../CWin/cwinClassCUAS.asm")) {
    $source =~ s/;[^\n]*//g;
    while ($source =~ /\w+\s+record\b(.*?)\w+\s+end\b/sg) {
        my @fields = $1 =~ /(\w*):\s*(\d+)/g;
        my $shift = 0;
        while (@fields) {
            my $width = pop @fields;
            my $name = pop @fields;
            $mask{$name} = ((1 << $width) - 1) << $shift if length $name;
            $shift += $width;
        }
    }
}
sub bits { my $v = 0; $v |= $mask{$_} // die "Unknown mask $_\n" for @_; $v }
my ($code) = $base =~ /GetTaskMenuState proc near(.*?)GetTaskMenuState endp/s;
$code =~ s/.*?add\s+di,\s*ds:\[di\]\.Vis_offset\s+//s;
$code =~ s/;[^\n]*//g;
my @code = grep length, map { s/^\s+|\s+$//gr } split /\n/, $code;
my %label;
for (0 .. $#code) { $label{$1} = $_ if $code[$_] =~ /^(\w+):$/ }
sub execute {
    my ($mem) = @_;
    my ($pc, $al, $zero) = (0, 0, 0);
    for (1 .. 100) {
        my $op = $code[$pc++];
        next if $op =~ /:$|^\.leave$|^segmov/;
        return $al if $op eq 'ret';
        if ($op =~ /^clr\s+ax$/) { $al = 0; $zero = 1 }
        elsif ($op =~ /^test\s+.*?(OLWI_\w+|olExtWinAttrs)\]?,\s*mask (\w+)$/) {
            $zero = !($mem->{$1} & bits($2));
        } elsif ($op =~ /^tst\s+.*?\.(VCI_window)$/) { $zero = !$mem->{$1} }
        elsif ($op =~ /^ornf\s+al,\s*mask (\w+)$/) { $al |= bits($1); $zero = !$al }
        elsif ($op =~ /^(jz|jmp)\s+(\w+)$/) { $pc = $label{$2} if $1 eq 'jmp' || $zero }
        else { die "Unsupported capability instruction: $op\n" }
    }
    die "Capability selection did not return\n";
}

# Check the complete state/capability matrix against window-menu semantics.
my @attr = qw(OWA_CLOSABLE OWA_MINIMIZABLE OWA_MAXIMIZABLE OWA_MOVABLE OWA_RESIZABLE);
my $cases = 0;
for my $caps (0 .. 31) {
    my $attrs = bits(@attr[grep { $caps & (1 << $_) } 0 .. $#attr]);
    for my $min (0, 1) { for my $max (0, 1) { for my $restore (0, 1) {
        for my $realized (0, 1) { for my $ext (0 .. 3) {
            my $state = ($min ? bits('OLWSS_MINIMIZED') : 0) |
                        ($max ? bits('OLWSS_MAXIMIZED') : 0);
            my %mem = (OLWI_attrs => $attrs, OLWI_specState => $state,
                OLWI_fixedAttr => $restore ? bits('OWFA_RESTORABLE') : 0,
                VCI_window => $realized,
                olExtWinAttrs => ($ext & 1 ? bits('EWA_MOVABLE') : 0) |
                                 ($ext & 2 ? bits('EWA_RESIZABLE') : 0));
            my $want = 0;
            $want |= bits('OLWSI_CLOSABLE') if $caps & 1;
            $want |= bits('OLWSI_MINI') if ($caps & 2) && !$min;
            $want |= bits('OLWSI_MAXI') if ($caps & 4) && ($min ? $restore : !$max);
            $want |= bits('OLWSI_RESTORE') if $restore && ($min || $max);
            $want |= bits('OLWSI_MOVE') if ($caps & 8) && !$min && $realized && ($ext & 1);
            $want |= bits('OLWSI_SIZE') if ($caps & 16) && !$min && $realized && ($ext & 2);
            die "Wrong commands: caps=$caps min=$min max=$max restore=$restore realized=$realized ext=$ext\n"
                unless execute(\%mem) == $want;
            ++$cases;
        } }
    } } }
}

# UIC order must agree with the one permission/dispatch table used by ESP.
my $ui = read_file("$FindBin::Bin/../CSpec/cspecCUAS.ui");
my ($children) = $ui =~ /TaskMenu = TaskBarMenu \{.*?children = ([^;]+);/s;
my @items = $children =~ /(Task\w+)/g;
my ($table) = $base =~ /taskMenuCommands label word(.*?)TASK_MENU_COMMAND_COUNT/s;
my @messages = $table =~ /word\s+(MSG_\w+),/g;
die "Wrong menu size\n" unless @items == 6 && @messages == 6;
for (0 .. 5) {
    die "Menu/command order differs for $items[$_]\n"
        unless $ui =~ /\Q$items[$_]\E = GenTrigger \{[^}]*action = MSG_TASK_BAR_MENU_COMMAND, TaskMenu;[^}]*word \Q$messages[$_]\E\b/s;
}
print "Taskbar menu: $cases capability cases and menu/command alignment passed\n";
