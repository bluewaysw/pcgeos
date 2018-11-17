/* Garbage.c  - This is the garbage collector. It also has routines
 *              for allocating the items it later collects. See
 *              'srccore/var.h' for a thorough description.
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

#ifdef JSE_MEM_SUMMARY
void memDump(struct Call *call);
#endif

#if JSE_NEVER_FREE==1
   void NEAR_CALL
callAddFreeItem(struct Call *call,void *mem)
{
   struct Global_ *global = call->Global;

   if( global->num_blocks_to_free>=global->max_blocks_to_free )
   {
      /* Debug-only code, so it is ok to use the 'Must' allocation
       * routines.
       */
      assert( global->num_blocks_to_free==global->max_blocks_to_free );
      global->max_blocks_to_free += 100;
      if( global->num_blocks_to_free )
      {
         global->blocks_to_free = jseMustReMalloc(void *,
                                                  global->blocks_to_free,
                                                  global->max_blocks_to_free*sizeof(void *));
      }
      else
      {
         global->blocks_to_free = jseMustMalloc(void *,
                                                global->max_blocks_to_free*sizeof(void *));
      }
   }

   global->blocks_to_free[global->num_blocks_to_free++] = mem;
}
#endif

/* All of the items that we garbage collect, we have a list
 * of, so we free everything when we exit.
 */
   void NEAR_CALL
collectUnallocate(struct Call *call)
{
   uint i;
   struct Global_ *global = call->Global;

#  if JSE_MEM_SUMMARY
   memDump(call);
#  endif

   /* free all remaining objects */
   while( global->all_hobjs )
   {
      rSEObject all_robjs;
      hSEObject hNext;

      SEOBJECT_ASSIGN_LOCK_R(all_robjs,global->all_hobjs);
      hNext = SEOBJECT_PTR(all_robjs)->hNext;
      if( SEOBJECT_PTR(all_robjs)->hsemembers!=hSEMembersNull )
      {
#        if JSE_MEMEXT_MEMBERS==0
            jseMustFree(SEOBJECT_PTR(all_robjs)->hsemembers);
#        else
            semembersFree(SEOBJECT_PTR(all_robjs)->hsemembers);
#        endif
#ifdef MEM_TRACKING
	 global->all_mem_count--;
	 global->all_mem_size -=
#        if JSE_PACK_OBJECTS==0
           (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(all_robjs)->alloced);
#        else
           (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(all_robjs)->used);
#        endif
#endif
      }
      SEOBJECT_UNLOCK_R(all_robjs);
#     if JSE_MEMEXT_OBJECTS==0
         jseMustFree(global->all_hobjs);
#     else
         seobjectFree(global->all_hobjs);
#     endif
#ifdef MEM_TRACKING
      global->all_objs_count--;
      global->all_objs_size -= sizeof(struct _SEObject);
#endif
      global->all_hobjs = hNext;
   }


   /* Free up string buffer data. */
   {
      struct seString *sd, *prev;
      prev = global->stringdatas;
      while ( NULL != (sd=prev) )
      {
         prev = sd->prev;
         SESTRING_FREE_DATA(sd);
         jseMustFree(sd);
      }
   }
   global->stringdatas = NULL;


   /* Free all remaining functions */
   while( global->funcs )
   {
      struct Function *tmp = global->funcs->next;

#ifdef MEM_TRACKING
      if ( !(FUNCTION_IS_LOCAL((global->funcs))) ) {
	  if ( !(Func_StaticLibrary & ((struct LibraryFunction *)(global->funcs))->function.flags) ) {
	      global->func_alloc_size -= jseChunkSize(((struct LibraryFunction *)(global->funcs))->FuncDesc->FunctionName);
	      global->func_alloc_size -= sizeof(struct jseFunctionDescription);
	  }
      }
      global->func_alloc_size -= sizeof(struct LibraryFunction);
      global->func_alloc_count--;
#endif
      functionDelete(global->funcs,call);
      global->funcs = tmp;
   }


#  if 0==JSE_DONT_POOL
      /* Free structure member thingees */
      for( i=0;i<global->memPoolCount;i++ )
      {
#        if JSE_MEMEXT_MEMBERS==0
            jseMustFree(global->mem_pool[i]);
#        else
            semembersFree(global->mem_pool[i]);
#        endif
      }
#  endif

#  if JSE_NEVER_FREE==1
      for( i=0;i<global->num_blocks_to_free;i++ )
         jseMustFree(global->blocks_to_free[i]);
      if( global->blocks_to_free!=NULL )
         jseMustFree(global->blocks_to_free);
#  endif
}


/* ----------------------------------------------------------------------
 * The mark/sweep collector. It is possible I will rewrite this later
 * to be more efficient, but it will probably not change. We use a
 * relatively simple collection of things need to be swept, and this
 * collector does a pretty good job. The only thing I'd like to do
 * is make it non-recursive, probably by storing the back pointers
 * in structures as I traverse them.
 * ---------------------------------------------------------------------- */


/* NYI: do the checks at the head of each function (the 'have I already
 *      been marked' checks) before calling the function instead.
 */

#define MARK_VARNAME(s) \
   if( IsNormalStringTableEntry(s) ) HashListFromVarName(s)->flags |= JSE_STRING_SWEEP
#ifdef NDEBUG
static void NEAR_CALL mark_variable(wSEVar var);
static void NEAR_CALL mark_object(hSEObject hobj);
#else
   void mark_variable(wSEVar var);
   void mark_object(hSEObject hobj);
#endif


static void NEAR_CALL mark_function(struct Function *func)
{
   assert( func!=NULL );

   if( (func->flags&Func_SweepBit)!=0 )
      return;
   else
      func->flags |= Func_SweepBit;

#  if 0 != JSE_MULTIPLE_GLOBAL
      if ( hSEObjectNull != func->hglobal_object )
         mark_object(func->hglobal_object);
#  endif
   /* all security is marked from the global, not individually for functions */

   if( FUNCTION_IS_LOCAL(func) )
   {
      /* currently we lock function text variable names into memory,
       * and only collect object member names
       */
      assert( ((struct LocalFunction *)func)->hConstants!=hSEObjectNull );
      mark_object(((struct LocalFunction *)func)->hConstants);
   }
}


