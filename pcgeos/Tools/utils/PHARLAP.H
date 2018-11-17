/* PHARLAP.H - Definitions for Phar Lap's 386|DOS-Extender */
/* $Id: PHARLAP.H,v 3.1 1996/08/07 05:00:45 ron Exp $ */

/************************************************************************/
/*	Copyright (C) 1986-1991 Phar Lap Software, Inc.			*/
/*	Unpublished - rights reserved under the Copyright Laws of the	*/
/*	United States.  Use, duplication, or disclosure by the 		*/
/*	Government is subject to restrictions as set forth in 		*/
/*	subparagraph (c)(1)(ii) of the Rights in Technical Data and 	*/
/*	Computer Software clause at 252.227-7013.			*/
/*	Phar Lap Software, Inc., 60 Aberdeen Ave., Cambridge, MA 02138	*/
/************************************************************************/

/*	

	FILE DESCRIPTION

This include file contains definitions used by application programs 
that run under Phar Lap's 386|DOS-Extender.  The file defines the
application program interface (API) to 386|DOS-Extender.  The following
definitions are present in the file:

	* Fixed selector numbers
	* Program segment prefix (PSP)
	* Interrupt numbers
	* System call numbers
	* Error numbers
	* Data structures used by system calls

*/

#ifndef PLTYPES
#include <pltypes.h>
#endif


/*

Fixed GDT Segment selectors used by 386|DOS-Extender

The following selectors in the GDT are available to 
applications to directly access the LDT, GDT, and IDT
when running under 386|DOS-Extender.

THESE SEGMENTS MUST NOT BE USED IF THE PROGRAM RUNS AT PRIVILEGE LEVEL
3 AND/OR DPMI COMPATIBILITY IS DESIRED

*/

#define	SS_LDT		0x0028		/* LDT system segment */
#define SS_DLDT		0x0030		/* data segment mapping LDT */
#define SS_DGDT		0x0038		/* data segment mapping GDT */
#define SS_DIDT 	0x0050		/* data segment mapping IDT */


/*

Fixed LDT Segment selectors used by 386|DOS-Extender

The following selectors in the LDT are available to be 
used by an applications to access the various pieces of
a program when running under 386|DOS-Extender. 

*/

#define SS_CODE  	0x000C		/* User code */
#define SS_DATA  	0x0014		/* User data */
#define SS_SCREEN 	0x001C		/* Screen memory */
#define SS_PSP   	0x0024		/* PSP */
#define SS_ENV		0x002C		/* DOS environment */
#define SS_DOSMEM 	0x0034		/* low 1 megabyte of memory (RO) */
#define SS_1167 	0x003C		/* Weitek 1167,3167,4167 coprocessor */
#define SS_WEITEK 	0x003C		/* Weitek 1167,3167,4167 coprocessor */
#define SS_GRAPHICS	0x0044		/* Screen graphics memory */
#define SS_CYRIX	0x004C		/* Cyrix EMC387 coprocessor, added */
					/*in version 3.0 of 386|DOS-Extender*/


/*
 
The max. length of a DOS file name string 

*/

#define MAX_FNLEN	128


/*

Program segment prefix (PSP)
 
*/

typedef struct
{
	USHORT	i20;		/* INT 20h instruction */
	USHORT	end_alloc;	/* para addr of end of allocation block */
	UCHAR	pad1;		/* unused byte */
	UCHAR	fcall;		/* -RESERVED- */
	USHORT	cpmoffs;	/* -RESERVED- */
	USHORT	cpmseg;		/* -RESERVED- */
	USHORT	term_ip;	/* -RESERVED- */
	USHORT	term_cs;	/* -RESERVED- */
	USHORT	cc_ip;		/* -RESERVED- */
	USHORT	cc_cs;		/* -RESERVED- */
	USHORT	ce_ip;		/* -RESERVED- */
	USHORT	ce_cs;		/* -RESERVED- */
	USHORT	parseg;		/* segment address of parent */
	UCHAR	oftab[20];	/* open file table */
	USHORT	env_addr;	/* para addr of environment block */
	USHORT	sp_sav;		/* -RESERVED- */
	USHORT	ss_sav;		/* -RESERVED- */
	USHORT	maxfil;		/* max. number of open files */
	USHORT	oftoffs;	/* offset of open file table */
	USHORT	oftseg;		/* segment addr of open file table */
	USHORT	npspoffs;	/* next PSP offset */
	USHORT	npspseg;	/* next PSP segment */
	UCHAR	pad2[20];	/* unused bytes, always 0 */
	USHORT	i21;		/* INT 21h opcode */
	UCHAR	fret;		/* far return opcode */
	UCHAR	pad3[9];	/* unused bytes, always 0 */
	ULONG	data_size;	/* # data bytes read from .EXE file */
	ULONG	dseg_size;	/* size, in bytes, of data segment */
	ULONG	edat_size;	/* # extra data bytes alloc'd (size-amt) */
	UCHAR	pad4[24];	/* unused bytes, always 0 */
	UCHAR	ct_len;		/* length of command tail string */
	UCHAR	ctail[127];	/* buffer for command tail */
} MS_PSP;


/*

DOS interrupt numbers

*/

#define INT_TERM	0x20	/* Terminate */
#define INT_DOS		0x21	/* DOS system call */
#define INT_TADDR	0x22	/* Terminate address */
#define INT_CTRLC	0x23	/* Control/C handler */
#define INT_CRERR	0x24	/* Critical error handler */
#define INT_DREAD	0x25	/* Disk read */
#define INT_DWRITE	0x26	/* Disk write */
#define INT_TSR		0x27	/* Terminate-and-stay resident */
#define INT_PSC		0x2F	/* Print spool control */


/* 

System call numbers 

*/

