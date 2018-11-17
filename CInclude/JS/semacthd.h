/* semacthd.h  Macintosh Threading
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

#if defined(__JSE_MAC__)

#include <Threads.h>

#ifndef MAC_THREAD_YIELD_FREQ
   #define MAC_THREAD_YIELD_FREQ  60
#endif
#ifndef MAC_THREAD_POOL_SIZE
   #define MAC_THREAD_POOL_SIZE   20
#endif
#ifndef MAC_THREAD_MAX
   #define MAC_THREAD_MAX         0
#endif
#ifndef MAC_THREAD_STACK_SIZE
   #define MAC_THREAD_STACK_SIZE  40000
#endif

struct MacThread {
      void *              threadEntryParam;
      ThreadEntryProcPtr  threadEntryFunc;
      ThreadID            threadID;
      long                lastCount;

#if defined(__NPEXE__)
      struct ShimLink_t          *ShimLink;
#endif
};

extern short   MacThreadExclusiveThreadCount;
extern long    MacThreadYieldFrequency;
extern long    MacThreadNumberOfTasks;
extern jsebool MacThreadPoolInitialized;

struct MacThread * NewMacThread( ThreadEntryProcPtr entryFunc, void * entryParam );
void DeleteMacThread( struct MacThread * This );
jsebool MacThreadRun( struct MacThread * This );
void MacThreadOccasionalYield( );

void MacThreadDispose( ThreadID id);
void MacThreadRunTasks( ulong ticksToRun );

#define MacThreadExclusiveThreadStart()  ++MacThreadExclusiveThreadCount;
#define MacThreadExclusiveThreadEnd()              \
   --MacThreadExclusiveThreadCount;                \
   assert( MacThreadExclusiveThreadCount >= 0 );   \
   if( MacThreadExclusiveThreadCount < 0 )         \
      MacThreadExclusiveThreadCount = 0
#define MacThreadResentExclusiveThread() MacThreadExclusiveThreadCount = 0;



#endif /* __JSE_MAC__ && USE_MAC_THREADS */