static void NEAR_CALL mark_global(struct Global_ *global)
{
   seAPIVar loop = global->APIVars;
#if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   struct Security *sloop = global->allSecurity;
#endif

   assert( global!=NULL );

   while( loop!=NULL )
   {
      mark_variable(&(loop->value));
      mark_variable(&(loop->last_access));
      loop = loop->next;
   }
#if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   while( sloop!=NULL )
   {
      uint i;

      for( i=0;i<sloop->acceptUsed;i++ )
      {
         assert( sloop->acceptFuncs[i]!=NULL );
         mark_function(sloop->acceptFuncs[i]);
      }
      for( i=0;i<sloop->guardUsed;i++ )
      {
         assert( sloop->guardFuncs[i]!=NULL );
         mark_function(sloop->guardFuncs[i]);
      }
      if( sloop->hPrivateVariable ) mark_object(sloop->hPrivateVariable);
      if( sloop->hjseSecurityGuard ) mark_object(sloop->hjseSecurityGuard);
      if( sloop->hjseSecurityInit ) mark_object(sloop->hjseSecurityInit);
      if( sloop->hjseSecurityTerm ) mark_object(sloop->hjseSecurityTerm);

      sloop = sloop->next;
   }
#endif
}

#ifndef NDEBUG
static void NEAR_CALL assertNothingIsMarked(struct Call *call)
{
   struct Global_ *global = call->Global;
   { /* OBJECTS */
      hSEObject hobjs, hnext;
      for ( hobjs = global->all_hobjs; hSEObjectNull != hobjs; hobjs = hnext )
      {
         rSEObject robjs;
         SEOBJECT_ASSIGN_LOCK_R(robjs,hobjs);
         if( 0 != (SEOBJECT_PTR(robjs)->flags & SEOBJ_SWEEP_BIT) )
         {
            assert( False );
         }
         hnext = SEOBJECT_PTR(robjs)->hNext;
         SEOBJECT_UNLOCK_R(robjs);
      }
   }

   { /* FUNCTIONS */
      struct Function *funcs;
      for ( funcs = global->funcs; NULL != funcs; funcs = funcs->next )
      {
         if ( 0 != (funcs->flags & Func_SweepBit) )
         {
            assert( False );
         }
      }
   }

   { /* STRINGS */
      struct seString *strings;
      for ( strings = global->stringdatas; NULL != strings; strings = strings->prev )
      {
         if ( 0 != SESTR_MARKED(strings) )
         {
            assert( False );
         }
      }
   }

   { /* STRING TABLE */
      uint i;
#     if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
         uint hashSize = global->hashSize;
         struct HashList ** hashTable = global->hashTable;
#     endif
      for( i = 0; i < hashSize; i++ )
      {
         struct HashList *current;
         for ( current = hashTable[i]; NULL != current; current = current->next )
         {
            if ( 0 != (current->flags & JSE_STRING_SWEEP) )
            {
               assert( False );
            }
         }
      }
   }
}
#endif

static void NEAR_CALL mark_call(struct Call *call)
{
   struct Global_ *global = call->Global;
   seAPIVar loop = call->tempvars;

   assert( call!=NULL );

   /* Mark the stack using the stack pointer from the latest
    * call.
    */
   if( call->next==NULL )
   {
#  if !defined(JSE_GROWABLE_STACK) || (0==JSE_GROWABLE_STACK)
      wSEVar i = global->stack;

      for( ;i<=call->stackptr;i++ )
         mark_variable(i);
#else
      sint i;

      for( i=0;i<=call->stackptr;i++ )
         mark_variable(global->growingStack + i);
#endif
      mark_global(global);
   }
   else
   {
      assert( call->stackptr<=call->next->stackptr );
   }

   if( call->hDynamicDefault!=hSEObjectNull ) mark_object(call->hDynamicDefault);
   if( call->hObjectPrototype!=hSEObjectNull ) mark_object(call->hObjectPrototype);
   if( call->hArrayPrototype!=hSEObjectNull ) mark_object(call->hArrayPrototype);
   if( call->hFunctionPrototype!=hSEObjectNull ) mark_object(call->hFunctionPrototype);
   if( call->hStringPrototype!=hSEObjectNull ) mark_object(call->hStringPrototype);

   mark_variable(&(call->old_main));
   mark_variable(&(call->old_init));
   mark_variable(&(call->old_argc));
   mark_variable(&(call->old_argv));

   assert( call->hGlobalObject!=hSEObjectNull );
   mark_object(call->hGlobalObject);
   while( loop!=NULL )
   {
      mark_variable(&(loop->value));
      mark_variable(&(loop->last_access));
      loop = loop->next;
   }

   if( call->hScopeChain!=hSEObjectNull ) mark_object(call->hScopeChain);
   mark_variable(&(call->new_scope_chain));
   if( call->hVariableObject!=hSEObjectNull ) mark_object(call->hVariableObject);

   if( call->state==FlowError ) mark_variable(&(call->error_var));

   if( call->prev ) mark_call(call->prev);
}

#ifdef NDEBUG
static void NEAR_CALL mark_variable(wSEVar wVar)
#else
void mark_variable(wSEVar wVar)
#endif
{
   assert( wVar!=NULL );

   /* NYI: I should check that is valid var, but I need the call to
    * do it, so reformat to get a call in debug mode.
    */
   switch( wVar->type )
   {
      case VString:
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
#     endif
         assert( wVar->data.string_val.data!=NULL );
         SESTR_MARK(wVar->data.string_val.data);
         break;
      case VObject:
         if( SEVAR_GET_OBJECT(wVar) ) mark_object(SEVAR_GET_OBJECT(wVar));
         if( wVar->data.object_val.hSavedScopeChain!=hSEObjectNull )
            mark_object(wVar->data.object_val.hSavedScopeChain);
         break;
      case VReference:
         assert( wVar->data.ref_val.hBase!=hSEObjectNull );
         mark_object(wVar->data.ref_val.hBase);
         MARK_VARNAME(wVar->data.ref_val.reference);
         break;
      case VReferenceIndex:
         assert( wVar->data.ref_val.hBase!=hSEObjectNull );
         mark_object(wVar->data.ref_val.hBase);
         break;
#     ifndef NDEBUG
      case VNumber:
      case VNull:
      case VUndefined:
      case VBoolean:
      case VStorage:
#     if JSE_COMPACT_LIBFUNCS==1
      case VLibFunc:
#     endif
         break;
      default:
         assert( False );
#     endif
   }
}


