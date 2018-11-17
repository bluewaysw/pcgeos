/* jsemem.c    Random utilities used by ScriptEase.
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

#include "jseopt.h"
#include "jsetypes.h"
#include "jselib.h"
#include "seuni.h"
#ifdef __JSE_UNIX__
#include "unixfunc.h"
#endif

#if defined(__JSE_GEOS__)
#  include <Ansi/assert.h>
#  include <Ansi/stdlib.h>
#  include <Ansi/string.h>
#elif !defined(__JSE_MAC__) && !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#  include <assert.h>
#endif

#ifdef __cplusplus
#include <new.h>
#endif

#if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#   include <windows.h>
#endif
#if !defined(__CGI__) && !defined(__JSE_WIN16__) && !defined(__JSE_WIN32__) && !defined(__JSE_GEOS__)
#   include <stdio.h>
#endif
#if !defined(__JSE_GEOS__)
#include "dbgprntf.h"
#endif
#include "jsemem.h"


#if defined(JSE_MEM_SUMMARY) && defined(NDEBUG)
#define DebugPrintf printf
#endif

#if defined __JSE_MAC__

static struct MacTextBox *
SetupTextBox()
{
   struct MacTextBox * textbox = NewMacTextBox();
   assert( MacTextBoxIsValid( textbox ) );
   MacTextBoxSet(textbox, "0003: Insufficient Memory to continue operation.");
   return textbox;
}

#   include <sound.h>
   struct MacTextBox * error_box = NULL;
#endif

/* TOOLKIT USER: ASSUMED MEMORY SUCCESS: non-large memory allocations are
 * assumed to success, so they go through these "must" malloc and new
 * functions.  For different error reporting on failed mallocs (which would
 * only fail in extreme script cases on modern operating systems) replace
 * these functions with your own memory failure error reporting.  If you
 * already have set_new_handler then remove this one we added. */

void jseInsufficientMemory(void)
{
#if !defined(__CGI__) && (0!=JSE_FLOATING_POINT)
#if !defined(__JSE_GEOS__)
   static CONST_STRING(NoMemMessage,"0003: Insufficient Memory to continue operation.");
#endif
#  if (defined(__JSE_WIN16__) || defined(__JSE_WIN32__)) && !defined(__JSE_WINCE__)
      MessageBox((HWND)0,NoMemMessage,NULL,MB_TASKMODAL|MB_ICONHAND|MB_OK);
#  else
#     if defined(__JSE_MAC__)
         assert( error_box != NULL );
         SysBeep(10);
         MacTextBoxShow( error_box, NULL );
#     elif defined(__JSE_PSX__)
         printf(UNISTR("\a\a%s\n"),NoMemMessage);
#     elif defined(__JSE_WINCE__)
         MessageBox((HWND)0,NoMemMessage,NULL,MB_APPLMODAL|MB_ICONHAND|MB_OK);
#     elif defined(__JSE_GEOS__)
		 /* Need a dialog here -- brianc 8/21/00 */
	 SysNotify(SNF_EXIT|SNF_REBOOT, "Out of memory.", NULL);
#     else
         fprintf_jsechar(stderr,UNISTR("\a\a%s\n"),NoMemMessage);
#     endif
#  endif
#endif
   assert(False);               /* to ease debugging */
#  if defined(_WINDLL)
#     error for building in a _WINDLL you must provide an alternative\
   to exit() for fatal abort
#  else
      exit(EXIT_FAILURE);
#  endif
}

#ifdef HUGE_MEMORY
void _HUGE_ *jseMustHugeMalloc(ulong size)
{
   void _HUGE_ *ret;
   assert( 0 < size );
   if ( NULL == (ret = HugeMalloc(size)) )
      jseInsufficientMemory();
   return ret;
}
#endif

#if !defined(JSE_MEM_DEBUG) || (0==JSE_MEM_DEBUG)

void *jseUtilMustMalloc(uint size)
{
   void *ret;
#   ifdef __JSE_MAC__
      /* This is a very bad place to initalize this, but there is no function
       * outside of the core that is guaranteed to be called upon
       * initialization.  This is the best alternative I could think of.
       */
      if ( error_box == NULL )
      {
         error_box = (struct MacTextBox *) 1;
         /* Otherwise we go into an infinite loop */
         error_box = SetupTextBox();
      }
#   endif
   assert( 0 < size );
#ifdef GEOS_MAPPED_MALLOC
   if ( NULL == (ret = jseMappedMalloc(size)) )
#else
   if ( NULL == (ret = malloc(size)) )
#endif
      jseInsufficientMemory();
   return(ret);
}

