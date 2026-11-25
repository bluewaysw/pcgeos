/***********************************************************************
 *
 * PROJECT:	  PCGEOS host tools
 * MODULE:	  fatfs -- FAT file system library (FatFs by ChaN)
 * FILE:	  fatimg.h
 *
 * DESCRIPTION:
 *	Glue between FatFs and disk image files on the host. Every
 *	FatFs physical drive (0 .. FF_VOLUMES-1) can be attached to a
 *	region of a host file. The region is given in 512-byte sectors,
 *	so a single partition inside a hard disk image can be presented
 *	to FatFs as a whole "drive".
 *
 ***********************************************************************/
#ifndef _FATIMG_H_
#define _FATIMG_H_

#include <stdio.h>
#include "ff.h"

#define FATIMG_SECTOR_SIZE	512

/*
 * Attach a region of an already opened image file to a FatFs physical
 * drive.
 *	pdrv		FatFs physical drive number
 *	fp		image file (opened "rb" or "r+b")
 *	firstSector	first sector of the region in the file
 *	numSectors	size of the region in sectors
 *	readOnly	non-zero to reject writes
 * Returns 0 on success, -1 on error.
 */
extern int  FatImg_Attach(BYTE pdrv, FILE *fp, DWORD firstSector,
			  DWORD numSectors, int readOnly);

/*
 * Detach a drive again. The file itself is not closed.
 */
extern void FatImg_Detach(BYTE pdrv);

/*
 * Raw sector access to a host file (not limited to attached regions),
 * used for MBR and boot sector handling. Return 0 on success.
 */
extern int  FatImg_ReadSectors(FILE *fp, DWORD sector, void *buf,
			       unsigned count);
extern int  FatImg_WriteSectors(FILE *fp, DWORD sector, const void *buf,
				unsigned count);

#endif /* _FATIMG_H_ */