#ifdef NDEBUG
static void NEAR_CALL mark_object(hSEObject hobj)
#else
void mark_object(hSEObject hobj)
#endif
{
   MemCountUInt i;
   wSEObject wobj;

   assert( hobj!=hSEObjectNull );
   SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);

   if( (SEOBJECT_PTR(wobj)->flags&SEOBJ_SWEEP_BIT)!=0 )
   {
      /* this member has already been visited - do no more */
      SEOBJECT_UNLOCK_W(wobj);
   }
   else
   {
      MemCountUInt used;

      assert( (SEOBJECT_PTR(wobj)->flags&SEOBJ_SWEEP_BIT)==0 );
      SEOBJECT_PTR(wobj)->flags |= SEOBJ_SWEEP_BIT;

      if( SEOBJECT_PTR(wobj)->func!=NULL ) mark_function(SEOBJECT_PTR(wobj)->func);

      if ( 0 == (used = SEOBJECT_PTR(wobj)->used) )
      {
         SEOBJECT_UNLOCK_W(wobj);
      }
      else
      {
         wSEMembers wMembers;
         SEMEMBERS_ASSIGN_LOCK_W(wMembers,SEOBJECT_PTR(wobj)->hsemembers);
         SEOBJECT_UNLOCK_W(wobj);
         for( i=0;i<used;i++ )
         {
#           if JSE_MEMEXT_OBJECTS==0
               assert( (SEOBJECT_PTR(wobj)->flags&SEOBJ_DONT_SORT)!=0 \
                    || SEMEMBERS_PTR(wMembers)[i].name!=NULL );
#           endif
            if( SEMEMBERS_PTR(wMembers)[i].name!=NULL )
            {
               MARK_VARNAME(SEMEMBERS_PTR(wMembers)[i].name);
            }
            mark_variable(&(SEMEMBERS_PTR(wMembers)[i].value));
         }
         SEMEMBERS_UNLOCK_W(wMembers);
      }
   }
}


/* The sweeper looks through the items we garbage collect: strings, objects,
 * VarName entries, and functions. It discards unused items, either by
 * freeing them to the system or putting them back in the memory pools.
 * It restores all mark flags to unmarked if the object is not freed.
 */
   static void NEAR_CALL
