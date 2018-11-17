/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	disk.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines disk structures and routines.
 *
 *	$Id: disk.h,v 1.1 97/04/04 15:58:15 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__DISK_H
#define __DISK_H

#include <file.h>	/* VolumeName */
#include <drive.h>	/* DriveType, MediaType */

#define DISK_IS_STD_PATH_MASK	1

/***/

typedef struct {
    word		DIS_blockSize;
    sdword		DIS_freeSpace;
    sdword		DIS_totalSpace;
    VolumeName	    	DIS_name;
} DiskInfoStruct;

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskGetVolumeInfo(DiskHandle dh, DiskInfoStruct *info);

/***/

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskSetVolumeName(DiskHandle dh, const char *name);

/***/

extern dword				/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskGetVolumeFreeSpace(DiskHandle dh);

/***/

typedef enum /* word */ {
    CALLBACK_GET_SOURCE_DISK,
    CALLBACK_REPORT_NUM_SWAPS,
    CALLBACK_GET_DEST_DISK,
    CALLBACK_VERIFY_DEST_DESTRUCTION,
    CALLBACK_REPORT_FORMAT_PCT,
    CALLBACK_REPORT_COPY_PCT
} DiskCopyCallback;

typedef enum /* word */ {
    ERR_DISKCOPY_INSUFFICIENT_MEM=0xd0,
    ERR_CANT_COPY_FIXED_DISKS,
    ERR_CANT_READ_FROM_SOURCE,
    ERR_CANT_WRITE_TO_DEST,
    ERR_INCOMPATIBLE_FORMATS,
    ERR_OPERATION_CANCELLED,
    ERR_CANT_FORMAT_DEST,
} DiskCopyError;

extern DiskCopyError	/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskCopy(word source, word dest,
		    PCB(Boolean, callback, (DiskCopyCallback code,
					 DiskHandle disk,
					 word param)));

/***/
typedef WordFlags DiskFormatFlags;
#define DFF_CALLBACK_PCT_DONE	0x0004
#define DFF_CALLBACK_CYL_HEAD	0x0002
#define DFF_FORCE_ERASE	    	0x0001

typedef enum {
    FMT_DONE,
    FMT_READY,
    FMT_RUNNING,
    FMT_DRIVE_NOT_READY,
    FMT_ERR_WRITING_BOOT,
    FMT_ERR_WRITING_ROOT_DIR,
    FMT_ERR_WRITING_FAT,
    FMT_ABORTED,
    FMT_SET_VOLUME_NAME_ERR,
    FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE,
    FMT_BAD_PARTITION_TABLE,
    FMT_ERR_READING_PARTITION_TABLE,
    FMT_ERR_NO_PARTITION_FOUND,
    FMT_ERR_MULTIPLE_PRIMARY_PARTITIONS,
    FMT_ERR_NO_EXTENDED_PARTITION_FOUND,
    FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER,
    FMT_ERR_DISK_IS_IN_USE,
    FMT_ERR_WRITE_PROTECTED,
    FMT_ERR_DRIVE_CANNOT_SUPPORT_GIVEN_FORMAT,
    FMT_ERR_INVALID_DRIVE_SPECIFIED,
    FMT_ERR_DRIVE_CANNOT_BE_FORMATTED,
    FMT_ERR_DISK_UNAVAILABLE
} FormatError;
extern FormatError	/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskFormat(word driveNumber,
		MediaType media,
		DiskFormatFlags flags,
		dword *goodClusters,
		dword *badClusters,
		DiskHandle disk,
		char *volumeName,
		PCB(Boolean, callback, (word percentDone)) /* true = cancel */);

/***/

extern DiskHandle	/*XXX*/
    _pascal DiskRegisterDisk(word driveNumber);

/***/

extern DiskHandle	/*XXX*/
    _pascal DiskRegisterDiskSilently(word driveNumber);

/***/

extern DiskHandle	/*XXX*/
    _pascal DiskForEach(PCB(Boolean, callback, (DiskHandle disk)) /* true = cancel */);

/***/

extern word	/*XXX*/
    _pascal DiskGetDrive(DiskHandle disk);

/***/

extern void	/*XXX*/
    _pascal DiskGetVolumeName(DiskHandle disk, char *buffer);

/***/


typedef enum /* word */ {
    DFR_UNIQUE,
    DFR_NOT_UNIQUE,
    DFR_NOT_FOUND,
} DiskFindResult;


extern DiskHandle	/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal DiskFind(const char *fname, DiskFindResult *code);

/***/

extern Boolean	/*XXX*/
    _pascal DiskCheckWritable(DiskHandle disk);

/***/

extern Boolean	/*XXX*/
    _pascal DiskCheckInUse(DiskHandle disk);

/***/

extern Boolean	/*XXX*/
    _pascal DiskCheckUnnamed(DiskHandle disk);

/***/

extern Boolean _pascal DiskSave(DiskHandle disk, void *buffer, word *bufSizePtr);

/***/

typedef enum /* word */ {
    DRE_DISK_IN_DRIVE,
    DRE_DRIVE_NO_LONGER_EXISTS,
    DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK,
    DRE_USER_CANCELED_RESTORE,
    DRE_COULDNT_CREATE_NEW_DISK_HANDLE,
    DRE_REMOVABLE_DRIVE_IS_BUSY,
    DRE_NOT_ATTACHED_TO_SERVER,
    DRE_PERMISSION_DENIED,
    DRE_ALL_DRIVES_USED
} DiskRestoreError;

extern DiskHandle _pascal DiskRestore(void  *buffer,
			      PCB(DiskRestoreError,
			      	callback, (const char *driveName,
					    const char *diskName,
					    void **bufferPtr,
					    DiskRestoreError errorPtr)));

#ifdef __HIGHC__
pragma Alias(DiskGetVolumeInfo, "DISKGETVOLUMEINFO");
pragma Alias(DiskSetVolumeName, "DISKSETVOLUMENAME");
pragma Alias(DiskGetVolumeFreeSpace, "DISKGETVOLUMEFREESPACE");
pragma Alias(DiskCopy, "DISKCOPY");
pragma Alias(DiskFormat, "DISKFORMAT");
pragma Alias(DiskRegisterDisk, "DISKREGISTERDISK");
pragma Alias(DiskRegisterDiskSilently, "DISKREGISTERDISKSILENTLY");
pragma Alias(DiskForEach, "DISKFOREACH");
pragma Alias(DiskGetDrive, "DISKGETDRIVE");
pragma Alias(DiskGetVolumeName, "DISKGETVOLUMENAME");
pragma Alias(DiskFind, "DISKFIND");
pragma Alias(DiskCheckWritable, "DISKCHECKWRITABLE");
pragma Alias(DiskCheckInUse, "DISKCHECKINUSE");
pragma Alias(DiskCheckUnnamed, "DISKCHECKUNNAMED");
pragma Alias(DiskSave, "DISKSAVE");
pragma Alias(DiskRestore, "DISKRESTORE");
#endif

#endif
