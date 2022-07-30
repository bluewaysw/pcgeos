/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Communications protocol definitions
 * FILE:	  rpc.h
 *
 * AUTHOR:  	  Adam de Boor: Aug  9, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 9/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Protocol structure definitions to be included by both the stub
 *	and Swat.
 *
 *	NOTE: If the structures change, the Type descriptions in the
 *	various modules (ibm.c, atron.c, handle.c) must also be updated.
 *
 *	NOTE: Any use of LONGs in the protocol *must* be aligned on a
 *	longword boundary w/in the structure or the stub and Swat will
 *	be using different structures when Swat is run on a Sparc,
 *	which will pad the structure to align the LONG field.
 *
 * 	$Id: rpc.h,v 4.30 97/05/23 08:26:13 weber Exp $
 *
 ***********************************************************************/

#ifndef _RPC_H_
#define _RPC_H_ 1

/* START C DEFINITIONS */
/*
 * Any C preprocessor defines or C type definitions that should not also
 * be in rpc.def must be placed between comment lines containing
 * "START C DEFINITIONS" and "END C DFEINITIONS".
 */

#if defined(_MSC_VER)
/* We must have our structures be exact and not aligned to 8 bytes */
#pragma pack(push, 2)
#endif
#if defined(__WATCOMC__)
#pragma pack(push, 2)
#endif

/*
 * Macros for defining the structures
 */

#define STRUCT(name)	typedef struct name {
#define BYTE(field)	unsigned char field;
#define WORD(field)	unsigned short field;
#define LONG(field)	unsigned long field;
#define BYTEA(field,sz)	unsigned char field[sz];
#define WORDA(field,sz)	unsigned short field[sz];
#define LONGA(field,sz)	unsigned long field[sz];
#define FSTRUC(field,type) type field;
#define ENDST(name)	} name;

#if defined(_WIN32)
# include <time.h>
#else
# include    <sys/time.h>
#endif

#include    <objfmt.h>

#if defined(_MSDOS) || defined(_WIN32)
struct timeval {
    long    tv_sec; 	    /* seconds */
    long    tv_usec;	    /* and microseconds */
};

/*
 * Operations on timevals.
 *
 * NB: timercmp does not work for >= or <=.
 */
#define timerisset(tvp)         ((tvp)->tv_sec || (tvp)->tv_usec)
#define timercmp(tvp, uvp, cmp) \
        (((tvp)->tv_sec cmp (uvp)->tv_sec) || \
         (((tvp)->tv_sec == (uvp)->tv_sec) && \
	  ((tvp)->tv_usec cmp (uvp)->tv_usec)))
#define timerclear(tvp)         (tvp)->tv_sec = (tvp)->tv_usec = 0
#endif

/*
 * Boolean arguments
 */

#ifndef Boolean
#define Boolean	  int
#endif Boolean

/*
 * Flags for Rpc_Watch
 */
#define RPC_READABLE	1
#define RPC_WRITABLE	2
#define RPC_EXCEPTABLE	4

/*
 * Rpc_Debug flags
 */
#define RD_STREAM   	0x0001	    /* Tell about stream readiness */
#define RD_EVENT_QUEUE 	0x0002	    /* Tell about queueing and deleting events*/
#define RD_EVENT_TAKEN	0x0004	    /* Tell about events being taken */
#define RD_CALL	    	0x0008	    /* Tell about our calling */
#define RD_SERVE    	0x0010	    /* Tell about our servers */
#define RD_PACKET   	0x0020	    /* Tell about packet stuff */
#define RD_NO_TIMEOUT	0x0040	    /* Resend calls forever */
#define RD_CACHE    	0x0080	    /* Tell about server cache */

#define RETRY_SEC   	1
#define RETRY_USEC  	0
#define NUM_RETRIES 	2

typedef unsigned short 	Rpc_Proc;
typedef void 	  	*Rpc_Opaque;

typedef Rpc_Opaque  	Rpc_Event;  	/* Type returned by Rpc_EventCreate */
typedef Rpc_Opaque  	Rpc_Message;	/* Handle for replying to a call */
typedef byte		Rpc_Stat;   	/* Call status */

/*
 * communications modes
 */
#define CM_NONE      	0
#define CM_SERIAL    	1
#define CM_NETWARE   	2
#define CM_NPIPE     	3
#define CM_SERIAL_TCP   4

/*
 * Function definitions for Swat
 */
extern Rpc_Stat Rpc_Call (Rpc_Proc rpcNum,
			  int inLength, Type inType, Opaque inData,
			  int outLength, Type outType, Opaque outData);
extern void	Rpc_Init (int *argcPtr, char **argv);
extern void	Rpc_Exit (Rpc_Proc exitRpcNum);
extern Boolean	Rpc_Connect (void);
extern Boolean	Rpc_Disconnect (int wakeup);

extern void	Rpc_ServerCreate (Rpc_Proc num,
				  void (*serverProc) (Rpc_Message msg,
						      int dataLen,
						      Rpc_Opaque data,
						      Rpc_Opaque clientData),
				  Type argType,
				  Type replyType,
				  Rpc_Opaque clientData);
extern void	Rpc_ServerDelete (Rpc_Proc num);
extern Rpc_Event Rpc_EventCreate (struct timeval *interval,
				  Boolean (*eventProc) (Rpc_Opaque clientData,
							Rpc_Event event),
				  Rpc_Opaque clientData);
extern void	Rpc_EventDelete (Rpc_Event event);
extern void	Rpc_EventReset (Rpc_Event event, struct timeval *interval);
extern void	Rpc_Watch (int stream, int state,
			   void (*streamProc) (int stream,
					       Rpc_Opaque clientData,
					       int state),
			   Rpc_Opaque clientData);
extern void	Rpc_Ignore (int stream);
extern void	Rpc_Error (Rpc_Message msg, Rpc_Stat error);
extern void	Rpc_Return (Rpc_Message msg, int replyLen, Rpc_Opaque reply);
extern void	Rpc_Abort (void);
extern Address  Rpc_IndexToOffset(Patient patient, word index, ObjSym *s);
extern void	Rpc_Wait (void);
extern void	Rpc_Poll (void);
extern void	Rpc_Run (void);
extern void	Rpc_Debug (int debug);
extern char 	*Rpc_ErrorMessage (Rpc_Stat status);
extern char 	*Rpc_LastError (void);

extern	void	Rpc_Rs(void);
extern	void	Rpc_Rss(void);
extern	void	Rpc_Rssn(void);
extern	void	Rpc_Rsn(void);

extern  int 	Rpc_ReadFromGeode(Patient patient, dword offset, word size,
				    	    word dataType, char *buf,
				    	    word dataValue1, word dataValue2);

