#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <i86.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PATH_CHARS 127
#define CMD_TAIL_MAX 127
#define GFS_IMAGE_PATH_MAX 66

static char ownPath[MAX_PATH_CHARS + 1];
static char launcherDir[MAX_PATH_CHARS + 1];
static char batchPath[MAX_PATH_CHARS + 1];
static char comspecPath[MAX_PATH_CHARS + 1];
static char cmdTail[CMD_TAIL_MAX + 2];
static char cwdPath[MAX_PATH_CHARS + 1];
static char bootPath[MAX_PATH_CHARS + 1];
static char gfsText[600];

static const char batchName[] = "gsetup.bat";
/* BASEBOX host file system driver (EC, then non-EC name), see WriteGfsIni */
static const char *const hostfsNames[] = { "HOSTFSEC.GEO", "HOSTFS.GEO", 0 };
static const char slashC[] = "/C ";
static const char msgError[] = "GSETUP launcher failed.\r\n";

static int resolveOwnPath(char *argv[]);
static int buildBatchPath(void);
static int buildCommandTail(int argc, char *argv[]);
static int execComspec(void);
static int appendText(char *dst, unsigned int dstSize, const char *src);
static int appendCmdText(const char *src);
static int appendCmdChar(char ch);
static void normalizeSeparators(char *path);
static void writeError(void);
static int _pascal CheckDrive(unsigned drive);
static char _pascal FindFreeDrive(void);
static int _pascal UpperDosPath(char *pathP);
static int _pascal CreateTempFile(char *pathP, int *fileHP);
static int _pascal WriteGfsIni(const char *iniNameP);

int main(int argc, char *argv[])
{
    int exitCode;
    int i;

    /* Silence one probe. Only this process and its child inherit NUL. */
    if (argc > 1 && strcmp(argv[1], "/QUIET") == 0) {
        if (argc < 3 || argv[2][0] == '\0') {
            return 1;
        }
        cmdTail[0] = '\0';
        if (!appendCmdText(slashC)) {
            return 1;
        }
        for (i = 2; i < argc; i++) {
            if ((i > 2 && !appendCmdChar(' ')) ||
                !appendCmdText(argv[i])) {
                return 1;
            }
        }
        if (freopen("NUL", "w", stdout) == (void*)0 ||
            freopen("NUL", "w", stderr) == (void*)0) {
            return 1;
        }
        exitCode = execComspec();
        return exitCode < 0 ? 1 : exitCode;
    }

    /* Internal batch check: 0 = free, 1 = occupied, 2 = unknown. */
    if (argc > 1 && strcmp(argv[1], "/CHECKDRIVE") == 0) {
        if (argc != 3 || strlen(argv[2]) != 2 || argv[2][1] != ':' ||
            toupper((unsigned char)argv[2][0]) < 'C' ||
            toupper((unsigned char)argv[2][0]) > 'Z') {
            return 2;
        }
        return CheckDrive(toupper((unsigned char)argv[2][0]) - 'A' + 1);
    }

    if (!resolveOwnPath(argv)) {
        writeError();
        return 1;
    }

    if (!buildBatchPath()) {
        writeError();
        return 1;
    }

    if (argc > 1 && strcmp(argv[1], "/WRITEGFS") == 0) {
        if (argc != 3 || (strcmp(argv[2], "NET.INI") != 0 &&
                         strcmp(argv[2], "NETEC.INI") != 0)) {
            fputs("ERROR: /WRITEGFS needs NET.INI or NETEC.INI.\r\n", stderr);
            return 1;
        }
        return WriteGfsIni(argv[2]);
    }

    if (!buildCommandTail(argc, argv)) {
        writeError();
        return 1;
    }

    exitCode = execComspec();
    if (exitCode < 0) {
        writeError();
        return 1;
    }

    return exitCode;
}

/* Query drive assignment without reading media or changing directories. */
static int _pascal CheckDrive(unsigned drive)
{
    union REGS regs;

    memset(&regs, 0, sizeof(regs));
    regs.x.ax = 0x4409;
    regs.x.bx = drive;               /* A: = 1 */
    (void)int86(0x21, &regs, &regs);
    if (!regs.x.cflag) {
        return 1;
    }
    return regs.x.ax == 15 ? 0 : 2;  /* Only invalid drive means free. */
}

