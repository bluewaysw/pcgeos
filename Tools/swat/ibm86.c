/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- 8086 machine-dependent.
 * FILE:	  ibm86.c
 *
 * AUTHOR:  	  Adam de Boor: Jun 22, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Ibm86_Init  	    Initialize data for a patient
 *	Ibm86CurrentFrame   Return top-most frame for current patient
 *	Ibm86NextFrame	    Return next frame up the stack from given
 *	Ibm86PrevFrame	    Return previous frame down the stack from given
 *	Ibm86CopyFrame	    Create a more permanent copy of a frame
 *	Ibm86FrameValid	    See if a frame is still valid
 *	Ibm86DestroyFrame   Nuke a copied frame
 *	Ibm86FrameInfo	    Print information about a frame
 *	Ibm86ReturnAddress  Return address to which frame will return
 *	Ibm86FunctionStart  Skip over any prologue of function for given frame
 *	Ibm86GetFrameRegister Return value of a register w.r.t. a frame
 *	Ibm86SetFrameRegister Set the value of a register w.r.t. a frame
 *	Ibm86SetBreak	    Set a breakpoint at an address
 *	Ibm86ClearBreak	    Clear a breakpoint
 *	Ibm86Decode 	    Decode a machine instruction.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/22/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Machine-dependent code for the 8086 on an IBM PC.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ibm86.c,v 4.42 97/04/18 15:49:20 dbaumann Exp $";
#endif lint


#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "i86Opc.h"
#include "ibm.h"
#include "private.h"
#include "src.h"
#include "sym.h"
#include "type.h"
#include "var.h"
#include "expr.h"

#define size_t suns_size_t2
#include <sys/types.h>
#undef size_t

/*
 * types for 64 and 80 bit floating point numbers
 */

typedef struct {
    word    QW_word1;
    word    QW_word2;
    word    QW_word3;
    word    QW_word4;
} qword;

typedef struct {
        byte    TB_byte1;
        byte    TB_byte2;
        byte    TB_byte3;
        byte    TB_byte4;
        byte    TB_byte5;
        byte    TB_byte6;
        byte    TB_byte7;
        byte    TB_byte8;
        byte    TB_byte9;
        byte    TB_byte10;
} tbyte;

typedef union  {
    dword   OS_dword;
    float   OS_float;
    double  OS_double;
    tbyte   OS_tbyte;
} OperandSize;

extern word oldXIPPage;
extern word curXipPage;

/*
 * Determine the end of the stack. If it's the kernel's dgroup, the end is the
 * start of the handle, as denoted by the kernel's dgroup's handle ID. Else
 * it's the size of the handle.
 */
#define Ibm86EndStack(s) ((kernel != 0 && ((s) == kernel->resources[1].handle)) ? Handle_ID(s) : Handle_Size(s))

/*
 * These are initialized from the kernel symbol table and used for decoding
 * the stack.
 *
 */
static int  stackBotOff;    /* Offset in ThreadPrivateData of TPD_stackBot
			     * field */
/*
 * The addresses of the three ProcCallFixedOrMovable routines, so we can
 * backtrace through them.
 */
static SegAddr pcfom, pcfomPascal, pcfomCdecl;

/*
 * registers contains the name -> number mapping for all the 8086 registers.
 * May at some time want the '286 protected mode registers in here as well,
 * but not now. The first 12 are organized for Ibm86FrameInfo to use.
 */
static const struct {
    char    	  *name;
    Reg_Data	  data;
}	    registers[] = {
	{"ax",	{REG_MACHINE,	REG_AX}},
	{"cx",	{REG_MACHINE,	REG_CX}},
	{"dx",	{REG_MACHINE,	REG_DX}},
	{"bx",	{REG_MACHINE,	REG_BX}},
	{"sp",	{REG_MACHINE,	REG_SP}},
	{"bp",	{REG_MACHINE,	REG_BP}},
	{"si",	{REG_MACHINE,	REG_SI}},
	{"di",	{REG_MACHINE,	REG_DI}},
	{"es",	{REG_MACHINE,	REG_ES}},
	{"cs",	{REG_MACHINE,	REG_CS}},
	{"ss",	{REG_MACHINE,	REG_SS}},
	{"ds",	{REG_MACHINE,	REG_DS}},
	{"al",	{REG_MACHINE,	REG_AL}},
	{"ah",	{REG_MACHINE,	REG_AH}},
	{"bl",	{REG_MACHINE,	REG_BL}},
	{"bh",	{REG_MACHINE,	REG_BH}},
	{"cl",	{REG_MACHINE,	REG_CL}},
	{"ch",	{REG_MACHINE,	REG_CH}},
	{"dl",	{REG_MACHINE,	REG_DL}},
	{"dh",	{REG_MACHINE,	REG_DH}},
	{"AX",	{REG_MACHINE,	REG_AX}},
	{"BX",	{REG_MACHINE,	REG_BX}},
	{"CX",	{REG_MACHINE,	REG_CX}},
	{"DX",	{REG_MACHINE,	REG_DX}},
	{"SI",	{REG_MACHINE,	REG_SI}},
	{"DI",	{REG_MACHINE,	REG_DI}},
	{"SP",	{REG_MACHINE,	REG_SP}},
	{"BP",	{REG_MACHINE,	REG_BP}},
	{"CS",	{REG_MACHINE,	REG_CS}},
	{"DS",	{REG_MACHINE,	REG_DS}},
	{"SS",	{REG_MACHINE,	REG_SS}},
	{"ES",	{REG_MACHINE,	REG_ES}},
	{"AL",	{REG_MACHINE,	REG_AL}},
	{"AH",	{REG_MACHINE,	REG_AH}},
	{"BL",	{REG_MACHINE,	REG_BL}},
	{"BH",	{REG_MACHINE,	REG_BH}},
	{"CL",	{REG_MACHINE,	REG_CL}},
	{"CH",	{REG_MACHINE,	REG_CH}},
	{"DL",	{REG_MACHINE,	REG_DL}},
	{"DH",	{REG_MACHINE,	REG_DH}},
	{"cc",	{REG_MACHINE,	REG_SR}},
	{"CC",	{REG_MACHINE,	REG_SR}},
	{"ip",	{REG_MACHINE,	REG_IP}},
	{"IP",	{REG_MACHINE,	REG_IP}},
	{"pc",	{REG_MACHINE,	REG_PC}},
	{"PC",	{REG_MACHINE,	REG_PC}},
	{"fp",	{REG_MACHINE,	REG_FP}},
	{"FP",	{REG_MACHINE,	REG_FP}}
#if REGS_32
        ,
        {"eax",	{REG_MACHINE,	REG_EAX}},
        {"ebx",	{REG_MACHINE,	REG_EBX}},
        {"ecx",	{REG_MACHINE,	REG_ECX}},
        {"edx",	{REG_MACHINE,	REG_EDX}},
        {"esi",	{REG_MACHINE,	REG_ESI}},
        {"edi",	{REG_MACHINE,	REG_EDI}},
        {"ebp",	{REG_MACHINE,	REG_EBP}},
        {"esp",	{REG_MACHINE,	REG_ESP}},
        {"eip",	{REG_MACHINE,	REG_EIP}},
        {"fs",	{REG_MACHINE,	REG_FS}},
	{"gs",	{REG_MACHINE,	REG_GS}},

        {"EAX",	{REG_MACHINE,	REG_EAX}},
        {"EBX",	{REG_MACHINE,	REG_EBX}},
        {"ECX",	{REG_MACHINE,	REG_ECX}},
        {"EDX",	{REG_MACHINE,	REG_EDX}},
        {"ESI",	{REG_MACHINE,	REG_ESI}},
        {"EDI",	{REG_MACHINE,	REG_EDI}},
        {"EBP",	{REG_MACHINE,	REG_EBP}},
        {"ESP",	{REG_MACHINE,	REG_ESP}},
        {"EIP",	{REG_MACHINE,	REG_EIP}},
        {"FS",	{REG_MACHINE,	REG_FS}},
	{"GS",	{REG_MACHINE,	REG_GS}}
#endif
};

/*
 * Data kept with a stack frame.
 *
 * Two sets of register addresses are kept with the frame:
 *	- the registers saved by the frame.
 *	- the registers saved by all frames above it (i.e. toward the top
 *	  of the stack)
 * The first set is used both to set the second set for frames below it
 * (saved[i+1] = saved[i] | saves[i]), and for decoding the stack in the
 * event of a CALL with the destination stored in memory or a register.
 */

#if REGS_32
#define NUM_REGS  	14  	/* Number of registers with which we concern
				 * ourselves */
#define SAVED_REG_FS_AND_GS  12
#else
#define NUM_REGS  	12  	/* Number of registers with which we concern
				 * ourselves */
#endif

typedef struct _FramePriv {
    word 	    ip;	    	    /* PC in frame. Handle is in the
				     * Frame itself. */
    word	    sp;		    /* SP in frame */
    Handle  	    stackHan;	    /* Handle of block containing the
				     * stack */
    word    	    stackBot;	    /* TPD_stackBot in this frame */
    word    	    entrySP;   	    /* SP on entry to frame (address of return
				     * address). The handle is always
				     * the same -- the core block */
    Handle  	    entryStackHan;  /* Handle of block containing entrySP */
    word    	    fp;	    	    /* Frame pointer (different from entrySP
				     * if function contains a prologue) */
    Frame	    *next;    	    /* Next frame, if already fetched */
    Frame	    *prev;	    /* Previous frame. If NULL, frame has
				     * no previous frame (either because
				     * it's the top frame or because it's
				     * been copied) */
    SegAddr 	    retAddr;	    /* Return address (for checking
				     * validity) */
    unsigned long   flags;  	    /* Flags, including those for saved
				     * registers. A one bit in b0-b11
				     * indicates the address for the
				     * register is valid. The registers are
				     * ordered AX, CX, DX, BX, SP, BP, SI,
				     * DI, ES, CS, SS, DS because that's
				     * the way the processor orders them.
				     * REG_IP_MASK is set if the ip for
				     * the frame is in 'ip'. Otherwise it
				     * must be fetched from the patient-
				     * dependent interface. */
                                    /* FS and GS has been added as 13 and 14th */
    word	savedRegs[NUM_REGS];/* Where registers are stored. These are
				     * for the word registers only, since
				     * they're the only ones that can be
				     * pushed. NOTE:  LES!!! I'm not sure if this is true anymore. */
    word    	flagsAddr;  	    /* Special slot for saved flags */
    word    	xipPage;    	    /* xip page associated with this frame */
} FramePrivRec, *FramePrivPtr;
#define IP_SAVED	0x80000000  /* IP in private data valid */
#define HAVE_RETADDR	0x40000000  /* Found return address for frame */
#define FRAME_COPIED	0x20000000  /* Frame created by CopyFrame */
#define FLAGS_SAVED 	0x10000000  /* Flags saved in frame below */   
#define ALWAYS_VALID	0x08000000  /* Frame is always valid b/c we have no
				     * way to check its validity (e.g. if
				     * return address is in a register) */
#define RET_AT_STACKBOT	0x04000000  /* CS:IP are at stackBot, which means we
				     * should use the machine's ss, not the
				     * frame's ss, when fetching a saved cs */
#define VALIDATE    	0x02000000  /* Frame is left over from last time and
				     * needs to be validated. If it's not valid,
				     * it can be discarded and a new one built
				     * in its place */
#define REG_MASK    	((1<<NUM_REGS)-1)

/*
 * Private data kept with the patient. A linked list of stack frames is
 * maintained for the patient. When the patient is continued, validate is set
 * TRUE. The next call to CurrentFrame will cause the frame being pointed to
 * by top to be checked to make sure it is still valid. If it is, the entire
 * list is assumed valid. Otherwise, all frames are destroyed and the chain
 * is started from the beginning again.
 */
typedef struct {
    Frame   	*top;	    	/* Current top of the stack */
    Thread  	thread;	    	/* Thread for which frames are valid */
} Ibm86PrivRec, *Ibm86PrivPtr;

/*
 * Value format for operands. Defaults to hex but may be changed with the
 * operand-format command
 */
static char *valFormat	= "%xh";

#if REGS_32

/*
 * Indices into the commonly used prefixSize array.  If an attribute is
 * 32-bit, the corresponding element is TRUE.
 */
#define PREFIX_OPERAND_SIZE_32BIT     0
#define PREFIX_ADDRESS_SIZE_32BIT     1

#endif

/* Forward DECL */
static Boolean Ibm86FrameValid(const Frame	*frame);
static void Ibm86DestroyFrame(Frame	*frame);
static Boolean Ibm86GetFrameRegister(Frame *, RegType, int, regval *);
static Boolean Ibm86GetFrameRegister16(Frame *, RegType, int, word *);


/***********************************************************************
 *				Ibm86StackHandle
 ***********************************************************************
 * SYNOPSIS:	    Retrieve the handle for the current thread's actual
 *	    	    current stack block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The handle
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/1/92		Stolen from Ibm_StackHandle
 *
 ***********************************************************************/
static Handle
Ibm86StackHandle(void)
{
    regval  	ss;
    Handle  	h;

    Ibm_ReadRegister(REG_MACHINE, REG_SS, &ss);
    h = Handle_Find(MakeAddress(ss, 0));
    if ((h != NullHandle) && (Handle_Segment(h) != ss)) {
	return(NullHandle);
    } else {
	return(h);
    }
}

/***********************************************************************
 *				Ibm86FrameInterest
 ***********************************************************************
 * SYNOPSIS:	  Deal with a state change in a handle that's stored in
 *		  a frame.
 * CALLED BY:	  Handle module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  If the handle is freed and the frame was copied, the
 *		  frame is destroyed.
 *
 * STRATEGY:
 *	This routine serves two purposes: to make sure copied frames
 *	don't contain bogus handles and to provide an anchor whereby
 *	handles in frames don't get flushed. This allows the frame and
 *	the handle in it to be cached across continuations of the machine,
 *	if possible. Otherwise, if one enters an area of memory that isn't
 *	in a resource handle, and the frame is deemed otherwise valid
 *	when the machine stops again, the handle will have been freed by
 *	the continue and swat will get failed assertion errors.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/29/89		Initial Revision
 *
 ***********************************************************************/
void
Ibm86FrameInterest(Handle handle, Handle_Status status, Opaque data)
{
    FramePrivPtr	privPtr;
    Frame		*frame = (Frame *)data;


    privPtr = (FramePrivPtr)frame->private;

    if ((status == HANDLE_FREE) && (privPtr->flags & FRAME_COPIED)) {
	Ibm86DestroyFrame(frame);
    } else if (status == HANDLE_FREE) {
	/* XXX: This happens on detach sometimes */
	frame->handle = NullHandle;
    }
}

/***********************************************************************
 *				Ibm86FrameStackInterest
 ***********************************************************************
 * SYNOPSIS:	  Deal with a state change in a handle that's stored in
 *		  a frame.
 * CALLED BY:	  Handle module
 * RETURN:	  Nothing
 * SIDE EFFECTS:  If the handle is freed and the frame was copied, the
 *		  frame is destroyed.
 *
 * STRATEGY:
 *	This routine serves two purposes: to make sure copied frames
 *	don't contain bogus handles and to provide an anchor whereby
 *	handles in frames don't get flushed. This allows the frame and
 *	the handle in it to be cached across continuations of the machine,
 *	if possible. Otherwise, if one enters an area of memory that isn't
 *	in a resource handle, and the frame is deemed otherwise valid
 *	when the machine stops again, the handle will have been freed by
 *	the continue and swat will get failed assertion errors.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/1/92		Initial Revision
 *
 ***********************************************************************/
void
Ibm86FrameStackInterest(Handle handle, Handle_Status status, Opaque data)
{
    FramePrivPtr	privPtr;
    Frame		*frame = (Frame *)data;


    privPtr = (FramePrivPtr)frame->private;

    if ((status == HANDLE_FREE) && (privPtr->flags & FRAME_COPIED)) {
	Ibm86DestroyFrame(frame);
    } else if (status == HANDLE_FREE) {
	/* XXX: This happens on detach sometimes */

	if (privPtr->prev != NullFrame) {
	    /*
	     * Unlink this frame from the previous one, to avoid weirdness.
	     */
	    ((FramePrivPtr)privPtr->prev->private)->next = NullFrame;
	    privPtr->prev = NullFrame;
	}
	if (privPtr->next != NullFrame) {
	    /*
	     * Unlink this frame from the next one, to avoid weirdness.
	     */
	    ((FramePrivPtr)privPtr->next->private)->prev = NullFrame;
	    privPtr->next = NullFrame;
	}

	if (privPtr->stackHan == handle) {
	    privPtr->stackHan = NullHandle;
	}
	if (privPtr->entryStackHan == handle) {
	    privPtr->entryStackHan = NullHandle;
	}
    }
}

/***********************************************************************
 *				Ibm86DestroyFrame
 ***********************************************************************
 * SYNOPSIS:	  Destroy a stack frame that is no longer needed.
 * CALLED BY:	  GLOBAL
 * RETURN:	  Nothing
 * SIDE EFFECTS:  All memory for the frame is freed.
 *
 * STRATEGY:
 *	THIS ROUTINE SHOULD ONLY BE CALLED FOR FRAMES THAT HAVE BEEN
 *	COPIED.
 *
 *	Frees up the frame and unlinks it from its neighbors, if any.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static void
Ibm86DestroyFrame(Frame	*frame)
{
    FramePrivPtr  	privPtr;

    if (frame != NullFrame) {
	if (frame->handle != NullHandle) {
	    Handle_NoInterest(frame->handle, Ibm86FrameInterest,
				(Opaque)frame);
	}

	if (frame->private) {
	    privPtr = (FramePrivPtr)frame->private;

	    /*
	     * Only destroy frames that have been copied.
	     */
	    if (privPtr->flags & FRAME_COPIED) {
		if (privPtr->stackHan != NullHandle) {
		    Handle_NoInterest(privPtr->stackHan,
				      Ibm86FrameStackInterest,
				      (Opaque)frame);
		}
		
		if (privPtr->entryStackHan != NullHandle) {
		    Handle_NoInterest(privPtr->entryStackHan,
				      Ibm86FrameStackInterest,
				      (Opaque)frame);
		}
		
		/*
		 * Unlink the frame from its neighbors, if it has any.
		 */
		if (privPtr->prev != NullFrame) {
		    ((FramePrivPtr)privPtr->prev->private)->next = NullFrame;
		}
		if (privPtr->next != NullFrame) {
		    ((FramePrivPtr)privPtr->next->private)->prev = NullFrame;
		}

		free((char *)privPtr);
		free((char *)frame);
	    }
	} else {
	    /*
	     * Any frame w/o private data is harmless and may destroyed with
	     * impunity.
	     */
	    free((char *)frame);
	}
    }
}

/***********************************************************************
 *				Ibm86DestroyFrames
 ***********************************************************************
 * SYNOPSIS:	    Nuke an entire chain of frames.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    frames are freed and *framePtr is set to NULL
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/26/94	Initial Revision
 *
 ***********************************************************************/
static void
Ibm86DestroyFrames(Frame **framePtr)
{
    while(*framePtr != NullFrame) {
	Frame	  *next = ((FramePrivPtr)(*framePtr)->private)->next;
		
	/*
	 * Pretend we copied the frame so it gets destroyed
	 */
	((FramePrivPtr)(*framePtr)->private)->flags |= FRAME_COPIED;
		
	Ibm86DestroyFrame(*framePtr);
		
	*framePtr = next;
    }
}


/***********************************************************************
 *				Ibm86InvalidatePatientFrames
 ***********************************************************************
 * SYNOPSIS:	    Set the VALIDATE flag for all frames for the passed
 *		    patient
 * CALLED BY:	    (INTERNAL) Ibm86NukeFrames,
 *			       Ibm86CurrentFrameCommon,
 *			       Ibm86NextFrame
 * RETURN:	    nothing
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/26/94	Initial Revision
 *
 ***********************************************************************/
static void
Ibm86InvalidatePatientFrames(Patient patient)
{
    Frame   *f;


    for (f = ((Ibm86PrivPtr)patient->mdPriv)->top;
	 f != NullFrame;
	 f = ((FramePrivPtr)f->private)->next)
    {
	((FramePrivPtr)f->private)->flags |= VALIDATE;
    }
}

/***********************************************************************
 *			Ibm86InvalidateFrames
 ***********************************************************************
 * SYNOPSIS:	  Invalidate the frames we've decoded, causing to be
 *	    	  checked for validity the next time they're fetched.
 * CALLED BY:	  EVENT_CONTINUE, EVENT_ATTACH
 * RETURN:	  EVENT_HANDLED
 * SIDE EFFECTS:  mdPriv->validate is set TRUE.
 *
 * STRATEGY:
 *	Just sets validate TRUE and returns EVENT_HANDLED.
 *
 *	We handle EVENT_ATTACH b/c during the attach process we tend to
 *	play fast and loose with the curThread variable of the current
 *	patient, often the kernel, and can end up with the cached stack
 *	being for a thread other than the one that ends up as the current
 *	thread for the current patient, resulting in our producing bogus
 *	info unless we validate the next time the current frame is fetched.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *	ardeb	7/15/91	    	Changed to set ->validate true for *all*
 *	    	    	    	patients to deal with attach weirdness.
 *
 ***********************************************************************/
static int
Ibm86InvalidateFrames(Event 	    event,
		      Opaque	    callData,
		      Opaque	    clientData)
{
    LstNode 	ln;

    for (ln = Lst_First(patients); ln != NILLNODE; ln = Lst_Succ(ln)) {
	Patient	patient = (Patient)Lst_Datum(ln);

	Ibm86InvalidatePatientFrames(patient);
    }

    return(EVENT_HANDLED);
}

#if 0

DEFCMD(invalidate-frames,Ibm86InvalidateFrames,TCL_EXACT,NULL,swat_prog,
"")
{
    Ibm86InvalidateFrames(0,0,0);
    return TCL_OK;
}
#endif


/***********************************************************************
 *			Ibm86NukeFrames
 ***********************************************************************
 * SYNOPSIS:	  Delete all frames for a patient
 * CALLED BY:	  EVENT_EXIT
 * RETURN:	  EVENT_HANDLED
 * SIDE EFFECTS:  All the frames for the patient are freed.
 *
 * STRATEGY:
 *	Run through all cached frames for the patient and give them to
 *	Ibm86DestroyFrame for disposal. We don't just set validate to
 *	TRUE, as the death of the patient is a rather more drastic thing
 *	than the continuation of the machine -- many things may have
 * 	changed before the patient is resurrected, if it ever is.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/28/89		Initial Revision
 *
 ***********************************************************************/
static int
Ibm86NukeFrames(Event 	    	event,
	        Opaque	    	callData,	/* Patient that's exiting */
	        Opaque		clientData)
{
    Patient 	    	exitPatient;
    LstNode 	    	ln;

    exitPatient = (Patient)callData;

    for (ln = Lst_First(patients); ln != NILLNODE; ln = Lst_Succ(ln)) {
	Patient		patient;    /* Patient being checked for involvement
				     * with patient that's exiting */
	Ibm86PrivPtr  	pPrivPtr;   /* Our private data for current patient */
	Frame	    	*f; 	    /* Frame being examined */
	Boolean	    	nuke=FALSE; /* Set TRUE if f was active in the patient
				     * being exited */
	
	patient = (Patient)Lst_Datum(ln);
	pPrivPtr = (Ibm86PrivPtr)patient->mdPriv;

	/*
	 * See if any stack frame is active in the patient being exited. Sets
	 * nuke TRUE if so.
	 */
	for (f = pPrivPtr->top;
	     f != NullFrame;
	     f = ((FramePrivPtr)f->private)->next)
	{
	    if (f->patient == exitPatient) {
		nuke = TRUE;
		break;
	    }
	}

	if (nuke || (patient == exitPatient)) {
	    /*
	     * Need to throw away all frames for this patient, as it's
	     * involved with the exiting patient, so there's no way the cached
	     * frames could be valid next time, and leaving these around can
	     * lead to death, owing to the exiting patient's symbol file being
	     * closed and all...
	     */
	    Ibm86DestroyFrames(&pPrivPtr->top);
	    /*
	     * Indicate no current frame for the patient.
	     */
	    patient->frame = (Frame *)NULL;
	}
    }

    return(EVENT_HANDLED);
}

/***********************************************************************
 *				Ibm86HandleChange
 ***********************************************************************
 * SYNOPSIS:	    Handle an EVENT_CHANGE event
 * CALLED BY:	    Event_Dispatch when the current patient changes
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    The validate flag for the old patient is set TRUE
 *
 * STRATEGY:	    See above
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/88	Initial Revision
 *
 ***********************************************************************/
static int
Ibm86HandleChange(Event	    	event,	    	/* Event that invoked us */
		  Opaque    	callData,   	/* Old patient */
		  Opaque	clientData) 	/* Junk */
{
    Patient 	oldPatient = (Patient)callData;

    Ibm86InvalidatePatientFrames(oldPatient);

    return(EVENT_HANDLED);
}

