/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- Main definitions file.
 * FILE:	  swat.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 17, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/17/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Main header file for swat -- common definitions/inclusions.
 *
 *
* 	$Id: swat.h,v 4.26 97/04/18 16:43:59 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _SWAT_H_
#define _SWAT_H_

#define SWAT	/* Include function definitions in rpc.h */

#define REGS_32  1 /* Use 32 bit register communication (use 32 bit SWAT to work) */

#define DEBUG_OUTPUT_RPC_DATA_TO_FILE  0

#define GEOS32  0

#if GEOS32
#  define SEGMENT_SHIFT     16
#  define SEGMENT_MASK      0xFFFF0000
#  define OFFSET_MASK       0xFFFF
#  define MAXIMUM_ADDRESS   0xFFFFFFFF
#else
#  define SEGMENT_SHIFT     4
#  define SEGMENT_MASK      0xFFFF0
#  define OFFSET_MASK       0xF
#  define MAXIMUM_ADDRESS   0xFFFFF
#endif

#define SegmentOf(addr)             ((((dword)addr) & SEGMENT_MASK) >> SEGMENT_SHIFT)
#define OffsetOf(addr)              (((dword)addr) & OFFSET_MASK)
#define MakeSegOff(seg, off)        ((((dword)seg) << SEGMENT_SHIFT) + ((dword)off))
#define MakeAddress(seg, off)       ((Address)MakeSegOff(seg, off))

#ifdef _MSC_VER
#pragma warning(disable : 4090)
/* Turn off C4090 which doesn't like matching const types */
#endif

/*
 * If we're using an ANSI-C compiler, we want to use its type-checking
 * facilities by using function prototypes in the declarations of the module
 * interfaces. If it's not ANSI-C, just declare the functions in the standard
 * C form. A typical declaration will look like;
 * DECLARE(void, Sym_Enter, (Sym sym, Sym scope));
 */
/*
#define DECLARE(rt, func, args) extern rt func args
#define DECLAREARG(rt, func, args) rt (*func) args
#define DECLAREPRIV(rt, func, args) static rt func args
#define VECTOR(rt, func, args) rt (*func) args
*/
#define CONCAT(a,b) a##b

#if !defined(_WIN32)
#if !defined(__GNUC__)
#define inline
#endif
#endif

/*
 * High C won't allow "static" to be used for forward-definitions of a function
 * with a function typedef (it mistakenly thinks the thing is a function
 * definition, even though there's a semi-colon), but it does the right thing
 * when the beast is declared extern instead of static (GCC bitches about
 * something being external and then static...)
 */
#if defined(__HIGHC__) || defined(__BORLANDC__)
#define fstatic	extern
#else
#define fstatic static
#endif

/******************************************************************************
 *
 *		   BASIC TYPEDEFS AND INCLUDE FILES
 *
 *****************************************************************************/
typedef int 	Boolean;
typedef void	*Opaque;

#if defined(__HIGHC__) || defined(__BORLANDC__) || defined(__WATCOMC__)

/* (*&()*&Y High C allows almost nothing to be done with void *'s grrrr */
typedef unsigned long Address;
typedef unsigned long ClientData;	/* GET RID OF THIS */

#else

typedef void	*Address;   	/* DITTO ? */
typedef void	*ClientData;	/* GET RID OF THIS */

#endif

typedef struct {
    Opaque  data[2];
} VMToken;

#define NullOpaque  ((Opaque)NULL)

#include <assert.h>
#ifdef sparc
# include <alloca.h>
#endif

#define ClientData  LstClientData
#define Address	    LstAddress
#define Boolean	    LstBoolean
#include <lst.h>
#undef	Address
#undef	ClientData
#undef 	Boolean

#include <tcl.h>

#define Buffer	HCBuffer    	/* They're so anally ANSI about everything
				 * else, how dare they call something in
				 * stdio.h "Buffer"? */
#include <stdio.h>
#undef Buffer

