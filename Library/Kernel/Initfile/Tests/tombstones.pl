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
    my ($layers, $key) = @_;
    $key = 'items' unless defined $key;
    return () if exists $layers->[0]{$key} && Deleted($layers->[0]{$key});
    my %disabled = map {$_ => 1} split /,/, ($layers->[0]{"$key.disabled"} || '');
    my %seen;
    my @lower = @$layers[1 .. $#$layers];
    my @factory = grep {!$disabled{$_}}
                  map {split /,/} ReadValues(\@lower, $key, 0, 1);
    my @local = map {split /,/} ReadValues($layers, $key, 1, 0);
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

# Operation fixtures model a pending rewrite of one known list key.
# Snapshots and layer hashes are separate, as they are in the kernel.
sub PublishRewrite {
    my ($state) = @_;
    return unless exists $state->{snapshot};
    my $key = "$state->{key}.disabled";
    if (@{$state->{snapshot}}) {
        $state->{layers}[0]{$key} = join(',', @{$state->{snapshot}});
    } else {
        delete $state->{layers}[0]{$key};
    }
}

sub FinishRewrite {
    my ($state) = @_;
    PublishRewrite($state);
    delete $state->{snapshot};
    delete $state->{key};
}

sub BeginRewrite {
    my ($state, $key) = @_;
    FinishRewrite($state);
    DeleteKey($state->{layers}, $key);
    my @lower = @{$state->{layers}}[1 .. $#{$state->{layers}}];
    my @raw = ReadValues(\@lower, $key, 0, 0);
    if (@raw) {
        $state->{key} = $key;
        $state->{snapshot} = [split /,/, $raw[0]];
    }
}

sub AppendSection {
    my ($state, $key, $entry) = @_;
    FinishRewrite($state) if exists $state->{key} && $state->{key} ne $key;
    my $primary = $state->{layers}[0];
    delete $primary->{$key} if exists $primary->{$key} && Deleted($primary->{$key});
    my $skip = 0;
    if (exists $state->{snapshot}) {
        my @left = grep {$_ ne $entry} @{$state->{snapshot}};
        $skip = @left != @{$state->{snapshot}};
        $state->{snapshot} = \@left;
    }
    unless ($skip) {
        my @disabled = split /,/, ($primary->{"$key.disabled"} || '');
        my @left = grep {$_ ne $entry} @disabled;
        if (@left != @disabled) {
            if (@left) {
                $primary->{"$key.disabled"} = join(',', @left);
            } else {
                delete $primary->{"$key.disabled"};
            }
        } else {
            $primary->{$key} = join(',', grep {length} ($primary->{$key} || '', $entry));
        }
    }
    PublishRewrite($state);
}

sub DeleteSection {
    my ($state, $key, $index) = @_;
    FinishRewrite($state);
    my @list = ReadList($state->{layers}, $key);
    return if $index > $#list;
    my $entry = $list[$index];
    my @lower = @{$state->{layers}}[1 .. $#{$state->{layers}}];
    my @factory = map {split /,/} ReadValues(\@lower, $key, 0, 0);
    my $primary = $state->{layers}[0];
    if (grep {$_ eq $entry} @factory) {
        $primary->{"$key.disabled"} = join(',',
            grep {length} ($primary->{"$key.disabled"} || '', $entry));
    } else {
        $primary->{$key} = join(',', grep {$_ ne $entry}
            split /,/, ($primary->{$key} || ''));
    }
}

sub SavePrimary {
    my ($state) = @_;
    FinishRewrite($state);
    return {%{$state->{layers}[0]}};
}

sub RemoveCategory {
    my ($state, $category) = @_;
    FinishRewrite($state);
    for my $key (keys %{$state->{layers}[0]}) {
        delete $state->{layers}[0]{$key} if index($key, "$category/") == 0;
    }
}

sub RestorePrimary {
    my ($state, $backup, $failure) = @_;
    # A failed staging step has no effect on the active state.
    return 1 if $failure;
    $state->{layers}[0] = {%$backup};
    delete $state->{snapshot};
    delete $state->{key};
    delete $state->{cache};
    if (exists $state->{hash}) {
        my %keys;
        $keys{$_} = 1 for map {keys %$_} @{$state->{layers}};
        $state->{hash} = [sort keys %keys];
    }
    return 0;
}

my $state = {layers => [{}, {items => 'A,B,C'}]};
BeginRewrite($state, 'items');
AppendSection($state, 'items', 'A');
Check(join(',', ReadList($state->{layers})) eq 'A', 'partial rewrite visible before commit');
Check(!exists $state->{layers}[0]{items}, 'factory match skips the local write');
Check(join(',', @{$state->{snapshot}}) eq 'B,C', 'snapshot retained after publication');
AppendSection($state, 'items', 'B');
Check(join(',', ReadList($state->{layers})) eq 'A,B', 'next factory item can still match');
AppendSection($state, 'items', 'D');
Check(join(',', ReadList($state->{layers})) eq 'A,B,D', 'local write publishes exclusions too');
FinishRewrite($state);
Check(join(',', ReadList($state->{layers})) eq 'A,B,D', 'commit preserves visible rewrite');

$state = {layers => [{'items.disabled' => 'A'}, {items => 'A,B'}]};
BeginRewrite($state, 'items');
AppendSection($state, 'items', 'B');
Check(join(',', ReadList($state->{layers})) eq 'B', 'existing disabled entry retained before commit');
AppendSection($state, 'items', 'A');
Check(!exists $state->{layers}[0]{'items.disabled'}, 'complete rewrite clears empty exclusion sidecar');
Check(join(',', ReadList($state->{layers})) eq 'A,B', 'rewritten disabled factory item restored');

$state = {layers => [{}, {items => 'A,B,C'}]};
BeginRewrite($state, 'items');
AppendSection($state, 'items', 'A');
AppendSection($state, 'items', 'B');
DeleteSection($state, 'items', 0);
Check(join(',', ReadList($state->{layers})) eq 'B', 'item index uses current rewritten list');
FinishRewrite($state);
Check(join(',', ReadList($state->{layers})) eq 'B', 'commit cannot undo item deletion');

BeginRewrite($state, 'items');
AppendSection($state, 'items', 'B');
my $backup = SavePrimary($state);
Check(!exists $state->{snapshot}, 'save finishes pending rewrite');
$state->{layers}[0] = {};
Check(!RestorePrimary($state, $backup, ''), 'restore saved primary');
Check(join(',', ReadList($state->{layers})) eq 'B', 'backup includes pending exclusions');

for my $category ('devices', 'other') {
    $state = {layers => [{'other/key' => 'local'}, {'devices/items' => 'A,B'}]};
    BeginRewrite($state, 'devices/items');
    AppendSection($state, 'devices/items', 'A');
    RemoveCategory($state, $category);
    FinishRewrite($state);
    Check(!grep({index($_, "$category/") == 0} keys %{$state->{layers}[0]}),
          'deleted category stays physically absent after commit');
    if ($category eq 'devices') {
        Check(join(',', ReadList($state->{layers}, 'devices/items')) eq 'A,B',
              'physical category deletion restores factory inheritance');
    } else {
        Check(join(',', ReadList($state->{layers}, 'devices/items')) eq 'A',
              'other category deletion preserves pending list changes');
    }
}

for my $failure ('open', 'size', 'allocation', 'read', 'short read', 'EOF', 'validation') {
    $state = {layers => [{}, {items => 'A,B'}], cache => 123, hash => ['old']};
    BeginRewrite($state, 'items');
    AppendSection($state, 'items', 'A');
    Check(RestorePrimary($state, {}, $failure), "$failure failure reports an error");
    Check(join(',', ReadList($state->{layers})) eq 'A' && $state->{cache} == 123
          && $state->{hash}[0] eq 'old' && join(',', @{$state->{snapshot}}) eq 'B',
          "$failure failure keeps buffer, pending state and cache");
    AppendSection($state, 'items', 'B');
    Check(join(',', ReadList($state->{layers})) eq 'A,B',
          "$failure failure allows rewrite to continue");
}

$state = {layers => [{}, {items => 'A,B', lower => 'unchanged'}],
          cache => 123, hash => ['old']};
BeginRewrite($state, 'items');
AppendSection($state, 'items', 'A');
Check(!RestorePrimary($state, {items => 'C'}, ''), 'successful restore installs backup');
Check(!exists $state->{snapshot} && !exists $state->{cache}, 'restore discards old snapshot and offsets');
Check(join(',', @{$state->{hash}}) eq 'items,lower', 'restore refreshes lookup model for all layers');
Check((ReadValues($state->{layers}, 'lower', 0, 0))[0] eq 'unchanged',
      'successful restore keeps lower buffers');
FinishRewrite($state);
Check($state->{layers}[0]{items} eq 'C' && !exists $state->{layers}[0]{'items.disabled'},
      'commit cannot apply the replaced buffer snapshot');

print "PASS: $checks host-side contract checks (GEOS assembly not executed)\n";