/***********************************************************************
 *				Ibm86ValidateCachedFrames
 ***********************************************************************
 * SYNOPSIS:	    Make sure the frames cached for the current patient
 *	    	    are still valid. curXIPPage needs to be set properly
 *		    by the caller.
 * CALLED BY:	    Ibm86CurrentFrame, Ibm86FrameValid
 * RETURN:	    TRUE if cached frames are still ok
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 6/92		Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86ValidateCachedFrames(Ibm86PrivPtr	pPrivPtr,
			  word	    	*ssPtr,
			  word 	    	*spPtr,
			  word 	    	*csPtr,
			  word 	    	*ipPtr,
			  Sym	    	*functionPtr,
			  Sym	    	*scopePtr,
			  Handle    	*handlePtr,
			  Handle    	*stackHanPtr,
			  Boolean   	usePassedRegisters)
{
    word  	    	cs; 	    /* Current CS */
    word  	    	ip; 	    /* Current IP */
    word    	    	ss; 	    /* Current SS */
    word	  	sp; 	    /* Current SP */
    Handle  	    	handle;	    /* Handle to CS */
    Sym	    	    	function;   /* Function in which we're executing */
    Sym	    	    	scope;	    /* Scope in which we're executing (may be
				     * different) */
    Boolean 	    	retval;	    /* Value to really return */
    Handle  	    	stackHan;

    if (usePassedRegisters)
    {
	ip = *ipPtr;
	sp = *spPtr;
	cs = *csPtr;
	ss = *ssPtr;
    }
    else
    {
	Ibm_ReadRegister16 (REG_MACHINE, REG_IP, &ip); 
	Ibm_ReadRegister16 (REG_MACHINE, REG_CS, &cs); 

	Ibm_ReadRegister16 (REG_MACHINE, REG_SS, &ss);
	Ibm_ReadRegister16 (REG_MACHINE, REG_SP, &sp);
    }
    handle = Handle_Find(MakeAddress(cs, 0));
    if ((handle != NullHandle) && (cs == Handle_Segment(handle))) {
	/*
	 * Find where the patient is executing
	 */
	function = Sym_LookupAddr(handle, (Address)ip, SYM_FUNCTION);
	scope = Sym_LookupAddr(handle, (Address)ip, SYM_SCOPE);
    } else {
	function = NullSym;
	scope = NullSym;
	handle = NullHandle;
    }
    
    stackHan = Handle_Find(MakeAddress(ss, 0));
    if ((stackHan != NullHandle) && (Handle_Segment(stackHan) != ss)) {
	stackHan = NullHandle;
    }

    /*
     * Return various things we're supposed to return through pointers.
     */
    if (functionPtr) {*functionPtr = function;}
    if (scopePtr) {*scopePtr = scope;}
    if (handlePtr) {*handlePtr = handle;}
    if (stackHanPtr) {*stackHanPtr = stackHan; }
    if (!usePassedRegisters)
    {
	if (spPtr) {*spPtr = sp;}
	if (csPtr) {*csPtr = cs;}
	if (ipPtr) {*ipPtr = ip;}
	if (ssPtr) {*ssPtr = ss;}
    }

    retval = (!(pPrivPtr->thread != curPatient->curThread ||
		!Ibm86FrameValid(pPrivPtr->top) ||
		(stackHan !=((FramePrivPtr)pPrivPtr->top->private)->stackHan) ||
		(sp != ((FramePrivPtr)pPrivPtr->top->private)->sp) ||
		(!Sym_Equal(pPrivPtr->top->function, function))));


    return(retval);
}



/***********************************************************************
 *				Ibm86CurrentFrameCommon
 ***********************************************************************
 * SYNOPSIS:	    The real work of creating a frame for the top of
 *	    	    the stack, using either passed registers or values
 *		    fetched from the machine.
 * CALLED BY:	    (INTERNAL) Ibm86CurrentFrame, Ibm86GetFrame
 * RETURN:	    Frame *
 * SIDE EFFECTS:    the frames for the current thread are validated. if
 *		    they are invalid, they will be destroyed. Returned
 *		    frame is set as the topmost one.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/93	Initial Revision
 *
 ***********************************************************************/
static Frame *
Ibm86CurrentFrameCommon(Boolean	usePassedRegisters,
			word	cs, 	    /* Current CS */
			word	ip, 	    /* Current IP */
			word	ss,
			word	sp) 	    /* Current SP */
{
    Ibm86PrivPtr  	pPrivPtr;   /* Our private data for this patient */
    Handle  	    	handle;	    /* Handle to CS */
    Handle  	    	stackHan;   /* Handle to SS */
    Frame   	    	*frame;	    /* New frame */
    FramePrivPtr    	privPtr;    /* Private data for new frame */
    Sym	    	    	function;   /* Function in which we're executing */
    Sym	    	    	scope;	    /* Scope in which we're executing (may be
				     * different) */
    word    	    	oldXIP = curXIPPage;


    pPrivPtr = (Ibm86PrivPtr)curPatient->mdPriv;
    if (!usePassedRegisters &&
	(pPrivPtr->top != NullFrame) &&
	!(((FramePrivPtr)pPrivPtr->top->private)->flags & VALIDATE))
    {
	return(pPrivPtr->top);
    }

    /* TODO check what goes wrong here */
    /*Ibm_ReadRegister16 (REG_OTHER, (int)"xipPage", &curXIPPage);*/
    
    /*
     * Check for different thread, invalid top-most frame, sp changed
     * (this is very conservative, as it invalidates the frame if the function
     * so much as pushes a register, but in this case it's better to do
     * more work than necessary, than less work than really must be done),
     * or executing in a different function.
     */
    if (!Ibm86ValidateCachedFrames(pPrivPtr, &ss, &sp, &cs, &ip,
				   &function, &scope, &handle, &stackHan,
				   usePassedRegisters))
    {
	/*
	 * Things we have are no longer valid. Destroy all the frames we cached
	 */
	Ibm86DestroyFrames(&pPrivPtr->top);

	/*
	 * Old frame cannot possibly be valid and leaving it set will
	 * generate failed assertions when we go fetch stackBot.
	 */
	curPatient->frame = NullFrame;

	/*
	 * Allocate frame and initialize the fields to reasonable values.
	 */
	frame = (Frame *)malloc_tagged(sizeof(Frame), TAG_FRAME);
	frame->handle = handle;
	frame->function = function;
	frame->scope = NullSym;
	frame->patient = NullPatient;
	frame->execPatient = curPatient;
	
	/*
	 * Ditto for our private data.
	 */
	privPtr = (FramePrivPtr)malloc_tagged(sizeof(FramePrivRec), TAG_MD);
	
	privPtr->flags = 0;
	privPtr->sp = sp;
	privPtr->ip = ip;
	privPtr->next = NullFrame;
	privPtr->prev = NullFrame;
	privPtr->stackHan = stackHan;
	privPtr->entryStackHan = NullHandle;
	privPtr->xipPage = curXIPPage;

	/*
	 * Default fp to bp, not entrySP, allowing ".enter inherit" to work.
	 * In such cases, we just have to trust that anything it calls will
	 * save the value. Else we're hosed (we'd be hosed anyway; this way
	 * we've got a fighting chance)
	 */
	Ibm_ReadRegister16 (REG_MACHINE, REG_BP, &privPtr->fp);
	
	if (stackHan != NullHandle) {
	    Var_FetchInt(2, stackHan, (Address)stackBotOff,
			 (genptr)&privPtr->stackBot);
	} else {
	    /*
	     * Not on a GEOS stack, so stackBot is unimportant (we hope)
	     */
	    privPtr->stackBot = 0;
	}
	
	/*
	 * Register interest in the handle so it doesn't go away.
	 */
	if (frame->handle != NullHandle) {
	    Handle_Interest(frame->handle, Ibm86FrameInterest, (Opaque)frame);
	}
	/*
	 * Ditto for the stack itself.
	 */
	if (privPtr->stackHan != NullHandle) {
	    Handle_Interest(privPtr->stackHan, Ibm86FrameStackInterest,
			    (Opaque)frame);
	}

	frame->private = (Opaque)privPtr;
	frame->patientPriv = (Opaque)NULL;
	
	
	if (!Sym_IsNull(function)) {
	    /*
	     * Fill in the scope and the patient as well, if actually in a
	     * known function.
	     */
	    frame->scope = scope;
	    frame->patient = Sym_Patient(scope);
	}
    } else {
	/*
	 * Re-use the top-most frame since it's still valid.
	 */
	frame = pPrivPtr->top;
	privPtr = (FramePrivPtr)frame->private;

	privPtr->flags &= ~VALIDATE;

	/*
	 * Adjust fp if same as previous sp (i.e. we're making up the
	 * frame pointer...)
	 */
	if (privPtr->fp == privPtr->sp) {
	    privPtr->fp = sp;
	}
	/*
	 * Adjust other fields to match the current state of affairs.
	 */
	privPtr->sp = sp;
	privPtr->ip = ip;

	/*
	 * Function hasn't changed, but the scope might have, so set that too.
	 */
	frame->scope = scope;
    }
    
    /*
     * Record the top-most frame and the thread we're in now and mark it
     * as no longer needing validation.
     */
    pPrivPtr->top = frame;
    pPrivPtr->thread = curPatient->curThread;

    curXIPPage = oldXIP;

    return(frame);
}
/***********************************************************************
 *				Ibm86CurrentFrame
 ***********************************************************************
 * SYNOPSIS:	  Decode the frame at the top of the stack
 * CALLED BY:	  Many people
 * RETURN:	  A Frame * for the top of the stack.
 * SIDE EFFECTS:  Previously-existing frames may be discarded.
 *
 * STRATEGY:
 *	See if the top frame is valid. If so, return it.
 *
 *	If not valid, fetch the CS:IP for the curPatient and map it to its
 * 	corresponding FUNCTION Sym.
 *
 *	If it matches that in the top frame, see if the return address
 *	stored in the frame and that in the stack are the same.
 *
 *	If so, mark the top frame as valid and return it.
 *
 *	Else, discard previous frames and build a new top and return it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static Frame *
Ibm86CurrentFrame(void)
{
    Frame   *fr;

    fr = Ibm86CurrentFrameCommon(FALSE, 0, 0, 0, 0);
    return fr;
}


/***********************************************************************
 *				Ibm86TallyStackUse
 ***********************************************************************
 * SYNOPSIS:	    Figure how much stuff is "definitely" on the stack
 *	    	    for the current frame. Note that this does not include
 *	    	    pushed registers, as those might have been popped
 *	    	    by now, and a wrong assumption here would cause
 *	    	    us to not decode the frame correctly.
 * CALLED BY:	    Ibm86NextFrame
 * RETURN:	    Adjustment value for sp
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static word
Ibm86TallyStackUse(Handle   handle, 	/* Handle of function */
		   Address  pc,	    	/* Start of function */
		   Address  ip)	    	/* Current IP in the function */
{
    word    	insn;
    word    	use = 0;

    /*
     * Make sure not at start of function (frame not set up)
     */
    if (pc >= ip) {
	goto done;
    }
    /*
     * Make sure not at the end of the function (return instruction), as frame
     * has been dismantled by then...
     */
    Var_FetchInt(2, handle, ip, (genptr)&insn);
    switch (insn & 0xff) {
	case 0xc3:  	/* Near return */
	case 0xc2:  	/* Near return w/pop */
	case 0xcb:  	/* Far return */
	case 0xca:  	/* Far return w/pop */
	    /*
	     * Frame must have been nuked by now, so don't cause caller to
	     * skip possible return address by returning non-zero. Tell caller
	     * the function used no stack space
	     */
	    return (0);
    }
    
    /*
     * Look for a frame setup, making sure not to look past where we're
     * executing.
     *
     * To do this, we sort of want something like this:
     *  PUSH  BP
     *  SUB   SP, #
     *  MOV   BP, SP
     * We don't insist on the SUB, though if it exists, and it may come
     * either before or after the MOV. Perhaps we should allow both? The
     * Microsoft C compiler prefers to use positive offsets from BP for
     * its local variables, so...
     */
    Var_FetchInt(2, handle, pc, (genptr)&insn);
    if ((insn & 0xff) == 0x55) {
	/*
	 * PUSH BP
	 */
	pc += 1;
	use += 2;
	
	if (pc >= ip) {
	    goto done;
	}
	Var_FetchInt(2, handle, pc, (genptr)&insn);
    }
	
    /*
     * Check for initial subtraction (locals addressed with positive offsets)
     */
    if (insn == 0xec81) {
	/*
	 * SUB SP, #
	 *
	 * Fetch the displacement and add that to the usage.
	 */
	word	disp;
	    
	Var_FetchInt(2, handle, pc + 2, (genptr)&disp);
	use += disp;
	goto done;
    } else if (insn == 0xec83) {
	/*
	 * SUB SP, #
	 *
	 * Fetch the byte displacement, sign-extend it and add that to the
	 * usage.
	 */
	byte    disp;
	
	Ibm_ReadBytes(1, handle, pc+2, (genptr)&disp);
	use += disp + ((disp & 0x80) ? 0xff00 : 0);
	goto done;
    }
    if (insn == 0xec8b) {
	/*
	 * MOV BP, SP
	 *
	 * Skip this and fetch the next instruction
	 */
	pc += 2;
	Var_FetchInt(2, handle, pc, (genptr)&insn);

	if (pc >= ip) {
	    goto done;
	}

	if (insn == 0xec81) {
	    /*
	     * SUB SP, #
	     *
	     * Fetch the displacement and add that to the usage.
	     */
	    word	disp;
	    
	    Var_FetchInt(2, handle, pc + 2, (genptr)&disp);
	    use += disp;
	} else if (insn == 0xec83) {
	    /*
	     * SUB SP, #
	     *
	     * Fetch the byte displacement, sign-extend it and add that to the
	     * usage.
	     */
	    byte    disp;
	    
	    Ibm_ReadBytes(1, handle, pc+2, (genptr)&disp);
	    use += disp + ((disp & 0x80) ? 0xff00 : 0);
	}
    }
done:

    return(use);
}    

/***********************************************************************
 *				Ibm86ProcessOnStack
 ***********************************************************************
 * SYNOPSIS:	    Process an ON_STACK symbol that specifies the
 *		    stack layout at this point in the execution.
 * CALLED BY:	    Ibm86NextFrame
 * RETURN:	    TRUE if processed successfully
 * SIDE EFFECTS:    savedRegs and flags in *privPtr are altered according
 *		    to what's in the stack descriptor.
 *
 *	    	    curXIPPage may change, possibly to something random,
 *		    but likely to the XIP page for the frame below the one
 *		    being decoded.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/29/92		Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86ProcessOnStack(Sym	    	    os,	    	/* ON_STACK symbol */
		    Handle  	    stack,  	/* Handle of stack currently
						 * active */
		    Frame   	    *prevFrame,	/* Frame before the one being
						 * decoded (for which we're
						 * searching for saved
						 * registers, etc.) */
		    FramePrivPtr    prevPrivPtr,/* Our private data for that */
		    FramePrivPtr    privPtr,	/* Private data for the new
						 * frame */
		    word    	    *spPtr) 	/* IN/OUT: SP, as we know it. */
{
    int 	    nosd;   	    /* Number of elements in the stack
				     * descriptor */
    char 	    **osd;  	    /* Array of elements that make up the
				     * descriptor */
    char	    *val;   	    /* Current element in osd */
    Reg_Data        *rd;    	    /* Register data for current element */
    int 	    i;	    	    /* Index into osd of val */
    const char	    *errmsg;	    /* Error message to print in warning if
				     * there's something wrong with the
				     * descriptor */
    word    	    sp = *spPtr;
    
    osd = Sym_GetOnStackData(os, &nosd);
    val = "be quiet, gcc";
    /*
     * Process all the registers first.
     */
    for (i = 0; i < nosd; i++) {
	/*
	 * Look for register data for the current element.
	 */
	val = (char *)osd[i];
	rd = (Reg_Data *)Private_GetData(val);

	if (rd == NULL) {
	    /*
	     * => specifies return address, so stop now.
	     */
	    break;
	}

	if (rd->type == REG_OTHER) {
	    if (strcmp((char *)rd->number, "xipPage") == 0) {
		word	xipPage;
		
		Var_FetchInt(2, stack, (Address)sp, (genptr)&xipPage);
		if (VALID_XIP(xipPage)) {
		    curXIPPage = prevPrivPtr->xipPage = xipPage;
		} else {
		    Warning("invalid XIP page %04xh ignored\n", xipPage);
		}
	    }
	} else if (rd->number == REG_SR) {
	    /*
	     * Special-case flags register.
	     */
	    privPtr->flags |= FLAGS_SAVED;
	    privPtr->flagsAddr = sp;
	} else {
	    /*
	     * All other registers have decent numbers we can use for setting
	     * bits and indexing savedRegs...
	     */
	    privPtr->flags |= (1 << rd->number);
	    privPtr->savedRegs[rd->number] = sp;
	}
	/*
	 * Another word on the stack used.
	 */
	sp += 2;
    }

    if (i >= nosd) {
	/*
	 * Getting here means we hit the end of the descriptor without finding
	 * something telling us where the return address is. Since a large
	 * part of the purpose of such a descriptor is to tell us this, we
	 * generate a warning and tell our caller it wasn't helpful after all.
	 */
	Patient	p;
	ID  	file;
	int 	line;

	errmsg = "no return address specified";

    error:
	
	if (Src_MapAddr(prevFrame->handle, (Address)prevPrivPtr->ip,
			&p, &file, &line))
	{
	    extern VMHandle idfile;
	    
	    idfile = p->symFile;
	    Warning("on_stack near \"%s\", line %d: %s",
		    file, line, errmsg);
	} else {
	    Warning("on_stack near ^h%04xh:%04xh: %s\n",
		    Handle_ID(prevFrame->handle), prevPrivPtr->ip, errmsg);
	}
	return(FALSE);
    }
		
    /*
     * Decode the return type.
     */
    if (strcmp(val, "retn") == 0) {
	/*
	 * Fetch the IP from the stack and use the segment of the prevFrame's
	 * handle as the segment of the return address.
	 */
	Var_FetchInt(2, stack, (Address)sp,
		     (genptr)&prevPrivPtr->retAddr.offset);
	prevPrivPtr->retAddr.segment = Handle_Segment(prevFrame->handle);
    } else if (strcmp(val, "retf") == 0) {
	/*
	 * Fetch the actual return address from the stack for later use and mark
	 * where CS was last saved (the segment portion of the return address).
	 */
	Var_Fetch(typeSegAddr, stack, (Address)sp,
		  (genptr)&prevPrivPtr->retAddr);
	privPtr->savedRegs[REG_CS] = sp + 2;
	privPtr->flags |= (1 << REG_CS);
    } else if (strcmp(val, "iret") == 0) {
	/*
	 * Fetch the actual return address from the stack for later use and
	 * note where both CS and the flags register were most-recently
	 * preserved.
	 */
	Var_Fetch(typeSegAddr, stack, (Address)sp,
		  (genptr)&prevPrivPtr->retAddr);
	privPtr->savedRegs[REG_CS] = sp + 2;
	privPtr->flags |= (1 << REG_CS)|FLAGS_SAVED;
	privPtr->flagsAddr = sp+4;
    } else if (strncmp(val, "ret=",4) == 0) {
	/*
	 * Return address in a register. Following element (either immediately
	 * after the = or separated from same by whitespace) is register...
	 */
	if (val[4] != '\0') {
	    val += 4;
	} else {
	    i++;
	    if (i == nosd) {
		errmsg = "\"ret=\" missing register";
		goto error;
	    }
	    val = osd[i];
	}
	rd = (Reg_Data *)Private_GetData(val);
	if (rd == NULL) {
	    errmsg = "invalid register for \"ret=\"";
	    goto error;
	}
	
	/*
	 * If previous has previous, look for the register in that frame.
	 * Otherwise we use the current value...
	 */
	if (prevPrivPtr->prev != NullFrame) {
	    Ibm86GetFrameRegister16(prevPrivPtr->prev,
				  rd->type,
				  rd->number,
				  &prevPrivPtr->retAddr.offset);
	} else {
	    Ibm_ReadRegister16(rd->type, rd->number,
			     &prevPrivPtr->retAddr.offset);
	}
	/*
	 * Return address is in same segment (can't retf through a register)
	 */
	prevPrivPtr->retAddr.segment = Handle_Segment(prevFrame->handle);
	prevPrivPtr->flags |= ALWAYS_VALID;

    } else if (strncmp(val, "stackbot", 8) == 0) {
	/*
	 * Return address is in funky reverse stack used for software
	 * interrupts... Need to subtract size of reverse frame (4 words) from
	 * the stackBot value we had, both in prev frame and one being
	 * built, then fetch the return address from the LCIIF_retAddr field
	 * (offset 0) of the LCI_infoFrame.
	 *
	 * XXX: Should be based on the structure and field names the way we
	 * get TPD_stackBot.
	 *
	 * 1/28/92: because of the fun stack arrangement, this frame's entrySP
	 * should be the same as the previous frame's entrySP, because it's as
	 * if this frame didn't actually exist, so the "return address" to this
	 * frame that we skipped, above, isn't actually here. -- ardeb
	 */
	char    fsizeStr[256];
	char	retoffStr[256] = "0";
	char	xipOffStr[256] = "";
	int 	fsize, retoff, xipPageOff = -1;
	
	if (sscanf(val, "stackbot=%[^.].%[^, \t],%s", fsizeStr, retoffStr,
		   xipOffStr) != 3 &&
	    sscanf(val, "stackbot=%[^.].%s", fsizeStr, retoffStr) != 2)
	{
	    /*
	     * Nothing special specified, so assume it's our 8-byte favorite
	     * format used by ResourceCallInt.
	     */
	    fsize = 8;
	    retoff = 0;
	} else {
	    /*
	     * Frame size specified, and possibly offset w/in it for the
	     * return address (retoffStr initialized to "0" to deal with only
	     * frame structure being specified).
	     */
	    char	*cp;
	    
	    fsize = cvtnum(fsizeStr, &cp);
	    if (*cp != '\0') {
		/*
		 * Frame size not numeric, so look for a symbol of that name.
		 */
		Sym 	ftype;
		
		ftype = Sym_Lookup(fsizeStr, SYM_TYPE,
				   prevFrame->patient->global);
		
		if (Sym_IsNull(ftype)) {
		    errmsg = "stackbot frame type undefined";
		    goto error;
		}
		fsize = Type_Sizeof(TypeCast(ftype));

		retoff = cvtnum(retoffStr, &cp);
		if (*cp != 0) {
		    /*
		     * Return offset not numeric, so look for a symbol of
		     * that name within the frame type.
		     */
		    Sym	    xipPageSym;
		    Sym	    retoffSym;

		    retoffSym = Sym_LookupInScope(retoffStr, SYM_FIELD, ftype);

		    if (Sym_IsNull(retoffSym)) {
			errmsg = "stackbot return address offset undefined";
			goto error;
		    }

		    /*
		     * Fetch the bit-offset of the field and convert that to
		     * a byte offset.
		     */
		    Sym_GetFieldData(retoffSym, &retoff,  (int *)NULL,
				     	(Type *)NULL, (Type *)NULL);
		    retoff /= 8;

		    /* if we are dealing with an XIP system, we must get
		     * the XIP page from the RCI_infoFrame struct */
		    if (realXIPPage != HANDLE_NOT_XIP) {
			if (*xipOffStr != '\0') {
			    xipPageSym = Sym_LookupInScope(xipOffStr,
							   SYM_FIELD, ftype);
			} else if (!strncmp(retoffStr, "RCIIF", 5)) {
			    xipPageSym = Sym_LookupInScope("RCIIF_oldPage", 
							   SYM_FIELD, ftype);
			} else {
			    xipPageSym = NullSym;
			}
			
			if (!Sym_IsNull(xipPageSym)) 
			{
			    Sym_GetFieldData(xipPageSym, &xipPageOff, 
			       	    (int *)NULL,(Type *)NULL, (Type *)NULL);
			    xipPageOff /= 8;
			}
		    }
		}
	    } else {
		/*
		 * Return offset must be numeric if frame size is numeric.
		 */
		retoff = cvtnum(retoffStr, &cp);

		/*
		 * Ditto for xip page offset, if given.
		 */
		if (realXIPPage != HANDLE_NOT_XIP && xipOffStr[0] != '\0') {
		    xipPageOff = cvtnum(xipOffStr, &cp);
		}
	    }
	}
	/*
	 * Extract the return address from the frame, ensuring its validity
	 * by looking for a software interrupt or far call 5 bytes before it,
	 * or a CallFN 4 bytes before it. This allows us to cope with the
	 * trickiness exhibited by ChunkArrayEnumCommon and COBJMESSAGE, which
	 * store things in the stack at stackBot for various reasons.
	 */
	prevPrivPtr->stackBot -= fsize;

	for ( ; prevPrivPtr->stackBot != 0; prevPrivPtr->stackBot -= 1) {
	    Handle  h;
	    word    xipPage;
	    word    oldXIP = curXIPPage;    /* in case not actually at frame
					     * start */

	    /*
	     * Fetch the return address from the proper place in the structure.
	     */
	    Var_Fetch(typeSegAddr, Ibm86StackHandle(),
		      (Address)prevPrivPtr->stackBot+retoff,
		      (genptr)&prevPrivPtr->retAddr);
	    
	    /*
	     * If this thing changed XIP contexts, fetch the old XIP page
	     * and set it as the current one.
	     */
	    if (realXIPPage != HANDLE_NOT_XIP && xipPageOff != -1)
	    {

		/* it's an XIP resource so we need to tell the stub what page
		 * it should assume would be mapped in to find the proper
		 * data for the given address
		 */
		oldXIP = curXIPPage;

		Var_Fetch(type_Word, Ibm86StackHandle(),
			  (Address)prevPrivPtr->stackBot+xipPageOff,
			  (genptr)&xipPage);

		if (VALID_XIP(xipPage)) {
		    curXIPPage = xipPage;
		} else {
		    continue;
		}
	    } else {
		xipPage = curXIPPage;
	    }

	    /*
	     * See if the segment points to a block (as it must for us to accept
	     * it).
	     */
	    h = Handle_Find(SegToAddr(prevPrivPtr->retAddr));

	    if ((h != NullHandle) &&
		(Handle_Segment(h) == prevPrivPtr->retAddr.segment))
	    {
		dword   inst;
		
		/*
		 * Fetch the four bytes that are 5 bytes before the return
		 * address, as it's easiest to get them all at once.
		 */
		Var_FetchInt(4, h, (Address)prevPrivPtr->retAddr.offset-5,
			     (genptr)&inst);
		/*
		 * Now look for the instruction sequences we allow.
		 */
		if ((((inst & 0xffff) >= 0x80cd) && /* check softint between */
		     ((inst & 0xffff) <= 0x8fcd)) ||/* 80h and 8fh -- the values
						     * used by the kernel */
		    ((inst & 0xff) == 0x9a) ||	    /* far call */
		    ((inst & 0xffff00) == 0xe80e00))/* CallFN */
		{
		    prevPrivPtr->xipPage = privPtr->xipPage = xipPage;
		    break;
		}
	    }

	    /*
	     * We weren't at the start of the frame, so set curXIPPage back
	     * again for next lookup.
	     */
	    if (realXIPPage != HANDLE_NOT_XIP) {
		curXIPPage = oldXIP;
	    }
	}
	assert(VALID_XIP(curXIPPage));
	/*
	 * Subtract the frame size we just determined from the stackBot for
	 * the previous frame, as that's what stackBot was on entry. This
	 * is also the value it was when we left the frame now being fetched.
	 */
	privPtr->stackBot = prevPrivPtr->stackBot;

	/*
	 * Record where CS was last saved and mark the frame as always
	 * being valid.
	 */
	privPtr->savedRegs[REG_CS] = privPtr->stackBot+retoff+2;
	privPtr->flags |= 1 << REG_CS;
	prevPrivPtr->flags |= ALWAYS_VALID|RET_AT_STACKBOT;

	/* target of ResourceCallInt is always far */
	sp -= 4;
    }
    /*
     * Default fp to bp, not entrySP, allowing
     * ".enter inherit" to work. In such cases, we just have
     * to trust that anything it calls will save the value.
     * Else we're hosed (we'd be hosed anyway; this way
     * we've got a fighting chance)
     */
    Ibm86GetFrameRegister16(prevFrame, REG_MACHINE, REG_BP,
			  &prevPrivPtr->fp);
    
    prevPrivPtr->entrySP = sp;
    prevPrivPtr->entryStackHan = stack;
    Handle_Interest(stack, Ibm86FrameStackInterest, (Opaque)prevFrame);

    free((char *)osd);
    *spPtr = sp;
    return(TRUE);
}