#define _DOS_CHAR_INE	0x01	/* Character input with echo */
#define _DOS_CHAR_OUT	0x02	/* Character output */
#define _DOS_AUX_IN	0x03	/* Auxiliary input */
#define _DOS_AUX_OUT	0x04	/* Auxiliary output */
#define _DOS_PRT_OUT	0x05	/* Printer output */
#define _DOS_CHAR_IO	0x06	/* Direct console I/O */
#define _DOS_CHAR_INR	0x07	/* Character input (raw) */
#define _DOS_CHAR_INNE	0x08	/* Character input (no echo) */
#define _DOS_STR_OUT	0x09	/* Character string output */
#define _DOS_BUFF_IN	0x0A	/* Buffered input */
#define _DOS_IN_STATS	0x0B	/* Input status */
#define _DOS_RESET_IN	0x0C	/* Reset, then input */
#define _DOS_DISK_RES	0x0D	/* Disk reset */
#define _DOS_DEFD_SET	0x0E	/* Set default disk */
#define _DOS_DEFD_GET	0x19	/* Get default disk */
#define _DOS_DTA_SET	0x1A	/* Set disk transfer address */
#define _DOS_DALLOC_GET	0x1B	/* Get allocation info for default drive */
#define _DOS_SALLOC_GET	0x1C	/* Get allocation info for specific drive */
#define _DOS_DATE_GET	0x2A	/* Get date */
#define _DOS_DATE_SET	0x2B	/* Set date */
#define _DOS_TIME_GET	0x2C	/* Get time */
#define _DOS_TIME_SET	0x2D	/* Set time */
#define _DOS_VERF_SET	0x2E	/* Set verify flag */
#define _DOS_DTA_GET	0x2F	/* Get disk transfer address */
#define _DOS_VERNO_GET	0x30	/* Get DOS and 386|DOS-Extender version #'s */
#define _DOS_TSR	0x31	/* Terminate a stay resident */
#define _DOS_GDBLK	0x32	/* Get disk block */
#define _DOS_BRK_FLAG	0x33	/* Get or set control/break flag */
#define _DOS_FSPACE_GET	0x36	/* Get disk free space */
#define _DOS_CNTRY	0x38	/* Get or set country information */
#define _DOS_MKDIR	0x39	/* Create a subdirectory */
#define _DOS_RMDIR	0x3A	/* Remove a subdirectory */
#define _DOS_CHDIR	0x3B	/* Change current directory */
#define _DOS_CREATE	0x3C	/* Create a file */
#define _DOS_OPEN	0x3D	/* Open a file */
#define _DOS_CLOSE	0x3E	/* Close a file */
#define _DOS_READ	0x3F	/* Read from a file */
#define _DOS_WRITE	0x40	/* Write to a file */
#define _DOS_DELETE	0x41	/* Delete a file */
#define _DOS_SEEK	0x42	/* Seek in a file */
#define _DOS_FATTR	0x43	/* Get or set file attributes */
#define _DOS_IOCTL	0x44	/* Device I/O control */
#define _DOS_DUP	0x45	/* Duplicate a handle */
#define _DOS_DUP2	0x46	/* Duplicate a handle */
#define _DOS_CURDIR	0x47	/* Get current directory name */
#define _DOS_SEG_ALLOC	0x48	/* Allocate a segment */
#define _DOS_SEG_FREE	0x49	/* Free a segment */
#define _DOS_SEG_RESIZE	0x4A	/* Modify segment size */
#define _DOS_EXEC	0x4B	/* Execute a program */
#define _DOS_TERM	0x4C	/* Exit with a return code */
#define _DOS_RC_GET	0x4D	/* Get child return code */
#define _DOS_FIND_FIRST	0x4E	/* Find first */
#define _DOS_FIND_NEXT	0x4F	/* Find next */
#define _DOS_PSP_SET	0x50	/* Set PSP */
#define _DOS_VERF_GET	0x51	/* Get verify flag */
#define _DOS_RENAME	0x56	/* Rename a file */
#define _DOS_FDATE	0x57	/* Get or set file date */
#define _DOS_MEM_STRAT	0x58	/* Get or set conventional memory allocation
				   strategy */
#define _DOS_XERR_GET	0x59	/* Get extended error information */
#define _DOS_TEMPF_CRT	0x5A	/* Create a temporary file */
#define _DOS_CCREATE	0x5B	/* Create file if it does not exist */
#define _DOS_FILE_LOCK	0x5C	/* Lock a file */
#define _DOS_PSP_GET	0x62	/* Get PSP */


/*

386|DOS-Extender system call numbers

*/

#define _DX_RESET_DATA	0x2501	/* Reset DOS-Extender data structures */
#define _DX_PMIV_GET	0x2502	/* Get protected mode interrupt */
#define _DX_RMIV_GET	0x2503	/* Get real mode interrupt */
#define _DX_PMIV_SET	0x2504	/* Set protected mode interrupt */
#define _DX_RMIV_SET	0x2505	/* Set real mode interrupt */
#define _DX_APMIV_SET	0x2506	/* Set both interrupts to get control
				   in protected mode */
#define _DX_RPMIV_SET	0x2507	/* Get both interrupts separately */
#define _DX_TOLINEAR	0x2508	/* Get linear base address */
#define _DX_TOPHYS	0x2509	/* Convert a linear address to physical */
#define _DX_MAP_PHYS	0x250A	/* Map physical memory to the end of a
				   segment */
#define _DX_HWIV_GET	0x250C	/* Get hardware interrupt vector base */
#define _DX_RMLINK_GET	0x250D	/* Get real mode link information */
#define _DX_REAL_CALL	0x250E	/* Call a real mode procedure */
#define _DX_TOREAL	0x250F	/* Convert protected mode address to
				   real mode address */
#define _DX_REAL_REGCALL 0x2510	/* Call a real mode procedure with
				   register arguments */
#define _DX_REAL_INT	0x2511	/* Issue a real mode interrupt with
				   register arguments */
#define _DX_DBG_LOAD	0x2512	/* Load a program for debugging */
#define _DX_SEG_ALIAS	0x2513	/* Alias a segment */
#define _DX_SEGATTR_SET	0x2514	/* Set segment attributes */
#define _DX_SEGATTR_GET	0x2515	/* Get segment attributes */
#define _DX_LDTMEM_FREE	0x2516	/* Free all memory owned by LDT */
#define _DX_DBUFF_GET	0x2517	/* Get info on DOS data buffer */
#define _DX_SEGMOV_HAND	0x2518	/* Specify handler for moved segments */
#define _DX_MEMERR_GET	0x2519	/* Get additional memory error info */
#define _DX_LOCK_PAGE	0x251A	/* Lock pages in memory */
#define _DX_UNLOCK_PAGE	0x251B	/* Unlock pages in memory */
#define _DX_PAGE_FREE	0x251C	/* Free physical memory pages */
#define _DX_PTE_READ	0x251D	/* Read page table entry */
#define _DX_PTE_WRITE	0x251E	/* Write page table entry */
#define _DX_PTE_XCHG	0x251F	/* Exchange page table entries */
#define _DX_VM_STATS	0x2520	/* Get memory statistics */
#define _DX_XMEM_LIMIT	0x2521	/* Limit program's extended memory usage */
#define _DX_PGFLT_HAND	0x2522	/* Specify alternate page fault handler */
#define _DX_OSWSP_HAND	0x2523	/* Specify out-of-swap-space handler */
#define _DX_PGREPL_HAND	0x2524	/* Specify page replacement handlers */
#define _DX_CMEM_LIMIT	0x2525	/* Limit program's conventional memory usage */
#define _DX_CONFIG_INF	0x2526	/* Get Configuration Information */
#define _DX_DBG_FLAGS	0x2527	/* Set debug flags */
#define _DX_CC_RDREGS	0x2528	/* Read registers after Ctrl/C interrupt*/
#define _DX_LOAD_EXP	0x2529	/* Load Flat Model EXP file **/
#define _DX_DBG_NEWLD	0x252A	/* New load pgm for debug (more error info */
				/* than _DX_DBG_LOAD call) */
#define _DX_MEM_MGT	0x252B	/* Memory region page management */
#define _DX_ADD_UNMAP	0x252C	/* Add unmapped pages at end of segment */
#define _DX_CLOSE_VMH	0x252D	/* Close VMM file handle */
#define _DX_VMM_PARAMS	0x252E	/* Get/Set VMM parameters */
#define _DX_WR_PAGELOG	0x252F	/* Write record to VMM page log file */
#define _DX_SET_DOSBUF	0x2530	/* Set size of data buffer used for DOS calls*/
#define _DX_RW_LDTDESC	0x2531	/* Read/Write LDT descriptor */
#define _DX_PMEXC_GET	0x2532	/* Get prot mode processor exception vector */
#define _DX_PMEXC_SET	0x2533	/* Set prot mode processor exception vector */
#define _DX_IF_GET	0x2534	/* Get interrupt flag */
#define _DX_SR_RW	0x2535	/* Read/Write System Registers */
#define _DX_MEM_USAGE	0x2536	/* Min/Max Ext/Conv Memory Usage */
#define _DX_REAL_ADDB	0x2537	/* Allocate DOS memory above DOS Data Buffer */
#define _DX_SWI_RDREGS 0x2538  /* Read PM regs after a SW interrupt */
#define _DX_GET_HDROFF 0x2539	/* Get Offset of EXP file header */
#define _DX_MSEG_FAILH 0x253A	/* Install Mod. Segment Failure Handler */
#define _DX_TOREAL_JMP 0x253B  /* Jump to real mode code, no context saved */
#define _DX_SHRINK_SWAP	0x253C	/* shrink size of 386|VMM swap file */
#define _DX_RW_IDTDESC	0x253D	/* Read/Write IDT descriptor */
#define _DX_REAL_ALLOC	0x25C0	/* Allocate real mode memory */
#define _DX_REAL_FREE	0x25C1	/* Release real mode memory */
#define _DX_REAL_RESIZE	0x25C2	/* Change size of a real mode memory
				   block */
