/* call.c   Routines for calling function as well as initializing
 *          a new interpret.
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


/* Overview of calls as of SE430:
 *
 * SE430 sees massive simplification. Each call structure
 * tracks an Interpret only. Every time we call 'jseInterpret'
 * (or via script with eval), we create a new call structure
 * and populate it. There also is one main context created
 * when the whole thing is 'jseInitializeExternalLink'ed.
 *
 * Functions no longer need to create a whole new call.
 * For calling functions, we have a few needed fields to
 * keep up-to-the-minute information. A main one is the
 * frame pointer. It is the location on the secode stack where
 * we can find most of the other information, like parameters,
 * locals, the function being executed, the 'this' variable,
 * etc. On the stack also are a few bits of information we
 * deem necessary to save in the call, but for the previous
 * function. We store the old values on the stack and replace
 * them with new ones while a new function is being executed,
 * then restore them when going back a level. The most
 * important of these is, obviously, the previous frame pointer.
 *
 * Note that calling a wrapper function is done immediately,
 * after we build the new stack frame, we just call the wrapper
 * function directly, then undo the frame and return. For script
 * functions, we set everything up to go into the new
 * function, so that further calls to secodeInterpret() will
 * pick up in the right place.
 *
 * See call.h, struct Call entry 'fptr' for the frame format.
 *
 * see callFunction() and callReturnFromFunction() in this file.
 */


#include "srccore.h"


/*
 * Find the parents of a given object and add them to a particular
 * scope object. You must have create a ScopeChain already to add
 * these to.
 */
#if defined(SEOBJ_FLAG_BIT)
   static void NEAR_CALL
callImplicitParents(struct Call *call,hSEObject hThis,wSEObject wScopeChain)
{
   MemCountUInt count, end;
   rSEObjectMem rParentObjectmem, rNextParentObjectmem;
   wSEObject wThis;
   wSEMembers wScopeMembers;

   count = SEOBJECT_PTR(wScopeChain)->used;

   SEOBJECT_ASSIGN_LOCK_W(wThis,hThis);
   /* Note: we don't add the 'this', only the parents. 'this' does
    *       get added later if jseImplicitThis
    */
   SEOBJ_MARK_FLAGGED(wThis);
   rParentObjectmem = rseobjGetMemberStruct(call,SEOBJECT_CAST_R(wThis),
                                           STOCK_STRING(__parent__));
   while ( NULL != SEOBJECTMEM_PTR(rParentObjectmem) )
   {
      rSEVar parent = SEOBJECTMEM_VAR(rParentObjectmem);
      SEOBJECTMEM_PTR(rNextParentObjectmem) = NULL;  /* assume failure on next parent */

      if( SEVAR_GET_TYPE(parent)==VObject )
      {
         wSEObject wParentObj;

         SEOBJECT_ASSIGN_LOCK_W(wParentObj,SEVAR_GET_OBJECT(parent));

         if( !SEOBJ_WAS_FLAGGED(wParentObj) )
         {
            rSEObject rObj;

            SEOBJECT_ASSIGN_LOCK_R(rObj,SEVAR_GET_OBJECT(parent));

            SEOBJ_MARK_FLAGGED(wParentObj);

            seobjCreateMemberCopy(NULL,call,wScopeChain,NULL,parent);
            rNextParentObjectmem = rseobjGetMemberStruct(call,rObj,
                                                         STOCK_STRING(__parent__));
            SEOBJECT_UNLOCK_R(rObj);
         }
         SEOBJECT_UNLOCK_W(wParentObj);
      }
      SEOBJECTMEM_UNLOCK_R(rParentObjectmem);
      rParentObjectmem = rNextParentObjectmem;
   }

   /* unmark them */
   SEOBJ_MARK_NOT_FLAGGED(wThis);
   rParentObjectmem = rseobjGetMemberStruct(call,SEOBJECT_CAST_R(wThis),
                                           STOCK_STRING(__parent__));
   while ( NULL != SEOBJECTMEM_PTR(rParentObjectmem) )
   {
      rSEVar parent = SEOBJECTMEM_VAR(rParentObjectmem);
      SEOBJECTMEM_PTR(rNextParentObjectmem) = NULL;  /* assume failure on next parent */

      if( SEVAR_GET_TYPE(parent)==VObject )
      {
         wSEObject wParentObj;

         SEOBJECT_ASSIGN_LOCK_W(wParentObj,SEVAR_GET_OBJECT(parent));

         if( SEOBJ_WAS_FLAGGED(wParentObj) )
         {
            rSEObject rObj;

            SEOBJECT_ASSIGN_LOCK_R(rObj,SEVAR_GET_OBJECT(parent));

            SEOBJ_MARK_NOT_FLAGGED(wParentObj);

            seobjCreateMemberCopy(NULL,call,wScopeChain,NULL,parent);
            rNextParentObjectmem = rseobjGetMemberStruct(call,rObj,
                                                        STOCK_STRING(__parent__));
            SEOBJECT_UNLOCK_R(rObj);
         }
         SEOBJECT_UNLOCK_W(wParentObj);
      }
      SEOBJECTMEM_UNLOCK_R(rParentObjectmem);
      rParentObjectmem = rNextParentObjectmem;
   }

   SEOBJECT_UNLOCK_W(wThis);

   /* The parents are put on the ScopeChain in the wrong order, reverse
    * them.
    */
   if (count != 0)
   {
     SEMEMBERS_ASSIGN_LOCK_W(wScopeMembers,SEOBJECT_PTR(wScopeChain)->hsemembers);
     for ( end = SEOBJECT_PTR(wScopeChain)->used; count < --end; count++ )
     {
      struct _SEVar tmp = SEMEMBERS_PTR(wScopeMembers)[count].value;
      SEMEMBERS_PTR(wScopeMembers)[count].value = SEMEMBERS_PTR(wScopeMembers)[end].value;
      SEMEMBERS_PTR(wScopeMembers)[end].value = tmp;
     }
   SEMEMBERS_UNLOCK_W(wScopeMembers);
   }
}
#else /* #if defined(SEOBJ_FLAG_BIT) */
   static void NEAR_CALL
callImplicitParentsRecurse(struct Call *call,hSEObject hObj,wSEObject wScopeChain,
                           struct VarRecurse *prev)
{
   rSEObject rObj;
   rSEObjectMem rParentMem;

   SEOBJECT_ASSIGN_LOCK_R(rObj,hObj);
   rParentMem = rseobjGetMemberStruct(call,rObj,STOCK_STRING(__parent__));
   if ( NULL != SEOBJECTMEM_PTR(rParentMem) )
   {
      if ( VObject == SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rParentMem)) )
      {
         hSEObject hParentObj = SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(rParentMem));
         struct VarRecurse myRecurse;

         CHECK_FOR_RECURSION(prev,myRecurse,hParentObj)
         if ( !ALREADY_BEEN_HERE(myRecurse) )
         {
            /* call this function recursively to add next level of parent chain */
            callImplicitParentsRecurse(call,hParentObj,wScopeChain,&myRecurse);

            /* add this parent obj onto the parent chain */
            seobjCreateMemberCopy(NULL,call,wScopeChain,NULL,SEOBJECTMEM_VAR(rParentMem));
         }
      }
      SEOBJECTMEM_UNLOCK_R(rParentMem);
   }
   SEOBJECT_UNLOCK_R(rObj);
}
#define callImplicitParents(CALL,HOBJ,SCOPECHAIN) \
        callImplicitParentsRecurse((CALL),(HOBJ),(SCOPECHAIN),NULL)
#endif /* #if defined(SEOBJ_FLAG_BIT) */

/* ---------------------------------------------------------------------- */

/* The same as callFunction(), but if a script function, continue
 * until it returns. The result is as always the TOS (top of stack)
 */
   void NEAR_CALL
callFunctionFully(struct Call *call,uword16 num_args,jsebool constructor)
{
   wSEVar old_fptr = FRAME;
   wSEVar new_fptr;
   uword32 old_count = call->continue_count;

   /* make sure it drops back out to us */
   call->continue_count = 1;

   callFunction(call,num_args,constructor);
   while( NULL!=(new_fptr=FRAME) && new_fptr!=old_fptr )
   {
      assert( old_fptr<FRAME );
      secodeInterpret(call);
      if( !callMayIContinue(call) )
      {
         /* in case we are in the middle of a function that has not yet
          * properly set up its return value, give it something.
          */
         wSEVar ret = STACK_PUSH;
         SEVAR_INIT_UNDEFINED(ret);
         while( old_fptr!=FRAME )
         {
            callReturnFromFunction(call);
         }
         break;
      }
   }

   call->continue_count = old_count;
}


/* Call a new function. The top items of the stack are the
 * arguments, the function to be called (top of stack after args)
 * and the 'this' object (just below it). You can compare
 * the current FRAME to the one before calling this to determine
 * when the function completes, see callFunctionFully() above.
 */
   void NEAR_CALL
