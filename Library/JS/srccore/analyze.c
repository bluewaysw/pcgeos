/* analyze.c  Routines to do self-analysis.  These are useful for debugging.
 */

/* (c) COPYRIGHT 1993-2000         NOMBAS, INC.
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

#include "srccore.h"

#ifndef NDEBUG

void mark_variable(wSEVar var);
void mark_object(hSEObject hobj);

   static ulong NEAR_CALL
memcount(struct Call *call,ulong *total,ulong *pool)
{
   hSEObject hobj;
   struct Function *func;
   struct seString *string;
   ulong ret = 0;
   ulong i;
#  if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
      uint hashSize = call->Global->hashSize;
      struct HashList ** hashTable = call->Global->hashTable;
#  endif
   
   *total = 0;
   *pool = 0;
   
   hobj = call->Global->all_hobjs;
   while( hobj != hSEObjectNull )
   {
      wSEObject wobj;
      SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);

      if( hSEMembersNull != SEOBJECT_PTR(wobj)->hsemembers  )
      {
#        if JSE_PACK_OBJECTS==0
            *total += SEOBJECT_PTR(wobj)->alloced*sizeof(struct _SEObjectMem);
#        else
            *total += SEOBJECT_PTR(wobj)->used*sizeof(struct _SEObjectMem);
#        endif
      }
      *total += sizeof(struct _SEObject);

      if( (SEOBJECT_PTR(wobj)->flags & SEOBJ_SWEEP_BIT)!=0 )
      {
         ret += sizeof(struct _SEObject);
         if( hSEMembersNull != SEOBJECT_PTR(wobj)->hsemembers )
         {
#        if JSE_PACK_OBJECTS==0
            ret += SEOBJECT_PTR(wobj)->alloced*sizeof(struct _SEObjectMem);
#        else
            ret += SEOBJECT_PTR(wobj)->used*sizeof(struct _SEObjectMem);
#        endif
         }
      }
      if( (SEOBJECT_PTR(wobj)->flags & SEOBJ_FREE_LIST_BIT)!=0 )
      {
         *pool += sizeof(struct _SEObject);
         if( hSEMembersNull != SEOBJECT_PTR(wobj)->hsemembers )
         {
#           if JSE_PACK_OBJECTS==0
               *pool += SEOBJECT_PTR(wobj)->alloced*sizeof(struct _SEObjectMem);
#           else
               *pool += SEOBJECT_PTR(wobj)->used*sizeof(struct _SEObjectMem);
#           endif
         }
      }
      SEOBJECT_PTR(wobj)->flags &= ~SEOBJ_SWEEP_BIT;
      hobj = SEOBJECT_PTR(wobj)->hNext;
      SEOBJECT_UNLOCK_W(wobj);
   }

   /* count functions */
   for( func = call->Global->funcs;func!=NULL;func = func->next )
   {
      *total += FUNCTION_IS_LOCAL(func)?
         sizeof(struct LocalFunction):
         sizeof(struct LibraryFunction);

      if( (func->flags&Func_SweepBit)!=0 )
      {
         ret += FUNCTION_IS_LOCAL(func)?
         sizeof(struct LocalFunction):
         sizeof(struct LibraryFunction);
      }
      func->flags &= ~Func_SweepBit;
   }


   /* count strings */
   for( string = call->Global->stringdatas;string!=NULL;string = string->prev )
   {
      *total += sizeof(struct seString);
      *total += string->length*sizeof(jsechar);

      if( SESTR_MARKED(string)!=0 )
      {
         ret += sizeof(struct seString);
         ret += string->length*sizeof(jsechar);
      }
      SESTR_UNMARK(string);
   }


   /* count entries in string table */
   for( i = 0; i < hashSize; i++ )
   {
      struct HashList *current = hashTable[i],*next;

      while( current!=NULL )
      {
         next = current->next;

         ret += sizeof(struct HashList)+sizeof(stringLengthType);
         ret += LengthFromHashList(current);

         current->flags &= ~JSE_STRING_SWEEP;
         current = next;
      }
   }

   return ret;
}


   static void NEAR_CALL