extern void 	Rpc_Push(int stream);
extern Boolean 	Rpc_Pop(int stream);

#if defined(_WIN32)
extern Boolean  Rpc_NtserialInit(const char *tty);
#endif

/*
 * C defines REGS_32, while assembly defines _Regs_32.  We define and use the
 * assembly version here so we don't have to pull any (other) ugly tricks in
 * the rpc.sed script.  So, make sure you use the assembly define from hereon.
 */
#if REGS_32
#define _Regs_32 1
#else
#define _Regs_32 0
#endif

#if _Regs_32
int RegisterMapping(int regIndex) ;  /* Convert REG_AX types to reg_ax types */
#else
#define RegisterMapping(regIndex)  (regIndex)
#endif

#define Reg32(regarray, index)  *((dword *)&((regarray).reg_regs[index]))

/* END C DEFINITIONS */

#define True	  1
#define False	  0

/*
 * Special handle ID's. Used mostly by Swat itself, not the stub.
 */
#define HID_KTHREAD 	0
#define HID_KCODE   	1
#define HID_KINIT   	2
#define HID_KDATA   	16
#define HID_DOS	    	4
#define HID_SWAT    	5
#define HID_BIOS   	6
#define HID_PSP	    	7
#define HID_KROUT   	8

#define RPC_SUCCESS	0	    	/* Call succeeded, here's reply data */
#define RPC_CANTSEND	1	    	/* Couldn't send message, for some
					 * reason */
#define RPC_TIMEDOUT	2  	    	/* Message timed out */
#define RPC_TOOBIG	3  	    	/* Results (or message) too big */
#define RPC_NOPROC	4	  	/* No such procedure on remote
					 * machine */
#define RPC_ACCESS	5	  	/* Permission denied */
#define RPC_BADARGS	6  	    	/* Arguments were improper */
#define RPC_SYSTEMERR	7	    	/* Undefined system error */
#define RPC_SWAPPED 	8   	    	/* Data are swapped and can't be
					 * brought in */
#define RPC_NOHANDLE	9   	    	/* No such handle */
#define RPC_NOTATTACHED	10  	    	/* Not attached to PC */
#define RPC_INCOMPAT	11  	    	/* Target PC is incompatible, somehow */

/*
 * Protocol revision number. Swat will refuse to connect to a stub of a
 * lower revision number than this.
 */
#define RPC_REVISION1	16  /* Revision for Release 1 */
#define RPC_REVISION	24

/*
 * Each RPC call and reply consists of a header and data.
 *
 * The header contains bookkeeping info along with the number of bytes of data
 * that follow. The data are padded to a word boundary to make access of
 * parameters as efficient as possible. 
 *
 * All data are sent in the PC's byte-order (little endian)
 */
#define RPC_CALL  1    	    	/* Message is a call */
#define RPC_REPLY 2    	    	/* Message is a reply */
#define RPC_ERROR 4    	    	/* Message is an error reply. reply data is
				 * status code */
#define RPC_ACK	  8    	    	/* Message is an explicit acknowledge */
STRUCT(RpcHeader)
    BYTE(rh_flags)	    /* Flags for the message */
    BYTE(rh_procNum)	    /* Procedure called */
    BYTE(rh_length)	    /* Number of bytes of parameters */
    BYTE(rh_id)	  	    /* Sequence number */
ENDST(RpcHeader)

#define RPC_MAX_DATA	255

/*
 * Link-level framing constants. Each message begins with RPC_MSG_START
 * and ends with RPC_MSG_END. Any occurrence of these characters within
 * the message itself is quoted with RPC_MSG_QUOTE, followed by either
 * RPC_MSG_QUOTE_START or RPC_MSG_QUOTE_END. RPC_MSG_QUOTE itself is quoted
 * by the two-byte sequence RPC_MSG_QUOTE RPC_MSG_QUOTE_QUOTE.
 */
#define RPC_MSG_START	0x10 	/* Start-of-message byte */
#define RPC_MSG_END 	0x11 	/* End-of-message byte */
#define RPC_MSG_QUOTE	0x12 	/* Lead byte for 2-byte quote sequence */
#define RPC_MSG_QUOTE_START 'S'
#define RPC_MSG_QUOTE_END   'E'
#define RPC_MSG_QUOTE_QUOTE 'Q'

/*
 * Register structure transmitted by the PC
 */

#if _Regs_32
#define REG_NUM_REGS	22  	/* Number of "general" registers */

#define reg_ax	  	0
#define reg_eax         0

#define	reg_cx	  	4
#define reg_ecx         4

#define	reg_dx	  	8
#define reg_edx         8

#define reg_bx	  	12
#define reg_ebx         12

#define reg_sp	  	16
#define reg_esp         16

#define reg_bp	  	20
#define reg_ebp         20

#define reg_si	  	24
#define reg_esi         24

#define	reg_di	  	28
#define reg_edi         28

#define reg_es	  	32
#define reg_cs	  	34
#define reg_ss	  	36
#define reg_ds	  	38
#define reg_fs          40
#define reg_gs          42

STRUCT(IbmRegs)
    WORDA(reg_regs, REG_NUM_REGS)/* General registers */
    WORD(reg_ip)	    	/* IP */
    LONG(reg_eflags)	    	/* Flags register */
    WORD(reg_xipPage)	    	/* current xip page for thread */
ENDST(IbmRegs)

#else
#define REG_NUM_REGS	12  	/* Number of "general" registers */

#define reg_ax	  	0
#define	reg_cx	  	2
#define	reg_dx	  	4
#define reg_bx	  	6
#define reg_sp	  	8
#define reg_bp	  	10
#define reg_si	  	12
#define	reg_di	  	14

#define reg_es	  	16
#define reg_cs	  	18
#define reg_ss	  	20
#define reg_ds	  	22

STRUCT(IbmRegs)
    WORDA(reg_regs, REG_NUM_REGS)/* General registers */
    WORD(reg_ip)	    	/* IP */
    WORD(reg_flags)	    	/* Flags register */
    WORD(reg_xipPage)	    	/* current xip page for thread */
ENDST(IbmRegs)

#endif /* _Regs_32 */

/*
 * Initialization
 */
#define RPC_INIT_BASE	    0
#define RPC_BEEP	    (RPC_INIT_BASE)  /* Call sent to see if stub is
					      * awake. If so, returns the
					      * checksum for the loaded kernel
					      * as well as the revision for
					      * the stub (see RPC_REVISION) */
STRUCT(BeepReply1)  	    /* Reply to Release1XX RPC_BEEP */
    WORD(br1_csum)  	/* Kernel checksum */
    WORD(br1_rev)   	/* Stub revision */
ENDST(BeepReply1)

