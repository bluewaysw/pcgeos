/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	file.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines file structures and routines.
 *
 *	$Id: file.h,v 1.2 98/05/01 17:27:38 martin Exp $
 *
 ***********************************************************************/

#ifndef	__FILE_H
#define __FILE_H

/*
 * File system errors
 */

typedef WordFlags FileError;
#define ERROR_UNSUPPORTED_FUNCTION  	1
#define ERROR_FILE_NOT_FOUND		2
#define ERROR_PATH_NOT_FOUND		3
#define ERROR_TOO_MANY_OPEN_FILES	4
#define ERROR_ACCESS_DENIED		5
#define ERROR_INSUFFICIENT_MEMORY	8
#define ERROR_INVALID_VOLUME		15
#define ERROR_IS_CURRENT_DIRECTORY	16
#define ERROR_DIFFERENT_DEVICE		17
#define ERROR_NO_MORE_FILES		18
#define ERROR_WRITE_PROTECTED		19
#define ERROR_UNKNOWN_VOLUME		20
#define ERROR_DRIVE_NOT_READY		21
#define ERROR_CRC_ERROR			23
#define ERROR_SEEK_ERROR		25
#define ERROR_UNKNOWN_MEDIA		26
#define ERROR_SECTOR_NOT_FOUND		27
#define ERROR_WRITE_FAULT		29
#define ERROR_READ_FAULT		30
#define ERROR_GENERAL_FAILURE		31
#define ERROR_SHARING_VIOLATION		32
#define ERROR_ALREADY_LOCKED		33
#define ERROR_SHARING_OVERFLOW		36
#define ERROR_NETWORK_CONNECTION_BROKEN	55
#define ERROR_NETWORK_ACCESS_DENIED 	65
#define ERROR_NETWORK_NOT_LOGGED_IN 	78
#define ERROR_SHORT_READ_WRITE		128
#define ERROR_INVALID_LONGNAME		129
#define ERROR_FILE_EXISTS		130
#define ERROR_DOS_EXEC_IN_PROGRESS	131
#define ERROR_FILE_IN_USE		132
#define ERROR_ARGS_TOO_LONG		133
#define ERROR_DISK_UNAVAILABLE	    	134
#define ERROR_DISK_STALE	    	135
#define ERROR_FILE_FORMAT_MISMATCH	136
#define ERROR_CANNOT_MAP_NAME	    	137
#define ERROR_DIRECTORY_NOT_EMPTY	138
#define ERROR_ATTR_NOT_SUPPORTED	139
#define ERROR_ATTR_NOT_FOUND	    	140
#define ERROR_ATTR_SIZE_MISMATCH	141
#define ERROR_ATTR_CANNOT_BE_SET	142
#define ERROR_CANNOT_MOVE_DIRECTORY	143
#define ERROR_PATH_TOO_LONG	    	144
#define ERROR_ARGS_INVALID  	    	145
#define ERROR_CANNOT_FIND_COMMAND_INTERPRETER 146
#define ERROR_NO_TASK_DRIVER_LOADED 	147

/*
 * Constants for file system routines
 */

typedef ByteEnum FileExclude;
#define FE_EXCLUSIVE 1
#define FE_DENY_WRITE 2
#define FE_DENY_READ 3
#define FE_NONE 4

typedef ByteEnum FileAccess;
#define FA_READ_ONLY 0
#define FA_WRITE_ONLY 1
#define FA_READ_WRITE 2

typedef ByteFlags FileAccessFlags;
#define FILE_DENY_RW	0x10
#define FILE_DENY_W	0x20
#define FILE_DENY_R	0x30
#define FILE_DENY_NONE	0x40

#define FILE_ACCESS_R	0x00
#define FILE_ACCESS_W	0x01
#define FILE_ACCESS_RW	0x02

#define FILE_NO_ERRORS	0x80

