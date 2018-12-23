/***********************************************************************
 *
 *      Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:     PC/GEOS
 * FILE:        geos.h
 * AUTHOR:      Tony Requist: February 11, 1991
 *
 * DECLARER:    Kernel
 *
 * DESCRIPTION:
 *      This file defines global constants and structures.
 *
 *      $Id: geos.h,v 1.1 97/04/04 15:57:18 newdeal Exp $
 *
 ***********************************************************************/

#ifndef __GEOS_H
#define __GEOS_H


#include <stddef.h>


/*
 ******************************************************************
 *
 * Compiler dependent definitions
 *
 ******************************************************************
 */

#ifdef __HIGHC__

/*
 *      *****   MetaWare HighC   *****
 */

	/* Standard Pascal Conventions */
pragma Calling_Convention( _CALLEE_POPS_STACK | _SAVE_REGS);

#define _pascal _CC(_CALLEE_POPS_STACK | _SAVE_REGS)
#define _cdecl _CC(_REVERSE_PARMS | _SAVE_REGS)

pragma Off(Prototype_conversion_warn);
pragma Static_segment("idata");
pragma On(Optimize_for_space);
pragma On(Optimize_FP);
pragma On(Optimize_xjmp);       /* -g turns this off, we always need -g */
pragma Off(Public_var_warnings);
pragma On(Long_enums);          /* to be compatible with MSC */

#define _pragma_const_in_code pragma On(Const_in_code); \
			      pragma On(Literals_in_code); \
			      pragma On(Read_only_strings)
#define _pragma_end_const_in_code pragma Off(Const_in_code); \
				  pragma Off(Literals_in_code); \
				  pragma Off(Read_only_strings)

#define _inline_byte(val) _inline(val)
#define _inline_word(val) do{ _inline_byte(val & 0xff); _inline_byte(val >> 8); } while(0)

#define _REVERSED_DISTANCE_SEMANTICS

/* Macro so set data segments (HighC screws up if we use this */

#define _pragma_set_data_segment(seg)
#define _pragma_default_data_segment

#define PCB(ret,name,args) ret _pascal (*name) args
#define CCB(ret,name,args) ret _cdecl (*name) args

#elif defined __BORLANDC__

/*
 *      *****   Borland C   *****
 */

#define _pascal pascal
#define _cdecl cdecl

#pragma options -zRidata
#define _inline_byte(val)  inline_doesn_exist_yet_for_borland
#define _inline_word(val)  inline_doesn_exist_yet_for_borland

#define _far far

#define PCB(ret,name,args) ret (_pascal *name) args
#define CCB(ret,name,args) ret (_cdecl *name) args


#elif defined _MSDOS && _MSC_VER

/*
 *      *****   Microsoft C 6.0   *****
 */

#define __BASED_VARS

#define _pascal __pascal
#define _cdecl /* there is no cdecl */
#define _far __far
#define _inline_byte(val) __asm{ _emit val }
#define _inline_word(val) do{ _inline_byte(val & 0xff); _inline_byte(val >> 8);}while (0)

/* Macro to set data segments */

#define _pragma_set_data_segment(seg)
#define _pragma_default_data_segment

#define PCB(ret,name,args) ret (_pascal *name) args
#define CCB(ret,name,args) ret (_cdecl *name) args

#elif defined __WATCOMC__

/*
 *      *****   Watcom C   *****
 */
#define _pascal __pascal
#define _cdecl __cdecl

#define _inline_byte(val)  inline_doesn_exist_yet_for_watcom
#define _inline_word(val)  inline_doesn_exist_yet_for_watcom

#define _far __far

#define PCB(ret,name,args) ret (_pascal *name) args
#define CCB(ret,name,args) ret (_cdecl *name) args



#else
/*
 *      *****   Generic C (useful for type checking)   *****
 */

#define _near
#define _far
#define _pascal
#define _cdecl

#define _inline_byte(val)
#define _inline_word(val)

#define PCB(ret,name,args) ret (*name) args
#define CCB(ret,name,args) ret (*name) args