#if 0
old void *jseUtilMustCalloc(uint num,uint size)
old {
old    void *ret;
old #   ifdef __JSE_MAC__
old       /* This is a very bad place to initalize this, but there is no function
old        * outside of the core that is guaranteed to be called upon
old        * initialization.  This is the best alternative I could think of.
old        */
old       if ( error_box == NULL )
old       {
old          error_box = (struct MacTextBox *) 1;
old          /* Otherwise we go into an infinite loop */
old          error_box = SetupTextBox();
old       }
old #   endif
old    assert( 0 < size );
old    assert( 0 < num );
old #  if defined(__JSE_WINCE__)
old    ret = (void*)LocalAlloc(LMEM_ZEROINIT,size);
old #  else
old    ret = calloc(num,size);
old #  endif
old    if ( NULL == ret )
old       jseInsufficientMemory();
old    return(ret);
old }
#endif

void *jseUtilMustReMalloc(void *PrevMalloc,uint size)
{
   void *ret;
   assert( 0 < size );

/* You should not remalloc NULL */

#ifdef GEOS_MAPPED_MALLOC
   if ( NULL == (ret = (PrevMalloc)?jseMappedRealloc(PrevMalloc,size):jseMappedMalloc(size)) )
#else
#if defined(__JSE_PALMOS__)
   if ( PrevMalloc ) {
       ret = PrevMalloc;
       if ( 0 != MemPtrResize(PrevMalloc,(size_t)size) )
       {
           size_t oldSize = MemPtrSize(PrevMalloc);
           size_t copySize;
           if ( oldSize > size )
               copySize = size;
           else
               copySize = oldSize;
           ret = malloc(size);
           if ( ret == NULL ) {
               jseInsufficientMemory();
               return NULL;
           }
           MemMove(ret, PrevMalloc, copySize);
           free( PrevMalloc );
       }
   } else {
       /* Will assert error within if fails. */
       ret = malloc(size);
       if ( ret == NULL )
           jseInsufficientMemory();
   }
#else

   if ( NULL == (ret = (PrevMalloc)?realloc(PrevMalloc,size):malloc(size)) )
#endif
      jseInsufficientMemory();
#endif
   return(ret);
}

#else /* !defined(JSE_MEM_DEBUG) || (0==JSE_MEM_DEBUG) */

/* anal versions of allocation routines */

   /* ok variable; in thread lock and only for debugging */
static VAR_DATA(ulong) jseDbgAllocationCount = 0;
static VAR_DATA(jsebool) jseDbgInMemDebug = False;
static VAR_DATA(jsebool) jseDbgMemVerbosity = False;
static VAR_DATA(ulong) jseDbgAllocSequenceCounter = 0;
 /* used when debugging to catch a special value */
static VAR_DATA(ulong) DebugWatch = (ulong)(-1);
static VAR_DATA(uint) SizeWatch = (uint)(-1);
VAR_DATA(ulong) TotalMemoryAllocated = 0;
VAR_DATA(ulong) TotalMemoryAllocations = 0;
VAR_DATA(ulong) MaxTotalMemoryAllocated = 0;
VAR_DATA(ulong) MaxTotalMemoryAllocations = 0;


static void NEAR_CALL DebugWatcher(ulong sequence, uint size)
{
   if ( sequence == DebugWatch )
      DebugPrintf(UNISTR("Hit the DebugWatch value %lu.\n"),DebugWatch);
   if(size == SizeWatch)
      DebugPrintf(UNISTR("Hit the SizeWatch value %u.\n"),SizeWatch);

}

static jsecharptr NEAR_CALL jsemem_a_to_u(const char *asc_string)
{
   /* return this string convert to unicode in-place */
   static VAR_DATA(jsechar) uni_string[800];
   size_t i;
   jsecharptr tmp1;

   tmp1 = (jsecharptr)uni_string;
   for ( i = 0; i < (sizeof(uni_string)/sizeof(jsechar)) - 4;
         i++,JSECHARPTR_INC(tmp1) )
   {
      JSECHARPTR_PUTC(tmp1,(jsechar)(asc_string[i]));
      if ( asc_string[i]=='\0' ) break;
   }
   JSECHARPTR_PUTC(tmp1,'\0');
   return (jsecharptr)uni_string;
}