typedef ByteFlags FileAttrs;
#define FA_LINK	    	0x40
#define FA_ARCHIVE	0x20
#define FA_SUBDIR	0x10
#define FA_VOLUME	0x8
#define FA_SYSTEM	0x4
#define FA_HIDDEN	0x2
#define FA_RDONLY	0x1

#define FILE_ATTR_NORMAL	0
#define FILE_ATTR_READ_ONLY	FA_RDONLY
#define FILE_ATTR_HIDDEN	FA_HIDDEN
#define FILE_ATTR_SYSTEM	FA_SYSTEM
#define FILE_ATTR_VOLUME_LABEL	FA_VOLUME

typedef dword	FileID;
typedef struct {    /* Element of array returned by FileGetCurrentPathIDs */
    word    FPID_disk;	    /* disk handle */
    FileID  FPID_id;	    /* id for path on that disk */
} FilePathID;

#define FILE_NO_ID  (0)


typedef enum /* word */ {
    FEA_MODIFICATION,
    FEA_FILE_ATTR,
    FEA_SIZE,
    FEA_FILE_TYPE,
    FEA_FLAGS,
    FEA_RELEASE,
    FEA_PROTOCOL,
    FEA_TOKEN,
    FEA_CREATOR,
    FEA_USER_NOTES,
    FEA_NOTICE,
    FEA_CREATION,
    FEA_PASSWORD,
    FEA_CUSTOM,
    FEA_NAME,
    FEA_GEODE_ATTR,
    FEA_PATH_INFO,
    FEA_FILE_ID,
    FEA_DESKTOP_INFO,
    FEA_DRIVE_STATUS,
    FEA_DISK,
    FEA_DOS_NAME,
    FEA_OWNER,
    FEA_RIGHTS,
    FEA_MULTIPLE=0xfffe,
    FEA_END_OF_LIST=0xffff,
} FileExtendedAttribute;

typedef struct {
    FileExtendedAttribute   FEAD_attr;	    /* Attribute to get/set */
    void    	    	    *FEAD_value;    /* Pointer to buffer/new value */
    word    	    	    FEAD_size;	    /* Size of buffer/new value */
    TCHAR    	    	    *FEAD_name;	    /* Null-terminated ASCII name of
					     * attribute if FEA_CUSTOM */
} FileExtAttrDesc;

/* very similar v^, just needed to get around too picky type checking in XIP */

typedef struct {
    FileExtendedAttribute   FEAD_attr;	    /* Attribute to get/set */
    dword    	    	    *FEAD_value;    /* Pointer to buffer/new value */
    word    	    	    FEAD_size;	    /* Size of buffer/new value */
    TCHAR    	    	    *FEAD_name;	    /* Null-terminated ASCII name of
					     * attribute if FEA_CUSTOM */
} FileExtAttrDescLike;

/* GEOS file types */

typedef enum /* word */ {
    GFT_NOT_GEOS_FILE,
    GFT_EXECUTABLE,
    GFT_VM,
    GFT_DATA,
    GFT_DIRECTORY,
    GFT_LINK
} GeosFileType;


/* GEOS file header flags */

typedef WordFlags GeosFileHeaderFlags;
#define GFHF_TEMPLATE		0x8000
#define GFHF_SHARED_MULTIPLE	0x4000
#define GFHF_SHARED_SINGLE	0x2000
#define GFHF_HIDDEN		0x0800
#define GFHF_DBCS		0x0400
#define GFHF_UNREAD 	    	0x0200
#define GFHF_NOTES  	    	0x0100

/* Size of the user notes field in the file header */

#define GFH_USER_NOTES_LENGTH		(100 / sizeof(TCHAR)) - 1
#define GFH_USER_NOTES_BUFFER_SIZE	(GFH_USER_NOTES_LENGTH + 1) * sizeof(TCHAR)
typedef TCHAR FileUserNotes[GFH_USER_NOTES_BUFFER_SIZE];

/* Size of copyright notice */