STRUCT(BeepReply)
    WORD(br_csum)   	    	/* Loader's checksum */
    WORD(br_rev)    	    	/* Stub revision */
    WORD(br_baseSeg)	    	/* Loader's base segment */
    WORD(br_stubSeg)	    	/* Physical base segment of stub code */
    WORD(br_stubSize)	    	/* Total size of stub code and stack */
    BYTE(br_stubType)	    	/* Type of stub (see STUB_ constants) */
#define STUB_EMS  	    0	/* Stub is in EMS board */
#define STUB_ATRON	    1	/* Stub is in ATRON board */
#define STUB_LOW  	    2	/* Stub is in low memory */
#define STUB_BSW    	    3	/* Stub is in special BSW debug board */
#define STUB_ZOOMER 	    4	/* Stub is for the Zoomer */
#define STUB_32BIT_REGS    0x80 /* Stub uses 32 bit registers */
#define STUB_GEOS32        0x40
#define STUB_TYPE_MASK      0x3F

    BYTE(br_kernelLoaded)    	/* Non-zero if kernel has been loaded */
    WORD(br_sysTablesOff)	/* Offset of DOS system table addresses */
    WORD(br_sysTablesSeg)	/* Segment of same. These are words to avoid
				 * padding by gcc */
    WORD(br_psp)    	    	/* Segment of PSP for kernel/stub */
    BYTE(br_mask1)  	    	/* Mask we're using for controller 1 */
    BYTE(br_mask2)  	    	/* Mask we're using for controller 2 */
    WORD(br_irqHandlers)    	/* Base of InterruptHandlers table */
#if GEOS32
    WORD(br_kstack)             /* Stack used by kernal loader */
    WORD(br_kstacksize)         /* size of Stack used by kernal loader */
    WORD(br_biosseg)            /* Selector to BIOS read only code memory */
#endif
ENDST(BeepReply)

#define RPC_HELLO	    (RPC_INIT_BASE+1)  /* Startup call sent after
						* KERNEL_LOAD received */

#define RPC_KERNEL_LOAD	    (RPC_INIT_BASE+2)  /* Call from stub to say kernel
						* is now resident. Passes
						* SpawnArgs */
STRUCT(HelloArgs1)
    WORD(ha1_kdata)	    	    /* Offset to variable segment */
    WORD(ha1_bootstrap)	    	    /* Bootstrapping, so no need to find
				     * threads and geodes */
    WORD(ha1_HandleTable)   	    /* Offset to HandleTable w/in kdata */
    WORD(ha1_currentThread) 	    /* Offset to currentThread variable */
    WORD(ha1_geodeListPtr)  	    /* Offset to geodeListPtr */
    WORD(ha1_threadListPtr)  	    /* Offset to threadListPtr */
    WORD(ha1_dosLock) 	    	    /* Offset to DOS lock */
    WORD(ha1_heapSem)	    	    /* Offset to Heap lock */
    WORD(ha1_lastHandle)    	    /* Offset to lastHandle */
    WORD(ha1_initSeg)    	    /* Offset to BG_initSegment */
    WORD(ha1_sysECLevel)    	    /* offset to sysECLevel */ 
    WORD(ha1_DebugLoadResource)     /* Offset of resource load vector */
    WORD(ha1_DebugMemory)   	    /* Offset of memory state change vector */
    WORD(ha1_DebugProcess)  	    /* Offset of process state change vector */
    WORD(ha1_MemLock)	    	    /* Offset to MemLock routine */
    WORD(ha1_EndGeos)	    	    /* Offset to EndGeos routine */
    WORD(ha1_BlockOnLongQueue)	    /* Offset to BlockOnLongQueue routine */
    WORD(ha1_FileRead)	    	    /* Offset to FileRead routine */
    WORD(ha1_FilePos)	    	    /* Offset to FilePos routine */
ENDST(HelloArgs1)

STRUCT(HelloArgs)
    WORD(ha_bootstrap)	    	    /* Bootstrapping, so no need to find
				     * threads and geodes */
    WORD(ha_currentThread) 	    /* Offset to currentThread variable */
ENDST(HelloArgs)

/*
 * Hello reply structures. Return buffer looks like this (Release1XX):
 *	HelloReply1
 *	Geode handle #1
 *	    .
 *	    .
 *	    .
 *	Geode handle #HelloReply1.hr1_numGeodes
 *	Thread handle #1
 *	    .
 *	    .
 *	    .
 *	Thread handle#HelloReply1.hr1_numThreads
 *
 * The RPC Module will swap the HelloReply1, but the caller will have to
 * swap the handle id's by hand, once the number is known.
 *
 * For Release2, the return buffer is simply a HelloReply structure.
 */
STRUCT(HelloReply1)
    WORD(hr1_baseSeg)	    	/* Physical base segment of kernel */
    WORD(hr1_initSeg)	    	/* Current physical base of initialization
				 * code seg (0 if initialization complete) */
    WORD(hr1_stubSeg)	    	/* Physical base segment of stub code */
    BYTE(hr1_stubType)	    	/* Type of stub (see STUB_ constants) */
    BYTE(hr1_pad) 	    	/* Padding (word-alignment) */
    WORD(hr1_numGeodes)	    	/* Number of geodes loaded */
    WORD(hr1_numThreads)    	/* Number of threads active */
    WORD(hr1_curThread)	    	/* Current thread ID */
    WORD(hr1_lastHandle)    	/* The offset of the last handle */
    WORD(hr1_sysTablesOff)	/* Offset of DOS system table addresses */
    WORD(hr1_sysTablesSeg)	/* Segment of same. These are words to avoid
				 * padding by gcc */
    WORD(hr1_psp)    	    	/* Segment of PSP for kernel/stub */
    BYTE(hr1_mask1)  	    	/* Mask we're using for controller 1 */
    BYTE(hr1_mask2)  	    	/* Mask we're using for controller 2 */
    WORD(hr1_irqHandlers)    	/* Base of InterruptHandlers table */
ENDST(HelloReply1)

STRUCT(HelloReply)
    WORD(hr_numGeodes)          /* Number of geodes loaded */
    WORD(hr_numThreads)         /* Number of threads active */
    WORD(hr_curThread)          /* Current thread ID */
    WORD(hr_kernelVersion)  	/* version of kernel */
    WORD(hr_curXIPPage)	    	    /* get current xip page on startup */
ENDST(HelloReply)

#define STUB_EMS  	    0	/* Stub is in EMS board */
#define STUB_ATRON	    1	/* Stub is in ATRON board */
#define STUB_LOW  	    2	/* Stub is in low memory */
#define STUB_BSW    	    3	/* Stub is in special BSW debug board */

#define RPC_MAX_HELLO	    RPC_MAX_DATA    	/* Largest reply for RPC_HELLO*/

