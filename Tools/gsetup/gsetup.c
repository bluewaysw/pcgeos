#include <ctype.h>
#include <direct.h>
#include <i86.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PATH_CHARS 127
#define CMD_TAIL_MAX 127

static char ownPath[MAX_PATH_CHARS + 1];
static char launcherDir[MAX_PATH_CHARS + 1];
static char batchPath[MAX_PATH_CHARS + 1];
static char comspecPath[MAX_PATH_CHARS + 1];
static char cmdTail[CMD_TAIL_MAX + 2];
static char cwdPath[MAX_PATH_CHARS + 1];

static const char batchName[] = "gsetup.bat";
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

int main(int argc, char *argv[])
{
    int exitCode;

    if (!resolveOwnPath(argv)) {
        writeError();
        return 1;
    }

    if (!buildBatchPath()) {
        writeError();
        return 1;
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