#define GFH_NOTICE_SIZE	32
typedef char FileCopyrightNotice[GFH_NOTICE_SIZE];

/*	Room reserved for use by the desktop. Currently unused. */

#define FILE_DESKTOP_INFO_SIZE	16
typedef char FileDesktopInfo[FILE_DESKTOP_INFO_SIZE];


/*	Password bound to the file (FEA_PASSWORD). Currently unused. Not
 *	likely to be returned in cleartext...null-terminated unless array
 *	is full... */

#define FILE_PASSWORD_SIZE	8
typedef char FilePassword[FILE_PASSWORD_SIZE];

/*	The name of the owner of a file (FEA_OWNER). Supported primarily by
 *	network filesystem drivers. Null-terminated in the PC/GEOS character
 *	set. */

#define FILE_OWNER_NAME_SIZE	16
typedef char FileOwnerName[FILE_OWNER_NAME_SIZE];

/*	The access rights for the file (FEA_RIGHTS), either overall (e.g.
 *	for NFS) or for the current user (e.g. for novell). Supported primarily
 *	by network filesystem drivers. Null-terminated in the PC/GEOS character
 *	set in a format that's appropriate to the filesystem. */

#define FILE_RIGHTS_SIZE	16
typedef char FileAccessRights[FILE_RIGHTS_SIZE];

/*	Data for FEA_PATH_INFO */

typedef word	DirPathInfo;
#define DPI_EXISTS_LOCALLY		0x8000
#define DPI_ENTRY_NUMBER_IN_PATH	0x7f00
#define DPI_ENTRY_NUMBER_IN_PATH_OFFSET	8
#define DPI_STD_PATH			0x00ff
#define DPI_STD_PATH_OFFSET		0

typedef WordFlags FileOpenAndReadFlags;
#define FOARF_ADD_CRLF	    	    	0x8000
#define FOARF_ADD_EOF	    	    	0x4000
#define FOARF_NULL_TERMINATE	    	0x2000


/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileCreateDir(const TCHAR *name);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileCreateDirWithNativeShortName(const TCHAR *name);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileDeleteDir(const TCHAR *name);

/***/

extern void
    _pascal FilePushDir(void);

/***/

extern void
    _pascal FilePopDir(void);

/***/

extern DiskHandle	/*XXX*/
    _pascal FileGetCurrentPath(TCHAR *buffer, word bufferSize);

/***/

extern ChunkHandle  	/*XXX*/
    _pascal FileGetCurrentPathIDs(MemHandle block);

/***/

extern void
    _pascal FileEnableOpenCloseNotification(void);

extern void
    _pascal FileDisableOpenCloseNotification(void);

/***/

extern void
    _pascal FileBatchChangeNotifications(void);

extern void
    _pascal FileFlushChangeNotifications(void);

/***/

extern DiskHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileSetCurrentPath(DiskHandle disk, const TCHAR *path);

extern DiskHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileSetCurrentPathRaw(DiskHandle disk, const TCHAR *path);

/***/

extern FileHandle			/* Sets value for ThreadGetError() */	
    _pascal FileOpen(const TCHAR *name, FileAccessFlags flags);

/***/

#define FILE_CREATE_TRUNCATE (0 << 8)
#define FILE_CREATE_NO_TRUNCATE (1 << 8)
#define FILE_CREATE_ONLY (2 << 8)

typedef WordFlags FileCreateFlags;

#define FCF_NATIVE  	    	    0x8000
#define FCF_NATIVE_WITH_EXT_ATTRS   0x4000
#define FCF_MODE    	    	    0x0300	/* Filled with FILE_CREATE_*
						 * constant */
#define FCF_ACCESS  	    	    0x00ff	/* Filled with FileAccessFlags*/

extern FileHandle			/* Sets value for ThreadGetError() */	
    _pascal FileCreate(const TCHAR *name, FileCreateFlags flags, FileAttrs attributes);

