/***********************************************************************
 *
 * PROJECT:	  PCGEOS host tools
 * MODULE:	  img86box -- bootable FreeDOS + GEOS disk image for 86Box
 * FILE:	  img86box.c
 *
 * DESCRIPTION:
 *	Creates or updates a raw hard disk image that boots FreeDOS and
 *	starts the composed PC/GEOS target under the Swat serial stub.
 *
 *	The boot code (MBR and FAT boot sector) and the FreeDOS system
 *	files are taken from a bootable FreeDOS hard disk image (for
 *	example the FreeDOS LiteUSB image). The PC/GEOS target tree
 *	(gbuild's localpc directory) is copied to C:\ and kept in sync
 *	on later runs, so state written inside the emulator survives.
 *
 *	The FAT file system is handled by FatFs (Tools/fatfs).
 *
 *	Image layout: CHS geometry with 16 heads and 63 sectors per track,
 *	at most 1024 cylinders (504MB), one primary FAT partition starting
 *	at sector 63. These disks need no BIOS translation, so they boot
 *	on every 86Box machine from 286 to Pentium.
 *
 ***********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <errno.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "ff.h"
#include "fatimg.h"
#include "hostdir.h"

#define IMG86BOX_VERSION    "1.0"

#define SEC_SIZE	    FATIMG_SECTOR_SIZE
#define GEO_HEADS	    16
#define GEO_SECTORS	    63
#define GEO_MAX_CYLS	    1024
#define PART_START	    GEO_SECTORS	/* first partition at sector 63 */
#define DEFAULT_SIZE_MB	    256
#define MIN_SIZE_MB	    40

#define DRV_IMAGE	    0		/* FatFs drive of the target image */
#define DRV_TEMPLATE	    1		/* FatFs drive of the FreeDOS image */

#define MAX_PATH_LEN	    512
#define MAX_LIST	    32
#define COPY_BUF_SIZE	    32768

/* Boot sector offsets (shared BPB part) */
#define BPB_BYTSPERSEC	    11
#define BPB_SECPERCLUS	    13
#define BPB_RSVDSECCNT	    14
#define BPB_NUMFATS	    16
#define BPB_ROOTENTCNT	    17
#define BPB_TOTSEC16	    19
#define BPB_FATSZ16	    22
#define BPB_SECPERTRK	    24
#define BPB_NUMHEADS	    26
#define BPB_HIDDSEC	    28
#define BPB_TOTSEC32	    32
#define BS_DRVNUM16	    36
#define BPB_FATSZ32	    36
#define BPB_BKBOOTSEC	    50
#define BS_DRVNUM32	    64
#define BOOTCODE16	    0x3e	/* boot code after FAT12/16 BPB */
#define BOOTCODE32	    0x5a	/* boot code after FAT32 BPB */
#define BOOTCODE_END	    0x1fe	/* signature follows */
#define MBR_CODE_SIZE	    440		/* MBR code before disk signature */
#define MBR_PTABLE	    446

typedef enum {
    FST_NONE, FST_FAT12, FST_FAT16, FST_FAT32
} FsType;

/***********************************************************************
 *		Options
 ***********************************************************************/
static const char *optImage = NULL;	/* -o */
static const char *optTree = NULL;	/* -s */
static const char *optTemplate = NULL;	/* -f */
static const char *optSysDir = NULL;	/* -S */
static const char *optStub = NULL;	/* -t */
static const char *optPtty = "1,38400";	/* -p */
static const char *optRun = "CALL SS.BAT";	/* -r */
static const char *optWorkDir = "ENSEMBLE";	/* -w */
static const char *optKernel = "KERNEL.SYS";	/* -k */
static const char *optXms = NULL;	/* -x */
static const char *optMouse = NULL;	/* -M */
static const char *optAutoexec = NULL;	/* -a */
static const char *optLabel = "GEOS";
static int	optSizeMB = DEFAULT_SIZE_MB;	/* -m */
static int	optFresh = 0;		/* --fresh */
static int	optPrune = 1;		/* --no-prune */
static int	optCdrom = 0;		/* --cdrom */
static int	optVerbose = 0;		/* -v */
static int	optForce = 0;		/* --force */
static int	optQuiet = 0;		/* no informational output */
static const char *pruneDirs[MAX_LIST];
static const char *iniNames[MAX_LIST];	/* --ini */
static int	numIniNames = 0;
static const char *iniSets[MAX_LIST];	/* -I */
static int	numIniSets = 0;
static const char *getSpecs[MAX_LIST];	/* --get NAME=HOSTFILE */
static int	numGetSpecs = 0;
static int	numPruneDirs = 0;
static int	pruneDirsGiven = 0;

/* Statistics */
static unsigned long statCopied = 0, statSkipped = 0, statDeleted = 0,
		     statIgnored = 0;

static FATFS	fsImage, fsTemplate;
static int	haveTemplateFs = 0;
static BYTE	copyBuf[COPY_BUF_SIZE];

/***********************************************************************
 *		Utilities
 ***********************************************************************/
static void
Fatal(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    fprintf(stderr, "img86box: error: ");
    vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
    va_end(args);
    exit(1);
}

static void
Warn(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    fprintf(stderr, "img86box: warning: ");
    vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
    va_end(args);
}

static void
Info(const char *fmt, ...)
{
    va_list args;

    if (optQuiet) {
	return;
    }
    va_start(args, fmt);
    vprintf(fmt, args);
    printf("\n");
    va_end(args);
}

static const char *
FResultString(FRESULT res)
{
    static const char *names[] = {
	"ok", "disk error", "internal error", "not ready", "no file",
	"no path", "invalid name", "denied", "exists", "invalid object",
	"write protected", "invalid drive", "not enabled",
	"no file system", "mkfs aborted", "timeout", "locked",
	"not enough core", "too many open files", "invalid parameter"
    };

    if ((unsigned)res < sizeof(names) / sizeof(names[0])) {
	return names[res];
    }
    return "unknown error";
}

static void
CheckF(FRESULT res, const char *what, const char *path)
{
    if (res != FR_OK) {
	Fatal("%s %s: %s", what, path ? path : "", FResultString(res));
    }
}

static WORD
Ld16(const BYTE *p)
{
    return (WORD)(p[0] | (p[1] << 8));
}

static DWORD
Ld32(const BYTE *p)
{
    return (DWORD)p[0] | ((DWORD)p[1] << 8) | ((DWORD)p[2] << 16) |
	((DWORD)p[3] << 24);
}

static void
St16(BYTE *p, WORD v)
{
    p[0] = (BYTE)v;
    p[1] = (BYTE)(v >> 8);
}

static void
St32(BYTE *p, DWORD v)
{
    p[0] = (BYTE)v;
    p[1] = (BYTE)(v >> 8);
    p[2] = (BYTE)(v >> 16);
    p[3] = (BYTE)(v >> 24);
}

static int
StrCaseEq(const char *a, const char *b)
{
    while (*a && *b) {
	if (toupper((unsigned char)*a) != toupper((unsigned char)*b)) {
	    return 0;
	}
	a++, b++;
    }
    return *a == *b;
}