callFunction(struct Call *call,uword16 num_args,jsebool constructor)
{
   /* see call.h for a description of the stack frame format.
    * Otherwise, these won't make much sense.
    */
   rSEVar funcvar;
   struct Function *func;
   wSEVar wThisVar;
   jsebool islocal;
   jsebool isinit;
   wSEVar wTmpVar;
   uint count;
   uword16 true_args;
   rSEObject robj;
   wSEObject wScopeChain;
   wSEObjectMem wMemTmp;

   funcvar = STACKX(num_args);
   assert( SEVAR_GET_TYPE(funcvar)==VObject );
   SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(funcvar));
   func = SEOBJECT_PTR(robj)->func;
   SEOBJECT_UNLOCK_R(robj);
   wThisVar = STACKX(1+num_args);
   assert( SEVAR_GET_TYPE(wThisVar)==VObject );
   islocal = FUNCTION_IS_LOCAL(func);
   isinit = islocal && LOCAL_TEST_IF_INIT_FUNCTION(((struct LocalFunction *)func),call);
   true_args = num_args;


   /* any variables specified to the function but not passed
    * are treated as undefined.
    */
   if( islocal )
   {
      while( num_args<((struct LocalFunction *)func)->InputParameterCount )
      {
         wTmpVar = STACK_PUSH;
         SEVAR_INIT_UNDEFINED(wTmpVar);
         num_args++;
      }
   }

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   if( !checkSecurity(call,funcvar,num_args) )
   {
      /* return the top of the stack, which will be the
       * appropriate error, and discard all the stack parameters.
       */
      wTmpVar = STACK0;
      SEVAR_COPY(wThisVar,wTmpVar);
      call->stackptr = STACKPTR_SAVE(wThisVar);
      return;
   }
#  endif

   if ( islocal )
   {
#     if defined(JSE_GROWABLE_STACK) && JSE_GROWABLE_STACK==1
         if( (call->Global->length - call->stackptr) <
             (uword16)(100 + ((struct LocalFunction *)func)->max_params) )
         {
            call->Global->length += 100 + ((struct LocalFunction *)func)->max_params;
            call->Global->growingStack =
               jseMustReMalloc(struct _SEVar,call->Global->growingStack,
                               call->Global->length * sizeof(struct _SEVar));
         }
#     else
      {
         sint stackUsed = STACK0 - call->Global->stack +
            100 + ((struct LocalFunction *)func)->max_params;
         if ( isinit )
         {
            /* locals go in global object for init function, not on stack */
            stackUsed += ((struct LocalFunction *)func)->num_locals;
         }
         if ( SE_STACK_SIZE <= stackUsed )
         {
            callQuit(call,textcoreSTACK_OVERFLOW);
            return;
         }
      }
#     endif
   }

#  if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
      wTmpVar = STACK_PUSH;
      SEVAR_INIT_STORAGE_LONG(wTmpVar,(ulong)call->useCache);
#  endif

   wTmpVar = STACK_PUSH;
   SEVAR_COPY(wTmpVar,&(call->new_scope_chain));

   wTmpVar = STACK_PUSH;
   if( constructor )
   {
      /* return the 'this' by default if this is a constructor */
      SEVAR_COPY(wTmpVar,wThisVar);
   }
   else
   {
      SEVAR_INIT_UNDEFINED(wTmpVar);
   }

#  if JSE_MEMEXT_SECODES==1
   {
      wSEVar tmp;
      /* save last instruction pointer */
      tmp = STACK_PUSH;
      /* store the offset instead of the raw ptr */
      SEVAR_INIT_STORAGE_LONG(tmp,call->iptr - call->base);
      /* if currently a local function, unlock its codes */
      if( call->funcptr!=NULL && FUNCTION_IS_LOCAL(call->funcptr) )
      {
         jsememextUnlockRead(((struct LocalFunction *)call->funcptr)->op_handle,
                             call->base,jseMemExtSecodeType);
      }
      /* lock the new function's codes */
      if( islocal )
      {
         /* lock new codes */
         call->iptr = call->base =
            jsememextLockRead(((struct LocalFunction *)func)->op_handle,jseMemExtSecodeType);
      }
   }
#  else
      /* save last instruction pointer */
      wTmpVar = STACK_PUSH;
      SEVAR_INIT_STORAGE_PTR(wTmpVar,(void *)call->iptr);
      if( islocal )
      {
         call->iptr = ((struct LocalFunction *)func)->opcodes;
      }
#  endif
   /* save the number of arguments passed */
   wTmpVar = STACK_PUSH;
   SEVAR_INIT_STORAGE_LONG(wTmpVar,call->true_args);
   call->true_args = true_args;
   wTmpVar = STACK_PUSH;
   SEVAR_INIT_STORAGE_LONG(wTmpVar,call->num_args);
   call->num_args = num_args;
   /* save the previous VariableObject */
   wTmpVar = STACK_PUSH;
   SEVAR_INIT_OBJECT(wTmpVar,call->hVariableObject);

   if( isinit )
   {
      /* else we inherit the past variable object, either the global
       * or the caller's
       */
      if( call->hVariableObject == hSEObjectNull )
         call->hVariableObject = CALL_GLOBAL(call);
   }
   else if( islocal )
   {
      call->hVariableObject = hSEObjectNull;
   }
   /* last case is calling a wrapper function, in which case
    * we keep the same variable object
    */


   /* save the previous ftpr */
   wTmpVar = STACK_PUSH;
#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
      SEVAR_INIT_STORAGE_LONG(wTmpVar,call->frameptr);
#  else
      SEVAR_INIT_STORAGE_PTR(wTmpVar,FRAME);
#  endif
   call->frameptr = STACKPTR_SAVE(wTmpVar);

   call->funcptr = func;

   if( islocal )
   {
      struct LocalFunction *lfunc = (struct LocalFunction *)func;

#     if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
         /* We can't use the cache if this function would search anything
          * before the global, i.e. implicit stuff or if it has a
          * saved scope chain. The implicit stuff is checked below.
          */
         call->useCache = ((FUNCVAR)->data.object_val.hSavedScopeChain == hSEObjectNull);
         if( CALL_GLOBAL(call)!=call->hGlobalObject )
            call->useCache = False;
#     endif

      SEOBJECT_ASSIGN_LOCK_R(robj,lfunc->hConstants);
      call->hConstants = SEOBJECT_PTR(robj)->hsemembers;
      SEOBJECT_UNLOCK_R(robj);

      SEOBJECT_ASSIGN_LOCK_W(wScopeChain,call->hScopeChain);

      /* mark out a new section of the scope chain */
      wMemTmp = seobjCreateMemberType(call,wScopeChain,NULL,VNull);

      SEOBJECTMEM_UNLOCK_W(wMemTmp);

      /* If we are inheriting stuff, do that now */
      if( isinit  &&  call->pastGlobals  &&  call->prev!=NULL )
      {
         hSEObject hssc;

         /* NOTE: the scope chain is like a stack, the last entries are
          * searched first.
          */

         if( CALL_GLOBAL(call->prev)!=CALL_GLOBAL(call) )
         {
            wMemTmp = SEOBJ_CREATE_MEMBER(call,wScopeChain,NULL);
            SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wMemTmp),CALL_GLOBAL(call));
            SEOBJECTMEM_UNLOCK_W(wMemTmp);
         }

         /* Add the saved scope chain */

         if( FRAMECALL(call->prev)!=NULL
          && (hssc = (FUNCVARCALL(call->prev))->data.object_val.hSavedScopeChain)!=hSEObjectNull )
         {
            MemCountUInt lookin;
            rSEObject rssc;

            SEOBJECT_ASSIGN_LOCK_R(rssc,hssc);

            /* we need to add them in reverse order of the way they will
             * be searched (i.e. add the last to be searched first.
             * Since the saved scope chain is the opposite order,
             * we copy the end of it first/
             */
            for( lookin=0;lookin<SEOBJECT_PTR(rssc)->used;lookin++ )
            {
               rSEVar vr;
               rSEObjectMem rMem = rseobjIndexMemberStruct(call,rssc,lookin);

               assert( NULL != SEOBJECTMEM_PTR(rMem) );
               vr = SEOBJECTMEM_VAR(rMem);
               assert( SEVAR_GET_TYPE(vr)==VObject );
               seobjCreateMemberCopy(NULL,call,wScopeChain,NULL,vr);
               SEOBJECTMEM_UNLOCK_R(rMem);
            }
            SEOBJECT_UNLOCK_R(rssc);
         }

         /* copy all scope chain entries. Note that the global variable
          * is never explicitly enterred into these scope chains, it
          * is always assumed, which is why we need the above code.
          * Even in this case, the past global is thrown on, but our
          * current global is still just 'assumed'.
          */
         if( call->prev->hScopeChain!=hSEObjectNull )
         {
            rSEObject robj;
            MemCountUInt count;

            SEOBJECT_ASSIGN_LOCK_R(robj,call->prev->hScopeChain);
            count = SEOBJECT_PTR(robj)->used;
            if ( 0 != count )
            {
               rSEMembers rMembers;

               SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);

               /* We see all the stuff in the scope chain of our caller.
                * In this case, the caller is the past interpret level
                */
               while( count>0 )
               {
                  count--;
                  if( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(rMembers)[count].value))==VNull )
                     break;
               }
               assert( NULL != SEMEMBERS_PTR(rMembers) );
               if( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(rMembers)[count].value))==VNull )
               {
                  /* ok, there is a past scope chain to copy, do so */
                  while( ++count<SEOBJECT_PTR(robj)->used )
                  {
                     /* The past variable object should have been expanded during
                      * the call, thus it should not be VUndefined (i.e. waiting to
                      * be filled in if ever used) - it IS being used!
                      *
                      * Don't just create it here. It should have already been
                      * created, so this is a bug.
                      */
                     assert( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(rMembers)[count].value))!=VUndefined );

                     /* copy them forward to our new scope chain so they
                      * end up in the same order
                      */
                     seobjCreateMemberCopy(NULL,call,wScopeChain,NULL,
                                           &(SEMEMBERS_PTR(rMembers)[count].value));