/***/


extern word		/* Returns error and sets value for ThreadGetError() */

    _pascal FileClose(FileHandle fh, Boolean noErrorFlag);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileCommit(FileHandle fh, Boolean noErrorFlag);

/***/

extern FileHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileCreateTempFile(const TCHAR *dir, 
			       FileCreateFlags flags, 
			       FileAttrs attributes);
/***/

extern word	    	/* Returns error and sets value for ThreadGetError() */ 
	_pascal FileDelete(const char *name);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileRename(const TCHAR *oldName, const TCHAR *newame);

/***/

extern word				/* Sets value for ThreadGetError() */	
    _pascal FileRead(FileHandle fh, void *buf, word count, Boolean noErrorFlag);

/***/

extern word				/* Sets value for ThreadGetError() */	
    _pascal FileWrite(FileHandle fh, const void *buf, word count, Boolean noErrorFlag);

/***/

typedef ByteEnum FilePosMode;
#define FILE_POS_START 0
#define FILE_POS_RELATIVE 1
#define FILE_POS_END 2

extern dword				/* Sets value for ThreadGetError() */	
    _pascal FilePos(FileHandle fh, dword posOrOffset, FilePosMode mode);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileTruncate(FileHandle fh, dword offset, Boolean noErrorFlag);

/***/

extern dword	/*XXX*/
    _pascal FileSize(FileHandle fh);


/***/

/* Masks & offsets for FileTime values */
typedef WordFlags FileTime;
#define FT_HOUR		        0xf800
#define FT_MINUTE		0x07e0
#define FT_2SECOND		0x001f
#define FT_HOUR_OFFSET	        11
#define FT_MINUTE_OFFSET	5
#define FT_2SECOND_OFFSET	0

/* Masks & offsets for FileDate values */
typedef WordFlags FileDate;
#define FD_YEAR		        0xfe00
#define FD_MONTH		0x01e0
#define FD_DAY                  0x001f
#define FD_YEAR_OFFSET	        9
#define FD_MONTH_OFFSET	        5
#define FD_DAY_OFFSET		0

/* Masks & offsets for FileDateAndTime values */
typedef DWordFlags FileDateAndTime;
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

/* Macros for extracting fields from FileDateAndTime values */

#define FDATExtractHour(fdat) /* XXX */		\
	((byte) (((fdat) & FDAT_HOUR) >> FDAT_HOUR_OFFSET))

#define FDATExtractMinute(fdat) /* XXX */	\
	((byte) (((fdat) & FDAT_MINUTE) >> FDAT_MINUTE_OFFSET))

#define FDATExtract2Second(fdat) /* XXX */	\
	((byte) (((fdat) & FDAT_2SECOND) >> FDAT_2SECOND_OFFSET))

#define FDATExtractSecond(fdat) /* XXX */	\
	(FDATExtract2Second(fdat) << 1)

#define FDATExtractYear(fdat) /* XXX */		\
	((byte) (((fdat) & FDAT_YEAR) >> FDAT_YEAR_OFFSET))

#define FDATExtractYearAD(fdat) /* XXX */	\
	(((word) FDATExtractYear(fdat)) + FDAT_BASE_YEAR)

#define FDATExtractMonth(fdat) /* XXX */	\
	((byte) (((fdat) & FDAT_MONTH) >> FDAT_MONTH_OFFSET))

#define FDATExtractDay(fdat) /* XXX */		\
 	((byte) (((fdat) & FDAT_DAY) >> FDAT_DAY_OFFSET))



extern FileDateAndTime		/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileGetDateAndTime(FileHandle fh);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileSetDateAndTime(FileHandle fh, FileDateAndTime dateAndTime);

/***/

extern FileHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileDuplicateHandle(FileHandle fh);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileLockRecord(FileHandle fh, dword filePos, dword regLength);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileUnlockRecord(FileHandle fh, dword filePos, dword regLength);

