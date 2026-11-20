#!/usr/bin/env perl
# Exercise source-backed routing and cleanup with host event/resource shims.
# No GEOS runtime or decoder scheduling is exercised here.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

open my $source, '<:raw', "$FindBin::Bin/../htmlview/ImportG.goc" or die $!;
local $/;
my $code = <$source>;

sub extract {
    my ($text, $pattern) = @_;
    $text =~ $pattern or die "Cannot extract $pattern\n";
    return $1;
}

my $start = extract($code, qr/^(Boolean ImportThreadEngineStart\(.*?^})/ms);
my $count = extract($start, qr/(word numImportThreads[^;]*;)/);
$start = extract($start, qr/(if \(!G_importThreadStarted\).*?)(?=        \/\* First create)/s);
$start =~ s/#endif\s*\z// or die "Missing creation guard\n";
$start .= "CreateImporter(i);\n}\n#endif\nG_importThreadStarted = TRUE;\n}\n";

my $stop = extract($code, qr/^(void ImportThreadEngineStop\(.*?^})/ms);
$stop = extract($stop, qr/(if \(G_importThreadStarted\).*?)(?=#else\n\s*\@send)/s);
$stop =~ s/\@send\s*,insertAtFront\s*,forceQueue\s*\(G_importThreadObj\[i\]\)::MSG_IMPORT_THREAD_ENGINE_KILL\(\)/KillImporter(G_importThreadObj[i])/s
    or die "Missing shutdown message\n";
$stop .= "#endif\nG_importThreadStarted = FALSE;\n}\n";

my $abort = extract($code, qr/^(void ImportThreadAbortAll\(.*?^})/ms);
$abort = extract($abort, qr/(if \(G_importThreadStarted\).*?)(?=#else)/s);
$abort =~ s/\@send\s*,forceQueue\s*,insertAtFront G_importThreadObj\[i\]::MSG_IMPORT_THREAD_ENGINE_START_ABORT\(\)/QueueAbort(G_importThreadObj[i], 1)/
    or die "Missing front abort event\n";
$abort =~ s/\@send\s*,forceQueue G_importThreadObj\[i\]::MSG_IMPORT_THREAD_ENGINE_END_ABORT\(\)/QueueAbort(G_importThreadObj[i], 0)/
    or die "Missing back abort event\n";
$abort .= "#endif\n}\n";

my $route = extract($code, qr/(int importThread;.*?)(?=\n#endif)/s);
for my $field (qw(importProgressData.IPD_vmFile
                  importProgressData.IPD_loadProgressDataP mimeStatus)) {
    $route .= extract($code, qr/(p_request->\Q$field\E\s*=.*?;)/s) . "\n";
}
$route .= extract($code, qr/(\@send ,forceQueue G_importThreadObj\[importThread\]::\s*MSG_IMPORT_THREAD_ENGINE_IMPORT_GRAPHIC\(mem\)\s*;)/s);
$route =~ s/\@send ,forceQueue G_importThreadObj\[importThread\]::\s*MSG_IMPORT_THREAD_ENGINE_IMPORT_GRAPHIC\(mem\)/QueueImport(G_importThreadObj[importThread], mem)/s;

my $handler = extract($code, qr/^\@method ImportThreadEngineClass, MSG_IMPORT_THREAD_ENGINE_IMPORT_GRAPHIC\n\{(.*?)^}/ms);
my $condition = extract($handler, qr/(if\(pself->numAborts == 0\))/);
my $cleanup = extract($handler, qr/(    else\s*\@send \(request.textObj\)::\s*MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS\(request.name\);\s*#if PROGRESS_DISPLAY.*)\z/s);
$cleanup =~ s/\@send \(request.textObj\)::\s*MSG_URL_TEXT_INTERNAL_CANCEL_LIKE_GRAPHICS\(request.name\)/Cancel(request.textObj, request.name)/;
$cleanup =~ s/\@send \(request.textObj\)::MSG_URL_TEXT_DEC_PENDING\(\)/DecPending(request.textObj)/;
my $begin = extract($code, qr/\@method ImportThreadEngineClass, MSG_IMPORT_THREAD_ENGINE_START_ABORT\s*\{.*?(pself->numAborts\+\+\s*;)/s);
my $end = extract($code, qr/\@method ImportThreadEngineClass, MSG_IMPORT_THREAD_ENGINE_END_ABORT\s*\{.*?(pself->numAborts--\s*;)/s);
my $globals = extract($code, qr/(static int G_numImportThreads;\nstatic int G_nextImportThread;)/);
open my $fetchSource, '<:raw', "$FindBin::Bin/../urlfetch/URLFETCH.goc" or die $!;
my $fetchCode = <$fetchSource>;
my $fetchCount = extract($fetchCode, qr/(word numChildren = DEFAULT_FETCH_ENGINE_CHILDREN;)/);
$fetchCount .= extract($fetchCode, qr/(InitFileReadInteger\(HTMLVIEW_CATEGORY, "numConn".*?numChildren = DEFAULT_FETCH_ENGINE_CHILDREN\s*;)/s);
open my $options, '<:raw', "$FindBin::Bin/../options.goh" or die $!;
my $default = extract(<$options>, qr/(#define DEFAULT_FETCH_ENGINE_CHILDREN\s+\d+)/);
open my $fetchHeader, '<:raw', "$FindBin::Bin/../urlfetch.goh" or die $!;
my $fetchMax = extract(<$fetchHeader>, qr/(#define MAX_FETCH_ENGINE_CHILDREN\s+\d+)/);
my $importMax = extract($code, qr/(#define MAX_IMPORT_THREADS\s+\d+)/);

my $tmp = tempdir(CLEANUP => 1);
open my $test, '>', "$tmp/check.c" or die $!;
print $test <<'C';
#include <assert.h>
#include <stdio.h>
#include <string.h>
#define PROGRESS_DISPLAY 1
#define ALLOW_FETCH_WHILE_IMPORTING
#define IMPORT_PROGRESS_DATA_QUEUE_SIZE 20
#define HTMLVIEW_CATEGORY "HTMLView"
#define IMPORT_WORK_FILENAME "IMPORTWK.%03d"
#define HTML_VMCACHE_SP 0
#define HTML_VMCACHE_DIR ""
#define FILE_NO_ERRORS 0
#define MIME_STATUS_ABORT 1
#define NullHandle 0
#define FALSE 0
#define TRUE 1
typedef int Boolean;
typedef char FileLongName[40];
typedef struct { int MS_mimeFlags; } MimeStatus;
typedef struct { int LPD_loadThread, LPD_importSync; } LoadProgressData;
typedef struct {
    int IPD_vmFile;
    LoadProgressData *IPD_loadProgressDataP;
} ImportProgressData;
typedef struct {
    ImportProgressData importProgressData;
    MimeStatus *mimeStatus;
    int textObj, name, temporary, pageOwner;
    char curHTML[2];
} Request;
typedef struct { int type; Request *requestP; } Event;
typedef struct { int numAborts; } Engine;
typedef unsigned short word;
static int G_importThreadStarted, G_fetchWhileImport;
static int G_importThreadObj[3], G_importThreadMemory[3], G_importWorkFile[3];
static int G_importActive[2], G_importProgressDataQueue[20];
static int G_importProgressDataQueueSem;
static MimeStatus G_importMimeStatus[3];
static Event queue[3][8];
static int queued[3], created[3], killed[3], closed[3];
static int decoded[6], pending[6], canceled[6], deleted[6], unlocked[6], released[2];
static int setting = -1, fetchSetting = -1, progressLocked;
static void InitFileReadInteger(const char *categoryP, const char *keyP,
                               word *valueP)
{
    int value;
    assert(strcmp(categoryP, "HTMLView") == 0);
    assert(strcmp(keyP, "numImportThreads") == 0 || strcmp(keyP, "numConn") == 0);
    value = strcmp(keyP, "numConn") == 0 ? fetchSetting : setting;
    if (value != -1) *valueP = (word)value;
}
static int ThreadAllocSem(int count) { assert(count == 1); return 1; }
static void ThreadFreeSem(int sem) { assert(sem == 1); }
static void ThreadPSem(int sem) { assert(sem == 1 && !progressLocked); progressLocked = 1; }
static void ThreadVSem(int sem)
{
    if (sem == 1) { assert(progressLocked); progressLocked = 0; }
    else { assert(sem >= 10 && sem < 12); released[sem-10]++; }
}
static void FileSetCurrentPath(int sp, const char *pathP) { (void)sp; (void)pathP; }
static void VMClose(int file, int flags) { (void)flags; assert(file >= 10 && file < 13); closed[file-10]++; }
static void FileDelete(const char *pathP) { assert(pathP[0] >= '0' && pathP[0] <= '5'); deleted[pathP[0]-'0']++; }
static void ObjCacheUnlockItem(int owner) { assert(owner >= 1 && owner <= 6); unlocked[owner-1]++; }
static void DecPending(int obj) { assert(pending[obj-1] == 1); pending[obj-1]--; }
static void Cancel(int obj, int name) { assert(name == obj); canceled[obj-1]++; }
static void CreateImporter(int i)
{
    assert(i >= 0 && i < 3);
    created[i]++;
    G_importThreadObj[i] = i+1;
    G_importThreadMemory[i] = i+1;
    G_importWorkFile[i] = i+10;
}
static void KillImporter(int obj) { assert(obj >= 1 && obj <= 3); killed[obj-1]++; }
static void QueueImport(int obj, Request *requestP)
{
    int i = obj-1;
    assert(i >= 0 && i < 3 && created[i] == 1 && queued[i] < 8);
    queue[i][queued[i]].type = 0;
    queue[i][queued[i]++].requestP = requestP;
}
static void QueueAbort(int obj, int front)
{
    int i = obj-1;
    assert(i >= 0 && i < 3 && created[i] == 1 && queued[i] < 8);
    if (front) {
        memmove(queue[i]+1, queue[i], queued[i]*sizeof(Event));
        queue[i][0].type = 1;
    } else queue[i][queued[i]].type = 2;
    queued[i]++;
}
C
print $test "$default\n$fetchMax\n$importMax\n$globals\n";
print $test "static int FetchCount(void)\n{ $fetchCount\n    return numChildren;\n}\n";
print $test "static void Start(void)\n{ int i; $count\n$start}\n";
print $test "static void Stop(void)\n{ int i; FileLongName workFileName;\n$stop}\n";
print $test "static void Abort(void)\n{ int i;\n$abort}\n";
print $test "static void Route(Request *p_request, LoadProgressData *loadProgressDataP)\n{ Request *mem = p_request;\n$route\n}\n";
print $test "static void Handle(Engine *pself, Request request)\n{\n$condition\n decoded[request.textObj-1]++;\n$cleanup}\n";
print $test "static void Begin(Engine *pself) { $begin }\n";
print $test "static void End(Engine *pself) { $end }\n";
print $test <<'C';
static void Check(int option, int children, int fetch, int aborting)
{
    Request request[6];
    LoadProgressData stream[2];
    int i, j, count = option >= 1 && option <= 3 ? option : 1;
    setting = option;
    fetchSetting = children;
    assert(FetchCount() == children);
    G_fetchWhileImport = fetch;
    memset(created, 0, sizeof(created));
    memset(killed, 0, sizeof(killed));
    memset(closed, 0, sizeof(closed));
    memset(decoded, 0, sizeof(decoded));
    memset(canceled, 0, sizeof(canceled));
    memset(deleted, 0, sizeof(deleted));
    memset(unlocked, 0, sizeof(unlocked));
    memset(released, 0, sizeof(released));
    memset(G_importMimeStatus, 0, sizeof(G_importMimeStatus));
    memset(request, 0, sizeof(request));
    G_importActive[0] = G_importActive[1] = 1;
    Start();
    assert(G_numImportThreads == count);
    assert(!G_importActive[0] && !G_importActive[1]);
    /* The count stays fixed even if configuration changes while running. */
    setting = !option;
    assert(G_numImportThreads == count);
    for (i = 0; i < 3; i++) assert(created[i] == (i < count));
    for (i = 0; i < 6; i++) {
        request[i].textObj = request[i].name = request[i].pageOwner = i+1;
        request[i].temporary = 1;
        request[i].curHTML[0] = (char)('0'+i);
        pending[i] = 1;
        if (i && i <= children) {
            stream[i-1].LPD_loadThread = i-1;
            stream[i-1].LPD_importSync = 9+i;
            G_importActive[i-1] = fetch;
        }
        Route(request+i, i && i <= children ? stream+i-1 : (void*)0);
        assert(request[i].importProgressData.IPD_loadProgressDataP ==
               (i && i <= children ? stream+i-1 : (void*)0));
        assert(request[i].importProgressData.IPD_vmFile == 10+i%count);
        assert(request[i].mimeStatus == G_importMimeStatus+i%count);
        assert(!progressLocked);
    }
    for (i = 0; i < count; i++) assert(queued[i] == (5-i)/count+1);
    if (aborting) {
        Abort();
        for (i = 0; i < 3; i++)
            assert(G_importMimeStatus[i].MS_mimeFlags == (i < count));
    }
    /* One completion must not release the other worker's stream. */
    for (i = 0; i < count; i++) {
        Engine engine = {0};
        Event event;
        while (queued[i]) {
            event = queue[i][0];
            memmove(queue[i], queue[i]+1, --queued[i]*sizeof(Event));
            if (event.type == 1) Begin(&engine);
            else if (event.type == 2) End(&engine);
            else {
                Handle(&engine, *event.requestP);
                for (j = 0; j < children; j++) {
                    assert(G_importActive[j] == (pending[j+1] ? fetch : 0));
                    assert(released[j] == (pending[j+1] ? 0 : !fetch));
                }
            }
        }
        assert(engine.numAborts == 0);
    }
    for (i = 0; i < 6; i++) {
        assert(decoded[i] == !aborting && canceled[i] == aborting);
        assert(!pending[i] && deleted[i] == 1 && unlocked[i] == 1);
        if (i && i <= children)
            assert(!G_importActive[i-1] && released[i-1] == !fetch);
    }
    Stop();
    for (i = 0; i < 3; i++) {
        assert(killed[i] == (i < count) && closed[i] == (i < count));
        assert(!G_importThreadObj[i] && !G_importThreadMemory[i] && !G_importWorkFile[i]);
    }
    assert(!G_importThreadStarted);
}
int main(void)
{
    int children, imports, fetch, aborting, i;
    int options[] = {-1, 0, 1, 2, 3, 4, -2, 65535};
    for (i = 0; i < 8; i++) {
        fetchSetting = options[i];
        assert(FetchCount() == (fetchSetting >= 1 && fetchSetting <= 2 ? fetchSetting : 1));
    }
    for (children = 1; children <= 2; children++)
        for (imports = 0; imports < 8; imports++)
            for (fetch = 0; fetch <= 1; fetch++)
                for (aborting = 0; aborting <= 1; aborting++)
                    Check(options[imports], children, fetch, aborting);
    puts("Fetch/import counts, round-robin routing, abort and cleanup checks passed (64 cases).");
    return 0;
}
C
close $test or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror',
       "$tmp/check.c", '-o', "$tmp/check") == 0
    or die "Host compilation failed\n";
system("$tmp/check") == 0 or die "Importer check failed\n";