#endif   
/*
 * End of compiler dependent definitions
 *
 ******************************************************************
 */


/*
 * Error checking stuff
 */

#ifdef  DO_ERROR_CHECKING
#define ERROR_CHECK (-1)
#else
#define ERROR_CHECK 0
#endif

/*
 * DBCS stuff
 */

#ifdef  DO_DBCS

#define DBCS_GEOS (-1)
typedef wchar_t TCHAR;
#define __T(x) L##x

#else

#define DBCS_GEOS 0
typedef char TCHAR;
#define __T(x) x

#endif

#define _T(x) __T(x)
#define _TEXT(x) __T(x)


/*
 * Common constants
 */

#define FALSE 0
#define TRUE (~0)           /* Use as a return value, *not* for comparisons */

/*
 *      The problem here is that <stddef.h> defines null to be "(void *) 0",
 *      and this can't be assigned to a function pointer, no matter how we
 *      cast it, so we change it to just be 0 here. If you want some other
 *      value of NULL, define it after including "geos.h".
 */
#undef  NULL
#define NULL 0

/*
 * Standard types
 */

typedef	unsigned char byte;
typedef	signed char sbyte;
typedef	unsigned short word;
typedef	signed short sword;
typedef	unsigned long dword;
typedef	long sdword;
typedef	byte ByteFlags;
typedef	word WordFlags;
typedef	dword DWordFlags;
typedef	byte ByteEnum;
typedef	sword Boolean;
typedef unsigned int wchar;

#if (defined _MSDOS && _MSC_VER) || defined __WATCOMC__
typedef void __based(void)* ChunkHandle;
#else
typedef word ChunkHandle;
#endif

typedef dword optr;
typedef word Message;
typedef word VardataKey;

typedef word Handle;
typedef Handle MemHandle;
typedef Handle DiskHandle;
typedef Handle FileHandle;
typedef Handle ThreadHandle;
typedef Handle QueueHandle;
typedef Handle TimerHandle;
typedef Handle GeodeHandle;
typedef Handle GStateHandle;
typedef Handle WindowHandle;
typedef Handle SemaphoreHandle;
typedef Handle EventHandle;
typedef Handle ThreadLockHandle;
typedef Handle VMFileHandle;
typedef Handle hptr;

typedef Handle ReservationHandle;

typedef word VMBlockHandle;
typedef dword VMChain;
typedef word DBGroup;
typedef word DBItem;
typedef dword DBGroupAndItem;
typedef word Segment;

typedef struct _ClassStruct ClassStruct;

#define NullChunk ((ChunkHandle) 0)
#define NullHandle ((Handle) 0)
#define NullOptr ((optr) 0)


/*
 * Standard macros
 */

#ifdef __BORLANDC__
  /*
   * Versions optimized for Borland C, modelled after FP_SEG etc.
   */
# define OptrToHandle(op)       ((MemHandle) (void __seg *)(void __far *)(op))
# define OptrToChunk(op)        ((ChunkHandle) (op))

# define ConstructOptr(han,ch)  ((optr)(((void __seg *)(han) + (void __near *)(ch))))

# define PtrToSegment(ptr) 	((Segment) (void __seg *)(void __far *)(ptr))
# define SegmentOf(ptr) 	((Segment) (void __seg *)(void __far *)(ptr))
# define PtrToOffset(ptr) 	((word) (ptr))

#else 
#if defined(__WATCOMC__)

# define OptrToHandle(op) ((MemHandle) ((op) >> 16))
# define OptrToChunk(op) ((ChunkHandle) (op))

# define ConstructOptr(han,ch) ((((optr) (han)) << 16) | ((dword) (ch)))

# define PtrToSegment(ptr) 	((Segment) (((dword) (ptr)) >> 16))
# define SegmentOf(ptr) 		((Segment) (((dword) (ptr)) >> 16))
# define PtrToOffset(ptr) 	((word) ((dword) (ptr)))