struct AnalMalloc {
   struct AnalMalloc *Prev;
   uint size; /* this does not include the four bytes at the beginning
                 and end */
   ulong AllocSequenceCounter;
   ulong line;           /*__LINE__*/
   const char * file; /*__FILE__*/
   ubyte Head[4];
   ubyte data[1];
};
VAR_DATA(struct AnalMalloc *) RecentMalloc = NULL;
   /* ok variable; in thread lock and only for debugging */
#if !defined(JSE_PREEMPTIVE_THREADS) || (0==JSE_PREEMPTIVE_THREADS)
#   define ExclusiveMallocThreadStart();  /* */
#   define ExclusiveMallocThreadStop();   /* */
#   define ExclusiveMallocThreadInit();  /* */
#   define ExclusiveMallocThreadTerm();   /* */
#else
#  if defined(__JSE_WIN32__) || defined(__JSE_CON32__)
      static VAR_DATA(CRITICAL_SECTION) CriticalMallocSectionSemaphore;
#     define ExclusiveMallocThreadStart() \
         EnterCriticalSection(&CriticalMallocSectionSemaphore)
#     define ExclusiveMallocThreadStop()  \
         LeaveCriticalSection(&CriticalMallocSectionSemaphore)
#     define ExclusiveMallocThreadInit()  \
         InitializeCriticalSection(&CriticalMallocSectionSemaphore)
#     define ExclusiveMallocThreadTerm()  \
         DeleteCriticalSection(&CriticalMallocSectionSemaphore)
#  elif defined(__JSE_UNIX__)
      static VAR_DATA(pthread_mutex_t) CriticalMallocMutex;
#     define ExclusiveMallocThreadStart() \
         pthread_mutex_lock(&CriticalMallocMutex)
#     define ExclusiveMallocThreadStop()  \
         pthread_mutex_unlock(&CriticalMallocMutex)
#     define ExclusiveMallocThreadInit()  \
         pthread_mutex_init(&CriticalMallocMutex,NULL)
#     define ExclusiveMallocThreadTerm()  \
         pthread_mutex_destroy(&CriticalMallocMutex)
#  elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#     define ExclusiveMallocThreadStart() DosEnterCritSec()
#     define ExclusiveMallocThreadStop()  DosExitCritSec()
#     define ExclusiveMallocThreadInit();  /* */
#     define ExclusiveMallocThreadTerm();   /* */
#  elif defined(__JSE_NWNLM__)
      static VAR_DATA(MPKMutex) CriticalMallocMutex;
      static CONST_STRING(CriticalMallocMutexName,"JseMemCriticalMallocMutex");
#     define ExclusiveMallocThreadStart() \
         MPKMutexLock( CriticalMallocMutex )
#     define ExclusiveMallocThreadStop()  \
         MPKMutexUnlock( CriticalMallocMutex )
#     define ExclusiveMallocThreadInit()  \
         CriticalMallocMutex = MPKMutexAlloc( CriticalMallocMutexName )
#     define ExclusiveMallocThreadTerm()  \
         MPKMutexFree( CriticalMallocMutex )
#  else
#     error thread-locking critical section must be defined for this OS
#  endif
#endif

   void
jseInitializeMallocDebugging()
{
   ExclusiveMallocThreadInit();
   TotalMemoryAllocated = 0;
   TotalMemoryAllocations = 0;
   MaxTotalMemoryAllocated = 0;
   MaxTotalMemoryAllocations = 0;
}

   void
jseTerminateMallocDebugging()
{
#if defined(__JSE_MAC__)
  if ( error_box != NULL )
     DeleteMacTextBox(error_box);
  error_box = NULL;
#endif

   if ( 0 != jseMemReport(False) ) {
      jseMemDisplay();
      DebugPrintf(UNISTR("9002: Leaving, but there are %ld allocations.\n"),
                  jseMemReport(False));
      assert(False);
      exit(EXIT_FAILURE);
   }

   /* A useful debug output - it can tell you almost immediately if you have
    * an internal memory leak situation.
    */
#if 0
   DebugPrintf(UNISTR("\nMaximum memory allocated = %lu\n\n"),MaxTotalMemoryAllocated);
#endif
   assert( 0 == TotalMemoryAllocated );
   assert( 0 == TotalMemoryAllocations );
   ExclusiveMallocThreadTerm();
}

static CONST_DATA(ubyte) AnalMallocHead[] = {'H','e','a','d'};
   /* size of 4 is hardcoded below */
static CONST_DATA(ubyte) AnalMallocFoot[] = {'F','o','o','t'};
   /* size of 4 is hardcoded below */

   void