#define _DX_EXEC_SPEC	0x25C3	/* Special program execute call */


/*

I/O Control subfunction numbers

*/

#define _IOC_GDINFO	0	/* Get device information */
#define _IOC_SDINFO	1	/* Get device information */
#define _IOC_RCDCC	2	/* Read from char. device control channel */
#define _IOC_WCDCC	3	/* Write from char. device control channel */
#define _IOC_RBDCC	4	/* Read from block device control channel */
#define _IOC_WBDCC	5	/* Write from block device control channel */
#define _IOC_INST	6	/* Get input status */
#define _IOC_OUTST	7	/* Get output status */
#define _IOC_TCHG	8	/* Test if device is changeable */
#define _IOC_TDLOC	9	/* Test location of device */
#define _IOC_THLOC	10	/* Test location of handle */
#define _IOC_SSRC	11	/* Set sharing retry count */



/*

DOS error codes 

*/

#define _DOSE_NONE	0	/* No error */
#define _DOSE_BAD_FUNC	1	/* Bad function number */
#define _DOSE_FILE_NOTFND 2	/* File not found */
#define _DOSE_PATH_NOTFND 3	/* Path not found */
#define _DOSE_TOOMANY_OPENS 4	/* Too many files open */
#define _DOSE_ACC_DEN	5	/* Access denied */
#define _DOSE_BAD_HAND	6	/* Bad handle */
#define _DOSE_BAD_MCB	7	/* Bad memory control block */
#define _DOSE_NO_MEM	8	/* Out of memory */
#define _DOSE_BAD_MBA	9	/* Bad memory block address */
#define _DOSE_BAD_ENV	10	/* Bad environment */
#define _DOSE_BAD_FMT	11	/* Bad format */
#define _DOSE_BAD_ACC	12	/* Bad access code */
#define _DOSE_BAD_DATA	13	/* Bad data */
#define _DOSE_BAD_DISK	15	/* Bad disk drive */
#define _DOSE_REM_CD	16	/* Attempt to remove current directory */
#define _DOSE_NOT_SAME	17	/* Not same device */
#define _DOSE_NOMORE_FILES 18	/* No more files */
#define _DOSE_WRITE_PROT 19	/* Disk write-protected */
#define _DOSE_BAD_UNITNO 20	/* Bad disk unit number */
#define _DOSE_NOT_READY	21	/* Drive not ready */
#define _DOSE_BAD_CMD	22	/* Unknown command */
#define _DOSE_BAD_CRC	23	/* Bad CRC */
#define _DOSE_BAD_REQLEN 24	/* Bad request structure length */
#define _DOSE_SEEK	25	/* Seek error */
#define _DOSE_BAD_MEDT	26	/* Bad media type */
#define _DOSE_SECT_NOTFND 27	/* Sector not found */
#define _DOSE_NO_PAPER	28	/* No paper in printer */
#define _DOSE_WRITE_FLT	29	/* Write fault */
#define _DOSE_READ_FLT	30	/* Read fault */
#define _DOSE_GEN_FAIL	31	/* General failure */
#define _DOSE_SHARE_VIOL 32	/* Sharing violation */
#define _DOSE_LOCK_VIOL	33	/* Lock violation */
#define _DOSE_BAD_CHG	34	/* Invalid disk change */
#define _DOSE_NO_FCB	35	/* No FCB's available */
#define _DOSE_SHAR_OVF	36	/* Sharing buffer overflow */
#define _DOSE_REQ_NIMP	50	/* Network request not implemented */
#define _DOSE_RMT_NOLIS	51	/* Remote not listening */
#define _DOSE_DUP_NET	52	/* Duplicate name on network */
#define _DOSE_NET_NOTFND 53	/* Network name not found */
#define _DOSE_NET_BUSY  54	/* Network busy */
#define _DOSE_DEV_GONE  55	/* Network device no longer exists */
#define _DOSE_CMD_LIMIT	56	/* Network BIOS command limit exceeded */
#define _DOSE_NET_ERR	57	/* Network hardware error */
#define _DOSE_BAD_RESP	58	/* Bad response from network */
#define _DOSE_UNEXPECT 	59	/* Unexpected error */
#define _DOSE_ADPT_INC	60	/* Incompatible remote adapter */
#define _DOSE_PRTQ_FULL	61	/* Print queue full */
#define _DOSE_PRTQ_NOTFND 62	/* Print queue not found */
#define _DOSE_PRTF_DEL	63	/* Print file deleted */
#define _DOSE_NAME_DEL	64	/* Network name deleted */
#define _DOSE_ACC_DEN2	65	/* Access denied */
#define _DOSE_BAD_NTYEP	66	/* Bad network device type */
#define _DOSE_NET_NOTFND2 67	/* Network name not found */
#define _DOSE_NAME_LIMIT 68	/* Network name limit exceeded */
#define _DOSE_SESS_LIMIT 69	/* Network session limit exceeded */
#define _DOSE_TPAUSE	70	/* Temporary pause */
#define _DOSE_REQ_NACC	71	/* Network request not accepted */
#define _DOSE_RED_PAUSE	72	/* Print or disk redirection pause */
#define _DOSE_FILE_EXISTS 80	/* File already exists */
#define _DOSE_NO_DIRENT	82	/* Cannot make directory entry */
#define _DOSE_INT24_ERR	83	/* Error on INT 24 */
#define _DOSE_RED_TOOMANY 84	/* Too many redirections */
#define _DOSE_RED_DUP	85	/* Duplicate redirection */
#define _DOSE_BAD_PSWD	86	/* Bad password */
#define _DOSE_BAD_PARM	87	/* Bad parameter */
#define _DOSE_DEV_FAIL	88	/* Network device failure */


/*

386|DOS-Extender error codes

*/

#define _DXE_LDT_SIZE	128	/* LDT buf too small in load for debug call */
#define _DXE_BAD_PARAM	129	/* Bad parameter passed in to system call */
#define _DXE_NOT_DPMI	130	/* Operation not supported under this */
				/* DPMI implementation */
#define _DXE_DBG_NOSAV	131	/* Register saving for debuggers not enabled */
#define _DXE_DBG_NOREG	132	/* Register buffer for debuggers is empty */
#define _DXE_NO_PAGELOG	133	/* Attempt to write to VMM page log file */
				/* when no file exists */
#define _DXE_MAX_VMH	134	/* Maximum number of 386|VMM file handles */
				/* are already allocated */

/*
 * Memory error codes, returned by the Get Additional Memory Error Info
 * system call (_DX_MEMERR_GET), and some other system calls such as
 * _DX_LOAD_EXP and _DX_DBG_NEWLD.  It gives more detailed information
 * about why the most recent DOS memory error (error 8, _DOSE_NO_MEM) occurred.
 */
#define MERR_NONE	0	/* no additional info available */
#define MERR_NOMEM	1	/* insufficient physical memory available */
#define MERR_NOSWAP	2	/* insuff. VMM swap space available on disk */
#define MERR_NOLDT	3	/* no free LDT entries and unable to grow LDT*/
#define MERR_NOEXT	4	/* unable to change extended memory */
				/* allocation mark */