/***********************************************************************
 *				Ibm86NextFrame
 ***********************************************************************
 * SYNOPSIS:	  Decode and return the next frame down the stack.
 * CALLED BY:	  Many people
 * RETURN:	  The next frame down
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *	ardeb	11/27/88    	Changed to not use Ibm86BuildFrame. Now
 *				decodes the frame itself, thus keeping the
 *	    	    	    	finding of the return address to as late
 *				a point as possible.
 *
 ***********************************************************************/
static Frame *
Ibm86NextFrame(Frame 	*prevFrame)
{
    register Frame	*frame;	    	/* New frame to return */
    FramePrivPtr	privPtr;    	/* Our private data */
    FramePrivPtr  	prevPrivPtr;	/* Private data from previous frame */
    Handle  	    	handle;
    word    	    	sp;
    Address   	    	longPC;	    /* Offset of function start */
    Handle		stack;
    word	    	oldXIP = curXIPPage;

    prevPrivPtr = (FramePrivPtr)prevFrame->private;

    if (prevPrivPtr->next != (Frame *)NULL) {
	frame = prevPrivPtr->next;
	privPtr = (FramePrivPtr)frame->private;

	if (!(privPtr->flags & VALIDATE) || Ibm86FrameValid(frame)) {
	    privPtr->flags &= ~VALIDATE;
	    return(frame);
	} else {
	    Ibm86DestroyFrames(&prevPrivPtr->next);
	}
    } 
    if ((prevPrivPtr->flags & HAVE_RETADDR) &&
	(prevPrivPtr->retAddr.segment == 0) &&
	(prevPrivPtr->retAddr.offset == 0))
    {
	/*
	 * Hit the bottom of the stack last time. There are no more frames
	 * to decode.
	 */
	return(NullFrame);
    }

    /*
     * Allocate frame and initialize the fields to reasonable values.
     */
    frame = (Frame *)malloc_tagged(sizeof(Frame), TAG_FRAME);
    frame->handle = NullHandle;
    frame->function = NullSym;
    frame->scope = NullSym;
    frame->patient = NullPatient;
    frame->execPatient = prevFrame->execPatient;

    /*
     * Ditto for our private data.
     */
    privPtr = (FramePrivPtr)malloc_tagged(sizeof(FramePrivRec), TAG_MD);

    privPtr->flags = 0;
    privPtr->next = (Frame *)NULL;
    privPtr->prev = prevFrame;
    privPtr->xipPage = prevPrivPtr->xipPage;

    privPtr->entryStackHan = privPtr->stackHan = NullHandle;

    frame->private = (Opaque)privPtr;
    frame->patientPriv = (Opaque)NULL;


    /*
     * Build standard frame.
     * Since we've got the return address in the previous frame, there's
     * no need to look elsewhere. We only try and find the handle for the
     * function if the previous function is a FAR one. Otherwise, we can
     * just use the handle from the previous frame.
     */

    /*
     * Duplicate all registers saved by frames above the previous one,
     * along with their mask.
     */
    if (prevPrivPtr->flags & (REG_MASK&~(1 << REG_SP))) {
	bcopy((genptr)prevPrivPtr->savedRegs, (genptr)privPtr->savedRegs,
	      sizeof(privPtr->savedRegs));
	privPtr->flags |= (prevPrivPtr->flags & REG_MASK);
    }
    privPtr->stackBot = prevPrivPtr->stackBot;
    
    if (!(prevPrivPtr->flags & HAVE_RETADDR)) {
	/*
	 * If don't have the return address for the previous frame, we have
	 * to find it now.
	 */
	Boolean     	isFar;	    /* TRUE if current function is FAR */
	word		insn;	    /* Current instruction (when finding
				     * registers) */
	word   	    	ss; 	    /* Current SS register */
	unsigned long  	saved=0;    /* Registers we've already seen saved in
				     * this frame */
	prevPrivPtr->flags |= HAVE_RETADDR;

	if (Sym_IsNull(prevFrame->function)) {
	    /*
	     * If previous frame has no known function (?!), we've no chance
	     * of decoding any farther, so choke now.
	     */
no_next_frame:
	    prevPrivPtr->retAddr.segment = prevPrivPtr->retAddr.offset = 0;
	    /*
	     * Set entrySP and handle for previous frame to match sp and
	     * stackHan for previous frame, and register interest in the
	     * handle again, if such there be.
	     */
	    prevPrivPtr->entrySP = prevPrivPtr->sp;
	    prevPrivPtr->entryStackHan = prevPrivPtr->stackHan;
	    if (prevPrivPtr->entryStackHan != NullHandle) {
		Handle_Interest(prevPrivPtr->entryStackHan,
				Ibm86FrameStackInterest,
				(Opaque)prevFrame);
	    }
	    free((char *)privPtr);
	    free((char *)frame);
	    curXIPPage = oldXIP;
	    return(NullFrame);
	}
	/*
	 * If previous frame isn't top-most, load the frame pointer before that
	 * into sp. Otherwise, use the current machine register.
	 */
	if (prevPrivPtr->prev) {
	    FramePrivPtr prevPrevPrivPtr;

	    prevPrevPrivPtr = (FramePrivPtr)prevPrivPtr->prev->private;

	    /*
	     * Set XIP page context to that active in frame before previous
	     * so lookups for potential return addresses work right.
	     */
	    curXIPPage = prevPrevPrivPtr->xipPage;

	    if (Sym_IsFar(prevPrivPtr->prev->function)) {
		/*
		 * Frame before previous saved CS (since it's a FAR function),
		 * so skip both CS and IP in stack.
		 */
		sp = prevPrevPrivPtr->entrySP + 4;
	    } else if (prevPrevPrivPtr->flags & ALWAYS_VALID) {
		/*
		 * Frame before previous has retaddr in a register, so we don't
		 * need to (want to) skip anything.
		 */
		sp = prevPrevPrivPtr->entrySP;
	    } else {
		/*
		 * Frame before previous only saved IP, so just skip that.
		 */
		sp = prevPrevPrivPtr->entrySP + 2;
	    }
	    stack = prevPrevPrivPtr->entryStackHan;
	} else {
	    Ibm_ReadRegister16(REG_MACHINE, REG_SP, &sp);
	    stack = Ibm86StackHandle();
	    if (stack == NullHandle) {
		goto no_next_frame;
	    }
	    /*
	     * Set XIP page context to that for the current thread so
	     * lookups for potential return addresses work right.
	     */
	    Ibm_ReadRegister16(REG_OTHER, (int)"xipPage", &curXIPPage);
	}
	
	/*
	 * Find the function's start.
	 */
	Sym_GetFuncData(prevFrame->function, &isFar, &longPC, (Type *)NULL);

	/*
	 * Handle functions that dick with the stack.
	 */
	if (Sym_IsWeird(prevFrame->function) || 
	    Sym_IsInternalWeird(prevFrame->handle, prevPrivPtr->ip))
	{
	    Sym	    os = Sym_LookupAddr(prevFrame->handle,
					(Address)prevPrivPtr->ip,
					SYM_ONSTACK);
	    if (!Sym_IsNull(os) &&
		Ibm86ProcessOnStack(os, stack, prevFrame, prevPrivPtr, privPtr,
				    &sp))
	    {
		goto prev_decoded;
	    }
	}
	/*
	 * Skip over the stuff that has clearly been put on the stack by the
	 * prologue.
	 */
	sp += Ibm86TallyStackUse(prevFrame->handle, longPC,
				 (Address)prevPrivPtr->ip);

	/*
	 * Try and find a call to this routine. The stack should always be
	 * word-aligned, or else this will miss the return address. It should
	 * also be done for efficency's sake, but we won't go into that...
	 */
	if (!isFar) {
	    /*
	     * NEAR function. Only need to pay attention to same module.
	     *
	     * There are two types of call to which we pay attention. The
	     * direct call, where the offset to the function comes immediately
	     * after the opcode (0xe8), and the indirect call, whose encoding
	     * is 0xff /2. With the direct call, we can be 100% sure if it's a
	     * call to the right place. With the indirect call, we simply
	     * assume it's correct if there's one within the right region of
	     * the address on the stack. We have no guaranteed way to verify
	     * since the register through which the call was made, or the
	     * segment register used to address the pointer, may have been
	     * trashed, and we can't find where the current frame saved it
	     * until we find its return address. Catch-22.
	     */
	    word	  	retOffset;  /* Offset fetched from stack */
	    word	    	endStack;   /* Bottom of thread's stack */
	    
	    /*
	     * Find the bottom of the thread's stack.
	     */
	    endStack = Ibm86EndStack(stack);
	    
	    while(sp < endStack) {
		dword   	insn;
		
		/*
		 * Fetch the return offset first.
		 */
		Var_FetchInt(2, stack, (Address)sp,
			     (genptr)&retOffset);
		
		/*
		 * Now fetch the four bytes preceding that offset. Both types
		 * of calls will take at most four bytes, hence the number
		 * snagged.
		 */
		Var_FetchInt(4, prevFrame->handle, (Address)(retOffset - 4),
			     (genptr)&insn);
		if ((insn & 0xff00) == 0xe800) {
		    /*
		     * There's a near call at the right place (3 bytes before
		     * the return offset). See if the offset in the call is
		     * right.
		     */
		    if ((Address)((retOffset + (insn >> 16)) & 0xffff)==longPC)
		    {
			/*
			 * Got it.
			 */
			break;
		    }
		} else {
		    /*
		     * An indirect NEAR call is encoded using opcode 0xff with
		     * the REG field of the ModRM byte containing 2 (i.e.
		     * ModRM & 0x38 is 0x10). The following tests check both
		     * the REG field and the MOD field of the ModRM byte
		     * following the opcode.
		     */
		    if (((insn & 0xf8ff) == 0x90ff) || /* 16-bit displacement*/
			((insn & 0xf8ff00) == 0x50ff00) || /* 8-bit disp */
			((insn & 0xffff) == 0x16ff) || /* 16-bit address */
			((insn & 0xf8ff0000) == 0xd0ff0000)) /* word reg */
		    {
			/*
			 * There's a NEAR call at the right position to give us
			 * the desired return address. It's as close as we can
			 * get.
			 */
			break;
		    } else if (((insn & 0xf8ff0000) == 0x10ff0000) &&
			       ((insn & 0xffff0000) != 0x16ff0000))
		    {
			/*
			 * Ditto. Just needed to make sure it wasn't an
			 * absolute offset but was actually an index register
			 * with a 0 displacement.
			 */
			break;
		    }
		}
		/*
		 * That wasn't it. Try the next word down the stack
		 */
		sp += 2;

		if (sp == endStack &&
		    kernel != NULL &&	/* if only loader loaded, TBS not
					 * possible */
		    stack != kernel->resources[1].handle)   /* borrow doesn't
							     * happen if on
							     * kernel stack */
		{
		    /*
		     * Out of space in this block. Look for a link to another
		     * block containing stack data. The link is a handle/offset
		     * far pointer in the last 4 bytes of the stack block. If
		     * the handle is 0, we've hit the end of the chain.
		     */
		    Var_FetchInt(2, stack, (Address)endStack-2, (genptr)&ss);
		    if (ss != 0) {
			/*
			 * Link is there.
			 */
			Handle	nextStack = Handle_Lookup(ss);

			if (nextStack != NullHandle) {
			    /*
			     * We know the handle. Fetch the SP that continues
			     * things in that block and keep decoding.
			     */
			    Var_FetchInt(2, stack, (Address)endStack-4,
					 (genptr)&sp);
			    endStack = Handle_Size(nextStack);
			    stack = nextStack;
			}
		    }
		}
	    }

	    
	    /*
	     * Initialize retAddr to the address we found. Note that it's in
	     * the same segment...
	     */
	    prevPrivPtr->retAddr.segment = Handle_Segment(prevFrame->handle);
	    prevPrivPtr->retAddr.offset = retOffset;
	    /*
	     * If we're at the bottom of the stack, alter the return address to
	     * indicate this and return NULL, as there's not really a frame
	     * for us to get.
	     */
	    if (sp >= endStack) {
		goto no_next_frame;
	    }
	} else {
	    /*
	     * FAR call.
	     *
	     * We have the same problems here as we had with the NEAR call.
	     * See below for even more kludges required by the
	     * efficient pcgeos kernel.
	     */
	    word    endStack;   /* Bottom of thread's stack */
	    SegAddr routAddr;	/* Current routine's address (for easy
				 * comparison) */
	    SegAddr retAddr;    /* Return address on stack */
	    
	    /*
	     * Figure segment address of routine.
	     */
	    routAddr.segment = Handle_Segment(prevFrame->handle);
	    routAddr.offset = (word)longPC;
	    
	    /*
	     * Find the offset of the bottom of the thread's stack.
	     */
	    endStack = Ibm86EndStack(stack);
	    
	    /*
	     * Initialize retAddr with first doubleword from the stack.
	     * This allows us to use the segment from the previous value as
	     * the offset for the next when working up the stack.
	     */
	    Var_Fetch(typeSegAddr, stack, (Address)sp,
		      (genptr)&retAddr);
	    
	    while(sp < endStack) {
		unsigned char   op;
		Handle 	    	rhandle;
		
		/*
		 * Find the handle for the address. If there is no handle, it
		 * can't be right.
		 */
		rhandle = Handle_Find(SegToAddr(retAddr));

		/*
		 * Make sure we've got a handle whose base address is the same
		 * as the segment of the return address we're checking and
		 * whose data are actually resident. Note that it doesn't have
		 * to be code -- it's permissible to call from a data handle.
		 */
		if ((rhandle != NullHandle) &&
		    (Handle_State(rhandle) & HANDLE_IN) &&
		    (Handle_Segment(rhandle) == retAddr.segment))
		{
		    /*
		     * First look for a direct far call. This is opcode
		     * 0x9a and is followed by four bytes of long pointer.
		     * 4/11/93: added check for call to one of the
		     * ProcCallFixedOrMovable routines, which leave nothing
		     * on the stack and make it a pain to backtrace through
		     * them. -- ardeb.
		     */
		    unsigned long	insn;
		    
		    Ibm_ReadBytes(1, rhandle, (Address)(retAddr.offset-5),
				  (genptr)&op);
		    
		    if (op == 0x9a) {
			SegAddr 	dest;
			
			Var_Fetch(typeSegAddr, rhandle,
				  (Address)(retAddr.offset - 4),
				  (genptr)&dest);
			
			if (((dest.segment == routAddr.segment) &&
			     (dest.offset == routAddr.offset)) ||
			    ((dest.segment == pcfom.segment) &&
			     (dest.offset == pcfom.offset)) ||
			    ((dest.segment == pcfomPascal.segment) &&
			     (dest.offset == pcfomPascal.offset)) ||
			    ((dest.segment == pcfomCdecl.segment) &&
			     (dest.offset == pcfomCdecl.offset)))
			{
			    break;
			}
		    }
		    /*
		     * Fetch four-bytes before address as we'll need them
		     * for all further checks.
		     */
		    Var_FetchInt(4, rhandle, (Address)(retAddr.offset - 4),
				 (genptr)&insn);
		    
		    /*
		     * Deal with indirect CallFN. This thing can be
		     * up to 6 bytes long (PUSH CS is 1 byte, indirect
		     * near call can be up to 5: override, op, modrm, disp)
		     * First see if the 5th byte is a PUSH CS. If not,
		     * and the 5th byte is a segment override, check
		     * the byte before that.
		     *
		     * The other part of dealing with the indirect CallFN
		     * (one in the four bytes before the address) is taken
		     * care of later on.
		     */
#if REGS_32
                    if ((op == 0x0e) ||
			(((op & 0xe7) == 0x26) &&  /* CS: DS: ES: or SS: */
			 Ibm_ReadBytes(1, rhandle,
				       (Address)(retAddr.offset-6),
				       (genptr)&op) &&
			 (op == 0x0e)) ||
			(((op & 0xFE) == 0x64) &&  /* FS: or GS: */
			 Ibm_ReadBytes(1, rhandle,
				       (Address)(retAddr.offset-6),
				       (genptr)&op) &&
			 (op == 0x0e)))
#else
                    if ((op == 0x0e) ||
			(((op & 0xe7) == 0x26) &&
			 Ibm_ReadBytes(1, rhandle,
				       (Address)(retAddr.offset-6),
				       (genptr)&op) &&
			 (op == 0x0e)))
#endif
                    {
			/*
			 * PUSH CS in the right place. How about
			 * indirect near call?
			 */
			if (((insn&0x0000f8ff)==0x000090ff) ||/*wd w[r]*/
			    ((insn&0x00f8ffe7)==0x0050ff26) ||/*wd s:b[r]*/
			    ((insn&0x0000ffff)==0x000016ff))  /*wd dir*/
			{
			    /*
			     * There's a NEAR call at the right position
			     * to give us the desired return address. It's
			     * as close as we can get.
			     */
			    break;
			}
		    }
		    
		    /*
		     * No direct far call or indirect CallFN. See if
		     * there's a direct CallFN. This is PUSH CS (0eh)
		     * followed by a direct near CALL (0e8h...).
		     *
		     * 1/6/95: More coping with the ProcCallFixedOrMovable
		     * fiends. Look for a CallFN to one of them -- ardeb
		     */
		    if ((insn & 0xffff) == 0xe80e) {
			word retOff;

			retOff = (word)retAddr.offset + ((insn >> 16) & 0xffff);

			if ((retOff == routAddr.offset) ||
			    ((retAddr.segment == pcfom.segment) &&
			     (retOff == pcfom.offset)) ||
			    ((retAddr.segment == pcfomPascal.segment) &&
			     (retOff == pcfomPascal.offset)) ||
			    ((retAddr.segment == pcfomCdecl.segment) &&
			     (retOff == pcfomCdecl.offset)))
			{
			    break;
			}
		    }
		    
		    /*
		     * No direct far call, no CallFN, see if there's an
		     * indirect one around here somewhere.
		     * The encoding for an indirect far call is ff /3
		     * Also look for an indirect CallFN without override
		     * and with 8-bit or no displacement, or with override
		     * but no displacement 
		     */
		    if (((((insn&0xf8ffff00) == 0x10ff0e00) ||/* wd [r] */
			  ((insn&0xf8ffe7ff) == 0x10ff260e) ||/* wd s:[r]*/
			  ((insn&0xf8ff0000) == 0x18ff0000))&&/* dw [r] */
			 ((insn&0xc7000000) != 0x06000000)) ||
			((insn&0xf8ffff00) == 0xd0ff0e00) || /* rw */
			((insn&0x00f8ffff) == 0x0050ff0e) || /* wd b[r] */
			((insn&0x0000f8ff) == 0x000090ff) || /* wd w[r] */
			((insn&0x0000f8ff) == 0x000098ff) || /* dw w[r] */
			((insn&0x00f8ff00) == 0x0058ff00) || /* dw b[r] */
			((insn&0x0000ffff) == 0x00001eff))   /* dw dir */
		    {
			/*
			 * There's a FAR call or CallFN at the right
			 * position to give us the desired return address.
			 * It's as close as we can get.
			 */
			break;
		    } else if (((insn&0xf8ff0000) == 0x18ff0000) &&
			       ((insn&0xffff0000) != 0x1eff0000))
		    {
			/*
			 * Ditto. Just needed to make sure it wasn't
			 * an absolute offset but was actually an
			 * index register with a 0 displacement.
			 */
			break;
		    }
		}
		/*
		 * Move up the stack one word. The previous segment becomes the
		 * new offset and we read a new segment from the stack.
		 */
		sp += 2;

		if (sp+2 >= endStack &&
		    kernel != NULL &&	/* if only loader loaded, TBS not
					 * possible */
		    stack != kernel->resources[1].handle)   /* borrow doesn't
							     * happen if on
							     * kernel stack */
		{
		    /*
		     * Out of space in this block. Look for a link to another
		     * block containing stack data. The link is a handle/offset
		     * far pointer in the last 4 bytes of the stack block. If
		     * the handle is 0, we've hit the end of the chain.
		     */
		    Var_FetchInt(2, stack, (Address)endStack-2, (genptr)&ss);
		    if (ss != 0) {
			/*
			 * Link is there.
			 */
			Handle	nextStack = Handle_Lookup(ss);

			if (nextStack != NullHandle) {
			    /*
			     * We know the handle. Fetch the SP that continues
			     * things in that block and keep decoding.
			     */
			    Var_FetchInt(2, stack, (Address)endStack-4,
					 (genptr)&sp);
			    endStack = Handle_Size(nextStack);
			    stack = nextStack;
			}
		    }
		    Var_Fetch(typeSegAddr, stack, (Address)sp,
			      (genptr)&retAddr);
		} else {
		    retAddr.offset = retAddr.segment;
		    Var_FetchInt(2, stack, (Address)(sp + 2),
				 (genptr)&retAddr.segment);
		}
	    }
	    prevPrivPtr->retAddr = retAddr;
	    /*
	     * If we're at the bottom of the stack, alter the return address to
	     * indicate this and return Null.
	     */
	    if (sp >= endStack) {
		goto no_next_frame;
		     
	    } else {
		/*
		 * Remember where CS was saved.
		 */
		privPtr->savedRegs[REG_CS] = sp + 2;
		privPtr->flags |= (1 << REG_CS);
	    }
	}
	prevPrivPtr->entrySP = sp;
	prevPrivPtr->entryStackHan = stack;
	
	Handle_Interest(stack, Ibm86FrameStackInterest, (Opaque)prevFrame);
		

	/*
	 * Default fp to bp, not entrySP, allowing ".enter inherit" to work.
	 * In such cases, we just have to trust that anything it calls will
	 * save the value. Else we're hosed (we'd be hosed anyway; this way
	 * we've got a fighting chance)
	 */
	Ibm86GetFrameRegister16(prevFrame, REG_MACHINE, REG_BP,
			      &prevPrivPtr->fp);
	
	/*
	 * Once we know where the return address is, we can find what registers
	 * this frame saves.
	 *
	 * First determine the stack pointer when the registers were pushed.
	 * To do this, we sort of want something like this:
	 *  PUSH  BP
	 *  SUB   SP, #
	 *  MOV   BP, SP
	 * We don't insist on the SUB, though if it exists, and it may come
	 * either before or after the MOV. Perhaps we should allow both? The
	 * Microsoft C compiler prefers to use positive offsets from BP for
	 * its local variables, so...
	 */
	if ((word)longPC >= prevPrivPtr->ip) {
	    /*
	     * This snippet of code is used to determine if our decoding
	     * of the prologue has gone past the actual execution of the
	     * function by the machine, i.e. if the instructions we're
	     * decoding haven't been executed yet.
	     */
	    goto prev_decoded;
	}
	Var_FetchInt(2, prevFrame->handle, longPC, (genptr)&insn);
#define MARK_SAVED(reg,addr) \
	if (!(saved & (1<<(reg)))) {\
	    privPtr->savedRegs[reg] = (addr);\
	    saved |= (1 << (reg));\
	    privPtr->flags |= (1<<(reg));\
	}

	/*XXX: check for sp <= prevPrivPtr->prev->private->entrySP*/

	/*
	 * Now for the saving of registers. We allow for PUSHA and PUSH
	 * instructions. The MARK_SAVED macro ensures that we record only
	 * the first time a register is pushed.
	 */

	while ((word)longPC < prevPrivPtr->ip) {
	    if ((insn == 0xec81) || (insn == 0xec83)) {
		/*
		 * SUB SP, #
		 *
		 * Fetch the displacement and subtract it from SP.
		 */
		if (insn == 0xec81) {
		    /*
		     * word displacement.
		     */
		    word	disp;
		
		    Var_FetchInt(2, prevFrame->handle, longPC + 2,
				 (genptr)&disp);
		    sp -= disp;
		    longPC += 4;
		} else {
		    byte	disp;
		
		    Ibm_ReadBytes(1, prevFrame->handle, longPC+2,
				  (genptr)&disp);
		    sp -= disp + ((disp & 0x80) ? 0xff00 : 0);
		    longPC += 3;
		}
		/*
		 * Cope with push-initialized local variables, throwing away
		 * the addresses of all the registers other than BP that have
		 * been saved by this frame to this point, as they are all
		 * for push-initialized locals (and thus might be changed
		 * during the course of the function; we don't want to give the
		 * impression that we've accurately found the value of the
		 * register in the previous frame when we haven't).
		 */
		privPtr->flags &= ~(saved & ~(1<<REG_BP));
		if (saved & ~(1 << REG_BP)) {
		    /*
		     * Recover the addresses of anything we overwrote from
		     * the previous frame.
		     */
		    int	    i;

		    for (i = 0; i < NUM_REGS; i++) {
			if ((i != REG_BP) && (i != REG_SP) &&
			    (prevPrivPtr->flags & (1 << i)))
			{
			    privPtr->savedRegs[i] = prevPrivPtr->savedRegs[i];
			    privPtr->flags |= (1 << i);
			}
		    }
		    if (prevPrivPtr->flags & FLAGS_SAVED) {
			privPtr->flagsAddr = prevPrivPtr->flagsAddr;
			privPtr->flags |= FLAGS_SAVED;
		    }
		}
		/*
		 * Mark only BP saved by this frame, if it was.
		 */
		saved &= 1 << REG_BP;
	    } else if (insn == 0xec8b) {
		/*
		 * MOV BP, SP
		 *
		 * Record the current SP as the frame pointer for the frame.
		 */
		longPC += 2;
		prevPrivPtr->fp = sp;
	    } else if ((insn & 0xff) == 0x60) {
		/*
		 * PUSHA
		 *
		 * Registers are pushed: AX, CX, DX, BX, SP, BP, SI, DI
		 */
		sp -= 2;
		MARK_SAVED(REG_AX,sp);
		sp -= 2;
		MARK_SAVED(REG_CX,sp);
		sp -= 2;
		MARK_SAVED(REG_DX,sp);
		sp -= 2;
		MARK_SAVED(REG_BX,sp);
		sp -= 2;
		MARK_SAVED(REG_SP,sp);
		sp -= 2;
		MARK_SAVED(REG_BP,sp);
		sp -= 2;
		MARK_SAVED(REG_SI,sp);
		sp -= 2;
		MARK_SAVED(REG_DI,sp);
		
		longPC += 1;
	    } else if ((insn & 0xff) == 0x9c) {
		/*
		 * PUSHF
		 */
		sp -= 2;
		if (!(saved & FLAGS_SAVED)) {
		    privPtr->flagsAddr = sp;
		    privPtr->flags |= FLAGS_SAVED;
		    saved |= FLAGS_SAVED;
		}
		longPC += 1;
	    } else if ((insn & 0xf8) == 0x50) {
		/*
		 * Push of a word register. Make sure it's not being
		 * used for a two-byte MOV by seeing if the next
		 * instruction is a POP.
		 */
		if (((insn & 0xf800) != 0x5800) &&  /* POP rw */
		    ((insn & 0xe700) != 0x0700))    /* POP seg */
		{
		    /*
		     * Nope. It's valid. Decrement the current SP and
		     * store the result in the appropriate slot of
		     * savesReg
		     */
		    sp -= 2;
		    MARK_SAVED(insn&0x7, sp);
		    
		    /*
		     * Go to next instruction
		     */
		    longPC += 1;
		} else {
		    /*
		     * Followed immediately by a pop -- ignore it.
		     * Advance PC beyond the pop and leave SP alone.
		     */
		    longPC += 2;
		}
	    } else if ((insn & 0xe7) == 0x06) {
		/*
		 * PUSH seg
		 */
		if (((insn & 0xf800) != 0x5800) &&	/* POP word? */
		    ((insn & 0xe700) != 0x0700)) 	/* POP seg? */
		{
		    /*
		     * A valid PUSH of a segment register (not followed by a
		     * POP). Update SP, save address and advance to next opcode
		     */
		    int	    reg;
		
		    reg = 8 + ((insn & 0x18) >> 3);
		    if (reg != REG_CS) {
			sp -= 2;
			MARK_SAVED(reg,sp);
		
		    } else if (((insn & 0xff00) == 0xe8) || /* near call? */
			       ((insn & 0x38ff00) == 0x10ff00)) /* ind near call? */
		    {
			/*
			 * Push of CS followed by a near call -- prologue
			 * finished.
			 */
			break;
		    } else {
			/*
			 * Take push into account, but do not claim CS is saved
			 * here...can mess up backtraces big time.
			 * -- ardeb 8/28/92
			 */
			sp -= 2;
		    }
		    longPC += 1;
		} else {
		    /*
		     * Push followed by a POP -- ignore both.
		     */
		    longPC += 2;
		}
	    } else {
		/*
		 * Some other instruction that signals end of the prologue.
		 */
		break;
	    }
	    /*
	     * Fetch next instruction for next loop.
	     */
	    Var_FetchInt(2, prevFrame->handle, longPC, (genptr)&insn);
	}

    }

    prev_decoded:
	
    /*
     * Update the XIP page for this new frame to match that determined for
     * the previous one, in case it changed
     */
    privPtr->xipPage = prevPrivPtr->xipPage;

    /*
     * If the previous frame contains a FAR function, or it saved CS (it's a
     * weird function that's actually NEAR but has a FAR return address [e.g.
     * ExitGraphics and Joe Code things like it]), use the whole return
     * address from the previous frame.
     */
    if (privPtr->flags & (1 << REG_CS)) {
	handle = Handle_Find(SegToAddr(prevPrivPtr->retAddr));
	if (handle == NullHandle) {
	    Warning("Can't find handle for function %04xh:%04xh",
		    prevPrivPtr->retAddr.segment,
		    prevPrivPtr->retAddr.offset);
	    curXIPPage = oldXIP;
	    free((malloc_t)frame);
	    free((malloc_t)privPtr);
	    return(NullFrame);
	}
    } else {
	handle = prevFrame->handle;
    }

    frame->handle = handle;
    /*
     * Register interest in the handle so it doesn't go away.
     */
    if (frame->handle != NullHandle) {
	Handle_Interest(frame->handle, Ibm86FrameInterest, (Opaque)frame);
    }
    privPtr->sp = prevPrivPtr->entrySP;
    privPtr->stackHan = prevPrivPtr->entryStackHan;
    privPtr->ip = prevPrivPtr->retAddr.offset;
    privPtr->flags |= (IP_SAVED|(1 << REG_SP));

    /*
     * Register interest in the stack handle so it doesn't go away.
     */
    if (privPtr->stackHan != NullHandle) {
	Handle_Interest(privPtr->stackHan, Ibm86FrameStackInterest,
			(Opaque)frame);
    }

    frame->function = Sym_LookupAddr(handle, (Address)privPtr->ip,
				     SYM_FUNCTION);
    if (!Sym_IsNull(frame->function)) {
	Sym_GetFuncData(frame->function, (Boolean *)NULL, &longPC,
			(Type *)NULL);
	if ((word)longPC == privPtr->ip) {
	    /*
	     * If the function is right at the address, it can't be the one we
	     * want (think about it), so try again, subtracting 1 from the ip.
	     * This is mostly to support calls to FatalError at the ends of
	     * functions...
	     */
	    frame->function = Sym_LookupAddr(handle, (Address)privPtr->ip-1,
					 SYM_FUNCTION);
	}
    
	/*
	 * Fill in the scope and the patient as well, if actually in a known
	 * function.
	 */
	frame->scope = Sym_LookupAddr(handle, (Address)privPtr->ip, SYM_SCOPE);
	frame->patient = Sym_Patient(frame->scope);
    }

    prevPrivPtr->next = frame;

    curXIPPage = oldXIP;

    return(frame);
}