#include <compat/string.h>
#include <malloc.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#include <fileUtil.h>

#define NUMBER_OF_INTERNAL_SYMBOLS 52

/******************************************************************************
 *
 *		     MEMORY ALLOCATOR DEFINITIONS
 *
 *****************************************************************************/
/*
 * Assignment of malloc tags to opaque types:
 */
#define TAG_TYPE    2	/* Internal type description */
#define TAG_FILE    3	/* Source file stuff (unused) */
#define TAG_BREAK   4	/* Breakpoint-associated data */
#define TAG_EVENT   5	/* Event data */
#define TAG_THREAD  6	/* Thread descriptor */
#define TAG_FRAME   7	/* Stack frame */
#define TAG_PATIENT 8	/* Patient info (including resource descriptors) */
#define TAG_CACHE   9	/* Cache record */
#define TAG_VECTOR  10	/* Vector data */
#define TAG_HASH    11	/* Hash-table entry */
#define TAG_HASHT   12	/* Hash-table stuff (overhead) */
#define TAG_HANDLE  13	/* Handle descriptor */
#define TAG_BUFFER  14	/* Expandable buffer data */
#define TAG_VALUE   15	/* Value data/history record */
#define TAG_TCLD    16	/* TclDebug data/frame */
#define TAG_TABLE   17	/* Data table */
#define TAG_ALIAS   18	/* Alias descriptor */
#define TAG_CBLOCK  19	/* Cache block */
#define TAG_ETC	    20	/* Miscellaneous */
#define TAG_HELP    21	/* Help structures (overhead) */
#define TAG_MD	    22	/* Machine-dependent stuff */
#define TAG_RPC	    23	/* Rpc events/servers/etc. */
#define TAG_TNODE   24	/* Tree node in Sym module */
#define TAG_SYMETC  25	/* Other Sym allocations */
#define TAG_TYPEETC 26	/* Other Type allocations */
#define TAG_CURSES  27	/* Curses UI stuff */
#define TAG_CWIN    28	/* Curses window */
#define TAG_STREAM  29	/* Stream descriptor */
#define TAG_CMD	    30	/* Command descriptor */
#define TAG_PNAME   31	/* Patient name */
#define TAG_HELPSTR 32	/* Help string */
#define TAG_HELPTS  33	/* Temporary help string (shouldn't be around) */
#define TAG_ID      34	/* Identifier/string table stuff */
#define TAG_INTRST  35	/* Interest record for handle command */
#define TAG_DVAL    36	/* Data block created by Value_ConvertFromString */
#define TAG_RPCSRV  37	/* RPC Server token */
#define TAG_RPCEV   38	/* RPC Event token */
#define TAG_VMFILE  39	/* VM file handle */
#define TAG_EXPR    40	/* Data allocated by Expr_Eval */

/*
 * VALIDPTR is true if the ptr is a valid dynamically-allocated specimen.
 * "end" is the end of the statically-allocated memory, while sbrk(0) returns
 * the end of the dynamically-allocated memory. A valid pointer points
 * between them.
 */
extern char 	end[];
#define VALIDPTR(ptr) (((ptr) > (typeof (ptr))end) && \
		       ((ptr) < (typeof (ptr))sbrk(0)))
#define VALIDTPTR(ptr,tag) (malloc_tag((char *)(ptr)) == (tag))

/******************************************************************************
 *
 *		    INTER-MODULE TOKEN DEFINITIONS
 *
 *****************************************************************************/
typedef VMToken	  Sym;	    /* Basic type manipulated by sym.c */
typedef VMToken	  Type;	    /* Basic type manipulated by type.c */
typedef Opaque	  File;	    /* Token used to identify a source file */
typedef Opaque	  Break;    /* Token used to identify a breakpoint */
typedef Opaque	  Event;    /* Token used to identify an event (handler) */
typedef Opaque	  Thread;   /* Token used to identify a thread */