#define MERR_NOVIRT	5	/* insuff. virtual memory space (-MAXPGMMEM */
				/* switch value exceeded) */
#define MERR_NORBRK	6	/* insuff. conventional memory to satisfy */
				/* -REALBREAK when loading an EXP file */
#define MERR_NOPSP	7	/* insuff. conventional memory to allocate */
				/* a PSP and environment when loading an EXP */
				/* file for debugging */

/*
 * Loader error codes, returned by Load EXP file (_DX_LOAD_EXP) and Load
 * Program for Debug (_DX_DBG_NEWLD).
 */
#define LERR_OPEN	1	/* DOS error returned opening file */
#define LERR_SEEK	2	/* DOS error returned seeking in file */
#define LERR_READ	3	/* DOS error returned reading from file */
#define LERR_NOTEXE	4	/* Not a supported EXE or EXP file format */
#define LERR_INVFILE	5	/* Invalid file format (file header was */
				/* recognized, but information in the file */
				/* was invalid) */
#define LERR_BADOFFS	6	/* Linker -OFFSET switch value is not a */
				/* multiple of 4K, or -OFFSET not allowed */
				/* because -NOPAGE used, or because this */
				/* DPMI version doesn't support -OFFSET */
#define LERR_BADRBRK	7	/* -REALBREAK not allowed because -NOPAGE */
				/* used, or because this DPMI version */
				/* doesn't support -REALBREAK */
#define LERR_DOSLOAD	8	/* DOS error returned loading real mode */
				/* EXE file */
#define LERR_PRIV	9	/* privilege level of program incompatible */
				/* with current privilege level (only ret'd */
				/* by Load for Debug, not by Load EXP File) */

/*

DOS time structure

*/

typedef struct
{
	UCHAR hour;		/* Hour (0-23) */
	UCHAR minute;		/* Minute (0-59) */
	UCHAR second;		/* Second (0-59) */
	UCHAR hsecond;		/* 1/100 second (0-99) */
} DOS_TIME;


/*

DOS date structure

*/

typedef struct
{
	UCHAR day;		/* Day (1-31) */
	UCHAR month;		/* Month (1-12) */
	USHORT year;		/* Year (1980-...) */
	UCHAR dayofweek;	/* Day of week (0-6) */
} DOS_DATE;


/*

Disk block used in function 32H

*/

typedef struct
{
	UCHAR drive;		/* Number number (A = 0) */
	UCHAR unit_no;		/* Unit number within driver */
	USHORT sec_size;	/* Sector size in bytes */
	UCHAR sec_cls;		/* Number of sectors per cluster - 1*/
	UCHAR cls_shift;	/* Cluster to sector shift */
	USHORT rsrv_cnt;	/* Number of reserved sectors */
	UCHAR fat_cnt;		/* Number of FAT entries */
	USHORT root_cnt;	/* Number of root directory entries */
	USHORT cls2_secno;	/* Sector number of cluster #2 */
	USHORT cls_cnt;		/* Number of clusters + 1 */
	UCHAR fat_scnt;		/* Number of sectors for the FAT */
	USHORT dir_secno;	/* Sector number of the directory */
	REALPTR dev_hdrp;	/* Real mode pointer to device handle */
	UCHAR media_byte;	/* Media descriptor byte */
	UCHAR not_accf;		/* Not accessed flag */
	REALPTR dblk_nextp;	/* Real mode pointer to next block */
} DISK_BLK;


/*

File attributes

*/

#define NORM_FILE	0	/* Normal file */
#define RO_FILE		1	/* Read only file */
#define HIDE_FILE	2	/* Hiddent file */
#define SYS_FILE	4	/* System file */


/*

Find block

*/

typedef struct
{
	UCHAR reserved[21];	/* 21 bytes reserved by DOS */
	UCHAR file_attr;	/* File attribute */
	USHORT file_time;	/* File time */
	USHORT file_date;	/* File data */
	ULONG file_size;	/* Size in bytes of file */
	UCHAR file_name[13];	/* Null terminate file name */
} FIND_BLK;


/*

MS-DOS EXEC system call control block

*/

typedef struct
{
	UCHAR *ex_eoff;		/* Offset of the environment segment */
	USHORT ex_eseg;		/* Segment of the environment segment */
	UCHAR *ex_coff;		/* Offset of the command tail */
	USHORT ex_cseg;		/* Segment of the command tail */
} EXEC_BLK;


/*

Type of disk media

*/

#define DM_FIXED	0xF8	/* Fixed disk */
#define DM_DS15		0xF9	/* Double sided, 15 sectors (1.2 Meg) */
#define DM_SS9		0xFC	/* Single sided, 9 sectors */
#define DM_DS9		0xFD	/* Double sided, 9 sectors */
#define DM_SS8		0xFE	/* Single sided, 8 sectors */
#define DM_DS8		0xFF	/* Doubled sided, 8 sectors */


/*

Seek directions

*/

#define SEEK_ABS	0	/* Absolute seek */
#define SEEK_REL	1	/* Relative to current file ptr. */
#define SEEK_EOF	2	/* Relative to EOF */



/*

Country info typedef

*/

typedef struct
{

	USHORT date_fmt;	/* Date format */
	UCHAR curr_sym;		/* Currency symbol */
	UCHAR fill1;		/* Filler (zero) */
	UCHAR dec_sep;		/* Decimal separator character */
	UCHAR fill2;		/* Filler (zero) */
	UCHAR date_sep;		/* Date separator character */
	UCHAR fill3; 		/* Filler (zero) */
	UCHAR time_sep;		/* Time separator character */
	UCHAR fill4; 		/* Filler (zero) */
	UCHAR curr_fmt;		/* Currency format */
	UCHAR curr_ddec;	/* Number of digits after decimal */
	UCHAR time_fmt;		/* Time format */
	REALPTR cm_ptr;		/* Case map function pointer (real mode) */
	UCHAR dlist_sep;	/* Data list separator character */
	UCHAR fill5[11];	/* Filler */
} COUNTRY_INFO;

#define DATE_USA		/* American date format */
#define DATE_EUROPE		/* European date format */
#define DATE_JAPAN		/* Japanese date format */

#define CURR_SPM	0x02	/* Number of spaces between currency symbol
				   and value (0 or 1) */
#define CURR_LOCM	0x01	/* Location mask */
#define CURR_BEFORE	0x00	/* Currency symbol precedes value */
#define CURR_AFTER	0x01	/* Currency symbol follows value */


/*

Data structure for calling a protected mode procedure from real mode
(using addr obtained from system call 250Dh).

*/

typedef struct
{
	USHORT ds;		/* DS register */
	USHORT es;		/* ES register */
	USHORT fs;		/* FS register */
	USHORT gs;		/* GS register */
} PMC_BLK;


/*

Data structure for call real mode procedure (2510h)

*/

typedef struct
{
	USHORT ds;		/* DS register */
	USHORT es;		/* ES register */
	USHORT fs;		/* FS register */
	USHORT gs;		/* GS register */
	ULONG eax;		/* EAX register */
	ULONG ebx;		/* EBX register */
	ULONG ecx;		/* ECX register */
	ULONG edx;		/* EDX register */
} RMC_BLK;


/*

Data structure for issue real mode interrupt (2511h)

*/

