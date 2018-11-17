/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	sysstats.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines system statistics structures and routines.
 *
 *	$Id: sysstats.h,v 1.1 97/04/04 15:58:38 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__SYSSTATS_H
#define __SYSSTATS_H

typedef struct {
    word	SSI_paragraphs;
    word	SSI_blocks;
} SysSwapInfo;

typedef struct {
    dword	SS_idleCount;
    SysSwapInfo	SS_swapOuts;
    SysSwapInfo	SS_swapIns;
    word	SS_contextSwitches;
    word	SS_interrupts;
    word	SS_runQueue;
} SysStats;

extern void	/*XXX*/
    _pascal SysStatistics(SysStats *stats);

/***/


typedef enum /* word */ {
    SGIT_TOTAL_HANDLES=0,
    SGIT_HEAP_SIZE=2,
    SGIT_LARGEST_FREE_BLOCK=4,
    SGIT_TOTAL_COUNT=6,
    SGIT_NUMBER_OF_VOLUMES=8,
    SGIT_TOTAL_GEODES=10,
    SGIT_NUMBER_OF_PROCESSES=12,
    SGIT_NUMBER_OF_LIBRARIES=14,
    SGIT_NUMBER_OF_DRIVERS=16,
    SGIT_CPU_SPEED=18,
    SGIT_SYSTEM_DISK=20,
    SGIT_UI_PROCESS=22,
    SGIT_HANDLE_TABLE_START=0x8000,
    SGIT_HANDLE_TABLE_SEGMENT=0x8002,
    SGIT_LAST_HANDLE=0x8004,
    SGIT_BIOS_LOCK=0x8006,
    SGIT_INITIAL_TEXT_MODE=0x8008,
    SGIT_DEFAULT_SIMPLE_GRAPHICS_MODE=0x800A,
    SGIT_CURRENT_SIMPLE_GRAPHICS_MODE=0x800C,
    SGIT_NUMBER_OF_FREE_HANDLES=0x800E,
    SGIT_ERROR=0x8010, /*Return the kernel's errorFlag variable (-1 means no errors)*/
    SGIT_LAST_DISK_ACCESS=0x8012,
    SGIT_LOADER_VARS_ADDRESS=0x8014,
    SGIT_KCODE_SEGMENT=0x8016,
} SysGetInfoType;

extern dword	/*XXX*/
    _pascal SysGetInfo(SysGetInfoType info);


#ifdef __HIGHC__
pragma Alias(SysStatistics, "SYSSTATISTICS");
pragma Alias(SysGetInfo, "SYSGETINFO");
#endif

#endif