sweep(struct Call *call)
{
   struct Global_ *global = call->Global;
   hSEObject hObj, hNextObj, hPrevObj;
   struct Function *funcs;
   struct seString **strings, *string;
   uint i;
   struct Function **funcplace;
#  if !defined(JSE_ONE_STRING_TABLE) || (0==JSE_ONE_STRING_TABLE)
      uint hashSize = global->hashSize;
      struct HashList ** hashTable = global->hashTable;
#  endif

   /* Free up all objects no longer used */

   /* build up new list of still-used objects */
   hPrevObj = hSEObjectNull;
   hNextObj = global->all_hobjs;
   while ( hSEObjectNull != (hObj = hNextObj) )
   {
      wSEObject wObj;

      SEOBJECT_ASSIGN_LOCK_W(wObj,hObj);
      hNextObj = SEOBJECT_PTR(wObj)->hNext;
      if ( (SEOBJECT_PTR(wObj)->flags&(SEOBJ_SWEEP_BIT|SEOBJ_FREE_LIST_BIT))==0 )
      {
         if( SEOBJECT_PTR(wObj)->hsemembers != hSEMembersNull )
         {
#        ifndef NDEBUG
            {
               MemCountUInt oIdx;
               wSEMembers wMembers;
               SEMEMBERS_ASSIGN_LOCK_W(wMembers,SEOBJECT_PTR(wObj)->hsemembers);
#              if JSE_PACK_OBJECTS==0
               for ( oIdx = 0; oIdx < SEOBJECT_PTR(wObj)->alloced; oIdx++ )
#              else
               for ( oIdx = 0; oIdx < SEOBJECT_PTR(wObj)->used; oIdx++ )
#              endif
               {
                  memset(SEMEMBERS_PTR(wMembers)+oIdx,JSE_INVALID_COLLECT,
                         sizeof(SEMEMBERS_PTR(wMembers)[oIdx]));
               }
               SEMEMBERS_UNLOCK_W(wMembers);
            }
#        endif
#        if JSE_DONT_POOL==0
            if( global->memPoolCount<SE_MEM_POOL_SIZE
                && SEOBJECT_PTR(wObj)->used<=(OBJ_DEFAULT_SIZE*2) )
            {
               global->mem_pool[global->memPoolCount++] = SEOBJECT_PTR(wObj)->hsemembers;
            }
            else
#        endif
            {
#           ifdef HUGE_MEMORY
#              if JSE_PACK_OBJECTS==0
               assert( (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(wObj)->alloced)<HUGE_MEMORY );
#              else
               assert( (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(wObj)->used)<HUGE_MEMORY );
#              endif
#           endif
               {
#              if JSE_NEVER_FREE==1
                  callAddFreeItem(call,pObj->Members);
#              else
#                 if JSE_MEMEXT_MEMBERS==0
                     jseMustFree(SEOBJECT_PTR(wObj)->hsemembers);
#                 else
                     semembersFree(SEOBJECT_PTR(wObj)->hsemembers);
#                 endif
#ifdef MEM_TRACKING
		  call->Global->all_mem_count--;
		  call->Global->all_mem_size -= 
#                 if JSE_PACK_OBJECTS==0
                    (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(wObj)->alloced);
#                 else
                    (sizeof(struct _SEObjectMem)*SEOBJECT_PTR(wObj)->used);
#                 endif
#endif
#              endif
               }
            }
         }

         SEOBJECT_PTR(wObj)->hsemembers = hSEMembersNull;
#        if JSE_DONT_POOL==0
         if( global->objPoolCount<SE_OBJ_POOL_SIZE )
         {
            global->hobj_pool[global->objPoolCount++] = hObj;
            SEOBJECT_PTR(wObj)->flags = SEOBJ_FREE_LIST_BIT;
            hPrevObj = hObj;  
         }
         else
#        endif
         {
            /* item in question must be returned to the system.
             * update pointer to next link.
             */
            if ( hSEObjectNull == hPrevObj )
            {
               /* no previous object, so this is the start of the list */
               assert( global->all_hobjs == hObj );
               global->all_hobjs = SEOBJECT_PTR(wObj)->hNext;
            }             
            else
            {
               /* update hPrevObj to point to whatever this points to */
               wSEObject wPrevObj;
               SEOBJECT_ASSIGN_LOCK_W(wPrevObj,hPrevObj);
               SEOBJECT_PTR(wPrevObj)->hNext = SEOBJECT_PTR(wObj)->hNext;
               SEOBJECT_UNLOCK_W(wPrevObj);
            }
             
            /* free it */
#           ifndef NDEBUG
               memset(SEOBJECT_PTR(wObj),JSE_INVALID_COLLECT,sizeof(*(SEOBJECT_PTR(wObj))));
#           endif
            SEOBJECT_UNLOCK_W(wObj);
#           if JSE_NEVER_FREE==1
               callAddFreeItem(call,hObj);
#           else
#              if JSE_MEMEXT_OBJECTS==0
                  jseMustFree(hObj);
#              else
                  seobjectFree(hObj);
#              endif
#ifdef MEM_TRACKING
	       call->Global->all_objs_count--;
	       call->Global->all_objs_size -= sizeof(struct _SEObject);
#endif
#           endif

            /* continue so that following objs link won't change */
            continue;
         }
      }
      else
      {
         /* object is still in use, or is already on the free list,
          * restore its sweep bit flag.
          */
         hPrevObj = hObj;  
         SEOBJECT_PTR(wObj)->flags &= ~SEOBJ_SWEEP_BIT;
      }
      SEOBJECT_UNLOCK_W(wObj);
   }

   /* Free up all functions no longer used */
   funcs = global->funcs;

   /* build up new list of still-used functions */
   funcplace = &(global->funcs);

   while( funcs!=NULL )
   {
      struct Function *tmp = funcs->next;

      if( (funcs->flags & Func_SweepBit)==0 )
      {
         /* get rid of it */
#ifdef MEM_TRACKING
	  if ( !(FUNCTION_IS_LOCAL((funcs))) ) {
	      if ( !(Func_StaticLibrary & ((struct LibraryFunction *)funcs)->function.flags) ) {
		  call->Global->func_alloc_size -= jseChunkSize(((struct LibraryFunction *)funcs)->FuncDesc->FunctionName);
		  call->Global->func_alloc_size -= sizeof(struct jseFunctionDescription);
	      }
	  }
	  call->Global->func_alloc_size -= sizeof(struct LibraryFunction);
	  call->Global->func_alloc_count--;
#endif
         functionDelete(funcs,call);
      }
      else
      {
         /* keep it */
         funcs->flags &= ~Func_SweepBit;

         *funcplace = funcs;
         funcplace = &(funcs->next);
      }
      funcs = tmp;
   }
   *funcplace = NULL;


   /* Free up all strings no longer used */
   strings = &(global->stringdatas);
   while( NULL != (string=*strings) )
   {
      if( !SESTR_MARKED(string) )
      {
         /* unlink it and get rid of it */
         *strings = string->prev;

#        if !defined(NDEBUG) && JSE_MEMEXT_READONLY==0
         {
            void *data = SESTRING_GET_DATA(string);
            memset(data,JSE_INVALID_COLLECT,string->length);
            SESTRING_UNGET_DATA(string,data);
         }
#        endif
         SESTRING_FREE_DATA(string);

#        ifndef NDEBUG
            memset(string,JSE_INVALID_COLLECT,sizeof(*string));
#        endif
#        if JSE_NEVER_FREE==1
            callAddFreeItem(call,string);
#        else
            jseMustFree(string);
#        endif
      }
      else
      {
         SESTR_UNMARK(string);
         strings = &(string->prev);
      }
   }

   /* sweep the string table */
   for( i = 0; i < hashSize; i++ )
   {
      struct HashList **next = &(hashTable[i]);

      while( *next!=NULL )
      {
         if( (*next)->flags==0 && (*next)->table_entry==0 )
         {
            struct HashList *old = (*next);
            *next = (*next)->next;
            /* Not marked and not locked */
            RemoveStringTableEntry(call,old);
         }
         else
         {
            (*next)->flags &= ~JSE_STRING_SWEEP;
            next = &((*next)->next);
         }
      }
   }
}

#ifndef NDEBUG
   static void NEAR_CALL
assertFreeBitsMatchFreeSize(struct Call *call)
{
   struct Global_ *global = call->Global;
   ulong free_total = 0;
   hSEObject hObj, hNextObj;
   for ( hObj = global->all_hobjs; hSEObjectNull != hObj; hObj = hNextObj )
   {
      rSEObject rObj;
      SEOBJECT_ASSIGN_LOCK_R(rObj,hObj);
      if( 0 != (SEOBJECT_PTR(rObj)->flags & SEOBJ_FREE_LIST_BIT) )
      {
         free_total++;
      }
      hNextObj = SEOBJECT_PTR(rObj)->hNext;
      SEOBJECT_UNLOCK_R(rObj);
   }
#  if 0==JSE_DONT_POOL
   if ( free_total != global->objPoolCount )
   {
      assert( False );
   }
#  endif
}
#endif

#if 0==JSE_DONT_POOL
   void NEAR_CALL