typedef struct
{
	USHORT inum;		/* Interrupt number */
	USHORT ds;		/* DS register */
	USHORT es;		/* ES register */
	USHORT fs;		/* FS register */
	USHORT gs;		/* GS register */
	ULONG eax;		/* EAX register */
	ULONG edx;		/* EDX register */
} RMI_BLK;


/*

Data structure for load for debug system call (2512h and 252Ah)

*/

typedef struct
{
	UCHAR *ex_eoff;		/* Offset of the environment segment */
	USHORT ex_eseg;		/* Segment of the environment segment */
	UCHAR *ex_coff;		/* Offset of the command tail */
	USHORT ex_cseg;		/* Segment of the command tail */
	UCHAR *ex_loff;		/* Offset of the LDT buffer */
	USHORT ex_lseg;		/* Segment of the LDT buffer */
	USHORT real_psp;	/* Real mode PSP address */
	USHORT protf;		/* Protected mode flag */
	ULONG eip;		/* Initial EIP */
	USHORT cs;		/* Initial CS */
	ULONG esp;		/* Initial ESP */
	USHORT ss;		/* Initial SS */
	USHORT ds;		/* Initial DS */
	USHORT es;		/* Initial ES */
	USHORT fs;		/* Initial FS */
	USHORT gs;		/* Initial GS */
} LDDBG_BLK;

/*
 * Data structure for load EXP file system call (2529h)
 */
typedef struct
{
	ULONG	eip;		/* initial EIP */
	USHORT	cs;		/* initial CS */
	ULONG	esp;		/* initial ESP */
	USHORT	ss;		/* initial SS */
	USHORT ds;		/* Initial DS */
	USHORT es;		/* Initial ES */
	USHORT fs;		/* Initial FS */
	USHORT gs;		/* Initial GS */
	ULONG	minsize;	/* minimum size of program segment, in bytes */
				/* (any -OFFSET value, plus size of pgm in */
				/* EXP file, plus any -MINDATA value.  Same */
				/* as info at offset 5Ch in PSP for main pgm)*/
	ULONG	extramem;	/* amount of extra memory, in bytes, beyond */
				/* the size of the pgm in the EXP file, that */
				/* was allocated (Same as info at offset 64h */
				/* in PSP for main pgm) */
	ULONG	flags;		/* flags, defined below */
	ULONG	rsrv[8];	/* reserved, always zeroed */
} LDEXP_BLK;
/* Bit definitions for flags word in LDEXP_BLK struct */
#define LD_UNPRIV 0x00000001	/* if set, child was linked with -UNPRIV */
				/* switch, if cleared, child linked -PRIV */

/*

VM_STATS - Memory statistics data structure returned by 2520h system call.

*/

typedef struct
{
	ULONG vm_presf;		/* 386|VMM is present flag */
	ULONG vm_nconvpg;	/* Conventional memory physical page count */
	ULONG vm_rsrv1;		/* reserved, always zero */
	ULONG vm_nextpg;	/* Extended memory physical page count (this is
				   an APPROXIMATE number) */
	ULONG vm_extpglim;	/* Extended memory physical page limit */
	ULONG vm_nallocpg;	/* Number of physical pages allocated to
				   application */
	ULONG vm_nlockpg;	/* Number of locked physical pages */
	ULONG vm_nsyspg;	/* Number of physical pages allocated by
				   386|DOS-Extender for system data */
	ULONG vm_rsrv2;		/* reserved, contents undefined */
	ULONG vm_dmin;		/* Linear address of the beginning of
				   the dynamic linear range */
	ULONG vm_dmax;		/* Linear address of 1 byte past the end of
				   the dynamic linear range */
	ULONG vm_eltime;	/* Elapse time in seconds since last
				   VM status reset */
	ULONG vm_pfltcnt;	/* Number of page faults since last
				   VM status reset */
	ULONG vm_wrtcnt;	/* Number of pages written out to disk
				   since the last VM status reset */
	ULONG vm_reclcnt;	/* Number of reclaimed pages since the
				   last VM status reset */
	ULONG vm_nvirtpg;	/* Number of virtual pages allocated to
				   application */
	ULONG vm_nswappg;	/* Size of swap file, in pages */
	ULONG vm_rsrv3;		/* reserved, contents undefined */
	ULONG vm_minconvpg;	/* Minimum number of conventional memory 
				   pages required */
	ULONG vm_maxswpg;	/* Max. size of swap file, in pages */
	ULONG vm_flags;		/* flag bits */
	ULONG vm_nfree;		/* number of free physical pages GUARANTEED 
				   (total number of physical pages currently
				   used by appl and 386|DOS-Extender system
				   data is vm_nfree + vm_syspg + vm_nallocpg */
	ULONG vm_navail;	/* number of free physical pages currently 
				   available (equal to
				   MIN(vm_nextpg, vm_extpglim) - vm_nlockpg - 
				   				vm_syspg */
	ULONG vm_rsrv[2];	/* Reserved, always zero */
} VM_STATS;

/*
 * Bit definitions for flags in VM_STATS structure
 */
#define VMFL_PGFLT	0x00000001	/* page fault in progress */

/*
 * 386|VMM parameters block (Get/Set 386|VMM Parameters System Call)
 */
typedef struct
{
	ULONG	vp_flags;	/* flag bits */
	ULONG	vp_vscan;	/* scan period, in milliseconds, for */
				/* updating page ageing information */
	ULONG	vp_vslen;	/* max length, in bytes, of linear address */
				/* space to process on each page table scan */
	ULONG	vp_rsrvd[13];	/* reserved for future expansion */
} VM_PARAMS;

/*
 * Bit definitions for flags in VM_PARAMS struct
 */
#define VMP_PGLOGEN	0x00000001	/* page fault logging enabled */

/*
 * Data structure for Get Configuration Information call (2526h)
 */
