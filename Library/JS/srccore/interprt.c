/* interprt.c           Set up a new interpret from the API
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


   static void NEAR_CALL
RunCompiledCode(struct Call *call,uint argc,jsecharptr argv[],jsebool call_main,
                hSEObject hThis)
{
   jsebool scratch;
   uint i;
   sword16 constant;
   VarName name;
   wSEVar old_neg1 = STACK_PUSH;
   wSEObject wGlobal;
   wSEObjectMem w_argv_var;
   rSEObjectMem r_argc_var, r_argv_var, rInit;
   const struct LocalFunction *initFunc;
   wSEObjectMem wMem;
   rSEObjectMem rItem;
   wSEObject wObj;
            wSEVar wItemVar;

   SEOBJECT_ASSIGN_LOCK_W(wGlobal,call->hGlobalObject);

   SEVAR_INIT_UNDEFINED(old_neg1);
   /* don't try to assign argc_var to it, because it could move */
   wMem = seobjNewMember(call,wGlobal,STOCK_STRING(_argc),&scratch);
   SEVAR_INIT_SLONG(SEOBJECTMEM_VAR(wMem),argc);
   SEOBJECTMEM_UNLOCK_W(wMem);

   wMem = seobjNewMember(call,wGlobal,STOCK_STRING(_argv),&scratch);
   /* SPECIAL CASE FOR ARGV[-1] - As Nombas' products introduce argv[-1]
    * to represent the name of the executable, it is possible that other
    * SE products may want to duplicate this behavior.  And so if this
    * instance does not have an argv[-1] but the previous instance does,
    * propogate this argv[-1].
    */
   if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(wMem))==VObject )
   {
      rSEObject robj;
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wMem)));
      rItem = rseobjGetMemberStruct(call,robj,NegativeStringTableEntry(-1));
      SEOBJECT_UNLOCK_R(robj);
   }
   else
   {
      SEOBJECTMEM_PTR(rItem) = NULL;
   }
   if( SEOBJECTMEM_PTR(rItem) != NULL )
   {
      SEVAR_COPY(old_neg1,SEOBJECTMEM_VAR(rItem));
      SEOBJECTMEM_UNLOCK_R(rItem);
   }
   else
   {
      rSEObject rPrevGlobalObject;
      SEOBJECT_ASSIGN_LOCK_R(rPrevGlobalObject,call->prev->hGlobalObject);
      rItem = rseobjGetMemberStruct(call,rPrevGlobalObject,STOCK_STRING(_argv));
      SEOBJECT_UNLOCK_R(rPrevGlobalObject);
      if ( NULL == SEOBJECTMEM_PTR(rItem) )
      {
         SEVAR_INIT_UNDEFINED(old_neg1);
      }
      else
      {
         if ( VObject == SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rItem)) )
         {
            rSEObjectMem rMem;
            rSEObject rObj;
            SEOBJECT_ASSIGN_LOCK_R(rObj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(rItem)));
            rMem = rseobjGetMemberStruct(call,rObj,NegativeStringTableEntry(-1));
            SEOBJECT_UNLOCK_R(rObj);
            if( NULL != SEOBJECTMEM_PTR(rMem) )
            {
               SEVAR_COPY(old_neg1,SEOBJECTMEM_VAR(rMem));
               SEOBJECTMEM_UNLOCK_R(rMem);
            }
            else
            {
               SEVAR_INIT_UNDEFINED(old_neg1);
            }
         }
         SEOBJECTMEM_UNLOCK_R(rItem);
      }
   }
   SEVAR_INIT_BLANK_OBJECT(call,SEOBJECTMEM_VAR(wMem));
   SEOBJECT_ASSIGN_LOCK_W(wObj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(wMem)));
   w_argv_var = SEOBJ_CREATE_MEMBER(call,wObj,NegativeStringTableEntry(-1));
   SEVAR_COPY(SEOBJECTMEM_VAR(w_argv_var),old_neg1);
   SEOBJECTMEM_UNLOCK_W(w_argv_var);
   STACK_POP;

   for( i = 0; i < argc; i++ )
   {
      wSEObjectMem wItem;
      name = PositiveStringTableEntry(i);
      wItem = SEOBJ_CREATE_MEMBER(call,wObj,name);
      SEVAR_INIT_STRING_NULLLEN(call,SEOBJECTMEM_VAR(wItem),argv[i],strlen_jsechar(argv[i]));
      SEOBJECTMEM_UNLOCK_W(wItem);
   }

   SEOBJECT_UNLOCK_W(wObj);
   SEOBJECTMEM_UNLOCK_W(wMem);

   r_argc_var = rseobjGetMemberStruct(call,SEOBJECT_CAST_R(wGlobal),STOCK_STRING(_argc));
   assert( NULL != SEOBJECTMEM_PTR(r_argc_var) );
   r_argv_var = rseobjGetMemberStruct(call,SEOBJECT_CAST_R(wGlobal),STOCK_STRING(_argv));
   assert( NULL != SEOBJECTMEM_PTR(r_argv_var) );

   assert( FRAME==NULL );
   rInit = rseobjGetMemberStruct(call,SEOBJECT_CAST_R(wGlobal),
                                 STOCK_STRING(Global_Initialization));
   assert( NULL != SEOBJECTMEM_PTR(r_argv_var) );

   /* execute main first, then execute the initialization function.
    * the initialization function will end up the current function,
    * main will be called when it returns
    *
    * Look through the initialization function to find its 'main'
    * member, if it exists
    */

   if( call_main )
   {
      initFunc = (const struct LocalFunction *)sevarGetFunction(call,SEOBJECTMEM_VAR(rInit));
      assert( initFunc!=NULL );
      assert( FUNCTION_IS_LOCAL((struct Function *)initFunc) );

      /* no parameters to an init func, it is just a block of code */
      assert( initFunc->InputParameterCount==0 );
      for( i=0;i<initFunc->num_locals;i++ )
      {
         if( initFunc->items[i].VarName==STOCK_STRING(main) &&
             (constant = initFunc->items[i].VarFunc)!=-1 )
         {
            /* Found it, make a call to it right now. */

            rSEObject rInitConstants;
            rSEMembers rMembers;
            rSEVar rTmpVar;

            /* push 'this' */
            wItemVar = STACK_PUSH;
            SEVAR_INIT_OBJECT(wItemVar,call->hGlobalObject);

            /* push function to call */
            SEOBJECT_ASSIGN_LOCK_R(rInitConstants,initFunc->hConstants);
            SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rInitConstants)->hsemembers);
            SEOBJECT_UNLOCK_R(rInitConstants);
            rTmpVar = &(SEMEMBERS_PTR(rMembers)[constant].value);
            wItemVar = STACK_PUSH;
            SEVAR_COPY(wItemVar,rTmpVar);
            SEMEMBERS_UNLOCK_R(rMembers);

            /* push params */
            wItemVar = STACK_PUSH;
            SEVAR_COPY(wItemVar,SEOBJECTMEM_VAR(r_argc_var));
            wItemVar = STACK_PUSH;
            SEVAR_COPY(wItemVar,SEOBJECTMEM_VAR(r_argv_var));
            callFunction(call,2,False);

            break;
         }
      }
   }

   SEOBJECTMEM_UNLOCK_R(r_argv_var);
   SEOBJECTMEM_UNLOCK_R(r_argc_var);

   SEOBJECT_UNLOCK_W(wGlobal);

   /* execute the initialization function, push 'this' */
   wItemVar = STACK_PUSH;
   SEVAR_INIT_OBJECT(wItemVar,hThis);
   /* push function to call */
   wItemVar = STACK_PUSH;
   SEVAR_COPY(wItemVar,SEOBJECTMEM_VAR(rInit));

   SEOBJECTMEM_UNLOCK_R(rInit);

   callFunction(call,0,False);
}

   static void NEAR_CALL
