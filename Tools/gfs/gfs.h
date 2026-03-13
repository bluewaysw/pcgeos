/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  gfs -- Definitions file
 * FILE:	  gfs.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * DESCRIPTION:
 *	Header file for gfs
 *
 * 	$Id: gfs.h,v 1.8 97/04/28 16:33:53 clee Exp $
 *
 ***********************************************************************/
#ifndef _GFS_H
#define _GFS_H

typedef int Boolean;

#define FALSE	  0
#define TRUE	  (!FALSE)

#include    <config.h>
#include    <bswap.h>
#include    <stdio.h>
#include    <ctype.h>
#include    <stdarg.h>
#include    <stddef.h>
#include    <stdlib.h>		/* not compat/stdlib.h (no utils) */
#include    <compat/string.h>
#include    <compat/file.h>
#include    <sys/types.h>
#include    <sys/stat.h>
#include    <memory.h>

#if defined(_MSDOS)
#include    <process.h>
typedef unsigned char byte;
typedef unsigned int word;
typedef unsigned long dword;

#else

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int dword;
#endif

#if defined(unix)
#include    <unistd.h>

/* SunOS header files are lame */
extern int sscanf(char *s, char *format, ...);
extern int printf(char *format, ...);
extern int fprintf(FILE *stream, char *format, ...);
extern int vfprintf(FILE *stream, char *format, va_list ap);
extern char *strdup(char *s);
extern int  toupper(int c);
extern long tell (int fd);
#endif

/*
 * This works in both Borland C and GNU C
 */

#define SwapWord swaps
#define SwapDWord swapl

/*
 * Data structures for GFS file systems
 */

#define GFS_PROTO_MAJOR	    1
#define GFS_PROTO_MINOR	    0

typedef struct {
    char    signature[4];   	/* "GFS:" */
    char    checksum[8];   	/* checksum in hex digits */
    char    crlfcrlf[4];   	/* C_CR, C_LF, C_CR, C_LF */
    char    description[100];  	/* Text description, Ctrl-Z terminated */
    word    versionMajor;
    word    versionMinor;
    dword   totalSize;
    char    reserved[16];
} GFSFileHeader;

#define FILE_LONGNAME_LENGTH 32
#define DOS_NO_DOT_FILE_NAME_LENGTH 11

#define FA_GEOS	    	0x80	    /* a GEOS implemented flag */
#define FA_LINK	    	0x40
#define FA_ARCHIVE	0x20
#define FA_SUBDIR	0x10
#define FA_VOLUME	0x8
#define FA_SYSTEM	0x4
#define FA_HIDDEN	0x2
#define FA_RDONLY	0x1

#define GFT_NOT_GEOS_FILE 0
#define GFT_EXECUTABLE	1
#define GFT_VM	    	2
#define GFT_DATA    	3
#define GFT_DIRECTORY	4

typedef struct {
    char    longName[FILE_LONGNAME_LENGTH];
    char    dosName[DOS_NO_DOT_FILE_NAME_LENGTH];
    byte    attrs;  	/* FA_ */
    dword   data;
    dword   size;
    byte    type;  	/* GFT_ */
} GFSDirEntry;

#define DIR_ENTRY_REAL_SIZE 53

#define GFHF_TEMPLATE		0x8000
#define GFHF_SHARED_MULTIPLE	0x4000
#define GFHF_SHARED_SINGLE	0x2000
#define GFHF_HIDDEN		0x0800

typedef struct {
    word	RN_major;
    word	RN_minor;
    word	RN_change;
    word	RN_engineering;
} ReleaseNumber;

typedef struct {
    word	PN_major;
    word	PN_minor;
} ProtocolNumber;

#define TOKEN_CHARS_LENGTH 4
typedef char TokenChars[TOKEN_CHARS_LENGTH];

typedef struct {
    TokenChars		GT_chars;
    word    		GT_manufID;
} GeodeToken;

#define GFH_USER_NOTES_BUFFER_SIZE 100
#define GFH_NOTICE_SIZE 32
#define FILE_DESKTOP_INFO_SIZE 16

#define FDAT_HOUR		0xf8000000
#define FDAT_MINUTE		0x07e00000
#define FDAT_2SECOND		0x001f0000
#define FDAT_YEAR		0x0000fe00
#define FDAT_MONTH		0x000001e0
#define FDAT_DAY		0x0000001f

#define FDAT_HOUR_OFFSET	27
#define FDAT_MINUTE_OFFSET	21
#define FDAT_2SECOND_OFFSET	16
#define FDAT_YEAR_OFFSET	9
#define FDAT_MONTH_OFFSET	5
#define FDAT_DAY_OFFSET		0

#define FDAT_BASE_YEAR		1980