#                    if JSE_CACHE_GLOBAL_VARS==1
                        /* actually copied something before the global in the
                         * scope chain, so cannot use cache.
                         */
                        call->useCache = False;
#                    endif
                  }
               }
               SEMEMBERS_UNLOCK_R(rMembers);
            }
            SEOBJECT_UNLOCK_R(robj);
         }
      }


      /* If we are doing implicit X, add those to the scope chain now. */

      if( func->attributes & jseImplicitParents )
      {
         callImplicitParents(call,SEVAR_GET_OBJECT(wThisVar),wScopeChain);
#        if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
            call->useCache = False;
#        endif
      }
      if( func->attributes & jseImplicitThis )
      {
         wMemTmp = SEOBJ_CREATE_MEMBER(call,wScopeChain,NULL);
         SEVAR_COPY(SEOBJECTMEM_VAR(wMemTmp),wThisVar);
#        if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
            call->useCache = False;
#        endif
         SEOBJECTMEM_UNLOCK_W(wMemTmp);
      }

      /* throw the initially uncreated VariableObject on the scope chain.
       * The initialization function doesn't have a variable object, it
       * is either inheriting the last function's, or it is the global.
       * No 'new' space to warrent making a scope chain entry for it.
       */
      if( !isinit )
      {
         wMemTmp = seobjCreateMemberType(call,wScopeChain,NULL,VUndefined);
         SEOBJECTMEM_UNLOCK_W(wMemTmp);
      }


      /* all variables are initialized as undefined when the scope is enterred but
       * receive their actual initialization when that section of the code is
       * encountered. This does the initial creation to Undefined (section 12.2)
       */
      for( count = 0;count<lfunc->num_locals;count++ )
      {
         VarName ourname = lfunc->items[lfunc->InputParameterCount+count].VarName;
         sint constant;
         hSEObject hif_func;

         if( (constant = lfunc->items[lfunc->InputParameterCount+count].VarFunc)==-1 )
         {
            hif_func = hSEObjectNull;
         }
         else
         {
            {
               /* following code just to get hif_func -- only expands for memory extensions */
               rSEObject robj;
               rSEMembers rMembers;
               SEOBJECT_ASSIGN_LOCK_R(robj,lfunc->hConstants);
               SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);
               hif_func = SEVAR_GET_OBJECT(&(SEMEMBERS_PTR(rMembers)[constant].value));
               SEMEMBERS_UNLOCK_R(rMembers);
               SEOBJECT_UNLOCK_R(robj);
            }

            if( hif_func && SEVAR_GET_TYPE(&(call->new_scope_chain))==VUndefined && !isinit )
            {
               MemCountUInt index;
               wSEObject wNewScopeChain;
               rSEMembers rMembers;

               if( call->hVariableObject==hSEObjectNull )
                  callCreateVariableObject(call,NULL);
               assert( call->hVariableObject!=hSEObjectNull );

               SEVAR_INIT_UNORDERED_OBJECT(call,&(call->new_scope_chain));

               /* Build the saved scope chain up from the end of the scope
                * chain stack, so it will be in the regular order (i.e. the
                * first member should be the first item searched, etc.
                */
               index = SEOBJECT_PTR(wScopeChain)->used;
               SEOBJECT_ASSIGN_LOCK_W(wNewScopeChain,SEVAR_GET_OBJECT(&(call->new_scope_chain)));
               SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(wScopeChain)->hsemembers);
               while( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(rMembers)[--index].value))!=VNull )
               {
                  wSEObjectMem wMem;
                  assert( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(rMembers)[index].value))==VObject );
                  wMem = SEOBJ_CREATE_MEMBER(call,wNewScopeChain,NULL);
                  SEVAR_COPY(SEOBJECTMEM_VAR(wMem),&(SEMEMBERS_PTR(rMembers)[index].value));
                  SEOBJECTMEM_UNLOCK_W(wMem);
               }
               SEMEMBERS_UNLOCK_R(rMembers);
               SEOBJECT_UNLOCK_W(wNewScopeChain);
            }
         }

         if( isinit )
         {
            wSEVar wLoc = STACK_PUSH;
            wSEVar wTmp = STACK_PUSH;

            SEVAR_INIT_UNDEFINED(wTmp);
            SEVAR_INIT_OBJECT(wLoc,call->hVariableObject);
            GetDotNamedVar(call,wLoc,GetStringTableEntry(call,ourname,NULL),False);
            if( hif_func!=hSEObjectNull )
            {
               SEVAR_INIT_OBJECT(wTmp,hif_func);
               wTmp->data.object_val.hSavedScopeChain = hSEObjectNull;
               if ( VObject == SEVAR_GET_TYPE(&(call->new_scope_chain)) )
               {
                  hSEObject hobj;
                  rSEObject robj;
                  hobj = SEVAR_GET_OBJECT(&(call->new_scope_chain));
                  assert( hSEObjectNull != hobj );
                  SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
                  if ( 0 < SEOBJECT_PTR(robj)->used )
                  {
                     wTmp->data.object_val.hSavedScopeChain = hobj;
                  }
                  SEOBJECT_UNLOCK_R(robj);
               }
               SEVAR_DO_PUT(call,wLoc,wTmp);
            }
	    else
	    {
	       SEVAR_INIT_UNDEFINED(wTmp);
	       SEVAR_DO_PUT(call,wLoc,wTmp);
	    }
            /* no need to set the attributes directly, the variable object
             * cannot be referenced by the script, which makes it
             * effectively 'DontDelete'.
             */
            STACK_POPX(2);
         }
         else
         {
            /* make space for the local variable on the stack */
            wSEVar wv = STACK_PUSH;
            if( hif_func!=hSEObjectNull )
            {
               SEVAR_INIT_OBJECT(wv,hif_func);
               wv->data.object_val.hSavedScopeChain =
                  SEVAR_GET_OBJECT(&(call->new_scope_chain));
            }
            else
            {
               SEVAR_INIT_UNDEFINED(wv);
            }
         }
      }
      SEOBJECT_UNLOCK_W(wScopeChain);
      SEVAR_INIT_UNDEFINED(&(call->new_scope_chain));
   }
   else
   {
      struct LibraryFunction *lfunc = (struct LibraryFunction *)func;
      seAPIVar mark = call->tempvars;

      /* In case the wrapper function returns nothing, we have
       * an undefined return. Remember, whatever is at the top
       * of the stack is the return. Thus, put something there.
       * If the wrapper calls jseReturnVar(), that will be
       * put at the top of the stack, this getting preference.
       */
      wTmpVar = STACK_PUSH;
      SEVAR_INIT_UNDEFINED(wTmpVar);

      assert( 0 <= lfunc->FuncDesc->MinVariableCount );
      assert( lfunc->FuncDesc->MinVariableCount <=
              lfunc->FuncDesc->MaxVariableCount  ||
              -1 == lfunc->FuncDesc->MaxVariableCount );
      if ( ( num_args < (uint)(lfunc->FuncDesc->MinVariableCount) )
           || ( (uint)(lfunc->FuncDesc->MaxVariableCount) < num_args
                && -1 != lfunc->FuncDesc->MaxVariableCount
                && !(call->Global->ExternalLinkParms.options & jseOptIgnoreExtraParameters) ) )
      {
         callQuit(call,textcoreINVALID_PARAMETER_COUNT,num_args,
                  lfunc->FuncDesc->FunctionName);
      }
      else
      {
         if( (lfunc->FuncDesc->FuncAttributes & jseFunc_ArgvStyle)!=0 )
         {
            rSEVar rDelVar;
            wSEVar wCP;
            jseVariable *locals;
            uint i;
#           if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
            char *FILE = "ScriptEase runtime engine";
            int LINE = 0;
#        endif
            jsebool alloced = False;


            if( call->num_args>0 )
            {
#              if 0==JSE_DONT_POOL
               if( call->num_args<=ARGV_CALL_POOL_COUNT &&
                   call->Global->argvCallPoolCount>0 )
               {
                  locals = call->Global->argvCallPool[--call->Global->argvCallPoolCount];
               }
               else
#              endif
               {
                  locals = jseMustMalloc(jseVariable,sizeof(jseVariable)*call->num_args);
                  alloced = True;
               }

               for( i=0;i<call->num_args;i++ )
               {
                  locals[i] = SEAPI_RETURN(call,CALL_PARAM(i),FALSE,UNISTR("parameter"));
               }
            }
            else
            {
               /* If no arguments, better than sending a 'blank' array is
                * sending NULL.
                */
               locals = NULL;
            }

            {
               jseVariable variable;

#           if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) &&\
               (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            variable = (jseVariable)DispatchToClient(call->Global->ExternalDataSegment,
                                        (ClientFunction)(lfunc->FuncDesc->FuncPtr),
                                        (void *)call,call->num_args,locals);
#           else
               variable = ((jseArgvLibraryFunction)(((struct LibraryFunction *)func)->
                                                    FuncDesc->FuncPtr))
                  (call,call->num_args,locals);
#     endif

               wCP = STACK_PUSH;
               SEVAR_INIT_UNDEFINED(wCP);
               if( variable!=NULL )
               {
                  rDelVar = seapiGetValue(call,variable);
                  SEVAR_COPY(wCP,rDelVar);
                  if( variable->shouldBeFreed )
                  {
                     seapiDeleteVariable(call,variable);
                  }
               }
            }

            if( alloced )
            {
               jseMustFree(locals);
            }
#           if 0==JSE_DONT_POOL
            else if( call->num_args>0 )
            {
               /* we took one off, there should be space to put it back on! */
               assert( call->Global->argvCallPoolCount<ARGV_CALL_POOL_SIZE );
               call->Global->argvCallPool[call->Global->argvCallPoolCount++] = locals;
            }
#           endif
         }
         else
         {
#     if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) \
       && (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
            DispatchToClient(call->Global->ExternalDataSegment,
                             (ClientFunction)(lfunc->FuncDesc->FuncPtr),
                             (void *)call);
#     else
            (*(lfunc->FuncDesc->FuncPtr))(call);
#     endif
         }
#     if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
         if ( !jseApiOK )
         {
	    jsecharptr fname = functionName(func,call);
            DebugPrintf(UNISTR("Error calling library function \"%s\""),
                        LFOM(fname));
	    UFOM(fname);
            DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
         }
#     endif


         assert( jseApiOK );
      }

      CALL_KILL_TEMPVARS(call,mark);

      callReturnFromFunction(call);
   }
}


/* This is only used to return from local functions */
   void NEAR_CALL
callReturnFromFunction(struct Call *call)
{
   wSEVar wThis = CALL_THIS;
   rSEVar rTmp;
#  if JSE_MEMEXT_SECODES==1
      ulong offset;

      if( call->funcptr!=NULL && FUNCTION_IS_LOCAL(call->funcptr) )
      {
         jsememextUnlockRead(((struct LocalFunction *)call->funcptr)->op_handle,
                             call->base,jseMemExtSecodeType);
      }
#  endif

   /* Pop off scope chain entries until we hit the VNull, which is the
    * marker that we put when calling this function
    */
   if( FUNCTION_IS_LOCAL(FUNCPTR) )
   {
      wSEObject wScopeChain;
      rSEMembers rMembers;

      SEOBJECT_ASSIGN_LOCK_W(wScopeChain,call->hScopeChain);
      SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(wScopeChain)->hsemembers);
      while( SEMEMBERS_PTR(rMembers)[--(SEOBJECT_PTR(wScopeChain)->used)].value.type!=VNull )
        {}
      SEMEMBERS_UNLOCK_R(rMembers);
      SEOBJECT_UNLOCK_W(wScopeChain);
   }

   /* top of stack will be the return value */
   rTmp = STACK0;
   if( SEVAR_GET_TYPE(rTmp)==VUndefined )
   {
      rTmp = OLD_RETURN;
   }
#  if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
      call->useCache = (jsebool)SEVAR_GET_STORAGE_LONG(OLD_USE_CACHE);
#  endif

   SEVAR_COPY(&(call->new_scope_chain),OLD_NEW_SCOPE);
#  if JSE_MEMEXT_SECODES==1
      offset = SEVAR_GET_STORAGE_LONG(OLD_IPTR);
#  else
      call->iptr = SEVAR_GET_STORAGE_PTR(OLD_IPTR);
#  endif
   call->num_args = (uword16)SEVAR_GET_STORAGE_LONG(OLD_ARGS);
   call->true_args = (uword16)SEVAR_GET_STORAGE_LONG(OLD_TRUE_ARGS);
   assert( sizeof(call->hVariableObject) <= sizeof(void *) );
   call->hVariableObject = (hSEObject)SEVAR_GET_STORAGE_PTR(OLD_VAROBJ);
#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
      call->frameptr = SEVAR_GET_STORAGE_LONG(OLD_FRAME);
#  else
      FRAME = SEVAR_GET_STORAGE_PTR(OLD_FRAME);
#  endif
   /* 'this' variable is the location that the return value will
    * end up going.
    */
   SEVAR_COPY(wThis,rTmp);
   call->stackptr = STACKPTR_SAVE(wThis);

   if( FRAME!=NULL )
   {
      rSEObject robj;

      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(FUNCVAR));
      call->funcptr = SEOBJECT_PTR(robj)->func;
      SEOBJECT_UNLOCK_R(robj);
      if( FUNCTION_IS_LOCAL(call->funcptr) )
      {
         SEOBJECT_ASSIGN_LOCK_R(robj,((struct LocalFunction *)call->funcptr)->hConstants);
         call->hConstants = SEOBJECT_PTR(robj)->hsemembers;
         SEOBJECT_UNLOCK_R(robj);
      }

#     if JSE_MEMEXT_SECODES==1
         /* Now that we have back the function */
         if( FUNCTION_IS_LOCAL(FUNCPTR) )
         {
            call->base = jsememextLockRead(((struct LocalFunction *)FUNCPTR)->op_handle,
                                           jseMemExtSecodeType);
            call->iptr = call->base + offset;
         }
#     endif
   }
   else
   {
      call->funcptr = NULL;
   }
}