#else

  /*
   * Standard C versions
   */
# define OptrToHandle(op) ((MemHandle) ((op) >> 16))
# define OptrToChunk(op) ((ChunkHandle) (op))

# define ConstructOptr(han,ch) ((((optr) (han)) << 16) | ((ChunkHandle) (ch)))

# define PtrToSegment(ptr) 	((Segment) (((dword) (ptr)) >> 16))
# define SegmentOf(ptr) 		((Segment) (((dword) (ptr)) >> 16))
# define PtrToOffset(ptr) 	((word) ((dword) (ptr)))
#endif
#endif

/* The following macros are obsolete. */
#define ChunkOf(optr)           OptrToChunk(optr)
#define HandleOf(optr)          OptrToHandle(optr)
#define HandleToOptr(han)       ConstructOptr(han,NullChunk)


#ifndef offsetof
#define offsetof(str, field)    ((word)&((str _near *)0)->field)
#endif

#define word_offsetof(str, field) ((word)&((str _near *)0)->field)

#define ARRAY_LEN(array, struct) (sizeof(array)/sizeof(struct))

/*
 * Standard fixed point types
 */

typedef struct {
    sword	WAAH_low;
    sbyte	WAAH_high;
} WordAndAHalf;

typedef word BBFixedAsWord;

typedef struct {
    byte	BBF_frac;
    sbyte	BBF_int;
} BBFixed;

typedef struct {
    byte	WBF_frac;
    sword	WBF_int;
} WBFixed;

typedef dword WWFixedAsDWord;

typedef struct {
    word	WWF_frac;
    sword	WWF_int;
} WWFixed;

#define MakeWWFixed(fl) ((dword) ((fl)*65536L))

/* These are for getting portions of a WWFixedAsDWord value. */
#define IntegerOf(op) ((word) (((WWFixedAsDWord) (op)) >> 16))
#define FractionOf(op) ((word) ((WWFixedAsDWord) (op)))

/* These are for addressing portions of a WWFixed value in memory. */
#define WWFixedToFrac(op) ((*((WWFixed *)&(op))).WWF_frac)
#define WWFixedToInt(op) ((*((WWFixed *)&(op))).WWF_int)

typedef struct {
    word        DWF_frac;
    sdword      DWF_int;
} DWFixed;


typedef WordFlags CPUFlags;
#define CPU_OVERFLOW_OFFSET     (11)
#define CPU_OVERFLOW            (0x01 << CPU_OVERFLOW_OFFSET)
#define CPU_DIRECTION_OFFSET    (10)
#define CPU_DIRECTION           (0x01 << CPU_DIRECTION_OFFSET)
#define CPU_INTERRUPT_OFFSET    (9)
#define CPU_INTERRUPT           (0x01 << CPU_INTERRUPT_OFFSET)
#define CPU_TRAP_OFFSET         (8)
#define CPU_TRAP                (0x01 << CPU_TRAP_OFFSET)
#define CPU_SIGN_OFFSET         (7)
#define CPU_SIGN                (0x01 << CPU_SIGN_OFFSET)
#define CPU_ZERO_OFFSET         (6)
#define CPU_ZERO                (0x01 << CPU_ZERO_OFFSET)
#define CPU_AUX_CARRY_OFFSET    (4)
#define CPU_AUX_CARRY           (0x01 << CPU_AUX_CARRY_OFFSET)
#define CPU_PARITY_OFFSET       (2)
#define CPU_PARITY              (0x01 << CPU_PARITY_OFFSET)
#define CPU_CARRY_OFFSET        (0)
#define CPU_CARRY               (0x01 << CPU_CARRY_OFFSET)


/***/

#define NO_ERROR_RETURNED 0

extern word     /*XXX*/
    _pascal ThreadGetError(void);

extern void
    _pascal ThreadSetError(word errno);

#ifdef __HIGHC__
pragma Alias(ThreadGetError, "THREADGETERROR");
pragma Alias(ThreadSetError, "THREADSETERROR");
#endif

#endif
