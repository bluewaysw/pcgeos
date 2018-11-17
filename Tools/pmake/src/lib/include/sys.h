/*
 * sys.h --
 *
 *     User-level definitions of routines and types for the sys module.
 *
 * Copyright 1986 Regents of the University of California
 * All rights reserved.
 *
 * $Id: sys.h,v 1.1 96/06/24 14:57:34 tbradley Exp $ SPRITE (Berkeley)
 *
 */

#ifndef _SYSUSER
#define _SYSUSER

typedef enum {
    SYS_WARNING, 
    SYS_FATAL
} Sys_PanicLevel;

/*
 * Flags for Sys_Shutdown.
 *
 *    SYS_REBOOT         Reboot the system. 
 *    SYS_HALT           Halt the system.
 *    SYS_KILL_PROCESSES Kill all processes.
 *    SYS_DEBUG		 Enter the debugger.
 *    SYS_WRITE_BACK	 Write back the cache after killing all processes but
 *			 obviously before halting or rebooting.
 */

#define SYS_REBOOT              0x01
#define SYS_HALT                0x02
#define	SYS_KILL_PROCESSES	0x04
#define	SYS_DEBUG		0x08
#define	SYS_WRITE_BACK		0x10

/*
 * Machine architecture and type values from Sys_GetMachineInfo().
 */

#define SYS_SPUR		1
#define SYS_SUN2		2
#define SYS_SUN3		3
#define SYS_SUN4		4
#define SYS_MICROVAX_2		5

#define SYS_SUN_2_50		0x02
#define SYS_SUN_2_120		0x01
#define SYS_SUN_2_160		0x02
#define SYS_SUN_3_75		0x11
#define SYS_SUN_3_160		0x11
#define SYS_SUN_3_50		0x12

extern ReturnStatus		Sys_GetMachineInfo();
extern void			Sys_Panic(Sys_PanicLevel, char *, ...);

#endif _SYSUSER