#pragma codeseg CALL2_TEXT_RARE

/* Creating the arguments object is not particularly fast. Fortunately,
 * we need only do it when someone explicitly uses it, when
 * referring to 'arguments.xxx'. For the vast majority of functions,
 * we need never build this ugly thing.
 */
   static void NEAR_CALL
callCreateArguments(struct Call *call,hSEObject hArgs,
                    uint true_args,uint num_args,
                    rSEVar rfptr,rSEVar funcvar)
{
   wSEObjectMem wMem;
   uint x;
   wSEObject wArgs;

   SEOBJECT_ASSIGN_LOCK_W(wArgs,hArgs);

   /* We used to set up '<function>.caller' but that is not in the
    * current ECMA spec, so I've dropped it.
    */

   /* The current spec says the arguments object is just that - it is
    * an object, not an array.
    */
   wMem = SEOBJ_CREATE_MEMBER(call,wArgs,STOCK_STRING(callee));
   SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wMem),SEVAR_GET_OBJECT(funcvar));
   SEOBJECTMEM_UNLOCK_W(wMem);

   wMem = SEOBJ_CREATE_MEMBER(call,wArgs,STOCK_STRING(length));
   SEVAR_INIT_SLONG(SEOBJECTMEM_VAR(wMem),true_args);
   SEOBJECTMEM_UNLOCK_W(wMem);

   for( x=0;x<num_args;x++ )
   {
      VarName name = PositiveStringTableEntry(x);
      rSEVar rTmp;

      wMem = SEOBJ_CREATE_MEMBER(call,wArgs,name);
      /* CALL_PARAM(x) */
      rTmp = (rfptr - (PARAM_START+num_args-x));
      SEVAR_COPY(SEOBJECTMEM_VAR(wMem),rTmp);
      SEOBJECTMEM_UNLOCK_W(wMem);
   }
   SEOBJECT_UNLOCK_W(wArgs);
}

#pragma codeseg CALL2_TEXT

   void NEAR_CALL
