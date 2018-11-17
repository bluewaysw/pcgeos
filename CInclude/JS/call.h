/* call.h - The 'context' structure.
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

/* 'struct Call' (also known as a jseContext) is the heart of the
 * ScriptEase engine. This data structure keeps track of a script
 * session. It keeps track of all memory used, all variables,
 * the current execution chain of functions, and so forth. A
 * pointer to a Call is passed to every function during execution
 * so each has access to all this needed information.
 *
 * An API application allocated one Call (using the ScriptEase
 * API call 'jseInitializeExternalLink') per script run
 * simultaneously. One Call can run one script at once, no
 * more. A single Call cannot be used by multiple threads; if
 * you need to run more than one script at a time, initialize
 * a new Call for each one.
 *
 * Note that a Call keeps track of a script's execution such
 * that we can execute a line of script code, return to the
 * user, then pick up where we have left off. This is what
 * the 'jseInterpExec' function does. However, if a wrapper
 * function is called, it is written in C, and we cannot
 * 'return' from the middle of it and then end up in it
 * again. It is easy to see that such a call must be
 * considered an entire statement in itself. However, such
 * a wrapper function can use the API to execute child
 * scripts. Because the chain of execution is threaded
 * through user's C code, there is no way to unroll all
 * the way back to the original caller and then back through
 * the C code to execute this child script a statement at
 * a time. Thus, limitations make the child script also
 * be considered part of that 'one statement', even though
 * it will be many statements long.
 */

#ifndef _CALL_H
#define _CALL_H

#include "extlib.h"

/* SE430
 *
 * Sees a lot of changes from se420, see call.c at the top for
 * some comments. More information is here.
 *
 * First, nested functions are now supported. As per ECMA, we
 * save the scope chain for each function when it is created.
 * We do not save the global variable as part of the scope
 * chain, it is implicitly understood to be there. This means
 * that the saved scope chain for global functions ends up
 * being nothing, i.e. NULL. Thus, for the vast majority
 * of functions, we don't have to build an explicit chain,
 * meaning that they are fast.
 */

