/***************************************************************************
 *  FILE:  AWATCHER.GOH
 ***************************************************************************/

/*-------------------------------------------------------------------------
 | Project:  WebMagick (HTML Browser)
 |
 | Module:   Allocation Watcher
 |           Used to keep track of a global amount of allocation and
 |           to parse it out little by little to the callers.
 |
 |           Copyright (c) 1998 Breadbox Computer Company
 |
 | Author:   Lysle E. Shields III
 |
 | History:
 |    Who: Date:     Comment:
 |    ---- --------- --------------------
 |    LES  05/13/98  Created.
 |
 *-----------------------------------------------------------------------*/

typedef MemHandle AllocWatcherHandle ;
#define NullWatcher NullHandle

AllocWatcherHandle AllocWatcherCreate(dword startingAmount) ;

void AllocWatcherDestroy(AllocWatcherHandle watch) ;

Boolean AllocWatcherAllocate(AllocWatcherHandle watch, dword amount) ;

void AllocWatcherFree(AllocWatcherHandle watch, dword amount) ;

dword AllocWatcherGetRemaining(AllocWatcherHandle watch) ;

/***************************************************************************
 *  END OF FILE:  AWATCHER.GOH
 ***************************************************************************/