#define RPC_GOODBYE1 	    (RPC_INIT_BASE+2) 	/* Detach from the PC. Replaces
						 * vectors, etc. */
#define RPC_GOODBYE 	    (RPC_INIT_BASE+3) 	/* Detach from the PC. Replaces
						 * vectors, etc. */

#define RPC_EXIT1    	    (RPC_INIT_BASE+3) 	/* Detach from the PC and go
						 * back to MS-DOS. Also sent
						 * by Stub if kernel exits. */
#define RPC_EXIT    	    (RPC_INIT_BASE+4) 	/* Detach from the PC and go
						 * back to MS-DOS. Also sent
						 * by Stub if kernel exits. */

#define RPC_RELOAD_SYS1	    (RPC_INIT_BASE+4) 	/* Kernel being reloaded after
						 * running a DOS app */
#define RPC_RELOAD_SYS	    (RPC_INIT_BASE+5) 	/* Kernel being reloaded after
						 * running a DOS app */

#define RPC_DOS_RUN1 	    (RPC_INIT_BASE+5)	/* Exiting to DOS for a bit */
#define RPC_DOS_RUN 	    (RPC_INIT_BASE+6)	/* Exiting to DOS for a bit */

#define	RPC_SETUP   	    (RPC_INIT_BASE+7) 	/* set up table of offsets */

STRUCT(SetupReplyArgs)
    WORD(sa_kernelHasTable) 	    /* this tells us if its an old kernel */
    WORD(sa_tableSize)	    	    /* size of the table */
    WORD(sa_currentThread)
    WORD(sa_geodeListPtr)
    WORD(sa_threadListPtr)
    WORD(sa_biosLock)
    WORD(sa_heapSem)
    WORD(sa_DebugLoadResource)
    WORD(sa_DebugMemory)
    WORD(sa_DebugProces)
    WORD(sa_MemLock)
    WORD(sa_EndGeos)
    WORD(sa_BlockOnLongQueue)
    WORD(sa_FileReadFar)
    WORD(sa_FilePosFar)
    WORD(sa_sysECBlock)
    WORD(sa_sysECChecksum)
    WORD(sa_sysECLevel)
    WORD(sa_systemCounter)	    /* Offset to systemCounter */
    WORD(sa_errorFlag)
    WORD(sa_ResourceCallInt)  	    /* Offset to ResourceCallInt */
    WORD(sa_ResourceCallInt_end)  	    /* Offset to ResourceCallInt */
    WORD(sa_FatalError)	    	    /* Offset to FatalError */
    WORD(sa_FatalError_end)
    WORD(sa_SendMessage)    	    /* Offset to SendMessage */
    WORD(sa_SendMessage_end)	    /* etc etc etc etc etc */
    WORD(sa_CallFixed)	    
    WORD(sa_CallFixed_end)
    WORD(sa_ObjCallMethodTable)
    WORD(sa_ObjCallMethodTable_end)	   
    WORD(sa_CallMethodCommonLoadESDI)	
    WORD(sa_CallMethodCommonLoadESDI_end)	
    WORD(sa_ObjCallMethodTableSaveBXSI)	
    WORD(sa_ObjCallMethodTableSaveBXSI_end)	
    WORD(sa_CallMethodCommon)	
    WORD(sa_CallMethodCommon_end)	
    WORD(sa_MessageDispatchDefaultCallBack)	    	
    WORD(sa_MessageDispatchDefaultCallBack_end)	    	
    WORD(sa_MessageProcess)	    	
    WORD(sa_MessageProcess_end)	    	
    WORD(sa_OCCC_callInstanceCommon)	    	
    WORD(sa_OCCC_callInstanceCommon_end)	    	
    WORD(sa_OCCC_no_save_no_test)	    	
    WORD(sa_OCCC_no_save_no_test_end)	    	
    WORD(sa_OCCC_save_no_test)	    	
    WORD(sa_OCCC_save_no_test_end)
    WORD(sa_Idle)
    WORD(sa_Idle_end)
    WORD(sa_curXIPPage)
    WORD(sa_MapXIPPageFar)
    WORD(sa_MAPPING_PAGE_SIZE)
    WORD(sa_MAPPING_PAGE_ADDRESS)
ENDST(SetupReplyArgs)

/*
 * Continuation calls
 */
#define RPC_CNT_BASE	    16
    
#define RPC_CONTINUE        (RPC_CNT_BASE+1) /* Continue machine
					     * unconditionally. Takes a word
					     * argument giving the state of
					     * the timer interrupt mask bit.
					     */

#define RPC_STEP 	    (RPC_CNT_BASE+3) /* Execute a single instruction in
					     * the current thread. */
STRUCT(StepReply)
    FSTRUC(sr_regs,IbmRegs) 	/* Current registers */
    WORD(sr_thread) 	    	/* Current thread (just to make sure) */
    WORD(sr_curXIPPage)
ENDST(StepReply)

#define RPC_SKIPBPT 	    (RPC_CNT_BASE+4) /* Execute a single instruction
					     * in the current thread, storing
					     * an INT 3 at its start when
					     * the instruction has executed.
					     * Continue the machine afterward.
					     * Word argument is breakpoint
					     * number to skip.
					     */
/*
 * Register access
 */
#define RPC_REG_BASE	    32
#define RPC_READ_REGS	    (RPC_REG_BASE)  /* Read all registers for the
					     * given thread (handle is arg,
					     * IbmRegs is result) */

#define RPC_WRITE_REGS	    (RPC_REG_BASE+1) /* Write all registers for
					     * thread (handle and IbmRegs
					     * are args) */
STRUCT(WriteRegsArgs)
    WORD(wra_thread)	    	/* Thread whose registers are to be written */
    FSTRUC(wra_regs,IbmRegs)	/* Registers to write */
ENDST(WriteRegsArgs)

#define RPC_READ_FPU	    (RPC_REG_BASE+2) /* Read all the FPU registers */

STRUCT(CoprocRegs)
    WORD(cr_control)
    WORD(cr_status)
    WORD(cr_tag)
    WORD(cr_ip)
    WORD(cr_opAndHighIP)
    WORD(cr_dp)
    WORD(cr_highDP)
    WORDA(cr_stack,40)      /* The stack, from ST(0) to ST(7) */
ENDST(CoprocRegs)

#define RPC_WRITE_FPU	    (RPC_REG_BASE+3)/* Write all the FPU registers */

/*
 * Memory access
 */
#define RPC_MEM_BASE	    48
#define RPC_READ_MEM	    (RPC_MEM_BASE)  /* Read memory. Handle, offset and
					     * 16-bit length are args. No more
					     * than 512 bytes of data may be
					     * read at a time. */

