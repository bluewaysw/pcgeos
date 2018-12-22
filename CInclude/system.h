/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	system.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines system related structures and routines.
 *
 *	$Id: system.h,v 1.1 97/04/04 15:57:10 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__SYSTEM_H
#define __SYSTEM_H

#include <geode.h>	/* ProtocolNumber, ReleaseNumber */

/***/

typedef ByteFlags DosExecFlags;
#define DEF_PROMPT		0x80
#define DEF_FORCED_SHUTDOWN	0x40
#define DEF_INTERACTIVE		0x20

extern word		/* Returns error and sets value for ThreadGetError() */	/*XXX*/
    _cdecl DosExec(const char *prog, DiskHandle progDisk, const char *arguments,
	    const char *execDir, DiskHandle execDisk, DosExecFlags flags);

/***/

extern DiskHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _cdecl SysLocateFileInDosPath(const char *fname, char *buffer);

/***/

extern Boolean		/* true if error (not found) */	/*XXX*/
    _pascal SysGetDosEnvironment(const char *variable, char *buffer, word bufSize);

/***/

typedef WordFlags SysNotifyFlags;
#define SNF_RETRY	0x8000
#define SNF_EXIT	0x4000
#define SNF_ABORT	0x2000
#define SNF_CONTINUE	0x1000
#define SNF_REBOOT	0x0800
#define SNF_BIZARRE	0x0400

extern word	/*XXX*/
    _pascal SysNotify(SysNotifyFlags flags, const char *string1, const char *string2);

/***/

extern void	/*XXX*/
    _pascal SysRegisterScreen(GeodeHandle driver, WindowHandle root);

/***/

typedef enum /* word */ {
    SST_CLEAN,
    SST_CLEAN_FORCED,
    SST_DIRTY,
    SST_PANIC,
    SST_REBOOT,
    SST_RESTART,
    SST_FINAL,
    SST_SUSPEND,
    SST_CONFIRM_START,
    SST_CONFIRM_END,
    SST_CLEAN_REBOOT
} SysShutdownType;

extern Boolean _cdecl	/*XXX*/
    SysShutdown(SysShutdownType type, ...);

/***/

typedef ByteFlags ExitFlags;
#define EF_PANIC	0x80
#define EF_RUN_DOS	0x40
#define EF_OLD_EXIT	0x20
#define EF_RESET	0x10
#define EF_RESTART	0x08

extern word	/*XXX*/
    _pascal SysSetExitFlags(ExitFlags bitsToSet, ExitFlags bitsToClear);

/***/

typedef ByteFlags SysConfigFlags;
#define SCF_UNDER_SWAT		0x80
#define SCF_2ND_IC		0x40
#define SCF_RTC			0x20
#define SCF_COPROC		0x10
#define SCF_RESTARTED		0x80
#define SCF_CRASHED		0x04
#define SCF_MCA			0x02
#define SCF_LOGGING		0x01

/***/

typedef ByteEnum SysProcessorType;
#define SPT_8088   0
#define SPT_8086   0
#define SPT_80186 1
#define SPT_80286 2
#define SPT_80386 3
#define SPT_80486 4

typedef ByteEnum SysMachineType;
#define SMT_UNKNOWN 0
#define SMT_PC 1
#define SMT_PC_CONV 2
#define SMT_PC_JR 3
#define SMT_PC_XT 4
#define SMT_PC_XT_286 5
#define SMT_PC_AT 6
#define SMT_PS2_30 7
#define SMT_PS2_50 8
#define SMT_PS2_60 9
#define SMT_PS2_80 10
#define SMT_PS1 11

#define SGC_PROCESSOR(val) 	((byte) ((val) >> 16))
#define SGC_MACHINE(val) 	((byte) ((val) >> 24))


typedef ByteEnum SysProcessorType;
#define SPT_8088   0
#define SPT_8086   0
#define SPT_80186 1
#define SPT_80286 2
#define SPT_80386 3
#define SPT_80486 4

typedef ByteEnum SysMachineType;
#define SMT_UNKNOWN 0
#define SMT_PC 1
#define SMT_PC_CONV 2
#define SMT_PC_JR 3
#define SMT_PC_XT 4
#define SMT_PC_XT_286 5
#define SMT_PC_AT 6
#define SMT_PS2_30 7
#define SMT_PS2_50 8
#define SMT_PS2_60 9
#define SMT_PS2_80 10
#define SMT_PS1 11
#define SMT_PRODUCT_SPECIFIC_1	12
#define SMT_PRODUCT_SPECIFIC_2	13
#define SMT_PRODUCT_SPECIFIC_3	14
#define SMT_PRODUCT_SPECIFIC_4	15