restoreOldVar(struct Call *call,wSEObject wCallObj,VarName name,wSEVar preservedHere,jsebool setDontEnum)
{
   jsebool found;
   wSEObjectMem wOld;

   wOld = seobjNewMember(call,wCallObj,name,&found);
   assert( NULL != SEOBJECTMEM_PTR(wOld) );
   if ( setDontEnum )
      SEOBJECTMEM_PTR(wOld)->attributes |= jseDontEnum;
   SEVAR_COPY(SEOBJECTMEM_VAR(wOld),preservedHere);
   SEOBJECTMEM_UNLOCK_W(wOld);
}

   static jsebool NEAR_CALL /* return true if it existed */
preserveOldVar(struct Call *call,rSEObject rCallObj,VarName name,wSEVar preserveHere,jsebool zeroThis)
{
   wSEObjectMem wOld;
   SEOBJECTMEM_CAST_R(wOld) = wseobjGetMemberStruct(call,rCallObj,name);
   if( SEOBJECTMEM_PTR(wOld)==NULL )
   {
      SEVAR_INIT_UNDEFINED(preserveHere);
      return False;
   }
   SEVAR_COPY(preserveHere,SEOBJECTMEM_VAR(wOld));
   if ( zeroThis )
   {
      SEVAR_INIT_UNDEFINED(SEOBJECTMEM_VAR(wOld));
   }
   SEOBJECTMEM_UNLOCK_W(wOld);
   return True;
}

   struct Call * NEAR_CALL