static void
StrUpper(char *s)
{
    for (; *s; s++) {
	*s = (char)toupper((unsigned char)*s);
    }
}

static long
HostFileSize(FILE *fp)
{
    long size;

    if (fseek(fp, 0, SEEK_END) != 0) {
	return -1;
    }
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    return size;
}

static int
HostIsDir(const char *path)
{
    struct stat st;

    return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

/*
 * Convert a host time to FAT date (high word) and time (low word).
 */
static void
HostTimeToFat(time_t t, WORD *fdate, WORD *ftime)
{
    struct tm *tm = localtime(&t);

    if (tm == NULL || tm->tm_year < 80) {
	*fdate = (WORD)((1 << 5) | 1);
	*ftime = 0;
	return;
    }
    *fdate = (WORD)(((tm->tm_year - 80) << 9) | ((tm->tm_mon + 1) << 5) |
		    tm->tm_mday);
    *ftime = (WORD)((tm->tm_hour << 11) | (tm->tm_min << 5) |
		    (tm->tm_sec >> 1));
}

/*
 * Convert a host file name to a DOS 8.3 name (upper case). Returns 0 if
 * the name cannot be represented without changing it.
 */
static int
DosName(const char *name, char *out)
{
    static const char *bad = "\"*+,/:;<=>?[\\]| ";
    const char	*dot = strrchr(name, '.');
    size_t	baseLen, extLen, i;

    if (name[0] == '.' || name[0] == '\0') {
	return 0;
    }
    baseLen = dot ? (size_t)(dot - name) : strlen(name);
    extLen = dot ? strlen(dot + 1) : 0;
    if (baseLen == 0 || baseLen > 8 || extLen > 3 ||
	(dot && extLen == 0))
    {
	return 0;
    }
    for (i = 0; name[i]; i++) {
	unsigned char c = (unsigned char)name[i];

	if (c < 0x20 || c >= 0x80 || strchr(bad, c) != NULL ||
	    (c == '.' && name + i != dot))
	{
	    return 0;
	}
    }
    strcpy(out, name);
    StrUpper(out);
    return 1;
}

/***********************************************************************
 *		Image in use check
 ***********************************************************************
 * On Linux the target script writes the 86Box process id to
 * <image>.lock. On Windows a file that 86Box keeps open cannot be
 * renamed, which is used as the test.
 ***********************************************************************/
static void
CheckImageNotInUse(const char *image)
{
#if defined(__NT__) || defined(_WIN32)
    char tmp[MAX_PATH_LEN];

    sprintf(tmp, "%s.chk", image);
    if (rename(image, tmp) != 0) {
	if (errno == ENOENT) {
	    return;
	}
	Fatal("%s is in use (is 86Box still running?)", image);
    }
    if (rename(tmp, image) != 0) {
	Fatal("cannot rename %s back to %s", tmp, image);
    }
#else
    char lock[MAX_PATH_LEN];
    char proc[64];
    FILE *fp;
    long pid = 0;

    sprintf(lock, "%s.lock", image);
    fp = fopen(lock, "r");
    if (fp == NULL) {
	return;
    }
    if (fscanf(fp, "%ld", &pid) != 1) {
	pid = 0;
    }
    fclose(fp);
    if (pid > 0) {
	sprintf(proc, "/proc/%ld", pid);
	if (HostIsDir(proc)) {
	    Fatal("%s is in use by process %ld (is 86Box still running?)",
		  image, pid);
	}
    }
    /* stale lock */
    remove(lock);
#endif
}

/***********************************************************************
 *		FreeDOS template
 ***********************************************************************/
typedef struct {
    FILE    *fp;
    BYTE    mbr[SEC_SIZE];
    BYTE    vbr[SEC_SIZE];
    DWORD   partStart;
    FsType  fsType;
} Template;

static Template tmpl;

static FsType
VbrFsType(const BYTE *vbr)
{
    DWORD totSec, fatSz, rootSecs, dataSecs, clusters;
    WORD  bps = Ld16(vbr + BPB_BYTSPERSEC);

    if (vbr[510] != 0x55 || vbr[511] != 0xaa || bps != SEC_SIZE ||
	vbr[BPB_SECPERCLUS] == 0 || vbr[BPB_NUMFATS] == 0)
    {
	return FST_NONE;
    }
    fatSz = Ld16(vbr + BPB_FATSZ16);
    if (fatSz == 0) {
	return FST_FAT32;
    }
    totSec = Ld16(vbr + BPB_TOTSEC16);
    if (totSec == 0) {
	totSec = Ld32(vbr + BPB_TOTSEC32);
    }
    rootSecs = ((DWORD)Ld16(vbr + BPB_ROOTENTCNT) * 32 + SEC_SIZE - 1) /
	SEC_SIZE;
    dataSecs = totSec - Ld16(vbr + BPB_RSVDSECCNT) -
	vbr[BPB_NUMFATS] * fatSz - rootSecs;
    clusters = dataSecs / vbr[BPB_SECPERCLUS];
    return clusters < 4085 ? FST_FAT12 : FST_FAT16;
}

static void
OpenTemplate(const char *path)
{
    int	    i;
    long    size;
    FRESULT res;

    tmpl.fp = fopen(path, "rb");
    if (tmpl.fp == NULL) {
	Fatal("cannot open FreeDOS image %s", path);
    }
    size = HostFileSize(tmpl.fp);
    if (size < 64L * SEC_SIZE) {
	Fatal("FreeDOS image %s is too small", path);
    }
    if (FatImg_ReadSectors(tmpl.fp, 0, tmpl.mbr, 1) != 0 ||
	tmpl.mbr[510] != 0x55 || tmpl.mbr[511] != 0xaa)
    {
	Fatal("%s is not a bootable disk image", path);
    }
    if (VbrFsType(tmpl.mbr) != FST_NONE) {
	Fatal("%s is not partitioned (a floppy or \"superfloppy\" image);"
	      " a bootable FreeDOS hard disk image is needed", path);
    }
    /*
     * Find the first FAT partition. Prefer an active one.
     */
    tmpl.partStart = 0;
    for (i = 0; i < 4 && tmpl.partStart == 0; i++) {
	const BYTE *pe = tmpl.mbr + MBR_PTABLE + i * 16;

	switch (pe[4]) {
	case 0x01: case 0x04: case 0x06: case 0x0b: case 0x0c: case 0x0e:
	    if (pe[0] == 0x80 || tmpl.partStart == 0) {
		tmpl.partStart = Ld32(pe + 8);
	    }
	    break;
	}
    }
    if (tmpl.partStart == 0) {
	Fatal("no FAT partition found in %s", path);
    }
    if (FatImg_ReadSectors(tmpl.fp, tmpl.partStart, tmpl.vbr, 1) != 0) {
	Fatal("cannot read boot sector of %s", path);
    }
    tmpl.fsType = VbrFsType(tmpl.vbr);
    switch (tmpl.fsType) {
    case FST_FAT16:
    case FST_FAT32:
	break;
    case FST_FAT12:
	Fatal("%s has a FAT12 partition; a FAT16 or FAT32 FreeDOS hard"
	      " disk image is needed", path);
	break;
    default:
	Fatal("partition in %s has no valid FAT boot sector", path);
    }

    if (FatImg_Attach(DRV_TEMPLATE, tmpl.fp, 0,
		      (DWORD)(size / SEC_SIZE), 1) != 0)
    {
	Fatal("cannot attach %s", path);
    }
    res = f_mount(&fsTemplate, "1:", 1);
    if (res != FR_OK) {
	Fatal("cannot read file system of %s: %s", path,
	      FResultString(res));
    }
    haveTemplateFs = 1;
    Info("FreeDOS template: %s (%s, partition at sector %lu)", path,
	 tmpl.fsType == FST_FAT32 ? "FAT32" : "FAT16",
	 (unsigned long)tmpl.partStart);
}

/*
 * Search the template file system recursively for a file name. Returns
 * 1 and the full FatFs path if found.
 */
static int
FindInTemplateDir(const char *dir, const char *name, char *found, int depth)
{
    DIR	    d;
    FILINFO fi;
    char    sub[MAX_PATH_LEN];
    int	    ok = 0;

    if (depth > 8 || f_opendir(&d, dir) != FR_OK) {
	return 0;
    }
    /* files first, so a file in the root wins over deeper copies */
    while (f_readdir(&d, &fi) == FR_OK && fi.fname[0]) {
	if (!(fi.fattrib & AM_DIR) && StrCaseEq(fi.fname, name)) {
	    sprintf(found, "%s/%s", dir, fi.fname);
	    ok = 1;
	    break;
	}
    }
    if (!ok) {
	f_readdir(&d, NULL);
	while (f_readdir(&d, &fi) == FR_OK && fi.fname[0]) {
	    if ((fi.fattrib & AM_DIR) && fi.fname[0] != '.') {
		sprintf(sub, "%s/%s", dir, fi.fname);
		if (FindInTemplateDir(sub, name, found, depth + 1)) {
		    ok = 1;
		    break;
		}
	    }
	}
    }
    f_closedir(&d);
    return ok;
}

/*
 * --get NAME=HOSTFILE: copy a file found anywhere in the FreeDOS image
 * (e.g. a package archive like CTMOUSE.ZIP) to the host. Returns 1 if
 * found.
 */
static int
GetTemplateFile(const char *spec)
{
    char    name[64], path[MAX_PATH_LEN];
    const char *eq = strchr(spec, '=');
    FIL	    in;
    FILE    *out;
    UINT    br;

    if (eq == NULL || eq == spec || (size_t)(eq - spec) >= sizeof(name) ||
	eq[1] == '\0')
    {
	Fatal("bad --get argument \"%s\" (NAME=HOSTFILE expected)", spec);
    }
    memcpy(name, spec, eq - spec);
    name[eq - spec] = '\0';
    if (!FindInTemplateDir("1:", name, path, 0)) {
	return 0;
    }
    CheckF(f_open(&in, path, FA_READ), "cannot open", path);
    out = fopen(eq + 1, "wb");
    if (out == NULL) {
	Fatal("cannot create %s", eq + 1);
    }
    for (;;) {
	CheckF(f_read(&in, copyBuf, sizeof(copyBuf), &br), "cannot read",
	       path);
	if (br == 0) {
	    break;
	}
	if (fwrite(copyBuf, 1, br, out) != br) {
	    Fatal("cannot write %s", eq + 1);
	}
    }
    f_close(&in);
    if (fclose(out) != 0) {
	Fatal("cannot write %s", eq + 1);
    }
    Info("%s -> %s", path + 3, eq + 1);
    return 1;
}

/***********************************************************************
 *		File copying into the image
 ***********************************************************************/
static void
CopyHostFile(const char *src, const char *dst, time_t mtime)
{
    FILE    *fp;
    FIL	    f;
    size_t  n;
    UINT    bw;
    FILINFO fi;
    FRESULT res;

    fp = fopen(src, "rb");
    if (fp == NULL) {
	Fatal("cannot open %s", src);
    }
    /* clear read-only so it can be replaced */
    f_chmod(dst, 0, AM_RDO | AM_SYS | AM_HID);
    res = f_open(&f, dst, FA_CREATE_ALWAYS | FA_WRITE);
    CheckF(res, "cannot create", dst);
    while ((n = fread(copyBuf, 1, sizeof(copyBuf), fp)) > 0) {
	res = f_write(&f, copyBuf, (UINT)n, &bw);
	if (res != FR_OK || bw != n) {
	    Fatal("writing %s failed (image full?): %s", dst,
		  res != FR_OK ? FResultString(res) : "disk full");
	}
    }
    fclose(fp);
    CheckF(f_close(&f), "cannot close", dst);
    memset(&fi, 0, sizeof(fi));
    HostTimeToFat(mtime, &fi.fdate, &fi.ftime);
    f_utime(dst, &fi);
}

static void
CopyTemplateFile(const char *src, const char *dst)
{
    FIL	    in, out;
    UINT    br, bw;
    FILINFO fi;

    CheckF(f_stat(src, &fi), "cannot stat", src);
    CheckF(f_open(&in, src, FA_READ), "cannot open", src);
    f_chmod(dst, 0, AM_RDO | AM_SYS | AM_HID);
    CheckF(f_open(&out, dst, FA_CREATE_ALWAYS | FA_WRITE),
	   "cannot create", dst);
    for (;;) {
	CheckF(f_read(&in, copyBuf, sizeof(copyBuf), &br), "cannot read",
	       src);
	if (br == 0) {
	    break;
	}
	if (f_write(&out, copyBuf, br, &bw) != FR_OK || bw != br) {
	    Fatal("writing %s failed (image full?)", dst);
	}
    }
    f_close(&in);
    CheckF(f_close(&out), "cannot close", dst);
    f_utime(dst, &fi);
}

static void
WriteImageText(const char *dst, const char *text)
{
    FIL	    f;
    UINT    bw;
    size_t  len = strlen(text);

    f_chmod(dst, 0, AM_RDO | AM_SYS | AM_HID);
    CheckF(f_open(&f, dst, FA_CREATE_ALWAYS | FA_WRITE), "cannot create",
	   dst);
    if (f_write(&f, text, (UINT)len, &bw) != FR_OK || bw != len) {
	Fatal("writing %s failed", dst);
    }
    CheckF(f_close(&f), "cannot close", dst);
}

/*
 * Locate a FreeDOS file: first in the -S directory on the host, then
 * anywhere in the template image. Copies it to dst. Returns 1 if found.
 */
static int
InstallFreeDosFile(const char *name, const char *dst)
{
    char path[MAX_PATH_LEN];

    if (optSysDir != NULL) {
	HostDir	    *dir = HostDir_Open(optSysDir);
	const char  *entry;

	if (dir != NULL) {
	    while ((entry = HostDir_Read(dir)) != NULL) {
		if (StrCaseEq(entry, name)) {
		    struct stat st;

		    sprintf(path, "%s/%s", optSysDir, entry);
		    if (stat(path, &st) == 0 && !S_ISDIR(st.st_mode)) {
			HostDir_Close(dir);
			CopyHostFile(path, dst, st.st_mtime);
			if (optVerbose) {
			    Info("  %s <- %s", dst, path);
			}
			return 1;
		    }
		}
	    }
	    HostDir_Close(dir);
	}
    }
    if (haveTemplateFs && FindInTemplateDir("1:", name, path, 0)) {
	CopyTemplateFile(path, dst);
	if (optVerbose) {
	    Info("  %s <- template %s", dst, path + 2);
	}
	return 1;
    }
    return 0;
}

/***********************************************************************
 *		Image creation
 ***********************************************************************/
static void
LbaToChs(DWORD lba, BYTE *chs)
{
    DWORD cyl = lba / (GEO_HEADS * GEO_SECTORS);
    DWORD head = (lba / GEO_SECTORS) % GEO_HEADS;
    DWORD sec = lba % GEO_SECTORS + 1;

    if (cyl > 1023) {
	cyl = 1023, head = GEO_HEADS - 1, sec = GEO_SECTORS;
    }
    chs[0] = (BYTE)head;
    chs[1] = (BYTE)(sec | ((cyl >> 2) & 0xc0));
    chs[2] = (BYTE)cyl;
}

static void
GraftBootCode(BYTE *vbr, DWORD partSectors)
{
    int codeStart = tmpl.fsType == FST_FAT32 ? BOOTCODE32 : BOOTCODE16;

    /* jump instruction and OEM name from the FreeDOS boot sector */
    memcpy(vbr, tmpl.vbr, 11);
    /* boot code */
    memcpy(vbr + codeStart, tmpl.vbr + codeStart, BOOTCODE_END - codeStart);
    /* geometry and location as seen by the BIOS */
    St16(vbr + BPB_SECPERTRK, GEO_SECTORS);
    St16(vbr + BPB_NUMHEADS, GEO_HEADS);
    St32(vbr + BPB_HIDDSEC, PART_START);
    vbr[tmpl.fsType == FST_FAT32 ? BS_DRVNUM32 : BS_DRVNUM16] = 0x80;
    vbr[510] = 0x55;
    vbr[511] = 0xaa;
    (void)partSectors;
}

static void
CreateImage(FILE *fp, DWORD totalSectors)
{
    BYTE	mbr[SEC_SIZE], vbr[SEC_SIZE];
    BYTE	*pe;
    DWORD	partSectors = totalSectors - PART_START;
    MKFS_PARM	mkfs;
    static BYTE	work[16384];
    FRESULT	res;
    BYTE	sysId;
    unsigned	i;

    Info("Creating %s: %lu cylinders, %d heads, %d sectors (%lu MB)",
	 optImage, (unsigned long)(totalSectors / (GEO_HEADS * GEO_SECTORS)),
	 GEO_HEADS, GEO_SECTORS,
	 (unsigned long)(totalSectors / 2048));

    /* allocate the whole file (the tail is written last) */
    memset(vbr, 0, sizeof(vbr));
    for (i = 0; i < PART_START; i++) {
	if (FatImg_WriteSectors(fp, i, vbr, 1) != 0) {
	    Fatal("cannot write %s", optImage);
	}
    }
    if (FatImg_WriteSectors(fp, totalSectors - 1, vbr, 1) != 0) {
	Fatal("cannot write %s (disk full?)", optImage);
    }

    /* file system */
    if (FatImg_Attach(DRV_IMAGE, fp, PART_START, partSectors, 0) != 0) {
	Fatal("cannot attach %s", optImage);
    }
    memset(&mkfs, 0, sizeof(mkfs));
    mkfs.fmt = (BYTE)((tmpl.fsType == FST_FAT32 ? FM_FAT32 : FM_FAT) |
		      FM_SFD);
    mkfs.n_fat = 2;
    mkfs.n_root = tmpl.fsType == FST_FAT32 ? 0 : 512;
    res = f_mkfs("0:", &mkfs, work, sizeof(work));
    if (res != FR_OK) {
	Fatal("cannot create %s file system on %s: %s (image too small"
	      " for this FAT type?)",
	      tmpl.fsType == FST_FAT32 ? "FAT32" : "FAT16", optImage,
	      FResultString(res));
    }

    /* boot sector: FreeDOS boot code with our geometry */
    if (FatImg_ReadSectors(fp, PART_START, vbr, 1) != 0) {
	Fatal("cannot read back boot sector");
    }
    if (VbrFsType(vbr) != tmpl.fsType) {
	Fatal("file system type does not match the FreeDOS boot code; use"
	      " a different image size (-m)");
    }
    GraftBootCode(vbr, partSectors);
    if (FatImg_WriteSectors(fp, PART_START, vbr, 1) != 0) {
	Fatal("cannot write boot sector");
    }
    if (tmpl.fsType == FST_FAT32) {
	WORD bk = Ld16(vbr + BPB_BKBOOTSEC);

	if (bk != 0 &&
	    FatImg_WriteSectors(fp, PART_START + bk, vbr, 1) != 0)
	{
	    Fatal("cannot write backup boot sector");
	}
	sysId = 0x0c;
    } else {
	sysId = partSectors < 65536 ? 0x04 : 0x06;
    }

    /* MBR: FreeDOS MBR code, one active partition */
    memset(mbr, 0, sizeof(mbr));
    memcpy(mbr, tmpl.mbr, MBR_CODE_SIZE);
    St32(mbr + MBR_CODE_SIZE, (DWORD)time(NULL));	/* disk signature */
    pe = mbr + MBR_PTABLE;
    pe[0] = 0x80;
    LbaToChs(PART_START, pe + 1);
    pe[4] = sysId;
    LbaToChs(totalSectors - 1, pe + 5);
    St32(pe + 8, PART_START);
    St32(pe + 12, partSectors);
    mbr[510] = 0x55;
    mbr[511] = 0xaa;
    if (FatImg_WriteSectors(fp, 0, mbr, 1) != 0) {
	Fatal("cannot write MBR");
    }
    fflush(fp);
}

/*
 * Check that an existing image has our layout. Returns the partition
 * size in sectors or 0.
 */
static DWORD
CheckExistingImage(FILE *fp, long fileSize)
{
    BYTE    mbr[SEC_SIZE];
    BYTE    *pe = mbr + MBR_PTABLE;
    DWORD   start, count;

    if (fileSize < (long)(PART_START + 1) * SEC_SIZE ||
	FatImg_ReadSectors(fp, 0, mbr, 1) != 0 ||
	mbr[510] != 0x55 || mbr[511] != 0xaa)
    {
	return 0;
    }
    start = Ld32(pe + 8);
    count = Ld32(pe + 12);
    if (start != PART_START || count == 0 ||
	(long)(start + count) * SEC_SIZE > fileSize)
    {
	return 0;
    }
    return count;
}

/***********************************************************************
 *		Tree synchronisation
 ***********************************************************************/
typedef struct {
    char    dosName[13];
    char    hostName[MAX_PATH_LEN];
    int	    isDir;
    time_t  mtime;
    long    size;
} HostEntry;

static int
CompareHostEntries(const void *a, const void *b)
{
    return strcmp(((const HostEntry *)a)->dosName,
		  ((const HostEntry *)b)->dosName);
}

/*
 * Read a host directory, returning a sorted array of entries that have
 * valid 8.3 names. Duplicate names (case variants) are reported.
 */
static HostEntry *
ReadHostDir(const char *hostDir, int *countPtr)
{
    HostDir	    *dir;
    const char	    *name;
    HostEntry	    *entries = NULL;
    int		    count = 0, alloc = 0, i;

    dir = HostDir_Open(hostDir);
    if (dir == NULL) {
	Fatal("cannot read directory %s", hostDir);
    }
    while ((name = HostDir_Read(dir)) != NULL) {
	HostEntry   e;
	struct stat st;

	sprintf(e.hostName, "%s/%s", hostDir, name);
	if (stat(e.hostName, &st) != 0) {
	    continue;
	}
	if (!DosName(name, e.dosName)) {
	    Warn("skipping %s: not a DOS 8.3 name", e.hostName);
	    statIgnored++;
	    continue;
	}
	e.isDir = S_ISDIR(st.st_mode);
	e.mtime = st.st_mtime;
	e.size = (long)st.st_size;
	if (count == alloc) {
	    alloc = alloc ? alloc * 2 : 64;
	    entries = (HostEntry *)realloc(entries, alloc * sizeof(HostEntry));
	    if (entries == NULL) {
		Fatal("out of memory");
	    }
	}
	entries[count++] = e;
    }
    HostDir_Close(dir);
    if (count > 1) {
	qsort(entries, count, sizeof(HostEntry), CompareHostEntries);
	for (i = 1; i < count; i++) {
	    if (!strcmp(entries[i].dosName, entries[i - 1].dosName)) {
		Warn("%s and %s map to the same DOS name; using the first",
		     entries[i - 1].hostName, entries[i].hostName);
		entries[i].dosName[0] = '\0';
	    }
	}
    }
    *countPtr = count;
    return entries;
}

static int
FindHostEntry(HostEntry *entries, int count, const char *dosName)
{
    int i;

    for (i = 0; i < count; i++) {
	if (!strcmp(entries[i].dosName, dosName)) {
	    return i;
	}
    }
    return -1;
}

/*
 * Collect the names in an image directory (FatFs cannot delete entries
 * of a directory that is being enumerated safely).
 */
typedef char DosNameBuf[13];

static DosNameBuf *
ReadImageDir(const char *path, int *countPtr)
{
    DIR		d;
    FILINFO	fi;
    DosNameBuf	*names = NULL;
    int		count = 0, alloc = 0;

    *countPtr = 0;
    if (f_opendir(&d, path) != FR_OK) {
	return NULL;
    }
    while (f_readdir(&d, &fi) == FR_OK && fi.fname[0]) {
	if (count == alloc) {
	    alloc = alloc ? alloc * 2 : 64;
	    names = (DosNameBuf *)realloc(names, alloc * sizeof(DosNameBuf));
	    if (names == NULL) {
		Fatal("out of memory");
	    }
	}
	strcpy(names[count++], fi.fname);
    }
    f_closedir(&d);
    *countPtr = count;
    return names;
}

static void
DeleteImageTree(const char *path)
{
    FILINFO	fi;
    char	sub[MAX_PATH_LEN];
    DosNameBuf	*names;
    int		count, i;

    if (f_stat(path, &fi) != FR_OK) {
	return;
    }
    if (fi.fattrib & AM_DIR) {
	names = ReadImageDir(path, &count);
	for (i = 0; i < count; i++) {
	    sprintf(sub, "%s/%s", path, names[i]);
	    DeleteImageTree(sub);
	}
	free(names);
    }
    f_chmod(path, 0, AM_RDO | AM_SYS | AM_HID);
    if (f_unlink(path) == FR_OK) {
	statDeleted++;
	if (optVerbose) {
	    Info("  delete %s", path + 3);
	}
    } else {
	Warn("cannot delete %s from the image", path + 3);
    }
}

/*
 * Is the image directory (path relative to the root, e.g.
 * "ENSEMBLE/SYSTEM") inside one of the prune directories?
 */
static int
InPruneScope(const char *relDir)
{
    int	    i;
    size_t  len;

    if (!optPrune) {
	return 0;
    }
    for (i = 0; i < numPruneDirs; i++) {
	len = strlen(pruneDirs[i]);
	if (len == 0) {
	    return 1;	/* whole tree */
	}
	if (strlen(relDir) >= len &&
	    !strncmp(relDir, pruneDirs[i], len) &&
	    (relDir[len] == '\0' || relDir[len] == '/'))
	{
	    return 1;
	}
    }
    return 0;
}

static void
SyncDir(const char *hostDir, const char *imgDir, const char *relDir)
{
    HostEntry	*entries;
    int		count, i;
    char	imgPath[MAX_PATH_LEN], rel[MAX_PATH_LEN];
    FILINFO	fi;
    FRESULT	res;

    entries = ReadHostDir(hostDir, &count);

    for (i = 0; i < count; i++) {
	HostEntry   *e = &entries[i];
	const char  *src = e->hostName;
	time_t	    mtime = e->mtime;
	long	    size = e->size;

	if (e->dosName[0] == '\0') {
	    continue;
	}
	sprintf(imgPath, "%s/%s", imgDir, e->dosName);
	sprintf(rel, "%s%s%s", relDir, relDir[0] ? "/" : "", e->dosName);

	if (e->isDir) {
	    res = f_stat(imgPath, &fi);
	    if (res == FR_OK && !(fi.fattrib & AM_DIR)) {
		DeleteImageTree(imgPath);
		res = FR_NO_FILE;
	    }
	    if (res != FR_OK) {
		CheckF(f_mkdir(imgPath), "cannot create directory", imgPath);
	    }
	    SyncDir(src, imgPath, rel);
	    continue;
	}

	/*
	 * The Swat stub that comes with the target talks IPX; replace it
	 * with the serial stub.
	 */
	if (optStub != NULL && !strcmp(e->dosName, "SWAT.EXE")) {
	    struct stat st;

	    if (stat(optStub, &st) != 0) {
		Fatal("cannot find stub %s", optStub);
	    }
	    src = optStub;
	    mtime = st.st_mtime;
	    size = (long)st.st_size;
	}

	res = f_stat(imgPath, &fi);
	if (res == FR_OK && (fi.fattrib & AM_DIR)) {
	    DeleteImageTree(imgPath);
	    res = FR_NO_FILE;
	}
	if (res == FR_OK) {
	    WORD fdate, ftime;

	    HostTimeToFat(mtime, &fdate, &ftime);
	    if ((long)fi.fsize == size && fi.fdate == fdate &&
		fi.ftime == ftime)
	    {
		statSkipped++;
		continue;
	    }
	}
	if (optVerbose) {
	    Info("  %s %s", res == FR_OK ? "update" : "add   ", rel);
	}
	CopyHostFile(src, imgPath, mtime);
	statCopied++;
    }

    /*
     * Remove what is no longer part of the target, within the prune
     * scope only.
     */
    if (InPruneScope(relDir)) {
	DosNameBuf  *names;
	int	    numNames, j;

	names = ReadImageDir(imgDir, &numNames);
	for (j = 0; j < numNames; j++) {
	    if (FindHostEntry(entries, count, names[j]) < 0) {
		sprintf(imgPath, "%s/%s", imgDir, names[j]);
		DeleteImageTree(imgPath);
	    }
	}
	free(names);
    }
    free(entries);
}

/***********************************************************************
 *		GEOS .ini adjustments
 ***********************************************************************
 * The target's ini files are written for DOSBox/basebox (e.g. the
 * basebox absolute mouse). -I section:key=value entries are applied to
 * every file in the image whose name matches one of the --ini names
 * (default NET.INI and NETEC.INI) after the tree has been synced.
 ***********************************************************************/
static char *
ReadImageFile(const char *path, UINT *lenPtr)
{
    FIL	    f;
    UINT    br;
    char    *buf;
    FSIZE_t size;

    if (f_open(&f, path, FA_READ) != FR_OK) {
	return NULL;
    }
    size = f_size(&f);
    buf = (char *)malloc((size_t)size + 1);
    if (buf == NULL) {
	Fatal("out of memory");
    }
    if (f_read(&f, buf, (UINT)size, &br) != FR_OK || br != size) {
	Fatal("cannot read %s", path);
    }
    f_close(&f);
    buf[size] = '\0';
    *lenPtr = (UINT)size;
    return buf;
}

/*
 * Return pointer to the start of the line following p (or the end).
 */
static char *
NextLine(char *p)
{
    while (*p && *p != '\n') {
	p++;
    }
    return *p ? p + 1 : p;
}

static char *
SkipBlanks(char *p)
{
    while (*p == ' ' || *p == '\t') {
	p++;
    }
    return p;
}

/*
 * Apply one "section:key=value" to an ini text. Returns a new buffer.
 */
static char *
IniSet(char *text, const char *spec)
{
    char	section[128], key[128];
    const char	*value, *colon, *eq;
    char	*line, *secStart = NULL, *insertAt = NULL, *replStart = NULL,
		*replEnd = NULL, *result;
    size_t	keyLen, secLen;
    int		inSection = 0;
    char	newLine[512];

    colon = strchr(spec, ':');
    eq = colon ? strchr(colon, '=') : NULL;
    if (colon == NULL || eq == NULL || colon == spec ||
	(size_t)(colon - spec) >= sizeof(section) ||
	(size_t)(eq - colon - 1) >= sizeof(key) || eq == colon + 1)
    {
	Fatal("bad -I argument \"%s\" (section:key=value expected)", spec);
    }
    secLen = colon - spec;
    memcpy(section, spec, secLen);
    section[secLen] = '\0';
    keyLen = eq - colon - 1;
    memcpy(key, colon + 1, keyLen);
    key[keyLen] = '\0';
    value = eq + 1;
    sprintf(newLine, "%s = %s\r\n", key, value);

    for (line = text; *line; line = NextLine(line)) {
	char *p = SkipBlanks(line);

	if (*p == '[') {
	    char *end = strchr(p, ']');

	    if (inSection) {
		break;		/* key not found in section */
	    }
	    if (end != NULL && (size_t)(end - p - 1) == secLen) {
		size_t i;

		for (i = 0; i < secLen; i++) {
		    if (toupper((unsigned char)p[1 + i]) !=
			toupper((unsigned char)section[i]))
		    {
			break;
		    }
		}
		if (i == secLen) {
		    inSection = 1;
		    secStart = line;
		    insertAt = NextLine(line);
		}
	    }
	    continue;
	}
	if (inSection) {
	    size_t i;

	    for (i = 0; i < keyLen; i++) {
		if (toupper((unsigned char)p[i]) !=
		    toupper((unsigned char)key[i]))
		{
		    break;
		}
	    }
	    if (i == keyLen && (*SkipBlanks(p + keyLen) == '=')) {
		replStart = line;
		replEnd = NextLine(line);
		break;
	    }
	    if (*p != '\r' && *p != '\n' && *p != '\0') {
		insertAt = NextLine(line);
	    }
	}
    }

    result = (char *)malloc(strlen(text) + strlen(newLine) + 16 +
			    secLen);
    if (result == NULL) {
	Fatal("out of memory");
    }
    if (replStart != NULL) {
	memcpy(result, text, replStart - text);
	strcpy(result + (replStart - text), newLine);
	strcat(result, replEnd);
    } else if (secStart != NULL) {
	memcpy(result, text, insertAt - text);
	result[insertAt - text] = '\0';
	/* make sure the previous line is terminated */
	if (insertAt > text && insertAt[-1] != '\n') {
	    strcat(result, "\r\n");
	}
	strcat(result, newLine);
	strcat(result, insertAt);
    } else {
	strcpy(result, text);
	if (result[0] && result[strlen(result) - 1] != '\n') {
	    strcat(result, "\r\n");
	}
	sprintf(result + strlen(result), "[%s]\r\n%s", section, newLine);
    }
    free(text);
    return result;
}

static void
PatchIniFile(const char *path)
{
    UINT    len;
    char    *text = ReadImageFile(path, &len);
    int	    i;

    if (text == NULL) {
	return;
    }
    for (i = 0; i < numIniSets; i++) {
	text = IniSet(text, iniSets[i]);
    }
    WriteImageText(path, text);
    free(text);
    if (optVerbose) {
	Info("  patched %s", path + 3);
    }
}

static void
PatchIniFiles(const char *dir)
{
    DosNameBuf	*names;
    int		count, i, j;
    char	path[MAX_PATH_LEN];
    FILINFO	fi;

    names = ReadImageDir(dir, &count);
    for (i = 0; i < count; i++) {
	sprintf(path, "%s/%s", dir, names[i]);
	if (f_stat(path, &fi) != FR_OK) {
	    continue;
	}
	if (fi.fattrib & AM_DIR) {
	    PatchIniFiles(path);
	    continue;
	}
	for (j = 0; j < numIniNames; j++) {
	    if (StrCaseEq(names[i], iniNames[j])) {
		PatchIniFile(path);
		break;
	    }
	}
    }
    free(names);
}

/***********************************************************************
 *		DOS configuration
 ***********************************************************************/
static void
InstallDosFiles(int created)
{
    char    config[2048], autoexec[4096], line[512];
    int	    haveXms = 0, haveMouse = 0, haveCd = 0;

    f_mkdir("0:/FDOS");

    if (created) {
	if (!InstallFreeDosFile(optKernel, "0:/KERNEL.SYS")) {
	    Fatal("FreeDOS kernel %s not found (template or -S directory)",
		  optKernel);
	}
	f_chmod("0:/KERNEL.SYS", AM_SYS, AM_SYS);
	if (!InstallFreeDosFile("COMMAND.COM", "0:/COMMAND.COM")) {
	    Fatal("COMMAND.COM not found (template or -S directory)");
	}
    }

    if (optXms != NULL && optXms[0] != '\0') {
	sprintf(line, "0:/FDOS/%s", optXms);
	haveXms = InstallFreeDosFile(optXms, line);
	if (!haveXms) {
	    Warn("XMS driver %s not found, continuing without it", optXms);
	}
    }
    if (optMouse != NULL) {
	haveMouse = InstallFreeDosFile("CTMOUSE.EXE", "0:/FDOS/CTMOUSE.EXE");
	if (!haveMouse) {
	    Warn("CTMOUSE.EXE not found; PC/GEOS will have no mouse");
	}
    }
    if (optCdrom) {
	haveCd = InstallFreeDosFile("UDVD2.SYS", "0:/FDOS/UDVD2.SYS") &&
	    (InstallFreeDosFile("SHSUCDX.COM", "0:/FDOS/SHSUCDX.COM") ||
	     InstallFreeDosFile("SHSUCDX.EXE", "0:/FDOS/SHSUCDX.EXE"));
	if (!haveCd) {
	    Warn("UDVD2.SYS/SHSUCDX not found, no CD-ROM drive in DOS");
	}
    }

    /* CONFIG.SYS */
    strcpy(config,
	   "; Generated by img86box - rewritten on every image update\r\n");
    if (haveXms) {
	sprintf(line, "DEVICE=C:\\FDOS\\%s\r\nDOS=HIGH\r\n", optXms);
	strcat(config, line);
    }
    if (haveCd) {
	strcat(config, "DEVICE=C:\\FDOS\\UDVD2.SYS /D:GEOSCD01\r\n");
    }
    strcat(config,
	   "FILES=60\r\nBUFFERS=20\r\nLASTDRIVE=Z\r\n"
	   "SHELL=C:\\COMMAND.COM C:\\ /E:1024 /P\r\n");
    WriteImageText("0:/CONFIG.SYS", config);
    /* make sure a template FDCONFIG.SYS cannot take precedence */
    f_unlink("0:/FDCONFIG.SYS");

    /* AUTOEXEC.BAT */
    if (optAutoexec != NULL) {
	struct stat st;

	if (stat(optAutoexec, &st) != 0) {
	    Fatal("cannot find %s", optAutoexec);
	}
	CopyHostFile(optAutoexec, "0:/AUTOEXEC.BAT", st.st_mtime);
	return;
    }
    strcpy(autoexec,
	   "@ECHO OFF\r\n"
	   "REM Generated by img86box - rewritten on every image update\r\n"
	   "SET PATH=C:\\FDOS;C:\\\r\n");
    sprintf(line, "SET PTTY=%s\r\n", optPtty);
    strcat(autoexec, line);
    if (haveMouse) {
	sprintf(line, "C:\\FDOS\\CTMOUSE.EXE %s\r\n", optMouse);
	strcat(autoexec, line);
    }
    if (haveCd) {
	strcat(autoexec, "IF EXIST C:\\FDOS\\SHSUCDX.COM "
	       "C:\\FDOS\\SHSUCDX.COM /D:GEOSCD01,R\r\n");
	strcat(autoexec, "IF EXIST C:\\FDOS\\SHSUCDX.EXE "
	       "C:\\FDOS\\SHSUCDX.EXE /D:GEOSCD01,R\r\n");
    }
    strcat(autoexec, "C:\r\n");
    if (optWorkDir[0] != '\0') {
	sprintf(line, "CD \\%s\r\n", optWorkDir);
	strcat(autoexec, line);
    }
    strcat(autoexec, "IF EXIST SETUP.BAT CALL SETUP.BAT\r\n");
    sprintf(line, "%s\r\n", optRun);
    strcat(autoexec, line);
    WriteImageText("0:/AUTOEXEC.BAT", autoexec);
}

/***********************************************************************
 *		Main
 ***********************************************************************/
static void
Usage(void)
{
    printf(
"img86box " IMG86BOX_VERSION " - bootable FreeDOS + PC/GEOS disk image for 86Box\n"
"\n"
"usage: img86box -o IMAGE -s TREE [-f FREEDOS_IMAGE] [options]\n"
"\n"
"  -o IMAGE      disk image to create or update\n"
"  -s TREE       target tree copied to C:\\ (gbuild's localpc directory)\n"
"  -f IMAGE      bootable FreeDOS hard disk image: source of the boot\n"
"                code and the FreeDOS files (needed to create an image)\n"
"  -S DIR        take FreeDOS files from DIR first (KERNEL.SYS, ...)\n"
"  -t STUB       Swat stub installed instead of every SWAT.EXE in TREE\n"
"  -m MB         size of a new image in MB (default %d, %d..504)\n"
"  -p PTTY       value of PTTY for the stub (default \"%s\")\n"
"  -k NAME       FreeDOS kernel file to install as KERNEL.SYS\n"
"  -x NAME       XMS driver to load from CONFIG.SYS (e.g. HIMEMX.EXE)\n"
"  -M ARGS       load CTMOUSE.EXE with ARGS (e.g. \"/P\" or \"/S2\")\n"
"  -w DIR        working directory for the start command (default %s)\n"
"  -r CMD        start command (default \"%s\")\n"
"  -a FILE       use FILE as AUTOEXEC.BAT instead of generating it\n"
"  -P DIR        prune directory (repeatable): files missing in TREE are\n"
"                deleted below DIR, e.g. ENSEMBLE/SYSTEM\n"
"  --no-prune    never delete files from the image\n"
"  -I S:K=V      set key K in section S of the GEOS ini files (repeatable)\n"
"  --ini NAME    ini file name -I applies to (repeatable, default NET.INI\n"
"                and NETEC.INI, anywhere in the image)\n"
"  --cdrom       load the FreeDOS CD-ROM drivers (drive R:)\n"
"  --fresh       recreate the image even if it exists\n"
"  --force       skip the \"image in use\" check\n"
"  -v            list every file that is copied or deleted\n"
"\n"
"usage: img86box -f FREEDOS_IMAGE --get NAME=HOSTFILE ...\n"
"  copy files found in the FreeDOS image (e.g. package archives) to the\n"
"  host; exit code 2 if one of them was not found (-v: report progress)\n",
	DEFAULT_SIZE_MB, MIN_SIZE_MB, optPtty, optWorkDir, optRun);
}

static const char *
NeedArg(int argc, char **argv, int *i)
{
    if (*i + 1 >= argc) {
	Fatal("option %s needs an argument", argv[*i]);
    }
    *i += 1;
    return argv[*i];
}

static char *
NormalizePruneDir(const char *s)
{
    char    *d = (char *)malloc(strlen(s) + 1);
    char    *p;

    if (d == NULL) {
	Fatal("out of memory");
    }
    while (*s == '/' || *s == '\\') {
	s++;
    }
    strcpy(d, s);
    for (p = d; *p; p++) {
	if (*p == '\\') {
	    *p = '/';
	}
    }
    while (p > d && p[-1] == '/') {
	*--p = '\0';
    }
    StrUpper(d);
    return d;
}

int
main(int argc, char **argv)
{
    int	    i, created = 0;
    FILE    *fp;
    long    fileSize = -1;
    DWORD   partSectors = 0;
    FRESULT res;

    for (i = 1; i < argc; i++) {
	const char *a = argv[i];

	if (!strcmp(a, "-o")) {
	    optImage = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-s")) {
	    optTree = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-f")) {
	    optTemplate = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-S")) {
	    optSysDir = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-t")) {
	    optStub = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-m")) {
	    optSizeMB = atoi(NeedArg(argc, argv, &i));
	} else if (!strcmp(a, "-p")) {
	    optPtty = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-k")) {
	    optKernel = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-x")) {
	    optXms = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-M")) {
	    optMouse = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-w")) {
	    optWorkDir = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-r")) {
	    optRun = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-a")) {
	    optAutoexec = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "-P")) {
	    if (numPruneDirs == MAX_LIST) {
		Fatal("too many -P options");
	    }
	    pruneDirs[numPruneDirs++] =
		NormalizePruneDir(NeedArg(argc, argv, &i));
	    pruneDirsGiven = 1;
	} else if (!strcmp(a, "-I")) {
	    if (numIniSets == MAX_LIST) {
		Fatal("too many -I options");
	    }
	    iniSets[numIniSets++] = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "--ini")) {
	    if (numIniNames == MAX_LIST) {
		Fatal("too many --ini options");
	    }
	    iniNames[numIniNames++] = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "--get")) {
	    if (numGetSpecs == MAX_LIST) {
		Fatal("too many --get options");
	    }
	    getSpecs[numGetSpecs++] = NeedArg(argc, argv, &i);
	} else if (!strcmp(a, "--no-prune")) {
	    optPrune = 0;
	} else if (!strcmp(a, "--cdrom")) {
	    optCdrom = 1;
	} else if (!strcmp(a, "--fresh")) {
	    optFresh = 1;
	} else if (!strcmp(a, "--force")) {
	    optForce = 1;
	} else if (!strcmp(a, "-v")) {
	    optVerbose = 1;
	} else if (!strcmp(a, "-h") || !strcmp(a, "--help") ||
		   !strcmp(a, "-?"))
	{
	    Usage();
	    return 0;
	} else {
	    Usage();
	    Fatal("unknown option %s", a);
	}
    }
    if (numGetSpecs > 0) {
	int missing = 0;

	if (optTemplate == NULL) {
	    Fatal("--get needs a FreeDOS image (-f)");
	}
	optQuiet = !optVerbose;
	OpenTemplate(optTemplate);
	for (i = 0; i < numGetSpecs; i++) {
	    if (!GetTemplateFile(getSpecs[i])) {
		if (optVerbose) {
		    Warn("%.*s not found in %s",
			 (int)(strchr(getSpecs[i], '=') - getSpecs[i]),
			 getSpecs[i], optTemplate);
		}
		missing = 1;
	    }
	}
	f_mount(NULL, "1:", 0);
	fclose(tmpl.fp);
	return missing ? 2 : 0;
    }
    if (optImage == NULL || optTree == NULL) {
	Usage();
	Fatal("-o and -s are required");
    }
    if (!HostIsDir(optTree)) {
	Fatal("target tree %s is not a directory", optTree);
    }
    if (optSizeMB < MIN_SIZE_MB ||
	optSizeMB > GEO_MAX_CYLS * GEO_HEADS * GEO_SECTORS / 2048)
    {
	Fatal("image size must be between %d and %d MB", MIN_SIZE_MB,
	      GEO_MAX_CYLS * GEO_HEADS * GEO_SECTORS / 2048);
    }
    if (!pruneDirsGiven) {
	/* build-owned directories of the target tree */
	pruneDirs[numPruneDirs++] = "ENSEMBLE/FREEGEOS";
	pruneDirs[numPruneDirs++] = "ENSEMBLE/SYSTEM";
	pruneDirs[numPruneDirs++] = "ENSEMBLE/WORLD";
    }
    if (!optForce) {
	CheckImageNotInUse(optImage);
    }

    /*
     * Open an existing image, or decide to create a new one.
     */
    fp = NULL;
    if (!optFresh) {
	fp = fopen(optImage, "r+b");
	if (fp != NULL) {
	    fileSize = HostFileSize(fp);
	    partSectors = CheckExistingImage(fp, fileSize);
	    if (partSectors != 0 &&
		FatImg_Attach(DRV_IMAGE, fp, PART_START, partSectors,
			      0) == 0 &&
		f_mount(&fsImage, "0:", 1) == FR_OK)
	    {
		Info("Updating %s", optImage);
	    } else {
		Warn("%s is not a usable img86box image, recreating it",
		     optImage);
		FatImg_Detach(DRV_IMAGE);
		fclose(fp);
		fp = NULL;
	    }
	}
    }
    if (optTemplate != NULL) {
	OpenTemplate(optTemplate);
    }
    if (fp == NULL) {
	DWORD cyls = (DWORD)optSizeMB * 2048 / (GEO_HEADS * GEO_SECTORS);

	if (optTemplate == NULL) {
	    Fatal("creating an image needs a FreeDOS image (-f)");
	}
	if (cyls > GEO_MAX_CYLS) {
	    cyls = GEO_MAX_CYLS;
	}
	fp = fopen(optImage, "w+b");
	if (fp == NULL) {
	    Fatal("cannot create %s", optImage);
	}
	CreateImage(fp, cyls * GEO_HEADS * GEO_SECTORS);
	res = f_mount(&fsImage, "0:", 1);
	CheckF(res, "cannot mount new image", optImage);
	f_setlabel(optLabel);
	created = 1;
    }
    /*
     * DOS files first, so the image boots even if the tree copy fails
     * (image full).
     */
    InstallDosFiles(created);

    Info("Copying %s", optTree);
    SyncDir(optTree, "0:", "");

    if (numIniSets > 0) {
	if (numIniNames == 0) {
	    iniNames[numIniNames++] = "NET.INI";
	    iniNames[numIniNames++] = "NETEC.INI";
	}
	PatchIniFiles("0:");
    }

    res = f_mount(NULL, "0:", 0);
    if (haveTemplateFs) {
	f_mount(NULL, "1:", 0);
	fclose(tmpl.fp);
    }
    if (fflush(fp) != 0 || fclose(fp) != 0) {
	Fatal("writing %s failed", optImage);
    }
    Info("%s: %lu copied, %lu unchanged, %lu deleted, %lu skipped",
	 optImage, statCopied, statSkipped, statDeleted, statIgnored);
    return 0;
}
