#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin;
use File::Find qw(find);

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
#include <dos.h>
#include <io.h>
#include <process.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int TestInt86(int number, union REGS *in, union REGS *out);
static int TestRename(const char *oldP, const char *newP);
static unsigned TestWrite(int fileH, const void __far *dataP,
                          unsigned count, unsigned *writtenP);
static unsigned TestClose(int fileH);
#define rename TestRename
#define _dos_write TestWrite
#define _dos_close TestClose
#define int86 TestInt86
#define main LauncherMain
C
open my $source, '>>', "$tmp/probe.c" or die $!;
print {$source} "#include \"$root/Tools/gsetup/gsetup.c\"\n";
print {$source} <<'C';
#undef main
#undef int86
#undef rename
#undef _dos_write
#undef _dos_close
#undef assert
#define assert(c) ((c) ? (void)0 : \
    (printf("FAIL line %u: %s\n", __LINE__, #c), exit(1)))

static unsigned limit = 12;
static unsigned errors[26];
static int failMode;
static int renameCount;

static int TestRename(const char *oldP, const char *newP)
{
    if (failMode == 4 && strcmp(oldP, "GFS.INI") == 0)
        return -1;
    if (strcmp(newP, "GFS.INI") == 0 &&
        ((failMode == 3 && renameCount++ == 0) || failMode == 5))
        return -1;
    return rename(oldP, newP);
}

static unsigned TestWrite(int fileH, const void __far *dataP,
                          unsigned count, unsigned *writtenP)
{
    return _dos_write(fileH, dataP, failMode == 1 ? count - 1 : count,
                      writtenP);
}

static unsigned TestClose(int fileH)
{
    unsigned error;

    error = _dos_close(fileH);
    return failMode == 2 ? 5 : error;
}

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
    unsigned i;
    FILE *file;
    char mode[16];
    char command[180];
    char *drive;
    int remove;
    char *args[] = { "gsetup", "install", "extra" };
    char *check[] = { "gsetup", "/CHECKDRIVE", "d:" };
    char *quiet[] = { "gsetup", "/QUIET", "C:\\PROBE.EXE", "noise", NULL };
    const char *tail = "/C C:\\DIST\\gsetup.bat C:\\DIST D: install extra";

    if (argc == 1) {
        assert(LauncherMain(2, quiet) == 1);
        quiet[2] = "";
        assert(LauncherMain(3, quiet) == 1);
        memset(command, 'X', sizeof(command) - 1);
        command[sizeof(command) - 1] = 0;
        quiet[2] = command;
        assert(LauncherMain(3, quiet) == 1);
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

        mkdir("NATIVE");
        assert(chdir("NATIVE") == 0);
        strcpy(launcherDir, "C:\\dist\\..\\dist");
        for (i = 1; i <= 5; i++) {
            file = fopen("GFS.INI", "wb");
            assert(file != NULL);
            fputs("ORIGINAL", file);
            fclose(file);
            failMode = i;
            renameCount = 0;
            assert(WriteGfsIni("NET.INI") == 1);
            file = fopen(i == 5 ? comspecPath : "GFS.INI", "rb");
            assert(file != NULL);
            assert(fread(command, 1, 8, file) == 8);
            assert(memcmp(command, "ORIGINAL", 8) == 0);
            fclose(file);
            if (i == 5)
                assert(rename(comspecPath, "GFS.INI") == 0);
            file = fopen(cwdPath, "rb");
            assert(file == NULL); /* Failed output must be removed. */
        }
        failMode = 0;
        assert(WriteGfsIni("NETEC.INI") == 0);
        memset(launcherDir, 'X', 60);
        launcherDir[60] = 0;
        assert(WriteGfsIni("NET.INI") == 1);
        assert(chdir("..") == 0);
        puts("PASS: short write, close, rename, rollback and path limit");
        return 0;
    }

    if (strcmp(argv[1], "noise") == 0 || strcmp(argv[1], "/C") == 0) {
        file = fopen("NOISE.RUN", "w");
        assert(file != NULL);
        fclose(file);
        puts("PROBE STDOUT");
        fputs("PROBE STDERR\n", stderr);
        return 37;
    }

    if (strcmp(argv[1], "quiet") == 0) {
        /* Capture both inherited handles, without shell-specific syntax. */
        assert(dup2(1, 2) == 0);
        assert(spawnl(P_WAIT, "C:\\GSETUP.EXE", "gsetup", "/QUIET",
                      "C:\\PROBE.EXE", "noise", (void*)0) >= 0);
        file = fopen("NOISE.RUN", "r");
        assert(file != NULL);
        fclose(file);
        assert(spawnl(P_WAIT, "C:\\GSETUP.EXE", "gsetup", "/QUIET",
                      "NOSUCHXX", (void*)0) >= 0);
        /* The emulator shell returns zero. Use a shell stub for status. */
        assert(putenv("COMSPEC=C:\\PROBE.EXE") == 0);
        assert(spawnl(P_WAIT, "C:\\GSETUP.EXE", "gsetup", "/QUIET",
                      "test", (void*)0) == 37);
        puts("PASS: quiet stdout");
        fflush(stdout);
        fputs("PASS: quiet stderr\n", stderr);
        return 0;
    }

    if (strcmp(argv[1], "readonly") == 0) {
        assert(_dos_setfileattr("GFS.INI", _A_RDONLY) == 0);
        return 0;
    }

    if (strcmp(argv[1], "move") == 0) {
        assert(rename(argv[2], argv[3]) == 0);
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
        puts("PROBE STDOUT");
        fputs("PROBE STDERR\n", stderr);
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
make_path("$tmp/DIST/SETUP/INSTALL", "$tmp/DIST/BOOT");
write_file('DIST/SETUP/INSTALL/GEOS.INI', "test\r\n");
write_file('DIST/SETUP/ACTIVATE/VERSION.TXT', "test\r\n");
# A reused build tree can contain the removed template. Never copy it.
write_file('DIST/SETUP/ACTIVATE/GFS.INI', "STALE\r\n");
for my $file ('GFS.IMG', 'NET.INI', 'NETEC.INI') {
    write_file("DIST/BOOT/$file", "test\r\n");
}
open my $generator, '<:raw', "$root/Tools/build/product/bbxensem/Scripts/buildbbx.pl"
    or die $!;
my $build_source = do { local $/; <$generator> };
close $generator;
$build_source =~ /(sub GenerateFreeGEOSSetupCopyScript \{.*?^\})/ms
    or die "Cannot find copy-script generator\n";
our %RealInfo;
{
    no strict 'vars';
    eval $1;
}
die $@ if $@;
for my $ec ('n', 'y') {
    $RealInfo{ec} = $ec;
    GenerateFreeGEOSSetupCopyScript("$tmp/DIST/SETUP/ACTIVATE",
        "$tmp/DIST/gact.bat", 'SETUP\\ACTIVATE');
    my $generated = read_file('DIST/gact.bat');
    my $ini = $ec eq 'y' ? 'NETEC.INI' : 'NET.INI';
    $generated =~ /%2\\GSETUP\.EXE \/WRITEGFS \Q$ini\E\r\n\z/
        or die "Wrong writer call: $generated\n";
    $generated !~ /^copy .*GFS\.INI/m or die "Stale GFS.INI copy remains\n";
    if ($ec eq 'y') {
        batch('GACTEC.BAT', $generated);
    }
}
{
    local @ARGV = ('ec=true', 'ec=false', 'ec=true');
    $RealInfo{ec} = 'n';
    GenerateFreeGEOSSetupCopyScript("$tmp/DIST/SETUP/ACTIVATE",
        "$tmp/DIST/gact.bat", 'SETUP\\ACTIVATE');
    read_file('DIST/gact.bat') =~ /\/WRITEGFS NETEC\.INI\r\n\z/
        or die "EC command-line override was ignored\n";
}
$RealInfo{ec} = 'n';
GenerateFreeGEOSSetupCopyScript("$tmp/DIST/SETUP/INSTALL",
    "$tmp/DIST/ginst.bat", 'SETUP\\INSTALL');
GenerateFreeGEOSSetupCopyScript("$tmp/DIST/SETUP/ACTIVATE",
    "$tmp/DIST/gact.bat", 'SETUP\\ACTIVATE');
for my $phase ('inst', 'act') {
    my $generated = read_file("DIST/g$phase.bat");
    my $label = $phase eq 'inst' ? 'INSTALL' : 'ACTIVATE';
    $generated =~ s/(\@echo off\r\n)/$1echo $label %1>>COPY.LOG\r\n/;
    write_file("DIST/g$phase.bat", $generated);
}

sub distribution {
    my ($path, $real) = @_;
    make_path("$tmp/$path/BOOT");
    for my $file ('gsetup.exe', 'ginst.bat', 'gact.bat') {
        copy("$tmp/DIST/$file", "$tmp/$path/$file") or die $!;
    }
    write_file("$path/gsetup.bat", $real ? $original : $script);
    for my $file ('GFS.IMG', 'NET.INI', 'NETEC.INI') {
        copy("$tmp/DIST/BOOT/$file", "$tmp/$path/BOOT/$file") or die $!;
    }
}
# Copy scripts need their fixture payloads only in DIST. Other path tests
# invoke the native writer directly after the common activation tests.
distribution('REAL', 1);
make_path("$tmp/REAL/SETUP/INSTALL", "$tmp/REAL/SETUP/ACTIVATE");
copy("$tmp/DIST/SETUP/INSTALL/GEOS.INI", "$tmp/REAL/SETUP/INSTALL/GEOS.INI") or die $!;
copy("$tmp/DIST/SETUP/ACTIVATE/VERSION.TXT", "$tmp/REAL/SETUP/ACTIVATE/VERSION.TXT") or die $!;

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
    ['NOGFS', 'E', '', 'Cannot generate GFS.INI.', 'EE', 1, 'D'],
    ['REAL', 'E', '', 'Install complete.', '', 0, 'D'],
);
my $runner = "\@echo off\nc:\\probe.exe >c:\\NATIVE.LOG\n" .
    "c:\\probe.exe quiet >c:\\QUIET.LOG\n";
for my $case (@cases) {
    my ($name, $mode, $invocation) = @$case;
    make_path("$tmp/$name");
    write_file("$name/mode.txt", "$mode\n");
    write_file("$name/update.txt", "test\n") unless $name eq 'NOOP';
    write_file("$name/geos.ini", "test\n")
        if $name =~ /^(UPDATE|EXPLICIT|NOOP)$/;
    write_file("$name/gfs.ini", "test\n") if $name eq 'NOOP';
    write_file("$name/GFS.INI", "ORIGINAL") if $name eq 'NOGFS';
    $runner .= "cd \\$name\n";
    $runner .= "c:\\probe.exe readonly\n" if $name eq 'NOGFS';
    $runner .= "z:\\subst D: C:\\EMPTY\n" if $name =~ /^(NEXT|BUSY)$/;
    my $distribution = $name eq 'REAL' ? 'real' : 'dist';
    $runner .= $invocation =~ /^direct (.+)$/
        ? "%COMSPEC% /c c:\\dist\\gsetup.bat c:\\dist $1 >RESULT.LOG\n"
        : "c:\\$distribution\\gsetup.exe $invocation >RESULT.LOG\n";
    $runner .= "c:\\probe.exe status $case->[6]: >STATUS.LOG\n";
    $runner .= "z:\\subst $case->[6]: /D\n" if $name =~ /^(CLEAN|POST|BUSY)$/;
    $runner .= "z:\\subst D: /D\n" if $name eq 'NEXT';
}
my @paths = (
    ['SAME', 'SAME/FREEGEOS/V1', 'c:\\same\\freegeos\\v1', 'NET.INI', 'FREEGEOS\\V1\\BOOT'],
    ['DOTS', 'DOTS/FREEGEOS/V1', 'c:\\dots\\freegeos\\v1\\..\\v1', 'NETEC.INI', 'FREEGEOS\\V1\\BOOT'],
    ['PREFIX', 'PREFIX2/FREEGEOS/V1', 'c:\\prefix2\\freegeos\\v1', 'NET.INI', 'C:\\PREFIX2\\FREEGEOS\\V1\\BOOT'],
    ['OTHER', 'REMOTE/FREEGEOS/V1', 'e:\\remote\\freegeos\\v1', 'NETEC.INI', 'E:\\REMOTE\\FREEGEOS\\V1\\BOOT'],
    ['LIMIT', 'LIMIT/AAAAAAAA/BBBBBBBB/CCCCCCCC/DDDDDDDD/EEEEEEEE',
     'c:\\limit\\aaaaaaaa\\bbbbbbbb\\cccccccc\\dddddddd\\eeeeeeee',
     'NET.INI', 'AAAAAAAA\\BBBBBBBB\\CCCCCCCC\\DDDDDDDD\\EEEEEEEE\\BOOT'],
);
for my $case (@paths) {
    my ($local, $source, $dos, $ini) = @$case;
    make_path("$tmp/$local");
    distribution($source, 1);
    $runner .= "cd \\$local\n";
    $runner .= "z:\\subst E: C:\\\n" if $local eq 'OTHER';
    $runner .= "$dos\\gsetup.exe /WRITEGFS $ini >RESULT.LOG\n";
    $runner .= "echo test>GEOS.INI\n" if $local eq 'SAME';
    $runner .= "z:\\subst E: /D\n" if $local eq 'OTHER';
}
$runner .= "cd \\\nc:\\probe.exe move C:\\SAME C:\\MOVED\ncd \\MOVED\n";
$runner .= "freegeos\\v1\\gsetup.exe >MOVE.LOG\n";
$runner .= "cd \\\nc:\\dist\\gsetup.exe /WRITEGFS NET.INI >ROOT.LOG\n";
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
read_file('QUIET.LOG') eq "PASS: quiet stdout\r\nPASS: quiet stderr\r\n"
    or die "Quiet probe output or handle restore failed: " . read_file('QUIET.LOG');
print "PASS: quiet commands, child exit code and parent output handles\n";

for my $case (@cases) {
    my ($name, $mode, $invocation, $message, $calls, $marker, $drive) = @$case;
    my $output = read_file("$name/RESULT.LOG");
    index($output, $message) >= 0 or die "$name: $output\n";
    $output !~ /PROBE (?:STDOUT|STDERR)|Illegal command|Bad command/i
        or die "$name: mapping probe output: $output\n";
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
    if ($name eq 'NOGFS') {
        read_file("$name/GFS.INI") eq 'ORIGINAL'
            or die "Writer failure replaced the old GFS.INI\n";
    } elsif ($message =~ /complete\./ && $name ne 'NOOP') {
        my $gfs = read_file("$name/GFS.INI");
        my $image = $name eq 'REAL' ? 'BOOT\\GFS.IMG' : 'C:\\DIST\\BOOT\\GFS.IMG';
        index($gfs, "file = $image\r\n") >= 0
            or die "$name: wrong image path: $gfs\n";
    }
    print "PASS: $name\n";
}

for my $case (@paths, ['ROOT', 'DIST', 'c:\\dist', 'NET.INI', 'DIST\\BOOT']) {
    my ($local, $source, $dos, $ini, $boot) = @$case;
    my $folder = $local eq 'ROOT' ? '' : ($local eq 'SAME' ? 'MOVED/' : "$local/");
    my $gfs = read_file("${folder}GFS.INI");
    for my $entry ("fs = MEGAFILE.GEO", "top = $boot GFS:\\FG",
                   "ini = $boot\\$ini", "file = $boot\\GFS.IMG",
                   "bootstrapPath = $boot") {
        index($gfs, "$entry\r\n") >= 0 or die "$local: wrong GFS.INI: $gfs\n";
    }
    for my $line ($gfs =~ /^(?:fs|top|ini|file|bootstrapPath) = (.*)/mg) {
        $line eq uc($line) or die "$local: lowercase path: $line\n";
    }
    print "PASS: $local uppercase paths ($ini)\n";
}
read_file('MOVED/MOVE.LOG') =~ /Startup check complete/
    or die "Moved installation did not keep its normal startup path\n";
print "PASS: moved combined installation\n";