callCreateVariableObject(struct Call *call,struct Function *lookfunc)
{
   MemCountUInt i;
   uint j;
   struct LocalFunction *func;
   wSEObjectMem wTmp, wTmp2;
   wSEVar wv;
   const struct Function *func_orig = call->funcptr;
   wSEVar wfptr = FRAME;
   uint num_args = call->num_args;
   uint true_args = call->true_args;
   wSEVar old_wfptr = NULL;
   rSEObject rScopeChain;
   wSEMembers wMembers;
   jsebool set_call = True;


   /* already created */
   if( lookfunc==NULL && call->hVariableObject!=hSEObjectNull ) return;

   /* no enclosing function */
   if( func_orig==NULL ) return;


   SEOBJECT_ASSIGN_LOCK_R(rScopeChain,call->hScopeChain);
   i = SEOBJECT_PTR(rScopeChain)->used;
   SEMEMBERS_ASSIGN(wMembers,SEOBJECT_PTR(rScopeChain)->hsemembers);
   SEOBJECT_UNLOCK_R(rScopeChain);

   /* Find the enclosing local function */
   while( !FUNCTION_IS_LOCAL(func_orig) || (lookfunc!=NULL && lookfunc!=func_orig) )
   {
      rSEObject robj;

      if( FUNCTION_IS_LOCAL(func_orig) )
      {
         /* In this case, the current call information refers to a past
          * function, so only update the stack.
          */
         set_call = False;

         /* was a local function, but not the one we are looking for.
          * Go back in the scope chain past this function.
          */
	 SEMEMBERS_LOCK_W(wMembers);
         do
         {
            assert( i>0 );
            i--;
            /* else the scope chain is not right */
         }
         while( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(wMembers)[i].value))!=VNull );
         SEMEMBERS_UNLOCK_W(wMembers);
      }


      num_args = (uword16)SEVAR_GET_STORAGE_LONG(wfptr-ARGS_OFFSET);
      true_args = (uword16)SEVAR_GET_STORAGE_LONG(wfptr-TRUE_ARGS_OFFSET);
      old_wfptr = wfptr;
#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
         wfptr = STACK_FROM_STACKPTR(SEVAR_GET_STORAGE_LONG(wfptr));
         if( wfptr==call->Global->growingStack )
            /* they both have a single if statement */
#     else
         wfptr = SEVAR_GET_STORAGE_PTR(wfptr);
         /* no enclosing local function */
         if( wfptr==NULL )
            /* they both have a single if statement */
#     endif
      {
         return;
      }


      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(wfptr - (num_args + FUNC_OFFSET)));
      func_orig = SEOBJECT_PTR(robj)->func;
      SEOBJECT_UNLOCK_R(robj);
   }
   func = (struct LocalFunction *)func_orig;

   /* check if already built */
   if( old_wfptr )
   {
      if( SEVAR_GET_STORAGE_PTR(old_wfptr-VAROBJ_OFFSET)!=NULL )
      {
         return;
      }
   }
   else
   {
      if( call->hVariableObject!=hSEObjectNull )
      {
         return;
      }
   }


   if (i > 0)
   {
    SEMEMBERS_LOCK_W(wMembers);

    while ( 0 < i-- )
    {
      assert( !LOCAL_TEST_IF_INIT_FUNCTION(func,call) );

      /* NULL is the marker for end of our scope chain, it should _not_
       * get here. It should find the slot reserved for the variable object
       * in the scope chain, set to VUndefined.
       */
      assert( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(wMembers)[i].value))!=VNull );
      if( SEVAR_GET_TYPE(&(SEMEMBERS_PTR(wMembers)[i].value))==VUndefined )
      {
         wSEObject wVariableObject;
         wSEObject wTmp2Obj;
         hSEObject tmpobj;

         SEVAR_INIT_UNORDERED_OBJECT(call,&(SEMEMBERS_PTR(wMembers)[i].value));
         tmpobj = SEVAR_GET_OBJECT(&(SEMEMBERS_PTR(wMembers)[i].value));
         if( set_call ) call->hVariableObject = tmpobj;

         /* The VariableObject for this function is not stored
          * with the function. The function comes from the previous
          * frame, it is part of the function's frame. The VariableObject
          * that goes along with it is in the call, so it is pushed
          * on the stack as storage when the next function is called,
          * therefore we need to update that storage location, which is
          * one frame 'higher' than the frame in which we found the
          * function.
          */
         if( old_wfptr )
         {
            old_wfptr -= VAROBJ_OFFSET;
            /* Update the stored VariableObject on the stack */
            assert( SEVAR_GET_STORAGE_PTR(old_wfptr)==NULL );
            assert( sizeof(call->hVariableObject) <= sizeof(void *) );
            SEVAR_INIT_STORAGE_PTR(old_wfptr,(void *)(call->hVariableObject));
         }

         /* OK, let's fill in the variable object with its appropriate stuff */
         SEOBJECT_ASSIGN_LOCK_W(wVariableObject,call->hVariableObject);

         /* params */
         for( j=0;j<func->InputParameterCount;j++ )
         {
            jsebool found;

            wTmp = seobjNewMember(call,wVariableObject,func->items[j].VarName,&found);

            /* CALL_PARAM(j) */
            wv = wfptr-(PARAM_START+num_args-j);
            SEVAR_COPY(SEOBJECTMEM_VAR(wTmp),wv);
            SEOBJECTMEM_UNLOCK_W(wTmp);
            if( SEVAR_GET_TYPE(wv)<VReference )
            {
               /* don't do this is it is already indirect, as there is no need
                * to have the local indirect into the object only to
                * indirect again elsewhere, just leave the indirection
                * to the original destination.
                */
               rSEObject robj;
               VarName name;
               SEOBJECT_ASSIGN_LOCK_R(robj,call->hVariableObject);
               name = (VarName)(SEOBJECT_PTR(robj)->used-1);
               SEOBJECT_UNLOCK_R(robj);
               SEVAR_INIT_REFERENCE_INDEX(wv,call->hVariableObject,name);
            }
         }

         /* locals */
         for( j=0;j<func->num_locals;j++ )
         {
            jsebool found;

            wTmp = seobjNewMember(call,wVariableObject,
                                  func->items[func->InputParameterCount+j].VarName,&found);
            /* CALL_LOCAL(j) */
            wv = wfptr+(j+1);
            SEVAR_COPY(SEOBJECTMEM_VAR(wTmp),wv);
            SEOBJECTMEM_UNLOCK_W(wTmp);
            if( SEVAR_GET_TYPE(wv)<VReference )
            {
               /* don't do this is it is already indirect, as there is no need
                * to have the local indirect into the object only to
                * indirect again elsewhere, just leave the indirection
                * to the original destination.
                */
               rSEObject robj;
               VarName name;
               SEOBJECT_ASSIGN_LOCK_R(robj,call->hVariableObject);
               name = (VarName)(SEOBJECT_PTR(robj)->used-1);
               SEOBJECT_UNLOCK_R(robj);
               SEVAR_INIT_REFERENCE_INDEX(wv,call->hVariableObject,name);
            }
         }

         /* arguments */

         wTmp = SEOBJ_CREATE_MEMBER(call,wVariableObject,STOCK_STRING(arguments));
         SEVAR_INIT_UNORDERED_OBJECT(call,SEOBJECTMEM_VAR(wTmp));
         callCreateArguments(call,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wTmp)),
                             true_args,num_args,wfptr,
                             wfptr - (num_args + FUNC_OFFSET));

         SEOBJECT_ASSIGN_LOCK_W(wTmp2Obj,SEVAR_GET_OBJECT(FUNCVAR));
         SEOBJECTMEM_CAST_R(wTmp2) = wseobjGetMemberStruct(call,
            SEOBJECT_CAST_R(wTmp2Obj),STOCK_STRING(arguments));
         if( NULL == SEOBJECTMEM_PTR(wTmp2) )
         {
            wTmp2 = SEOBJ_CREATE_MEMBER(call,wTmp2Obj,
                                        STOCK_STRING(arguments));
         }
         SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wTmp2),
                           SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wTmp)));
         SEOBJECTMEM_UNLOCK_W(wTmp);
         SEOBJECTMEM_UNLOCK_W(wTmp2);
         SEOBJECT_UNLOCK_W(wTmp2Obj);
         SEOBJECT_UNLOCK_W(wVariableObject);

         break;
      }
    }
    SEMEMBERS_UNLOCK_W(wMembers);
   }

   assert( 0 <= (slong)i );
}


/* Initializes a new context to do a jseInterpret().
 */
   struct Call * NEAR_CALL