jseMemDisplay()
{
   ExclusiveMallocThreadStart();
   {
      struct AnalMalloc *AM;
      for ( AM = RecentMalloc; NULL != AM; AM = AM->Prev ) {
         DebugPrintf(
UNISTR("Memory Block: Sequence = %lu, size = %u, ptr = %08lX line=%lu of file=%s\n\n"),
   AM->AllocSequenceCounter,AM->size,AM->data,AM->line,jsemem_a_to_u(AM->file));
      }
   }
   ExclusiveMallocThreadStop();
}


   void *
jseUtilMalloc(uint size, ulong line, const char* file)
{
   struct AnalMalloc *AM;
   assert( 0 < size );
#  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
#     undef malloc
#  endif
   AM = (struct AnalMalloc *)
        malloc(sizeof(*AM) - sizeof(AM->data) + size + 4);
#  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
#     define malloc(S)       use jseMustMalloc
#  endif
   if ( NULL == AM ) {
      return NULL;
   } /* endif */
   AM->line = line;
   AM->file = file;

   memcpy(AM->Head,AnalMallocHead,4);
   memcpy(&(AM->data[size]),AnalMallocFoot,4);
   AM->size = size;
   ExclusiveMallocThreadStart();
   {
      AM->Prev = RecentMalloc;
      RecentMalloc = AM;
      jseDbgAllocationCount++;
      AM->AllocSequenceCounter = jseDbgAllocSequenceCounter++;
      DebugWatcher(AM->AllocSequenceCounter, size);
      TotalMemoryAllocated += size;
      TotalMemoryAllocations++;
      if ( MaxTotalMemoryAllocated < TotalMemoryAllocated )
         MaxTotalMemoryAllocated = TotalMemoryAllocated;
      if ( MaxTotalMemoryAllocations < TotalMemoryAllocations )
         MaxTotalMemoryAllocations = TotalMemoryAllocations;
   }
   ExclusiveMallocThreadStop();

   if ( jseDbgMemVerbosity ) {
      DebugPrintf(UNISTR("Allocation# %lu allocated %u bytes at %08lX\n\n"),
                  AM->AllocSequenceCounter,size,AM->data);
   } /* endif */



   memset(AM->data,0xEE,size);   /* fill with non-null characters */
   return(AM->data);
}

#if 0
old static void *
old jseUtilCalloc(uint num,uint size, ulong line, const char* file)
old {
old    struct AnalMalloc *AM;
old    assert( 0 < size );
old #  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
old #     undef malloc
old #  endif
old    /* WARNING: This line is making several assumptions. First, it assumes
old     * you want't be allocating > 32 bits worth of data. Second, it is
old     * aligning to 8 bytes. Perhaps some wacko systems in the future will
old     * align more? This is all necessary because we are adding extra stuff
old     * and it can't be said with any certainty how calloc will align its
old     * memory on the particular system, so hopefully this will allocate
old     * enough.
old     */
old    /* size = (size + 7) & 0xfffffff8L; */
old    size = (size + 7) & ~7;
old    size *= num;
old    AM = (struct AnalMalloc *)
old         malloc(sizeof(*AM) - sizeof(AM->data) + size + 4);
old #  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
old #     define malloc(S)       use jseMustMalloc
old #  endif
old    if ( NULL == AM ) {
old       return NULL;
old    } /* endif */
old    AM->line = line;
old    AM->file = file;
old
old    memcpy(AM->Head,AnalMallocHead,4);
old    memcpy(&(AM->data[size]),AnalMallocFoot,4);
old    AM->size = size;
old    ExclusiveMallocThreadStart();
old    {
old       AM->Prev = RecentMalloc;
old       RecentMalloc = AM;
old       jseDbgAllocationCount++;
old       AM->AllocSequenceCounter = jseDbgAllocSequenceCounter++;
old       DebugWatcher(AM->AllocSequenceCounter, size);
old       TotalMemoryAllocated += size;
old       if ( MaxTotalMemoryAllocated < TotalMemoryAllocated )
old          MaxTotalMemoryAllocated = TotalMemoryAllocated;
old    }
old    ExclusiveMallocThreadStop();
old
old    if ( jseDbgMemVerbosity ) {
old       DebugPrintf(UNISTR("Allocation# %lu allocated %u (calloced) bytes at %08lX\n\n"),
old                   AM->AllocSequenceCounter,size,AM->data);
old    } /* endif */
old
old    memset(AM->data,0xEE,size);   /* fill with non-null characters */
old    return(AM->data);
old }
#endif

   void *