#define GA_PROCESS			0x8000
#define GA_LIBRARY			0x4000
#define GA_DRIVER			0x2000
#define GA_KEEP_FILE_OPEN		0x1000
#define GA_SYSTEM			0x0800
#define GA_MULTI_LAUNCHABLE		0x0400
#define GA_APPLICATION			0x0200
#define GA_DRIVER_INITIALIZED		0x0100
#define GA_LIBRARY_INITIALIZED		0x0080
#define GA_GEODE_INITIALIZED		0x0040
#define GA_USES_COPROC			0x0020
#define GA_REQUIRES_COPROC		0x0010
#define GA_HAS_GENERAL_CONSUMER_MODE	0x0008
#define GA_ENTRY_POINTS_IN_C		0x0004

#define FDAT_HOUR_OFFSET        27
#define FDAT_MINUTE_OFFSET      21
#define FDAT_2SECOND_OFFSET     16
#define FDAT_YEAR_OFFSET        9
#define FDAT_MONTH_OFFSET       5
#define FDAT_DAY_OFFSET         0

typedef struct {
    char    	    longName[FILE_LONGNAME_LENGTH];
    char    	    dosName[DOS_NO_DOT_FILE_NAME_LENGTH];
    byte    	    attrs;  	/* FA_ */
    word    	    type;   	/* GFT_ */
    word    	    flags;  	/* GFHF_ */
    ReleaseNumber   release;
    ProtocolNumber  protocol;
    GeodeToken	    token;
    GeodeToken	    creator;
    char    	    userNotes[GFH_USER_NOTES_BUFFER_SIZE];
    char    	    notice[GFH_NOTICE_SIZE];
    dword   	    created;
    char    	    desktop[FILE_DESKTOP_INFO_SIZE];
    dword   	    modified;
    dword   	    size;
    dword   	    targetID;	    	/* links only */
    word    	    geodeAttrs;
} GFSExtAttrs;

#define EXT_ATTR_REAL_SIZE 238
#define EXT_ATTR_ALIGNED_SIZE 256
#define FILE_LONGNAME_BUFFER_SIZE 36

typedef struct {
    char    	    signature[4];
    char    	    longName[FILE_LONGNAME_BUFFER_SIZE];
    word    	    type;   	/* GFT_ */
    word    	    flags;  	/* GFHF_ */
    ReleaseNumber   release;
    ProtocolNumber  protocol;
    GeodeToken	    token;
    GeodeToken	    creator;
    char    	    userNotes[GFH_USER_NOTES_BUFFER_SIZE];
    char    	    notice[GFH_NOTICE_SIZE];
    dword   	    created;
    char    	    password[8];
    char    	    desktop[FILE_DESKTOP_INFO_SIZE];
    char    	    unused[28];
}GeosFileHeader;

typedef struct {
    char    	    signature[4];
    char    	    longName[FILE_LONGNAME_BUFFER_SIZE];
    word    	    type;   	/* GFT_ */
    word    	    flags;  	/* GFHF_ */
    ReleaseNumber   release;
    ProtocolNumber  protocol;
    GeodeToken	    token;
    GeodeToken	    creator;

    char    	    desktop[FILE_DESKTOP_INFO_SIZE];
    byte    	    attrs;  	/* FA_ */
    char    	    geodeAttr[2];   	    /* not aligned, must use char */
    char    	    targetFileID[4];   	    /* not aligned, must use char */
    char    	    unused[16];   	    /* not aligned, must use char */
} DOSLinkHeader;

#define DOS_LINK_REAL_SIZE 107

typedef struct {
    word    	    diskSize;
    word    	    pathSize;
    word    	    extraDataSize;
} DOSLinkData;

#define DOS_LINK_DATA_REAL_SIZE 6

typedef struct _Special {
    char    	    *name;	    /* Name of this component */
    int	    	    flags;  	    /* What's so special about this thing */
#define SF_HIDDEN   	    0x0001  	/* Make file hidden */
#define SF_LOCAL    	    0x0002  	/* Place file in localizable portion */
    struct _Special  *nextSib;	    /* Next thing at the same level */
    struct _Special  *firstChild;   /* If non-null, then this thing itself
				     * is not to be hidden, but it's a
				     * directory that contains something
				     * that needs to be hidden. firstChild
				     * points to the first record within the
				     * directory that requires similar
				     * processing */
} Special;

/*
 * Global variables
 */

extern int  	alignSize;

extern int  	debug;

extern Special	*root;

extern long 	dirBase;
extern long 	fileBase;

extern int  	dataOnlyChecksum;

extern Boolean	doDbcs;

/*
 * Exported function definitions.
 */

extern void gfserror(char *fmt, ...);

extern void CreateGFS(int destFile, GFSFileHeader *fileHeader,
		      char *volumeName, dword limit);

extern void ListGFS(int sourceFile);

#endif /* _GFS_H */