#define SGC_PROCESSOR(val) 	((byte) ((val) >> 16))
#define SGC_MACHINE(val) 	((byte) ((val) >> 24))

extern dword	/*XXX*/
    _pascal SysGetConfig(void);

extern Boolean
    _pascal SysGetPenMode(void);	

/***/

typedef WordFlags  UtilHexToAsciiFlags;
#define UHTAF_SBCS_STRING   	    	0x0010
#define UHTAF_THOUSANDS_SEPARATORS  	0x0008
#define UHTAF_SIGNED_VALUE  	    	0x0004
#define UHTAF_INCLUDE_LEADING_ZEROS	0x0002
#define UHTAF_NULL_TERMINATE		0x0001

#define UHTA_NO_NULL_TERM_BUFFER_SIZE   10

/* Non DBCS buffer sizes must be word aligned */
#if !DBCS_GEOS
#define UHTA_NULL_TERM_BUFFER_SIZE      11 + 1
#define UHTA_SPACE_FOR_SIGN             1  + 1
#define UHTA_SPACE_FOR_SEPARATORS       3  + 1
#define UHTA_ALL_BUFFER_SIZE            10 + 1 +1 + 3 + 1
#else
#define UHTA_NULL_TERM_BUFFER_SIZE      11
#define UHTA_SPACE_FOR_SIGN             1
#define UHTA_SPACE_FOR_SEPARATORS       3 
#define UHTA_ALL_BUFFER_SIZE            10 + 1 +1 + 3

#endif

typedef enum /* word */ {
    UATH_NON_NUMERIC_DIGIT_IN_STRING,
    UATH_CONVERT_OVERFLOW,
} UtilAsciiToHexError;

extern word 	/* Returns the length of the string (w/o NULL) */
    _pascal UtilHex32ToAscii(TCHAR *buffer, dword value, UtilHexToAsciiFlags flags);

extern Boolean	/*XXX*/
    _pascal UtilAsciiToHex32(const TCHAR *string, sdword *value);

/***/

extern void
    _pascal SysLockBIOS(void);

extern void
    _pascal SysUnlockBIOS(void);

/***/
typedef WordFlags   SysNotificationType;
#define SNF_WORD1_MEM	    0x8000  /* set if first param word is MemHandle */
#define	SNF_WORD2_MEM	    0x4000  /* set if second param word is MemHandle */
#define SNF_WORD3_MEM	    0x2000  /* set if third param word is MemHandle */
#define SNF_WORD4_MEM	    0x1000  /* set if fourth param word is MemHandle */
#define SNF_NOTIFICATION    0x0fff  /* field for notification number (specific
				     * to subsystem being notified) */

typedef enum {	    /* Steps by 9... */
    SST_MAILBOX = 0,
    SST_MEDIUM 	= 9,
    SST_DEVICE_POWER = 18,
    SST_INDICATOR = 27,
    SST_IRDA = 36,
    SST_SOCKET = 45
}	SysSubsystemType;

extern void
    _pascal SysSendNotification(SysSubsystemType subsys,
				SysNotificationType notif,
				word	word1,
				word	word2,
				word	word3,
				word	word4);

extern Boolean
    _pascal SysHookNotification(SysSubsystemType subsys,
				PCB(void, routine,
				    (SysSubsystemType subsys,
				     SysNotificationType notif,
				     word word1,
				     word word2,
				     word word3,
				     word word4)));

extern void
    _pascal SysUnhookNotification(SysSubsystemType subsys,
				  PCB(void, routine,
				      (SysSubsystemType subsys,
				       SysNotificationType notif,
				       word word1,
				       word word2,
				       word word3,
				       word word4)));

extern Boolean
    _pascal SysIgnoreNotification(SysSubsystemType subsys);

extern void
    _pascal SysEnableAPO(void);

extern void
    _pascal SysDisableAPO(void);

extern word
    _pascal SysGetInkWidthAndHeight(void);

extern void
    _pascal SysSetInkWidthAndHeight(word WidthAndHeight);



#define	UTIL_WINDOW_MAX_NUM_WINDOWS	4