jseUtilMustMalloc(uint size, ulong line, const char* file)
{
   void *ptr;
#   ifdef __JSE_MAC__
      if ( error_box == NULL )
      {
         error_box = (struct MacTextBox *) 1;
            /* Otherwise we go into an infinite loop */
         error_box = SetupTextBox();
      }
#   endif
   assert( 0 < size );
   ptr = jseUtilMalloc(size, line, file);
   if ( NULL == ptr  &&  !jseDbgInMemDebug ) {
      jseInsufficientMemory();
   }
   return ptr;
}

#if 0
old    void *
old jseUtilMustCalloc(uint num,uint size, ulong line, const char* file)
old {
old    void *ptr;
old #   ifdef __JSE_MAC__
old       if ( error_box == NULL )
old       {
old          error_box = (struct MacTextBox *) 1;
old             /* Otherwise we go into an infinite loop */
old          error_box = SetupTextBox();
old       }
old #   endif
old    assert( 0 < size );
old    ptr = jseUtilCalloc(num,size, line, file);
old    if ( NULL == ptr  &&  !jseDbgInMemDebug ) {
old       jseInsufficientMemory();
old    }
old    return ptr;
old }
#endif

   static struct AnalMalloc **
FindAnalMalloc(void *ptr)
{
   struct AnalMalloc **AMptr;
   slong ptrOffset = (slong)(((struct AnalMalloc *)0)->data);
   struct AnalMalloc *AM = (struct AnalMalloc *)(((ubyte *)ptr) - ptrOffset);
   assert( NULL != ptr );
   assert( 1 == sizeof(ubyte) );
   assert( NULL != AM );
   for ( AMptr = &RecentMalloc; *AMptr != AM; AMptr = &((*AMptr)->Prev) ) {
      if ( NULL == *AMptr )
         break;
   } /* endfor */
   if ( NULL == *AMptr ) {
      DebugPrintf(
 UNISTR("9003: Tried to access unalloced memory %08lX; sequence = %lu, size = %u.\n"),
 ptr,AM->AllocSequenceCounter,AM->size);
      assert(False);
      exit(EXIT_FAILURE);
   }
   if ( 0 != memcmp(AnalMallocHead,AM->Head,4) ) {
      DebugPrintf(UNISTR("9004: Beginning of pointer has been overwritten.\n"));
      assert(False);
      exit(EXIT_FAILURE);
   }
   if ( 0 != memcmp(AnalMallocFoot,&(AM->data[AM->size]),4) ) {
         DebugPrintf(
 UNISTR("Memory Block: Sequence = %lu, size = %u, ptr = %08lX line=%lu of file=%s\n\n"),
 AM->AllocSequenceCounter,AM->size,AM->data,AM->line,jsemem_a_to_u(AM->file));
      DebugPrintf(
  UNISTR("9005: Tail of pointer has been overwritten: %08lX,\n")
  UNISTR("sequence %lu, size = %u, ptr = %08lX line=%lu of file=%s.\n"),
  ptr,AM->AllocSequenceCounter,AM->size,AM->data,AM->line,jsemem_a_to_u(AM->file));
      assert(False);
      exit(EXIT_FAILURE);
   }
   return(AMptr);
}

   void
jseUtilMustFree(void *ptr)
{
   struct AnalMalloc **AMptr;
   struct AnalMalloc *AM;

   assert( NULL != ptr );
   ExclusiveMallocThreadStart();
   AMptr = FindAnalMalloc(ptr);
   AM = *AMptr;
   TotalMemoryAllocated -= AM->size;
   TotalMemoryAllocations--;
   if ( jseDbgMemVerbosity ) {
      DebugPrintf(UNISTR("Freeing sequence %lu allocated memory at %08lX\n\n"),
                  AM->AllocSequenceCounter,ptr);

   } /* endif */

   *AMptr = AM->Prev;
   assert( 0 < jseDbgAllocationCount );
   jseDbgAllocationCount--;
   /* Fill in the data area with GARBAGE value */
#  define  BAD_DATA    0xBD
   memset(AM->data,BAD_DATA,AM->size);
#  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
#     undef free
#  endif

#if !defined(JSE_NEVER_FREE) || (0==JSE_NEVER_FREE)
   free(AM);
#endif

#  if !defined(JSE_ENFORCE_MEMCHECK) || (0!=JSE_ENFORCE_MEMCHECK)
#     define free(P)         use jseMustFree
#  endif
   ExclusiveMallocThreadStop();
}

   void *