/***/

extern DiskHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileGetDiskHandle(FileHandle fh);

/***/

extern FileAttrs			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileGetAttributes(const TCHAR *path);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal FileSetAttributes(const TCHAR *path, FileAttrs attr);

/***/
extern word    /* Returns error and sets value for ThreadGetError() */ /*XXX*/
    _pascal FileGetPathExtAttributes(const TCHAR *path, FileExtendedAttribute attr,
			     void *buffer, word bufSize);

extern word    /* Returns error and sets value for ThreadGetError() */ /*XXX*/
    _pascal FileGetHandleExtAttributes(FileHandle fh, FileExtendedAttribute attr,
			       void *buffer, word bufSize);

extern MemHandle  /* Sets value for ThreadGetError() */  /*XXX*/
    _pascal FileGetHandleAllExtAttributes(FileHandle fh, word *numExtAttrs);

extern word    /* Returns error and sets value for ThreadGetError() */ /*XXX*/
    _pascal FileSetPathExtAttributes(const TCHAR *path, FileExtendedAttribute attr,
			     const void *buffer, word bufSize);

extern word    /* Returns error and sets value for ThreadGetError() */ /*XXX*/
    _pascal FileSetHandleExtAttributes(FileHandle fh, FileExtendedAttribute attr,
			       const void *buffer, word bufSize);

/***/

typedef enum /* word */ {
    SP_NOT_STANDARD_PATH=0,
    SP_TOP=1,
    SP_APPLICATION=3,
    SP_DOCUMENT=5,
    SP_SYSTEM=7,
    SP_PRIVATE_DATA=9,
    SP_STATE=11,
    SP_FONT=13,
    SP_SPOOL=15,
    SP_SYS_APPLICATION=17,
    SP_USER_DATA=19,
    SP_MOUSE_DRIVERS=21,
    SP_PRINTER_DRIVERS=23,
    SP_FILE_SYSTEM_DRIVERS=25,
    SP_VIDEO_DRIVERS=27,
    SP_SWAP_DRIVERS=29,
    SP_KEYBOARD_DRIVERS=31,
    SP_FONT_DRIVERS=33,
    SP_IMPORT_EXPORT_DRIVERS=35,
    SP_TASK_SWITCH_DRIVERS=37,
    SP_HELP_FILES=39,
    SP_TEMPLATE=41,
    SP_POWER_DRIVERS=43,
    SP_DOS_ROOM=45,
    SP_HWR=47,
    SP_WASTE_BASKET=49,
    SP_BACKUP=51,
    SP_PAGER_DRIVERS=53,
/* @protominor	BasicComponentDir */
    SP_COMPONENT=55,
/* @protoreset, */
    SP_DUMMY=256
} StandardPath;

/*
 * The names of some standard paths have changed. For backwards
 * compatibility, the old names are defined as equal to the new ones:
 */

#define SP_TEMP_FILES 	SP_WASTE_BASKET
#define SP_PUBLIC_DATA	SP_USER_DATA

extern void	
    _pascal FileSetStandardPath(StandardPath sp);

extern void	
    _pascal FileSetRootPath(DiskHandle disk);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */
    _pascal FileCopy(const TCHAR *source, const TCHAR *dest, 
		     DiskHandle sourceDisk, DiskHandle destDisk);

extern word		/* Returns error and sets value for ThreadGetError() */
    _pascal FileCopyLocal(const TCHAR *source, const TCHAR *dest, 
			  DiskHandle sourceDisk, DiskHandle destDisk);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */
    _pascal FileMove(const TCHAR *source, const TCHAR *dest, 
		     DiskHandle sourceDisk, DiskHandle destDisk);

extern word		/* Returns error and sets value for ThreadGetError() */
    _pascal FileMoveLocal(const TCHAR *source, const TCHAR *dest, 
			  DiskHandle sourceDisk, DiskHandle destDisk);