/* Reserve A: and B:. Do not scan past the DOS drive table. */
static char _pascal FindFreeDrive(void)
{
    union REGS regs;
    unsigned drive;
    unsigned limit;

    memset(&regs, 0, sizeof(regs));
    regs.h.ah = 0x19;
    (void)int86(0x21, &regs, &regs);
    regs.h.dl = regs.h.al;
    regs.h.ah = 0x0e;                /* Reselect the current drive. */
    (void)int86(0x21, &regs, &regs);
    limit = regs.h.al;
    if (limit > 26) {
        limit = 26;
    }

    for (drive = 3; drive <= limit; drive++) {
        if (CheckDrive(drive) == 0) {
            return (char)('A' + drive - 1);
        }
    }
    return '-';
}

/* Use DOS case conversion, including its national character rules. */
static int _pascal UpperDosPath(char *pathP)
{
    union REGS regs;
    struct SREGS sregs;

    memset(&regs, 0, sizeof(regs));
    segread(&sregs);
    regs.x.ax = 0x6522;
    regs.x.dx = FP_OFF(pathP);
    sregs.ds = FP_SEG(pathP);
    (void)int86x(0x21, &regs, &regs, &sregs);
    return !regs.x.cflag;
}

/* DOS creates a unique file in the local root without replacing a file. */
static int _pascal CreateTempFile(char *pathP, int *fileHP)
{
    union REGS regs;
    struct SREGS sregs;

    strcpy(pathP, ".\\");
    memset(&regs, 0, sizeof(regs));
    segread(&sregs);
    regs.x.ax = 0x5a00;
    regs.x.dx = FP_OFF(pathP);
    sregs.ds = FP_SEG(pathP);
    (void)int86x(0x21, &regs, &regs, &sregs);
    if (regs.x.cflag) {
        return 0;
    }
    *fileHP = regs.x.ax;
    return 1;
}

/***********************************************************************
 *
 * ROUTINE:     WriteGfsIni
 *
 * DESCRIPTION: Write paths for the selected image into the local root.
 *              Keep paths relative when both parts can be moved together.
 *
 * PARAMETERS:  iniNameP - NET.INI or NETEC.INI, selected by the build.
 *
 * RETURN:      Zero on success, one on failure.
 *
 * STRATEGY:    Validate the paths, write and close a local temporary file,
 *              then replace GFS.INI with a backup for rollback.
 *
 * REVISION HISTORY:
 *      Name          Date        Description
 *      ----          ----        -----------
 *      Codex/MeyerK  11/14/26    Initial version
 *
 ***********************************************************************/