jseUtilReMalloc(void *PrevMalloc,uint size, ulong line, const char* file)
{
   struct AnalMalloc *oldAM, *newAM;
   void *newMemory;

   assert( 0 < size );
   if ( NULL == PrevMalloc )
   {
      return jseUtilMalloc(size,line,file);
   } /* endif */

   /* This re-malloc will ALWAYS move memory, which which force
    * any memory-moving errors to show up more quickly.  I (brent)
    * tried to make a remalloc that would mark old moved memory
    * as bad but couldn't be sure that the underlying memory
    * management didn't write its own information there.
    */
   newMemory = jseUtilMalloc(size,line,file);
   if ( NULL == newMemory )
      return NULL;

   ExclusiveMallocThreadStart();
   oldAM = *(FindAnalMalloc(PrevMalloc));
   if ( jseDbgMemVerbosity ) {
      newAM = *(FindAnalMalloc(newMemory));
      DebugPrintf(UNISTR("ReAllocated %lu to sequence %lu, from memory %08lX to %08lX\n\n"),
                  oldAM->AllocSequenceCounter,newAM->AllocSequenceCounter,
                  PrevMalloc,newMemory);
   } /* endif */
   ExclusiveMallocThreadStop();

   /* move minmum bytes from old place to new place, then free the old */
   memcpy(newMemory,PrevMalloc,min(size,oldAM->size));

   jseUtilMustFree(PrevMalloc);

   return newMemory;
}

   void *
jseUtilMustReMalloc(void *PrevMalloc,uint size, ulong line, const char* file)
{
   void *ptr = jseUtilReMalloc(PrevMalloc,size, line, file);
   if ( NULL == ptr  &&  !jseDbgInMemDebug ) {
      jseInsufficientMemory();
   }
   return ptr;
}

   ulong
jseMemReport(jsebool verbose) /* Do some checks on memory allocation */
{
   jsebool SaveVerbosity = jseDbgMemVerbosity;
   struct AnalMalloc * AM;
   ulong Count;

   jseDbgInMemDebug = True;
   jseDbgMemVerbosity = False;
   if ( verbose )
      DebugPrintf(UNISTR("There are currently %lu blocks allocated.\n"),
                  jseDbgAllocationCount);
   /* loop through current stack and see that allocations all look OK */
   for ( AM = RecentMalloc, Count = 0; NULL != AM; AM = AM->Prev, Count++ )
   {
      if ( 0 != memcmp(AnalMallocHead,AM->Head,4) ) {
         DebugPrintf(UNISTR("9004: Beginning of pointer has been overwritten.\n"));
         DebugPrintf( UNISTR("Memory Block: Sequence = %lu, size = %u, ptr = %08lX line=%lu of file=%s\n\n"),
   AM->AllocSequenceCounter,AM->size,AM->data,AM->line,jsemem_a_to_u(AM->file));
         assert( False );
         exit(EXIT_FAILURE);
      }
      if ( 0 != memcmp(AnalMallocFoot,&(AM->data[AM->size]),4) ) {

         DebugPrintf(UNISTR("9005: Tail of pointer has been overwritten\n"));
         DebugPrintf( UNISTR("Memory Block: Sequence = %lu, size = %u, ptr = %08lX line=%lu of file=%s\n\n"),
   AM->AllocSequenceCounter,AM->size,AM->data,AM->line,jsemem_a_to_u(AM->file));


            /* Why no numeric arguments? -JMC */
         assert( False );
         exit(EXIT_FAILURE);
      }
   } /* endfor */
   if ( Count != jseDbgAllocationCount ) {
      DebugPrintf(UNISTR("9006: There are %lu blocks allocated, but should be %lu\n"),
                  Count,jseDbgAllocationCount);
      assert( False );
      exit(EXIT_FAILURE);
   }
#ifdef JSE_MIN_MEMORY
   /* You don't want to do this on virtual memory systems, it thrashes
    * you machine and gives no real useful information.
    */
   if ( verbose ) {
      /* See how many times we can allocate a 100-byte chunk. */
      struct AllocLoop {
         struct AllocLoop *Prev;
      } *Recent = NULL;
#      define DEBUG_MALLOC_SIZE  100
      for ( Count = 0; ; Count++ ) {
         struct AllocLoop *New =
            jseMustMalloc(struct AllocLoop,DEBUG_MALLOC_SIZE -
                          sizeof(struct AllocLoop));
         if ( NULL == New ) {
            break;
         } else {
            New->Prev = Recent;
            Recent = New;
         } /* endif */
      } /* endif */
      DebugPrintf(UNISTR("Could allocate %u bytes %lu times.\n"),
                  DEBUG_MALLOC_SIZE,Count);
      /* free up all the memory just allocated */
      while ( NULL != Recent ) {
         struct AllocLoop *Prev = Recent->Prev;
         jseMustFree(Recent);
         Recent = Prev;
      } /* endwhile */
   } /* endif */
#endif
   jseDbgMemVerbosity = SaveVerbosity;
   jseDbgInMemDebug = False;
   return(jseDbgAllocationCount);
}

   void