typedef struct {
    Opaque  	  otherInfo;	/* Word of special data:
				 *  Sym of module if resource.
				 *  Thread if THREAD
				 */
}	    	  *Handle;

#if defined(__HIGHC__) || defined(__BORLANDC__) || defined(__WATCOMC__)
extern Type NullType;
extern Sym  NullSym;
#else
#define NullType ((Type){0, 0})
#define NullSym ((Sym){0, 0})
#endif

#define NullFile  ((File)NULL)
#define NullBreak ((Break)NULL)
#define NullEvent ((Event)NULL)
#define NullHandle ((Handle)NULL)
#define NullThread ((Thread)NULL)

#define TypeCast(q) (*(Type *)&(q))
#define SymCast(q) (*(Sym *)&(q))

typedef struct _Patient	*Patient;   /* Forward declaration */
#define NullPatient ((Patient)NULL)

#define ValueHandle ((Handle)1)	    /* Special value returned in GeosAddr.handle
				     * from Expr_Eval if value's been fetched
				     * from the PC */

/******************************************************************************
 *
 *		     REGISTER ACCESS DEFINITIONS
 *
 *****************************************************************************/
/*
 * Each register defined has a Reg_Data structure entered in
 * the private data under the appropriate name. The type and number
 * are those needed to access the register itself.
 */
typedef enum {
    REG_MACHINE,  	    	    /* Machine register */
    REG_OTHER	  	    	    /* Other register known to patient
				     * interface */
} 	    	  RegType;  /* Register type for ReadRegister and
			     * WriteRegister calls */
typedef struct {
    RegType 	  type;	    	    /* Type of register */
    int		  number;   	    /* Its number (or name) */
}	    	  Reg_Data; /* Data stored with register names for the parser
			     * and other people. */

#include    "ibm.h"
#include    "handle.h"
#include    "geos.h"

#define REG_PC	  	256 	/* Special magic number for PC */
#define REG_SR	  	257 	/* Special magic number for status reg */
#define REG_FP	    	258 	/* Special magic number for frame pointer */


#define Number(array)	(sizeof(array)/sizeof((array)[0]))

/******************************************************************************
 *
 *			 STACK FRAME DECODING
 *
 *****************************************************************************/
/*
 * Frames are associated with a thread, but can come from
 * a different patient (e.g. if the thread is in a library or the kernel).
 */
typedef struct Frame {
    Handle  	  handle;   	    /* Handle of block in which it's
				     * executing */
    Sym	    	  function; 	    /* The function called */
    Sym	    	  scope;    	    /* Scope for symbol look-up */
    Opaque  	  private;    	    /* Data private to machine-dependent
				     * functions. */
    Opaque  	  patientPriv;	    /* Data private to patient-dependent
				     * functions (if necessary) */
    Patient 	  patient;  	    /* Patient whose code we're really
				     * executing */
    Patient 	  execPatient;	    /* Patient on whose thread we're
				     * executing */
} Frame;

#define NullFrame ((Frame *)NULL)


/******************************************************************************
 *
 *			 PATIENT DEFINITIONS
 *
 *****************************************************************************/
/*
 * Data stored for each resource in the file.
 */
typedef struct {
    Handle  	    handle;   	/* Handle for the resource. */
    Sym	    	    sym;    	/* Symbols in this segment */
    int	    	    flags;    	/* Allocation flags */
    int	    	    size;    	/* Resource size */
    int	    	    offset;   	/* Position for it in the .geo file */
} ResourceRec, *ResourcePtr;

/*
 * Each patient handled by the debugger is identified by a Patient handle.
 * A patient is either a GEODE (application, library, driver) or the kernel.
 * The kernel isn't really a patient (or a COB, for that matter), but it
 * simplifies things to have an actual Patient handle for it.
 */

#define SYMFILE_FORMAT_OLD 0
#define SYMFILE_FORMAT_NEW 1