static int _pascal WriteGfsIni(const char *iniNameP)
{
    char *pathP;
    unsigned rootLength;
    unsigned attributes;
    unsigned oldAttributes;
    unsigned error;
    unsigned length;
    unsigned written;
    unsigned writeError;
    unsigned closeError;
    int fileH;
    int haveOld;
    int i;
    const char *hostfsP;

    if (_fullpath(bootPath, launcherDir, sizeof(bootPath)) == (void*)0 ||
        _fullpath(cwdPath, ".", sizeof(cwdPath)) == (void*)0 ||
        !appendText(bootPath, sizeof(bootPath), "\\BOOT") ||
        !UpperDosPath(bootPath) || !UpperDosPath(cwdPath)) {
        goto badPath;
    }

    /* MegaFile expands relative names into the same 67-byte buffer. */
    if (strlen(bootPath) + strlen("\\GFS.IMG") > GFS_IMAGE_PATH_MAX) {
        fputs("ERROR: Full GFS image path exceeds 66 characters.\r\n", stderr);
        return 1;
    }

    ownPath[0] = '\0';
    if (!appendText(ownPath, sizeof(ownPath), bootPath) ||
        !appendText(ownPath, sizeof(ownPath), "\\GFS.IMG") ||
        _dos_getfileattr(ownPath, &attributes) != 0 ||
        (attributes & _A_SUBDIR)) {
        goto badPath;
    }
    ownPath[0] = '\0';
    if (!appendText(ownPath, sizeof(ownPath), bootPath) ||
        !appendText(ownPath, sizeof(ownPath), "\\") ||
        !appendText(ownPath, sizeof(ownPath), iniNameP) ||
        _dos_getfileattr(ownPath, &attributes) != 0 ||
        (attributes & _A_SUBDIR)) {
        goto badPath;
    }

    /* These lower INI files are read-only as a hint to the user. */
    if (!(attributes & _A_RDONLY) &&
        _dos_setfileattr(ownPath, attributes | _A_RDONLY) != 0) {
        fprintf(stderr, "WARNING: Cannot set %s read-only.\r\n", ownPath);
    }

    rootLength = strlen(cwdPath);
    pathP = bootPath;
    if (strncmp(bootPath, cwdPath, rootLength) == 0 &&
        (cwdPath[rootLength - 1] == '\\' ||
         bootPath[rootLength] == '\\' || bootPath[rootLength] == '\0')) {
        pathP += rootLength;
        if (*pathP == '\\') {
            pathP++;
        }
        if (*pathP == '\0') {
            pathP = ".";
        }
    }

    /*
     * The BASEBOX host file system driver is loaded after MegaFile when
     * the build has it next to MegaFile. It stays loaded only under
     * pcgeos-basebox with [hostfs] drives configured, else it unloads
     * itself again.
     */
    hostfsP = 0;
    for (i = 0; hostfsNames[i] != 0 && hostfsP == 0; i++) {
        ownPath[0] = '\0';
        if (appendText(ownPath, sizeof(ownPath), bootPath) &&
            appendText(ownPath, sizeof(ownPath), "\\SYSTEM\\FS\\") &&
            appendText(ownPath, sizeof(ownPath), hostfsNames[i]) &&
            _dos_getfileattr(ownPath, &attributes) == 0 &&
            !(attributes & _A_SUBDIR)) {
            hostfsP = hostfsNames[i];
        }
    }

    /* A BOOT path of at most 58 characters keeps this below 600 bytes. */
    strcpy(gfsText,
        "; Do not change this file by hand.\r\n"
        "; An update will overwrite changes.\r\n\r\n");
    length = strlen(gfsText);
    if (hostfsP != 0) {
        sprintf(gfsText + length, "[system]\r\nfs = {\r\nMEGAFILE.GEO\r\n%s\r\n}\r\n\r\n",
            hostfsP);
    } else {
        strcpy(gfsText + length, "[system]\r\nfs = MEGAFILE.GEO\r\n\r\n");
    }
    length = strlen(gfsText);
    sprintf(gfsText + length,
        "[paths]\r\ntop = %s GFS:\\FG\r\nini = %s\\%s\r\n\r\n"
        "[gfs]\r\nfile = %s\\GFS.IMG\r\ndrive = GFS\r\n"
        "bootstrapPath = %s\r\ncacheFile = none\r\n",
        pathP, pathP, iniNameP, pathP, pathP);
    length = strlen(gfsText);

    error = _dos_getfileattr("GFS.INI", &oldAttributes);
    haveOld = error == 0;
    if ((error != 0 && error != 2) ||
        (haveOld && (oldAttributes & _A_SUBDIR))) {
        goto fileError;
    }

    /* The path buffers are no longer needed. Reuse them for local names. */
    if (!CreateTempFile(cwdPath, &fileH)) {
        goto fileError;
    }
    writeError = _dos_write(fileH, gfsText, length, &written);
    closeError = _dos_close(fileH);
    if (writeError != 0 || written != length || closeError != 0) {
        goto removeTemp;
    }

    if (haveOld) {
        if (!CreateTempFile(comspecPath, &fileH)) {
            goto removeTemp;
        }
        closeError = _dos_close(fileH);
        if (remove(comspecPath) != 0 || closeError != 0) {
            goto removeTemp;
        }

        /* Allow activation to replace a previously protected GFS.INI. */
        if ((oldAttributes & _A_RDONLY) &&
            _dos_setfileattr("GFS.INI", oldAttributes & ~_A_RDONLY) != 0) {
            fputs("WARNING: Cannot clear read-only on GFS.INI.\r\n", stderr);
        }
        pathP = "GFS.INI";
        if (rename("GFS.INI", comspecPath) != 0) {
            goto restoreAttributes;
        }
    }

    if (rename(cwdPath, "GFS.INI") != 0) {
        if (haveOld && rename(comspecPath, "GFS.INI") != 0) {
            fprintf(stderr, "ERROR: Previous GFS.INI is saved as %s.\r\n",
                    comspecPath);
            pathP = comspecPath;
        }
        if (haveOld) {
            goto restoreAttributes;
        }
        goto removeTemp;
    }
    if (_dos_getfileattr("GFS.INI", &attributes) != 0 ||
        (!(attributes & _A_RDONLY) &&
         _dos_setfileattr("GFS.INI", attributes | _A_RDONLY) != 0)) {
        fputs("WARNING: Cannot set GFS.INI read-only.\r\n", stderr);
    }
    if (haveOld && remove(comspecPath) != 0) {
        fprintf(stderr, "ERROR: Cannot remove GFS.INI backup %s.\r\n",
                comspecPath);
        pathP = comspecPath;
        goto restoreAttributes;
    }
    return 0;

badPath:
    fputs("ERROR: Cannot use the selected BOOT directory or INI file.\r\n",
          stderr);
    return 1;

restoreAttributes:
    if ((oldAttributes & _A_RDONLY) &&
        _dos_setfileattr(pathP, oldAttributes) != 0) {
        fprintf(stderr, "WARNING: Cannot restore attributes on %s.\r\n", pathP);
    }
removeTemp:
    (void)remove(cwdPath);
fileError:
    fputs("ERROR: Cannot write or replace GFS.INI.\r\n", stderr);
    return 1;
}