memreport(struct Call *call,jsecharptr usage)
{
   ulong used,total,pool;

   used = memcount(call,&total,&pool);

   DebugPrintf(UNISTR("      %s:"),usage);
   DebugPrintf(UNISTR("        total bytes:    %ld"),total);
   DebugPrintf(UNISTR("        bytes in pools: %ld"),pool);
   DebugPrintf(UNISTR("        locked in:      %ld"),used);
}


   static void NEAR_CALL
memcheck(struct Call *call)
{
   struct Global_ *global = call->Global;
   struct Call *loop;
   seAPIVar vloop = global->APIVars;

   while( call->next!=NULL ) call = call->next;


   /* global variable cache's are on a per-call basis,
    * and just record indexes into the global, so they
    * mark nothing new. In each case, when we go to use
    * the cache, if the item is in the cache, but the
    * index doesn't match (i.e. that element is not the
    * name we are looking for), the item is just
    * purged from the cache.
    */
    
#  if !defined(JSE_GROWABLE_STACK) || (0==JSE_GROWABLE_STACK)
   {
      rSEVar i = call->Global->stack;

      for( ;i<=call->stackptr;i++ )
         mark_variable(i);
#else
   {
      sint i;

      for( i=0;i<=call->stackptr;i++ )
         mark_variable(call->Global->growingStack + i);
#endif
   }
   memreport(call,UNISTR("secode stack"));



   while( vloop!=NULL )
   {
      mark_variable(&(vloop->value));
      mark_variable(&(vloop->last_access));
      vloop = vloop->next;
   }
   memreport(call,UNISTR("API variables yet to be destroyed"));


   loop = call;
   while( loop!=NULL )
   {
      vloop = call->tempvars;
      while( vloop!=NULL )
      {
         mark_variable(&(vloop->value));
         mark_variable(&(vloop->last_access));
         vloop = vloop->next;
      }
      loop = loop->next;
   }
   memreport(call,UNISTR("API tempvars"));

   
   loop = call;
   while( loop!=NULL )
   {
      mark_object(call->hGlobalObject);
      loop = loop->prev;
   }
   memreport(call,UNISTR("global variable(s)"));
}

   static void NEAR_CALL
stringTableStuff(struct Call *call)
{
   struct HashList *entry;
   uint index;
   ulong totalStrings = 0;

   /* string table stuff */
   DebugPrintf(UNISTR("    String Table:"));
   for ( index = 0; index < call->Global->hashSize; index++ )
   {
      DebugPrintf(UNISTR("      index: %d"),index);
      for ( entry = call->Global->hashTable[index]; NULL != entry; entry = entry->next )
      {
         DebugPrintf(UNISTR("        \"%s\""),NameFromHashList(entry));
         totalStrings++;
      }
   }
   DebugPrintf(UNISTR("      Total Strings: %ld"),totalStrings);
}

   static void NEAR_CALL
showCallVarCounts(struct Call *call,uint depth)
{
   uword32 i;
   seAPIVar loop;
   rSEObject robj;

   i = 0;
   for( loop=call->Global->APIVars;loop!=NULL;loop = loop->next ) i ++;
   DebugPrintf(UNISTR("  %*sUndestroyed API vars = %d"),depth*2,"",i);
   
   i = 0;
   for( loop=call->tempvars;loop!=NULL;loop = loop->next ) i ++;
   DebugPrintf(UNISTR("  %*stempVars in this call = %d"),depth*2,"",i);
   DebugPrintf(UNISTR("  %*sGlobalObject = %08lX"),depth*2,"",call->hGlobalObject);
   SEOBJECT_ASSIGN_LOCK_R(robj,call->hGlobalObject);
   DebugPrintf(UNISTR("  %*sglobal vars = %d"),depth*2,"",SEOBJECT_PTR(robj)->used);
   SEOBJECT_UNLOCK_R(robj);
}

   static void NEAR_CALL
lotsOfMemoryStuff(struct Call *call)
{
   /* show how much memory is being used where */
   DebugPrintf(UNISTR("    memory use:"));
   memcheck(call);

   /* string and chunk data no longer shown because they are not
    * allocated in checks, the memreport() shows all need to know
    * about them
    */
}

   static void NEAR_CALL
ShowMembers(struct Call *call,hSEObject hobj,uint depth,jsebool mark)
{
   rSEObject robj;

   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);

   if ( (mark && (0 != (SEOBJ_SWEEP_BIT & SEOBJECT_PTR(robj)->flags)))
     || (!mark && (0 == (SEOBJ_SWEEP_BIT & SEOBJECT_PTR(robj)->flags))) )
   {
      if ( mark )
      {
         DebugPrintf(UNISTR("    %*s<revisited>"),depth*2,"");
      }
      SEOBJECT_UNLOCK_R(robj);
   }
   else
   {
      wSEObject wobj;
      MemCountUInt i;
      rSEMembers rMembers;
      MemCountUInt used;

      SEOBJECT_UNLOCK_R(robj);

      SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
      if ( mark )
         SEOBJECT_PTR(wobj)->flags |= SEOBJ_SWEEP_BIT;
      else
         SEOBJECT_PTR(wobj)->flags &= ~SEOBJ_SWEEP_BIT;
      used = SEOBJECT_PTR(wobj)->used;
      if ( 0 != used )
         SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(wobj)->hsemembers);
      SEOBJECT_UNLOCK_W(wobj);
      if ( 0 != used )
      {
         for ( i = 0; i < used; i++ )
         {
            rSEVar var = &(SEMEMBERS_PTR(rMembers)[i].value);
            if ( mark )
            {
               DebugPrintf(VObject == SEVAR_GET_TYPE(var)?
                           UNISTR("    %*s%s %d %08lX"):UNISTR("    %*s%s %d"),
                           depth*2,"",GetStringTableEntry(call,SEMEMBERS_PTR(rMembers)[i].name,NULL),
                           SEVAR_GET_TYPE(var),SEVAR_GET_OBJECT(var));
            }
            if ( VObject == SEVAR_GET_TYPE(var) && SEVAR_GET_OBJECT(var) )
            {
               /* call this function recursively */
               ShowMembers(call,SEVAR_GET_OBJECT(var),depth+1,mark);
            }
         }
         SEMEMBERS_UNLOCK_R(rMembers);
      }
   }
}

   static void NEAR_CALL