STRUCT(ReadArgs)  	    /* Args for reading handle memory */
    WORD(ra_offset)	    	/* Offset in block to access */
    WORD(ra_handle)	    	/* Handle of data. Should be swapped in
				 * if necessary and possible. If block has been
				 * discarded or can't be swapped in, return
				 * error. */
    WORD(ra_numBytes)	    	/* Number of bytes to read */
ENDST(ReadArgs)

#define RPC_WRITE_MEM	    (RPC_MEM_BASE+1) /* Write memory. Handle, offset
					     * and 16-bit length are args.
					     * No more than 512 bytes of
					     * data may be written at once */

STRUCT(WriteArgs) 	    /* Args for writing to handle memory. Number
			     * of bytes indicated by length of RPC */
    WORD(wa_offset)	    	/* Offset in block to access */
    WORD(wa_handle)	    	/* Handle for data */
ENDST(WriteArgs)

#define RPC_FILL_MEM8	    (RPC_MEM_BASE+2) /* Fill memory. handle/offset,
					     * 16-bit length and fill byte are
					     * args. */
#define RPC_FILL_MEM16	    (RPC_MEM_BASE+3) /* Fill memory. handle/offset,
					     * 16-bit length and fill word are
					     * args */

STRUCT(FillArgs)
    WORD(fa_offset)	    	/* Offset in block */
    WORD(fa_handle)	    	/* Handle of data */
    WORD(fa_length)	    	/* Number of bytes/words to fill */
    WORD(fa_value) 	    	/* Value for filling (in low byte if byte
				 * fill) */
ENDST(FillArgs)

#define RPC_READ_IO8	    (RPC_MEM_BASE+4) /* Read from 8-bit I/O port. Arg
					     * is port number. Reply is
					     * zero-extended value */
#define RPC_READ_IO16	    (RPC_MEM_BASE+5) /* Read from a 16-bit I/O port.
					     * Arg is port number. Reply is
					     * 16-bit value */
#define RPC_WRITE_IO8	    (RPC_MEM_BASE+6) /* Write to an 8-bit I/O port.
					     * Args are port number and value*/
#define RPC_WRITE_IO16	    (RPC_MEM_BASE+7)  /* Write to a 16-bit I/O port. */
STRUCT(IoWriteArgs)
    WORD(iow_port)	    	/* Port to write */
    WORD(iow_value)	    	/* Use low 8-bits for 8-bit write */
ENDST(IoWriteArgs)

#define RPC_READ_ABS	    (RPC_MEM_BASE+8) /* Read from absolute memory
					     * location. Data returned as
					     * for RPC_READ_MEM */
STRUCT(AbsReadArgs)
    WORD(ara_offset)	    	/* Offset into segment */
    WORD(ara_segment)	    	/* Segment from which to read */
    WORD(ara_numBytes)	    	/* Number of bytes to read */
ENDST(AbsReadArgs)

#define RPC_WRITE_ABS	    (RPC_MEM_BASE+9) /* Write to absolute memory
					     * location. Args are segment/offset
					     * followed by bytes to
					     * write. Number of bytes implied
					     * by RPC length */
STRUCT(AbsWriteArgs)
    WORD(awa_offset)	    	/* Offset into segment */
    WORD(awa_segment)	    	/* Segment to which to write */
ENDST(AbsWriteArgs)

#define RPC_FILL_ABS8	    (RPC_MEM_BASE+10) /* Fill memory. Segment/offset,
					     * 16-bit length and fill byte are
					     * args. */
#define RPC_FILL_ABS16	    (RPC_MEM_BASE+11) /* Fill memory. Segment/offset,
					     * 16-bit length and fill word are
					     * args */
STRUCT(AbsFillArgs)
    WORD(afa_offset)	    	/* Offset to which to write */
    WORD(afa_segment)	    	/* Segment to which to write */
    WORD(afa_length)	    	/* Number of bytes/words to fill */
    WORD(afa_value)	    	/* Value with which to fill (in low byte
				 * if byte fill) */
ENDST(AbsFillArgs)

/*
 * Block Info
 *
 * For BLOCK_LOAD, BLOCK_OUT, BLOCK_MOVE, and BLOCK_CHANGE, the machine
 * may continue once the RPC has returned.
 */
#define RPC_BLK_BASE	    64
#define RPC_BLOCK_LOAD	    (RPC_BLK_BASE)  /* A flagged block has been
					     * (re)loaded. Passes handle and
					     * segment address for block.
					     * Issued in response to a
					     * DEBUG_SWAPIN call to
					     * DebugMemory */
STRUCT(LoadArgs)
    WORD(la_handle)	    /* Handle swapped in */
    WORD(la_dataAddress)    /* New address */
ENDST(LoadArgs)

#define RPC_RES_LOAD	    (RPC_BLK_BASE+1) /* A module has been loaded. Args
					     * are as for BLOCK_LOAD.
					     * Issued in response to a
					     * DebugLoadResource call */

#define RPC_BLOCK_MOVE	    (RPC_BLK_BASE+2) /* A block has moved on the heap.
					     * Passes handle and new segment
					     * address. Issued in response to
					     * a DEBUG_MOVE call to
					     * DebugMemory. */
STRUCT(MoveArgs)
    WORD(ma_handle)	    /* Handle moved */
    WORD(ma_dataAddress)    /* New address */
ENDST(MoveArgs)

#define RPC_BLOCK_OUT	    (RPC_BLK_BASE+3) /* A block has been thrown out.
					     * Passes handle and a byte that
					     * is non-zero if the block was
					     * discarded. Issued in response to
					     * either a DEBUG_DISCARD or a
					     * DEBUG_SWAPOUT call to
					     * DebugMemory. */
STRUCT(OutArgs)
    WORD(oa_handle)	    /* Handle swapped out */
    WORD(oa_discarded)	    /* Non-zero if discarded */
ENDST(OutArgs)

#define RPC_BLOCK_REALLOC   (RPC_BLK_BASE+4) /* A block has been reallocated.
					     * Passes handle, seg addr and new
					     * paragraph size. Issued in
					     * response to a DEBUG_REALLOC
					     * call to DebugMemory */
STRUCT(ReallocArgs)
    WORD(rea_handle)
    WORD(rea_dataAddress)
    WORD(rea_paraSize)
ENDST(ReallocArgs)

#define RPC_BLOCK_FREE	    (RPC_BLK_BASE+5) /* Handle has been freed. Arg is
					     * handle ID. Issued in response to
					     * a DEBUG_FREE call to
					     * DebugMemory. */

#define RPC_BLOCK_FIND	    (RPC_BLK_BASE+6) /* Find the handle that
					     * encompasses the given segment.
					     * Arg is 16-bit segment. Reply is
					     * handle id and structure. Sought
					     * handles are marked as debugged.
					     */