callInterpret(struct Call *this,jseNewContextSettings settings,jsebool see_old,
              jsebool traperrors)
{
   struct Call *call;

   /* Allocate a structure for use.
    */
   call = jseMustMalloc(struct Call,sizeof(struct Call));
#  if ( 2 <= JSE_API_ASSERTLEVEL )
   call->cookie = (uword8) jseContext_cookie;
#  endif

   call->Global = this->Global;
   assert( this->next==NULL );
   this->next = call;
   call->prev = this;
   call->next = NULL;
   call->hGlobalObject = CALL_GLOBAL(this);
   call->pastGlobals = see_old;

   call->CallSettings = (uword8) settings;

   /* copy old session settings possibly to be overwritten */
   call->hDynamicDefault = this->hDynamicDefault;
   call->hObjectPrototype = this->hObjectPrototype;
   call->hArrayPrototype = this->hArrayPrototype;
   call->hFunctionPrototype = this->hFunctionPrototype;
   call->hStringPrototype = this->hStringPrototype;

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   call->currentSecurity = this->currentSecurity;
#  endif
#  if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
   call->Definitions = this->Definitions;
#  endif
   call->TheLibrary = this->TheLibrary;
   call->AtExitFunctions = this->AtExitFunctions;
#  if defined(JSE_LINK) && (0!=JSE_LINK)
   call->ExtensionLib = this->ExtensionLib;
#  endif

#  if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
   call->frameptr = 0;
#  else
   call->frameptr = NULL;
#  endif
   call->stackptr = this->stackptr;
   call->tempvars = NULL;
   call->iptr = NULL;
   call->tries = NULL;
   call->hVariableObject = hSEObjectNull;
   call->state = FlowNoReasonToQuit;
   call->funcptr = NULL;
   call->continue_count = 1;

   /* Make sure it is an illegal value so that if it is used
    * incorrectly, asserts will trigger. It must be set if
    * an error occurs
    */
   SEDBG( call->error_var.type = 125; )

   call->mustPrintError = !traperrors;
   call->errorPrinted = False;
   SEVAR_INIT_UNDEFINED(&(call->new_scope_chain));
   SEVAR_INIT_UNDEFINED(&(call->old_main));
   SEVAR_INIT_UNDEFINED(&(call->old_init));
   SEVAR_INIT_UNDEFINED(&(call->old_argc));
   SEVAR_INIT_UNDEFINED(&(call->old_argv));

   call->hScopeChain = hSEObjectNull;     /* for if we collect trying to allocate one */
   call->hScopeChain = seobjNew(call,False);

   if( !callNewSettings(call,(uword8)settings) )
   {
      /* propogate error back up */
      this->error_var = call->error_var;
      this->next = NULL;
      jseMustFree(call);
      return NULL;
   }

   /* We still need to create this because the scope chain has to
    * be correct;it will be used later on and it is expected
    * to be fleshed out.
    */
   if( this->hVariableObject==hSEObjectNull )
      callCreateVariableObject(this,NULL);

   /* if this->prev==NULL, then the old one is the initial context
    * which has none of these things, so have to start from scratch
    */
   if( see_old && (settings & jseNewGlobalObject)==0 && this->prev!=NULL )
   {
      call->hVariableObject = this->hVariableObject;
   }
   else
   {
      call->hVariableObject = CALL_GLOBAL(call);
   }

#  if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
      assert( JSE_CACHE_SIZE>=2 );
      /* zero the cache */
      memset(call->cache,0,sizeof(call->cache));
#  endif

   return call;
}


   void NEAR_CALL
callDelete(struct Call *call)
{
   rSEVar rret = STACK0;
   uword8 save_exit = call->state;

#  if JSE_MEMEXT_SECODES==1
      if( call->funcptr!=NULL && FUNCTION_IS_LOCAL(call->funcptr) )
      {
         jsememextUnlockRead(((struct LocalFunction *)call->funcptr)->op_handle,
                             call->base,jseMemExtSecodeType);
      }
#  endif

   if( call->prev==NULL )
   {
      /* last chance call of all destructors */
      call->state = FlowNoReasonToQuit;
      callDestructors(call);
   }

   if( call->state==FlowError && call->mustPrintError && !call->errorPrinted )
   {
      callPrintError(call);
      rret = &(call->error_var);
   }
   /* in case the following cleanup routines err */
   call->mustPrintError = True;


   /* cleanup new call settings */

   if( call->CallSettings & jseNewAtExit )
   {
      assert( NULL != call->AtExitFunctions );
      atexitCallFunctions(call->AtExitFunctions,call);
      atexitDelete(call->AtExitFunctions);
   }
   if( call->CallSettings & jseNewLibrary )
   {
      /* When unloading libraries, it needs to know if the call had
       * an error - this is exactly opposite from scripts in which
       * case an error ends execution.
       */
      call->state = save_exit;
      libraryDelete(call->TheLibrary,call);
   }
#  if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
   if ( call->CallSettings & jseNewDefines )
      defineDelete(call->Definitions);
#  endif


   /* Need to cleanup these things before the library, but can't
    * clean up the entire global because that has needed stuff
    * in it.
    */
   if( call->prev==NULL )
   {
      /* Cleanup shared data */
      if( call->Global->sharedDataList != NULL )
      {
         struct sharedDataNode * current = call->Global->sharedDataList;

         while( current != NULL )
         {
            struct sharedDataNode * temp = current->next;

            if( current->cleanupFunc != NULL )
#if defined(__JSE_GEOS__)
		((pcfm_jseShareCleanupFunc *)ProcCallFixedOrMovable_pascal)
		    (current->data, current->cleanupFunc);
#else
               current->cleanupFunc( current->data );
#endif

            jseMustFree( current->name );
            jseMustFree( current );

            current = temp;
         }
      }
   }

#  if defined(JSE_LINK) && (0!=JSE_LINK)
   /* remove #link libraries at last possible moment.  Theoretically
    * these may need to be garbage collected, on the off chance that
    * we may return a variable referencing a function in a link
    * library. #link libraries will have to be written just a little
    * more carefully to avoid that problem.
    */
   if( call->CallSettings & jseNewExtensionLib )
   {
      extensionDelete(call,call->ExtensionLib,call->Global->jseFuncTable);
   }
#  endif


   /* delete any remaining temp vars */
   CALL_KILL_TEMPVARS(call,NULL);

   if( call->prev )
   {
      /* an interpret-level cleanup */

      /* Pass return back up chain */
      call->prev->state = call->state;
      if( call->state==FlowError )
      {
         rret = &(call->error_var);
         SEVAR_COPY(&(call->prev->error_var),rret);
      }
      call->prev->stackptr++;
#     if defined(JSE_GROWABLE_STACK) && JSE_GROWABLE_STACK==1
         SEVAR_COPY(call->Global->growingStack+call->prev->stackptr,rret);
#     else
         SEVAR_COPY(call->prev->stackptr,rret);
#     endif
   }
   else
   {
      /* top level cleanup */

      callCleanupGlobal(call);
   }

   assert( call->next==NULL );
   if( call->prev!=NULL ) call->prev->next = NULL;

   assert( call->tempvars==NULL );
   jseMustFree(call);
}

#pragma codeseg CALL2_TEXT_RARE

   hSEObject
InitGlobalPrototype(struct Call *call,VarName name)
{
   wSEObject wObj;
   wSEObjectMem wObjMem;
   jsebool found;
   hSEObject hRet;

   /* Create '<global.>name', for example 'Object'. Make that
    * don't enum as all builtin objects should be that way.
    */
   SEOBJECT_ASSIGN_LOCK_W(wObj,CALL_GLOBAL(call));
   wObjMem = seobjNewMember(call,wObj,name,&found);
   SEOBJECT_UNLOCK_W(wObj);
   assert( NULL != SEOBJECTMEM_PTR(wObjMem) );
   SEOBJECTMEM_PTR(wObjMem)->attributes = jseDontEnum;
   if( SEOBJECTMEM_PTR(wObjMem)->value.type!=VObject )
      SEVAR_INIT_BLANK_OBJECT(call,SEOBJECTMEM_VAR(wObjMem));

   /* Make '.prototype' of that object and return it.
    */
   SEOBJECT_ASSIGN_LOCK_W(wObj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wObjMem)));
   SEOBJECTMEM_UNLOCK_W(wObjMem);
   wObjMem = seobjNewMember(call,wObj,STOCK_STRING(prototype),&found);
   SEOBJECT_UNLOCK_W(wObj);
   if( SEOBJECTMEM_PTR(wObjMem)->value.type!=VObject )
      SEVAR_INIT_BLANK_OBJECT(call,SEOBJECTMEM_VAR(wObjMem));
   SEOBJECTMEM_PTR(wObjMem)->attributes = jseDontEnum | jseDontDelete | jseReadOnly;
   hRet = SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wObjMem));
   SEOBJECTMEM_UNLOCK_W(wObjMem);
   return hRet;
}


   void