showAPIvars(struct Call *call)
{
   seAPIVar apiVars;
   uint unfreed_count = 0;
   struct Global_ *global = call->Global;
   struct Call *origcall = call;


   while( call->next!=NULL ) call = call->next;

   while( 1 )
   {
      apiVars = call?call->tempvars:global->APIVars;

      while( apiVars!=NULL )
      {
         if ( apiVars->shouldBeFreed )
         {
            rSEVar var;
            unfreed_count++;
         
#if JSE_TRACKVARS==1
            DebugPrintf(UNISTR("    File: %s, Line %d by function %s"),
                        apiVars->file,apiVars->line,apiVars->function);
#endif

            var = seapiGetValue(origcall,apiVars);
            DebugPrintf(UNISTR("      type: %d"),SEVAR_GET_TYPE(var));
            if ( VObject == SEVAR_GET_TYPE(var) )
            {
               /* call this function recursively */
               DebugPrintf(UNISTR("      members of %08lX"),SEVAR_GET_OBJECT(var));
               ShowMembers(origcall,SEVAR_GET_OBJECT(var),2,True);
               ShowMembers(origcall,SEVAR_GET_OBJECT(var),2,False);
            }
         }
         apiVars = apiVars->next;
      }
      
      if( call==NULL ) break;
      call = call->prev;
   }
   
   if ( 0 == unfreed_count )
   {
      DebugPrintf(UNISTR("    no apiVars allocated"));
   }
}

   static void NEAR_CALL