jseMemVerbose(jsebool SetVerbose)
{
   jseDbgMemVerbosity = SetVerbose;
}

   jsebool
jseMemValid(void *ptr,uint offset)
{
   struct AnalMalloc *AM;
   ExclusiveMallocThreadStart();
   AM = *(FindAnalMalloc(ptr));
   ExclusiveMallocThreadStop();
   return( offset < AM->size );
}

#endif /*# ifdef# else JSE_MEM_DEBUG */


/* mapped malloc stuff */

#ifdef GEOS_MAPPED_MALLOC

#include <MapHeap.h>

/* Flag that script engine should callQuit as soon as possible due to 
   an out of memory condition. */
extern jsebool jseOutOfMemory;

Boolean mapCreated = FALSE;
MemHandle phyMemInfoBlk;
word mappedCount = 0;

#define MapHeapPtr(p) (mapCreated && MapHeapMaybeInHeap(p))
#define MappedChunkSize(p) (*((word *)((byte *)p-2)))

#ifdef MEM_TRACKING

#include <heap.h>

dword mappedSize;
dword maxMappedSize;
dword nonMappedSize;
dword maxNonMappedSize;

dword NonMappedChunkSize(void *ptr)
{
    if (PtrToOffset(ptr) == 2) {
	/* waah...handle is at beginning of chunk, use handy offset -2 macro */
	return (MemGetInfo(MappedChunkSize(ptr), MGIT_SIZE));
    } else {
	return MappedChunkSize(ptr);
    }
}

dword jseChunkSize(void *ptr)
{
    if (MapHeapPtr(ptr)) {
	return MappedChunkSize(ptr);
    } else {
	return NonMappedChunkSize(ptr);
    }
}

#define MAXMAPPEDSIZE() if (mappedSize > maxMappedSize) maxMappedSize = mappedSize;
#define MAXNONMAPPEDSIZE() if (nonMappedSize > maxNonMappedSize) maxNonMappedSize = nonMappedSize;

#endif  /* MEM_TRACKING */

JSECALLSEQ_CFUNC(void) mappedInit()
{
#ifndef FULL_EXECUTE_IN_PLACE
#pragma option -dc
#endif
    mapCreated = MapHeapCreate("js      ", &phyMemInfoBlk);
#ifndef FULL_EXECUTE_IN_PLACE
#pragma option -dc-
#endif
#ifdef MEM_TRACKING
    mappedSize = 0;
    nonMappedSize = 0;
#endif
}

JSECALLSEQ_CFUNC(void) mappedExit()
{
    if (mapCreated) MapHeapDestroy(phyMemInfoBlk);
    mapCreated = FALSE;
#ifdef MEM_TRACKING
    mappedSize = 0;
    nonMappedSize = 0;
#endif
}

JSECALLSEQ_CFUNC(void) jseMappedFree(void *blockPtr)
{
    jseAssert();

    if (MapHeapPtr(blockPtr)) {
#ifdef MEM_TRACKING
	mappedSize -= MappedChunkSize(blockPtr);
#endif
	MapHeapFree(blockPtr);
    } else {
#ifdef MEM_TRACKING
	nonMappedSize -= NonMappedChunkSize(blockPtr);
#endif
	free(blockPtr);
    }
}

JSECALLSEQ_CFUNC(void *) jseMappedMalloc(word newSize)
{
    void *ret = 0;

    jseAssert();

    if (mapCreated) {
	ret = MapHeapMalloc(newSize);
#ifdef MEM_TRACKING
	if (ret) {
	    mappedSize += MappedChunkSize(ret);
	    MAXMAPPEDSIZE();
	}
#endif
	if (!ret)
	    jseOutOfMemory = TRUE;	/* bail ASAP */
    }
    if (!ret) {
	ret = malloc(newSize);
#ifdef MEM_TRACKING
	if (ret) {
	    nonMappedSize += NonMappedChunkSize(ret);
	    MAXNONMAPPEDSIZE();
	}
#endif
    }
    return ret;
}