/***/

extern StandardPath	/*XXX*/
    _pascal FileParseStandardPath(DiskHandle disk, const TCHAR **path);

/***/

extern DiskHandle	/*XXX*/
    _pascal FileConstructFullPath(TCHAR **buffer, word bufSize,
					DiskHandle disk,
					const TCHAR *tail,
					Boolean addDriveLetter);

/***/

typedef WordFlags FileResolveStandardPathFlags;
#define FRSPF_ADD_DRIVE_NAME	    0x0002
#define FRSPF_RETURN_FIRST_DIR	    0x0001

extern DiskHandle   	/*XXX*/
    _pascal FileResolveStandardPath(TCHAR **buffer, word bufSize, const TCHAR *tail,
			    FileResolveStandardPathFlags flags,
			    FileAttrs *attrsPtr);
/***/

typedef ByteEnum PathCompareType;

#define PCT_EQUAL 0
#define PCT_SUBDIR 1
#define PCT_UNRELATED 2
#define PCT_ERROR 3

extern PathCompareType
 /*XXX*/
    _pascal FileComparePaths(const TCHAR *path1, 
			     	    DiskHandle disk1,
			     	    const TCHAR *path2,
			     	    DiskHandle disk2);

extern word
    _pascal FileCreateLink(const TCHAR *path,
					word targetDiskHandle,
					const TCHAR *targetPath,
					word targetAttrsFlag);
extern DiskHandle
    _pascal FileReadLink(const TCHAR *path, const TCHAR *targetPath);

extern DiskHandle
    _pascal FileSetLinkExtraData(const TCHAR *path,
					TCHAR *buffer,
					word bufSize);
extern DiskHandle
    _pascal FileGetLinkExtraData(const TCHAR *path,
					TCHAR *buffer,
					word bufSize);
extern DiskHandle
    _pascal FileConstructActualPath(TCHAR **buffer,
				    	word bufSize, DiskHandle disk,
				    	const TCHAR _far *tail,
				    	Boolean addDriveLetter);
extern word  
    /*XXX*/   
 _pascal FileCopyPathExtAttributes(const TCHAR *sourcePath,
				DiskHandle sourceDisk,
				const TCHAR *destPath,
				DiskHandle destDisk);

extern MemHandle /*XXX*/
 _pascal FileOpenAndRead(FileOpenAndReadFlags flags,
				const TCHAR _far *filename,
				FileHandle *fh);


/*
 * Various file system constants
 */

#define FILE_LONGNAME_LENGTH		32 / sizeof(TCHAR)
#define FILE_LONGNAME_BUFFER_SIZE	36

#define DRIVE_NAME_MAX_LENGTH	    	32

#define DOS_DRIVE_REF_LENGTH		3	/* B:\ */
#define DOS_STD_PATH_LENGTH		64

#define DOS_FILE_NAME_CORE_LENGTH	8
#define DOS_FILE_NAME_EXT_LENGTH	3

/* Size of item without null termination */

#define DOS_NO_DOT_FILE_NAME_LENGTH	(DOS_FILE_NAME_CORE_LENGTH + \
					DOS_FILE_NAME_EXT_LENGTH)
#define DOS_DOT_FILE_NAME_LENGTH	(DOS_NO_DOT_FILE_NAME_LENGTH + 1)
#define VOLUME_NAME_LENGTH	(DOS_FILE_NAME_CORE_LENGTH + DOS_FILE_NAME_EXT_LENGTH)
#define PATH_LENGTH		(DRIVE_NAME_MAX_LENGTH+5*(FILE_LONGNAME_LENGTH+1))

/* Size of strings with null termination */

#define DOS_NO_DOT_FILE_NAME_LENGTH_ZT	(DOS_NO_DOT_FILE_NAME_LENGTH + 1)
#define DOS_DOT_FILE_NAME_LENGTH_ZT	(DOS_DOT_FILE_NAME_LENGTH + 1)
#define VOLUME_NAME_LENGTH_ZT		(VOLUME_NAME_LENGTH + 1)
#define PATH_LENGTH_ZT			(PATH_LENGTH + 1)