typedef struct {
	ULONG	c_flags1;	/* flags dword 1 */
	ULONG	c_flags2;	/* flags dword 2 */
	ULONG	c_flags3;	/* flags dword 3 */
	ULONG	c_major;	/* 386|DOS-Extender major version # */
	ULONG	c_minor;	/* 386|DOS-Extender minor version # */
	ULONG	c_letter;	/* first letter, in ASCII, of text following */
				/* minor version # in version number string */
				/* 0 if no letter present */
	ULONG	c_betaf;	/* 0 ==> not a beta version, 1 ==> beta */
				/* more than one letter following minor */
				/* version number) */
	ULONG	c_processor;	/* 3 ==> 386, 4 ==> 486 */
	ULONG	c_coproc;	/* 4 ==> none, 6 ==> 287, 7 ==> 387 or 486 */
	ULONG	c_weitekf;	/* 0 ==> not present, 1 ==> present (see */
				/* also c_1167 below) */
	ULONG	c_machine;	/* 0 ==> IBM compat, 1 ==> NEC 9800 series */
	ULONG	c_mclass;	/* IBM:  0==>ISA, 1==>MCA, 2==>XT, 3==>EISA */
				/* NEC:  0==>normal mode, 1==>high res mode */
	ULONG	c_dosenv;	/* VCPI flag; 0==>no VCPI, 1==>VCPI present */
	ULONG	c_1167;		/* -WEITEK or -1167 switch setting:  */
				/* 0 ==> AUTO, 1 ==> ON, 2 ==> OFF */
	ULONG	c_minreal;	/* -MINREAL switch setting */
	ULONG	c_maxreal;	/* -MAXREAL switch setting */
	ULONG	c_minibuf;	/* -MINIBUF switch setting */
	ULONG	c_maxibuf;	/* -MAXIBUF switch setting */
	ULONG	c_ibufsize;	/* size of data buf for DOS calls, in bytes */
	ULONG	c_nistack;	/* -NISTACK switch setting */
	ULONG	c_istksize;	/* -ISTKSIZE switch setting */
	ULONG	c_realbreak;	/* -REALBREAK switch setting */
	ULONG	c_callbufs;	/* -CALLBUFS switch setting */
	ULONG	c_hwivec;	/* -HWIVEC switch setting */
	ULONG	c_privec;	/* -PRIVEC switch setting */
	ULONG	c_intmap;	/* -INTMAP switch setting */
	ULONG	c_primap;	/* -PRIMAP switch setting */
	ULONG	c_irq0;		/* hardware interrupt vector for IRQ0 when */
				/* running under VCPI */
	ULONG	c_irq8;		/* HW interrupt vector for IRQ8 under VCPI, 0*/
				/* if running on an XT with only IRQ0-7 */
	ULONG	c_prscreen;	/* interrupt vector for BIOS print screen, */
				/* 0 if c_machine == NEC */
	ULONG	c_extlow;	/* -EXTLOW switch setting */
	ULONG	c_exthigh;	/* -EXTHIGH switch setting */
	ULONG	c_minext;	/* physical addr of lowest extended memory */
				/* 386|DOS-Extender will ever allocate */
	ULONG	c_maxext;	/* physical addr of 1 byte past highest */
				/* ext mem 386|DOS-Extender will allocate */
	ULONG	c_smem_base;	/* physical base addr of "special" memory */
				/* (either auto detected, or specified with */
				/* the -SPCLMEM switch, 0 if none) */
	ULONG	c_smem_size;	/*size, in bytes, of "special" mem, 0 if none*/
	ULONG	c_maxvcpimem;	/* -MAXVCPIMEM switch setting */
	ULONG	c_vscan;	/* -VSCAN switch setting */
	ULONG	c_swapchk;	/* -SWAPCHK switch setting:  0 ==> OFF, */
				/* 1 ==> ON, 2 ==> FORCE, 3 ==> MAX */
	ULONG	c_codesize;	/* -CODESIZE switch setting */
	ULONG	c_minswfsize;	/* -MINSWFSIZE switch setting */
	ULONG	c_maxswfsize;	/* -MAXSWFSIZE switch setting */
	ULONG	c_replpolicy;	/* 0 ==> LFU, 1 ==> NUR */
	ULONG	c_ngdtent;	/* -NGDTENT switch setting */
	ULONG	c_nldtent;	/* -NLDTENT switch setting */
	ULONG	c_priv;		/*privilege level program is running at (0-3)*/
/* the following values were added in release 3.0 of 386|DOS-Extender */
	ULONG	c_lockstack;	/* -LOCKSTACK switch setting */
	ULONG	c_maxextmem;	/* -MAXEXTMEM switch setting */
	ULONG	c_maxxmsmem;	/* -MAXXMSMEM switch setting */
	ULONG	c_maxpgmmem;	/* -MAXPGMMEM switch setting */
	ULONG	c_datathresh;	/* -DATATHRESHOLD switch setting */
	ULONG	c_vmmf;		/* 0 ==> 386|VMM not present, 1 ==> present */
	ULONG	c_cyrixf;	/* 0==>Cyrix EMC387 not present, 1==>present*/
	ULONG	c_cyrix;	/* -CYRIX switch setting, 0 ==> AUTO */
				/* 1 ==> ON, 2 ==> OFF */
	ULONG	c_dpmif;	/* 0 ==> DPMI not present, 1 ==> present */
	ULONG	c_dpmimaj;	/* DPMI major version number */
	ULONG	c_dpmimin;	/* DPMI minor version number */
	ULONG	c_dpmi_capf;	/* DPMI capabilities flags */
	ULONG	c_vcpimaj;	/* VCPI major version number */
	ULONG	c_vcpimin;	/* VCPI minor version number */
	USHORT	c_vcpiirq0;	/* under VCPI, IRQ0 physical base int vector */
	USHORT	c_vcpiirq8;	/* under VCPI, IRQ8 physical base int vector */
	ULONG	c_xmsf;		/* 0 ==> XMS not present, 1 ==> present */
	ULONG	c_xmsmaj;	/* XMS major version number */
	ULONG	c_xmsmin;	/* XMS minor version number */
	USHORT	c_cs_sel;	/* appl's CS selector */
	USHORT	c_ds_sel;	/* appl's DS selector */
	USHORT	c_psp_sel;	/* appl's PSP selector */
	USHORT	c_env_sel;	/* appl's environment selector */
	USHORT	c_dos_sel;	/* selector for segment mapping DOS 1MB */
				/* address space */
	USHORT	c_vidtxt_sel;	/* selector for segment mapping video text */
				/* memory */
	USHORT	c_vidgrph_sel;	/* selector for segment that maps video */
				/* graphics memory on NEC machines;  maps */
				/* the same memory as the video text segment */
				/* on IBM-compatible machines */
	USHORT	c_weitek_sel;	/* selector of segment that maps Weitek */
				/* address space, 0 if no Weitek chip */
	USHORT	c_cyrix_sel;	/* selector of segment that maps Cyrix EMC387*/
				/* address space, 0 if no Cyrix chip */
	USHORT	c_unused;	/* reserved, always zero */
	ULONG	c_swprot;	/* real mode FAR addr of 386|DOS-X routine */
				/* to CALL for a jump to protected mode */
				/* with no saved context */
	ULONG	c_ldtsize;	/* size of LDT, in bytes */
	ULONG	c_rsrv[57];	/* Reserved, always zero */
} CONFIG_INF;
/*
 * Bit definitions for c_flags1.  c_flags2 and c_flags3 are currently unused.
 */
#define	CF1_NOPAGE	0x00000001L	/* -NOPAGE switch used */
#define	CF1_A20		0x00000002L	/* -A20 switch used */
#define	CF1_VDISK	0x00000004L	/* -VDISK switch used */
#define	CF1_XT		0x00000008L	/* -XT switch used */
#define	CF1_AT		0x00000010L	/* -AT switch used */
#define	CF1_MCA		0x00000020L	/* -MCA switch used */
#define	CF1_EISA	0x00000040L	/* -EISA switch used */
#define	CF1_NORMRES	0x00000080L	/* -NORMRES switch (for NEC) used */
#define	CF1_HIGHRES	0x00000100L	/* -HIGHRES switch (for NEC) used */
#define	CF1_SWFGROW	0x00000200L	/* 1 ==> -SWFGROW1ST switch used, */
					/* 0 ==> -NOSWFGROW1ST */
#define	CF1_NOVM	0x00000400L	/* -NOVM switch used */
#define	CF1_SAVEREGS	0x00000800L	/* -SAVEREGS switch used */
/*	0x00001000L			not used, always zero */
#define	CF1_NOVCPI	0x00002000L	/* -NOVCPI switch used */
#define	CF1_NOMUL	0x00004000L	/* -NOMUL switch used */
#define	CF1_NOBMCHK	0x00008000L	/* -NOBMCHK switch used */
#define	CF1_NOSPCL	0x00010000L	/* -NOSPCLMEM or -NOBIM switch used */
#define	CF1_NOPGEXP	0x00020000L	/* -NOPGEXP switch used */
#define	CF1_SWAPDEFDISK	0x00040000L	/* -SWAPDEFDISK switch used */
/* the following values were added in release 3.0 of 386|DOS-Extender */
#define CF1_SAVEINTS	0x00080000L	/* -SAVEINTS switch used */
#define CF1_NOLOAD	0x00100000L	/* -NOLOAD switch used */
#define CF1_PAGELOG	0x00200000L	/* -PAGELOG switch used */
#define CF1_OPENDENY	0x00400000L	/* -OPENDENY switch used */
#define CF1_ERRATA17	0x00800000L	/* -ERRATA17 switch used */