interpretInit(struct Call * call,const jsecharptr OriginalSourceFile,
              const jsecharptr OriginalSourceText,
              const void *PreTokenizedSource,
              jseNewContextSettings NewContextSettings,
              int HowToInterpret)
{
   struct Call *InterpretCall;
   uint argc;
   jsecharptr *argv;
   jsecharptr SourceText;
   jsebool CallMain = (HowToInterpret & JSE_INTERPRET_CALL_MAIN);
   rSEObject rCallObj;
   jsebool oldMain, oldInit;

   /* ----------------------------------------------------------------------
    * First, set up for the interpret by doing some checking on the input
    * parameters.
    * ---------------------------------------------------------------------- */

   if( HowToInterpret & JSE_INTERPRET_LOAD )
   {
      /* if we are loading, we are saying that we want to put the stuff
       * in the original context.
       */
      HowToInterpret &= ~JSE_INTERPRET_NO_INHERIT;
      NewContextSettings &= ~jseNewGlobalObject;
   }

   /* determine all the argv and argc parameter for source
    * (always at least 1) */
   argc = 1;
   argv = jseMustMalloc(jsecharptr ,sizeof(jsecharptr ));
   SourceText = StrCpyMalloc(( NULL != OriginalSourceText ) ?
                             OriginalSourceText : UNISTR("") );

   if ( NULL == OriginalSourceFile )
   {
      /* no source file, so this is pure text to interrpet */
      argv[0] = StrCpyMalloc(UNISTR(""));
   }
   else
   {
      /* source file is supplied; argv[0] is that file;
       * pull other parameters out of SourceText */
      argv[0] = StrCpyMalloc(OriginalSourceFile);
      ParseSourceTextIntoArgv(SourceText,&argc,&argv);
   }

   /* ---------------------------------------------------------------------- */
   /* then get the new call */
   /* ---------------------------------------------------------------------- */

   InterpretCall = callInterpret(call,NewContextSettings,
                                 (HowToInterpret&JSE_INTERPRET_NO_INHERIT)==0,
                                 (HowToInterpret&JSE_INTERPRET_TRAP_ERRORS)!=0);
   if( InterpretCall==NULL )
   {
      jseMustFree(SourceText);
      FreeArgv(argc,argv);
      return NULL;
   }

   if( HowToInterpret&JSE_INTERPRET_INFREQUENT_CONT )
      InterpretCall->continue_count = 2+JSE_INFREQUENT_COUNT;

   /* Save any old 'main' or global initialization function, zero them
    * so only what is defined by the new interpret stuff exists.
    * Also save old argc, argv.
    */
   SEOBJECT_ASSIGN_LOCK_R(rCallObj,CALL_GLOBAL(InterpretCall));
   oldMain=preserveOldVar(call,rCallObj,STOCK_STRING(main),&(InterpretCall->old_main),True);
   oldInit=preserveOldVar(call,rCallObj,STOCK_STRING(Global_Initialization),
                          &(InterpretCall->old_init),True);
   preserveOldVar(call,rCallObj,STOCK_STRING(_argc),&(InterpretCall->old_argc),False);
   preserveOldVar(call,rCallObj,STOCK_STRING(_argv),&(InterpretCall->old_argv),False);
   SEOBJECT_UNLOCK_R(rCallObj);

   /* ---------------------------------------------------------------------- */
   /* Compile the stuff into it. */
   /* ---------------------------------------------------------------------- */

#  if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
      if ( NULL != PreTokenizedSource )
      {
         CompileFromTokens(InterpretCall,PreTokenizedSource);
      }
#  endif

#  if (0!=JSE_COMPILER)
      if ((NULL == PreTokenizedSource &&
          !CompileFromText(InterpretCall,OriginalSourceFile ?
                           &(argv[0]) : &SourceText,
                           NULL != OriginalSourceFile))
          || CALL_ERROR(InterpretCall))
      {
         /* there was an error - restore main/init, return */
         if ( oldMain || oldInit )
         {
            wSEObject wCallObj;
            SEOBJECT_ASSIGN_LOCK_W(wCallObj,CALL_GLOBAL(InterpretCall));
            if( oldMain )
               restoreOldVar(call,wCallObj,STOCK_STRING(main),&(InterpretCall->old_main),False);
            if( oldInit )
               restoreOldVar(call,wCallObj,STOCK_STRING(Global_Initialization),
                             &(InterpretCall->old_init),False);
            SEOBJECT_UNLOCK_W(wCallObj);
         }

         callDelete(InterpretCall);
         jseMustFree(SourceText);
         FreeArgv(argc,argv);

         return NULL;
      }
#  endif

   /* ---------------------------------------------------------------------- */
   /* Set up 'main' and 'global initialization' calls */
   /* ---------------------------------------------------------------------- */
   RunCompiledCode(InterpretCall,argc,argv,CallMain,
                   (hSEObject)((HowToInterpret & JSE_INTERPRET_KEEPTHIS)?
                      SEVAR_GET_OBJECT(CALL_THIS):
                      CALL_GLOBAL(InterpretCall)));
   /* ---------------------------------------------------------------------- */
   /* some cleanup                                                           */
   /* ---------------------------------------------------------------------- */

   jseMustFree(SourceText);
   FreeArgv(argc,argv);

   /* ---------------------------------------------------------------------- */
   /* all set, return the result */
   /* ---------------------------------------------------------------------- */

   return InterpretCall;
}


   struct Call * NEAR_CALL