/* Size to make buffers (null termination, rounded up to word size) */

#define DOS_NO_DOT_FILE_NAME_SIZE ((DOS_NO_DOT_FILE_NAME_LENGTH_ZT+1) & 0xfffe)
#define DOS_DOT_FILE_NAME_SIZE	((DOS_DOT_FILE_NAME_LENGTH_ZT+1) & 0xfffe)
#define VOLUME_BUFFER_SIZE	((VOLUME_NAME_LENGTH_ZT+1) & 0xfffe)
#define PATH_BUFFER_SIZE	((PATH_LENGTH_ZT+1) & 0xfffe) * sizeof(TCHAR)

/* Common types */

#ifdef DO_DBCS
typedef TCHAR DosNoDotFileName[DOS_NO_DOT_FILE_NAME_SIZE/2];
typedef TCHAR DosDotFileName[DOS_DOT_FILE_NAME_SIZE/2];
typedef TCHAR  FileLongName[FILE_LONGNAME_BUFFER_SIZE/2];
typedef TCHAR  PathName[PATH_BUFFER_SIZE/2];
typedef TCHAR VolumeName[VOLUME_BUFFER_SIZE/2];
#else
typedef char DosNoDotFileName[DOS_NO_DOT_FILE_NAME_SIZE];
typedef char DosDotFileName[DOS_DOT_FILE_NAME_SIZE];
typedef char  FileLongName[FILE_LONGNAME_BUFFER_SIZE];
typedef char  PathName[PATH_BUFFER_SIZE];
typedef char VolumeName[VOLUME_BUFFER_SIZE];
#endif

/* 
 * Keeping these mistyped definitions for backwards compatibility only.
 * Use DOS_NO_DOT_FILE_NAME_LENGTH, DOS_DOT_FILE_NAME_LENGTH,
 * DOS_NO_DOT_FILE_NAME_LENGTH_ZT, DOS_DOT_FILE_NAME_LENGTH_ZT,
 * DOS_NO_DOT_FILE_NAME_SIZE, and DOS_DOT_FILE_NAME_SIZE instead.
 */
#define DOS_NO_DOT_DOS_FILE_NAME_LENGTH	(DOS_FILE_NAME_CORE_LENGTH + \
					DOS_FILE_NAME_EXT_LENGTH)
#define DOS_DOT_DOS_FILE_NAME_LENGTH	(DOS_NO_DOT_DOS_FILE_NAME_LENGTH + 1)

#define DOS_NO_DOT_DOS_FILE_NAME_LENGTH_ZT (DOS_NO_DOT_DOS_FILE_NAME_LENGTH + 1)
#define DOS_DOT_DOS_FILE_NAME_LENGTH_ZT	(DOS_DOT_DOS_FILE_NAME_LENGTH + 1)

#define DOS_NO_DOT_DOS_FILE_NAME_SIZE ((DOS_NO_DOT_DOS_FILE_NAME_LENGTH_ZT+1) & 0xfffe)
#define DOS_DOT_DOS_FILE_NAME_SIZE	((DOS_DOT_DOS_FILE_NAME_LENGTH_ZT+1) & 0xfffe)