collectRefill(struct Call *call)
{
   struct Global_ *global = call->Global;
   while( global->objPoolCount<SE_OBJ_POOL_SIZE )
   {
      wSEObject wTmp;
      hSEObject hTmp;

#     if JSE_MEMEXT_OBJECTS==0
         hTmp = jseMalloc(struct _SEObject,sizeof(struct _SEObject));
#     else
         hTmp = seobjectAlloc();
#     endif
      global->hobj_pool[global->objPoolCount++] = hTmp;

      /* Can't use 'jseMallocWithGC', because this routine
       * is called during GC - we are already doing it,
       * there is no extra memory.
       */
      if( hTmp==hSEObjectNull )
      {
         if( --global->objPoolCount==0 )
         {
            /* We have to have some in each pool or we can't continue */
            jseInsufficientMemory();
         }
         else
         {
            /* we didn't completely fill up the pool, but we have some
             * entries. Try to make do with them as long as we can.
             */
            break;
         }
      }

      SEOBJECT_ASSIGN_LOCK_W(wTmp,hTmp);
      SEOBJECT_PTR(wTmp)->flags = SEOBJ_FREE_LIST_BIT;
      SEOBJECT_PTR(wTmp)->hsemembers = hSEMembersNull;
      SEOBJECT_PTR(wTmp)->hNext = global->all_hobjs;
      SEOBJECT_UNLOCK_W(wTmp);
      global->all_hobjs = hTmp;
#ifdef MEM_TRACKING
      call->Global->all_objs_count++;
      if (call->Global->all_objs_count > call->Global->all_objs_maxCount)
	  call->Global->all_objs_maxCount = call->Global->all_objs_count;
      call->Global->all_objs_size += sizeof(struct _SEObject);
      if (call->Global->all_objs_size > call->Global->all_objs_maxSize)
	  call->Global->all_objs_maxSize = call->Global->all_objs_size;
#endif
   }
}
#endif /* #if 0==JSE_DONT_POOL */


/* Call each of the destructors in the call's global destructor table.
 * All are called, destructors cannot resurrect themselves (the object
 * may no longer be garbage, but its destructor will be called.) As
 * each destructor is called, delete that VarObjs _delete member.
 */
   static void NEAR_CALL
destructors(struct Call *call)
{
   struct Global_ *global = call->Global;
   /* This may seem weird, but it allows recursive collection/
    * destructor calling to work - they use the same 'global'
    * area.
    */
   while( global->destructorCount>0 )
   {
      hSEObject hToDestroy;
      rSEObject rToDestroy;
      wSEObject wToDestroy;

      hToDestroy = global->hDestructors[--global->destructorCount];
      SEOBJECT_ASSIGN_LOCK_R(rToDestroy,hToDestroy);

      /* can't destroy it while it is in use. */
      if( SEOBJ_IS_DYNAMIC(rToDestroy) )
      {
         seobjCallDynamicProperty(call,rToDestroy,dynacallDelete,
                                  STOCK_STRING(_delete),NULL,NULL);
      }
      SEOBJECT_ASSIGN_LOCK_W(wToDestroy,hToDestroy);
      SEOBJECT_UNLOCK_R(rToDestroy);

      /* We may have mucked with the structure, so make sure to
       * relookup the member name
       */
      seobjDeleteMember(call,wToDestroy,STOCK_STRING(_delete),False);
      SEOBJECT_UNLOCK_W(wToDestroy);
   }
}


#define DESTR_RECORD 0
#define DESTR_MARK   1

/* All seObjects are marked as used. Put all those unused and with
 * destructors onto the destructor list.
 */
   static jsebool NEAR_CALL
noteDestructors(struct Call *call,int mode)
{
   struct Global_ *global = call->Global;
   hSEObject hobj;

   assert( mode==DESTR_RECORD || mode==DESTR_MARK );

   if( global->final ) return False;

   global->destructorCount = 0;

   hobj = global->all_hobjs;
   while( hobj!=hSEObjectNull )
   {
      rSEObject robj;
      hSEObject hNextObj;
      jsebool toDestroy;

      SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
      hNextObj = SEOBJECT_PTR(robj)->hNext;
      toDestroy = (SEOBJECT_PTR(robj)->flags & (SEOBJ_SWEEP_BIT|SEOBJ_FREE_LIST_BIT))==0
               && SEOBJ_IS_DYNAMIC(robj);
      SEOBJECT_UNLOCK_R(robj);
      /* If it is not in use or currently on the free list, and has a destructor */
      if( toDestroy )
      {
         if( mode==DESTR_RECORD )
         {
            if( global->destructorCount>=global->destructorAlloced )
            {
               hSEObject *hNewD;
               global->destructorAlloced += 20;
               hNewD = jseReMalloc(hSEObject,global->hDestructors,
                                   sizeof(hSEObject)*global->destructorAlloced);
               if( hNewD==NULL )
               {
                  /* on failed realloc, the original memory is retained */
                  global->destructorAlloced -= 20;
                  return False;
               }
               global->hDestructors = hNewD;
            }
            global->hDestructors[global->destructorCount++] = hobj;
         }
         else
         {
            mark_object(hobj);
         }
      }
      hobj = hNextObj;
   }

   return True;
}


/* Call _all_ destructors in any seObject left. Because we remove
 * destructors after we call them, no destructors will be called
 * twice. This is used when the program is about to exit, a last
 * chance call of all remaining destructors.
 */
   void NEAR_CALL
callDestructors(struct Call *call)
{
   struct Global_ *global = call->Global;
   jsebool again;

   global->final = True;

   do {
      hSEObject hobj;

      again = False;
      global->destructorCount = 0;

      hobj = global->all_hobjs;
      while( hobj!=hSEObjectNull )
      {
         rSEObject robj;
         hSEObject hNextObj;
         jsebool hasDeleteProp;

         SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
         hNextObj = SEOBJECT_PTR(robj)->hNext;
         hasDeleteProp = SEOBJ_IS_DYNAMIC(robj);
         SEOBJECT_UNLOCK_R(robj);
         if( hasDeleteProp )
         {
            if( global->destructorCount>=global->destructorAlloced )
            {
               hSEObject *hNewD;

               global->destructorAlloced += 20;
               hNewD = jseReMalloc(hSEObject,global->hDestructors,
                                   sizeof(hSEObject)*global->destructorAlloced);
               if( hNewD==NULL )
               {
                  /* Normally, we record all destructors in existence then
                   * call them all. If any make a new object with a destructor
                   * (which would be instantly free since we are exiting),
                   * those destructors are not called. This prevents infinite
                   * loops.
                   *
                   * If we run out of memory, we try to do the destructors
                   * peacemeal. We record as many as we can, execute this,
                   * then record again. This leaves often the possibility of
                   * infinite destructor loops, but that is the best we can
                   * do without memory.
                   */
                  global->destructorAlloced -= 20;
                  if( global->destructorAlloced==0 )
                  {
                     /* In this case, we have no storage to even do some
                      * of the destructors, not much we can do except try
                      * to call it right away. This is even more likely to
                      * an infinite loop than the above case. However, such
                      * a thing is still a mistake in the user's object design.
                      * It is better to protect the customer who is using it
                      * right (by not just aborting his program for lack of
                      * memory) than favor the customer who is using it wrong
                      * (by aborting because we cannot guarantee an infinite loop
                      * won't happen), IMO. Thus, we call the destructors one
                      * at a time and an infinite loop cannot always be detected.
                      */
                     global->destructorCount = 1;
                     assert( global->hDestructors==NULL );
                     global->hDestructors = &hobj;
                     destructors(call);
                     global->destructorCount = 0;
                     global->hDestructors = NULL;

                     /* Continue looking for objects and calling them one at
                      * a time.
                      */
                     continue;
                  }

                  again = True;
                  break;
               }

               global->hDestructors = hNewD;
               assert( global->hDestructors!=NULL );
            }
            global->hDestructors[global->destructorCount++] = hobj;
         }
         hobj = hNextObj;
      }

      destructors(call);
   } while( again );
}