/*
 * Flags bits for DPMI capabilities flags dword 
 */
#define CD_PAGING	0x00000001L	/* paging support capability present */
					/* (never present in 0.9 DPMI, always*/
					/* present if 1.0 or later DPMI) */
#define CD_DEVMAP	0x00000002L	/* Physical Device Mapping capability*/
					/* present */
#define CD_CONVMEM	0x00000004L	/* Conventional Memory Mapping */
					/* capability present */
#define CD_EXCRSTRT	0x00000008L	/* Exceptions Restartability */
					/* capability present */

/*
 * Data structure for system call 2528h and 2538h (get appl registers)
 */
typedef struct {
	USHORT	u1;		/* unused, never modified */
	ULONG	u2;		/* unused, never modified */
	USHORT	u3;		/* unused, never modified */
	ULONG	eax;		/* register EAX contents */
	ULONG	ebx;		/* register EBX contents */
	ULONG	ecx;		/* register ECX contents */
	ULONG	edx;		/* register EDX contents */
	ULONG	esi;		/* register ESI contents */
	ULONG	edi;		/* register EDI contents */
	ULONG	ebp;		/* register EBP contents */
	ULONG	esp;		/* register ESP contents */
	USHORT	cs;		/* register CS contents */
	USHORT	ds;		/* register DS contents */
	USHORT	ss;		/* register SS contents */
	USHORT	es;		/* register ES contents */
	USHORT	fs;		/* register FS contents */
	USHORT	gs;		/* register GS contents */
	ULONG	eip;		/* register EIP contents */
	ULONG	flags;		/* register EFLAGS contents */
} SWI_REGS;

/*
 * Bit definitions for the page type word returned for each page by the
 * Get Page Types call (system call 252Bh, subfunction 4)
 *
 * The flags bits apply only if the page type is allocated.
 */
#define PT_TYPE		0x000F	/* page type code field */
	#define PTYP_UNMAP	0	/* unmapped page */
	#define PTYP_ALLOC	1	/* allocated page */
	#define PTYP_PHYSDEV	2	/* physical device page */
#define PT_LOCKED	0x0010	/* allocated page is locked */
#define PT_SWAPPED	0x0020	/* allocated page is swapped to disk */
#define PT_ROFILE	0x0040	/* alloc'd page mapped to rd only data file */
#define PT_RWFILE	0x0080	/* alloc'd page mapped to rd/wr data file */

/*
 * Data structure for Read/Write System Registers system call 2535h 
 */

typedef struct{
	ULONG	cr0;		/* Control Register 0 */
	ULONG	dr0;		/* Debug Register 0 */
	ULONG	dr1;		/* Debug Register 1 */
	ULONG	dr2;		/* Debug Register 2 */
	ULONG	dr3;		/* Debug Register 3 */
	ULONG	rsrv1[2];	/* reserved, always zeroed */
	ULONG	dr6;		/* Debug Register 6 */
	ULONG	dr7;		/* Debug Register 7 */
	ULONG	rsrv2[3];	/* reserved, always zeroed */
} SYS_REGS;

/*
 * Record numbers for page log file created by 386|VMM if the
 * -PAGELOG switch is used
 */
#define PREC_BASE	0	/* segment base changed record */
#define PREC_LIMIT	1	/* segment limit changed record */
#define PREC_PGFLT	2	/* page fault record */
#define PREC_SWAPSIZ	3	/* swap file size increased record */
#define PREC_APPL	4	/* application-defined record */

/*
 * Flag bit definitions for the flags byte in a page fault record 
 */
#define PLOG_DSKRD	0x01	/* set if page read from swap file, EXP */
				/* file, or mapped data file;  cleared if */
				/* page was just zeroed */
#define PLOG_SWAPRD	0x02	/* set if read from swap file, cleared if */
				/* read from EXP file or mapped data file */
#define PLOG_THRASH	0x04	/* set if this page has been in memory */
				/* before, cleared if 1st time in memory */
#define PLOG_REPLCD	0x08	/* set if another virtual page was replaced */
				/* (kicked out of memory), cleared if a free */
				/* physical page was available.  If set, */
				/* the DWORD at offset 6 in the page fault */
				/* record is present, and specifies the */
				/* linear addr of the replaced page */
#define PLOG_SWAPWR	0x10	/* set if replaced page written to swap file */
				/* or to a read/write mapped data file, */
				/* cleared if replaced page just discarded */
				/* because it was unmodified */

/*	
 * Function prototypes for C-callable routines in DOSX32.LIB, to make
 * 386|DOS-Extender system calls from C.
 *
 * All functions return an error code, a zero value (_DOSE_NONE) meaning 
 * no error.
 */
extern int _dx_reset_data(void);
extern int _dx_pmiv_get(UINT int_no, FARPTR *int_handpp);
extern int _dx_rmiv_get(UINT int_no, REALPTR *int_handpp);
extern int _dx_pmiv_set(UINT int_no, FARPTR int_handp);
extern int _dx_rmiv_set(UINT int_no, REALPTR int_handp);
extern int _dx_apmiv_set(UINT int_no, FARPTR int_handp);
extern int _dx_rpmiv_set(UINT int_no, FARPTR pm_int_handp,
	                 REALPTR rm_int_handp);
extern int _dx_tolinear(USHORT selector, ULONG *lin_addrp);
extern int _dx_tophys(ULONG lin_addr, ULONG *phys_addrp);
extern int _dx_map_phys(USHORT selector, ULONG phys_addr, ULONG page_cnt,
				ULONG *offsetp);
extern int _dx_hwiv_get(UINT *irq0_7p, UINT *irq8_15p, UINT *prt_scrp);
extern int _dx_rmlink_get(REALPTR *cback_addrpp, REALPTR *rm_cbuff_addrpp,
		       ULONG *cbuff_sizep, FARPTR *pm_cbuff_addrpp);
extern int _dx_real_call(REALPTR proc_addr, UINT word_cnt);
extern int _dx_toreal(FARPTR pm_addrp, ULONG byte_cnt, REALPTR *rm_addrpp);
extern int _dx_real_regcall(REALPTR proc_addrp, ULONG word_cnt, 
		            RMC_BLK *parmp);
extern int _dx_real_int(RMC_BLK *parmp);
extern int _dx_dbg_load(UCHAR *prog_namep, LDDBG_BLK *parmp, UINT ldt_bytes,
		      UINT *sel_countp);
extern int _dx_seg_alias(USHORT selector, UINT acc_rights, UINT use_types, 
                     USHORT *alias_selp);
extern int _dx_segattr_set(USHORT selector, UINT acc_rights, UINT use_types);
extern int _dx_segattr_get(USHORT selector, UINT *acc_rightsp, 
			   UINT *use_typesp);
extern int _dx_ldtmem_free(void);
extern int _dx_dosbuf_get(FARPTR *pm_buffpp, REALPTR *rm_buffpp,
		         ULONG *buff_sizep);