typedef struct _Patient {
/* GLOBAL STATE */
    char	*name;    	    	/* Patient's name */
    FileType   	object;  	    	/* Stream open to patient's object
					 * file */
    Opaque  	symFile;    	    	/* VM file open to symbol file */
    word    	symfileFormat;	    	/* 0 for old one, 1 for new one */
    char    	*srcRootEnd;   	    	/* The place in "path" where we should
					 * copy to when we find a relative
					 * source file name. It starts as 0,
					 * meaning to try the whole thing. If
					 * the resulting file doesn't exist,
					 * but we find a file that exists by
					 * stripping off the last component
					 * of path and trying again, it means
					 * the patient is product-specific, and
					 * was compiled in a directory one
					 * level higher than the executable
					 * lies */
    char    	*path;  	    	/* Path to the object file */
    Sym	    	global; 	    	/* Symbols not in any resource */
    Boolean 	dos;	    	    	/* Non-zero if patient is some
					 * DOS entity, not a GEOS one */
    /* Lookup context */
    Frame   	*frame;    	    	/* Currently-active stack frame
					 * for lookups. */
    File    	file;    	    	/* Current file for line lookups */
    int		line;    	    	/* Current line number */
    Sym	    	scope;    	    	/* Scope for symbol-lookup, when not
					 * done by expressions */

    /* GEOS-specific stuff */
    Handle  	core;    	    	/* Handle to core block */
    union {
	GeodePtr    v1;
	Geode2Ptr   v2;
    }       	geode;  	    	/* GEODE descriptor */

    Lst	    	threads;  	    	/* Active threads */
    Thread	curThread;		/* Current thread */

    Patient	*libraries;	    	/* Libraries used */
    int		numLibs;		/* Number in 'libraries' */

    ResourcePtr	resources;      	/* All resources */
    int		numRes;  	    	/* Number of ResourceRec's in
					 * 'resources' */
/* PRIVATE DATA */
    Opaque  	patientPriv;	    	/* Data private to patient interface */
    Opaque  	mdPriv;   	    	/* Data private to machine-dependent
					 * interface */
    Opaque  	sourcePriv;	    	/* Data private to source.c */
    Opaque  	symPriv;    	    	/* Data private to sym.c */
} PatientRec;

/*
 * Patient status flags
 */
extern int  	    sysFlags;

#define PATIENT_RUNNING	    0x00000001	/* Patient running */
#define PATIENT_STOPPED	    0x00000002	/* Patient stopped */
#define PATIENT_DIED	    0x00000004	/* Patient dead */
#define PATIENT_FREE	    0x00000008	/* Patient has been released */

#define PATIENT_TRACE	    0x00000100	/* Trace the execution of each source
					 * line. */
#define PATIENT_STOP        0x00000400	/* Keep patient stopped. Signals
					 * to patient interface that it should
					 * keep the patient stopped after it
					 * has dispatched the EVENT_STOP. If
					 * this bit is not set, the patient
					 * should be continued. */
#define PATIENT_CALLING	    0x00000800	/* SWAT is calling a function in the
					 * patient */
#define PATIENT_BREAKPOINT  0x00001000	/* Patient stopped because of a
					 * breakpoint */
#define PATIENT_SKIPBPT	    0x00002000	/* Special flag set when continuing
					 * over a breakpoint (or not taking
					 * one) to use the special SKIPBPT
					 * Rpc */

extern word 	    skipBP; 	/* Number of breakpoint to skip */

/*
 * Patient interfaces:
 */
extern void Patient_Init (int *argcPtr, char **argv);
extern void Patient_Continue (void);
#if 0
DECLARE(void, Patient_Step, (Patient patient, Address begin, Address end,
			     Boolean skipFuncs, Boolean cont));
#endif
extern Patient Patient_ByName (char *name);

/******************************************************************************
 *
 *			   GLOBAL VARIABLES
 *
 *****************************************************************************/