/* ----------------------------------------------------------------------
 * Garbage collects. It expects the sweep bits on all variables to be
 * not set, and it will make sure that is still the case before it exits.
 * After it collects, it will 'fill up' the allocator pools.
 * ---------------------------------------------------------------------- */

   void NEAR_CALL
garbageCollect(struct Call *call)
{
   struct Global_ *global = call->Global;
   uint i;

   /* global fine since all calls in chain share it */
   while( call->next ) call = call->next;

   /* We will be collecting as many strings as possible, so zero this. */
   global->stringallocs = 0;

   /* If garbage collection is disabled, we only collectRefill the allocator
    * pools. This allows a program to specify a realtime block it
    * doesn't want garbage collected in.
    */
   if ( 0 == global->collect_disable++ )
   {
#     ifndef NDEBUG
         assertNothingIsMarked(call);
#     endif

      /* go through and mark everything that is being used */
      mark_call(call);

      if( !noteDestructors(call,DESTR_RECORD) )
      {
         /* We do not have enough memory to note all destructors. So
          * we mark them but won't call them. Hopefully, later more
          * memory will become available and then we can call them.
          */
         noteDestructors(call,DESTR_MARK);
      }


      /* Note: we do the mark here because it must be done after
       * the varobjs are moved to this list, which obviously isn't
       * possible until we know which varobjs with destructors are
       * freed.
       */
      for( i=0;i<global->destructorCount;i++ )
         mark_object(global->hDestructors[i]);

      /* sweep unused stuff onto the free lists */
      sweep(call);

#     ifndef NDEBUG
         assertNothingIsMarked(call);
#     endif
   }
   else
   {
      /* just collectRefill the allocator pools */
   }

#  if 0==JSE_DONT_POOL
      /* collectRefill the allocator pools so the destructors have the needed structures
       * to allocate.
       */
      collectRefill(call);
#  endif

#  ifndef NDEBUG
      assertFreeBitsMatchFreeSize(call);
#  endif

   global->collect_disable--;

   destructors(call);
}


/* ---------------------------------------------------------------------- */

   hSEObject
seobjNew(struct Call *call,jsebool ordered)
{
   struct Global_ *global = call->Global;
   hSEObject hobj;
   wSEObject wobj;

#  if 0==JSE_DONT_POOL
      if( global->objPoolCount==0 ) garbageCollect(call);
      assert( global->objPoolCount>0 );
      hobj = global->hobj_pool[--global->objPoolCount];
#  else
      hobj = seobjectAlloc();
      assert( NULL != hobj );      
#  endif   
   
   /* initialize the object */
   SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
#  if 0!=JSE_PER_OBJECT_CACHE
      SEOBJECT_PTR(wobj)->cache = 0;
#  endif
   SEOBJECT_PTR(wobj)->used = 0;
   SEOBJECT_PTR(wobj)->flags = ordered ? 0 : SEOBJ_DONT_SORT ;
#  if (0!=JSE_OBJECTDATA)
   SEOBJECT_PTR(wobj)->data = NULL;
#  endif
#  if defined(JSE_DYNAMIC_OBJS)
   SEOBJECT_PTR(wobj)->callbacks = NULL;
#  endif
   SEOBJECT_PTR(wobj)->func = NULL;
#  if JSE_PACK_OBJECTS==0
   SEOBJECT_PTR(wobj)->alloced = OBJ_DEFAULT_SIZE;

   if( SEOBJECT_PTR(wobj)->alloced )
   {
#ifdef MEM_TRACKING
#  if 0==JSE_DONT_POOL
    if (call->Global->memPoolCount==0)
#  endif
    {
      call->Global->all_mem_count++;
      if (call->Global->all_mem_count > call->Global->all_mem_maxCount)
   	  call->Global->all_mem_maxCount = call->Global->all_mem_count;
      call->Global->all_mem_size += sizeof(struct _SEObjectMem)*OBJ_DEFAULT_SIZE;
      if (call->Global->all_mem_size > call->Global->all_mem_maxSize)
	  call->Global->all_mem_maxSize = call->Global->all_mem_size;
    }
#endif
      SEOBJECT_PTR(wobj)->hsemembers =
#   if 0==JSE_DONT_POOL
         (global->memPoolCount!=0)
         ? global->mem_pool[--global->memPoolCount] :
#   endif
#   if JSE_MEMEXT_MEMBERS==0
      jseMustMalloc(struct _SEObjectMem,sizeof(struct _SEObjectMem)*OBJ_DEFAULT_SIZE) ;
#   else
      semembersAlloc(OBJ_DEFAULT_SIZE) ;
#   endif
   }
   else
#  endif
   {
      SEOBJECT_PTR(wobj)->hsemembers = hSEMembersNull;
   }
   
   SEOBJECT_UNLOCK_W(wobj);

   return hobj;
}

   seString NEAR_CALL