/***********************************************************************
 *				Ibm86GetFrame
 ***********************************************************************
 * SYNOPSIS:	  Decode and return the next frame down the stack.
 * CALLED BY:	  Many people
 * RETURN:	  The next frame down
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *	ardeb	11/27/88    	Changed to not use Ibm86BuildFrame. Now
 *				decodes the frame itself, thus keeping the
 *	    	    	    	finding of the return address to as late
 *				a point as possible.
 *
 ***********************************************************************/
static Frame *
Ibm86GetFrame(word ss, word sp, word cs, word ip)
{
    /* set up a new frame using ss:sp and cs:ip */
    return Ibm86CurrentFrameCommon(TRUE, cs, ip, ss, sp);
}

/***********************************************************************
 *				Ibm86CopyFrame
 ***********************************************************************
 * SYNOPSIS:	    Make a copy of a frame
 * CALLED BY:	    GLOBAL
 * RETURN:	    The new frame
 * SIDE EFFECTS:    Memory be allocated...
 *
 * STRATEGY:	    Not really
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 3/88	Initial Revision
 *
 ***********************************************************************/
static Frame *
Ibm86CopyFrame(Frame *frame)
{
    Frame   	    *newFrame;
    FramePrivPtr    newPrivPtr;

    newFrame = (Frame *)malloc_tagged(sizeof(Frame), TAG_FRAME);
    newPrivPtr = (FramePrivPtr)malloc_tagged(sizeof(FramePrivRec), TAG_MD);

    *newFrame = *frame;
    *newPrivPtr = *(FramePrivPtr)frame->private;
    newFrame->private = (Opaque)newPrivPtr;

    /*
     * Register interest in the handle so it doesn't go away.
     */
    if (newFrame->handle != NullHandle) {
	Handle_Interest(newFrame->handle, Ibm86FrameInterest,
			(Opaque)newFrame);
    }

    /*
     * Ditto for the two stack handles
     */
    if (newPrivPtr->stackHan != NullHandle) {
	Handle_Interest(newPrivPtr->stackHan, Ibm86FrameStackInterest,
			(Opaque)newFrame);
    }

    if (newPrivPtr->entryStackHan != NullHandle) {
	Handle_Interest(newPrivPtr->entryStackHan, Ibm86FrameStackInterest,
			(Opaque)newFrame);
    }

    /*
     * Copied frames have no links unless created later.
     */
    newPrivPtr->prev = newPrivPtr->next = (Frame *)NULL;
    
    newPrivPtr->flags |= FRAME_COPIED;
    return(newFrame);
}

GeosAddr 
Ibm86FrameRetaddr(Frame *frame)
{
    GeosAddr	result;
    FramePrivPtr    privPtr = (FramePrivPtr)frame->private;

    result.handle = (Handle)privPtr->retAddr.segment;
    result.offset = (Address)privPtr->retAddr.offset;
    return result;
}

/***********************************************************************
 *				Ibm86PrevFrame
 ***********************************************************************
 * SYNOPSIS:	  Return the frame previous to this one, if any.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The Frame * for the previous frame, or NullFrame if none.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Just looks at the prev pointer in the frame's private data.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static Frame *
Ibm86PrevFrame(Frame	*frame)
{
    Frame   *fr;

    fr = ((FramePrivPtr)frame->private)->prev;
    return fr;
}

/***********************************************************************
 *				Ibm86FrameValid
 ***********************************************************************
 * SYNOPSIS:	  See if the given frame is still valid.
 * CALLED BY:	  GLOBAL
 * RETURN:	  TRUE if it's valid
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	Two numbers are kept with the frame to figure this out. The first
 *	is the stack pointer when the frame was entered (stored in
 *	frame->private->entrySP). The second is the return address for
 *	the frame (in frame->private->retAddr). If the stack has retreated
 *	above the start of the frame, or the value stored at the start
 *	of the frame doesn't match the return address we have, the frame
 *	is no longer valid.
 *	The assumption is that the return address is sufficiently
 *	magical to be different if another call is made or the frame
 *	is overwritten.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static Boolean
Ibm86FrameValid(const Frame	*frame)
{
    word 	  	sp;
    FramePrivPtr  	privPtr;
    Ibm86PrivPtr    	pPrivPtr;
    Handle		stack;

    /*
     * See if the frame is out-of-bounds before trying to reference through
     * it. 
     */
    if (!VALIDTPTR(frame, TAG_FRAME)) {
	return(FALSE);
    }
    
    pPrivPtr = (Ibm86PrivPtr)curPatient->mdPriv;

    if ((pPrivPtr->top == NullFrame) ||
	((((FramePrivPtr)pPrivPtr->top->private)->flags & VALIDATE) &&
	 (frame != pPrivPtr->top)))
    {
	/*
	 * If the whole set of cached frames for the patient need to be
	 * validated and this isn't the top-most frame for the stack
	 * being checked, revalidated the whole mess of them.
	 */
	return(Ibm86ValidateCachedFrames(pPrivPtr,
					 (word *)NULL,
					 (word *)NULL,
					 (word *)NULL,
					 (word *)NULL,
					 (Sym *)NULL,
					 (Sym *)NULL,
					 (Handle *)NULL,
					 (Handle *)NULL,
					 FALSE));
    }
    
    privPtr = (FramePrivPtr)frame->private;

    if (!VALIDTPTR(privPtr->entryStackHan, TAG_HANDLE) ||
	(privPtr->flags & ALWAYS_VALID))
    {
	/*
	 * Patient switched stacks, or we have no idea in what patient we're
	 * executing, or the frame is marked as always being valid,
	 * so assume the frame's valid...(makes other things a
	 * little easier [e.g. if this is the current frame, we can still
	 * access registers, etc.])
	 */
	return(TRUE);
    }

    stack = Ibm86StackHandle();
    Ibm_ReadRegister16(REG_MACHINE, REG_SP, &sp);

    if (!(privPtr->flags & HAVE_RETADDR)) {
	/*
	 * Haven't decoded the return address, so we can't tell...If things
	 * farther down are ok, though, this one is too, and if this is
	 * the top-most and we're being called by Ibm86CurrentFrame, it
	 * will alter anything that needs altering, so no harm is done.
	 */
	return(TRUE);
    } else if (stack != privPtr->entryStackHan) {
	/*
	 * Frame is from a saved stack block that still exists, so we
	 * assume it's still valid.
	 */
	return(TRUE);
    } else if (sp > privPtr->entrySP) {
	/*
	 * Stack pointer now above that for this frame.
	 */
	return(FALSE);
    } else if (privPtr->retAddr.segment || privPtr->retAddr.offset) {
	/*
	 * Not the bottom-most frame in the stack (we assume the bottom-most
	 * frame is always valid unless sp has risen above its entrySP)
	 */
	if (Sym_IsFar(frame->function)) {
	    SegAddr	retAddr;

	    Var_Fetch(typeSegAddr, stack, (Address)privPtr->entrySP,
		      (genptr)&retAddr);

	    if ((retAddr.segment != privPtr->retAddr.segment) ||
		(retAddr.offset != privPtr->retAddr.offset))
	    {
		return(FALSE);
	    }
	} else {
	    word    retOffset;

	    Var_FetchInt(2, stack, (Address)privPtr->entrySP,
			 (genptr)&retOffset);
	    if (privPtr->retAddr.offset != retOffset) {
		return(FALSE);
	    }
	}
    }
    return(TRUE);
}

/*****************************************************************************
 *									     *
 *	    	    INSTRUCTION DECODING FOR FUN AND PROFIT		     *
 *	    	   (well, disassembly and stepping, actually)		     *
 *									     *
 *****************************************************************************/
typedef struct {
    char    	**bufferPtr;
    dword   	value;
    int	    	numClear;
    Boolean    	printingInverse;
} Ibm86PRData;


/***********************************************************************
 *				Ibm86PrintRecordFlags
 ***********************************************************************
 * SYNOPSIS:	    Format an immediate value as a set of flags: a field's
 *	    	    name is placed in the buffer if its bit is set.
 * CALLED BY:	    Ibm86PrintRecordEA via Type_ForEachField
 * RETURN:	    FALSE (continue traversal)
 * SIDE EFFECTS:    *bufferPtr is advanced
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86PrintRecordFlags(Type	    base,  	/* Base (record) type */
		      const char    *fieldName,	/* Name of this field */
		      int 	    fieldOffset,/* Bit offset of this field */
		      int 	    fieldLength,/* Bit length of this field */
		      Type	    fieldType,  /* Type of this field */
		      Opaque	    clientData) /* Pointer to Ibm86PRData */
{
    Ibm86PRData	    *data = (Ibm86PRData *)clientData;

    if (fieldLength == 1) {
	if (data->value & (1 << fieldOffset)) {
	    /*
	     * Place a comma and space before the field name. We can do this b/c
	     * we need a separator after the dest value anyway, not having
	     * put one in in Ibm86PrintRecordEA (for this reason, of course)
	     */
	    sprintf(*data->bufferPtr,
		    (data->printingInverse ? "%s" : ", %s"),
		    fieldName);
	    *data->bufferPtr += strlen(*data->bufferPtr);
	} else {
	    data->numClear += 1;
	}
    }

    return(FALSE);
}

/***********************************************************************
 *				Ibm86PrintRecordField
 ***********************************************************************
 * SYNOPSIS:	    Print the immediate value as a succession of
 *	    	    fields from the record.
 * CALLED BY:	    Ibm86PrintRecordEA via Type_ForEachField
 * RETURN:	    FLASE (keep going)
 * SIDE EFFECTS:    *bufferPtr is advanced.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86PrintRecordField(Type	    base,      	/* Base (record) type */
		      const char    *fieldName, /* Name of this field */
		      int 	    fieldOffset,/* Bit offset of this field */
		      int 	    fieldLength,/* Bit length of this field */
		      Type	    fieldType,  /* Type of this field */
		      Opaque	    clientData) /* Pointer to Ibm86PRData */
{
    Ibm86PRData	    *data = (Ibm86PRData *)clientData;

    if (*fieldName != '\0') {
	unsigned value = (data->value>>fieldOffset) & ((1 << fieldLength) - 1);
	
	if (Type_Class(fieldType) != TYPE_ENUM) {
	    sprintf(*data->bufferPtr, ", %s=%d", fieldName, value);
	} else {
	    sprintf(*data->bufferPtr, ", %s=%s", fieldName,
		    Type_GetEnumName(fieldType, (int)value));
	}

	*data->bufferPtr += strlen(*data->bufferPtr);
    }
    return(FALSE);
}


/***********************************************************************
 *				Ibm86SeeIfFlags
 ***********************************************************************
 * SYNOPSIS:	    Callback function to determine if a record is
 *	    	    all flags. Any field larger than a bit whose name
 *	    	    doesn't end in "UNUSED" is ineligible.
 * CALLED BY:	    Ibm86PrintRecordEA via Type_ForEachField
 * RETURN:	    TRUE if not flags, FALSE if still flags
 * SIDE EFFECTS:    If not flags, FALSE is stored in Boolean pointed
 *	    	    to by clientData
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 4/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86SeeIfFlags(Type	    base,   	    /* Base (record) type */
		const char  *fieldName,	    /* Name of this field */
		int 	    fieldOffset,    /* Bit offset of this field */
		int 	    fieldLength,    /* Bit length of this field */
		Type	    fieldType,	    /* Type of this field */
		Opaque	    clientData)	    /* Pointer to isFlags */
{
    Boolean 	*isFlagsPtr = (Boolean *)clientData;

    if ((fieldLength == 1) || (*fieldName == '\0')) {
	return(FALSE);		/* Keep searching */
    } else {
	*isFlagsPtr = FALSE;
	return(TRUE);		/* Stop searching */
    }
}

/***********************************************************************
 *				Ibm86PrintRecordEA
 ***********************************************************************
 * SYNOPSIS:	    Print out access to a record. There are two cases:
 *	    	    	- immediate data: Figure out which bits
 *	    	    	  and print them, separated by commas, following
 *			  the name of the variable
 *	    	    	- other: just strip off the last field name in the
 *			  field name we were given and print what's left.
 * CALLED BY:	    PrintEA
 * RETURN:	    Nothing
 * SIDE EFFECTS:    *bufferPtr is advanced
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 3/89		Initial Revision
 *
 ***********************************************************************/
static void
Ibm86PrintRecordEA(char	    	    **bufferPtr,/* Place to store name */
		   const GeosAddr   *eaPtr,	/* Address being printed */
		   const I86Opcode  *op,	/* Opcode involved */
		   const OperandSize *vals,    	/* Operand values */
		   int	    	    valIdx,    	/* Index into vals of ea */
		   char  	    *fieldName,	/* Field name determined so
						 * far */
		   Sym	    	    sym,    	/* Closest variable */
		   Type	    	    type,    	/* Type of variable */
		   Address  	    realOffset)	/* Offset of variable */
{
    char    	*cp;

    /*
     * Trim off the final component (the record field name) from the name
     * found so far. If there's only one component, just print the name
     * of the variable. The beast is followed by an = if valIdx is 0 or 1
     * (i.e. there's a value that needs to be printed).
     */
    cp = rindex(fieldName, '.');
    if (cp == NULL) {
	sprintf(*bufferPtr, "%s%s", Sym_Name(sym), valIdx < 0 ? "" : "=");
	fieldName[0] = '\0';
    } else {
	*cp = '\0';
	sprintf(*bufferPtr, "%s.%s%s", Sym_Name(sym), fieldName,
		valIdx < 0 ? "" : "=");
    }
    *bufferPtr += strlen(*bufferPtr);

    /*
     * Now, if there's a value to be printed, do so.
     * XXX: Decode into bits?
     */
    if (valIdx >= 0) {
	sprintf(*bufferPtr, valFormat, vals[valIdx].OS_dword);
	*bufferPtr += strlen(*bufferPtr);
    }
    
    if (op->args[2] == 'd') {
	/*
	 * Source is immediate: Decode into bits and print them.
	 * To accomplish this, we want to work through all the fields
	 * of the record and see if they're set.
	 */
	char	    *ecp;
	Boolean	    isFlags;
	Ibm86PRData data;
	int	    offset;

	cp = fieldName;
	offset = 0;
	if (*cp != '\0') {
	    do {
		int foffset = 0;
		
		ecp = index(cp, '.');
		if (ecp != NULL) {
		    *ecp++ = '\0';
		}
		
		Type_GetFieldData(type, cp,  &foffset, NULL, &type);
		offset += foffset;
		cp = ecp;
	    } while (cp != NULL);
	}


	/*
	 * Now have  type  containing the record type itself. First make sure
	 * the thing is just flags. If it's not, we'll have to print things
	 * differently.
	 */
	isFlags = TRUE;

	Type_ForEachField(type, Ibm86SeeIfFlags, (Opaque)&isFlags);

	/*
	 * Set up the data to be passed to the print functions. Note we
	 * have to deal with byte access to a word record by masking out
	 * the proper bits of the value, since the value may have been
	 * sign-extended by Ibm86Decode.
	 */
	data.bufferPtr = bufferPtr;
	data.value = vals[1].OS_dword & (op->args[1] == 'b' ? 0xff : 0xffff);
	data.numClear = 0;
	data.printingInverse = FALSE;

	if (eaPtr->offset-(offset/8) != realOffset) {
	    /*
	     * Not playing with the base of the record -- adjust the immediate
	     * value to correspond to actual bits of the record by shifting
	     * it left the number of bits difference from the base of the
	     * record to the ea.
	     */
	    data.value <<= (eaPtr->offset-(realOffset+(offset/8)))*8;
	}
	
	Type_ForEachField(type,
			  (isFlags ?
			   Ibm86PrintRecordFlags :
			   Ibm86PrintRecordField),
			  (Opaque)&data);

	if (isFlags && data.numClear == 1) {
	    /*
	     * Bleah. Only one field was clear of that whole flags word, so
	     * it's more useful to print out what it's the inverse of, since
	     * the programmer is most likely doing something like
	     *
	     *	andnf ax, not biff
	     *
	     * Invert the value and revert the buffer pointer and print things
	     * out accordingly.
	     */
	    data.value = ~data.value;
	    strcpy(*bufferPtr, ", NOT ");
	    *bufferPtr += 6;
	    data.bufferPtr = bufferPtr;
	    data.printingInverse = TRUE;

	    Type_ForEachField(type, Ibm86PrintRecordFlags, (Opaque)&data);
	}
	bufferPtr = data.bufferPtr;
    }
}
typedef struct {
    Sym	    closest;	    /* Closest symbol so far */
    short   offset;  	    /* Offset from that symbol */
    short   diff;   	    /* Difference in the address */
} PEAData;

/***********************************************************************
 *				PEAFindLocal
 ***********************************************************************
 * SYNOPSIS:	    Find the proper local variable for a reference to
 *	    	    the stack segment of a thread. The symbol chosen is
 *	    	    the one whose offset is <= the difference encountered
 *	    	    by PrintAddress but closest to it.
 * CALLED BY:	    PrintEA via Sym_ForEach
 * RETURN:	    non-zero if find exact match, data->closest will be
 *	    	    set to the closest match or left null if none
 *	    	    reasonable
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/31/90		Initial Revision
 *
 ***********************************************************************/