extern Lst  	    patients; 	    /* All known patients */
extern Patient	    kernel;   	    /* The patient handle for the kernel */
extern Patient	    loader;   	    /* The patient handle for the loader */
extern Tcl_Interp   *interp;  	    /* The global command interpreter */
extern Patient	    curPatient;	    /* Currently-active patient */
extern Patient	    defaultPatient; /* Default patient for symbol lookups if
				     * lookup in curPatient fails */
extern Boolean	    swap;   	    /* TRUE if need to byteswap data to/from
				     * the PC */
extern Boolean	    debug;  	    /* TRUE if debugging enabled */
extern int  	    sysStep;	    /* Count of people wanting the PC to
				     * single-step */
extern Boolean	    rel2;   	    /* TRUE if attached to a Release2
				     * PC/GEOS system */

/*
 * Miscellaneous
 */
extern void Status_Changed(void);
extern volatile void	Punt(const char *msg, ...);
#if defined(_WIN32)
extern void Swat_Death(void);
#endif
#ifdef __WATCOMC__
_WCRTLINK _WCNORETURN extern void   abort( void );
#else
#if defined(__GNUC__) 
extern volatile void   	abort(void);
#else
extern void abort(void);
#endif
#endif

extern int  cvtnum(const char *cp, char **endPtr);

/*
 * Vectors for user-interface functions
 */
extern void 	(*Message)(const char *fmt, ...);
extern void 	(*Warning)(const char *fmt, ...);
extern void 	(*MessageFlush)(const char *fmt, ...);
extern void 	(*Ui_ReadLine)(char *line);
extern int  	(*Ui_NumColumns)(void);
extern void 	(*Ui_Exit)(void);

/* MACHINE-DEPENDENT DATA */

#if 0
extern Address Allocate(Patient patient, int numBytes);
extern void Free(Patient patient, Address address);
extern void PushArg(Patient patient, int argSize, Address argAddr);
extern Boolean CallFunc(Patient patient, Address address, Address retBuf,
			Type retType);
#endif

extern Frame	*(*MD_GetFrame)(word ss, word sp, word cs, word ip);
extern Frame 	*(*MD_CurrentFrame)(void);
extern Frame 	*(*MD_NextFrame)(Frame *curFrame);
extern Frame 	*(*MD_PrevFrame)(Frame *curFrame);
extern Frame 	*(*MD_CopyFrame)(Frame *frame);
extern Boolean 	(*MD_FrameValid)(const Frame *frame);
extern void 	(*MD_DestroyFrame)(Frame *frame);
extern void 	(*MD_FrameInfo)(Frame *frame);
extern GeosAddr (*MD_ReturnAddress)(void);
extern GeosAddr (*MD_FrameRetaddr)(Frame *frame);
extern GeosAddr (*MD_FunctionStart)(Handle handle, word offset);
extern Boolean 	(*MD_GetFrameRegister)(Frame *frame,
				       RegType regType, int regNum,
				       regval *valuePtr);
extern Boolean 	(*MD_SetFrameRegister)(Frame *frame,
				       RegType regType, int regNum,
				       regval value);
extern Opaque 	(*MD_SetBreak)(Handle handle, Address address);
extern void 	(*MD_ClearBreak)(Handle handle, Address address, Opaque data);
extern Boolean 	(*MD_Decode)(Handle handle, Address offset, char *buffer,
			    int *instSizePtr, char *decode);

#define MAX_XIP_PAGE 4096
#define VALID_XIP(pg)	((pg) < MAX_XIP_PAGE || \
			 (pg) == HANDLE_NOT_XIP || \
			 ((pg) & 0xef00) == 0xa000) /* a000 or b000... */

extern	word	curXIPPage;
extern 	word	realXIPPage;

extern void dprintf(char *msg, ...);

#if defined(_WIN32)
extern int win32dbg;	   /* whether or not to be verbose w/ error messages */
#endif

#endif /* _SWAT_H */