typedef struct {
    Segment	WI_addr;	/* window segment (NULL if not supported) */
    word	WI_paraSize;	/* window size in paragraphs */
} UtilWinInfo;

typedef struct {
    dword	UWPMI_addr;	/* physical memory address */
    word	UWPMI_paraSize;	/* physical memory size in paragraphs */
} UtilWinPhyMemInfo;

typedef struct {
    word	UWPMIB_count;
#ifdef __HIGHC__
    char	UWPMIB_info[0];
#else
#ifdef __WATCOM__
    char	UWPMIB_info[];
#else
    void	UWPMIB_info;
#endif /* __WATCOM__ */
#endif
} UtilWinPhyMemInfoBlk;

/*
 * Returns address and size of direct mapping window, if present.
 *
 * Pass:    pointer to UtilWinInfo array to be returned
 *	    permanent name of geode
 *	    pointer to MemHandle to UtilWinPhyMemInfoBlk to be returned
 * Return:  TRUE if mapping window supported
 *	    UtilWinInfo array filled in
 *	    MemHandle filled in with MemHandle to UtilWinPhyMemInfoBlk
 */
extern Boolean
    _pascal SysGetUtilWindowInfo(
	UtilWinInfo info[UTIL_WINDOW_MAX_NUM_WINDOWS],
	char permName[GEODE_NAME_SIZE],
	MemHandle *phyMemInfoBlk);

/*
 * Maps physical memory to mapping window.
 *
 * Pass:    physical address to map in (starts at 100000h)
 *	    pointer to fptr to mapped data to be returned
 *	    window number to use
 * Return:  number of paragraphs mapping in (i.e. size of window - offset into
 *	    	    	    	    	window where passed physical address
 *	    	    	    	    	begins)
 *	    fptr filled in with fptr to beginning of physical data in
 *	    	    map window
 */
extern word
    _pascal SysMapUtilWindow(void *physicalAddress, void **windowAddress,
			     word windowNumber);

/*
 * Releases mapping of physical memory from mapping window.  Restores
 * previously mapping physical memory, if any.
 *
 * Pass:    nothing
 * Return:  zero on sucesss
 *	    non-zero on error (could restore previous mapping)
 */
extern word
    _pascal SysUnmapUtilWindow();

#ifdef __HIGHC__
pragma Alias(DosExec, "_DosExec");
pragma Alias(SysLocateFileInDosPath, "SYSLOCATEFILEINDOSPATH");
pragma Alias(SysGetDosEnvironment, "SYSGETDOSENVIRONMENT");
pragma Alias(SysNotify, "SYSNOTIFY");
pragma Alias(SysRegisterScreen, "SYSREGISTERSCREEN");
pragma Alias(SysShutdown, "_SysShutdown");
pragma Alias(SysSetExitFlags, "SYSSETEXITFLAGS");
pragma Alias(SysGetPenMode, "SYSGETPENMODE");
pragma Alias(SysGetConfig, "SYSGETCONFIG");
pragma Alias(UtilHex32ToAscii, "UTILHEX32TOASCII");
pragma Alias(UtilAsciiToHex32, "UTILASCIITOHEX32");
pragma Alias(SysLockBIOS, "SYSLOCKBIOS");
pragma Alias(SysUnlockBIOS, "SYSUNLOCKBIOS");
pragma Alias(SysSendNotification, "SYSSENDNOTIFICATION");
pragma Alias(SysHookNotification, "SYSHOOKNOTIFICATION");
pragma Alias(SysUnhookNotification, "SYSUNHOOKNOTIFICATION");
pragma Alias(SysIgnoreNotification, "SYSIGNORENOTIFICATION");
pragma Alias(SysEnableAPO, "SYSENABLEAPO");
pragma Alias(SysDisableAPO, "SYSDISABLEAPO");
pragma Alias(SysGetInkWidthAndHeight, "SYSGETINKWIDTHANDHEIGHT");
pragma Alias(SysSetInkWidthAndHeight, "SYSSETINKWIDTHANDHEIGHT");
pragma Alias(SysGetUtilWindowInfo, "SYSGETUTILWINDOWINFO");
pragma Alias(SysMapUtilWindow, "SYSMAPUTILWINDOW");
pragma Alias(SysUnmapUtilWindow, "SYSUNMAPUTILWINDOW");
#endif

#endif