JSECALLSEQ_CFUNC(void *) jseMappedRealloc(void *blockPtr, word newSize)
{
    void *retP = 0;

    jseAssert();

    /* a couple of special cases */
    if (blockPtr == 0) {
	return jseMappedMalloc(newSize);
    }
    if (newSize == 0) {
	jseMappedFree(blockPtr);
	return 0;
    }

    if (MapHeapPtr(blockPtr)) {
	word oldSize = MappedChunkSize(blockPtr);

	retP = MapHeapRealloc(blockPtr, newSize);
#ifdef MEM_TRACKING
	if (retP) {
	    mappedSize -= oldSize;
	    mappedSize += MappedChunkSize(retP);
	    MAXMAPPEDSIZE();
        }
#endif
	if (!retP) {
	    jseOutOfMemory = TRUE;	/* bail ASAP */
	    retP = malloc(newSize);
	    if (retP) {
#ifdef MEM_TRACKING
		nonMappedSize += NonMappedChunkSize(retP);
		MAXNONMAPPEDSIZE();
#endif
		memcpy(retP, blockPtr, oldSize);
	    }
	}
    } else {
#ifdef MEM_TRACKING
	word noldSize = NonMappedChunkSize(blockPtr);
#endif
	retP = realloc(blockPtr, newSize);
#ifdef MEM_TRACKING
	if (retP) {
	    nonMappedSize -= noldSize;
	    nonMappedSize += NonMappedChunkSize(retP);
	    MAXNONMAPPEDSIZE();
        }
#endif
    }
    return retP;
}

#else  /* GEOS_MAPPED_MALLOC */

/* these are the non-GEOS_MAPPED_MALLOC versions */

#include <heap.h>

dword jseChunkSize(void *ptr)
{
    if (PtrToOffset(ptr) == 2) {
	/* handle is at beginning of chunk */
	return (MemGetInfo((*((word *)((byte *)ptr-2))), MGIT_SIZE));
    } else {
	return (*((word *)((byte *)ptr-2)));
    }
}

JSECALLSEQ_CFUNC(void) jseMappedFree(void *blockPtr)
{
    free(blockPtr);
}

JSECALLSEQ_CFUNC(void *) jseMappedMalloc(word newSize)
{
    return malloc(newSize);
}

JSECALLSEQ_CFUNC(void *) jseMappedRealloc(void *blockPtr, word newSize)
{
    return realloc(blockPtr, newSize);
}

#endif  /* GEOS_MAPPED_MALLOC */

/* these exists for non-GEOS_MAPPED_MALLOC versions since they're exported */

JSECALLSEQ_CFUNC(void) jseEnter()
{
#ifdef GEOS_MAPPED_MALLOC
    if (mapCreated) MapHeapEnter(phyMemInfoBlk);
EC_ERROR_IF(mappedCount>20, -1);
    mappedCount++;
#endif
}

JSECALLSEQ_CFUNC(void) jseLeave()
{
#ifdef GEOS_MAPPED_MALLOC
EC_ERROR_IF(mappedCount==0, -1);
    mappedCount--;
    if (mapCreated) MapHeapLeave();
#endif
}

JSECALLSEQ_CFUNC(void) jseAssert()
{
#ifdef GEOS_MAPPED_MALLOC
    if (mappedCount==0) CFatalError(-1);
EC_ERROR_IF(mappedCount==0, -1);
#endif
}

JSECALLSEQ_CFUNC(void) jseMemInfo(jseMemInfoStruct *memInfo)
{
#ifdef MEM_TRACKING
    extern dword handleMemSize;
    extern dword maxHandleMemSize;

#ifdef GEOS_MAPPED_MALLOC
    memInfo->mappedSize = mappedSize;
    memInfo->maxMappedSize = maxMappedSize;
    memInfo->nonMappedSize = nonMappedSize;
    memInfo->maxNonMappedSize = maxNonMappedSize;
#else
    memInfo->mappedSize = 0;
    memInfo->maxMappedSize = 0;
    memInfo->nonMappedSize = 0;
    memInfo->maxNonMappedSize = 0;
#endif
    memInfo->handleMemSize = handleMemSize;
    memInfo->maxHandleMemSize = maxHandleMemSize;
#endif
}