callNewGlobalVariable(struct Call *call)
{
   wSEObjectMem wmem;
   wSEObject wGlobalObject;

   call->hGlobalObject = seobjNew(call,True);
   SEOBJECT_ASSIGN_LOCK_W(wGlobalObject,call->hGlobalObject);
   wmem = seobjCreateMemberType(call,wGlobalObject,STOCK_STRING(_argc),VNumber);
   SEOBJECTMEM_PTR(wmem)->attributes = jseDontEnum;
   SEOBJECTMEM_UNLOCK_W(wmem);

   wmem = seobjCreateMemberType(call,wGlobalObject,STOCK_STRING(_argv),VObject);
   SEOBJECTMEM_PTR(wmem)->attributes = jseDontEnum;
   SEOBJECTMEM_UNLOCK_W(wmem);

   if( call->prev==NULL )
   {
      call->hDynamicDefault = seobjNew(call,True);
   }
   else
   {
      assert( call->hDynamicDefault==call->prev->hDynamicDefault);
      assert( call->hDynamicDefault!=hSEObjectNull );
   }

#  if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
      /* For the dynamic default value, each global object should
       * have a copy of it, so the user can always find it. However,
       * each copy needs to point to the same object, the
       * special marker.
       */
      wmem = SEOBJ_CREATE_MEMBER(call,wGlobalObject,
         LockedStringTableEntry(call,OP_NOT_SUPPORTED_PROPERTY,
                                (stringLengthType)strlen_jsechar(OP_NOT_SUPPORTED_PROPERTY)));
      SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wmem),call->hDynamicDefault);
      SEOBJECTMEM_PTR(wmem)->attributes = jseDontDelete | jseDontEnum | jseReadOnly;
      SEOBJECTMEM_UNLOCK_W(wmem);
#endif

   wmem = SEOBJ_CREATE_MEMBER(call,wGlobalObject,
      LockedStringTableEntry(call,DYN_DEFAULT_PROPERTY,
                             (stringLengthType)strlen_jsechar(DYN_DEFAULT_PROPERTY)));
   SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wmem),call->hDynamicDefault);
   SEOBJECTMEM_PTR(wmem)->attributes = jseDontDelete | jseDontEnum | jseReadOnly;
   SEOBJECTMEM_UNLOCK_W(wmem);
   SEOBJECT_UNLOCK_W(wGlobalObject);
}

#pragma codeseg CALL2_TEXT

/* Search for the given variable, in the current scope chain.
 * Space already reserved on the stack to fill-in
 */
   jsebool NEAR_CALL
callFindAnyVariable(struct Call *call,VarName name,jsebool full_look,jsebool make_ref)
{
   wSEVar wslot = STACK0;
   MemCountUInt lookin;
   hSEObject hssc;
   struct Call *loop;
   rSEObject rGlobalObject;

   /* Garbage collection could occur during this routine, make sure
    * we have a valid variable.
    */
   SEVAR_INIT_UNDEFINED(wslot);

   if( call->hScopeChain!=hSEObjectNull )
   {
      rSEObject rScopeChain;

      SEOBJECT_ASSIGN_LOCK_R(rScopeChain,call->hScopeChain);
      lookin=SEOBJECT_PTR(rScopeChain)->used;
      if ( 0 == lookin )
      {
         SEOBJECT_UNLOCK_R(rScopeChain);
      }
      else
      {
         rSEMembers rMembers;
         SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rScopeChain)->hsemembers);
         SEOBJECT_UNLOCK_R(rScopeChain);
         do
         {
            rSEVar rv = &(SEMEMBERS_PTR(rMembers)[lookin-1].value);

#           ifndef NDEBUG
            {
               /* check that pointers did not change in sub-sections */
               rSEObject rScopeChainTemp;
               rSEMembers rMembersTemp;
               SEOBJECT_ASSIGN_LOCK_R(rScopeChainTemp,call->hScopeChain);
               assert( hSEMembersNull != SEOBJECT_PTR(rScopeChainTemp)->hsemembers );
               SEMEMBERS_ASSIGN_LOCK_R(rMembersTemp,SEOBJECT_PTR(rScopeChainTemp)->hsemembers);
               assert( SEMEMBERS_PTR(rMembersTemp) == SEMEMBERS_PTR(rMembers) );
               SEMEMBERS_UNLOCK_R(rMembersTemp);
               SEOBJECT_UNLOCK_R(rScopeChainTemp);
            }
#           endif
            if( rv==NULL || SEVAR_GET_TYPE(rv)==VNull )
               break;
            if( SEVAR_GET_TYPE(rv)==VUndefined )
            {
               if( name==STOCK_STRING(arguments) )
               {
                  assert( call->hVariableObject==hSEObjectNull );
                  callCreateVariableObject(call,NULL);
                  if( make_ref )
                  {
                     SEVAR_INIT_REFERENCE(wslot,call->hVariableObject,
                                          STOCK_STRING(arguments));
                  }
                  else
                  {
                     rSEObject rVariableObject;
                     rSEObjectMem rIt;
                     SEOBJECT_ASSIGN_LOCK_R(rVariableObject,call->hVariableObject);
		     rIt = rseobjGetMemberStruct(call,rVariableObject,
						 STOCK_STRING(arguments));
                     SEOBJECT_UNLOCK_R(rVariableObject);
                     assert( SEOBJECTMEM_PTR(rIt) != NULL );
                     SEVAR_COPY(wslot,SEOBJECTMEM_VAR(rIt));
                     SEOBJECTMEM_UNLOCK_R(rIt);
                  }
                  SEMEMBERS_UNLOCK_R(rMembers);
                  return TRUE;
               }
               /* if peephole off, always do full_search */
#           if !defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER)
               /* This only works if we know that all references to locals
                * use an seLocalXXX opcode. The optimizer sees that it happens.
                * Without the optimizer, it can not be true, such as when
                * the 'var x' of variable 'x' comes after its first use.
                *
                * In the case where new locals can be created, the scope
                * chain will have the local variable object, so it will
                * be searched for there.
                */
               if( full_look )
#           endif
               {
                  /* NYI: else look up the call chain to find the
                   * enclosing local function
                   */
                  if( FUNCTION_IS_LOCAL(FUNCPTR) )
                  {
                     struct LocalFunction *func = (struct LocalFunction *)FUNCPTR;

                     if( !LOCAL_TEST_IF_INIT_FUNCTION(func,call) )
                     {
                        uword16 i;
                        uword16 totalVarNames = (uword16)(func->InputParameterCount+func->num_locals);
                        struct localItem *names;

                        for( i=0, names=func->items; i < totalVarNames; i++, names++ )
                        {
                           if( name == names->VarName )
                           {
                              if( make_ref )
                              {
                                 callCreateVariableObject(call,NULL);
                                 /* now it will be a reference into the
                                  * variable object
                                  */
                              }
                              SEVAR_COPY( wslot,                                       \
                                          i < func->InputParameterCount                \
                                        ? CALL_PARAM(i)                                \
                                        : CALL_LOCAL(i-func->InputParameterCount+1) );
                              SEMEMBERS_UNLOCK_R(rMembers);
                              return TRUE;
                           }
                        }
                     }
                  }
               }
            }
            else
            {
               rSEObject robj;
   
               assert( SEVAR_GET_TYPE(rv)==VObject );
               SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(rv));
               SEMEMBERS_UNLOCK_R(rMembers);
	       if( seobjHasProperty(call,robj,name,wslot,make_ref?HP_REFERENCE:HP_DEFAULT) )
               {
                  SEOBJECT_UNLOCK_R(robj);
                  return TRUE;
               }
               SEOBJECT_UNLOCK_R(robj);
               SEOBJECT_ASSIGN_LOCK_R(rScopeChain,call->hScopeChain);
               SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rScopeChain)->hsemembers);
               SEOBJECT_UNLOCK_R(rScopeChain);
            }
            assert( 0 < lookin );
         } while ( 0 != --lookin );
         SEMEMBERS_UNLOCK_R(rMembers);
      }
   }


   if( FRAME!=NULL && (hssc = (FUNCVAR)->data.object_val.hSavedScopeChain)!=hSEObjectNull )
   {
      /* This scope chain is built up starting from the end of the
       * old scope chain, so the first element is the first object
       * to be looked at, and so forth rather than the scope
       * chain which is a stack, so the latest (first) element is
       * at the end.
       */
      rSEObject rssc;
      SEOBJECT_ASSIGN_LOCK_R(rssc,hssc);
      for( lookin=0; lookin<SEOBJECT_PTR(rssc)->used; lookin++ )
      {
         rSEObjectMem rMem;
         rSEObject robj;
         rMem = rseobjIndexMemberStruct(call,rssc,lookin);

         assert( NULL != SEOBJECTMEM_PTR(rMem) );
         assert( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem))==VObject );
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(rMem)));
         SEOBJECTMEM_UNLOCK_R(rMem);
         if( seobjHasProperty(call,robj,name,wslot,make_ref?HP_REFERENCE:HP_DEFAULT) )
         {
            SEOBJECT_UNLOCK_R(robj);
            SEOBJECT_UNLOCK_R(rssc);
            return True;
         }
         SEOBJECT_UNLOCK_R(robj);
      }
      SEOBJECT_UNLOCK_R(rssc);
   }

   /* Now search the global */
   SEOBJECT_ASSIGN_LOCK_R(rGlobalObject,CALL_GLOBAL(call));
   if( seobjHasProperty(call,rGlobalObject,name,wslot,make_ref?HP_REFERENCE:HP_DEFAULT) )
   {
#     if defined(JSE_CACHE_GLOBAL_VARS) && JSE_CACHE_GLOBAL_VARS==1
         if( call->useCache )
         {
            /* Found an entry, store it. We save it as the last entry
             * dropping the current last entry, then bump it up one.
             * The bump up allows the entry to 'take hold' so that
             * if we are using two variables back and forth, they
             * don't just keep knocking each other out of the
             * cache before either can move up.
             */
            assert( JSE_CACHE_SIZE>=2 );
            call->cache[JSE_CACHE_SIZE-1] = call->cache[JSE_CACHE_SIZE-2];
            call->cache[JSE_CACHE_SIZE-2].entry = name;
#           if 0==JSE_PER_OBJECT_CACHE
               assert( call->Global->recentObjectCache.hobj == SEOBJECT_HANDLE(rGlobalObject) );
               assert( (uint)call->Global->recentObjectCache.index == call->Global->recentObjectCache.index );
               call->cache[JSE_CACHE_SIZE-2].slot = (uint)call->Global->recentObjectCache.index;
#           else
               assert( (uint)SEOBJECT_PTR(rGlobalObject)->cache == SEOBJECT_PTR(rGlobalObject)->cache );
               call->cache[JSE_CACHE_SIZE-2].slot = (uint)SEOBJECT_PTR(rGlobalObject)->cache;
#           endif
         }
#     endif
      SEOBJECT_UNLOCK_R(rGlobalObject);
      return True;
   }
   SEOBJECT_UNLOCK_R(rGlobalObject);


   /* finally we need to search the globals of the parent contexts,
    * as long as we are inheriting their globals
    */
   loop = call;
   while( loop->prev!=NULL && loop->pastGlobals )
   {
      rSEObject robj;
      loop = loop->prev;
      /* We use 'loop->GlobalObject' because we are looking for
       * the past global objects for these calls, not the
       * stored global for the function currently executing
       * in it.
       *
       *
       */
      SEOBJECT_ASSIGN_LOCK_R(robj,CALL_GLOBAL(loop));
      if( seobjHasProperty(call,robj,name,wslot,make_ref?HP_REFERENCE:HP_DEFAULT) )
      {
         SEOBJECT_UNLOCK_R(robj);
         return True;
      }
      SEOBJECT_UNLOCK_R(robj);
   }

   /* the 'global' or its equivelent.
    */
   if( name==STOCK_STRING(global)
    || name==call->Global->userglobal )
   {
      SEVAR_INIT_OBJECT(wslot,CALL_GLOBAL(call));
      return TRUE;
   }

   /* Not found anywhere */
   return False;
}