sestrCreateAllocated(struct Call *call,const void *mem,JSE_POINTER_UINDEX len,
#                    if defined(JSE_MBCS) && (JSE_MBCS!=0)
                        JSE_POINTER_UINDEX bytelen,
#                    endif
                    jsebool buffer)
{
   struct Global_ *global = call->Global;
   struct seString *ret = jseMustMalloc(struct seString,sizeof(struct seString));
#  if !defined(JSE_MBCS) || JSE_MBCS==0
   JSE_POINTER_UINDEX bytelen;
#  endif

#  if !defined(JSE_MBCS) || JSE_MBCS==0
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( buffer )
      {
         bytelen = len;
      }
      else
#  endif
      {
         bytelen = BYTECOUNT_FROM_STRLEN((jsecharptr)string,len);
      }
#  endif

   global->stringallocs += bytelen+40/*overhead estimate*/;
#  if JSE_ALWAYS_COLLECT==0
   if( global->stringallocs>=JSE_STRINGS_COLLECT )
#  endif
   {
      global->stringallocs = 0;
      garbageCollect(call);
   }

   ret->length = len;
#if defined(JSE_MBCS) && (JSE_MBCS!=0)
   ret->bytelength = bytelen;
#endif
   ret->flags = 0;
   ret->zoffset = 0;
   
   SESTRING_PUT_DATA(ret,(void *)mem,bytelen+sizeof(jsechar));

   /* Link it in */
   ret->prev = global->stringdatas;
   global->stringdatas = ret;

   return ret;
}


/* A string is a literal we are trying to update, make a copy of it
 * to update
 */
   void NEAR_CALL
sevarDuplicateString(struct Call *call,wSEVar wSrcVar)
{
   struct seString *old = wSrcVar->data.string_val.data;
   void _HUGE_ * newmem;
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      JSE_POINTER_UINDEX len = old->bytelength;
#  else
      JSE_POINTER_UINDEX len = old->length;
#  endif
   JSE_POINTER_UINDEX copyLen;
   JSE_MEMEXT_R void *data;
   
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
      copyLen = len + sizeof(jsecharptrdatum);
#  elif defined(JSE_UNICODE) && (JSE_UNICODE!=0)
      copyLen = ( len + 1 ) * sizeof(jsechar);
#  else /* ascii */
      copyLen = len + 1;
#  endif

#  ifdef HUGE_MEMORY
   assert( copyLen<HUGE_MEMORY );
#  endif
   newmem = jseMalloc(void,(size_t)copyLen);
   if( newmem==NULL )
   {
      garbageCollect(call);
      newmem = jseMustMalloc(void,(size_t)copyLen);
   }

   /* the source is string, so it will already have a null at the end, so
    * don't need to explicitly add a null because it is already there!
    */
   data = SESTRING_GET_DATA(old);
   HugeMemCpy(newmem,data,copyLen);
   SESTRING_UNGET_DATA(old,data);
   assert( '\0' == JSECHARPTR_GETC(JSECHARPTR_OFFSET((jsecharptr)newmem,len)) );

#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      wSrcVar->data.string_val.data = sestrCreateAllocated(call,newmem,old->length,len,False);
#  else
      wSrcVar->data.string_val.data =  sestrCreateAllocated(call,newmem,(JSE_POINTER_UINDEX)len,False);
#  endif
}

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   seString NEAR_CALL
sestrCreateBuffer(struct Call *call,const void *mem,JSE_POINTER_UINDEX len)
{
   void _HUGE_ * newmem;

   newmem = jseMalloc(void,len+sizeof(jsechar));
   if( newmem==NULL )
   {
      garbageCollect(call);
      newmem = jseMustMalloc(void,len+sizeof(jsechar));
   }

   memcpy(newmem,mem,len);
   ((ubyte *)newmem)[len] = '\0';

#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      return sestrCreateAllocated(call,newmem,len,len,True);
#  else
      return sestrCreateAllocated(call,newmem,len,True);
#  endif
}
#endif

#if defined(JSE_MBCS) && (JSE_MBCS!=0)
   seString NEAR_CALL sestrCreate(struct Call *call,const void *mem,JSE_POINTER_UINDEX len,
                                  JSE_POINTER_UINDEX bytelen)
#else
   seString NEAR_CALL sestrCreate(struct Call *call,const void *mem,JSE_POINTER_UINDEX len)
#endif
{
#  if !defined(JSE_MBCS) || JSE_MBCS==0
   JSE_POINTER_UINDEX bytelen;
#  endif
   void _HUGE_ * newmem;

#  if !defined(JSE_MBCS) || JSE_MBCS==0
   bytelen = BYTECOUNT_FROM_STRLEN((jsecharptr)string,len);
#  endif


   newmem = jseMalloc(void,bytelen+sizeof(jsechar));
   if( newmem==NULL )
   {
      garbageCollect(call);
      newmem = jseMustMalloc(void,bytelen+sizeof(jsechar));
   }
   memcpy(newmem,mem,bytelen);

#if defined(JSE_MBCS) && (JSE_MBCS!=0)
   *(jsechar *)(((ubyte *)newmem)+bytelen) = '\0';
   return sestrCreateAllocated(call,newmem,len,bytelen,False);
#else
   *(jsecharptr)(((ubyte *)newmem)+bytelen) = '\0';
   return sestrCreateAllocated(call,newmem,len,False);
#endif
}


   void *
jseMallocWithGC(struct Call *call,uint size)
{
   void *mem;


#  ifdef HUGE_MEMORY
   assert( size<HUGE_MEMORY );
#  endif
   mem = jseMalloc(void,size);
   if( mem==NULL )
   {
      garbageCollect(call);
      mem = jseMalloc(void,size);
   }

   if( mem==NULL )
   {
      callQuit(call,textcoreOUT_OF_MEMORY);
   }

   return mem;
}



#  ifdef JSE_MEM_SUMMARY
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
extern VAR_DATA(struct AnalMalloc *) RecentMalloc;
extern VAR_DATA(ulong) TotalMemoryAllocated;
extern VAR_DATA(ulong) TotalMemoryAllocations;
extern VAR_DATA(ulong) MaxTotalMemoryAllocated;
extern VAR_DATA(ulong) MaxTotalMemoryAllocations;

   void