showAllCallInformation(struct Call *call)
{
   jsechar buffer[500];
   struct Call *next;
   struct Call *prev;
   uword16 old_collect_disable;

   DebugPrintf(UNISTR("  BEFORE GARBAGE COLLECTION:\n"));
   lotsOfMemoryStuff(call);

   old_collect_disable = call->Global->collect_disable;
   call->Global->collect_disable = 0;
   garbageCollect(call);
   call->Global->collect_disable = old_collect_disable;

   DebugPrintf(UNISTR(""));
   DebugPrintf(UNISTR("  AFTER GARBAGE COLLECTION:\n"));
   lotsOfMemoryStuff(call);

   DebugPrintf(UNISTR(""));
   stringTableStuff(call);

   DebugPrintf(UNISTR(""));
   DebugPrintf(UNISTR("  call = %08lX"),call);
   showCallVarCounts(call,1);

   /* show all prev calls */
   strcpy_jsechar((jsecharptr)buffer,UNISTR("call"));
   prev = call;
   while ( NULL != (prev=prev->prev) )
   {
      strcat_jsechar((jsecharptr)buffer,UNISTR("->prev"));
      DebugPrintf(UNISTR("  %s = %08lX\n"),buffer,prev);
      showCallVarCounts(prev,1);
   }

   /* show all next calls */
   strcpy_jsechar((jsecharptr)buffer,UNISTR("call"));
   next = call;
   while ( NULL != (next=next->next) )
   {
      strcat_jsechar((jsecharptr)buffer,UNISTR("->next"));
      DebugPrintf(UNISTR("  %s = %08lX\n"),buffer,next);
      showCallVarCounts(next,1);
   }

   DebugPrintf(UNISTR(""));
#if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
   DebugPrintf(UNISTR("  stack offset = %lu"),call->stackptr);
#else
   DebugPrintf(UNISTR("  stack offset = %lu"),call->stackptr - call->Global->stack);
#endif
   
   DebugPrintf(UNISTR(""));
   DebugPrintf(UNISTR("  GlobalObject %08lX"),call->hGlobalObject);
   ShowMembers(call,call->hGlobalObject,0,True);
   ShowMembers(call,call->hGlobalObject,0,False);

   /* show all API variables in use */
   DebugPrintf(UNISTR(""));
   DebugPrintf(UNISTR("  API variables not yet freed:"));
   showAPIvars(call);
}

void seInternalAnalysis(struct Call *call)
{
   DebugPrintf(UNISTR("start seInternalAnalysis"));
   DebugPrintf(UNISTR("  collect_disable was %d"),call->Global->collect_disable);

   call->Global->collect_disable++;
   showAllCallInformation(call);
   call->Global->collect_disable--;
#ifdef MEM_TRACKING
   DebugPrintf(UNISTR("all_objs_count - %d"),call->Global->all_objs_count);
   DebugPrintf(UNISTR("all_objs_maxCount - %d"),call->Global->all_objs_maxCount);
   DebugPrintf(UNISTR("all_objs_size - %ld"),call->Global->all_objs_size);
   DebugPrintf(UNISTR("all_objs_maxSize - %ld"),call->Global->all_objs_maxSize);

   DebugPrintf(UNISTR("all_mem_count - %d"),call->Global->all_mem_count);
   DebugPrintf(UNISTR("all_mem_maxCount - %d"),call->Global->all_mem_maxCount);
   DebugPrintf(UNISTR("all_mem_size - %ld"),call->Global->all_mem_size);
   DebugPrintf(UNISTR("all_mem_maxSize - %ld"),call->Global->all_mem_maxSize);

   DebugPrintf(UNISTR("hashAllocSize - %ld"),call->Global->hashAllocSize);
   DebugPrintf(UNISTR("maxHashAllocSize - %ld"),call->Global->maxHashAllocSize);
#endif

   DebugPrintf(UNISTR("end seInternalAnalysis"));
   DebugPrintf(UNISTR(""));
}

#else

   ALLOW_EMPTY_FILE

#endif /* #ifndef NDEBUG */