static int
PEAFindLocal(Sym    sym,
	     Opaque data)
{
    PEAData  	    *pead = (PEAData *)data;
    Address	    offset;
    StorageClass    sClass;

    Sym_GetVarData(sym, (Type *)NULL, &sClass, &offset);
    
    if ((sClass == SC_Local) || (sClass == SC_Parameter)) {
	if ((short)offset < pead->diff) {
	    /*
	     * Symbol lies below the address, which is good. See if
	     * it's any closer than what we had before.
	     */
	    if ((short)offset > pead->offset) {
		pead->closest = sym;
		pead->offset = (short)offset;
	    }
	} else if ((short)offset == pead->diff) {
	    pead->closest = sym;
	    pead->offset = (short)offset;
	    return(1);
	}
    }
    return(0);
}

/***********************************************************************
 *				PrintEA
 ***********************************************************************
 * SYNOPSIS:	    Print an effective address symbolically
 * CALLED BY:	    Ibm86PrintArgs
 * RETURN:	    Nothing
 * SIDE EFFECTS:    bufferPtr is advanced
 *
 * STRATEGY:	    Call the Sym module to find a symbol
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/18/88	Initial Revision
 *
 ***********************************************************************/
static void
PrintEA(char   	    	**bufferPtr,
	GeosAddr	*eaPtr,	    	/* Effective address */
	const I86Opcode *op,	    	/* Opcode involved */
	const OperandSize *vals,	    	/* Operand values */
	int 	    	valIdx)	    	/* Index of ea's value in vals. -1
					 * if shouldn't print value */
{
    Sym	    	sym;	    	/* Closest symbol */
    Address 	realOffset; 	/* Actual address of sym */

    if (eaPtr->handle != NullHandle) {
	if (VALIDTPTR(curPatient->frame, TAG_FRAME) &&
	    (eaPtr->handle ==
	     ((FramePrivPtr)curPatient->frame->private)->stackHan) &&
	    !Sym_IsNull(curPatient->frame->function))
	{
	    /*
	     * Refers to something in the stack segment. Figure the difference
	     * from the current BP (XXX: frame-relative?) and see if
	     * there's a local variable for the current frame in the
	     * vicinity...
	     */
	    word    bp;
	    PEAData pead;

	    Ibm_ReadRegister16(REG_MACHINE, REG_BP, &bp);
	    pead.diff = (word)eaPtr->offset - 
		    	((FramePrivPtr)curPatient->frame->private)->fp;
	    pead.closest = NullSym;
	    pead.offset = -32768; /* Really small... */

	    Sym_ForEach(curPatient->frame->function, SYM_LOCALVAR, PEAFindLocal,
			(Opaque)&pead);

	    if (!Sym_IsNull(pead.closest)) {
		eaPtr->offset = (Address)pead.diff;
		sym = pead.closest;
		goto have_sym;
	    }
	}
	sym = Sym_LookupAddr(eaPtr->handle, eaPtr->offset,
			     SYM_FUNCTION|SYM_VAR|SYM_LABEL);

	if (Sym_IsNull(sym)) {
	    sprintf(*bufferPtr, "%04xh:%04xh", Handle_Segment(eaPtr->handle),
		    (unsigned int)(eaPtr->offset));
	} else {
	    have_sym:

	    if (Sym_Class(sym) & (SYM_FUNCTION|SYM_LABEL)) {
		Sym_GetFuncData(sym, (Boolean *)NULL, &realOffset,
				(Type *)NULL);
	    } else {
		/*
		 * Variable -- resolve to field if structure
		 */
		Type	type;	    	/* Type of variable */
		char	*fieldName; 	/* Name of enclosing field */
		int 	fieldLength;	/* Bit-length of field */
		Type	fieldType;  	/* Base type of field */
		int 	offset;
		
		Sym_GetVarData(sym, &type, NULL, &realOffset);
		
		if ((Type_Class(type) == TYPE_STRUCT) &&
		    (Type_FindFieldData(type, (eaPtr->offset - realOffset) * 8,
					&fieldName, &fieldLength,
					&fieldType, &offset)))
		{
		    /*
		     * See if we've stumbled on a record by comparing the
		     * length of the field against the number of bits in
		     * its base type.
		     */
		    if (fieldLength != Type_Sizeof(fieldType) * 8) {
			Ibm86PrintRecordEA(bufferPtr, eaPtr, op, vals, valIdx,
					   fieldName, sym, type, realOffset);
			return;
		    } else if (offset) {
			if (offset & 0x7) {
			    sprintf(*bufferPtr, "%s.%s+%d:%d", Sym_Name(sym),
				    fieldName, offset / 8, offset & 0x7);
			} else {
			    sprintf(*bufferPtr, "%s.%s+%d", Sym_Name(sym),
				    fieldName, offset / 8);
			}
			free(fieldName);
		    } else {
			sprintf(*bufferPtr, "%s.%s", Sym_Name(sym), fieldName);
			free(fieldName);
		    }
		    goto pea_done;
		}
	    }
	    if (eaPtr->offset - realOffset != 0) {
		sprintf(*bufferPtr, "%s+%d", Sym_Name(sym),
			eaPtr->offset - realOffset);
	    } else {
		strcpy(*bufferPtr, Sym_Name(sym));
	    }
	}
    } else {
	sprintf(*bufferPtr, "abs %05xh", (unsigned int)(eaPtr->offset));
    }
pea_done:
    *bufferPtr += strlen(*bufferPtr);
    if (valIdx >= 0) {
	*(*bufferPtr)++ = '=';
	switch(op->args[valIdx*2+1]) {
	    case 'b':
	    case 'w':
	    case 'd':
	    case 'v':
		sprintf(*bufferPtr, valFormat, vals[valIdx].OS_dword);
		break;
	    case 'f':
		sprintf(*bufferPtr, "%g", vals[valIdx].OS_float);
		break;
	    case 'q':
		sprintf(*bufferPtr, "%g", vals[valIdx].OS_double);
		break;
	    case 't':
		strcpy(*bufferPtr, "?");
		break;
	}
	*bufferPtr += strlen(*bufferPtr);
    }
}

	    

/***********************************************************************
 *				PrintAddress
 ***********************************************************************
 * SYNOPSIS:	    Print an address symbolically
 * CALLED BY:	    Ibm86Decode, Ibm86PrintArgs
 * RETURN:	    Nothing
 * SIDE EFFECTS:    bufferPtr is advanced
 *
 * STRATEGY:	    Call the Sym module to find a symbol
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/18/88	Initial Revision
 *
 ***********************************************************************/
static void
PrintAddress(char   	**bufferPtr,
	     Handle 	handle,
	     Address	offset)
{
    Sym	    	sym;
    Address 	realOffset;

    if (handle != NullHandle) {
	sym = Sym_LookupAddr(handle, offset, SYM_FUNCTION|SYM_VAR|SYM_LABEL);

	if (Sym_IsNull(sym)) {
	    sprintf(*bufferPtr, "%.4xh:%.4xh", Handle_Segment(handle), 
		    (unsigned int)offset);
	} else {
	    
	    if (Sym_Class(sym) & (SYM_FUNCTION|SYM_LABEL)) {
		Sym_GetFuncData(sym, (Boolean *)NULL, &realOffset,
				(Type *)NULL);
	    } else {
		Type	type;
		char	*fieldName;
		int 	diff;
		
		Sym_GetVarData(sym, &type, NULL, &realOffset);
		if ((Type_Class(type) == TYPE_STRUCT) &&
		    (Type_FindFieldData(type, (offset - realOffset) * 8,
					&fieldName, (int *)NULL,
					(Type *)NULL, &diff)))
		{
		    sprintf(*bufferPtr, "%s.%s", Sym_Name(sym), fieldName);
		    free(fieldName);
		    goto pa_done;
		}
	    }
	    if (offset - realOffset != 0) {
		sprintf(*bufferPtr, "%s+%d", Sym_Name(sym),
			offset - realOffset);
	    } else {
		strcpy(*bufferPtr, Sym_Name(sym));
	    }
	}
    } else {
	sprintf(*bufferPtr, "abs %05xh", (unsigned int)offset);
    }
pa_done:
    *bufferPtr += strlen(*bufferPtr);
}

/***********************************************************************
 *				PrintFlags
 ***********************************************************************
 * SYNOPSIS:	    Print a word as the flags word of the 8086
 * CALLED BY:	    Ibm86Decode
 * RETURN:	    Nothing
 * SIDE EFFECTS:    *bufferPtr is advanced.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/88	Initial Revision
 *
 ***********************************************************************/
static void
PrintFlags(Boolean  printAll,	    /* TRUE if high byte should be decoded */
	   char	    **bufferPtr,    /* Place to store result */
	   word	    w)	    	    /* Word to decode */
{
    register char   *bp;

    bp = *bufferPtr;

#define DECODE(flag,pref,last) \
    if (w & REG_##flag) {\
	sprintf(bp, #flag "%s", last ? "" : " ");\
	bp += 2 + !last;\
    }

    if (printAll) {
	DECODE(OF,O,0);
	DECODE(DF,D,0);
	DECODE(IF,I,0);
	DECODE(TF,T,0);
    }
    DECODE(SF,S,0);
    DECODE(ZF,Z,0);
    DECODE(AF,A,0);
    DECODE(PF,P,0);
    DECODE(CF,C,1);

    *bufferPtr = bp;
}

/***********************************************************************
 *				Ibm86ReadStack
 ***********************************************************************
 * SYNOPSIS:	    Read an integer from the stack.
 * CALLED BY:	    Ibm86PrintArgs
 * RETURN:	    *ptr filled in
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 7/92	Initial Revision
 *
 ***********************************************************************/
static void
Ibm86ReadStack(int  	size,	    /* Size of integer to read */
	       int  	offset,	    /* Offset from ss:sp at which to read */
	       genptr	ptr)	    /* Place to store bytes */
{
    GeosAddr	addr;

    Expr_Eval("ss:sp", NullFrame, &addr, (Type *)NULL, TRUE);

    Var_FetchInt(size, addr.handle, addr.offset+offset, ptr);
}

/***********************************************************************
 *				Ibm86PrintArgs
 ***********************************************************************
 * SYNOPSIS:	    Print the arguments for the instruction based
 *	    	    on the flags in the opcode.
 * CALLED BY:	    Ibm86Decode
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 3/89		Initial Revision
 *
 ***********************************************************************/
#if REGS_32
static void
Ibm86PrintArgs(char    	    	*decode,    /* Buffer for result */
	       Handle	    	handle,	    /* Handle of block in which
					     * instruction lies */
	       unsigned long	flags,	    /* Flags of what to print */
	       int  	    	eaNum,	    /* Operand that's ea */
	       GeosAddr  	*eaPtr,	    /* ea itself */
	       const OperandSize *vals,	    /* Values for operands */
	       const I86Opcode 	*op,	    /* Opcode involved */
	       int 	    	overReg,    /* Regnum for segment override */
	       Boolean          prefixSize[2])	/* Operand/EA size attributes */
#else
static void
Ibm86PrintArgs(char    	    	*decode,    /* Buffer for result */
	       Handle	    	handle,	    /* Handle of block in which
					     * instruction lies */
	       unsigned long	flags,	    /* Flags of what to print */
	       int  	    	eaNum,	    /* Operand that's ea */
	       GeosAddr  	*eaPtr,	    /* ea itself */
	       const OperandSize *vals,	    /* Values for operands */
	       const I86Opcode 	*op,	    /* Opcode involved */
	       int 	    	overReg)    /* Regnum for segment override */
#endif
{
    unsigned long	flag;	/* Current flag */
    word	    	reg;
    regval		regv;
    
    while(flags) {
	flag = 1 << (ffs(flags) - 1);
	flags &= ~flag;
	
#define DEST_INDEX  0	/* Index in vals for dest operand */
#define SRC_INDEX   1	/* Index in vals for source operand */
	
	switch(flag) {
	    case IA_DEST:
		/*
		 * Dest value (+ addr if ea)
		 */
		if (eaNum == DEST_INDEX) {
		    PrintEA(&decode, eaPtr, op, vals, DEST_INDEX);
		} else {
		    sprintf(decode, valFormat, vals[DEST_INDEX].OS_dword);
		}
		break;
	    case IA_DESTADR:
		/*
		 * Dest addr (not value)
		 */
		if (eaNum == DEST_INDEX) {
		    PrintEA(&decode, eaPtr, op, vals, -1);
		} else {
		    continue;
		}
		break;
	    case IA_SRC:
		/*
		 * Source value (+ addr if ea)
		 */
		if (eaNum == SRC_INDEX) {
		    PrintEA(&decode, eaPtr, op, vals, SRC_INDEX);
		} else {
		    sprintf(decode, valFormat, vals[SRC_INDEX].OS_dword);
		}
		break;
	    case IA_SRCADR:
		/*
		 * Address of source (LEA)
		 */
		if (eaNum == SRC_INDEX) {
		    PrintEA(&decode, eaPtr, op, vals, -1);
		}
		break;
	    case IA_AL:
		/*
		 * AL (BCD & XLAT & strings)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_AL, &reg);
		sprintf(decode, "AL=%.2xh", reg);
		break;
	    case IA_AX:
		/*
		 * [E]AX (CWD, OUT)
		 */
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    Ibm_ReadRegister(REG_MACHINE, REG_EAX, &regv);
		    sprintf(decode, "EAX=%.8lxh", regv);
		    break;
		}
#endif
		Ibm_ReadRegister16(REG_MACHINE, REG_AX, &reg);
		sprintf(decode, "AX=%.4xh", reg);
		break;
	    case IA_DF:
		/*
		 * DF (strings)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		sprintf(decode, "DF=%c", ((int)reg&REG_DF) ? '1' : '0');
		break;
	    case IA_ESDI:
	    {
		/*
		 * ES:DI's value, symbolicly
		 */
		Address addr;
		Handle  handle;
		
		Ibm_ReadRegister16(REG_MACHINE, REG_ES, &reg);
		addr = MakeAddress(reg, 0);
		
		Ibm_ReadRegister16(REG_MACHINE, REG_DI, &reg);
		addr += reg;
		handle = Handle_Find(addr);
		/*
		 * Adjust to offset if w/in a handle, else leave
		 * absolute.
		 */
		if (handle != NullHandle) {
		    addr -= (int)Handle_Address(handle);
		}
		PrintAddress(&decode, handle, addr);
		break;
	    }
	    case IA_DIPTR:
	    {
		/*
		 * DI's value and what it points at
		 */
		Address addr;
		Handle  handle;
		
		Ibm_ReadRegister16(REG_MACHINE, REG_ES, &reg);
		addr = MakeAddress(reg, 0);
		
		Ibm_ReadRegister16(REG_MACHINE, REG_DI, &reg);
		addr += reg;
		handle = Handle_Find(addr);
		/*
		 * Adjust to offset if w/in a handle, else leave
		 * absolute.
		 */
		if (handle != NullHandle) {
		    addr -= (int)Handle_Address(handle);
		}
		/*
		 * Low bit set means it's a [d]word instruction
		 */
		if (op->value & 1) {

#if REGS_32
		    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
			dword	d;

			Var_FetchInt(4, handle, addr, (genptr)&d);

			PrintAddress(&decode, handle, addr);
			sprintf(decode, "=%.8lxh", d);
		    } else {
#endif
			word	w;

			Var_FetchInt(2, handle, addr, (genptr)&w);
			
			PrintAddress(&decode, handle, addr);
			sprintf(decode, "=%.4xh", w);
#if REGS_32
		    }
#endif
		} else {
		    byte	b;
		    
		    Ibm_ReadBytes(1, handle, addr, (genptr)&b);
		    PrintAddress(&decode, handle, addr);
		    sprintf(decode, "=%.2xh", b);
		}
		break;
	    }
	    case IA_SIPTR:
	    {
		/*
		 * SI's value and what it points at
		 */
		Address addr;
		Handle  handle;
		
		Ibm_ReadRegister16(REG_MACHINE, overReg ? overReg : REG_DS, &reg);
		
		addr = MakeAddress(reg, 0);
		
		Ibm_ReadRegister16(REG_MACHINE, REG_SI, &reg);
		
		addr += reg;
		
		handle = Handle_Find(addr);
		/*
		 * Adjust to offset if w/in a handle, else leave
		 * absolute.
		 */
		if (handle != NullHandle) {
		    addr -= (int)Handle_Address(handle);
		}
		
		if (op->value & 1) {
#if REGS_32
		    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
			dword	d;

			Var_FetchInt(4, handle, addr, (genptr)&d);

			PrintAddress(&decode, handle, addr);
			sprintf(decode, "=%.8lxh", d);
		    } else {
#endif
			word	w;

			Var_FetchInt(2, handle, addr, (genptr)&w);
			
			PrintAddress(&decode, handle, addr);
			sprintf(decode, "=%.4xh", w);
#if REGS_32
		    }
#endif
		} else {
		    byte	b;
		    
		    Ibm_ReadBytes(1, handle, addr, (genptr)&b);
		    PrintAddress(&decode, handle, addr);
		    sprintf(decode, "=%.2xh", b);
		}
		break;
	    }
	    case IA_CF:
		/*
		 * CF (RCR, RCL, CMC)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		sprintf(decode, "CF=%c", ((word)reg&REG_CF) ? '1' : '0');
		break;
	    case IA_CL:
		/*
		 * CL (variable shifts)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_CL, &reg);
		sprintf(decode, "CL=%.2xh", (byte)reg);
		decode += strlen(decode);
		break;
	    case IA_CX:
		/*
		 * [E]CX (LOOPs, REPs, JCXZ)
		 */
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    Ibm_ReadRegister(REG_MACHINE, REG_ECX, &regv);
		    sprintf(decode, "ECX=%.8lxh", regv);
		    break;
		}
#endif
		Ibm_ReadRegister16(REG_MACHINE, REG_CX, &reg);
		sprintf(decode, "CX=%.4xh", (word)reg);
		break;
	    case IA_BX:
		/*
		 * BX (XLAT)
		 */
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    Ibm_ReadRegister(REG_MACHINE, REG_EBX, &regv);
		    sprintf(decode, "EBX=%.8lxh", regv);
		    break;
		}
#endif
		Ibm_ReadRegister16(REG_MACHINE, REG_BX, &reg);
		sprintf(decode, "BX=%.4xh", (word)reg);
		break;
	    case IA_DXAX:
	    {
		/*
		 * [E]DX:[E]AX as int (DIV et al)
		 */
		dword   d;

#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    dword a;
		   
		    Ibm_ReadRegister(REG_MACHINE, REG_EDX, &regv);
		    d = regv;
		    Ibm_ReadRegister(REG_MACHINE, REG_EAX, &regv);
		    a = regv;
		    
		    sprintf(decode, "EDX:EAX=%.8x%.8x", d, a);
		    break;
		}
#endif		
		Ibm_ReadRegister16(REG_MACHINE, REG_DX, &reg);
		d = (int)reg << 16;
		Ibm_ReadRegister16(REG_MACHINE, REG_AX, &reg);
		d |= ((int)reg & 0xffff);
		
		sprintf(decode, "DX:AX=%d", (int)d);
		break;
	    }
	    case IA_TOSF:
	    {
		/*
		 * TOS as flags word (POPF)
		 */
		word    w;

		Ibm86ReadStack(2, 0, (genptr)&w);
		
		PrintFlags(TRUE, &decode, w);
		break;
	    }
	    case IA_TOSRETN:
	    {
		/*
		 * TOS for near return
		 */
		word    w;
		
		Ibm86ReadStack(2, 0, (genptr)&w);
		PrintAddress(&decode, handle, (Address)w);
		break;
	    }
	    case IA_TOSRETF:
	    {
		/*
		 * TOS for far return
		 */
		Address a;
		Handle  h;
		
		Ibm86ReadStack(4, 0, (genptr)&a);

		a = (Address)((word)a + ((((dword) a) >> 12) & 0xffff0));
		
		h = Handle_Find(a);
		
		if (h == NullHandle) {
		    /*
		     * Print it absolutely. If we call Handle_Address, we
		     * die.
		     */
		    PrintAddress(&decode, NullHandle, a);
		} else {
		    PrintAddress(&decode,h,(Address)(a-Handle_Address(h)));
		}
		break;
	    }
	    case IA_TOSIRET:
	    {
		/*
		 * TOS for IRET
		 */
		word    w;
		Address a;
		Handle  h;
		
		Ibm86ReadStack(4, 0, (genptr)&a);
		Ibm86ReadStack(2, 4, (genptr)&w);
		a = (Address)((word)a + ((((dword) a) >> 12) & 0xffff0));
		
		h = Handle_Find(a);
		if (h == NullHandle) {
		    /*
		     * Print it absolutely. If we call Handle_Address, we
		     * die.
		     */
		    PrintAddress(&decode, NullHandle, a);
		} else {
		    PrintAddress(&decode,h,(Address)(a-Handle_Address(h)));
		}
		strcpy(decode, "; ");
		decode += 2;
		PrintFlags(TRUE, &decode, w);
		break;
	    }
	    case IA_TOS:	    /* TOS (POP) */
	    {
		/*
		 * Top of stack (POP)
		 */
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    dword d;
		    
		    Ibm86ReadStack(4, 0, (genptr)&d);

		    sprintf(decode, "[SP]=%.8lxh", d);
		    break;
		}
		else
		{
#endif
		    word    w;
		
		    Ibm86ReadStack(2, 0, (genptr)&w);
		    
		    sprintf(decode, "[SP]=%.4xh", w);
		    break;
#if REGS_32
		}
#endif
	    }
	    case IA_TOSPOPA:
		/*
		 * TOS (POPA) -- NYI
		 */
		break;
	    case IA_ZF:
		/*
		 * ZF (LOOPcc)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		sprintf(decode, "ZF=%c", (reg&REG_ZF) ? '1' : '0');
		break;
	    case IA_BRANCH:
	    {
		/*
		 * If instruction will branch (Jcc, LOOPcc, INTO)
		 */
		Boolean willJump = FALSE; /* Init for GCC */
		
		if ((op->value & 0xf0) == 0x70) {
		    /*
		     * Jcc -- fetch status reg first off, then figure out
		     * the cc and decide.
		     */
		    Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		    switch(op->value & 0xf) {
			case 0x0: 	/* JO */
			    willJump = reg & REG_OF;
			    break;
			case 0x1: 	/* JNO */
			    willJump = !(reg & REG_OF);
			    break;
			case 0x2:	/* JC */
			    willJump = reg & REG_CF;
			    break;
			case 0x3:	/* JNC */
			    willJump = !(reg & REG_CF);
			    break;
			case 0x4:	/* JZ */
			    willJump = reg & REG_ZF;
			    break;
			case 0x5:	/* JNZ */
			    willJump = !(reg & REG_ZF);
			    break;
			case 0x6:	/* JBE */
			    willJump = (reg & (REG_ZF|REG_CF));
			    break;
			case 0x7:	/* JA */
			    willJump = !(reg & (REG_ZF|REG_CF));
			    break;
			case 0x8:	/* JS */
			    willJump = (reg & REG_SF);
			    break;
			case 0x9:	/* JNS */
			    willJump = !(reg & REG_SF);
			    break;
			case 0xa:	/* JP */
			    willJump = (reg & REG_PF);
			    break;
			case 0xb:	/* JNP */
			    willJump = !(reg & REG_PF);
			    break;
			case 0xc:	/* JL */
			    /*
			     * SF ^^ OF
			     */
			    willJump = (((reg & (REG_SF|REG_OF)) ?
					 (reg & (REG_SF|REG_OF)) :
					 (REG_SF|REG_OF)) !=
					(REG_SF|REG_OF));
			    break;
			case 0xd:	/* JGE */
			    /*
			     * !(SF ^^ OF)
			     */
			    willJump = (((reg & (REG_SF|REG_OF)) ?
					 (reg & (REG_SF|REG_OF)) :
					 (REG_SF|REG_OF)) ==
					(REG_SF|REG_OF));
			    break;
			case 0xe:	/* JLE */
			    /*
			     * ZF || (SF ^^ OF)
			     */
			    willJump = ((reg & REG_ZF) ||
					(((reg & (REG_SF|REG_OF)) ?
					  (reg & (REG_SF|REG_OF)) :
					  (REG_SF|REG_OF)) !=
					 (REG_SF|REG_OF)));
			    break;
			case 0xf:	/* JG */
			    /*
			     * !ZF && !(SF ^^ OF)
			     */
			    willJump = (!(reg & REG_ZF) &&
					(((reg & (REG_SF|REG_OF)) ?
					  (reg & (REG_SF|REG_OF)) :
					  (REG_SF|REG_OF)) ==
					 (REG_SF|REG_OF)));
			    break;
			default:
			    Punt("Hit default in Ibm86PrintArgs");
		    }
		} else {
		    switch (op->value & 0xff) {
			case 0xe0:
			    /*
			     * LOOPNZ
			     */
			    Ibm_ReadRegister16(REG_MACHINE, REG_CX, &reg);
			    willJump = (reg != 1);
			    Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
			    willJump = willJump && !(reg & REG_ZF);
			    break;
			case 0xe1:
			    /*
			     * LOOPZ
			     */
			    Ibm_ReadRegister16(REG_MACHINE, REG_CX, &reg);
			    willJump = (reg != 1);
			    Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
			    willJump = willJump && (reg & REG_ZF);
			    break;
			case 0xe2:
			    /*
			     * LOOP
			     */
			    Ibm_ReadRegister16(REG_MACHINE, REG_CX, &reg);
			    willJump = (reg != 1);
			    break;
			case 0xe3:
			    /*
			     * JCXZ
			     */
			    Ibm_ReadRegister16(REG_MACHINE, REG_CX, &reg);
			    willJump = (reg == 0);
			    break;
			case 0xce:
			    /*
			     * INTO
			     */
			    Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
			    willJump = (reg & REG_OF);
			    break;
		    }
		}
		sprintf(decode, "Will%s jump", willJump ? "" : " not");
		break;
	    }
	    case IA_SAHF:
		/*
		 * AH as flags (SAHF)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_AH, &reg);
		PrintFlags(FALSE, &decode, reg);
		break;
	    case IA_LAHF:
		/*
		 * Low-order flags (LAHF)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		PrintFlags(FALSE, &decode, (word)(reg & 0xff));
		break;
	    case IA_PUSHF:
		/*
		 * All flags (PUSHF)
		 */
		Ibm_ReadRegister16(REG_MACHINE, REG_SR, &reg);
		PrintFlags(TRUE, &decode, reg);
		break;
	    case IA_PUSHA:
		/*
		 * All registers (PUSHA) -- NYI
		 */
		break;
	    case IA_BOUND:
		/*
		 * Index bounds (BOUND) -- NYI
		 */
		break;
	    case IA_DX:
		/*
		 * [E]DX (OUT)
		 */
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) {
		    Ibm_ReadRegister(REG_MACHINE, REG_EDX, &regv);
		    sprintf(decode, "EDX=%.8lxh", regv);
		    break;
		}