memDump(struct Call *call)
{
   struct AnalMalloc *AM;
   ulong stable_count = 0,stable_mem = 0;
   ulong misc_count = 0,misc_mem = 0;
   ulong sdata_count = 0,sdata_mem = 0;
   ulong sdesc_count = 0,sdesc_mem = 0;
   ulong objmem_count = 0,objmem_mem = 0;
   ulong object_count = 0,object_mem = 0;
#  if 0==JSE_DONT_POOL   
      ulong argvpool_count = 0,argvpool_mem = 0;
#  endif      
   ulong libfunc_count = 0,libfunc_mem = 0;
   ulong locfunc_count = 0,locfunc_mem = 0;
   ulong strcpy_count = 0,strcpy_mem = 0;
   ulong desttable_count = 0,desttable_mem = 0;
   ulong gstack_count = 0,gstack_mem = 0;
   ulong global_count = 0,global_mem = 0;
   ulong cenvi_count = 0,cenvi_mem = 0;
   ulong total_count = 0,total_mem = 0;
   
   for ( AM = RecentMalloc; NULL != AM; AM = AM->Prev )
   {
      if( AM->line==434 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
#        if 0
         struct HashList *hl = (struct HashList *)AM->data;
         printf("String table entry: %s\n",VarNameFromHashList(hl));
#        endif
         stable_count++; stable_mem += AM->size;
      }
      else if( AM->line==1245 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         stable_count++; stable_mem += AM->size;
      }
      else if( AM->line==1228 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         global_count++; global_mem += AM->size;
      }
      else if( AM->line==1210 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         global_count++; global_mem += AM->size;
      }
      else if( AM->line==313 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\call.c")==0 )
      {
         gstack_count++; gstack_mem += AM->size;
      }
      else if( AM->line==1280 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         gstack_count++; gstack_mem += AM->size;
      }
      else if( AM->line==1580 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\jselib.c")==0 )
      {
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==1568 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\jselib.c")==0 )
      {
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==1363 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\varutil.c")==0 )
      {
         /* obj member realloc */
         objmem_count++; objmem_mem += AM->size;
      }
      else if( AM->line==1353 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\varutil.c")==0 )
      {
         /* obj member first alloc alternate */
         objmem_count++; objmem_mem += AM->size;
      }
      else if( AM->line==2405 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         /* expand vlibfunc */
         libfunc_count++; libfunc_mem += AM->size;
      }
      else if( AM->line==2450 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         /* regular function */
         libfunc_count++; libfunc_mem += AM->size;
      }
      else if( AM->line==40 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\loclfunc.c")==0 )
      {
         /* local function structure */
         locfunc_count++; locfunc_mem += AM->size;
      }
      else if( AM->line==86 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\loclfunc.c")==0 )
      {
         /* realloc tokens */
         locfunc_count++; locfunc_mem += AM->size;
      }
      else if( AM->line==244 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\loclfunc.c")==0 )
      {
         /* realloc arrays */
         locfunc_count++; locfunc_mem += AM->size;
      }
      else if( AM->line==157 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\loclfunc.c")==0 )
      {
         locfunc_count++; locfunc_mem += AM->size;
      }
      else if( AM->line==1471 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\expressn.c")==0 )
      {
         locfunc_count++; locfunc_mem += AM->size;
      }
#     if 0==JSE_DONT_POOL      
      else if( AM->line==1298 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\util.c")==0 )
      {
         argvpool_count++; argvpool_mem += AM->size;
      }
#     endif      
      else if( AM->line==698 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         /* allocate object */
         object_count++; object_mem += AM->size;
      }
      else if( AM->line==1062 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         objmem_count++; objmem_mem += AM->size;
      }
      else if( AM->line==1157 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==1220 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         /* create buffer */
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==880 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         /* create buffer */
         desttable_count++; desttable_mem += AM->size;
      }
      else if( AM->line==234 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\var.c")==0 )
      {
         /* realloc of string data */
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==63 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\varutil.c")==0 )
      {
         sdata_count++; sdata_mem += AM->size;
      }
      else if( AM->line==1085 && strcmp(AM->file,"..\\..\\..\\..\\..\\srccore\\garbage.c")==0 )
      {
         sdesc_count++; sdesc_mem += AM->size;
      }
      else if( AM->line==549 && strcmp(AM->file,"..\\..\\srcmisc\\utilstr.c")==0 )
      {
         strcpy_count++; strcpy_mem += AM->size;
      }
      else if( strstr(AM->file,"srccenvi")!=NULL )
      {
         cenvi_count++; cenvi_mem += AM->size;
      }
      else
      {
         printf(
           UNISTR("Memory Block: Sequence = %lu, size = %u, ptr = %08lX line=%lu of file=%s\n"),
           AM->AllocSequenceCounter,AM->size,AM->data,AM->line,AM->file);
         misc_count++; misc_mem += AM->size;
      }
      total_count++; total_mem += AM->size;
   }

   printf("Objects:                     %04d:%08d\n",object_count,object_mem);
   printf("Object member arrays:        %04d:%08d\n",objmem_count,objmem_mem);
   printf("StringTable entries:         %04d:%08d\n",stable_count,stable_mem);
   printf("String descriptors:          %04d:%08d\n",sdesc_count,sdesc_mem);
   printf("String data:                 %04d:%08d\n",sdata_count,sdata_mem);
   printf("Library functions:           %04d:%08d\n",libfunc_count,libfunc_mem);
   printf("Script functions:            %04d:%08d\n",locfunc_count,locfunc_mem);
#  if 0==JSE_DONT_POOL   
   printf("Argv pool:                   %04d:%08d\n",argvpool_count,argvpool_mem);
#  endif   
   printf("Strcpys:                     %04d:%08d\n",strcpy_count,strcpy_mem);
   printf("Destructor table:            %04d:%08d\n",desttable_count,desttable_mem);
   printf("The secode stack:            %04d:%08d\n",gstack_count,gstack_mem);
   printf("Calls and their global:      %04d:%08d\n",global_count,global_mem);
   printf("Cenvi allocations:           %04d:%08d\n",cenvi_count,cenvi_mem);
   printf("Unknown:                     %04d:%08d\n\n",misc_count,misc_mem);

   printf("Totals:                      %04d:%08d\n",total_count,total_mem);
   printf("Assuming 12 byte overhead per allocation,\n"
          "Total memory used:                %08d\n\n",12*total_count+total_mem);
   printf("Maximum:                     %04d:%08d\n",MaxTotalMemoryAllocations,MaxTotalMemoryAllocated);
   printf("Assuming 12 byte overhead per allocation,\n"
          "Max total memory used:            %08d\n",12*MaxTotalMemoryAllocations+MaxTotalMemoryAllocated);
}
#  endif
