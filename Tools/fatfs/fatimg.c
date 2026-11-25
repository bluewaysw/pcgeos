/***********************************************************************
 *
 * PROJECT:	  PCGEOS host tools
 * MODULE:	  fatfs -- FAT file system library (FatFs by ChaN)
 * FILE:	  fatimg.c
 *
 * DESCRIPTION:
 *	Implementation of the FatFs media access interface (diskio.h)
 *	on top of host disk image files. See fatimg.h.
 *
 ***********************************************************************/
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "ff.h"
#include "diskio.h"
#include "fatimg.h"

typedef struct {
    FILE    *fp;
    DWORD   first;
    DWORD   count;
    int	    readOnly;
} FatImgDrive;

static FatImgDrive fatImgDrives[FF_VOLUMES];

/***********************************************************************
 *		Raw sector access
 ***********************************************************************/
static int
FatImgSeek(FILE *fp, DWORD sector)
{
    /*
     * Images are limited to well below 2GB (CHS addressable disks),
     * so a long offset is sufficient.
     */
    return fseek(fp, (long)sector * FATIMG_SECTOR_SIZE, SEEK_SET);
}

int
FatImg_ReadSectors(FILE *fp, DWORD sector, void *buf, unsigned count)
{
    size_t  n;

    if (FatImgSeek(fp, sector) != 0) {
	return -1;
    }
    n = fread(buf, FATIMG_SECTOR_SIZE, count, fp);
    if (n != count) {
	/*
	 * Reading past the end of a sparse/short image returns zeroes.
	 */
	memset((char *)buf + n * FATIMG_SECTOR_SIZE, 0,
	       (count - n) * FATIMG_SECTOR_SIZE);
	clearerr(fp);
    }
    return 0;
}

int
FatImg_WriteSectors(FILE *fp, DWORD sector, const void *buf, unsigned count)
{
    if (FatImgSeek(fp, sector) != 0) {
	return -1;
    }
    if (fwrite(buf, FATIMG_SECTOR_SIZE, count, fp) != count) {
	return -1;
    }
    return 0;
}

/***********************************************************************
 *		Attach/detach
 ***********************************************************************/
int
FatImg_Attach(BYTE pdrv, FILE *fp, DWORD firstSector, DWORD numSectors,
	      int readOnly)
{
    if (pdrv >= FF_VOLUMES || fp == NULL || numSectors == 0) {
	return -1;
    }
    fatImgDrives[pdrv].fp = fp;
    fatImgDrives[pdrv].first = firstSector;
    fatImgDrives[pdrv].count = numSectors;
    fatImgDrives[pdrv].readOnly = readOnly;
    return 0;
}

void
FatImg_Detach(BYTE pdrv)
{
    if (pdrv < FF_VOLUMES) {
	memset(&fatImgDrives[pdrv], 0, sizeof(FatImgDrive));
    }
}

/***********************************************************************
 *		FatFs media access interface
 ***********************************************************************/
DSTATUS
disk_status(BYTE pdrv)
{
    if (pdrv >= FF_VOLUMES || fatImgDrives[pdrv].fp == NULL) {
	return STA_NOINIT | STA_NODISK;
    }
    return fatImgDrives[pdrv].readOnly ? STA_PROTECT : 0;
}

DSTATUS
disk_initialize(BYTE pdrv)
{
    return disk_status(pdrv);
}

DRESULT
disk_read(BYTE pdrv, BYTE *buff, LBA_t sector, UINT count)
{
    FatImgDrive	*d;

    if (pdrv >= FF_VOLUMES || fatImgDrives[pdrv].fp == NULL) {
	return RES_NOTRDY;
    }
    d = &fatImgDrives[pdrv];
    if (sector + count > d->count) {
	return RES_PARERR;
    }
    if (FatImg_ReadSectors(d->fp, d->first + (DWORD)sector, buff,
			   count) != 0) {
	return RES_ERROR;
    }
    return RES_OK;
}

DRESULT
disk_write(BYTE pdrv, const BYTE *buff, LBA_t sector, UINT count)
{
    FatImgDrive	*d;

    if (pdrv >= FF_VOLUMES || fatImgDrives[pdrv].fp == NULL) {
	return RES_NOTRDY;
    }
    d = &fatImgDrives[pdrv];
    if (d->readOnly) {
	return RES_WRPRT;
    }
    if (sector + count > d->count) {
	return RES_PARERR;
    }
    if (FatImg_WriteSectors(d->fp, d->first + (DWORD)sector, buff,
			    count) != 0) {
	return RES_ERROR;
    }
    return RES_OK;
}

DRESULT
disk_ioctl(BYTE pdrv, BYTE cmd, void *buff)
{
    FatImgDrive	*d;

    if (pdrv >= FF_VOLUMES || fatImgDrives[pdrv].fp == NULL) {
	return RES_NOTRDY;
    }
    d = &fatImgDrives[pdrv];
    switch (cmd) {
    case CTRL_SYNC:
	if (!d->readOnly && fflush(d->fp) != 0) {
	    return RES_ERROR;
	}
	return RES_OK;
    case GET_SECTOR_COUNT:
	*(LBA_t *)buff = d->count;
	return RES_OK;
    case GET_SECTOR_SIZE:
	*(WORD *)buff = FATIMG_SECTOR_SIZE;
	return RES_OK;
    case GET_BLOCK_SIZE:
	*(DWORD *)buff = 1;
	return RES_OK;
    default:
	return RES_PARERR;
    }
}

/***********************************************************************
 *		get_fattime
 ***********************************************************************
 * Current local time in FAT format, used for files FatFs creates.
 ***********************************************************************/
DWORD
get_fattime(void)
{
    time_t	now = time(NULL);
    struct tm	*tm = localtime(&now);

    if (tm == NULL || tm->tm_year < 80) {
	return ((DWORD)(2026 - 1980) << 25) | ((DWORD)1 << 21) |
	    ((DWORD)1 << 16);
    }
    return ((DWORD)(tm->tm_year - 80) << 25) |
	((DWORD)(tm->tm_mon + 1) << 21) |
	((DWORD)tm->tm_mday << 16) |
	((DWORD)tm->tm_hour << 11) |
	((DWORD)tm->tm_min << 5) |
	((DWORD)tm->tm_sec >> 1);
}