static int resolveOwnPath(char *argv[])
{
    char temp[MAX_PATH_CHARS + 1];
    char *cwd;
    int drive;
    unsigned int len;

    if (argv == 0 || argv[0] == 0 || argv[0][0] == '\0') {
        return 0;
    }

    temp[0] = '\0';
    if (!appendText(temp, sizeof(temp), argv[0])) {
        return 0;
    }
    normalizeSeparators(temp);
    if (isalpha((unsigned char)temp[0]) && temp[1] == ':') {
        if (temp[2] == '\\' || temp[2] == '/') {
            if (!appendText(ownPath, sizeof(ownPath), temp)) {
                return 0;
            }
        } else {
            drive = temp[0];
            if (drive >= 'a' && drive <= 'z') {
                drive = drive - ('a' - 'A');
            }
            if (_getdcwd((drive - 'A') + 1, cwdPath, sizeof(cwdPath)) == 0) {
                return 0;
            }
            if (!appendText(ownPath, sizeof(ownPath), cwdPath)) {
                return 0;
            }
            normalizeSeparators(ownPath);
            len = (unsigned int)strlen(ownPath);
            if (len > 0 && ownPath[len - 1] != '\\') {
                if (!appendText(ownPath, sizeof(ownPath), "\\")) {
                    return 0;
                }
            }
            if (!appendText(ownPath, sizeof(ownPath), temp + 2)) {
                return 0;
            }
        }
    } else if (temp[0] == '\\' || temp[0] == '/') {
        drive = _getdrive();
        ownPath[0] = (char)('A' + drive - 1);
        ownPath[1] = ':';
        ownPath[2] = '\0';
        if (!appendText(ownPath, sizeof(ownPath), temp)) {
            return 0;
        }
    } else {
        cwd = getcwd(cwdPath, sizeof(cwdPath));
        if (cwd == 0 || cwd[0] == '\0') {
            return 0;
        }
        if (!appendText(ownPath, sizeof(ownPath), cwd)) {
            return 0;
        }
        normalizeSeparators(ownPath);
        len = (unsigned int)strlen(ownPath);
        if (len > 0 && ownPath[len - 1] != '\\') {
            if (!appendText(ownPath, sizeof(ownPath), "\\")) {
                return 0;
            }
        }
        if (!appendText(ownPath, sizeof(ownPath), temp)) {
            return 0;
        }
    }
    normalizeSeparators(ownPath);
    return 1;
}

static int buildBatchPath(void)
{
    unsigned int len;
    char *sep;

    if (!appendText(launcherDir, sizeof(launcherDir), ownPath)) {
        return 0;
    }

    sep = strrchr(launcherDir, '\\');
    if (sep == 0) {
        return 0;
    }
    *sep = '\0';

    if (!appendText(batchPath, sizeof(batchPath), launcherDir)) {
        return 0;
    }

    len = (unsigned int)strlen(batchPath);
    if (len == 0) {
        return 0;
    }
    if (batchPath[len - 1] != '\\') {
        if (!appendText(batchPath, sizeof(batchPath), "\\")) {
            return 0;
        }
    }
    if (!appendText(batchPath, sizeof(batchPath), batchName)) {
        return 0;
    }
    return 1;
}