#ifdef __HIGHC__
pragma Alias(FileCreateDir, "FILECREATEDIR");
pragma Alias(FileCreateDirWithNativeShortName, "FILECREATEDIRWITHNATIVESHORTNAME");
pragma Alias(FileDeleteDir, "FILEDELETEDIR");
pragma Alias(FilePushDir, "FILEPUSHDIR");
pragma Alias(FilePopDir, "FILEPOPDIR");
pragma Alias(FileGetCurrentPath, "FILEGETCURRENTPATH");
pragma Alias(FileSetCurrentPath, "FILESETCURRENTPATH");
pragma Alias(FileOpen, "FILEOPEN");
pragma Alias(FileCreate, "FILECREATE");
pragma Alias(FileClose, "FILECLOSE");
pragma Alias(FileCommit, "FILECOMMIT");
pragma Alias(FileCreateTempFile, "FILECREATETEMPFILE");
pragma Alias(FileDelete, "FILEDELETE");
pragma Alias(FileRename, "FILERENAME");
pragma Alias(FileRead, "FILEREAD");
pragma Alias(FileWrite, "FILEWRITE");
pragma Alias(FilePos, "FILEPOS");
pragma Alias(FileTruncate, "FILETRUNCATE");
pragma Alias(FileSize, "FILESIZE");
pragma Alias(FileGetDateAndTime, "FILEGETDATEANDTIME");
pragma Alias(FileSetDateAndTime, "FILESETDATEANDTIME");
pragma Alias(FileDuplicateHandle, "FILEDUPLICATEHANDLE");
pragma Alias(FileLockRecord, "FILELOCKRECORD");
pragma Alias(FileUnlockRecord, "FILEUNLOCKRECORD");
pragma Alias(FileGetDiskHandle, "FILEGETDISKHANDLE");
pragma Alias(FileGetAttributes, "FILEGETATTRIBUTES");
pragma Alias(FileSetAttributes, "FILESETATTRIBUTES");
pragma Alias(FileSetStandardPath, "FILESETSTANDARDPATH");
pragma Alias(FileSetRootPath, "FILESETROOTPATH");
pragma Alias(FileCopy, "FILECOPY");
pragma Alias(FileCopyLocal, "FILECOPYLOCAL");
pragma Alias(FileMove, "FILEMOVE");
pragma Alias(FileMoveLocal, "FILEMOVELOCAL");
pragma Alias(FileParseStandardPath, "FILEPARSESTANDARDPATH");
pragma Alias(FileConstructFullPath, "FILECONSTRUCTFULLPATH");
pragma Alias(FileResolveStandardPath, "FILERESOLVESTANDARDPATH");
pragma Alias(FileConstructActualPath, "FILECONSTRUCTACTUALPATH");
pragma Alias(FileGetPathExtAttributes, "FILEGETPATHEXTATTRIBUTES");
pragma Alias(FileGetHandleExtAttributes, "FILEGETHANDLEEXTATTRIBUTES");
pragma Alias(FileGetHandleAllExtAttributes, "FILEGETHANDLEALLEXTATTRIBUTES");
pragma Alias(FileSetPathExtAttributes, "FILESETPATHEXTATTRIBUTES");
pragma Alias(FileSetHandleExtAttributes, "FILESETHANDLEEXTATTRIBUTES");
pragma Alias(FileComparePaths, "FILECOMPAREPATHS");
pragma Alias(FileCreateLink, "FILECREATELINK");
pragma Alias(FileReadLink, "FILEREADLINK");
pragma Alias(FileSetLinkExtraData, "FILESETLINKEXTRADATA");
pragma Alias(FileGetLinkExtraData, "FILEGETLINKEXTRADATA");
pragma Alias(FileCopyPathExtAttributes, "FILECOPYPATHEXTATTRIBUTES");
pragma Alias(FileEnableOpenCloseNotification, "FILEENABLEOPENCLOSENOTIFICATION");
pragma Alias(FileDisableOpenCloseNotification, "FILEDISABLEOPENCLOSENOTIFICATION");
pragma Alias(FileBatchChangeNotifications, "FILEBATCHCHANGENOTIFICATIONS");
pragma Alias(FileFlushChangeNotifications, "FILEFLUSHCHANGENOTIFICATIONS");
pragma Alias(FileGetCurrentPathIDs, "FILEGETCURRENTPATHIDS");
pragma Alias(FileOpenAndRead, "FILEOPENANDREAD");
#endif

#endif
