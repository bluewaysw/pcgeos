/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Patient-dependent internal definitions
 * FILE:	  ibmInt.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 26, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions common to the Ibm modules.
 *
* 	$Id: ibmInt.h,v 4.4 94/12/20 18:41:20 ian Exp $
 *
 ***********************************************************************/
#ifndef _IBMINT_H_
#define _IBMINT_H_

#include    "cache.h"
#include    "rpc.h"

/*
 * Offsets into the .exe header for things we need.
 */
#define EXE_CSUM_OFF	    0x12
#define EXE_HEADERSIZE_OFF  8

#define swaps(s) ((word)(swap ? ((s & 0xff) << 8) | ((s >> 8) & 0xff) : s))

/*
 * Miscellaneous thingies
 */
extern word 	kcsum;	    /* Checksum of current kernel */
extern int  	stubType;   /* Type of stub on other end */
extern Boolean 	noFullStop; /* Don't deliver fullstop event on stoppage */
extern int  	attached;   /* Non-zero if attached to PC */
extern Boolean	bootstrap;  /* Non-zero if should bootstrap symbols */
extern long  	exeLoadBase;	/* File offset in kernel/loader executable of
				 * load image */
extern int  	patientsChucked;    /* Number of patients discarded since
				     * last garbage collection */
/*
 * Type descriptions for RPC calls
 */
extern Type 	    typeSegAddr, typeIbmRegs, typeHaltArgs, typeMaskArgs,
		    typeCallArgs, typeReadArgs, typeWriteArgs, typeFillArgs,
		    typeIOWArgs, typeAbsReadArgs, typeAbsWriteArgs,
		    typeAbsFillArgs, typeSpawnArgs, typeDeathArgs,
		    typeHelloArgs, typeHelloReply, typeHelloGeode,
		    typeHelloThread, typeGeodeHeader, typeWriteRegsArgs,
		    typeStepReply, typeBeepReply,typeReadXmsMemArgs;

/*
 * Private data we maintain for each thread.
 */
typedef struct {
    IbmRegs 	    regs;    	/* Saved registers */
    Lst	    	    state;    	/* Stack of saved state */
    word 	    stackBot; 	/* Bottom of stack */
    Handle  	    handle;   	/* Handle for thread */
    int	    	    flags;    	/* Flags for the thread (see below) */
    int	    	    number; 	/* The number of the thread (as revealed by
				 * which stack it's using) */
    Handle  	    stack;  	/* Block in which stack resides */
} ThreadRec, *ThreadPtr;
#undef NullThread
#define NullThread ((ThreadPtr)NULL)


#define IBM_REGS_DIRTY	0x00000001  	/* Registers have been modified.
					 * Should be written before
					 * threads are changed or the
					 * machine continued. */
#define IBM_REGS_NEEDED	0x00000002  	/* Registers for thread need to
					 * be fetched. */
#define IBM_THREAD_GONE	0x00000004  	/* Set if thread actually gone.
					 * IbmFlushState then destroys the
					 * thread descriptor (assuming it's
					 * been removed from the patient's
					 * list). Needed to handle getting
					 * a reset during an exit... */
#define KRES_KDATA  	1
#define KRES_KCODE  	2
#define KRES_KROUT  	3
#define KRES_KINIT  	4
#define KRES_DOS    	5
#define KRES_SWAT   	6
#define KRES_BIOS  	7
#define KRES_PSP    	8

extern Lst  	    allThreads;
extern ThreadPtr    realCurThread;

/*
 * Cache definitions
 */
extern int  	bytesFromPC;	    /* Total number of bytes read from
				     * the PC */
extern int  	bytesFromCache;     /* Number of bytes read from the cache */
extern int  	bytesToPC;	    /* Total number of bytes written to
				     * the PC */
extern int  	bytesToCache;	    /* Number of bytes written into the cache*/
extern int  	cacheRefs;	    /* Number of times the cache was
				     * examined */
extern int  	cacheHits;	    /* Number of times the block was found
				     * in the cache. */

extern int  	cacheBlockSize;     /* Current size of blocks to be cached.
				     * may only be changed when Cache_Size is
				     * 0 */
extern Cache	dataCache;  	    /* Block cache */
/*
 * Structure used as the key for the cache.
 */
typedef struct {
    Handle  	  handle;
    Address 	  offset;
} IbmKey;

#define TAG_DCBLOCK (TAG_CBLOCK+128)	/* Tag for dirty cache blocks */

/*
 * Routines exported by ibm.c to ibm*.c ONLY
 */
extern void 	IbmDisconnect(Rpc_Proc	procNum);
extern Boolean 	IbmReadThreadRegister(ThreadPtr	    thread,
				      RegType	    regType,
				      int   	    regNum,
				      regval        *valuePtr);
extern Boolean  IbmReadThreadRegister16(
                      ThreadPtr	    thread,
		      RegType	    regType,
		      int   	    regNum,
		      word        *valuePtr) ;
extern int  	IbmSetDir();
extern void 	IbmInitKernel();
extern void 	IbmCheckPatient(Patient patient);
extern Boolean	IbmOpenObject(Patient patient, GeodeName *gnp, char *name,
			      word coreID);
extern void 	IbmEnsureObject(Patient patient);
extern void 	IbmEnsureClosed(Patient patient);
extern Patient	IbmFindOtherInstance(GeodeName	    *gnPtr,
				     Patient	    notThis,
				     int   	    *nPtr);
extern int  	IbmFindLRes(const char *name);
/*
 * Routines exported from ibmCmd.c to ibm.c ONLY
 */
extern void 	IbmCreateAlias(char *name);
extern void 	IbmDestroyAlias(char *name);
#endif /* _IBMINT_H_ */