STRUCT(FindArgs)
    WORD(fa_address)	    /* segment address to find */
    WORD(fa_xipPage)	    /* xip page to consider mapped in */
ENDST(FindArgs)

STRUCT(FindReply)
    WORD(fr_id)	  	    /* Handle ID */
    /*
     * Actual handle structure
     */
    WORD(fr_dataAddress)    /* Data address */
    WORD(fr_paraSize)	    /* Size of data block (paragraphs) */
    WORD(fr_owner)	    /* Handle of owning process */
    WORD(fr_otherInfo)	    /* otherInfo field */
    BYTE(fr_flags) 	    /* Handle flags */
    BYTE(fr_pad)    	    /* Padding for word alignment */
    WORD(fr_xipPage)	    /* page number if an xip handle, else -1 */
ENDST(FindReply)

#define RPC_BLOCK_INFO	    (RPC_BLK_BASE+7) /* Read a handle's state. Arg is
					     * handle ID. Return is InfoReply.
					     */
/*
 * If requested handle is a thread handle, ir_paraSize contains the max
 * SP for the thread, with ir_otherInfo being the SS for the thread; ir_flags
 * is undefined.
 */
STRUCT(InfoReply)
    WORD(ir_dataAddress)    /* Data address */
    WORD(ir_paraSize)	    /* Size of data block (paragraphs) */
    WORD(ir_owner)	    /* Handle of owning process */
    WORD(ir_otherInfo)	    /* otherInfo field */
    BYTE(ir_flags) 	    /* Handle flags */
    BYTE(ir_pad)    	    /* Padding for word alignment */
    WORD(ir_xipPage)	    /* page number if an xip handle, else -1 */
ENDST(InfoReply)

#define RPC_BLOCK_ATTACH    (RPC_BLK_BASE+8) /* Attach to a handle, causing
					     * the new state of the handle to
					     * be transmitted when it changes.
					     * Arg is handle id. */

#define RPC_BLOCK_DETACH    (RPC_BLK_BASE+9) /* Opposite of ATTACH */

/*
 * Thread manipulation.
 */
#define RPC_THD_BASE	    80
#define RPC_SPAWN	    (RPC_THD_BASE)  /* A thread has spawned a new
					     * thread, or a driver/library
					     * has been loaded. Passes new
					     * thread handle (0 for d/l) and
					     * its owner */
STRUCT(SpawnArgs)
    WORD(sa_thread) 	    /* New thread/current thread for d/l */
    WORD(sa_owner)  	    /* Owner of new thread */
    WORD(sa_ss)	    	    /* Initial SS for new thread (0 for appl thread
			     * and for d/l load) */
    WORD(sa_sp)	    	    /* Initial SP for new thread (junk for appl thread,
			     * 0 for d/l load) */
    WORD(sa_xipPage)	    /* current xip page at time of spawn */
ENDST(SpawnArgs)

#define RPC_THREAD_EXIT	    (RPC_THD_BASE+1) /* A thread has exited. Passes
					      * the thread handle and exit
					      * status */
STRUCT(ThreadExitArgs)
    WORD(tea_handle) 	    /* Thread handle. */
    WORD(tea_status) 	    /* Exit status/current thread (for d/l) */
ENDST(ThreadExitArgs)

#define RPC_GEODE_EXIT	    (RPC_THD_BASE+2) /* A geode has exited. Passes
					      * handle of exiting geode and
					      * handle of current thread.
					      * NOTE: For a process, this will
					      * come before the THREAD_EXIT for
					      * the last thread. */
STRUCT(GeodeExitArgs)
    WORD(gea_handle)	    /* Geode handle */
    WORD(gea_curThread)	    /* Current thread */
ENDST(GeodeExitArgs)

/*
 * HALT definitions
 */
#define RPC_HLT_BASE	    96
#define RPC_HALT     	    (RPC_HLT_BASE)  /* Machine stopped for some reason.
					     * Args are an IbmRegs structure
					     * with the registers at the time
					     * of the halt,  a word indicating
					     * the reason for the stop, and a
					     * word giving the thread that was
					     * active. These codes
					     * correspond to the actual
					     * interrupt generated by the
					     * exception condition. In the case
					     * of other intercepted interrupts,
					     * the interrupt number will be
					     * passed. */

STRUCT(HaltArgs)
    WORD(ha_thread) 	    	/* Thread in which it stopped */
    FSTRUC(ha_regs,IbmRegs) 	/* Active registers */
    WORD(ha_reason)    	    	/* Why machine halted: */
    WORD(ha_curXIPPage)	    	/* current XIP page, -1 if not applicable */
ENDST(HaltArgs)

#define RPC_HALT_DIV0	    0	    /* Divide-by-zero */
#define RPC_HALT_STEP	    1	    /* Single-step complete. */
#define RPC_HALT_NMI	    2	    /* NMI recognized */
#define	RPC_HALT_BPT	    3	    /* Processor hit a breakpoint. */
#define RPC_HALT_INTO	    4	    /* Overflow interrupt */
#define RPC_HALT_BOUND	    5	    /* Bound error */
#define RPC_HALT_ILLINST    6	    /* Illegal instruction */
#define RPC_HALT_PEXT	    7	    /* Processor extension not present */
#define RPC_HALT_DCHECK     8	    /* Double-check fault */
#define RPC_HALT_PEXTERR    9	    /* Processor extension overrun */
#define RPC_HALT_INVTSS    10	    /* Invalid task-state-segment */
#define RPC_HALT_NOSEG	   11	    /* Segment not present */
#define RPC_HALT_SSOVER    12	    /* Stack segment overrun or absent */
#define RPC_HALT_GP	   13	    /* General protection fault */

#define RPC_MASK 	    (RPC_HLT_BASE+1) /* Gives two bytes of mask for
					     * the interrupt controllers while
					     * the system is halted. I.e.
					     * enables interrupts to occur
					     * while the stub is awaiting
					     * a command */
STRUCT(MaskArgs)
    BYTE(ma_PIC1) 	    	/* Mask for controller 1 */
    BYTE(ma_PIC2) 	    	/* Mask for controller 2 */
ENDST(MaskArgs)

#define RPC_INTERRUPT	    (RPC_HLT_BASE+2) /* Stop the machine! */

#define RPC_CBREAK  	    (RPC_HLT_BASE+3) /* Set a conditional breakpoint.
					     * UNIX side is responsible for
					     * changing the instruction...
					     * Returns the breakpoint #
					     * (always non-zero) */
/*
 * cb_thread must come before cb_regs b/c the IbmRegs structure in HaltArgs
 * has reg_ip and reg_flags following the 12 general registers. Putting
 * cb_thread first makes for grossness up on unix and cleanliness down on
 * the pc...
 */