static int buildCommandTail(int argc, char *argv[])
{
    char drive;

    cmdTail[0] = '\0';

    if (!appendCmdText(slashC)) {
        return 0;
    }
    if (!appendCmdText(batchPath)) {
        return 0;
    }
    if (!appendCmdChar(' ')) {
        return 0;
    }
    if (!appendCmdText(launcherDir)) {
        return 0;
    }

    /* Internal arguments: distribution directory, drive, then user mode. */
    drive = FindFreeDrive();
    if (!appendCmdChar(' ') || !appendCmdChar(drive)) {
        return 0;
    }
    if (drive != '-' && !appendCmdChar(':')) {
        return 0;
    }

    if (argc > 1 && argv[1] != 0 && argv[1][0] != '\0') {
        if (!appendCmdChar(' ')) {
            return 0;
        }
        if (!appendCmdText(argv[1])) {
            return 0;
        }
    }

    if (argc > 2 && argv[2] != 0 && argv[2][0] != '\0') {
        if (!appendCmdChar(' ')) {
            return 0;
        }
        if (!appendCmdText(argv[2])) {
            return 0;
        }
    }

    return 1;
}

static int execComspec(void)
{
    union REGS regs;
    struct SREGS sregs;
    static struct ExecBlock {
        unsigned short envSeg;
        unsigned short cmdOff;
        unsigned short cmdSeg;
        unsigned short fcb1Off;
        unsigned short fcb1Seg;
        unsigned short fcb2Off;
        unsigned short fcb2Seg;
    } execBlock;
    char *comspec;

    comspec = getenv("COMSPEC");
    if (comspec == 0 || comspec[0] == '\0') {
        if (!appendText(comspecPath, sizeof(comspecPath), "COMMAND.COM")) {
            return -1;
        }
    } else {
        if (!appendText(comspecPath, sizeof(comspecPath), comspec)) {
            return -1;
        }
    }
    normalizeSeparators(comspecPath);

    execBlock.envSeg = 0;
    execBlock.cmdOff = FP_OFF(cmdTail);
    execBlock.cmdSeg = FP_SEG(cmdTail);
    execBlock.fcb1Off = 0x5c;
    execBlock.fcb1Seg = FP_SEG(cmdTail);
    execBlock.fcb2Off = 0x6c;
    execBlock.fcb2Seg = FP_SEG(cmdTail);

    segread(&sregs);
    sregs.ds = FP_SEG(comspecPath);
    sregs.es = FP_SEG(&execBlock);

    regs.x.ax = 0x4b00;
    regs.x.dx = FP_OFF(comspecPath);
    regs.x.bx = FP_OFF(&execBlock);
    (void)int86x(0x21, &regs, &regs, &sregs);
    if (regs.x.cflag != 0) {
        return -1;
    }

    regs.x.ax = 0x4d00;
    (void)int86x(0x21, &regs, &regs, &sregs);
    return (int)regs.h.al;
}

static int appendText(char *dst, unsigned int dstSize, const char *src)
{
    unsigned int dstLen;
    unsigned int i;

    if (dst == 0 || src == 0 || dstSize == 0) {
        return 0;
    }

    dstLen = (unsigned int)strlen(dst);
    for (i = 0; src[i] != '\0'; i++) {
        if (dstLen + 1 >= dstSize) {
            return 0;
        }
        dst[dstLen++] = src[i];
    }
    dst[dstLen] = '\0';
    return 1;
}

static int appendCmdText(const char *src)
{
    unsigned int len;
    unsigned int i;

    len = (unsigned int)cmdTail[0];
    for (i = 0; src[i] != '\0'; i++) {
        if (len >= CMD_TAIL_MAX) {
            return 0;
        }
        cmdTail[len + 1] = src[i];
        len++;
    }
    cmdTail[0] = (char)len;
    cmdTail[len + 1] = '\r';
    return 1;
}

static int appendCmdChar(char ch)
{
    unsigned int len;

    len = (unsigned int)cmdTail[0];
    if (len >= CMD_TAIL_MAX) {
        return 0;
    }
    cmdTail[len + 1] = ch;
    len++;
    cmdTail[0] = (char)len;
    cmdTail[len + 1] = '\r';
    return 1;
}

static void normalizeSeparators(char *path)
{
    while (path != 0 && *path != '\0') {
        if (*path == '/') {
            *path = '\\';
        }
        path++;
    }
}

static void writeError(void)
{
    fputs(msgError, stderr);
}
