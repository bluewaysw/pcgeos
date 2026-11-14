#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin;

# Run with: perl Tools/build/product/bbxensem/Tests/gsetup.pl
# Requires Open Watcom and Basebox/DOSBox-staging. No PC/GEOS code is run.
my $root = abs_path("$FindBin::Bin/../../../../..");
my $tmp = tempdir(CLEANUP => 1);
my $watcom = $ENV{WATCOM} or die "Set WATCOM first\n";
my $emulator = $ENV{BASEBOX} || 'basebox';

sub write_file {
    my ($path, $text) = @_;
    open my $file, '>:raw', "$tmp/$path" or die "$path: $!\n";
    print {$file} $text;
    close $file or die "$path: $!\n";
}

sub read_file {
    my ($path) = @_;
    open my $file, '<:raw', "$tmp/$path" or die "$path: $!\n";
    return do { local $/; <$file> };
}

sub batch {
    my ($path, $text) = @_;
    $text =~ s/\r?\n/\r\n/g;
    write_file($path, $text);
}

# Include the production C code. Mock only the DOS assignment queries.
# The same executable also supplies mapper stubs for the real DOS shell.
write_file('probe.c', <<'C');
#include <assert.h>
#include <i86.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int TestInt86(int number, union REGS *in, union REGS *out);
#define int86 TestInt86
#define main LauncherMain
C
open my $source, '>>', "$tmp/probe.c" or die $!;
print {$source} "#include \"$root/Tools/gsetup/gsetup.c\"\n";
print {$source} <<'C';
#undef main
#undef int86
#undef assert
#define assert(c) ((c) ? (void)0 : \
    (printf("FAIL line %u: %s\n", __LINE__, #c), exit(1)))

static unsigned limit = 12;
static unsigned errors[26];

static int TestInt86(int number, union REGS *in, union REGS *out)
{
    assert(number == 0x21);
    *out = *in;
    switch (in->h.ah) {
    case 0x19:
        out->h.al = 2;
        break;
    case 0x0e:
        assert(in->h.dl == 2); /* Must keep C: as the default drive. */
        out->h.al = limit;
        break;
    case 0x44:
        assert(in->h.al == 9 && in->x.bx >= 1 && in->x.bx <= 26);
        out->x.ax = errors[in->x.bx - 1];
        out->x.cflag = out->x.ax != 0;
        break;
    default:
        assert(0);
    }
    return 0;
}

int main(int argc, char **argv)
{
    union REGS regs;
    FILE *file;
    char mode[16];
    char command[180];
    char *drive;
    int remove;
    char *args[] = { "gsetup", "install", "extra" };
    char *check[] = { "gsetup", "/CHECKDRIVE", "d:" };
    const char *tail = "/C C:\\DIST\\gsetup.bat C:\\DIST D: install extra";

    if (argc == 1) {
        errors[3] = 15;
        assert(FindFreeDrive() == 'D');
        assert(CheckDrive(3) == 1); /* Assigned, regardless of media. */
        assert(CheckDrive(4) == 0);
        assert(LauncherMain(3, check) == 0);
        check[2] = "A:";
        assert(LauncherMain(3, check) == 2);
        check[2] = "D:\\";
        assert(LauncherMain(3, check) == 2);
        errors[3] = 5;
        errors[4] = 15;
        assert(CheckDrive(4) == 2);
        assert(FindFreeDrive() == 'E');
        errors[2] = 15;
        assert(FindFreeDrive() == 'C');
        memset(errors, 0, sizeof(errors));
        errors[0] = errors[1] = 15; /* Never use A: or B:. */
        errors[12] = 15;
        assert(FindFreeDrive() == '-'); /* M: is past LASTDRIVE=L. */
        errors[11] = 15;
        assert(FindFreeDrive() == 'L');
        limit = 26;
        errors[11] = 0;
        errors[12] = 0;
        errors[25] = 15;
        assert(FindFreeDrive() == 'Z');
        limit = 30;
        assert(FindFreeDrive() == 'Z');
        limit = 0;
        assert(FindFreeDrive() == '-');
        limit = 12;
        errors[3] = 15;
        strcpy(batchPath, "C:\\DIST\\gsetup.bat");
        strcpy(launcherDir, "C:\\DIST");
        assert(buildCommandTail(3, args));
        assert((unsigned char)cmdTail[0] == strlen(tail));
        assert(memcmp(cmdTail + 1, tail, strlen(tail)) == 0);
        assert(cmdTail[strlen(tail) + 1] == '\r');
        memset(errors, 0, sizeof(errors));
        assert(buildCommandTail(1, args));
        assert(memcmp(cmdTail + cmdTail[0] - 1, " -\r", 3) == 0);
        memset(launcherDir, 'X', sizeof(launcherDir) - 1);
        assert(!buildCommandTail(3, args));
        puts("PASS: drive selection, DOS errors and command tail");
        return 0;
    }

    if (strcmp(argv[1], "status") == 0) {
        memset(&regs, 0, sizeof(regs));
        regs.x.ax = 0x4409;
        regs.x.bx = argv[2][0] - 'A' + 1;
        int86(0x21, &regs, &regs);
        printf("%d\n", !regs.x.cflag ? 1 : regs.x.ax == 15 ? 0 : 2);
        return 0;
    }

    file = fopen("mode.txt", "r");
    assert(file != NULL && fgets(mode, sizeof(mode), file) != NULL);
    fclose(file);
    mode[strcspn(mode, "\r\n")] = 0;
    file = fopen("MAP.LOG", "a");
    assert(file != NULL);
    fprintf(file, "%s %s %s\n", argv[1], argv[2], argv[3]);
    fclose(file);
    remove = strcmp(argv[2], "-d") == 0 || strcmp(argv[3], "/D") == 0;
    drive = strcmp(argv[2], "-d") == 0 ? argv[3] : argv[2];
    if (remove) {
        if (strcmp(mode, "CLEAN") == 0 || strcmp(mode, "POST") == 0)
            return 0;
        sprintf(command, "z:\\subst %s /D", drive);
    } else {
        if (strcmp(mode, "NONE") == 0)
            return 0;
        if (strcmp(mode, "S") == 0 && argv[1][0] != 'S')
            return 0;
        if (strcmp(mode, "W") == 0 && argv[1][0] != 'W')
            return 0;
        sprintf(command, "z:\\subst %s %s", drive,
            argv[1][0] == 'E' &&
            (strcmp(mode, "BAD") == 0 || strcmp(mode, "CLEAN") == 0)
            ? "C:\\EMPTY" : argv[3]);
    }
    system(command);
    return 99; /* A working mapper need not return zero. */
}
C
close $source;

my $cwd = getcwd();
chdir $tmp or die $!;
for my $unit ('probe', 'gsetup') {
    my $input = $unit eq 'probe' ? 'probe.c' : "$root/Tools/gsetup/gsetup.c";
    system('wcl', '-bt=dos', '-ms', '-zq', "-i=$watcom/h",
        "-fe=$unit.exe", $input) == 0 or die "Cannot build $unit\n";
}
chdir $cwd or die $!;

make_path("$tmp/DIST/SETUP/ACTIVATE", "$tmp/EMPTY");
copy("$tmp/gsetup.exe", "$tmp/DIST/gsetup.exe") or die $!;
open my $batch, '<:raw', "$root/Tools/build/product/bbxensem/gsetup/gsetup.bat"
    or die $!;
my $script = do { local $/; <$batch> };
close $batch;
my $original = $script;
# Inject mapper stubs. All IF, GOTO, CALL and checks run in the real DOS shell.
$script =~ s/\bemudrv /c:\\probe.exe E /g;
$script =~ s/\bsubst /c:\\probe.exe S /g;
$script =~ s/\bswsubst /c:\\probe.exe W /g;
write_file('DIST/gsetup.bat', $script);
batch('DIST/ginst.bat', "\@echo off\necho INSTALL %1>>COPY.LOG\necho test>geos.ini\n");
batch('DIST/gact.bat', "\@echo off\necho ACTIVATE %1>>COPY.LOG\nif exist nogfs.tag goto END\ncopy %1\\setup\\activate\\gfs.ini gfs.ini\n:END\n");
write_file('DIST/SETUP/ACTIVATE/gfs.ini', "test\r\n");
make_path("$tmp/REAL/SETUP/ACTIVATE");
for my $file ('gsetup.exe', 'ginst.bat', 'gact.bat', 'SETUP/ACTIVATE/gfs.ini') {
    copy("$tmp/DIST/$file", "$tmp/REAL/$file") or die $!;
}
write_file('REAL/gsetup.bat', $original);

my @cases = (
    # name, mapper mode, invocation, completion, mapper calls, marker, drive
    ['EOK', 'E', '', 'Install complete.', 'EE', 0, 'D'],
    ['SOK', 'S', '', 'Install complete.', 'ESS', 0, 'D'],
    ['WOK', 'W', '', 'Install complete.', 'ESWW', 0, 'D'],
    ['BAD', 'BAD', '', 'Install complete.', 'EESS', 0, 'D'],
    ['NONE', 'NONE', '', 'Cannot map a free setup drive', 'ESW', 1, 'D'],
    ['CLEAN', 'CLEAN', '', 'Cannot confirm removal', 'EE', 1, 'D'],
    ['POST', 'POST', '', 'Cannot confirm removal', 'EE', 1, 'D'],
    ['UPDATE', 'S', '', 'Activate complete.', 'ESS', 0, 'D'],
    ['EXPLICIT', 'E', 'activate', 'Activate complete.', 'EE', 1, 'D'],
    ['NEXT', 'E', '', 'Install complete.', 'EE', 0, 'E'],
    ['BUSY', 'E', 'direct D:', 'occupied or cannot be checked', '', 1, 'D'],
    ['NOFREE', 'E', 'direct -', 'Cannot map a free setup drive', '', 1, 'D'],
    ['NOOP', 'E', 'direct -', 'Startup check complete.', '', 0, 'D'],
    ['ARGS', 'E', 'activate extra', 'Invalid arguments.', '', 1, 'D'],
    ['NOGFS', 'E', '', 'did not provide GFS.INI', 'EE', 1, 'D'],
    ['REAL', 'E', '', 'Install complete.', '', 0, 'D'],
);
my $runner = "\@echo off\nc:\\probe.exe >c:\\NATIVE.LOG\n";
for my $case (@cases) {
    my ($name, $mode, $invocation) = @$case;
    make_path("$tmp/$name");
    write_file("$name/mode.txt", "$mode\n");
    write_file("$name/update.txt", "test\n") unless $name eq 'NOOP';
    write_file("$name/geos.ini", "test\n")
        if $name =~ /^(UPDATE|EXPLICIT|NOOP)$/;
    write_file("$name/gfs.ini", "test\n") if $name eq 'NOOP';
    write_file("$name/nogfs.tag", "test\n") if $name eq 'NOGFS';
    $runner .= "cd \\$name\n";
    $runner .= "z:\\subst D: C:\\EMPTY\n" if $name =~ /^(NEXT|BUSY)$/;
    my $distribution = $name eq 'REAL' ? 'real' : 'dist';
    $runner .= $invocation =~ /^direct (.+)$/
        ? "%COMSPEC% /c c:\\dist\\gsetup.bat c:\\dist $1 >RESULT.LOG\n"
        : "c:\\$distribution\\gsetup.exe $invocation >RESULT.LOG\n";
    $runner .= "c:\\probe.exe status $case->[6]: >STATUS.LOG\n";
    $runner .= "z:\\subst $case->[6]: /D\n" if $name =~ /^(CLEAN|POST|BUSY)$/;
    $runner .= "z:\\subst D: /D\n" if $name eq 'NEXT';
}
batch('run.bat', $runner);

local $ENV{SDL_VIDEODRIVER} = 'dummy';
local $ENV{SDL_AUDIODRIVER} = 'dummy';
open my $saveout, '>&', \*STDOUT or die $!;
open my $saveerr, '>&', \*STDERR or die $!;
open STDOUT, '>', "$tmp/emulator.log" or die $!;
open STDERR, '>&', \*STDOUT or die $!;
my $result = system($emulator, '--noprimaryconf', '--nolocalconf',
    '--set', 'output=texture', '--set', 'mididevice=none', '--exit',
    '-c', "mount c \"$tmp\"", '-c', 'c:', '-c', 'call run.bat');
open STDOUT, '>&', $saveout or die $!;
open STDERR, '>&', $saveerr or die $!;
$result == 0 or die read_file('emulator.log');
-e "$tmp/NATIVE.LOG" or die read_file('emulator.log');
read_file('NATIVE.LOG') =~ /^PASS:/ or die read_file('NATIVE.LOG');
print read_file('NATIVE.LOG');

for my $case (@cases) {
    my ($name, $mode, $invocation, $message, $calls, $marker, $drive) = @$case;
    my $output = read_file("$name/RESULT.LOG");
    index($output, $message) >= 0 or die "$name: $output\n";
    my $log = -e "$tmp/$name/MAP.LOG" ? read_file("$name/MAP.LOG") : '';
    my $actual = join '', $log =~ /^([ESW]) /mg;
    $actual eq $calls or die "$name: wrong mapper sequence: $log\n";
    $log !~ / [A-Z]:/ || $log =~ / \Q$drive\E:/
        or die "$name: wrong setup drive: $log\n";
    (-e "$tmp/$name/update.txt" ? 1 : 0) == $marker
        or die "$name: wrong update marker state\n";
    my $occupied = $name =~ /^(CLEAN|POST|BUSY)$/ ? 1 : 0;
    read_file("$name/STATUS.LOG") =~ /^$occupied\s*$/
        or die "$name: wrong drive state\n";
    my $copies = -e "$tmp/$name/COPY.LOG" ? read_file("$name/COPY.LOG") : '';
    my $expected = $message =~ /complete\./ && $name ne 'NOOP' || $name =~ /^(POST|NOGFS)$/
        ? ($name =~ /^(UPDATE|EXPLICIT)$/ ? '' : "INSTALL $drive:\r\n") . "ACTIVATE $drive:\r\n"
        : '';
    $copies eq $expected or die "$name: wrong copy phases: $copies\n";
    print "PASS: $name\n";
}