#endif
		Ibm_ReadRegister16(REG_MACHINE, REG_DX, &reg);
		sprintf(decode, "DX=%.4xh", reg);
		break;
	    case IA_FLOATREG:
	    case IA_FLOATNUM:
		break;
	    case IA_FPSRC:
		/*
		 * Source value  (+ addr if ea)
		 */
		if (eaNum == DEST_INDEX) {
		    PrintEA(&decode, eaPtr, op, vals, DEST_INDEX);
		} else {
		    switch(op->args[1]) {
			case 'b':
			case 'w':
			case 'd':
		        case 'v':
			    sprintf(decode, valFormat,
				    vals[DEST_INDEX].OS_dword);
			    break;
			case 'f':
			    sprintf(decode, "%g",
				    vals[DEST_INDEX].OS_float);
			    break;
			case 'q':
			    sprintf(decode, "%g",
				    vals[DEST_INDEX].OS_double);
			    break;
			case 't':
			    break;
		    }
		}
		break;
	}
	decode += strlen(decode);
	if (flags) {
	    strcpy(decode, ", ");
	    decode += 2;
	}
    }
}

/***********************************************************************
 *				Ibm86DecodeInt
 ***********************************************************************
 * SYNOPSIS:	    Internal decode function that relies on a supplied
 *	    	    buffer of bytes.
 *	    	
 * CALLED BY:	    Ibm86Decode and find-opcode
 * RETURN:	    TRUE if could be decoded
 *     	    	    If buffer is non-null, it is filled with the string
 *	    	    for the instruction.
 *		If instSizePtr is non-null, it is filled with the actual
 *	    	size of the instruction.
 *	    	If decode is non-null, it is filled with the actual
 *	    	operands of the instruction.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	XXX: When decoding args, should we allow it to be frame-relative?
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/89	Initial Revision
 *
 ***********************************************************************/
static int
Ibm86DecodeInt(byte	*ibuf,	    	/* Buffer of bytes to decode */
	       int  	len,	    	/* Number of bytes in same */
	       Handle	handle,	    	/* Handle from which the bytes came (for
					 * use in decoding relative jumps) */
	       Address 	offset,	    	/* Offset of same for same purpose */
	       char 	*buffer,    	/* Place to store decoded instruction */
	       int  	*instSizePtr,	/* Place for total size of
					 * instruction */
	       char 	*decode)    	/* Non-null to decode/print the args.
					 * Args are formatted into the buffer */
{
    unsigned long  	inst;	    	/* Instruction to decode */
    register const I86Opcode *op;    	/* Opcode description */
    register const char	*args;		/* Argument description string */
    register byte	*ip;		/* Current location in ibuf */
    byte  	  	modrm;	    	/* ModRM byte for those
					 * instructions that have them */
    char    	  	*segover;   	/* Segment override */
    int	    	  	overReg;    	/* Register number of override */
    static char		*byteRegs = "ALCLDLBLAHCHDHBH";
    static char		*wordRegs = "AXCXDXBXSPBPSIDI";
    static char	  	*segs = "ESCSSSDS";
#if REGS_32
    static char         *segsFSGS = "FSGS" ;
    Boolean             prefixSize[2] = {FALSE, FALSE} ;
    byte *              ibuf2;          /* Start of instruction without size prefixes */
#endif
    OperandSize		vals[2];	/* Argument values */
    GeosAddr		ea;		/* Effective address. */
    int			eaNum;		/* Which arg is the effective address*/
    int			valNum;		/* Index into vals */
    unsigned long   	flags;	    	/* Operand printing flags */
    const char		*name32;	/* Pointer to 32-bit name of opcode */
    const char		*opname;	/* Pointer to name of opcode */

    if (decode) {
	*decode = '\0';
    }
    

    ip = ibuf ;
#if REGS_32
    ibuf2 = ip ;
    if (*ip == 0x67)  {
        prefixSize[PREFIX_ADDRESS_SIZE_32BIT] = TRUE ;
        ip++ ;
        len-- ;
        if (len == 0)
            return FALSE ;
        ibuf2++ ;
    }
    if (*ip == 0x66)  {
        prefixSize[PREFIX_OPERAND_SIZE_32BIT] = TRUE ;
        ip++ ;
        len-- ;
        if (len == 0)
            return FALSE ;
        ibuf2++ ;
    }
#endif
    /*
     * See if first byte is actually a segment override prefix.
     */
    /* CS, DS, ES, or SS override */
    if ((*ip & 0xe7) == 0x26)  {
         /*
	 * First byte is segment-override prefix for e[bwd] argument.
	 * Find the segment name (not null-terminated) by shifting the reg
	 * field of the prefix down 2 bits (not three, since we need to
	 * multiply the segment register number by two anyway...).
	 * The instruction to decode begins in the first byte of the buffer.
	 */

	segover = &segs[(*ip >> 2) & 0x06];
	overReg = REG_ES + ((*ip >> 3) & 0x03);
	ip++;
	len--;
        if (len == 0)
            return FALSE ;
#if REGS_32
    /* FS or GS override */
    } else if ((*ip & 0xFE) == 0x64)  {
	segover = &segsFSGS[(*ip & 1)<<1];
	overReg = REG_FS + (*ip & 1);
	ip++;
	len--;
        if (len == 0)
            return FALSE ;
#endif
    } else {
	/*
	 * Indicate no override by setting segover to NULL. The instruction
	 * starts at the beginning of the buffer.
	 */
	segover = (char *)NULL;
	overReg = 0;
    }

    /*
     * Form three bytes of instruction for I86FindOpcode.
     */
    inst = ip[0] | (ip[1] << 8) | (ip[2] << 16);

    /*
     * Locate the opcode
     */
    op = I86FindOpcode(inst, &modrm, &name32);

    /*
     * Skip over the opcode and the mod r/m byte (if it'll actually be used).
     * Set args to point to the argument descriptor string.
     */
    ip += op->length;
    len -= op->length;
    if (len < 0) {
	return(FALSE);
    }
    args = op->args;
    flags = op->flags;
    opname = op->name;
#if REGS_32
    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT] && name32 != NULL)
	opname = name32;
#endif

    /*
     * Special case a segment-override prefix on a DB. The prefix is really
     * just data, like the opcode itself. This makes the prefix appear as
     * data too, rather than disappearing.
     */
    if ((op->length == 0) && (segover != (char *)NULL)) {
	/*
	 * Just a DB (the opcode is illegal) but we've swallowed a byte for
	 * a meaningless segment override. Back ip up to the start of the
	 * instruction.
	 */
	len++;
    }

    /*
     * printez le opcode
     */
    if (buffer) {
	sprintf(buffer, "%-8s", opname);
	buffer += 8;
    }

    /*
     * Format each operand/argument in turn based on the argument descriptor
     * string.
     *
     * XXX:
     *	Should print immediate bytes in current radix.
     *	Bit-oriented instructions should probably print immediate values in
     *	    binary (configurable)
     */
    valNum = 0;
    eaNum = -1;
    while (*args) {
	switch (*args) {
	case 'r':
	    /*
	     * Register operand. We only need to something if we're actually
	     * disassembling the thing.
	     */
	    if (buffer) {
		char	*reg;

		if (args[1] == 'b') {
		    /*
		     * Byte register. Only shift the reg field down two bits
		     * since we need to get reg * 2 anyway.
		     */
		    reg = &byteRegs[(modrm >> 2) & 0x0e];
		    if (decode) {
			/*
			 * Fetch the byte register as the value.
			 */
			word	w;
			
			Ibm_ReadRegister16(REG_MACHINE,
					 REG_AL + ((modrm >> 3)&7),
					 &w);
			vals[valNum++].OS_dword = w;
		    }
		} else {
                    /*
		     * Word register. Same shifting applies.
		     */
                    /* Or DWord register if we are doing 32-bit */
#if REGS_32
                    /* Prefix value with an E if extended 32-bit register */
                    if ((prefixSize[PREFIX_OPERAND_SIZE_32BIT]) && 
			    (args[1] != 'w'))  {
                        *(buffer++) = 'E' ;
		        reg = &wordRegs[(modrm >> 2) & 0x0e];
		        if (decode) {
			    /*
			     * Fetch the register as the value
			     */
                            regval	r ;

			    Ibm_ReadRegister(REG_MACHINE,
					     ((modrm >> 3) & 7)-REG_AX+REG_EAX,
					     &r);
			    vals[valNum++].OS_dword = r ;
		        }
                    } else {
#endif
		        reg = &wordRegs[(modrm >> 2) & 0x0e];
		        if (decode) {
			    /*
			     * Fetch the register as the value
			     */
                            word	w;

			    Ibm_ReadRegister16(REG_MACHINE,
					     ((modrm >> 3) & 7),
					     &w);
			    vals[valNum++].OS_dword = w;
		        }
#if REGS_32
                    }
#endif
		}
		sprintf(buffer, "%.2s", reg);
		buffer += 2;
	    }
	    break;
	case 'm':
	    /*
	     * Memory operand. The same as effective address except at
	     * assembly time...
	     */
	case 'e': {
#if REGS_32
            if (prefixSize[PREFIX_ADDRESS_SIZE_32BIT])  {
	        static char *indices[] = {
                    /* 32-bit versions */
                    "[EAX%s]",
		    "[ECX%s]",
		    "[EDX%s]",
		    "[EBX%s]",
		    "[ESP%s]",
		    "[EBP%s]",
		    "[ESI%s]",
		    "[EDI%s]",
	        };
                static char multipliers[4][3] = {
                    "",
                    "*2",
                    "*4",
                    "*8"
                } ;
	        Address	base=0;
	        word	segVal;
	        int	reg1 = -1,
                        reg2 = -1,
                        regRM,
                        mod,
                        reg,
                        rm,
			segRM,
                        segReg ;
	        regval	regVal;
                char    type ;
                char    *multiplier = multipliers[0] ;
                int     multi = 1 ;
                byte    sib ;           /* Scale Index Base */
                dword   disp32 ;

                enum  {
                    DISPLACEMENT_TYPE_NONE,
                    DISPLACEMENT_TYPE_8BIT,
                    DISPLACEMENT_TYPE_32BIT,
                } dispType = DISPLACEMENT_TYPE_NONE ;

//                char    finalIndex[40] ;
                Boolean goAhead = TRUE ;

                /*
	         * Figure the base value from the index registers and the
	         * default or override segment. reg1 is the base register.
	         * reg2 is the index register (or -1 if no index). segReg is
	         * the default segment register for that mode. The effective
	         * address is accumulated in 'base'.
	         */
                /* 32-bit version of registers to interpret here */

                /* Break down modrm into it's 3 parts */
                /*  MOD Reg R/M  */
                /*   11 111 111  */
                mod = (modrm >> 6) & 3 ;
                reg = (modrm >> 3) & 7 ;
                rm = (modrm & 0x7) ;
                regRM = REG_EAX + rm ;

                /* Are we doing just registers? */
                if (mod == 3)  {
                    /* Just direct registers, not an effective address */
                    eaNum = -1 ;
		    if (buffer) {
		        switch (args[1]) {
		    	    case 'b': 
		    	    {
			        regval w;

			        sprintf(buffer, "%.2s", &byteRegs[rm << 1]);
			        if (decode) {
			    	    Ibm_ReadRegister(REG_MACHINE,
				    	             REG_AL + rm,
					    	     &w);
			    	    vals[valNum++].OS_dword = w;
			        }
		    	    }
		    	    break;
		    	    case 'v':
                                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
			            regval w; 
				    
                                    sprintf(buffer++, "E%.2s", 
				            &wordRegs[rm << 1]);
			            if (decode) {
			    	        Ibm_ReadRegister(REG_MACHINE,
				    	                 regRM,
					    	         &w);
			    	        vals[valNum++].OS_dword = w;
			            }
				    break;
                                }
				/* else FALLTHRU */
		    	    case 'w':
			    {
			            word w;
			        
			            sprintf(buffer, "%.2s", 
				            &wordRegs[rm << 1]);
			            if (decode) {
			    	        Ibm_ReadRegister16(REG_MACHINE,
				    	                 REG_AX + rm,
					    	         &w);
			    	        vals[valNum++].OS_dword = w;
			            }
		    	    }
			    break;
			    case 'f':
			    case 't':
			    case 'q':
			        if (rm)
			        {
				    sprintf(buffer, "ST(%u)", rm);
				    buffer += 3;
			        }
			        else
			        {
				    sprintf(buffer, "ST");
			        }
 	    	    	        flags = IA_FLOATREG;
			        break;
		        }
	    	        buffer += 2;
		    }
                } else {
                    /* We use the SS segment register if we are BP or SP */
                    segRM = ((regRM == REG_EBP) || (regRM == REG_ESP)) ? REG_SS : REG_DS ;
	            if (segover != (char *)NULL)
		        segReg = overReg;


                    /* Effective address is this up coming value spot */
	            eaNum = valNum;

                    /* Determine type of displacement */
                    if (mod == 1)  {
                        dispType = DISPLACEMENT_TYPE_8BIT ;
                    } else if (mod == 2)  {
                        dispType = DISPLACEMENT_TYPE_32BIT ;
                    } else if (mod == 0)  {
                        if (rm == 5)
                            dispType = DISPLACEMENT_TYPE_32BIT ;
                    }

                    /* Determine if we have a sib */
                    if (rm == 4)  {
                        /* Get the sib */
                        /* The next byte is the Scale Index Byte */
                        if (len == 0)
                            return FALSE ;
                        sib = *ip ;
                        ip++ ;
                        len-- ;

                        /* Break down the sib to its parts */
                        reg1 = REG_EAX + ((sib >> 3) & 7) ;
                        reg2 = REG_EAX + (sib & 7) ;
                        multi = 1 << ((sib >> 6) & 3) ;
                        multiplier = multipliers[(sib >> 6) & 3] ;

                        /* ESP is not allowed (normally) */
                        if (reg1 == REG_ESP)
                            reg1 = -1 ;

                        /* There are some special rules that also apply further */
                        if (reg2 == REG_EBP)  {
                            if (mod == 0)  {
                                reg2 = -1 ;
                                dispType = DISPLACEMENT_TYPE_32BIT ;
                            }
                        }
                    }

                    /*
	             * Indicate the type of the operand (but no PTR garbage...) as
	             * long as it's really an address (don't do it for registers).
	             */
                    type = args[1] ;
		    if (type == 'v')
			if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])
			    type = 'd' ;
			else
			    type = 'w' ;
	            if (buffer && (dispType != DISPLACEMENT_TYPE_NONE)) {
		        strcpy(buffer, ((type == 'b') ? "BYTE " :
				        ((type == 'w') ? "WORD " : 
				         ((type == 'd') ? "DWORD " :
				          ((type == 'f') ? "FLOAT " :
				           ((type == 'q') ? "DOUBLE " :
				            "TBYTE "))))));
		        buffer += strlen(buffer);
	            }

                    /* Construct a string for this instruction */
                    if (buffer)  {
                        /* Add a segment override */
		        if (segover) {
			    sprintf(buffer, "%.2s:", segover);
			    buffer += 3;
			} else if (decode) {
			    /*
			     * If not overridden, segReg was set to REG_SS,
			     * which is wrong -- the default is REG_DS.
			     */
			    segReg = REG_DS;
			    Ibm_ReadRegister16(REG_MACHINE, REG_DS, &segVal);
			}

                        if (dispType == DISPLACEMENT_TYPE_8BIT)  {
                            if ((--len) < 0)
                                return FALSE ;
                            disp32 = *(ip++) ;
                        } else if (dispType == DISPLACEMENT_TYPE_32BIT)  {
                            len -= 4 ;
                            if (len < 0)
                                return FALSE ;
                            disp32 = *((dword *)ip) ;
                            ip += 4 ;
                        } else {
                            disp32 = 0 ;
                        }

                        /* Add the displayer text */
                        if (dispType != DISPLACEMENT_TYPE_NONE)  {
                            if (dispType == DISPLACEMENT_TYPE_8BIT)  {
                                sprintf(buffer, "%d", (int)disp32) ;
                            } else {
                                sprintf(buffer, "%lxh", disp32) ;
                            }
                            buffer += strlen(buffer) ;
                        }

                        /* Add the second offset (if any) */
                        if (reg2 != -1)  {
                            sprintf(buffer, indices[reg2-REG_EAX], "") ;
                            buffer += strlen(buffer) ;
                        }

                        /* Add the first offset (if any) */
                        if (reg1 != -1)  {
                            sprintf(buffer, indices[reg1-REG_EAX], multiplier) ;
                            buffer += strlen(buffer) ;
                        }
                    }
                }

                /* Do decoding offsets */
                if (decode)  {
                    regval regVal ;
                    base += (Address)disp32 ;

                    if (reg1 != -1)  {
		        Ibm_ReadRegister(REG_MACHINE, reg1, &regVal);
                        base += regVal * multi ;
                    }

                    if (reg2 != -1)  {
		        Ibm_ReadRegister(REG_MACHINE, reg2, &regVal);
                        base += regVal ;
                    }

		    base = MakeAddress(segVal, base & 0xFFFF) ;
		    
		    ea.handle = Handle_Find(base);
		    if (ea.handle != NullHandle) {
			ea.offset = (Address)(base - Handle_Address(ea.handle));
		    } else {
			ea.offset = base;
		    }
                }
				      
                /*
	         * If the thing was a real effective address and we're decoding,
	         * fetch the data at that address, the number of bytes depending
	         * on the mode of the effective address, of course.
	         */
	        if ((eaNum != -1) && decode) {
		    switch(args[1]) {
		        case 'b': {
			    byte	b;
			    Ibm_ReadBytes(1, ea.handle, ea.offset,
				          (genptr)&b);
			    vals[valNum++].OS_dword = b;
			    break;
		        }
		        case 'v':
			    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
				Var_FetchInt(4, ea.handle, ea.offset,
					     (genptr)&vals[valNum++].OS_dword);
				break;
			    }
			    /* else FALLTHRU */
		        case 'w': {
			    word	w;
			    Var_FetchInt(2, ea.handle, ea.offset,
				         (genptr)&w);
			    vals[valNum++].OS_dword = w;
			    break;
		        }
		        case 'd':
			    Var_FetchInt(4, ea.handle, ea.offset,
				         (genptr)&vals[valNum++].OS_dword);
			    break;
		        case 'f':
			    Var_FetchInt(4, ea.handle, ea.offset,
				         (genptr)&vals[valNum++].OS_float);
			    break;
		        case 'q': /* 64 bit memory operand */
			    Var_FetchInt(8, ea.handle, ea.offset, 
				         (genptr)&vals[valNum++].OS_double);
			    break;
		        case 't': /* 80 bit memory operand */
			    Var_FetchInt(10, ea.handle, ea.offset, 
				         (genptr)&vals[valNum++].OS_tbyte);
			    break;
		    }
	        }
            } else {
                /* Nope.  Do the 16-bit version */
#endif
                /*
	         * Effective address. The argument is encoded in the modrm byte.
	         * "indices" is a table of the indexing used based on the r/m field
	         * of the modrm byte.
	         */
	        static char *indices[] = {
                    /* 16-bit versions */
		    "[BX][SI]",
		    "[BX][DI]",
		    "[BP][SI]",
		    "[BP][DI]",
		    "[SI]",
		    "[DI]",
		    "[BP]",
		    "[BX]",
	        };
	        Address	base=0;
	        word	segVal;
	        int     reg1,
			reg2,
			segReg;
	        regval	regVal;
                char    type ;

	        /*
	         * Figure the base value from the index registers and the
	         * default or override segment. reg1 is the base register.
	         * reg2 is the index register (or -1 if no index). segReg is
	         * the default segment register for that mode. The effective
	         * address is accumulated in 'base'.
	         */
	        eaNum = valNum;
                switch (modrm & 0x7) {
		    case 0: reg1 = REG_BX; reg2 = REG_SI; segReg = REG_DS; break;
		    case 1: reg1 = REG_BX; reg2 = REG_DI; segReg = REG_DS; break;
		    case 2: reg1 = REG_BP; reg2 = REG_SI; segReg = REG_SS; break;
		    case 3: reg1 = REG_BP; reg2 = REG_DI; segReg = REG_SS; break;
		    case 4: reg1 = REG_SI; reg2 = -1;     segReg = REG_DS; break;
		    case 5: reg1 = REG_DI; reg2 = -1;     segReg = REG_DS; break;
		    case 6: reg1 = REG_BP; reg2 = -1;     segReg = REG_SS; break;
		    case 7: reg1 = REG_BX; reg2 = -1;     segReg = REG_DS; break;
		    default: Punt("Default reached in Ibm86Decode"); return(FALSE);
	        }

	        if (segover != (char *)NULL) {
		    segReg = overReg;
	        }
	        if (decode) {
		    Ibm_ReadRegister(REG_MACHINE, reg1, &regVal);
		    base = (Address)regVal;

		    if (reg2 != -1) {
		        Ibm_ReadRegister(REG_MACHINE, reg2, &regVal);
		        base += regVal;
                        base = (Address)((dword)base & 0xffff);
                    }
		    Ibm_ReadRegister16(REG_MACHINE, segReg, &segVal);
	        }
	        /*
	         * Indicate the type of the operand (but no PTR garbage...) as
	         * long as it's really an address (don't do it for registers).
	         */
                type = args[1] ;
#if REGS_32
		if (type == 'v')
		    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])
			type = 'd' ;
		    else
			type = 'w' ;
#else
		if (type == 'v')
		    type = 'w';