#pragma codeseg CALL2_TEXT_RARE

/* IMPORTANT: if this algorithm changes AT ALL, similar changes
 * must be made to jseCallStackInfo()!!!!
 */
   jsebool NEAR_CALL
callErrorTrapped(struct Call *call)
{
   struct TryBlock *tries;

   for( tries = call->tries; tries!=NULL; tries = tries->prev )
   {
      if( !tries->incatch && tries->catch!=(ADDR_TYPE)-1 )
      {
         /* found a trap */
         return True;
      }
   }
   return !call->mustPrintError;
}

#pragma codeseg CALL_TEXT

   void NEAR_CALL
callGetVarNeed(struct Call *this,rSEVar rVar,wSEVar wDest,
               uint InputVarOffset,jseVarNeeded need)
{
   struct Call *call = this;
   jseVarType vType;
   jsebool isfunc;
   const struct Function *itsfunc;
   jsenumber f;
   jseVarNeeded VNConvertTo;
   jsebool param = rVar==NULL;
   jsebool changed = False;

   if( rVar==NULL )
   {
      rVar = CALL_PARAM(InputVarOffset);
   }
   SEVAR_COPY(wDest,rVar);
   SEVAR_DEREFERENCE(call,wDest);
   if( CALL_QUIT(call) ) return;

   /* Make sure 'pVar' is of the correct type. Change it as necessary,
    * but store any intermediate results as temp var so not lost.
    */
   if( 0==(need&0x3ff) ) goto Validated;

   /* get the current type of the variable */
   vType = SEVAR_GET_TYPE(wDest);
   isfunc = SEVAR_IS_FUNCTION(this,wDest);
   itsfunc = isfunc?sevarGetFunction(this,wDest):(struct Function *)NULL;
/* This is a useless check, as f is only used if vType==vNumber. */
/* f = (vType==VNumber) ? SEVAR_GET_NUMBER(wDest) : jseZero; */

   /* if already one of the valid types then return it as it is */
   if ( (1 << vType) & need ) goto Validated;

   /* if a function is wanted, and this is an object function, then okeedokee */
   if( (JSE_VN_FUNCTION & need)  &&  VObject == vType  &&  isfunc )
   {
      goto Validated;
   }

   if ( vType==VNumber )
   {
      if( VNumber != vType  &&  (need & JSE_VN_NUMBER) )
      {
         /* element of string or buffer can always act as a number */
         goto Validated;
      }
      if( need & (JSE_VN_BYTE|JSE_VN_INT) )
      {
	 f = SEVAR_GET_NUMBER(wDest);
         if ( need & JSE_VN_INT )
         {
            /* check if can cast OK as integer */
            if ( JSE_FP_EQ(JSE_FP_CAST_FROM_SLONG(JSE_FP_CAST_TO_SLONG(f)),f) )
               goto Validated;
         }
         else
         {  /* if can't cast as integer then sure won't cast as a byte */
            assert( need & JSE_VN_BYTE );
            /* casting to char will use the compilers default signed/unsigned state, which
             * will match wherever else a char was converted to a jsenumber
             */
            if ( JSE_FP_EQ(JSE_FP_CAST_FROM_SLONG((unsigned char)JSE_FP_CAST_TO_SLONG(f)),f) )
               goto Validated;
         }
      }
   }

   /* if reached this part of the code then is not already one of the
    * acceptable types. Last acceptable chance is to convert it to the
    * desired JSE_VN_CONVERT type
    */
   VNConvertTo = (need >> 16) & 0xFF;
   if ( 0 != VNConvertTo )
   {
      /* if one of the allowable convert-to types do the requested conversion
       * and leave OK
       */
      /* Also, if the lenient conversion flag is set, then convert from
       * anything.
       */
      /* Also, if the variable is read-only, then we cannot replace it
       * so treat implicitly as if JSE_VN_COPY
       */
      if (((1 << vType) & (need >> 24)) ||
          (jseOptLenientConversion & this->Global->ExternalLinkParms.options))
      {
         AutoConvert(call,wDest,VNConvertTo);
         changed = True;
         goto Validated;
      }
   }

   /* all attempts to validate this variable have failed.  Pretty a return
    * string telling what types of variables would have been valid, and what
    * was invalid.
    */
   {
      /* prepare buffer giving parameter offset, if we can figure it out */
      jsechar ParameterOffset[10];
      jsecharptr cname;
      struct InvalidVarDescription BadDesc;
      if ( param )
      {
         assert( sizeof_jsechar(' ') == sizeof(jsecharptrdatum) );
         ParameterOffset[0] = ' ';
         long_to_string((sint)InputVarOffset+1,(jsecharptr)(ParameterOffset+1));
         assert( strlen_jsechar((jsecharptr)ParameterOffset) < (sizeof(ParameterOffset) / sizeof(ParameterOffset[0])) );
      }
      else
      {
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
         ParameterOffset[0] = '\0';
      }

      /* tell error (include types we could have converted from) */
      DescribeInvalidVar(this,rVar,vType,itsfunc, need | (need >> 24),&BadDesc);

      cname = callCurrentName(this);
      callError(this,textcoreVARNEEDED_PARAM_ERROR,ParameterOffset,
                BadDesc.VariableName,LFOM(cname),
                BadDesc.VariableType,BadDesc.VariableWanted);
      UFOM(cname);
   }

 Validated:
   if( !CALL_QUIT(call) )
   {
      if( SEVAR_GET_TYPE(rVar)>=VReference )
      {
         /* If we are copy converting, or it is readonly, we just
          * work with a copy, else we make it point back to the original
          * variable. Note that if the original is not changed, even on
          * copyconvert, we don't copy.
          */
         if( ((need & JSE_VN_COPYCONVERT)==0 || !changed) ||
             (SEVAR_GET_TYPE(rVar)==VReference &&
              (seobjGetAttributes(call,rVar->data.ref_val.hBase,
                                  rVar->data.ref_val.reference) & jseReadOnly)!=0) )
         {
            if( changed )
            {
               /* we are dealing with a pass-by-reference parameter */
               wSEVar wTmp = STACK_PUSH;
               SEVAR_COPY(wTmp,rVar);
               sevarDoPut(call,wTmp,wDest);
               STACK_POP;
            }
            /* Make dest the reference so we continue to update the variable */
            SEVAR_COPY(wDest,rVar);
         }
      }
   }

   return;
}