extern int _dx_segmove_hand(FARPTR new_handp, FARPTR *old_handpp);
extern int _dx_memerr_get(void);
extern int _dx_page_lock(FARPTR addrp, ULONG npage);
extern int _dx_page_lockl(ULONG linadr, ULONG npage);
extern int _dx_page_unlock(FARPTR addrp, ULONG npage);
extern int _dx_page_unlockl(ULONG linadr, ULONG npage);
extern int _dx_page_free(FARPTR addrp, ULONG npage, BOOL discardf);
extern int _dx_page_freel(ULONG linadr, ULONG npage, BOOL discardf);
extern int _dx_pte_read(FARPTR addrp, ULONG *valp);
extern int _dx_pte_readl(ULONG linadr, ULONG *valp);
extern int _dx_pte_write(FARPTR addrp, ULONG val);
extern int _dx_pte_writel(ULONG linadr, ULONG val);
extern int _dx_pte_xchg(FARPTR addr1p, FARPTR addr2p);
extern int _dx_pte_xchgl(ULONG linaddr1, ULONG linadr2);
extern int _dx_vm_stats(VM_STATS *statp, BOOL resetf);
extern int _dx_xmem_limit(ULONG npages, ULONG *minp, ULONG *maxp);
extern int _dx_pgflt_hand(FARPTR new_handp, FARPTR *old_handpp);
extern int _dx_oswsp_hand(FARPTR new_addrp, FARPTR *old_addrpp);
extern int _dx_pgrepl_hand(FARPTR new_raddrp, FARPTR *old_raddrpp,
			   FARPTR new_taddrp, FARPTR *old_taddrpp,
			   FARPTR new_paddrp, FARPTR *old_paddrpp);
extern int _dx_cmem_limit(ULONG npages, ULONG *minp, ULONG *maxp);
extern int _dx_config_inf(CONFIG_INF *bufp, UCHAR *swf_namep);
extern int _dx_dbg_regsav(BOOL savf);
extern int _dx_cc_rdregs(SWI_REGS *buffp);
extern	int _dx_ld_flat(UCHAR *prog_namep, LDEXP_BLK *parmp, BOOL dmdloadf, 
			UINT *vmmhp, UINT *errinfop, UINT *doserrp);
extern int _dx_dbg_ld(UCHAR *prog_namep, LDDBG_BLK *parmp, UINT ldt_bytes,
                      BOOL dmdloadf, UINT *vmmhp, UINT *ndescp,
		       UINT *errinfop, UINT *doserrp);
extern	int _dx_umap_pgs(FARPTR addrp, UINT len);
extern	int _dx_umap_pgsl(ULONG linadr, UINT len);
extern	int _dx_alloc_pgs(FARPTR addrp, UINT len);
extern	int _dx_alloc_pgsl(ULONG linadr, UINT len);
extern	int _dx_map_pgs(FARPTR addrp, UINT len, ULONG baseaddr);
extern	int _dx_map_pgsl(ULONG linadr, UINT len, ULONG baseaddr);
extern	int _dx_mfile_pgs(FARPTR addrp, UINT len, UCHAR *fnamep, USHORT facc,
                      UINT *vmmhp, UINT *flenp, UINT *errinfo, UINT *doserr);
extern	int _dx_mfile_pgsl(ULONG linadr, UINT len, UCHAR *fnamep, USHORT facc,
                       UINT *vmmhp, UINT *flenp, UINT *errinfo, UINT *doserr);
extern	int _dx_gtyp_pgs(FARPTR addrp, UINT len, UCHAR *buffp);
extern	int _dx_gtyp_pgsl(ULONG linadr, UINT len, UCHAR *buffp);
extern	int _dx_lock_pgs(FARPTR addrp, UINT len);
extern	int _dx_lock_pgsl(ULONG linadr, UINT len);
extern	int _dx_ulock_pgs(FARPTR addrp, UINT len);
extern	int _dx_ulock_pgsl(ULONG linadr, UINT len);
extern	int _dx_fphys_pgs(FARPTR addrp, UINT len, BOOL discardf);
extern	int _dx_fphys_pgsl(ULONG linadr, UINT len, BOOL discardf);
extern int _dx_add_umapg(USHORT selector, ULONG page_cnt, UINT *segoffp);
extern int _dx_vmm_close(UINT vmmhndl);
extern int _dx_vmm_pget(VM_PARAMS *buffp);
extern int _dx_vmm_pset(VM_PARAMS *buffp);
extern int _dx_vmm_wlog(UCHAR *datap, USHORT datasiz);
extern int _dx_dosbuf_set(UINT buffsiz);
extern int _dx_ldt_rd(USHORT selector, UCHAR *descp);
extern int _dx_ldt_wr(USHORT selector, UCHAR *descp);
extern int _dx_excep_get(UCHAR num, FARPTR *evecpp);
extern int _dx_excep_set(UCHAR num, FARPTR evecp);
extern int _dx_if_get(BOOL *iflg);
extern int _dx_sysregs_get(SYS_REGS *buffp);
extern int _dx_sysregs_set(SYS_REGS *buffp);
extern int _dx_cmem_usage(ULONG npages, BOOL maximizef, ULONG *minp, 
							ULONG *maxp);
extern int _dx_ext_usage(ULONG npages, BOOL maximizef, ULONG *minp, 
							ULONG *maxp);
extern int _dx_real_above(UINT para_count, USHORT *para_addrp,
			  USHORT *largestp);
extern int _dx_swi_rdregs(SWI_REGS *buffp, BOOL nextf, ULONG *ihndp,
						ULONG *intnump);
extern int _dx_hdroff_get(ULONG hndl, ULONG *hdroffp, ULONG *fep, 
							USHORT *dosep);
extern int _dx_msegfail_hnd(FARPTR new_hndp, FARPTR *old_hndpp);
extern int _dx_jmp_toreal(SWI_REGS *buffp);
extern int _dx_shrink_swap(ULONG *old_nbytep, ULONG *new_nbytep);
extern int _dx_idt_rd(UINT int_no, UCHAR *descp);
extern int _dx_idt_wr(UINT int_no, UCHAR *descp);
extern int _dx_real_alloc(UINT para_count, USHORT *para_addrp, 
			  USHORT *largestp);
extern int _dx_real_free(USHORT para_addr);
extern int _dx_real_resize(USHORT para_addr, UINT para_count,
            USHORT *largestp);
extern int _dx_exec_spec(UCHAR *pathp, EXEC_BLK *parmp);

/*	
 * Function prototypes for C-callable routines in DOS32.LIB, to make
 * 32-bit DOS system calls from C.
 *
 * All functions return an error code, a zero value (_DOSE_NONE) meaning 
 * no error.
 */

#ifndef __HIGHC__
extern int _dos_char_ine(UCHAR *chp);
extern int _dos_char_out(UCHAR ch);
extern int _dos_str_out(UCHAR *strp);
extern int _dos_buff_in(UCHAR *bufp);
extern int _dos_ver(ULONG dxinfo, ULONG *verp, ULONG *dxverp, ULONG *dxenvp);
extern int _dos_create(UCHAR *fnamep, USHORT attr, USHORT *handlep);
extern int _dos_open(UCHAR *fnamep, USHORT attr, USHORT *handlep);
extern int _dos_close(USHORT handle);
extern int _dos_read(USHORT handle, int nbytes, FARPTR bufp, int *nreadp);
extern int _dos_write(USHORT handle, int nbytes, FARPTR bufp, int *nwritep);
extern int _dos_delete(UCHAR *fnamep);
extern int _dos_seek(USHORT handle, int origin, LONG offset,ULONG *new_filep);
extern int _dos_force_hnd(USHORT hnd, USHORT newhnd);
extern int _dos_seg_alloc(ULONG npages, USHORT *selectorp, ULONG *maxpgsp);
extern int _dos_seg_free(USHORT selector);
extern int _dos_seg_resize(USHORT selector, ULONG npages, ULONG *maxpgsp);
extern int _dos_alloc_sset(USHORT strategy);
extern int _dos_alloc_sget(USHORT *stratp);
#endif