STRUCT(CBreakArgs)
    WORD(cb_ip)	    	    /* IP for breakpoint */
    WORD(cb_cs)	    	    /* CS for breakpoint */
#if _Regs_32
    BYTEA(cb_comps,12)
#else
    BYTEA(cb_comps,7)	    /* Comparisons. These are four bits for each
			     * field being compared. The four bits encode
			     * the type of comparison to be performed and come
			     * from the low four bits of the Jcond instruction.
			     * The bits actually encode the inverse of the
			     * comparison... 0 implies the value is
			     * uninteresting. */
    BYTE(cb_pad)    	    /* Padding for Sparc... */
#endif
    WORD(cb_thread) 	    /* Thread handle active */
    WORDA(cb_regs,REG_NUM_REGS) /* Registers for comparison */
/* Stuff for memory word comparison */
    WORD(cb_value)  	    /* Value against which word is to be compared.
			     * Placed before seg:off to allow reference
			     * via cb_regs... */
    WORD(cb_off)    	    /* Offset of word for comparison */
    WORD(cb_seg)    	    /* Segment of word for comparison */
    WORD(cb_xipPage)	    /* xip page of handle */
ENDST(CBreakArgs)
    
#define RPC_NOCBREAK	    (RPC_HLT_BASE+4) /* Clear conditional breakpoint.
					     * Pass breakpoint # returned by
					     * CBREAK */

#define RPC_CHGCBREAK	    (RPC_HLT_BASE+5) /* Change the criteria of a
					      * conditional breakpoint */
STRUCT(ChangeCBreakArgs)
    WORD(ccba_num)  	    /* Breakpoint number */
    FSTRUC(ccba_crit,CBreakArgs)    /* New criteria */
ENDST(ChangeCBreakArgs)

#define RPC_SETTBREAK	    (RPC_HLT_BASE+6)	/* Set a tally breakpoint */
STRUCT(SetTBreakArgs)
    WORD(stba_ip)   	    /* IP for breakpoint */
    WORD(stba_cs)   	    /* CS for breakpoint */
    WORD(stba_xipPage)	    /* xip page */
ENDST(SetTBreakArgs)

STRUCT(SetTBreakReply)
    WORD(stbr_num)  	    /* Breakpoint number */
ENDST(SetTBreakReply)

#define RPC_GETTBREAK	    (RPC_HLT_BASE+7)	/* Fetch count for a tbrk.
						 * Arg is number returned by
						 * RPC_SETTBREAK, result is
						 * dword count */

#define RPC_ZEROTBREAK	    (RPC_HLT_BASE+8)	/* Reset the counter for a
						 * tally breakpoint. Arg is
						 * number returned by
						 * RPC_SETTBREAK */

#define RPC_CLEARTBREAK	    (RPC_HLT_BASE+9)	/* Clear a tally breakpoint.
						 * Arg is number returned by
						 * RPC_SETTBREAK */

#define RPC_SETTIMEBRK	    (RPC_HLT_BASE+10)	/* Set timing breakpoint.
						 * Return value is bp number */
STRUCT(SetTimeBrkArgs)
    WORD(stiba_ip)  	    /* IP for breakpoint */
    WORD(stiba_cs)  	    /* CS for breakpoint */
    WORD(stiba_xipPage)	    /* xip page */
    WORD(stiba_endIP)	    /* IP for ending breakpoint. If stiba_endHandle
			     * is 0, this is 0 if the routine is near, and
			     * non-zero if the routine is far. */
    WORD(stiba_endHandle)   /* Handle of block containing same. 0 if should
			     * run to completion of the routine */
ENDST(SetTimeBrkArgs)

#define RPC_CLEARTIMEBRK    (RPC_HLT_BASE+11)	/* Clear a timing breakpoint.
						 * Arg is the breakpoint
						 * number */

#define RPC_GETTIMEBRK	    (RPC_HLT_BASE+12)	/* Fetch the time accumulated
						 * for a timing breakpoint.
						 * Arg is the breakpoint number.
						 */
STRUCT(GetTimeBrkReply)
    WORD(gtbr_ticksLow)	/* Ticks */
    WORD(gtbr_ticksHigh)/* Ticks (cont) */
    WORD(gtbr_cus) 	/* Clock units (19886 per tick) */
    WORD(gtbr_countLow)	/* Times hit */
    WORD(gtbr_countHigh)/* Times hit (cont) */
ENDST(GetTimeBrkReply)

#define RPC_ZEROTIMEBRK	    (RPC_HLT_BASE+13)	/* Reset the accumulated time
						 * for the given timing break-
						 * point. Arg is the bp number*/

#define RPC_SETBREAK	    (RPC_HLT_BASE+14)	/* Set unconditional
						 * breakpoint. Returns bp
						 * number. */
STRUCT(SetBreakArgs)
    WORD(sba_ip)
    WORD(sba_cs)    	    /* handle if sba_xip != -1 */
    WORD(sba_xip)   	    /* -1 if not xip, xip page if in xip */
ENDST(SetBreakArgs)

#define RPC_CLEARBREAK	    (RPC_HLT_BASE+15)	/* Clear unconditional bp */

/*
 * Atron board definitions
 */
#define RPC_ATR_BASE	    112
#define RPC_TRACE_FETCH     (RPC_ATR_BASE)  /* Begin fetching trace records.
					     * The stub will send them up in
					     * 30-record chunks, calling
					     * RPC_TRACE_NEXT in Swat. */
#define RPC_TRACE_NEXT	    (RPC_ATR_BASE+1)/* Procedure called by the stub to
					     * transfer trace records up to Swat
					     * Server should return a single
					     * byte return value: 1 if more
					     * records are wanted, 0 if not. */
STRUCT(AtronTraceRecord)
    WORD(atr_addrLow)	    	/* Low 16 bits of address */
    WORD(atr_data)  	    	/* 16 bits of data */
    BYTE(atr_bus)  	    	/* Bus-control signals */
#define ATRB_DMA    	0x01   	    /* -DMA (DMA cycle) */
#define ATRB_MASTER 	0x02   	    /* -MASTER (Other bus master) */
#define ATRB_IOR    	0x04   	    /* -IOR (I/O read) */
#define ATRB_MRD	0x08   	    /* -MRD (memory read) */
#define ATRB_MWT    	0x10   	    /* -MWT (memory write) */    
#define ATRB_IOW    	0x20   	    /* -IOW (I/O write) */
#define ATRB_REFRESH	0x40	    /* REFRESH (memory-refresh cycle) */
#define ATRB_BHE    	0x80	    /* High byte of data bus valid */
    BYTE(atr_misc)  	    	/* Miscellaneous signals from coprocessor
				 * and board */
#define ATRM_S0	    	0x01	    /* S0 (queue status 0 -- not valid on
				     * all machines) */