interpretTerm(struct Call *call)
{
   struct Call *ret = call->prev;
   wSEObject wCallObj;

   /* frame pointer will be restored to NULL when the last function exits. */
   if( FRAME!=NULL )
   {
      while( FRAME!=NULL ) callReturnFromFunction(call);

      /* This means the user aborted the script, probably with
       * a failed MayIContinue(). We should not report this as an
       * error - the user will have called a jseLibErrorPrintf()
       * if he really wants to generate an error.
       */
      if( !CALL_QUIT(call) )
      {
         CALL_SET_ERROR(call,FlowExit);
      }
   }

   /* restore saved global variables */
   SEOBJECT_ASSIGN_LOCK_W(wCallObj,CALL_GLOBAL(call));
   restoreOldVar(call,wCallObj,STOCK_STRING(main),&(call->old_main),True);
   restoreOldVar(call,wCallObj,STOCK_STRING(Global_Initialization),&(call->old_init),True);
   restoreOldVar(call,wCallObj,STOCK_STRING(_argc),&(call->old_argc),False);
   restoreOldVar(call,wCallObj,STOCK_STRING(_argv),&(call->old_argv),False);
   SEOBJECT_UNLOCK_W(wCallObj);

   assert( call->next==NULL );
   assert( call->prev!=NULL );
   callDelete(call);

   return ret;
}