#if defined(__cplusplus)
   extern "C" {
#endif

/* ----------------------------------------------------------------------
 * SECODE stack and manipulation functions
 * ---------------------------------------------------------------------- */

#if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
   /* The stack can move around, so we have to store indexes
    * into it. Needs to be signed to handle -1 == NULL frame.
    */
   typedef sint STACKPTR;

#  define STACK0 (call->Global->growingStack+call->stackptr)
#  define STACK1 (call->Global->growingStack+(call->stackptr-1))
#  define STACK2 (call->Global->growingStack+(call->stackptr-2))
#  define STACKX(x) (call->Global->growingStack+(call->stackptr-(x)))

#  define STACK_POP (call->stackptr--)
#  define STACK_POPX(x) (call->stackptr -= x)


   /* IMPORTANT: when using STACK_PUSH, make sure you initialize
    * it before collection can occur! When in doubt, SEVAR_INIT_UNDEFINED
    * it immediately.
    *
    * For growing stack, we don't need to do any extra checks because
    * that is done when a function is called, i.e. we verify we have
    * enough space there and extend the stack if we do not.
    */
#  define STACK_PUSH (call->Global->growingStack + (++call->stackptr))
#  define STACK_PUSH_ONLY (++call->stackptr)
#  define STACK_PUSHX(x) (call->Global->growingStack + (call->stackptr+=x))

#  define FRAME (call->frameptr?call->Global->growingStack + call->frameptr:NULL)
#  define FRAMECALL(c) ((c)->frameptr?(c)->Global->growingStack + (c)->frameptr:NULL)

#  define STACKPTR_SAVE(x) ((x)-call->Global->growingStack)
#  define STACK_FROM_STACKPTR(x) (call->Global->growingStack + (x))

#else

   /* The stack is fixed in size and location. Since it cannot
    * move, indexes into it can be stored as direct pointers,
    * rather than having to do the addition each time.
    *
    * This results in faster AND smaller code
    */
   typedef struct _SEVar *STACKPTR;

#  define STACK0 (call->stackptr)
#  define STACK1 (call->stackptr-1)
#  define STACK2 (call->stackptr-2)
#  define STACKX(x) (call->stackptr-(x))

#  define STACK_POP (call->stackptr--)
#  define STACK_POPX(x) (call->stackptr -= (x))

   /* IMPORTANT: when using STACK_PUSH, make sure you initialize
    * it before collection can occur! When in doubt, SEVAR_INIT_UNDEFINED
    * it immediately.
    */
#  define STACK_PUSH (++call->stackptr)
#  define STACK_PUSHX(x) (call->stackptr+=x)

#  define FRAME  (call->frameptr)
#  define FRAMECALL(c)  ((c)->frameptr)

#  define STACKPTR_SAVE(x) (x)
#  define STACK_FROM_STACKPTR(x) (x)

#endif


/* The idea of a frame is simple. The call has several fields that
 * relate to the currently executing function. When we execute a
 * new function, the old fields are thrown onto the stack, and
 * the new values inserted. When we return, the old values can
 * be retrieved from the stack. This is called a stack frame.
 * We have a frame pointer, which is one of the values that gets
 * saved. The locals and parameters can also be found from the
 * frame.
 */

/* STACK FRAME:
 *
 * FRAME is basically how we get at everything.
 *
 *    fptr[1]..fptr[num_locals]      = local variable storage
 *    fptr[0]                        = previous_fptr as number variable
 *    fptr[-1]                       = old variable object
 *    fptr[-2]                       = num_args stored as number variable
 *    fptr[-3]                       = true_args stored as number variable
 *    fptr[-4]                       = last iptr stored as number variable
 *    fptr[-5]                       = default return if return is undefined
 *    fptr[-6]                       = saved 'new_scope_chain'
 *    fptr[-7]                       = old useCache setting (if defined)
 *    fptr[-8]..fptr[-num_args-7]    = the arguments
 *    fptr[-num_args-8]              = current function variable
 *    fptr[-num_args-9]              = current this variable
 *    fptr[-num_args-10]..fptr[-x]   = intermediate stuff for last function
 */

#if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
#  define FUNC_OFFSET      8
#  define THIS_OFFSET      9
#  define USE_CACHE_OFFSET 7
#  define OLD_USE_CACHE    (FRAME-USE_CACHE_OFFSET)
#else
#  define FUNC_OFFSET      7
#  define THIS_OFFSET      8
#endif

#define FUNCVAR         (FRAME-(FUNC_OFFSET+call->num_args))
#define FUNCVARCALL(c)  (FRAMECALL(c)-(FUNC_OFFSET+(c)->num_args))
#define FUNCPTR_STACK   (SEVAR_GET_OBJECT(FUNCVAR)->func)
#define FUNCPTR         (call->funcptr)

#define CALL_THIS       (FRAME-(THIS_OFFSET+call->num_args))


#define NEW_SCOPE_OFFSET 6
#define RETURN_OFFSET 5
#define OLD_RETURN      (FRAME-RETURN_OFFSET)
#define ARGS_OFFSET 2
#define OLD_ARGS        (FRAME-ARGS_OFFSET)
#define TRUE_ARGS_OFFSET 3
#define OLD_TRUE_ARGS   (FRAME-TRUE_ARGS_OFFSET)
#define IPTR_OFFSET 4
#define OLD_IPTR        (FRAME-IPTR_OFFSET)
#define VAROBJ_OFFSET 1
#define OLD_VAROBJ      (FRAME-VAROBJ_OFFSET)
#define OLD_FRAME       (FRAME)
#define OLD_NEW_SCOPE   (FRAME-NEW_SCOPE_OFFSET)

#if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
#  define PARAM_START USE_CACHE_OFFSET
#else
#  define PARAM_START NEW_SCOPE_OFFSET
#endif

#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
#  define CALL_CBEHAVIOR  ((FRAME==NULL)?False:FUNCTION_C_BEHAVIOR(FUNCPTR))
#endif

#define IPTR (call->iptr)
#if JSE_MEMEXT_SECODES==1
#  define IPTR_FROM_INDEX(c,i) (call->base + (i))
#  define INDEX_FROM_IPTR(c,i) ((i) - call->base)
#else
#  define IPTR_FROM_INDEX(c,i) (((struct LocalFunction *)(FUNCPTR))->opcodes + (i))
#  define INDEX_FROM_IPTR(c,i) ((i) - ((struct LocalFunction *)(FUNCPTR))->opcodes)
#endif


/* NOTE: locals are numbered from 1 so we don't have to add 1 each time */
#define CALL_LOCAL(i) (FRAME+(i))
/* Parameters are numbered from 0 */
#define CALL_PARAM(i) (FRAME-(PARAM_START+call->num_args-(i)))


struct Global_;


struct sharedDataNode
{
   void _FAR_ *            data;
   jseShareCleanupFunc     cleanupFunc;
   struct sharedDataNode * next;
   jsecharptr              name;
};


/* IMPORTANT: This value MUST be an even number of bytes!!! */
#if (defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)) \
 || ( defined(__JSE_WIN16__) || defined(__JSE_DOS16__) )
   typedef uword16 stringLengthType;
#else
   typedef uword32 stringLengthType;
#endif

#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
   extern VAR_DATA(struct HashList **) hashTable;
   extern VAR_DATA(uint) hashSize;
#endif


#define JSE_STRING_SWEEP 1
   /* Garbage collector marking this as still used. */
#define JSE_STRING_LOCK 2
   /* This string is locked into memory. This is done in 2 places. First, when
    * the API enters a string, then calls some routines, then removes it, it is
    * locked. This prevents us from having to store the value somewhere that the
    * collector will note. Second, all strings that are in the code (i.e. part of
    * the byte codes) is locked. This is because we don't actually scan the byte
    * codes during collection - they stay the same for the length of the program.
    * It would be just one big waste of time to note over and over again that we
    * shouldn't free these items.
    */

struct HashList
{
   uword8 flags;
   uword8 pad;          /* the returned, embedded string must be even aligned */

   uword16 table_entry; /* back pointer into API table of strings or 0,
                         * table entry 0 never used.
                         */


   /* The 'where it was allocated' info is now removed - we no longer explicitly
    * remove them, so there won't be any messages that they aren't removed.
    */

   struct HashList * next;
   /* The string pointer is implicitly added after the end of the structure */
};

enum stock_table_entries
{
   Global_Initialization_entry = 0,

   Array_entry,
   Boolean_entry,
   Buffer_entry,
   DYN_DEFAULT_entry,
   Date_entry,
   Error_entry,
   Function_entry,
   Number_entry,
   OPERATOR_DEFAULT_BEHAVIOR_entry,
   Object_entry,
   RegExp_entry,
   String_entry,
   __parent___entry,
   _argc_entry,
   _argv_entry,
   _call_entry,
   _canPut_entry,
   _class_entry,
   _construct_entry,
   _defaultValue_entry,
   _delete_entry,
   _get_entry,
   _hasProperty_entry,
   _operator_entry,
   _prototype_entry,
   _put_entry,
   _value_entry,

   arguments_entry,
   callee_entry,
   constructor_entry,
   global_entry,
   length_entry,
   main_entry,
   preferredType_entry,
   prototype_entry,
   this_entry,
   toSource_entry,
   toString_entry,
   valueOf_entry,

   STOCK_TABLE_SIZE
};
extern CONST_DATA(jsecharptr) stock_strings[STOCK_TABLE_SIZE];

/* VarName
 *
 * A VarName is an internalized value that represents a string.
 * The key is that every string is uniquely identified by a
 * VarName. Thus, internally strings can be compared via a direct
 * comparison. VarNames are 4 bytes.
 *
 * The format of a VarName is myriad, to encompass many forms
 * of string efficiently.
 */

/* All formats have lowbyte as specified by the following. The
 * high 3 bytes are the data field for the formats.
 */

#define ST_FORMAT(x) ((uword32)(x)&0xff)
#define ST_DATA(x) ((uword32)(x)>>8)


#define IsNormalStringTableEntry(x) (((uword32)(x)&0x01)==0)
#define NormalStringTableEntryData(x) ((void *)(x))

#define HashListFromVarName(x) \
   (((struct HashList *)(((stringLengthType *)NormalStringTableEntryData(x))-1))-1)
#define VarNameFromHashList(x) \
  ((VarName)(((stringLengthType *)((x)+1))+1))
#define NameFromHashList(hashlist) \
      ((jsecharptr )(((stringLengthType *)((hashlist)+1))+1))
#define LengthFromHashList(hashlist) \
      (*((stringLengthType *)((hashlist)+1)))

#define PositiveStringTableEntry(x) ((VarName)((((uword32)(x))<<8)|ST_NUMBER_POS))
#define NegativeStringTableEntry(x) ((VarName)((((uword32)(-(x)))<<8)|ST_NUMBER_NEG))
#define IsNumericStringTableEntry(x) ((((uword32)(x)&0xff)==ST_NUMBER_POS) || (((uword32)(x)&0xff)==ST_NUMBER_NEG))
#define GetNumericStringTableEntry(x) ((((uword32)(x)&0xff)==ST_NUMBER_POS)?ST_DATA(x):-(sword32)ST_DATA(x))


/* All of the special formats must be odd, i.e. have the low bit set,
 * to differentiate them from the normal string table entry.
 */


/* This is up to 5 alnum characters (lower case, upper case, numbers,
 * _,$) which is 63 possibilities per char. Thus, 6 bits each, so up to 5 chars
 * can be stuffed in 30 bits plus this mask. Note that value 0 = '$'
 * for the 1st 4 characters, but means no character for the 5th, allowing
 * 4 or 5 length strings. This means a 5 length string ending in
 * '$' is not encoded using this format.
 */
#define ST_ALNUM_MASK 0x03

/* A positive number in the valid range. Positive numbers too
 * big are stored as text in the string table.
 */
#define ST_NUMBER_POS 0x05  /* note: this value & 0x03 must not be 0x03 */
#define ST_NUMBER_POS_VALUE(x) ((sword32)(ST_DATA(x)))


/* A negative number in the valid range. Negative numbers too
 * small are stored as text in the string table.
 */
#define ST_NUMBER_NEG 0x09 /* note: this value & 0x03 must not be 0x03 */
#define ST_NUMBER_BEG_VALUE(x) ((sword32)((uword32)ST_DATA(x) | (uword32)0xff000000))


/* A 0-3 byte ascii string. The unused bytes are filled
 * with '\0'. The high byte is the string's first byte,
 * the second byte is the next highest, and unused bytes
 * as I said are replaced with '\0'
 */
#define ST_SHORT_ASCII 0x0d /* note: this value & 0x03 must not be 0x03 */


/* An entry in the binary-sorted stock string table. The data
 * is just the index into the table. The data is not copied.
 */
#define ST_STOCK_ENTRY 0x11 /* note: this value & 0x03 must not be 0x03 */

/* Similar, but user string table */
#define ST_USER_ENTRY 0x15 /* note: this value & 0x03 must not be 0x03 */

/* This will turn something like 'STOCK_ENTRY(_argv)' into
 * the correct ST_STOCK_ENTRY by using the '_entry' enumeration
 * that maps the string entries in the table to their
 * corresponding number.
 */
#define STOCK_STRING(text) ((VarName)(((text##_entry)<<8)|ST_STOCK_ENTRY))


#if (0!=JSE_COMPILER)

union tokData
{
   MemCountUInt const_index;/* only for Type() == Variable,
                             * into call->Global->CompileStatus.current_func's
                             * constant table.
                             */
   uint lineNumber;          /* only for Type() == SourceFileLineNumber        */
   VarName name;            /* Type is not determined                         */
};

struct tok
{
   union tokData Data;
   setokval type;
};

struct CompileStatus_
{
   uint NowCompiling;
   const jsecharptr CompilingFileName;
   /* while compiling, keep track of current file name for debugging */
   uint CompilingLineNumber;  /* while compiling remember line number */

   struct Source *src;
   jsecharptr srcptr;
   jsebool c_function;

   struct tok look_ahead;
   jsebool look_used;

   jsebool new_source;
   /* can only give out one token at a time, if we need to give a
    * second (i.e. filename/linenumber), do so.
    */
};
#endif


struct api_string
{
   VarName name;
   uint count;          /* reference count for API */
};

#if JSE_MEMEXT_STRINGS==1
  struct stringTrack;
#endif

struct Global_
{
   /* parameters that cannot change as context depth changes;
    * created only at top level
    */

   /* IMPORTANT - this must always be the first entry of this structure! */
#if defined(JSE_LINK) && (0!=JSE_LINK)
   struct jseFuncTable_t *jseFuncTable;
#endif

   uword16 collect_disable;

#  if JSE_DONT_POOL==0

#     ifndef SE_OBJ_POOL_SIZE
#        if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
#           define SE_OBJ_POOL_SIZE 128
#        else
#           define SE_OBJ_POOL_SIZE 1024
#        endif
#     endif
#     ifndef SE_MEM_POOL_SIZE
#        define SE_MEM_POOL_SIZE SE_OBJ_POOL_SIZE
#     endif

      hSEObject hobj_pool[SE_OBJ_POOL_SIZE];
                                   /* the pool of reusable objects */
      uint objPoolCount;           /* items in pool */
#ifdef MEM_TRACKING
      word all_objs_count;
      word all_objs_maxCount;
      dword all_objs_size;
      dword all_objs_maxSize;
#endif

      hSEMembers mem_pool[SE_MEM_POOL_SIZE];
                                   /* the pool of reusable objects */
      uint memPoolCount;           /* items in pool */
#ifdef MEM_TRACKING
      word all_mem_count;
      word all_mem_maxCount;
      dword all_mem_size;
      dword all_mem_maxSize;
#endif
#  endif

   hSEObject all_hobjs;           /* all objects currently allocated */
#  if JSE_PER_OBJECT_CACHE==0
      /* cache most-recently used object and index */
      struct {
         hSEObject hobj;
         MemCountUInt index;
      } recentObjectCache;
#  endif

#  if !defined(JSE_GROWABLE_STACK) || (0==JSE_GROWABLE_STACK)
#     if !defined(SE_STACK_SIZE)
#        if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
#           define SE_STACK_SIZE 512
#        else
#           define SE_STACK_SIZE 2048
#        endif
#     endif
      struct _SEVar stack[SE_STACK_SIZE];

#  else
      struct _SEVar *growingStack;
      uint length;
#  endif

#  if JSE_DONT_POOL==0
#     define ARGV_CALL_POOL_COUNT 20 /* num arguments in each */
#     define ARGV_CALL_POOL_SIZE 3   /* probably is good enough at 1, barring recursion */
      seAPIVar *argvCallPool[ARGV_CALL_POOL_SIZE];
      uint argvCallPoolCount;
#  endif

   hSEObject *hDestructors;   /* realloced list of VarObjs with destructors needed
                               * to be called.
                               */
   uint destructorCount;
   uint destructorAlloced;
   jsebool final;

#     ifndef JSE_STRINGS_COLLECT
#        if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
#           define JSE_STRINGS_COLLECT 100000
#        else
#           define JSE_STRINGS_COLLECT 1000000
#        endif
#     endif
      uword32 stringallocs;
   seString stringdatas;        /* all strings currently allocated */

   struct Function *funcs;      /* all functions currently allocated */

#ifdef MEM_TRACKING
   word func_alloc_count;
   dword func_alloc_size;
#endif

#  if JSE_NEVER_FREE==1
      void **blocks_to_free;
      uint num_blocks_to_free,max_blocks_to_free;
#  endif

#  if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
      struct HashList ** hashTable;
      uint hashSize;
#ifdef MEM_TRACKING
      dword hashAllocSize;
      dword maxHashAllocSize;
#endif
#  endif

   /* prelocked */
   VarName userglobal;

   struct api_string *api_strings;
   uword16 api_strings_used,api_last_unused;

#  if (0!=JSE_COMPILER)
      struct CompileStatus_ CompileStatus;
#  endif

   int number;
#  if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
      jsecharptr *FileNameList;
#  endif

   void _FAR_ * GenericData;
      /* this data may be specific to each implementation */
   struct jseExternalLinkParameters ExternalLinkParms;

   jsechar tempNumToStringStorage[12];
      /* when numbers are converted to strings they are converted here
       * and this data is returned.  Note that this means there is
       * one number used at a time per context thread.  This is big
       * enough for longest number, which is -2147483648.
       */

   struct sharedDataNode * sharedDataList;

#  if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
      (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
      uword16 ExternalDataSegment;
#  endif

   /* This flag is needed because if we are within an ErrorVPrintf, and we encounter
    * another error, then we don't want it printed, because most likely  the error
    * happened while within ErrorVPrintf (such as a prototype loop), and it will
    * create an infinite loop and a stack overflow.
    */
   jsebool inErrorVPrintf;

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      /* a record of all security so we can delete them on exit */
      struct Security *allSecurity;
#  endif


   /* This is where we store the API-returned Variables, the
    * ones that the user has to explicitly delete. Can be
    * relatively small, it only needs to be the amount that
    * a wrapper function uses then frees. Most wrapper functions
    * only deal with a few, say 6 or under. 16 should be overkill.
    */
   seAPIVar APIVars;
#  if JSE_DONT_POOL==0
#     define API_VAR_POOL_SIZE 16
      seAPIVar api_pool[API_VAR_POOL_SIZE];
      MemCountUInt api_pool_count;
#  endif

   struct dynacallRecurse *dynacallRecurseList;
   uint dynacallDepth;  /* prevent extreme depth-without-end on dynamic calling */
      /* linked list of all dynamic calls currently being executed */

#  if defined(JSE_LINK) && (0!=JSE_LINK)
      /* These are all the freed extlibs. We don't actually release
       * them until we are about to exit, because they may still have
       * memory and routines we need to call, like if you return
       * a wrapper function defined in them, or if they set shared data.
       */
      struct ExtensionLibrary savedLibs;
#  endif

#  if JSE_MEMEXT_STRINGS==1
      struct stringTrack *tracks;
#  endif
};

/* ---------------------------------------------------------------------- */

struct TryBlock
{
   struct TryBlock *prev;

   ADDR_TYPE begin,end;      /* block location so transfers outside it trigger */
   ADDR_TYPE catch;          /* catch location, (ADDR_TYPE)-1 = none. */
   ADDR_TYPE fin;            /* finally location */

   uword8 state;        /* saved when entering finally */
   ADDR_TYPE loc;       /* when enterring finally, save where we were - -1
                         * means haven't entered finally yet */
   jsebool incatch;     /* to know if we need to discard a scope chain entry */
   jsebool endtryreached;

   STACKPTR fptr;       /* the state we were in when this was created
                         * so we can return to it. Basically, we do
                         * 'callReturnFromFunction' until the fptr saved
                         * is FPTR, then goto the try handler.
                         */
   STACKPTR sptr;
};


/* The Call structure */

/* The Call structure now just tracks 1/interpret!
 */

struct Call
{
   /* IMPORTANT: The 'jseFuncTable' entry MUST be FIRST!!! The external
    *            libraries rely on this! Do NOT put anything else first.
    *            It is the first member of Global!!
    */
   struct Global_ *Global;      /* Information that is the same for one jseContext
                                 * regardless of subsequent calls and such.
                                 */

#  if ( 2 <= JSE_API_ASSERTLEVEL )
      ubyte cookie;             /* This value is set on all calls to verify
                                 * that a pointer passed to the API is indeed
                                 * a call.
                                 */
#  endif


   struct Call *next,*prev;     /* Call chain */

   /* all objects by default (if not HAS_PROTOTYPE) will get the prototype
    * from either Object.prototype or Function.prototype.  These will already
    * be initialized. Of course, the garbage collector will have to note
    * that these are locked. They are 'per-interpret'.
    */
   hSEObject hObjectPrototype;
   hSEObject hArrayPrototype;
   hSEObject hFunctionPrototype;
   hSEObject hStringPrototype;

   /* Value returned via dynamic properties indicating
    * 'do the regular thing', including callback
    * properties
    */
   hSEObject hDynamicDefault;


   uword8 CallSettings;
#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   struct Security *currentSecurity;
#  endif
#  if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
      struct Define *Definitions;
#  endif
   struct Library *TheLibrary;
   struct AtExit *AtExitFunctions;
#  if defined(JSE_LINK) && (0!=JSE_LINK)
      struct ExtensionLibrary *ExtensionLib;
#  endif

   /* If 0, never continue. If 1, always continue, else it is
    * counting down to next continue.
    */
   uword32 continue_count;


   struct _SEVar old_main,old_init;
   struct _SEVar old_argc,old_argv;


   hSEObject hGlobalObject;     /* the current global for this interpret.
                                 * If JSE_MULTIPLE_GLOBAL, probably want to
                                 * use the function's stored global instead.
                                 * Thus, always use CALL_GLOBAL.
                                 */
#  if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
      /* Globals are always cached for the main global for each
       * interpret. Note that you want to turn off caching if
       * you are going to be using a dynamic global object
       */
#     ifndef JSE_CACHE_SIZE
#        define JSE_CACHE_SIZE 10
#     endif

      struct call_cache {
         VarName entry;
         MemCountUInt slot;
      } cache[JSE_CACHE_SIZE];

      /* There are a number of times when we don't want to use the
       * cache for a particular function. Basically, if the function
       * has a different global, or if it has any items in the scope
       * chain other than the global, we cannot use the cache.
       */
      jsebool useCache;
#  endif


   STACKPTR frameptr;
   uword16 num_args,true_args;

   STACKPTR stackptr;           /* current location on the stack */


   seAPIVar tempvars;           /* A doubly-linked list */

#  if JSE_MEMEXT_SECODES==1
      secode base;              /* the value we get when locking */
#  endif
   /* Some information stored for actually interpretting code. These obviously
    * only apply to local functions.
    */
   secode iptr;                 /* instruction pointer */


   struct TryBlock *tries;      /* try blocks currently in operator */


   struct Function *funcptr;
   hSEMembers hConstants;

   /* An unsorted variable object to be used as a ScopeChain. We
    * need to be able to garbage collect these things, and add
    * them to a list. It makes more sense to reuse object descriptors,
    * than to build a whole new data type, collect it, and so
    * forth. Later, this can be changed if it really is necessary.
    *
    * Each new function has its scope chain stored in this object,
    * delimited by a VNull entry. The VariableObject is stored
    * here, initially being VUndefined.
    */
   hSEObject hScopeChain;
   struct _SEVar new_scope_chain;

   jsebool pastGlobals;         /* only for interpret level, inherit past
                                 * globals?
                                 */
   hSEObject hVariableObject;

   uword8 state;                /* FlowError, FlowExit, FlowNoReasonToQuit */

   /* For errors, we keep the error variable in a separate place. The
    * reason is that keeping it on the stack top is problematic. There
    * are too many places in the code that assumes (as was true for past
    * versions), that the error is stored away in the call. They for
    * instance do their normal STACK_POP cleanups even in an error
    * situation. Of course, the item on the stack is no longer the
    * temp they made, but the error on top of it, so problems show up.
    * Rather than try to catch every place and have a slew of
    * 'if( CALL_QUIT(call) ) break;' everywhere, we use the old
    * style behavior.
    */
   struct _SEVar error_var;

   jsebool mustPrintError;
   jsebool errorPrinted;
};

/* ---------------------------------------------------------------------- */

/* anal debug stuff */
#if JSE_MUST_FREE==1
void NEAR_CALL callAddFreeItem(struct Call *call,void *mem);
#endif

/* string table stuff */

/* Creates and locks into memory a string table entry. It will be freed
 * when exiting. Use this for entries in the program text, and the 'stock'
 * entries like '_get', 'main' and such that we need access to for as
 * long as the program runs.
 */
   VarName
LockedStringTableEntry(struct Call *call,const jsecharptr name,
                       stringLengthType length);


/* This is the version the API (and structure members with a string value
 * for a name) will use. This is for the 'get a lock' on a string table entry,
 * use it, then free it. Internally, once you release it, it will not
 * be freed immediately - it may be still locked in place by references and
 * if an object member uses it as a name. The garbage collector will get rid
 * of it when the engine is not using it anymore. The 'temp' is just a storage
 * space the locking mechanism needs (it saves each string table entry from
 * needing an extra 'count' field.)
 */
VarName GrabStringTableEntry(struct Call *call,const jsecharptr name,
                                      stringLengthType length,uword8 *temp);
VarName GrabStringTableEntryStrlen(struct Call *call,const jsecharptr name,
                                            uword8 *temp);
void ReleaseStringTableEntry(/*struct Call *call,*/VarName entry,uword8 temp);

/* This one physically removes the entry, ignoring locking - it is called
 * by the collector when an entry can be freed, and always at program exit.
 */
void RemoveStringTableEntry(struct Call *call,struct HashList *it);

   const jsecharptr
GetStringTableEntry(struct Call *call,VarName entry,stringLengthType *length);
   /* pass length as NULL to ignore */


/* Adds the string to the api string table with a count of 1, or
 * increments the count if already there. Returns the api string
 * table entry.
 */
   jseString
callApiStringEntry(struct Call *call,VarName result);


/* decrements the count in the API string table and removes
 * the api string table entry if goes to 0.
 */
void callRemoveApiStringEntry(struct Call *call,struct api_string *s);


#if defined(JSE_ONE_STRING_TABLE) && (0!=JSE_ONE_STRING_TABLE)
   jsebool allocateGlobalStringTable();
   void freeGlobalStringTable();
#endif

/* ---------------------------------------------------------------------- */

/* information routines */

#if 0 != JSE_MULTIPLE_GLOBAL
#  define CALL_GLOBAL(c) (hSEObject)( ((c)->funcptr!=NULL && (c)->funcptr->hglobal_object!=hSEObjectNull) \
                         ? (c)->funcptr->hglobal_object : (c)->hGlobalObject )
#else
#  define CALL_GLOBAL(c) ((c)->hGlobalObject)
#endif

#if 0 != JSE_MULTIPLE_GLOBAL
#  define CALL_SET_GLOBAL(c,g) \
             if ( (c)->funcptr && (c)->funcptr->hglobal_object ) (c)->funcptr->hglobal_object=(g); \
             else (c)->hGlobalObject = (g)
#else
#  define CALL_SET_GLOBAL(c,g) ((c)->hGlobalObject = (g))
#endif

#define CALL_ERROR(call) ((call)->state==FlowError)
#define CALL_QUIT(call) ((call)->state!=FlowNoReasonToQuit)
#define CALL_SET_ERROR(call,err) ((call)->state = (err))


   const jsecharptr
callCurrentName(struct Call *call);

#if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
#  define CALL_GET_FILENAME_LIST(this,number) \
          (*(number) = (this)->Global->number,(this)->Global->FileNameList)
#endif

   void NEAR_CALL
callGetVarNeed(struct Call *this,rSEVar pVar,wSEVar dest,uint InputVarOffset,
               jseVarNeeded need);

   jsebool NEAR_CALL
callFindAnyVariable(struct Call *this,VarName name,jsebool full_look,jsebool create_ref);

   void NEAR_CALL
callCreateVariableObject(struct Call *call,struct Function *lookfunc);

   void NEAR_CALL
callFunction(struct Call *call,uword16 num_args,jsebool constructor);
   void NEAR_CALL
callFunctionFully(struct Call *call,uword16 num_args,jsebool constructor);
   void NEAR_CALL
callReturnFromFunction(struct Call *call);


#define CALL_ADD_SCOPE_OBJECT(call,wScopeChain,rvar) \
   seobjCreateMemberCopy(NULL,(call),(wScopeChain),NULL,(rvar))

#if 0==JSE_MEMEXT_OBJECTS
#  define CALL_REMOVE_SCOPE_OBJECT(call) ((call)->hScopeChain->used--)
#else
   void NEAR_CALL CALL_REMOVE_SCOPE_OBJECT(struct Call *call);
#endif

   jsebool
callBreakpointTest(struct Call *call,hSEObject hParentObject,
               const jsecharptr WantedName,
               uword32 LineNumber,uint depth);

/* error routines */

   void JSE_CFUNC
callQuit(struct Call * call,enum textcoreID id,...);
   void JSE_CFUNC
callError(struct Call * call,enum textcoreID id,...);
   void
callPrintError(struct Call *call);  /* Must be an error object */

   struct Call * NEAR_CALL
interpretInit(struct Call * call,const jsecharptr OriginalSourceFile,
              const jsecharptr OriginalSourceText,
              const void *PreTokenizedSource,
              jseNewContextSettings NewContextSettings,
              int HowToInterpret);
   struct Call * NEAR_CALL
interpretTerm(struct Call *call);


   struct Call * NEAR_CALL
callInitial(void _FAR_ *LinkData,
            struct jseExternalLinkParameters *ExternalLinkParms,
            const jsecharptr globalVariableName,
            stringLengthType GlobalVariableNameLength);

   struct Call * NEAR_CALL
callInterpret(struct Call *this,jseNewContextSettings settings,jsebool see_old,
              jsebool traperrors);
   void NEAR_CALL
callDelete(struct Call *call);

   jsebool NEAR_CALL
callErrorTrapped(struct Call *call);

/* initialization */

   hSEObject
InitGlobalPrototype(struct Call *call,VarName name);
   void
callNewGlobalVariable(struct Call *call);
   jsebool
callNewSettings(struct Call *this,uword8 NewContextSettings);
   void
callCleanupGlobal(struct Call *this);
   void
InitializeBuiltinVariables(struct Call *call);


/* I don't like big inlines like this, but it is only called in
 * a few places, and not having to call a function makes a 10%
 * difference in wrapper function looping tests.
 */
#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
#  define CALL_FREE_APIVAR_DEBUG(call,apivar)                           \
         jseMustFree(s->function);                                      \
         jseMustFree(s->file)
#else
#  define CALL_FREE_APIVAR_DEBUG(call,apivar)  /* nothing */
#endif
#if JSE_MEMEXT_STRINGS==0
#  define CALL_FREE_APIVAR_STRINGDATA(call,apivar)   /* nothing */
#else
#  define CALL_FREE_APIVAR_STRINGDATA(call,apivar) \
      if( (apivar)->data ) SEVAR_FREE_DATA((call),(apivar)->data);
#endif
#if JSE_DONT_POOL==0
#  define CALL_FREE_APIVAR(call,apivar)                                       \
         CALL_FREE_APIVAR_DEBUG(call,apivar);                                 \
         if( call->Global->api_pool_count<API_VAR_POOL_SIZE )                 \
            call->Global->api_pool[call->Global->api_pool_count++] = apivar;  \
         else                                                                 \
            jseMustFree(apivar)
#else
#  define CALL_FREE_APIVAR(call,apivar)                                       \
            CALL_FREE_APIVAR_DEBUG(call,apivar);                              \
            jseMustFree(apivar)
#endif
#define CALL_KILL_TEMPVARS_GUTS(call,mark)                           \
   while( call->tempvars!=mark )                                     \
   {                                                                 \
      seAPIVar s = call->tempvars;                                   \
                                                                     \
      assert( call->tempvars->prev==NULL );                          \
      if( s->next ) s->next->prev = NULL;                            \
      call->tempvars = s->next;                                      \
      CALL_FREE_APIVAR_STRINGDATA(call,s)                            \
      CALL_FREE_APIVAR(call,s);                                      \
   }


#if !defined(JSE_INLINES) || (1==JSE_INLINES)
#  define CALL_KILL_TEMPVARS(c,m) CALL_KILL_TEMPVARS_GUTS(c,m)
#else
   void CALL_KILL_TEMPVARS(struct Call *call,seAPIVar mark);
#endif

#if defined(__cplusplus)
   }
#endif

#endif
