#!/usr/bin/perl
# Host-side INI contract fixtures. Does not execute the GEOS assembly.
# Run: perl Library/Kernel/Initfile/Tests/tombstones.pl
use strict;
use warnings;

my $checks = 0;
sub Check {
    my ($ok, $name) = @_;
    die "FAIL: $name\n" unless $ok;
    ++$checks;
}

sub Deleted {
    return $_[0] =~ /\A[ \t]*\@deleted[ \t]*(?:;[^\r\n\x1a\0]*)?(?:[\r\n\x1a\0]|\z)/;
}

# Each hash is one INI layer, in priority order; values retain raw syntax.
sub ReadValues {
    my ($layers, $key, $first, $all) = @_;
    my @values;
    for my $i (0 .. ($first ? 0 : $#$layers)) {
        next unless exists $layers->[$i]{$key};
        my $raw = $layers->[$i]{$key};
        last if Deleted($raw);
        push @values, $raw;
        last unless $all;
    }
    return @values;
}

sub DeleteKey {
    my ($layers, $key) = @_;
    return if exists $layers->[0]{$key} && Deleted($layers->[0]{$key});
    my @lower = @$layers[1 .. $#$layers];
    if (@lower && ReadValues(\@lower, $key, 0, 0)) {
        $layers->[0]{$key} = '@deleted';
    } else {
        delete $layers->[0]{$key};
    }
}

sub WriteString {
    my ($layers, $key, $value) = @_;
    $layers->[0]{$key} = ($value eq '' || Deleted($value)) ? "{$value}" : $value;
}

sub ReadTyped {
    my ($layers, $key, $type, $default) = @_;
    my @raw = ReadValues($layers, $key, 0, 0);
    return (1, $default) unless @raw;
    my $value = $raw[0];
    $value =~ s/\A\{(.*)\}\z/$1/s;
    $value = ($value eq 'true' ? 1 : 0) if $type eq 'boolean';
    return (0, $value);
}

for my $raw ('@deleted', " \t\@deleted\t ", '@deleted; note',
             "\@deleted \t; note\r\nnext = true", "\@deleted\r\n",
             "\@deleted\n", "\@deleted\x1a", "\@deleted\0") {
    Check(Deleted($raw), 'complete bare marker');
}
for my $raw ('', '{}', '@Deleted', '@DELETED', '@deletedLater',
             '@deleted later', '@ deleted', '{@deleted}',
             "{\r\n\@deleted\r\n}", ';@deleted', '\@deleted') {
    Check(!Deleted($raw), 'ordinary data is not a marker');
}
for my $end (0 .. 7) {
    Check(!Deleted(substr('@deleted', 0, $end)), 'truncated marker');
}

for my $type ('string', 'data', 'integer', 'boolean') {
    my %values = (string => 'factory', data => '4142',
                  integer => '42', boolean => 'true');
    my $layers = [{}, {value => $values{$type}}];
    DeleteKey($layers, 'value');
    Check($layers->[0]{value} eq '@deleted', "$type inherited deletion");
    my ($error, $output) = ReadTyped($layers, 'value', $type, 'unchanged');
    Check($error && $output eq 'unchanged', "$type missing preserves output");
    Check(!ReadValues($layers, 'value', 1, 0), "$type primary-only missing");
    Check(!ReadValues($layers, 'value', 0, 1), "$type read-all missing");
    $layers->[1] = {};
    DeleteKey($layers, 'value');
    Check($layers->[0]{value} eq '@deleted', 'retain marker without lower key');
    $layers->[1]{value} = 'new factory';
    Check(!ReadValues($layers, 'value', 0, 0), 'retain marker across factory update');
    $layers->[0]{value} = $values{$type};
    Check(ReadValues($layers, 'value', 0, 0) == 1, "$type replacement write");
}

for my $raw ('0', 'false', '{}') {
    my $layers = [{}, {value => $raw}];
    DeleteKey($layers, 'value');
    Check($layers->[0]{value} eq '@deleted', 'lower empty, zero and false keys exist');
}
my $future = [{value => 'local'}, {}];
DeleteKey($future, 'value');
$future->[1]{value} = 'new factory';
Check((ReadValues($future, 'value', 0, 0))[0] eq 'new factory',
      'new factory key appears after a local-only deletion');

my $layers = [{value => 'local'}, {value => 'factory'}];
DeleteKey($layers, 'value');
Check($layers->[0]{value} eq '@deleted', 'local override deletion');
DeleteKey($layers, 'value');
Check($layers->[0]{value} eq '@deleted', 'repeated deletion');
my $saved = [{%{$layers->[0]}}, {%{$layers->[1]}}];
Check(!ReadValues($saved, 'value', 0, 0), 'saved marker survives reload');
delete $saved->[0]{value};
Check((ReadValues($saved, 'value', 0, 0))[0] eq 'factory', 'manual inheritance reset');

for my $layers ([{value => 'local'}], [{value => 'local'}, {}], [{}, {}]) {
    DeleteKey($layers, 'value');
    Check(!exists $layers->[0]{value}, 'no lower value means physical deletion');
}
$layers = [{value => 'local'}, {value => '@deleted'}, {value => 'factory'}];
DeleteKey($layers, 'value');
Check(!exists $layers->[0]{value}, 'lower barrier means no effective factory value');
Check(!ReadValues($layers, 'value', 0, 0), 'lower barrier blocks third layer');
$layers->[0]{value} = 'local';
Check(join(',', ReadValues($layers, 'value', 0, 1)) eq 'local',
      'read-all keeps contributions before a barrier');
$layers = [{value => 'local'}, {}, {value => 'factory'}];
DeleteKey($layers, 'value');
Check($layers->[0]{value} eq '@deleted', 'find lower key across missing layer');

$layers = [{}, {value => 'factory'}];
WriteString($layers, 'value', '@deleted');
Check($layers->[0]{value} eq '{@deleted}', 'literal marker is enclosed');
Check((ReadTyped($layers, 'value', 'string', 'default'))[1] eq '@deleted',
      'literal marker round trip');
WriteString($layers, 'value', '');
Check((ReadTyped($layers, 'value', 'string', 'default'))[1] eq '', 'empty string');
DeleteKey($layers, 'value');
Check($layers->[0]{value} eq '@deleted', 'empty local value still masks a factory key');

# List fixtures retain the existing exact-entry sidecar and rewrite snapshot.
sub ReadList {
    my ($layers) = @_;
    return () if exists $layers->[0]{items} && Deleted($layers->[0]{items});
    my %disabled = map {$_ => 1} split /,/, ($layers->[0]{'items.disabled'} || '');
    my %seen;
    my @lower = @$layers[1 .. $#$layers];
    my @factory = grep {!$disabled{$_}}
                  map {split /,/} ReadValues(\@lower, 'items', 0, 1);
    my @local = map {split /,/} ReadValues($layers, 'items', 1, 0);
    return grep {!$seen{$_}++} (@factory, @local);
}

$layers = [{'items.disabled' => 'A'}, {items => 'A,B'}];
my @lower = @$layers[1 .. $#$layers];
my @snapshot = split /,/, (ReadValues(\@lower, 'items', 0, 0))[0];
DeleteKey($layers, 'items');
Check(!ReadList($layers), 'whole-list marker blocks merging');
Check(join(',', @snapshot) eq 'A,B', 'snapshot reads below primary marker');
$layers->[0]{'items.disabled'} = join(',', @snapshot);
Check(!ReadList($layers), 'commit snapshot does not remove whole-key marker');
# First append restores B by matching the factory snapshot, with no local write.
delete $layers->[0]{items};
@snapshot = grep {$_ ne 'B'} @snapshot;
$layers->[0]{'items.disabled'} = join(',', @snapshot);
Check(!exists $layers->[0]{items}, 'factory-match optimization skips local write');
Check(join(',', ReadList($layers)) eq 'B', 'rewrite clears whole-key marker');
Check($layers->[0]{'items.disabled'} eq 'A', 'existing disabled item stays disabled');
$layers->[0]{items} = 'C';
Check(join(',', ReadList($layers)) eq 'B,C', 'local list item merges normally');
$layers->[1]{items} = 'A,B,D';
Check(join(',', ReadList($layers)) eq 'B,D,C', 'new factory list item remains visible');

print "PASS: $checks host-side contract checks (GEOS assembly not executed)\n";