#endif
	        if (buffer && ((modrm & 0xc0) < 0xc0)) {
		    strcpy(buffer, ((type == 'b') ? "BYTE " :
				    ((type == 'w') ? "WORD " : 
				     ((type == 'd') ? "DWORD " :
				      ((type == 'f') ? "FLOAT " :
				       ((type == 'q') ? "DOUBLE " :
				        "TBYTE "))))));
		    buffer += strlen(buffer);
	        }
				      
	        /*
	         * The high two bits of the modrm byte tell us what sort of
	         * displacement there is on the index registers.
	         *	  00	No displacement. If r/m is 110, however, there's
	         *	  	really a 16-bit displacement and no index registers.
	         *	  	I.e. it's a 16-bit offset (a memory address).
	         *	  01	The displacement is 8 bits.
	         *	  10	16-bit displacement.
	         *	  11	r/m is actually a register description.
	         */
	        switch (modrm & 0xc0) {
	        case 0x00:
		    if ((modrm & 07) != 6) {
		        /*
		         * Indexing with no displacement
		         */
		        if (buffer) {
			    if (segover) {
			        sprintf(buffer, "%.2s:", segover);
			        buffer += 3;
			    }
#if REGS_32
                            sprintf(buffer, "%s", indices[(modrm & 7) + (prefixSize[PREFIX_ADDRESS_SIZE_32BIT]?8:0)]);
#else
                            sprintf(buffer, "%s", indices[(modrm & 7)]);
#endif
                            buffer += strlen(buffer);
			    if (decode) {
			        base += MakeAddress(segVal, 0) ;
			        ea.handle = Handle_Find(base);
			        if (ea.handle != NullHandle) {
				    ea.offset =
				        (Address)(base -
					          Handle_Address(ea.handle));
			        } else {
				    ea.offset = base;
			        }
			    }
		        }
		    } else {
		        /*
		         * Direct addressing w/16 bit offset. Since it's 16-bit,
		         * try and print the thing as an address since this is the
		         * way most tables are addressed.
		         */
		        len -= 2;
		        if (len < 0) {
			    return(FALSE);
		        }
		        if (buffer) {
			    if (segover) {
			        sprintf(buffer, "%.2s:", segover);
			        buffer += 3;
			    } else if (decode) {
			        /*
			         * If not overridden, segReg was set to REG_SS,
			         * which is wrong -- the default is REG_DS.
			         */
			        segReg = REG_DS;
			        Ibm_ReadRegister16(REG_MACHINE, REG_DS, &segVal);
			    }

			    if (decode) {
                                base = MakeAddress(segVal, (ip[0] | (ip[1] << 8))) ;
			        ea.handle = Handle_Find(base);
			        if (ea.handle != NullHandle) {
				    ea.offset =
				        (Address)(base -
					          Handle_Address(ea.handle));
			        } else {
				    ea.offset = base;
			        }
			    }
			    sprintf(buffer, "[%.4xh]", ip[0] | (ip[1] << 8));
			    buffer += strlen(buffer);
		        }
		        ip += 2;
		    }
		    break;
	        case 0x40:
		    /*
		     * 8-bit displacement.
		     */
		    len -= 1;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (buffer) {
		        if (segover) {
			    sprintf(buffer, "%.2s:", segover);
			    buffer += 3;
		        }
                        base += (ip[0] | ((ip[0]&0x80) ? 0xffffff00 : 0)) +
			    MakeAddress(segVal, 0);
		        sprintf(buffer, "%d%s",
			        ip[0] | ((ip[0]&0x80) ? 0xffffff00 : 0),
			        indices[modrm & 7]);
		        buffer += strlen(buffer);

		        if (decode) {
			    ea.handle = Handle_Find(base);
			    if (ea.handle != NullHandle) {
			        ea.offset =
				    (Address)(base - Handle_Address(ea.handle));
			    } else {
			        ea.offset = base;
			    }
		        }
		    }
		    ip += 1;
		    break;
	        case 0x80:
		    /*
		     * 16-bit displacement.
		     */
		    len -= 2;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (buffer) {
		        if (segover) {
			    sprintf(buffer, "%.2s:", segover);
			    buffer += 3;
		        }
		        if (decode) {
			    base += (ip[0] | (ip[1] << 8));
                            base = MakeAddress(segVal, base & 0xFFFF) ;
			    
			    ea.handle = Handle_Find(base);
			    if (ea.handle != NullHandle) {
			        ea.offset =
				    (Address)(base - Handle_Address(ea.handle));
			    } else {
			        ea.offset = base;
			    }
		        }
		        if ((modrm & 0x2) && ((modrm & 0x7) != 0x07) &&
			    (ip[1] & 0x80) &&
			    (segReg == REG_SS))
		        {
			    /*
			     * Negative offset from BP with no override (bp-involved
			     * modes are 2, 3, and 6): assume it's referencing a
			     * stack frame and print the thing in decimal
			     */
			    sprintf(buffer, "%d%s",
				    ip[0] | (ip[1] << 8) | 0xffff0000,
				    indices[modrm & 7]);
		        } else {
			    sprintf(buffer, "%xh%s", ip[0] | (ip[1] << 8),
				    indices[modrm & 7]);
		        }
		        buffer += strlen(buffer);

		    }
		    ip += 2;
		    break;
	        case 0xc0:
		    /*
		     * Byte/word register.
		     */

		    eaNum = -1;
		    if (buffer) {
		        switch (args[1])
		        {
		    	    case 'b': 
		    	    {

			        word w;

                                sprintf(buffer, "%.2s", 
				        &byteRegs[(modrm & 7) << 1]);
			        if (decode) {
			    	    Ibm_ReadRegister16(REG_MACHINE,
				    	             REG_AL + (modrm & 7),
					    	     &w);
			    	    vals[valNum++].OS_dword = w;
			        }
		    	    }
		    	    break;
		    	    case 'v':
#if REGS_32
                                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
			            regval w; 
				    
                                    sprintf(buffer++, "E%.2s", 
				            &wordRegs[(modrm & 7) << 1]);
			            if (decode) {
			    	        Ibm_ReadRegister(REG_MACHINE,
				    	                 REG_EAX + (modrm & 7),
					    	         &w);
			    	        vals[valNum++].OS_dword = w;
			            }
				    break;
                                }
				/* else FALLTHRU */
#endif
		    	    case 'w':
			    {
			            word w;
			        
			            sprintf(buffer, "%.2s", 
				            &wordRegs[(modrm & 7) << 1]);
			            if (decode) {
			    	        Ibm_ReadRegister16(REG_MACHINE,
				    	                 modrm & 7,
					    	         &w);
			    	        vals[valNum++].OS_dword = w;
			            }
		    	    }
			    break;
			    case 'f':
			    case 't':
			    case 'q':
			        if (modrm & 7)
			        {
				    sprintf(buffer, "ST(%u)", (modrm  & 7));
				    buffer += 3;
			        }
			        else
			        {
				    sprintf(buffer, "ST");
			        }
 	    	    	        flags = IA_FLOATREG;
			        break;
		        }
	    	        buffer += 2;
		    }
		    break;
	        }
	        /*
	         * If the thing was a real effective address and we're decoding,
	         * fetch the data at that address, the number of bytes depending
	         * on the mode of the effective address, of course.
	         */
	        if ((eaNum != -1) && decode) {
		    switch(args[1]) {
		        case 'b': {
			    byte	b;
			    Ibm_ReadBytes(1, ea.handle, ea.offset,
				          (genptr)&b);
			    vals[valNum++].OS_dword = b;
			    break;
		        }
		        case 'v':
#if REGS_32
			    if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
				Var_FetchInt(4, ea.handle, ea.offset,
					     (genptr)&vals[valNum++].OS_dword);
				break;
			    }
			    /* else FALLTHRU */
#endif
		        case 'w': {
			    word	w;
			    Var_FetchInt(2, ea.handle, ea.offset,
				         (genptr)&w);
			    vals[valNum++].OS_dword = w;
			    break;
		        }
		        case 'd':
			    Var_FetchInt(4, ea.handle, ea.offset,
				         (genptr)&vals[valNum++].OS_dword);
			    break;
		        case 'f':
			    Var_FetchInt(4, ea.handle, ea.offset,
				         (genptr)&vals[valNum++].OS_float);
			    break;
		        case 'q': /* 64 bit memory operand */
			    Var_FetchInt(8, ea.handle, ea.offset, 
				         (genptr)&vals[valNum++].OS_double);
			    break;
		        case 't': /* 80 bit memory operand */
			    Var_FetchInt(10, ea.handle, ea.offset, 
				         (genptr)&vals[valNum++].OS_tbyte);
			    break;
		    }
	        }
#if REGS_32
            }
#endif
            break;
	}
	case 'd':
	    /*
	     * Immediate data encoded in-line. Print them in decimal. (?)
	     */
	    if (args[1] == 'b') {
		/*
		 * Byte-sized immediate data. Sign-extend before printing.
		 */
		len -= 1;
		if (len < 0) {
		    return(FALSE);
		}
		if (buffer) {
		    vals[valNum].OS_dword = ip[0] | ((ip[0]&0x80) ? 
						     	    0xffffff00 : 0); 
		    sprintf(buffer, "%d (%02xh)", 
			    (int)(vals[valNum].OS_dword),ip[0]);
		    valNum++;
		    buffer += strlen(buffer);
		}
		ip += 1;
	    } else {
#if REGS_32
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
		    /*
		     * Word-sized immediate data. Sign-extend to 32-bits.
		     */
		    len -= 4;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (buffer) {
		        vals[valNum].OS_dword = *((dword *)ip) ;
		        sprintf(buffer, "%d (%xh)", *((dword *)ip),
			        *((dword *)ip));
		        valNum++;
		        buffer += strlen(buffer);
		    }
		    ip += 4;
                } else {
#endif
		    /*
		     * Word-sized immediate data. Sign-extend to 32-bits.
		     */
		    len -= 2;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (buffer) {
		        vals[valNum].OS_dword = (ip[0] | (ip[1] << 8) |
				    	        ((ip[1]&0x80) ? 0xffff0000 : 0));
		        sprintf(buffer, "%d (%04xh)", (int)(vals[valNum].OS_dword),
			        ip[0] | (ip[1] << 8));
		        valNum++;
		        buffer += strlen(buffer);
		    }
		    ip += 2;
#if REGS_32
                }
#endif
	    }
	    break;
	case 'a':
	    /*
	     * Control flow change using absolute address following the instruction.
	     *	  Size	    Change
	     *      v       Next word or dword (depending on operand size attribute)
	     *              are offset of destination in same segment from next
	     *              instruction.
	     *              next instruction.
	     *	    p	    Next four bytes or six bytes (depending on operand size
	     *              attribute) are [offset,segment] of destination.
	     */
	    if (args[1] == 'v') {
#if REGS_32
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
                    len -= 4;
		    if (len < 0) {
		        return(FALSE);
		    }
		    ea.handle = handle;
		    ea.offset = (Address)(ip[0] | (ip[1] << 8) | ((dword)ip[2] << 16)
					    | ((dword)ip[3] << 24));

		    if (buffer) {
		        PrintAddress(&buffer, ea.handle, ea.offset);
		    }
		    ip += 4;
                } else {
#endif
                    len -= 2;
		    if (len < 0) {
		        return(FALSE);
		    }
		    ea.handle = handle;
		    ea.offset = (Address)(ip[0] | (ip[1] << 8));

		    if (buffer) {
		        PrintAddress(&buffer, ea.handle, ea.offset);
		    }
		    ip += 2;
#if REGS_32
                }
#endif
            } else {  /* Case 'p' for pointer */
		Address	next;
#if REGS_32
		int pointerSize = (prefixSize[PREFIX_OPERAND_SIZE_32BIT]) ? 6 : 4;

		len -= pointerSize;
#else
		len -= 4;
#endif
		if (len < 0) {
		    return(FALSE);
		}
#if REGS_32
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])
		    next = MakeAddress((ip[4] | (ip[5] << 8)),
				       (ip[0] | (ip[1] << 8) | ((dword)ip[2] << 16)
					| ((dword)ip[3] << 24))) ;
		else
#endif
		    next = MakeAddress((ip[2] | (ip[3] << 8)),
				       (ip[0] | (ip[1] << 8))) ;

		ea.handle = Handle_Find(next);
		if (ea.handle != NullHandle) {
		    ea.offset = (Address)(next - Handle_Address(ea.handle));
		} else {
		    ea.offset = next;
		}

		if (buffer) {
		    PrintAddress(&buffer, ea.handle, ea.offset);
		}
#if REGS_32
                ip += pointerSize;
#else
		ip += 4;
#endif
	    }
	    break;

	case 'c':
	    /*
	     * Control flow change using relative offset following the instruction.
	     *	  Size	    Change
	     *	    b	    Byte is sign extended and added to the address
	     *		    of the next instruction.
	     *      v       Word or dword (depending on operand size attribute)
	     *              is sign extended and added to the address of the
	     *              next instruction.
	     */
	    if (args[1] == 'b') {
		len -= 1;
		if (len < 0) {
		    return(FALSE);
		}
		ea.handle = handle;

		ea.offset = (offset + (ip + 1 - ibuf)) +
		    (ip[0] | ((ip[0] & 0x80) ? 0xffffff00 : 0));

		if (buffer) {
		    PrintAddress(&buffer, ea.handle, ea.offset);
		}
		ip += 1;
	    } else { /* Case 'v' for [d]word */
#if REGS_32
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
                    len -= 4;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (handle != NullHandle) {
		        ea.handle = handle;
		        ea.offset = (Address)((((word)offset + (ip + 4 - ibuf2)) +
					       *((dword *)ip)) & 0xffff);
		    } else {
		        /*
		         * If absolute, deal with sign-extending the offset to
		         * 32-bits before adding it to the full 32-bit address
		         */
		        ea.handle = handle;
		        ea.offset = (Address)((dword)offset + (ip + 4 - ibuf2) + 
					      (*((dword *)ip) & 0xFFFF)) ;
		    }

		    if (buffer) {
		        PrintAddress(&buffer, ea.handle, ea.offset);
		    }
		    ip += 4;
                } else {
#endif
                    len -= 2;
		    if (len < 0) {
		        return(FALSE);
		    }
		    if (handle != NullHandle) {
		        ea.handle = handle;
		        ea.offset = (Address)((((word)offset + (ip + 2 - ibuf)) +
					       (ip[0] | (ip[1] << 8))) & 0xffff);
		    } else {
		        /*
		         * If absolute, deal with sign-extending the offset to
		         * 32-bits before adding it to the full 32-bit address
		         */
		        ea.handle = handle;
		        ea.offset = (Address)((dword)offset + (ip + 2 - ibuf) +
					      ip[0] + (ip[1] << 8) +
					      ((ip[1] & 0x80) ? 0xffff0000 : 0));
		    }

		    if (buffer) {
		        PrintAddress(&buffer, ea.handle, ea.offset);
		    }
		    ip += 2;
#if REGS_32
                }
#endif
	    }
	    break;

	case 'x':
            {
                char type = args[1] ;
                dword addr ;

	        /*
	         * Special-cased address for moving between memory and [E]A[XL]
	         * Address is at ip.
	         */

#if REGS_32
		if (type == 'v')
		    if (prefixSize[PREFIX_ADDRESS_SIZE_32BIT])
			type = 'd' ;
		    else
			type = 'w' ;
#else
		if (type == 'v')
		    type = 'w';
#endif
#if REGS_32
                if (type == 'd')  {
	            len -= 4 ;
	            if (len < 0) {
		        return(FALSE);
	            }
                    addr = *((dword *)ip) ;
                    ip += sizeof(dword) ;
                } else {
#endif
	            len -= 2;
	            if (len < 0) {
		        return(FALSE);
	            }
                    addr = *((word *)ip) ;
                    ip += sizeof(word) ;
#if REGS_32
                }
#endif
                eaNum = valNum;
	        if (buffer) {
		    sprintf(buffer, "%s %.2s%s[%xh]",
			    ((type == 'b') ? "BYTE" :
			     ((type == 'w') ? "WORD" : "DWORD")),
			    segover ? segover : "", 
			    segover ? ": " : "",
			    addr);
		    buffer += strlen(buffer);
	        }
	        
	        if (decode) {
		    Address	arg;
		    word	segVal;
		    
		    if (segover) {
		        Ibm_ReadRegister16(REG_MACHINE, overReg, &segVal);
		    } else {
		        Ibm_ReadRegister16(REG_MACHINE, REG_DS, &segVal);
		    }
                    arg = MakeAddress(segVal, addr & 0xFFFF) ;
		    ea.handle = Handle_Find(arg);
		    if (ea.handle != NullHandle) {
		        ea.offset = (Address)(arg - Handle_Address(ea.handle));
		    } else {
		        ea.offset = arg;
		    }

                    if (type == 'b') {
		        byte	b;
		        
		        Ibm_ReadBytes(1, ea.handle, ea.offset, (genptr)&b);
		        vals[valNum++].OS_dword = b;
#if REGS_32
                    } else if (type == 'd')  {
                        dword d ;
                        Var_FetchInt(4, ea.handle, ea.offset, (genptr)&d) ;
                        vals[valNum++].OS_dword = d ;
#endif
                    } else {
		        word	w;
		        
		        Var_FetchInt(2, ea.handle, ea.offset,
				     (genptr)&w);
		        
		        vals[valNum++].OS_dword = w;
		    }
	        }
            }
	    break;

	case 'o':
	    /*
	     * Print string source opcode only if segment override...
	     */
	    if (segover && buffer) {
		if (opname[0] == 'X') {
#if REGS_32
                    if (prefixSize[PREFIX_ADDRESS_SIZE_32BIT])  {
		        sprintf(buffer, "%.2s:[EBX][AL]", segover);
                    } else {
#endif
		        sprintf(buffer, "%.2s:[BX][AL]", segover);
#if REGS_32
                    }
#endif
		} else {
#if REGS_32
                    if (prefixSize[PREFIX_ADDRESS_SIZE_32BIT])  {
		        sprintf(buffer, "%.2s:[ESI]", segover);
                    } else {
#endif
		        sprintf(buffer, "%.2s:[SI]", segover);
#if REGS_32
                    }
#endif
		}
                buffer += strlen(buffer) ;
	    }
	    break;
	case 'N':
	    /*
	     * Opcode is actually a prefix -- decode the next instruction
	     */
	    /*
	     * See if first byte is actually a segment override prefix.
	     */
	    if (len <= 0) {
		return(FALSE);
	    }
	    if ((*ip & 0xe7) == 0x26) {
		/*
		 * First byte is segment-override prefix for e[bwd] argument.
		 * Find the segment name (not null-terminated) by shifting the
		 * reg field of the prefix down 2 bits (not three, since we
		 * need to multiply the segment register number by two
		 * anyway...). The instruction to decode begins at ip[1].
		 */
		
		segover = &segs[(*ip >> 2) & 0x06];
		overReg = REG_ES + ((*ip >> 3) & 0x03);
		ip++;
		len--;
#if REGS_32
    /* CS, DS, ES, or SS override */
            } else if ((*ip & 0xFE) == 0x64)  {
	        segover = &segsFSGS[(*ip & 1)<<1];
	        overReg = REG_FS + ((*ip & 1)<<1);
	        ip++ ;
	        len--;
#endif
	    } else {
		/*
		 * Indicate no override by setting segover to NULL. The
		 * instruction starts at ip.
		 */
		segover = (char *)NULL;
		overReg = 0;
	    }
	    
	    /*
	     * Locate the opcode in the table
	     */
	    inst = ip[0] | (ip[1] << 8) | (ip[1] << 16);
	    op = I86FindOpcode(inst, &modrm, &name32);
	    if (op != (I86Opcode *)NULL) {
		opname = op->name;
#if REGS_32
		if (prefixSize[PREFIX_OPERAND_SIZE_32BIT] && name32 != NULL)
		    opname = name32;
#endif		/*
		 * Print the opcode itself
		 */
		if (buffer) {
		    sprintf(buffer, "%-8s", opname);
		    buffer += 8;
		}
		/*
		 * Adjust ip and point args at the opcode's arguments. Since
		 * this loop goes until *args is 0, this allows the loop
		 * to continue parsing the arguments for the instruction
		 * itself. The flags for printing the arguments accumulate
		 * over prefixes...
		 */
		ip += op->length;
		len -= op->length;
		if (len < 0) {
		    return(FALSE);
		}
		args = op->args;
		flags |= op->flags;

		continue;
	    }
	    break;

	default:
	    /*
	     * Argument is a literal string. Enter both its characters,
	     */
	    if (buffer) {
#if REGS_32
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
                    sprintf(buffer, "E%.2s", args);
                } else {
#endif
                    sprintf(buffer, "%.2s", args);
#if REGS_32
                }
#endif
		buffer += strlen(buffer);
	    }
	    if (decode) {
		int 	regNum=0;
		regval  regVal;
		
		/*
		 * Record register value for printing arguments. We decide
		 * which regNum based on the two letters, making use of
		 * the registers known to be in the opcode table.
		 */
		switch(args[0]) {
		    case 'A':
			switch(args[1]) {
			    case 'X': regNum = REG_AX; break;
			    case 'L': regNum = REG_AL; break;
			    case 'H': regNum = REG_AH; break;
			}
			break;
		    case 'B':
			switch(args[1]) {
			    case 'P': regNum = REG_BP; break;
			    case 'X': regNum = REG_BX; break;
			    case 'L': regNum = REG_BL; break;
			    case 'H': regNum = REG_BH; break;
			}
			break;
		    case 'C':
			switch(args[1]) {
			    case 'X': regNum = REG_CX; break;
			    case 'L': regNum = REG_CL; break;
			    case 'H': regNum = REG_CH; break;
			    case 'S': regNum = REG_CS; break;
			}
			break;
		    case 'D':
			switch(args[1]) {
			    case 'X': regNum = REG_DX; break;
			    case 'L': regNum = REG_DL; break;
			    case 'H': regNum = REG_DH; break;
			    case 'I': regNum = REG_DI; break;
			    case 'S': regNum = REG_DS; break;
			}
			break;
		    case 'E':
			regNum = REG_ES;
			break;
		    case 'S':
			switch(args[1]) {
			    case 'P': regNum = REG_SP; break;
			    case 'S': regNum = REG_SS; break;
			    case 'I': regNum = REG_SI; break;
			}
			break;
		}
#if REGS_32
                /* If doing extended registers, convert */
                if (prefixSize[PREFIX_OPERAND_SIZE_32BIT])  {
                    if (regNum <= REG_DI)  {
                        regNum -= REG_AX ;
                        regNum += REG_EAX ;
                    }
                }
#endif

                Ibm_ReadRegister(REG_MACHINE, regNum, &regVal);
		vals[valNum++].OS_dword = regVal;
	    }
			
	    break;
	}
	args += 2;
	if ((*args != '\0') && (buffer != (char *)NULL)) {
	    strcpy(buffer, ", ");
	    buffer += 2;
	}
    }

    /*
     * If interested in the instruction size, return it
     */
    if (instSizePtr) {
	*instSizePtr = ip - ibuf;
    }

    if (decode) {
#if REGS_32
	Ibm86PrintArgs(decode, handle, flags, eaNum, &ea, vals, op, overReg, 
		       prefixSize);
#else
	Ibm86PrintArgs(decode, handle, flags, eaNum, &ea, vals, op, overReg);
#endif
    }
    return(1);
}

/***********************************************************************
 *				Ibm86Decode
 ***********************************************************************
 * SYNOPSIS:	Decode a single instruction
 * CALLED BY:	...
 * RETURN:	TRUE if could decode the thing.
 *	    	If buffer is non-null, it is filled with the string
 *		for the instruction.
 *		If instSizePtr is non-null, it is filled with the actual
 *	    	size of the instruction.
 *	    	If decode is non-null, it is filled with the actual
 *	    	operands of the instruction.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/22/88		Initial Revision
 *
 ***********************************************************************/
static int
Ibm86Decode(Handle    	handle,    	/* Handle of data to decode */
	    Address    	offset,	    	/* Offset of data to decode */
	    char	*buffer,    	/* Buffer in which to place assembly
					 * language version */
	    int		*instSizePtr,	/* Place for size of instruction */
	    char    	*decode)	/* Non-null to decode/print the args.
					 * points to buffer into which the
					 * args are formatted */
{
    byte		ibuf[MAXINST];	/* Place to store instruction and
					 * following bytes so we don't need
					 * to keep calling ReadBytes */
    /*
     * Fetch all the bytes we may need from the curPatient
     */
    if (!Ibm_ReadBytes(sizeof(ibuf), handle, offset, (genptr)ibuf))
    {
	/* we read zero bytes, so nothing to decode */
	return (FALSE);
    }

    return (Ibm86DecodeInt(ibuf, sizeof(ibuf), handle, offset, buffer,
			   instSizePtr, decode));
}


/***********************************************************************
 *				Ibm86SetBreak
 ***********************************************************************
 * SYNOPSIS:	  Set a breakpoint at the requested address.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The byte that was there before
 * SIDE EFFECTS:  The instruction that was there before is overwritten
 *	    	  with an INT 3 instruction.
 *
 * STRATEGY:
 *	Not much.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static Opaque
Ibm86SetBreak(Handle  	handle,	    /* Handle of instruction */
	      Address  	offset)	    /* Offset of instruction */
{
    byte  	  	insn;	    /* Instruction byte */
    byte  	  	bpt = 0xcc; /* Breakpoint instruction */

    /*
     * Read instruction to overwrite.
     */
    Ibm_ReadBytes(1, handle, offset, (genptr)&insn);

    /*
     * Store in the breakpoint
     */
    Ibm_WriteBytes(1, (genptr)&bpt, handle, offset);

    /*
     * Return the original instruction for ClearBreak to store back.
     */
    return((Opaque)insn);
}

/***********************************************************************
 *				Ibm86ClearBreak
 ***********************************************************************
 * SYNOPSIS:	  Clear out a breakpoint by installing the original
 *	    	  instruction.
 * CALLED BY:	  GLOBAL
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The breakpoint is overwritten.
 *
 * STRATEGY:
 *	None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static void
Ibm86ClearBreak(Handle 	handle,	    /* Handle of breakpoint */
		Address	offset,	    /* Offset to breakpoint */
		Opaque	data)	    /* Old instruction */
{
    byte  	  	insn = (byte)data;

    Ibm_WriteBytes(1, (genptr)&insn, handle, offset);
}

/***********************************************************************
 *				Ibm86ReturnAddress
 ***********************************************************************
 * SYNOPSIS:	  Given that we have just entered a new function,
 *	    	  return the address to which this new function will
 *	    	  return.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The return address
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *	Figure out if the current function is a near or far function
 *	and fetch the correct number of bytes from the stack, convert
 *	the resulting address to 32 bits and return it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *	ardeb	10/6/88	    	Changed to handles.
 *
 ***********************************************************************/
static GeosAddr
Ibm86ReturnAddress(void)
{
    Sym	    	  	function;   /* Function we entered */
    Address 	  	pc; 	    /* 32-bit version of CS:IP */
    word 	  	sp; 	    /* SP register */
    Handle  	    	handle;	    /* Handle of block in which we're
				     * executing */
    GeosAddr	    	result;

    Ibm_ReadRegister(REG_MACHINE, REG_PC, (regval *)&pc);
    Ibm_ReadRegister16(REG_MACHINE, REG_SP, &sp);

    handle = Handle_Find(pc);

    function = Sym_LookupAddr(handle, (Address)(pc - Handle_Address(handle)),
			      SYM_FUNCTION);
    if (Sym_IsNull(function) || !Sym_IsFar(function)) {
	/*
	 * The function is a near one. The offset comes from the stack,
	 * while the handle is what we've already got.
	 */
	Handle	shandle = Ibm86StackHandle();

	if (shandle == NullHandle) {
	    word    ss;

	    Ibm_ReadRegister16(REG_MACHINE, REG_SS, &ss);
	    Var_FetchInt(2, NullHandle, MakeAddress(ss, sp),
			 (genptr)&result.offset);
	} else {
	    Var_FetchInt(2, shandle, (Address)sp,
			 (genptr)&result.offset);
	}
	result.handle = handle;
    } else {
	/*
	 * Function is FAR -- fetch the long pointer from the stack, use
	 * its offset as the offset we return, but find its handle.
	 */
	SegAddr	    retAddr;
	Handle	    shandle = Ibm86StackHandle();

	if (shandle == NullHandle) {
	    word    ss;

	    Ibm_ReadRegister16(REG_MACHINE, REG_SS, &ss);

	    Var_Fetch(typeSegAddr, NullHandle, MakeAddress(ss, sp),
		      (genptr)&retAddr);
	} else {
	    Var_Fetch(typeSegAddr, shandle, (Address)sp,
		      (genptr)&retAddr);
	}
	result.offset = (Address)retAddr.offset;
	result.handle = Handle_Find(SegToAddr(retAddr));
    }
    return(result);
}

