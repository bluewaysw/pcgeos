/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Handle management
 * FILE:	  handle.h
 *
 * AUTHOR:  	  Adam de Boor: Jul 21, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/21/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for users of the Handle module. The Handle module
 *	is responsible for tracking the memory management of the GEOS
 *	kernel, primarily for the installation and removal of breakpoints
 *	when a block changes state.
 *
* 	$Id: handle.h,v 4.4 97/04/18 15:32:29 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _HANDLE_H_
#define _HANDLE_H_

/*
 * State bits. Note that assert statements in handle.c depend on the contiguity
 * of certain of these bits. Change their order with care...
 */
#define HANDLE_IN 	    0x00001 /* Block is in */

#define HANDLE_SWAPABLE     0x00002 /* Block may be swapped */
#define HANDLE_DISCARDABLE  0x00004 /* Block may be discarded */
#define HANDLE_FIXED	    0x00008 /* Block is fixed in memory */
#define HANDLE_SHARED	    0x00010 /* Block is shared */

#define HANDLE_SWAPPED	    0x00020 /* Block has been swapped out */
#define HANDLE_DISCARDED    0x00040 /* Block has been discarded */

#define HANDLE_RESOURCE	    0x00080 /* Handle is for a resource */
#define HANDLE_PROCESS	    0x00100 /* Handle is for a process */
#define HANDLE_ATTACHED	    0x00200 /* We've expressed an interest */
#define HANDLE_KERNEL	    0x00400 /* Handle is for the kernel. There are
				     * many of these. kcode, kinit, kdata,
				     * thread 0, swat, dos, bios1 and bios2 */
#define HANDLE_LMEM 	    0x00800 /* Managed by LMem */
#define HANDLE_READ_ONLY    0x01000 /* Resource handle is read-only so it's
				     * shared between instances of a geode */
#define HANDLE_INVALID	    0x02000 /* Resource handle was flushed last time
				     * and we need to get correct current
				     * position. */

#define HANDLE_TYPE 	    0xf8000 /* Type of handle */

#define HANDLE_MEMORY	    0x08000 /* Handle is for memory */
#define HANDLE_QUEUE	    0x40000 /* Event queue */
#define HANDLE_DISK 	    0x50000 /* Disk tracking */
#define HANDLE_TIMER	    0x60000 /* Timer data */
#define HANDLE_EVENT_DATA   0x70000 /* Data for EVENT_STACK */
#define HANDLE_EVENT_STACK  0x80000 /* Handle is event w/stack stuff */
#define HANDLE_EVENT	    0x90000 /* Handle is regular event */
#define HANDLE_SAVED	    0xa0000 /* Handle is for "saved" block */
#define HANDLE_VM_HDR	    0xb0000 /* Handle is to header of VM file */
#define HANDLE_VM   	    0xc0000 /* VMem handle (owns blocks, so...) */
#define HANDLE_FILE 	    0xd0000 /* File handle */
#define HANDLE_THREAD	    0xe0000 /* Handle is for a thread */
#define HANDLE_GSEG 	    0xf0000 /* GSeg handle */

#define Handle_IsMemory(state)	(((state)&HANDLE_TYPE) == HANDLE_MEMORY)
#define Handle_IsThread(state)	(((state)&HANDLE_TYPE) == HANDLE_THREAD)
#define Handle_IsVM(state)  	(((state)&HANDLE_TYPE) == HANDLE_VM)
#define Handle_IsFile(state)  	(((state)&HANDLE_TYPE) == HANDLE_FILE)
#define Handle_IsGSeg(state)  	(((state)&HANDLE_TYPE) == HANDLE_GSEG)

/*
 * Resource handles and Kernel handles both contain symbols
 */
#define HANDLE_SYM	    (HANDLE_RESOURCE|HANDLE_KERNEL)


/*
 * Status parameter for interest procedures
 */
typedef enum {
    HANDLE_SWAPIN,	    /* Block has been swapped in */
    HANDLE_LOAD,  	    /* Block has been loaded from disk */
    HANDLE_SWAPOUT,	    /* Block has been swapped out */
    HANDLE_DISCARD,	    /* Block has been discarded */
    HANDLE_RESIZE,	    /* Block has been resized */
    HANDLE_MOVE,  	    /* Block has moved */
    HANDLE_FREE,  	    /* Block has been freed */
    HANDLE_FCHANGE, 	    /* Block flags changed */
} Handle_Status;

typedef void	HandleInterestProc(Handle, Handle_Status, Opaque);

void 	Handle_Init (void);
Handle  Handle_Find (Address address);
Handle  Handle_Lookup (word id);
void	Handle_Reset(Handle handle, word id);
void	Handle_Free (Handle handle);
Address Handle_Address (Handle handle);
word	Handle_Segment (Handle handle);
word 	Handle_ID (Handle handle);
long 	Handle_State (Handle handle);
word 	Handle_XipPage (Handle handle);
Handle 	Handle_Owner (Handle handle);
Patient Handle_Patient (Handle handle);
int 	Handle_Size (Handle handle);
Opaque 	Handle_OtherInfo (Handle handle);
void 	Handle_Interest (Handle handle,
			 HandleInterestProc *interestProc,
			 Opaque data);
void 	Handle_NoInterest (Handle handle,
			   HandleInterestProc *interestProc,
			   Opaque data);
/*
 * Return Type token describing structure of a given non-memory handle.
 * Don't declare to return Type b/c we may not have type.h here...
 */
Type	Handle_TypeStruct(Handle handle);

/*
 * For patient-dependent interface ONLY
 */
#define HANDLE_ADDRESS	    1	    /* Address changed */
#define HANDLE_SIZE	    2	    /* Size changed */
#define HANDLE_FLAGS	    4	    /* Flags changed */
#define HANDLE_ID 	    8	    /* Id changed */

#define HANDLE_NOT_XIP	    (word)-1

void 	Handle_Change (Handle handle, int which, word id,
		       Address address, dword size, long flags, word xipPage);
Handle 	Handle_Create (Patient patient, word id, Handle owner,
		       Address address, dword size, long flags,
		       Opaque otherInfo, word xipPage);
Handle 	Handle_CreateResource(Patient patient, word id, word resid);
void	Handle_SetOwner(Handle handle, Patient patient);
void	Handle_MakeReadOnly (Handle handle);

#endif /* _HANDLE_H_ */