#define ATRM_COD    	0x02	    /* COD/-INTA line from processor */
#define ATRM_S1	    	0x04	    /* S1 (queue status 1 -- not valid on all
				     * machines) */
#define ATRM_PEACK  	0x08	    /* Cycle on behalf of processor extension */
#define ATRM_RUN    	0x10	    /* Board in free-running mode */
#define ATRM_HWBP   	0x20	    /* Hardware breakpoint detected
				     * (unreliable) */
#define ATRM_MISCBP 	0x40	    /* Other breakpoint (stop button -- also
				     * unreliable) */
#define ATRM_IOCHK  	0x80	    /* -IOCHCHK (I/O channel check) */
    BYTE(atr_addrHigh)	    	/* High 8 bits of address */
    BYTE(atr_pad)   	    	/* Pad to word-boundary */
ENDST(AtronTraceRecord)

#define RPC_BRK_FILL	    (RPC_ATR_BASE+2)/* Fill a region of breakpoint
					     * RAM */
STRUCT(BrkFillArgs)
    LONG(bfa_addr)	    	/* Address to fill */
    WORD(bfa_length)	    	/* Number of bytes to fill */
    BYTE(bfa_value)	    	/* Byte to store */
    BYTE(bfa_pad)   	    	/* Padding for word alignment */
ENDST(BrkFillArgs)

#define RPC_BRK_WRITE	    (RPC_ATR_BASE+3)/* Write data to breakpoint RAM.
					     * Args are same as for writing
					     * regular RAM */


#define RPC_FILE_XFER	128 	/* file transfer routines */

#define FILE_XFER_BLOCK_SIZE	230

#define RPC_SEND_FILE			RPC_FILE_XFER
#define	FILE_XFER_SYNC				127
#define FILE_XFER_ERROR				001
#define FILE_XFER_RETRY				002
#define FILE_XFER_ERROR_DOS_SEM_TAKEN		003
#define FILE_XFER_ERROR_FILE_CREATE_FAILED	004
#define FILE_XFER_QUIT				120

#define RPC_SEND_FILE_NEXT_BLOCK 	    	RPC_FILE_XFER+1
/* since we sometimes try to get at data from geodes that are in the geo
 * file but not in the geodes resources (ie. file header and resource tables)
 * for XIPed geodes, this data must be gereated some other way, for the
 * resource tables we can just build out the table by going through the
 * handle table in the core block
 */


    /* udata can only be gotton  from a geo file, the load has no
     * geo file, and normal data for XIP geodes is always in memory
     * so no need to */
#define GEODE_DATA_UDATA_SIZE  	0   /* geode header stuff */
#define GEODE_DATA_LOADER   	1   /* a special case for the loader */
#define GEODE_DATA_OFFSETS  	2   /* get the resource offsets */

    /* leave a gap here in case we need to add any other non-geode cases */
#define GEODE_DATA_GEODE    	10   /* defines first real geode data value */
#define GEODE_DATA_FLAGS    	10   /* get the resource allocation flags */
#define GEODE_DATA_HEADER   	11   /* geode header stuff */
#define	GEODE_DATA_NORMAL   	12   /* get data from a geodes resource */

#define	RPC_READ_GEODE	RPC_SEND_FILE_NEXT_BLOCK+1
STRUCT(ReadGeodeArgs)
    WORD(RGA_size)  	    	    /* number of bytes to read */
    WORD(RGA_geodeHandle)    	    /* handle of geode used to get at */
    LONG(RGA_offset)	    	    /* file position to read from */
    WORD(RGA_dataType)	 	    /* type of data */
    WORD(RGA_dataValue1) 	    /* value depends on data type */
    WORD(RGA_dataValue2) 	    /* value depends on data type */
ENDST(ReadGeodeArgs)		    /* the GEOS file handle (GH_geoHandle) */

STRUCT(ReadGeodeReply)
    WORD(RGR_size)  	    	    /* size */
    BYTE(RGR_ok)    	    	    /* is everything ok */
    BYTE(RGR_pad)   	    	    /* a byte of padding so C and ASM agree*/
ENDST(ReadGeodeReply)	    	    /* on the size of this thing */


#define RPC_INDEX_TO_OFFSET RPC_READ_GEODE+1
STRUCT(IndexToOffsetArgs)
    WORD(ITOA_geodeHandle)    	    /* handle of geode used to get at */
    WORD(ITOA_index)	    	    /* index into export table to convert */
ENDST(IndexToOffsetArgs)

STRUCT(IndexToOffsetReply)
    WORD(ITOR_offset)	    	    /* converted offset */
ENDST(IndexToOffsetReply)


#define RPC_FIND_GEODE RPC_INDEX_TO_OFFSET+1 /* geode file search routine */
#define RPC_FIND_GEODE_XFER_SIZE 128	/* data transfer size */

#define RPC_GET_NEXT_DATA_BLOCK RPC_FIND_GEODE+1 /* get a generic chunk of data */
STRUCT(GetNextDataBlock)
    WORD(GNDB_size)
ENDST(GetNextDataBlock)

#define RPC_READ_XMS_MEM RPC_GET_NEXT_DATA_BLOCK+1 /* get a chunk of data from xms */
STRUCT(ReadXmsMemArgs)
     LONG(RXMA_size)               /* size of block to get */
     LONG(RXMA_sourceOffset)       /* offset into xms block to read from */
     WORD(RXMA_sourceHandle)       /* handle of xms block to read from */
     WORD(RXMA_procSegment)        /* segment of xmsAddr */
     WORD(RXMA_procOffset)         /* offset of xmsAddr */
ENDST(ReadXmsMemArgs)

#define RPC_READ_DEBUG_REGS 135
#define RPC_WRITE_DEBUG_REGS RPC_READ_DEBUG_REGS+1

/* The Intel debugging registers.  DR4 and DR5 are unused. */
STRUCT(DebugRegsArgs)
     LONG(DRA_dr7)		    /* control register */
     LONG(DRA_dr6)		    /* status register  */
     LONG(DRA_dr3)		    /* linear address 3 */
     LONG(DRA_dr2)		    /* linear address 2 */
     LONG(DRA_dr1)		    /* linear address 1 */
     LONG(DRA_dr0)		    /* linear address 0 */
ENDST(DebugRegsArgs)

/* START C DEFINITIONS */
#if defined(_MSC_VER)
/* Go back to what we had for structure padding/packing */
#pragma pack(pop)
#endif
#if defined(__WATCOMC__)
#pragma pack(pop)
#endif
/* END C DEFINITIONS */

/*
 * The last defined RPC
 */
#define RPC_LAST    	    RPC_WRITE_DEBUG_REGS
#endif /* _RPC_H_ */