/***********************************************************************
 *				Ibm86FunctionStart
 ***********************************************************************
 * SYNOPSIS:	  Skip over any prologue in a function.
 * CALLED BY:	  GLOBAL
 * RETURN:	  The address of the first non-prologue instruction in
 *	    	  the function.
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *	None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/88		Initial Revision
 *
 ***********************************************************************/
static GeosAddr
Ibm86FunctionStart(Handle   handle,	    /* Handle of function */
		   word	    offset)	    /* Offset w/in handle */
{
    GeosAddr	    	result;

    /*
     * For now, don't bother doing anything.
     */
    result.handle = handle;
    result.offset = (Address)offset;

    return(result);
}

/***********************************************************************
 *				Ibm86GetFrameRegister
 ***********************************************************************
 * SYNOPSIS:	    Fetch the contents of a register from a certain
 *		    frame.
 * CALLED BY:	    GLOBAL
 * RETURN:	    TRUE if it could be gotten
 * SIDE EFFECTS:    Data are read from the PC
 *
 * STRATEGY:
 *	If the register isn't marked as saved in the current frame,
 *	call the ReadRegister vector.
 *
 *	Otherwise, fetch the offset of the register from the savedReg
 *	array and read the word from the PC and return it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 6/88	Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86GetFrameRegister(Frame 	*frame,	    /* Frame from which to get the
					     * value */
		      RegType	regType,    /* Type of register desired. Only
					     * REG_MACHINE is handled here. */
		      int   	regNum,	    /* The number of the register to
					     * fetch */
		      regval  	*valuePtr)  /* Where to store the value */
{
    FramePrivPtr    privPtr;	/* Private data in the frame */
    Handle	    stack;

    if (frame == NullFrame)
    {
	return (FALSE);
    }
    privPtr = (FramePrivPtr)frame->private;
    /*
     * 10/17/95: set curXIPPage to the xip page for the frame from which the
     * register is being fetched, so any use of the register value to look up
     * an address will be performed in the correct context. This is balanced
     * expr.y fetching the xipPage for the current frame at the start of the
     * parse, to cope with numeric segments being given... -- ardeb.
     */
    curXIPPage = privPtr->xipPage;

    stack = privPtr->stackHan;

    if (regType == REG_MACHINE) {
	switch (regNum) {
	    case REG_AX:
	    case REG_BX:
	    case REG_CX:
	    case REG_DX:
	    case REG_BP:
	    case REG_SI:
	    case REG_DI:
	    case REG_ES:
	    case REG_CS:
	    case REG_DS:
		if (privPtr->flags & (1 << regNum)) {
		    word	reg;
		    
		    if ((regNum == REG_CS) &&
			(privPtr->flags & RET_AT_STACKBOT))
		    {
			Var_FetchInt(2, Ibm86StackHandle(),
				     (Address)privPtr->savedRegs[regNum],
				     (genptr)&reg);
		    } else {
			Var_FetchInt(2, stack,
				     (Address)privPtr->savedRegs[regNum],
				     (genptr)&reg);
		    }
		    *valuePtr = reg;
		    return(TRUE);
		}
		break;
	    case REG_AL:
	    case REG_BL:
	    case REG_CL:
	    case REG_DL:
		if (privPtr->flags & (1 << (regNum - REG_AL))) {
		    byte	reg;
		    
		    Ibm_ReadBytes(1, stack,
				  (Address)privPtr->savedRegs[regNum - REG_AL],
				  (genptr)&reg);
		    *valuePtr = (word)reg;
		    return(TRUE);
		}
		break;
	    case REG_AH:
	    case REG_BH:
	    case REG_CH:
	    case REG_DH:
		if (privPtr->flags & (1 << (regNum - REG_AH))) {
		    byte	reg;
		    
		    Ibm_ReadBytes(1, stack,
				  (Address)privPtr->savedRegs[regNum-REG_AH]+1,
				  (genptr)&reg);
		    *valuePtr = (word)reg;
		    return(TRUE);
		}
		break;
	    case REG_SS:
		/*
		 * Use the segment of the stackHan (not the entryStackHan, as
		 * we want the SS active in this frame, which may not be
		 * what it was on entry, if the routine borrowed some stack
		 * space...)
		 */
		if (privPtr->stackHan != NullHandle) {
		    *valuePtr = Handle_Segment(privPtr->stackHan);
		    return(TRUE);
		}
		break;
	    case REG_SP:
		if (privPtr->flags & (1 << REG_SP)) {
		    *valuePtr = privPtr->sp;
		    return(TRUE);
		}
		break;
	    case REG_SR:
		if (privPtr->flags & FLAGS_SAVED) {
		    Var_FetchInt(2, stack,
				 (Address)privPtr->flagsAddr,
				 (genptr)valuePtr);
		    return(TRUE);
		}
		break;
	    case REG_IP:
		if (privPtr->flags & IP_SAVED) {
		    *valuePtr = (word)privPtr->ip;
		    return (TRUE);
		}
		break;
	    case REG_PC:
		if (privPtr->flags & IP_SAVED) {
		    *(Address *)valuePtr = (Handle_Address(frame->handle) +
					    privPtr->ip);
		    return(TRUE);
		}
		break;
	    case REG_FP:
		/*
		 * Make sure this frame has been fully decoded before we return
		 * the frame pointer.
		 */
		if (!(privPtr->flags & HAVE_RETADDR)) {
		    (void)Ibm86NextFrame(frame);
		}
		*valuePtr = privPtr->fp;
		return(TRUE);
#if REGS_32
            case REG_EAX:
            case REG_EBX:
            case REG_ECX:
            case REG_EDX:
            case REG_ESI:
            case REG_EDI:
            case REG_EBP:
            case REG_ESP:
                break ;
            case REG_EIP:
                break ;
            case REG_FS:
            case REG_GS:
                break ;
#endif /* REGS_32 */
	    default:
		return(FALSE);
	}
    } else {
	char	*regName = (char *)regNum;

	if (strcmp(regName, "xipPage") == 0) {
	    *valuePtr = privPtr->xipPage;
	    return(TRUE);
	}
    }
    /*
     * Default to reading the current value of the register
     */
    return Ibm_ReadRegister(regType, regNum, valuePtr);
}

static Boolean
Ibm86GetFrameRegister16(Frame 	*frame,	    /* Frame from which to get the
					     * value */
		      RegType	regType,    /* Type of register desired. Only
					     * REG_MACHINE is handled here. */
		      int   	regNum,	    /* The number of the register to
					     * fetch */
		      word  	*valuePtr)  /* Where to store the value */
{
    regval regvalue ;
    Boolean ret = Ibm86GetFrameRegister(frame, regType, regNum, &regvalue) ;
    *valuePtr = regvalue ;
    return ret ;
}


/***********************************************************************
 *				Ibm86SetFrameRegister
 ***********************************************************************
 * SYNOPSIS:	    Change the contents of a register for a certain
 *		    frame.
 * CALLED BY:	    GLOBAL
 * RETURN:	    TRUE if it could be changed
 * SIDE EFFECTS:    Data are written to the PC
 *
 * STRATEGY:
 *	If the register isn't marked as saved in the current frame,
 *	call the WriteRegister vector.
 *
 *	Otherwise, fetch the offset of the register from the savedRegs
 *	array and write the word to the PC.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 6/88	Initial Revision
 *
 ***********************************************************************/
static Boolean
Ibm86SetFrameRegister(Frame 	*frame,	    /* Frame to which to store the
					     * value */
		      RegType	regType,    /* Type of register desired. Only
					     * REG_MACHINE is handled here. */
		      int   	regNum,	    /* The number of the register to
					     * store */
		      regval  	value)	    /* Value to store */
{
    FramePrivPtr    privPtr;	/* Private data in the frame */
    Handle	    stack;

    privPtr = (FramePrivPtr)frame->private;
    stack = privPtr->entryStackHan;

    if (regType == REG_MACHINE) {
	switch (regNum) {
	case REG_AX:
	case REG_BX:
	case REG_CX:
	case REG_DX:
	case REG_SP:
	case REG_BP:
	case REG_SI:
	case REG_DI:
	case REG_ES:
	case REG_DS:
	    if (privPtr->flags & (1 << regNum)) {
		Var_StoreInt(2, value, stack,
			     (Address)privPtr->savedRegs[regNum]);
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	    break;
	case REG_AL:
	case REG_BL:
	case REG_CL:
	case REG_DL:
	    if (privPtr->flags & (1 << (regNum - REG_AL))) {
		Var_StoreInt(1, value, stack,
			     (Address)privPtr->savedRegs[regNum - REG_AL]);
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	    break;
	case REG_AH:
	case REG_BH:
	case REG_CH:
	case REG_DH:
	    if (privPtr->flags & (1 << (regNum - REG_AH))) {
		Var_StoreInt(1, value, stack,
			     (Address)privPtr->savedRegs[regNum - REG_AH]+1);
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	    break;
	case REG_SR:
	    if (privPtr->flags & FLAGS_SAVED) {
		Var_StoreInt(2, value, stack,
			     (Address)privPtr->flagsAddr);
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	case REG_CS:
	    if (privPtr->flags & (1 << REG_CS)) {
		if (privPtr->flags & RET_AT_STACKBOT) {
		    Var_StoreInt(2, value, Ibm86StackHandle(),
				 (Address)privPtr->savedRegs[REG_CS]);
		} else {
		    Var_StoreInt(2, value, stack,
				 (Address)privPtr->savedRegs[REG_CS]);
		}
		((FramePrivPtr)privPtr->prev->private)->retAddr.segment =
		    value;
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	case REG_IP:
	    if (privPtr->flags & IP_SAVED) {
		/*
		 * First modify the return address on the stack
		 */
		if (privPtr->flags & RET_AT_STACKBOT) {
		    Var_StoreInt(2, value, Ibm86StackHandle(),
				 (Address)privPtr->savedRegs[REG_CS]-2);
		} else {
		    Var_StoreInt(2, value, stack,
				 (Address)privPtr->sp);
		}
		/*
		 * Then our copy of that address
		 */
		privPtr->ip = value;
		/*
		 * Then the previous frame's copy of that address
		 */
		((FramePrivPtr)privPtr->prev->private)->retAddr.offset = value;
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
            break ;
#if REGS_32
        case REG_EAX:
        case REG_EBX:
        case REG_ECX:
        case REG_EDX:
        case REG_ESI:
        case REG_EDI:
        case REG_EBP:
        case REG_ESP:
	    if (privPtr->flags & (1 << regNum)) {
		Var_StoreInt(4, value, stack,
			     (Address)privPtr->savedRegs[regNum]);
		return(TRUE);
	    } else {
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	    break;
        case REG_FS:
        case REG_GS:
            {
                int index = regNum - REG_FS + SAVED_REG_FS_AND_GS;
	        if (privPtr->flags & (1 << index)) {
		    Var_StoreInt(4, value, stack,
			         (Address)privPtr->savedRegs[index]);
		    return(TRUE);
	        } else {
		    return Ibm_WriteRegister(regType, regNum, value);
	        }
            }            
            break;
#endif /* REGS_32 */
	case REG_PC:
	default:
	    return(FALSE);
	case REG_SS:
	    if (privPtr->stackHan != Ibm86StackHandle()) {
		return(FALSE);
	    } else {
		/* XXX: update stackHan, too */
		return Ibm_WriteRegister(regType, regNum, value);
	    }
	}
    } else {
	return Ibm_WriteRegister(regType, regNum, value);
    }
    return(FALSE); /* makes the compiler happier - shouldn't be reached */
}

/***********************************************************************
 *				Ibm86FrameInfo
 ***********************************************************************
 * SYNOPSIS:	    Provide info on saved registers, etc., for the frame
 * CALLED BY:	    FrameCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/88	Initial Revision
 *
 ***********************************************************************/
static void
Ibm86FrameInfo(Frame	*frame)
{
    FramePrivPtr    privPtr = (FramePrivPtr)frame->private;
    int	    	    i, mask;

    for (i = 0, mask = 1; i < REG_AL; i++, mask <<= 1) {
	if (i == REG_SP) {
	    Message("sp =    %04xh  ", privPtr->sp);
	} else {
	    Message("%s from ", registers[i].name);
	    if (privPtr->flags & mask) {
		Message("%04xh  ", privPtr->savedRegs[i]);
	    } else {
		Message("cpu   ");
	    }
	}
	if (!((i+1) & 3)) {
	    Message("\n");
	}
    }
    if (privPtr->flags & IP_SAVED) {
	Message("ip from %04xh  ", privPtr->sp);
    } else {
	Message("ip from cpu   ");
    }
    if (privPtr->flags & FLAGS_SAVED) {
	Message("flags from %04xh\n", privPtr->flagsAddr);
    } else {
	Message("flags from cpu\n");
    }
    if (privPtr->flags & HAVE_RETADDR) {
	Message("Return address = %04xh:%04xh ", privPtr->retAddr.segment,
		privPtr->retAddr.offset);
	if (privPtr->flags & ALWAYS_VALID) {
	    Message(" (from register/stackBot)");
	}
	Message("ss:TPD_stackBot = %04xh\n", privPtr->stackBot);
    } else {
	Message("Return address not determined");
    }
    Message("xip page = %d", privPtr->xipPage);
    Message("\n");
}
	

/***********************************************************************
 *			    Ibm86FindOpcodeCmd
 ***********************************************************************
 * SYNOPSIS:	    Locate and return data for the given opcode
 * CALLED BY:	    Tcl
 * RETURN:	    A list of data
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Requires three ascii integers as the bytes of the
 *	    	    opcode.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/27/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(find-opcode,Ibm86FindOpcode,TCL_EXACT,NULL,swat_prog,
"Locates the mnemonic for and decodes an opcode. Accepts the address from which\n\
the opcode bytes were fetched, and one or more opcode bytes as arguments.\n\
Returns a list of data from the opcode descriptor:\n\
	{name length branch-type args modrm bRead bWritten inst}\n\
length is the length of the instruction.\n\
branch-type is one of:\n\
\n\
	1	none (flow passes to next instruction)\n\
	j	absolute jump\n\
	b   	pc-relative jump (branch)\n\
	r	near return\n\
	R	far return\n\
	i	interrupt return\n\
	I	interrupt instruction\n\
\n\
args is a list of two-character argument descriptors. The first character\n\
indicates the type of argument. The second indicates the argument size.\n\
The first is taken from the following list:\n\
\n\
	c	code address -- indicates a flow change\n\
	d	data -- an immediate value\n\
	e	effective address -- contents of register or memory\n\
	m	memory\n\
	r	register\n\
	x	simple memory (used for short Ax MOV's)\n\
	N	next instruction. arg size ignored\n\
	o	string instruction source operand only if override\n\
\n\
Any argument descriptor that doesn't match is to be taken as a literal. E.g.\n\
AX as a descriptor means AX is that operand.\n\
modrm is the modrm byte for the opcode.\n\
bRead is the number of bytes that may be read by the instruction, if one of\n\
its operands is in memory. bWritten is the number of bytes that may be written\n\
by the instruction, if one of its operands is in memory.\n\
inst is the decoded form of the instruction. If not enough bytes were given\n\
to decode the instruction, inst is returned as empty.")
{
    unsigned long   inst;
    const I86Opcode *op;
    byte    	    modrm;
    GeosAddr	    addr;
    byte	    *bytes;
    int 	    i;
    const char	    *name32;
    int		    opsize = 0;

    bytes = (byte *)malloc(argc-1);
    /*
     * Convert all bytes from ascii.
     */
    for (i = 2; i < argc; i++) {
	bytes[i-2] = cvtnum(argv[i], NULL);
    }

    if (argc < 3) {
	free((malloc_t)bytes);
	Tcl_Error(interp, "Usage: find-opcode <addr> <byte>+");
    }

    /*
     * Skip over any prefix bytes -- the caller will want the actual,
     * unmodified instruction.
     */
    i = 0;
    while (1) {
	int done = 0;
	
	switch(bytes[i]) {
#if REGS_32
            case 0x66:  /* Operand size toggle 16/32 */
		opsize = TRUE;
		/* FALLTHRU */
            case 0x64:  /* FS: */
            case 0x65:  /* GS: */
            case 0x67:  /* Address size toggle 16/32 */
#endif
	    case 0xf3:	/* REP */
	    case 0xf2:	/* REPNE */
	    case 0x26:	/* ES: */
	    case 0x2e:	/* CS: */
	    case 0x36:	/* SS: */
	    case 0x3e:	/* DS: */
	    case 0xf0:	/* LOCK */
                i++;
		break;
	    default:
		done = 1;
		break;
	}
	if (done) {
	    break;
	}
    }
	
    inst = 0;
    switch(argc-(i+2)) {
	default:
	case 3: inst    |= bytes[i+2] << 16;
	case 2: inst	|= bytes[i+1] << 8;
	case 1: inst	|= bytes[i]; break; 
	case 0: break;	/* BOGUS -- ALL PREFIX */
    }
    if (!Expr_Eval(argv[1], NullFrame, &addr, (Type *)NULL, TRUE)) {
	free((malloc_t)bytes);
	Tcl_Error(interp, "couldn't parse address");
    }
    
    op = I86FindOpcode(inst, &modrm, &name32);
    if (op == NULL) {
	/*
	 * No known opcode -- return NIL
	 */
	Tcl_Return(interp, "nil", TCL_STATIC);
    } else {
	int 	    nops = strlen(op->args)/2;
	char	    *ops;    	/* Argument descriptors broken into elements */
	const char  *res[8];    /* Vector for Tcl_Merge of result */
	char	    len[3];     /* Length, in ascii */
	char	    btype[2];   /* Branch type, as string (not char) */
	char	    modrmstr[4];/* ModRM byte, in ascii decimal */
	char	    inst[256];
	int 	    length;
	char	    bread[3], bwrite[3];
	Boolean	    freeOps = FALSE;
	
	if (!Ibm86DecodeInt(bytes, argc-2, addr.handle, addr.offset,
			    inst, &length, NULL))
	{
	    /*
	     * Couldn't decode with the bytes given -- return empty instruction
	     * and set length to match opcode length.
	     */
	    inst[0] = '\0';
	    length = op->length;
	}
	/*
	 * Convert length to ascii
	 */
	sprintf(len, "%d", length);
	/*
	 * Convert branch type to string
	 */
	btype[0] = op->branch;
	btype[1] = '\0';

	if (nops) {
	    /*
	     * Break argument string into a list.
	     */
	    char    *cp;
	    const char	*ap;
	    
	    ops = (char *)malloc(nops * 3 + 1);
	    freeOps = TRUE;

	    ap = op->args;
	    cp = ops;

	    while (*ap != '\0') {
		/*
		 * First char always exists
		 */
		*cp++ = *ap++;
		if ((*cp++ = *ap++) != ' ') {
		    /*
		     * Store space as separator only if second char of
		     * descriptor wasn't a space
		     */
		    *cp++ = ' ';
		}
	    }
	    /*
	     * Null-terminate
	     */
	    *cp = '\0';
	} else {
	    ops = "";
	}
	/*
	 * Convert modrm byte to ascii
	 */
	sprintf(modrmstr, "%u", modrm);

	sprintf(bread, "%d", op->bread);
	sprintf(bwrite, "%d", op->bwrite);

	/*
	 * Form vector for merging, merge, and return result
	 */
#if REGS_32
	res[0] = (opsize && name32) ? name32 : op->name;
#else
	res[0] = op->name;
#endif
	res[1] = (const char *)len;
	res[2] = (const char *)btype;
	res[3] = (const char *)ops;
	res[4] = (const char *)modrmstr;
	res[5] = (const char *)bread;
	res[6] = (const char *)bwrite;
	res[7] = (const char *)inst;

	Tcl_Return(interp, Tcl_Merge(8, (char **)res), TCL_DYNAMIC);
	if (freeOps) {
	    free((malloc_t)ops);
	}
    }

    free((malloc_t)bytes);
    return(TCL_OK);
}
	    

/***********************************************************************
 *				Ibm86_Init
 ***********************************************************************
 * SYNOPSIS:	  Initialize Ibm 8086 interface
 * CALLED BY:	  Ibm_Init
 * RETURN:	  Nothing
 * SIDE EFFECTS:  Procedure vectors are filled.
 *		  Register information is entered.
 *		  Machine-dependent parameters initialized.
 *
 * STRATEGY:
 *	This stuff is all constant, so the initialization is fairly
 *	straight-forward.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/88		Initial Revision
 *
 ***********************************************************************/
void
Ibm86_Init(Patient  patient)
{
    int			i;
    Ibm86PrivPtr 	privPtr;
    static Boolean  	initialized = FALSE;

    privPtr = (Ibm86PrivPtr)malloc_tagged(sizeof(Ibm86PrivRec), TAG_MD);
    privPtr->top = NullFrame;
    privPtr->thread = NullThread;
    patient->mdPriv =	    	    (Opaque)privPtr;

    if (!initialized) {
	MD_CurrentFrame = 	Ibm86CurrentFrame;
	MD_NextFrame =	    	Ibm86NextFrame;
	MD_PrevFrame =	    	Ibm86PrevFrame;
	MD_CopyFrame =	    	Ibm86CopyFrame;
	MD_FrameValid =	    	Ibm86FrameValid;
	MD_DestroyFrame =	Ibm86DestroyFrame;
	MD_FrameInfo =	    	Ibm86FrameInfo;
	MD_ReturnAddress =	Ibm86ReturnAddress;
	MD_FunctionStart =	Ibm86FunctionStart;
	MD_GetFrameRegister =   Ibm86GetFrameRegister;
	MD_SetFrameRegister =   Ibm86SetFrameRegister;
	MD_SetBreak =	    	Ibm86SetBreak;
	MD_ClearBreak =	    	Ibm86ClearBreak;
	MD_Decode =		Ibm86Decode;
	MD_FrameRetaddr =   	Ibm86FrameRetaddr;
	MD_GetFrame =	    	Ibm86GetFrame;

	for (i = 0; i < Number(registers); i++) {
	    Private_Enter(registers[i].name, (Opaque)&registers[i].data,
			  (void (*)(void *, char *))NULL);
	}

	(void)Event_Handle(EVENT_EXIT, 0, Ibm86NukeFrames,
			   (ClientData)NULL);
	(void)Event_Handle(EVENT_CONTINUE, 0, Ibm86InvalidateFrames,
			   (ClientData)NULL);
	(void)Event_Handle(EVENT_ATTACH, 0, Ibm86InvalidateFrames,
			   (ClientData)NULL);
	(void)Event_Handle(EVENT_CHANGE, 0, Ibm86HandleChange,
			   (ClientData)NULL);

	Cmd_Create(&Ibm86FindOpcodeCmdRec);
/*	Cmd_Create(&Ibm86InvalidateFramesCmdRec); */
	initialized = TRUE;
    }

    if ((strcmp(patient->name, "geos") == 0) ||
	(strcmp(patient->name, "kernel") == 0))
    {
	Sym 	sym;

	/*
	 * Locate TPD_stackBot's offset
	 */
	sym = Sym_LookupInScope("ThreadPrivateData", SYM_TYPE, patient->global);
	assert(!Sym_IsNull(sym));
	sym = Sym_LookupInScope("TPD_stackBot", SYM_FIELD, sym);
	assert(!Sym_IsNull(sym));
	Sym_GetFieldData(sym, &stackBotOff, (int *)NULL, (Type *)NULL,
			 (Type *)NULL);
	stackBotOff /= 8;   /* Returned in bits */
	/*
	 * Locate the ProcCallFixedOrMovable family of functions.
	 */
	{
	    GeosAddr	addr;
	    static struct {
		const char  *name;
		SegAddr	    *var;
	    }	    pcfomFuncs[] = {
		{"ProcCallFixedOrMovable", &pcfom},
		{"PROCCALLFIXEDORMOVABLE_PASCAL", &pcfomPascal},
		{"_ProcCallFixedOrMovable_cdecl", &pcfomCdecl}
	    };
	    int	    	i;
	    Sym	    	kcode;

	    /*
	     * Locate kcode scope, as we cannot use Sym_Lookup here, owing
	     * to the patient not actually being on the list of known patients
	     * yet, so when the lookup in patient->global fails, we fail
	     * an assertion attempting to get the patient for the scope we
	     * passed in.
	     */
	    kcode = Sym_LookupInScope("kcode", SYM_MODULE, patient->global);
	    assert(!Sym_IsNull(kcode));
	    for (i = 0; i < patient->numRes; i++) {
		if (!Sym_IsNull(patient->resources[i].sym))
		{
		    if (Sym_Equal(kcode, patient->resources[i].sym)) 
		    {
		    	addr.handle = patient->resources[i].handle;
			break;
		    }
		}
	    }
	    for (i = 0; i < sizeof(pcfomFuncs)/sizeof(pcfomFuncs[0]); i++) {
		sym = Sym_LookupInScope(pcfomFuncs[i].name, SYM_FUNCTION,
					kcode);
		assert(!Sym_IsNull(sym));
		
		Sym_GetFuncData(sym, (Boolean *)NULL, &addr.offset,
				(Type *)NULL);
		
		pcfomFuncs[i].var->segment = Handle_Segment(addr.handle);
		pcfomFuncs[i].var->offset = (word)addr.offset;
	    }
	}
    }
}
