/* jselib.c   ISDK API interface functions
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

#if defined(__JSE_GEOS__)
#include <Ansi/stdio.h>
#elif !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#include <stdio.h>
#endif


/* Cleanup all remaining API variable structures. If we are in
 * debug mode, also report any unfreed variables as errors.
 */
   void
seapiCleanup(struct Call *call)
{
   uint i;
   seAPIVar vars = call->Global->APIVars;
#  if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   jsebool bad = FALSE;
#  endif


   call->Global->APIVars = NULL;        /* since we are freeing them */

   while( vars!=NULL )
   {
      seAPIVar nxt = vars->next;

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
      if( vars->shouldBeFreed && !vars->alreadyFreed )
      {
         DebugPrintf(UNISTR("A variable that you received from the API using one of\n"));
         DebugPrintf(UNISTR("the functions that returns a variable you must free was\n"));
         DebugPrintf(UNISTR("never freed. This variable must be freed before you exit.\n"));
         DebugPrintf(UNISTR("Don't blindly 'jseDestroyVariable()' it - make sure first\n"));
         DebugPrintf(UNISTR("you have not made a mistake elsewhere in your code where\n"));
         DebugPrintf(UNISTR("you thought you had freed it. This variable was returned\n"));
         DebugPrintf(UNISTR("from the ScriptEase API to your code at:\n"));
         DebugPrintf(UNISTR("   File: %s, Line %d by function %s.\n\n"),
                     vars->file,vars->line,vars->function);
         bad = TRUE;
      }

      jseMustFree(vars->function);
      jseMustFree(vars->file);
#endif
#     if JSE_MEMEXT_STRINGS==1
         if( vars->data ) SEVAR_FREE_DATA(call,vars->data);
#     endif
      jseMustFree(vars);

      vars = nxt;
   }

#  if 0==JSE_DONT_POOL
      for( i=0;i<call->Global->api_pool_count;i++ )
      {
         jseMustFree(call->Global->api_pool[i]);
      }
#  endif

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   if( bad )
   {
#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Some variables were not freed, see C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Some variables were not freed, see C:\\JseDebug.log for details.\n"));
      exit(1);
#endif
   }
#endif
}


#if !defined(NDEBUG) && JSE_TRACKVARS==1
   static JSE_POINTER_UINT
computeChecksum(seAPIVar var)
{
   /* A simple algorithm, but we don't expect anyone to be trying to
    * 'trick' us, so it will work fine.
    */
   /* ignore the next and prev because they change */
   return
      (JSE_POINTER_UINT)(var->function)+
      (JSE_POINTER_UINT)(var->file)+
      (JSE_POINTER_UINT)(var->line);
}


   static void NEAR_CALL
trackvar_check(seAPIVar var)
{
   JSE_POINTER_UINT checksum;

   checksum = computeChecksum(var);

   if( checksum!=var->checksum )
   {
      DebugPrintf(UNISTR("Variable passed to API function is not a valid variable.\n"));
      DebugPrintf(UNISTR("Likely cause is that you have already freed the variable or\n"));
      DebugPrintf(UNISTR("passed it to an API function in a way that implicitly frees\n"));
      DebugPrintf(UNISTR("it, such as passing it to jseReturnVar() with the flag set\n"));
      DebugPrintf(UNISTR("to jseRetTempVar.\n"));

#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));

      exit(1);
#endif
   }
   if( var->alreadyFreed )
   {
      DebugPrintf(UNISTR("Variable passed to API function is no longer valid. Many\n"));
      DebugPrintf(UNISTR("API functions do not force you to free the returned variable.\n"));
      DebugPrintf(UNISTR("Such variables are only valid until the wrapper function\n"));
      DebugPrintf(UNISTR("that allocated it exits. If you need to retain such a variable\n"));
      DebugPrintf(UNISTR("use 'jseCreateSiblingVariable()'. This variable was returned\n"));
      DebugPrintf(UNISTR("from the ScriptEase API to your code at:\n"));
      DebugPrintf(UNISTR("   File: %s, Line %d by function %s.\n\n"),
                  var->file,var->line,var->function);

#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Variable no longer valid error, check C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Variable no longer valid error, check C:\\JseDebug.log for details.\n"));

      exit(1);
#endif
   }
}
#endif

/* First, validate the given variable, and report any appropriate errors.
 * This includes in TRACKVAR builds making sure reading to it is allowed.
 * Then get the readable contents to an internal buffer. Return the internal
 * buffer. Note that this is reentrant as long as you don't expect the
 * buffer to 'hang around'.
 */
wSEVar seapiGetValue(struct Call *call,seAPIVar var)
{
   if( var==NULL ) return NULL;

#  if ( 0 < JSE_API_ASSERTLEVEL )
   if( var->cookie!=APIVAR_COOKIE )
   {
#if !defined(NDEBUG) && JSE_TRACKVARS==1
      DebugPrintf(UNISTR("Variable passed to API function is not a valid variable.\n"));
      DebugPrintf(UNISTR("This has been triggered because the variable does not\n"));
      DebugPrintf(UNISTR("have a valid cookie. Likely cause is passing a garbage\n"));
      DebugPrintf(UNISTR("pointer to the function. Because this pointer is not one\n"));
      DebugPrintf(UNISTR("recognized, we can give no further information on it.\n"));
      fprintf_jsechar(stderr,UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));
#endif
      exit(1);
   }
#  endif
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   trackvar_check(var);
#endif

   if( SEVAR_GET_TYPE(&(var->value))<VReference )
   {
      return &(var->value);
   }
   else
   {
      SEVAR_COPY(&(var->last_access),&(var->value));
      SEVAR_DEREFERENCE(call,&(var->last_access));
      return &(var->last_access);
   }
}


/* Update the given API variable to have the given new value. Usually,
 * this is simply a copy to the api var's internal 'seVar' structure,
 * but if this is a reference, we must put the value in the given
 * structure member, doing a dynamic put if necessary.
 */
static void NEAR_CALL seapiPutValue(struct Call *call,seAPIVar var,wSEVar from)
{
#  if ( 0 < JSE_API_ASSERTLEVEL )
   if( var->cookie!=APIVAR_COOKIE )
   {
#if !defined(NDEBUG) && JSE_TRACKVARS==1
      DebugPrintf(UNISTR("Variable passed to API function is not a valid variable.\n"));
      DebugPrintf(UNISTR("This has been triggered because the variable does not\n"));
      DebugPrintf(UNISTR("have a valid cookie. Likely cause is passing a garbage\n"));
      DebugPrintf(UNISTR("pointer to the function. Because this pointer is not one\n"));
      DebugPrintf(UNISTR("recognized, we can give no further information on it.\n"));
      fprintf_jsechar(stderr,UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));
#endif
      exit(1);
   }
#  endif
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   trackvar_check(var);
#endif

   SEVAR_DO_PUT(call,&(var->value),from);
}

   void NEAR_CALL
seapiDeleteVariable(struct Call *call,seAPIVar var)
{
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   JSE_POINTER_UINT checksum = computeChecksum(var);

   if( checksum!=var->checksum )
   {
      DebugPrintf(UNISTR("Variable passed to API function is not a valid variable.\n"));
      DebugPrintf(UNISTR("Likely cause is that you have already freed the variable or\n"));
      DebugPrintf(UNISTR("passed it to an API function in a way that implicitly frees\n"));
      DebugPrintf(UNISTR("it, such as passing it to jseReturnVar() with the flag set\n"));
      DebugPrintf(UNISTR("to jseRetTempVar.\n"));
#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Invalid variable error, check C:\\JseDebug.log for details.\n"));

      exit(1);
#endif
   }

   if( var->alreadyFreed )
   {
      DebugPrintf(UNISTR("Variable passed to API function is no longer valid. Many\n"));
      DebugPrintf(UNISTR("API functions do not force you to free the returned variable.\n"));
      DebugPrintf(UNISTR("Such variables are only valid until the wrapper function\n"));
      DebugPrintf(UNISTR("that allocated it exits. If you need to retain such a variable\n"));
      DebugPrintf(UNISTR("use 'jseCreateSiblingVariable()'. This variable was returned\n"));
      DebugPrintf(UNISTR("from the ScriptEase API to your code at:\n"));
      DebugPrintf(UNISTR("   File: %s, Line %d by function %s.\n\n"),
                  var->file,var->line,var->function);
#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Variable no longer valid error, check C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Variable no longer valid error, check C:\\JseDebug.log for details.\n"));

      exit(1);
#endif
   }
   if( !var->shouldBeFreed )
   {
      DebugPrintf(UNISTR("You are trying to delete a variable that is not supposed to be\n"));
      DebugPrintf(UNISTR("freed. This can also happen if you pass a variable that implicitly\n"));
      DebugPrintf(UNISTR("deletes the variable (such as jseReturnVar() with jseRetTempVar\n"));
      DebugPrintf(UNISTR("This variable was returned to you by an API function which doesn't\n"));
      DebugPrintf(UNISTR("gibe you a variable to be freed. This variable was returned\n"));
      DebugPrintf(UNISTR("from the ScriptEase API to your code at:\n"));
      DebugPrintf(UNISTR("   File: %s, Line %d by function %s.\n\n"),
                  var->file,var->line,var->function);

#ifdef __JSE_GEOS__
      DebugPrintf(UNISTR("Variable freed that shouldn't be, check C:\\JseDebug.log for details.\n"));
      FatalError(-1);
#else
      fprintf_jsechar(stderr,UNISTR("Variable freed that shouldn't be, check C:\\JseDebug.log for details.\n"));

      exit(1);
#endif
   }
#else
   /* mgroeber: I prefer these to be fatals... */
   assert( !var->alreadyFreed );
   assert( var->shouldBeFreed );
   if( var->alreadyFreed || !var->shouldBeFreed ) return;
#endif

   var->alreadyFreed = True;

   if( var->prev==NULL )
   {
      call->Global->APIVars = var->next;
   }
   else
   {
      var->prev->next = var->next;
   }
   if( var->next!=NULL )
      var->next->prev = var->prev;

#  if JSE_MEMEXT_STRINGS==1
      if( var->data ) SEVAR_FREE_DATA(call,var->data);
#  endif
#if !defined(NDEBUG) && JSE_TRACKVARS==1
   jseMustFree(var->function);
   jseMustFree(var->file);
#endif

#  if 0==JSE_DONT_POOL
   if( call->Global->api_pool_count<API_VAR_POOL_SIZE )
      call->Global->api_pool[call->Global->api_pool_count++] = var;
   else
#  endif
      jseMustFree(var);
}


/* Package a real variable for returning. Allocates a new seAPIVar, locks
 * it in, copies the given variable's contents to it, and fills in all
 * the fields.
 */
   seAPIVar
seapiCopyAndReturn(struct Call *call,rSEVar realvar,
                   jsebool api_lock
#if !defined(NDEBUG) && JSE_TRACKVARS==1
                   /* NOT jsechar, these are generated by __FILE__, which
                    * appear to always be char strings.
                    */
                   ,jsecharptr apiname,char *file,uint line
#endif
                   )
{
   seAPIVar ret;

   if( realvar==NULL ) return NULL;


#  if 0==JSE_DONT_POOL
   if( call->Global->api_pool_count )
   {
      ret = call->Global->api_pool[--(call->Global->api_pool_count)];
   }
   else
#  endif
   {
      ret = jseMustMalloc(struct seAPIVar,sizeof(struct seAPIVar));
   }

   ret->prev = NULL;
   if( api_lock )
   {
      if( call->Global->APIVars!=NULL )
         call->Global->APIVars->prev = ret;
      ret->next = call->Global->APIVars;
      call->Global->APIVars = ret;
   }
   else
   {
      if( call->tempvars!=NULL )
         call->tempvars->prev = ret;
      ret->next = call->tempvars;
      call->tempvars = ret;
   }

   /* mgroeber: catch code that creates infinite tempvar loops */
   assert( ret->next!=ret );

#  if JSE_MEMEXT_STRINGS==1
      ret->data = NULL;
#  endif
#if !defined(NDEBUG) && JSE_TRACKVARS==1
#if (!defined(JSE_UNICODE) || (0==JSE_UNICODE))
   ret->file = StrCpyMalloc(file);
   /* it is a null-terminated MBCS string, can be copied just
    * like a regular one.
    */
   ret->function = StrCpyMalloc((char *)apiname);
#else
   {
      size_t nameLen = strlen(file);
      ret->file = jseMustMalloc(char,nameLen+1);
      memcpy(ret->file,file,nameLen+1);

      nameLen = strlen_jsechar(apiname);
      ret->function = jseMustMalloc(char,nameLen+1);
      memcpy(ret->function,apiname,nameLen+1);
   }
#endif
   ret->line = line;

   ret->checksum = computeChecksum(ret);
#endif

   ret->shouldBeFreed = api_lock;
   ret->alreadyFreed = False;

#  if ( 0 < JSE_API_ASSERTLEVEL )
   ret->cookie = APIVAR_COOKIE;
#  endif

   SEVAR_COPY(&(ret->value),realvar);
   SEVAR_INIT_UNDEFINED(&(ret->last_access));

   return ret;
}

/* ---------------------------------------------------------------------- */


   JSECALLSEQ( void )
jseLibSetExitFlag(jseContext call,jseVariable variable)
{
   wSEVar loc = STACK_PUSH;

   JSE_API_STRING(ThisFuncName,"jseLibSetExitFlag");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   if( variable!=NULL )
   {
      /* since the seapiGetValue is called first, and can collect,
       * we need protection.
       */
      SEVAR_INIT_UNDEFINED(loc);
      SEVAR_COPY(loc,seapiGetValue(call,variable));
   }
   else
   {
      SEVAR_INIT_SLONG(loc,EXIT_SUCCESS);
   }
   CALL_SET_ERROR(call,FlowExit);
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseContext )
jseReallyInterpInit(jseContext call,
                    const jsecharptr SourceFile,
                    const jsecharptr SourceText,
                    const void * PreTokenizedSource,
                    jseNewContextSettings NewContextSettings,
                    int howToInterpret,
                    jseVariable *retvar,
                    char *FILE,
                    int LINE
                    )
#else
   JSECALLSEQ( jseContext )
jseInterpInit(jseContext call,
              const jsecharptr SourceFile,
              const jsecharptr SourceText,
              const void * PreTokenizedSource,
              jseNewContextSettings NewContextSettings,
              int howToInterpret,
              jseContext unused_parameter,
              jseVariable *retvar
             )
#endif
{
   jseContext ret;

#  if defined(NDEBUG) || !defined(JSE_TRACKVARS) || JSE_TRACKVARS==0
      UNUSED_PARAMETER(unused_parameter);
#  endif

   assert( call->next==NULL );

   if( retvar ) *retvar = NULL;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseInterpInit"),return NULL);
   CALL_SET_ERROR(call,FlowNoReasonToQuit);

   ret = interpretInit(call,SourceFile,SourceText,PreTokenizedSource,
                       NewContextSettings,howToInterpret);

   if( ret==NULL )
   {
      rSEVar err = &(call->error_var);

      if( (howToInterpret & JSE_INTERPRET_TRAP_ERRORS)!=0 && retvar!=NULL )
      {

         /* In this case, the error is propogated up into our call */
         *retvar = SEAPI_RETURN(call,err,TRUE,UNISTR("jseInterpInit"));
      }
      else
      {
         /* error already printed */
         CALL_SET_ERROR(call,FlowNoReasonToQuit);
      }
      STACK_POP;
   }

   return ret;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyInterpTerm(jseContext call,jsebool traperrors,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseInterpTerm(jseContext call,jsebool traperrors)
#endif
{
   jseVariable ret;
   jsebool error;
   rSEVar tmp;
   jsebool disregard = False;


   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseInterpTerm"),return NULL);

   /* Some people may mistakenly pass the higher level context in,
    * we allow that.
    */
   if( call->next ) call = call->next;

   /* If there is any more, they have just plain passed the wrong context
    */
   assert( call->next==NULL );

   /* If not a NULL frame, more code to execute, in which case
    * this is an 'abort', so disregard the return value.
    */
   if( FRAME!=NULL ) disregard = True;

   call = interpretTerm(call);

   error = CALL_ERROR(call);

   tmp = error?&(call->error_var):STACK0;

   if( (traperrors && error) || !disregard )
   {
      ret = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseInterpTerm"));
   }
   else
   {
      /* error already printed */
      ret = NULL;
   }

   STACK_POP;
   CALL_SET_ERROR(call,FlowNoReasonToQuit);
   return ret;
}


/* API returns NULL when nothing left to interpret */
   JSECALLSEQ( jseContext )
jseInterpExec(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseInterpExec"),return NULL);
   assert( call->next==NULL );
   return secodeInterpret(call)?call:NULL;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jsebool )
jseReallyInterpret(jseContext call,
                   const jsecharptr SourceFile,
                   const jsecharptr SourceText,
                   const void * PreTokenizedSource,
                   jseNewContextSettings NewContextSettings,
                   int howToInterpret,
                   jseVariable *retvar,
                   char *FILE,
                   int LINE)
#else
   JSECALLSEQ( jsebool )
jseInterpret(jseContext call,
             const jsecharptr SourceFile,
             const jsecharptr SourceText,
             const void * PreTokenizedSource,
             jseNewContextSettings NewContextSettings,
             int howToInterpret,
             jseContext unused_parameter,
             jseVariable *retvar)
#endif
{
   jseContext newc;
   jsebool retbool;
   rSEVar ret;
#if (0!=JSE_COMPILER)
   uint compilingSave;
#endif

#  if defined(NDEBUG) || !defined(JSE_TRACKVARS) || JSE_TRACKVARS==0
      UNUSED_PARAMETER(unused_parameter);
#  endif

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseInterpret"),return False);
   assert( call->next==NULL );

   CALL_SET_ERROR(call,FlowNoReasonToQuit);


   newc = interpretInit(call,SourceFile,SourceText,PreTokenizedSource,
                        NewContextSettings,howToInterpret);

   if( newc!=NULL )
   {
      /* This is a really ugly hack which is meant to preserve the compilation state.
       * Because we may actually do an interpret() within a compilation (as with our
       * binary object files), we want to make sure that the interpret doesn't think
       * we're still compiling files, because we're not.  Well, sort of.
       */
#if (0!=JSE_COMPILER)
      compilingSave = call->Global->CompileStatus.NowCompiling;
      call->Global->CompileStatus.NowCompiling = 0;
#endif

      /* remain in loop calling statement after statement, even if the
       * level of function changes.
       */
      while( secodeInterpret(newc) )
      {
         /* context has not changed; still in the same function */
         if( !callMayIContinue(newc) )
         {
            /* probably in the middle of a function, but something
             * sensible on the top of the stack to return
             */
            wSEVar tmp = STACK_PUSH;

            SEVAR_INIT_UNDEFINED(tmp);

            break;
         }
      }

      interpretTerm(newc);
#if (0!=JSE_COMPILER)
      call->Global->CompileStatus.NowCompiling = compilingSave;
#endif
   }


   /* it only fails on error, exiting is ok */
   retbool = !CALL_ERROR(call);

   ret = retbool?STACK0:&(call->error_var);

   if( retvar!=NULL && (retbool || (howToInterpret&JSE_INTERPRET_TRAP_ERRORS)!=0) )
   {
      *retvar = SEAPI_RETURN(call,ret,TRUE,UNISTR("jseInterpTerm"));
   }
   else
   {
      if( retvar!=NULL ) *retvar = NULL;
      if( !retbool )
      {
         /* error already printed */
         CALL_SET_ERROR(call,FlowNoReasonToQuit);
      }
   }

   STACK_POP;
   CALL_SET_ERROR(call,FlowNoReasonToQuit);
   return retbool;
}


#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   JSECALLSEQ( jseTokenRetBuffer)
     jseCreateCodeTokenBuffer(jseContext call,
                              const jsecharptr source,
                              jsebool sourceIsFileName
                                 /*else is source string*/,
                              uint *bufferLen)
{
   struct Call *newCall;
   void *ret;
   JSE_API_STRING(ThisFuncName,"jseCreateCodeTokenBuffer");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(source,2,ThisFuncName,return NULL);
   JSE_API_ASSERT_(bufferLen,4,ThisFuncName,return NULL);

   newCall = callInterpret(call,jseNewGlobalObject|jseNewLibrary,False,False);

   ret = CompileIntoTokens(newCall,source,sourceIsFileName,bufferLen);

   callDelete(newCall);

   return ret;
}
#endif

   JSECALLSEQ( jsebool )
jseAddLibrary(jseContext call, const jsecharptr objectVariableName,
              const struct jseFunctionDescription *FunctionList,
              void _FAR_ *InitLibData,
              jseLibraryInitFunction libInitFunction,
              jseLibraryTermFunction libTermFunction)
{
   JSE_API_STRING(ThisFuncName,"jseAddLibrary");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );
   JSE_API_ASSERT_(FunctionList,3,ThisFuncName,return False);

   return libraryAddFunctions(call->TheLibrary,call,
                              objectVariableName,FunctionList,
                              libInitFunction,libTermFunction,InitLibData);
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyFuncVar(jseContext call,uint ParameterOffset,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseFuncVar(jseContext call,uint ParameterOffset)
#endif
{
   jsecharptr cname;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseFuncVar"),return NULL);
   assert( call->next==NULL );
   if( call->num_args <= ParameterOffset )
   {
      cname = callCurrentName(call);
      callError(call,textcoreFUNCPARAM_NOT_PASSED,1 + ParameterOffset,
                LFOM(cname));
      UFOM(cname);
      return NULL;
   }
   return ( SEAPI_RETURN(call,CALL_PARAM(ParameterOffset),FALSE,UNISTR("jseFuncVar")) );
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyFuncVarNeed(jseContext call,uint parameterOffset,jseVarNeeded need,
                     char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseFuncVarNeed(jseContext call,uint parameterOffset,jseVarNeeded need)
#endif
{
   wSEVar dest = STACK_PUSH;
   jseVariable ret;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseFuncVarNeed"),return NULL);
   assert( call->next==NULL );

   SEVAR_INIT_UNDEFINED(dest);
   callGetVarNeed(call,NULL,dest,parameterOffset,need);
   if( CALL_QUIT(call) )
   {
      /* leave error on top of stack */
      ret = NULL;
   }
   else
   {
      ret =  SEAPI_RETURN(call,dest,(need&JSE_VN_CREATEVAR)?TRUE:FALSE,UNISTR("jseFuncVarNeed"));
      STACK_POP;
   }

   return ret;
}

   JSECALLSEQ( jsebool )
jseVarNeed(jseContext call,jseVariable variable,jseVarNeeded need)
{
   wSEVar v;
   JSE_API_STRING(ThisFuncName,"jseVarNeed");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );

   v = seapiGetValue(call,variable);
   callGetVarNeed(call,v,v,0,need);
   seapiPutValue(call,variable,v);

   return CALL_QUIT(call)==0;
}


#if ( 0 < JSE_API_ASSERTLEVEL )
static jsebool NEAR_CALL TestValidForArrayLength(/*jseContext call,*/rSEVar var)
{
   jseVarType vType = SEVAR_GET_TYPE(var);
   if ( VObject != vType
#    if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
     && VBuffer != vType
#    endif
     && VString != vType )
   {
      SetLastApiError(UNISTR("Invalid var type for Get/SetArrayLength"));
      return False;
   }
   return True;
}
#endif

   JSECALLSEQ( JSE_POINTER_UINDEX )
jseGetArrayLength(jseContext call,jseVariable variable,
                  JSE_POINTER_SINDEX *MinIndex)
{
   rSEVar var;
   JSE_POINTER_UINDEX ret;
   JSE_API_STRING(ThisFuncName,"jseGetArrayLength");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return 0);
   assert( call->next==NULL );


   var = seapiGetValue(call,variable);
#  if ( 0 < JSE_API_ASSERTLEVEL )
   if ( !TestValidForArrayLength(var) )
   {
      ret = 0;
      if ( NULL != MinIndex )
         *MinIndex = 0;
   }
   else
#  endif
   {
      ret = sevarGetArrayLength(call,var,MinIndex);
   }
   return ret;
}


   JSECALLSEQ( void )
jseSetArrayLength(jseContext call,jseVariable variable,
                  JSE_POINTER_SINDEX MinIndex,JSE_POINTER_UINDEX Length)
{
   wSEVar var;
   JSE_API_STRING(ThisFuncName,"jseSetArrayLength");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   var = seapiGetValue(call,variable);
#  if ( 0 < JSE_API_ASSERTLEVEL )
   if ( TestValidForArrayLength(var) )
#  endif
   {
      sevarSetArrayLength(call,var,MinIndex,Length);
   }
}

   JSECALLSEQ( void )
jseSetAttributes(jseContext call,jseVariable variable,
                 jseVarAttributes attr)
{
   rSEVar var;
   struct Function *func;

   JSE_API_STRING(ThisFuncName,"jseSetAttributes");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   var = seapiGetValue(call,variable);

   if( SEVAR_GET_TYPE(var)==VObject )
   {
      wSEObject wobj;
      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(var));
      if( (func = SEOBJECT_PTR(wobj)->func)!=NULL )
         func->attributes = attr;
      if( attr & jseEcmaArray )
         seobjMakeEcmaArray(call,wobj);
      if( attr & jseDynamicOnUndefined )
         SEOBJ_MAKE_DYNAMIC_UNDEFINED(wobj);
      SEOBJECT_UNLOCK_W(wobj);
   }
   if( SEVAR_GET_TYPE(&(variable->value))==VReference )
   {
      /* set these on the object member itself */
      seobjSetAttributes(call,variable->value.data.ref_val.hBase,
                         variable->value.data.ref_val.reference,
                         attr);
   }
}


#if defined(JSE_DYNAMIC_OBJS)
   JSECALLSEQ(void)
jseSetObjectCallbacks(jseContext call,jseVariable obj,struct jseObjectCallbacks *cbs)
{
   rSEVar var;

   JSE_API_STRING(ThisFuncName,"jseSetObjectCallbacks");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );


   var = seapiGetValue(call,obj);

   if( SEVAR_GET_TYPE(var)==VObject )
   {
      wSEObject wobj;
      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(var));
      SEOBJECT_PTR(wobj)->callbacks = cbs;
      SEOBJ_MAKE_DYNAMIC(wobj);
      SEOBJECT_UNLOCK_W(wobj);
   }
}


   JSECALLSEQ(struct jseObjectCallbacks *)
jseGetObjectCallbacks(jseContext call,jseVariable obj)
{
   rSEVar var;
   struct jseObjectCallbacks *callbacks;

   JSE_API_STRING(ThisFuncName,"jseGetObjectCallbacks");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   var = seapiGetValue(call,obj);

   if( SEVAR_GET_TYPE(var)==VObject )
   {
      rSEObject robj;
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(var));
      callbacks = SEOBJECT_PTR(robj)->callbacks;
      SEOBJECT_UNLOCK_R(robj);
   }
   else
   {
      callbacks = NULL;
   }
   return callbacks;
}
#endif


   JSECALLSEQ( jseVarAttributes )
jseGetAttributes(jseContext call,jseVariable variable)
{
   jseVarAttributes ret;
   JSE_API_STRING(ThisFuncName,"jseGetAttributes");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return 0);
   assert( call->next==NULL );

   if( SEVAR_GET_TYPE(&(variable->value))==VReference )
   {
      /* get these from the object member itself */
      ret = seobjGetAttributes(call,variable->value.data.ref_val.hBase,
                               variable->value.data.ref_val.reference);
   }
   else if( SEVAR_GET_TYPE(&(variable->value))==VReferenceIndex )
   {
      rSEObject robj;
      rSEMembers rMembers;
      uint index;

      index = (uint)(ulong)(variable->value.data.ref_val.reference);
      SEOBJECT_ASSIGN_LOCK_R(robj,variable->value.data.ref_val.hBase);
      /* get these from the object member itself */
      assert( index < SEOBJECT_PTR(robj)->used );
      SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);
      SEOBJECT_UNLOCK_R(robj);
      ret = SEMEMBERS_PTR(rMembers)[index].attributes;
      SEMEMBERS_UNLOCK_R(rMembers);
   }
   else
   {
      rSEVar var;
      ret = 0;
      var = seapiGetValue(call,variable);
      if( SEVAR_GET_TYPE(var)==VObject )
      {
         rSEObject robj;
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(var));
         if ( SEOBJECT_PTR(robj)->func != NULL )
            ret = SEOBJECT_PTR(robj)->func->attributes;
         SEOBJECT_UNLOCK_R(robj);
      }
   }
   return ret;
}

   JSECALLSEQ( void )
jseReturnLong(jseContext call,slong longValue)
{
   wSEVar var = STACK_PUSH;
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseReturnLong"),return);
   assert( call->next==NULL );

   SEVAR_INIT_SLONG(var,longValue);
}

   JSECALLSEQ( void )
jseReturnNumber(jseContext call,jsenumber number)
{
   wSEVar var = STACK_PUSH;
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseReturnNumber"),return);
   assert( call->next==NULL );
   SEVAR_INIT_NUMBER(var,number);
}

   JSECALLSEQ( void )
jseReturnVar(jseContext call,jseVariable variable,
             jseReturnAction RetAction)
{
   rSEVar ret;
   wSEVar tmp;

   JSE_API_STRING(ThisFuncName,"jseReturnVar");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   /* We always return the given variable's value, there is no
    * return-by-reference (what would that mean?) The copy-to-temp-var
    * differentiation really only made sense in old versions of the
    * core.
    */
   ret = seapiGetValue(call,variable);
   tmp = STACK_PUSH;
   SEVAR_COPY(tmp,ret);
   if( RetAction==jseRetTempVar )
   {
      seapiDeleteVariable(call,variable);
   }
}

   JSECALLSEQ( jsebool )
jseCompare(jseContext call,jseVariable variable1,jseVariable variable2,
           slong *CompareResult)
{
   wSEVar var1,var2;
   jsebool ret;
   JSE_API_STRING(ThisFuncName,"jseCompare");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );
   JSE_API_ASSERT_(CompareResult,4,ThisFuncName,return False);


   if( CompareResult==JSE_COMPVAR &&
       ((SEVAR_GET_TYPE(&(variable1->value))==VReference &&
        SEVAR_GET_TYPE(&(variable2->value))==VReference) ||
       (SEVAR_GET_TYPE(&(variable1->value))==VReferenceIndex &&
        SEVAR_GET_TYPE(&(variable2->value))==VReferenceIndex))
       )
   {
      if( variable1->value.data.ref_val.hBase==variable2->value.data.ref_val.hBase &&
          variable1->value.data.ref_val.reference==variable2->value.data.ref_val.reference )
         return True;
   }

   var1 = seapiGetValue(call,variable1);
   var2 = seapiGetValue(call,variable2);

   if( CompareResult==JSE_COMPVAR )
   {
      if( SEVAR_GET_TYPE(var1)==SEVAR_GET_TYPE(var2) )
      {
         if( SEVAR_GET_TYPE(var1)==VObject )
         {
            ret = SEVAR_GET_OBJECT(var1)==SEVAR_GET_OBJECT(var2);
         }
         else if(
# if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
                 SEVAR_GET_TYPE(var1)==VBuffer ||
# endif
                 SEVAR_GET_TYPE(var1)==VString )
         {
            ret = SEVAR_GET_STRING(var1).loffset==SEVAR_GET_STRING(var2).loffset &&
                  SEVAR_GET_STRING(var1).data==SEVAR_GET_STRING(var2).data;
         }
         else
         {
            ret = (var1==var2);
         }
      }
      else
      {
         ret = False;
      }
   }
   else
   {
      if( CompareResult==JSE_COMPLESS )
      {
         ret = (SEVAR_COMPARE_LESS(call,var1,var2)==1);
      }
      else if( CompareResult==JSE_COMPEQUAL )
      {
         ret = SEVAR_COMPARE_EQUALITY(call,var1,var2);
      }
      else
      {
         ret = sevarCompare(call,var1,var2,CompareResult);
      }
   }

   return ret;
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyFindVariable(jseContext call, const jsecharptr name, ulong flags,
                      char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jseFindVariable(jseContext call, const jsecharptr name, ulong flags)
#endif
{
   wSEVar it = STACK_PUSH;
   jsebool found;
   uword8 tmp;
   VarName varname;
   jseVariable ret;


   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseFindVariable"),
                  return NULL);
   assert( call->next==NULL );

   varname = GrabStringTableEntryStrlen(call,name,&tmp);
   SEVAR_INIT_UNDEFINED(it);
   found = callFindAnyVariable(call,varname,True,True);
   ReleaseStringTableEntry(/*call,*/varname,tmp);

   if( found )
   {
      ret = SEAPI_RETURN(call,it,(flags&jseCreateVar)?TRUE:FALSE,UNISTR("jseFindVariable"));
   }
   else
   {
      ret = NULL;
   }
   STACK_POP;
   return ret;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyCreateVariable(jseContext call,jseDataType VDataType,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseCreateVariable(jseContext call,jseDataType VDataType)
#endif
{
   wSEVar ret = STACK_PUSH;
   jseVariable retvar;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseCreateVariable"),
                  return NULL);
   assert( call->next==NULL );

   if( !SEVAR_IS_VALID_TYPE(VDataType) )
   {
#     if ( 0 < JSE_API_ASSERTLEVEL )
#           if (0!=JSE_API_ASSERTNAMES)
               SetLastApiError(
      UNISTR("%s: Invalid data type"),UNISTR("jseCreateVariable"));
#        else
               SetLastApiError(UNISTR("Invalid data type"));
#        endif
#     endif
      SEVAR_INIT_UNDEFINED(ret);
   }
   sevarInitType(call,ret,VDataType);
   retvar = SEAPI_RETURN(call,ret,TRUE,UNISTR("jseCreateVariable"));
   STACK_POP;
   return retvar;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyCreateSiblingVariable(jseContext call,jseVariable olderSiblingVar,
                               JSE_POINTER_SINDEX elem,
                               char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseCreateSiblingVariable(jseContext call,jseVariable olderSiblingVar,
                         JSE_POINTER_SINDEX elem)
#endif
{
   wSEVar dest = STACK_PUSH;
   rSEVar old;
   jseVariable ret;

   JSE_API_STRING(ThisFuncName,"jseCreateSiblingVariable");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   SEVAR_INIT_UNDEFINED(dest);

   old = seapiGetValue(call,olderSiblingVar);
   if( SEVAR_ARRAY_PTR(old) )
   {
      SEVAR_INIT_ARRAY_SIBLING(dest,old,elem);
   }
   else
   {
      SEVAR_INIT_OBJECT_SIBLING(dest,old);
   }

   ret = SEAPI_RETURN(call,dest,TRUE,UNISTR("jseCreateSiblingVariable"));
   STACK_POP;
   return ret;
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyCreateConvertedVariable(jseContext call,jseVariable variableToConvert,
                                 jseConversionTarget targetType,char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jseCreateConvertedVariable(jseContext call,jseVariable variableToConvert,
                           jseConversionTarget targetType)
#endif
{
   wSEVar dest;
   rSEVar tmp;
   jseVariable ret;

   JSE_API_STRING(ThisFuncName,"jseCreateConvertedVariable");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   tmp = seapiGetValue(call,variableToConvert);
   dest = STACK_PUSH;
   SEVAR_COPY(dest,tmp);
   sevarConvert(call,dest,targetType);
   if( CALL_QUIT(call) )
   {
      ret = NULL;
   }
   else
   {
      ret = SEAPI_RETURN(call,dest,TRUE,UNISTR("jseCreateConvertedVariable"));
      STACK_POP;
   }
   return ret;
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyCreateLongVariable(jseContext call,slong value,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseCreateLongVariable(jseContext call,slong value)
#endif
{
   wSEVar tmp = STACK_PUSH;
   jseVariable ret;


   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseCreateLongVariable"),
                  return NULL);
   assert( call->next==NULL );

   SEVAR_INIT_SLONG(tmp,value);
   ret = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCreateLongVariable"));
   STACK_POP;
   return ret;
}


   JSECALLSEQ( void )
jseDestroyVariable(jseContext call,jseVariable variable)
{
   JSE_API_STRING(ThisFuncName,"jseDestroyVariable");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   if( variable ) seapiDeleteVariable(call,variable);
}

   JSECALLSEQ( jseDataType )
jseGetType(jseContext call,jseVariable variable)
{
   jseVarType ret;


   JSE_API_STRING(ThisFuncName,"jseGetType");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return 0);
   assert( call->next==NULL );

   ret = variable?SEVAR_GET_TYPE(seapiGetValue(call,variable)):(jseVarType)VUndefined;
   assert( SEVAR_IS_VALID_TYPE(ret) );

   return ret;
}

   jsenumber
GenericGetNumber(
#  if (0!=JSE_API_ASSERTNAMES)
      const jsecharptr ThisFuncName,
#  endif
   jseContext call,jseVariable variable)
{
   wSEVar var;
   rSEVar tmp;
   jsenumber number;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return jseNaN);
   assert( call->next==NULL );

   tmp = seapiGetValue(call,variable);
   var = STACK_PUSH;
   SEVAR_COPY(var,tmp);
   number = sevarConvertToNumber(call,var);
   STACK_POP;

   return number;
}

   JSECALLSEQ( jsebool )
jseEvaluateBoolean(jseContext call,jseVariable variable)
{
   wSEVar var;
   rSEVar tmp;
   jsebool ret;

   JSE_API_STRING(ThisFuncName,"jseEvaluateBoolean");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );


   tmp = seapiGetValue(call,variable);
   var = STACK_PUSH;
   SEVAR_COPY(var,tmp);
   ret = sevarConvertToBoolean(call,var);
   STACK_POP;

   return ret;
}

   JSECALLSEQ( void )
jsePutBoolean(jseContext call,jseVariable variable,jsebool boolValue)
{
   wSEVar val;
   JSE_API_STRING(ThisFuncName,"jsePutBoolean");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   val = STACK_PUSH;
   SEVAR_INIT_BOOLEAN(val,boolValue!=False);
   seapiPutValue(call,variable,val);
   STACK_POP;
}

   JSECALLSEQ( void )
jsePutNumber(jseContext call,jseVariable variable,jsenumber number)
{
   wSEVar val;
   JSE_API_STRING(ThisFuncName,"jsePutNumber");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   val = STACK_PUSH;
   SEVAR_INIT_NUMBER(val,number);
   seapiPutValue(call,variable,val);
   STACK_POP;
}

   JSECALLSEQ( void )
jsePutLong(jseContext call,jseVariable variable,slong longValue)
{
   wSEVar val;
   JSE_API_STRING(ThisFuncName,"jsePutLong");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   val = STACK_PUSH;
   SEVAR_INIT_SLONG(val,longValue);
   seapiPutValue(call,variable,val);
   STACK_POP;
}

#if !defined(NDEBUG) && JSE_TRACKVARS==1
   void _HUGE_ *
GenericGetDataPtr(
#  if (0!=JSE_API_ASSERTNAMES)
      const jsecharptr ThisFuncName,
#  endif
   jseContext call,jseVariable variable,
   JSE_POINTER_UINDEX *filled,jseVarType vType,
   jsebool Writeable,char *FILE,int LINE)
#else
   void _HUGE_ *
GenericGetDataPtr(
#  if (0!=JSE_API_ASSERTNAMES)
      const jsecharptr ThisFuncName,
#  endif
   jseContext call,jseVariable variable,
   JSE_POINTER_UINDEX *filled,jseVarType vType,
   jsebool Writeable)
#endif
{
   wSEVar ret;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   ret = seapiGetValue(call,variable);
   if( SEVAR_GET_TYPE(ret) != vType )
   {
      if( ret!=&(variable->last_access) )
      {
         SEVAR_COPY(&(variable->last_access),ret);
         ret = &(variable->last_access);
      }
      if( !Writeable &&
          (jseOptLenientConversion & call->Global->ExternalLinkParms.options) )
      {
         sevarConvert(call,ret,
#           if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
                      vType == VBuffer ? jseToBuffer :
#           endif
                      jseToString);
      }
      else
      {
         /* should not have called in this way; but don't crash */
         if ( filled ) *filled = 0;
#     if ( 0 < JSE_API_ASSERTLEVEL )
#                  if (0!=JSE_API_ASSERTNAMES)
         SetLastApiError(
            UNISTR("%s: Data type is not correct string or buffer type"),ThisFuncName);
#        else
         SetLastApiError(UNISTR("Data type is not correct string or buffer type"));
#        endif
#     endif
         return UNISTR("");
      }
   }


   if( SEVAR_GET_TYPE(&(variable->value))==VReference )
   {
      /* make a temp variable to lock it into memory. */
      SEAPI_RETURN(call,ret,FALSE,UNISTR("GenericGetDataPtr"));
   }

   if( filled ) *filled = SEVAR_STRING_LEN(ret);
#  if JSE_MEMEXT_STRINGS==1
      if( variable->data ) SEVAR_FREE_DATA(call,variable->data);
      return variable->data = (void *)sevarGetData(call,ret);
#  else
      return (void _HUGE_ *)sevarGetData(call,ret);
#  endif
}



#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
/* Determine if calling script function is cbehavior, FALSE if none */
   static jsebool NEAR_CALL
callLocalCBehavior(struct Call *call)
{
   const struct Function *func_orig = call->funcptr;
   wSEVar wfptr = FRAME;

   /* no enclosing function */
   if( func_orig==NULL ) return False;

   /* Find the enclosing local function */
   while( !FUNCTION_IS_LOCAL(func_orig) )
   {
      uword16 num_args = (uword16)SEVAR_GET_STORAGE_LONG(wfptr-ARGS_OFFSET);
#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
         wfptr = STACK_FROM_STACKPTR(SEVAR_GET_STORAGE_LONG(wfptr));
         if( wfptr==call->Global->growingStack ) return False;
#     else
         wfptr = SEVAR_GET_STORAGE_PTR(wfptr);
         /* no enclosing local function */
         if( wfptr==NULL ) return False;
#     endif
      {
         rSEObject robj;
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(wfptr - (num_args + FUNC_OFFSET)));
         func_orig = SEOBJECT_PTR(robj)->func;
         SEOBJECT_UNLOCK_R(robj);
      }
   }
   return FUNCTION_C_BEHAVIOR(func_orig);
}
#endif /* #if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS) */

   void
GenericPutDataPtr(
#  if (0!=JSE_API_ASSERTNAMES)
      const jsecharptr ThisFuncName,
#  endif
   jseContext call,jseVariable variable,void _HUGE_ *data,
   jseVarType vType,JSE_POINTER_UINDEX *size)
{
   wSEVar val;

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );
#  if ( 0 < JSE_API_ASSERTLEVEL )
   if ( NULL != size  &&  0 != *size )
   {
      JSE_API_ASSERT_(data,3,ThisFuncName,return);
   }
#  endif
   assert( SEVAR_IS_VALID_TYPE(vType) );

   if( data==NULL ) return;


   /* In C functions, we physically update the old pointer.
    * In regular functions, we write a new string by updating it first.
    * We must also always copy constant strings.
    */

   val = seapiGetValue(call,variable);
#  if JSE_MEMEXT_STRINGS!=0
      if( variable->data )
      {
         SEVAR_FREE_DATA(call,variable->data);
         variable->data = NULL;
      }
#  endif
   if ( SEVAR_GET_TYPE(val)==VString )
   {
#     if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
      if ( SESTR_IS_CONSTANT(SEVAR_GET_STRING(val).data)  ||  !callLocalCBehavior(call) )
#     endif
         sevarDuplicateString(call,val);
   }

   if( val!=NULL && SEVAR_GET_TYPE(val)==vType )
   {
      JSE_POINTER_SINDEX minidx;

      sevarGetArrayLength(call,val,&minidx);
      if( minidx<0 )
      {
         /* merge with existing data, this is so something like:
          *
          * Clib.strcpy(foo+5,"goo");
          *
          * will work as expected.
          */

#        if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
         if( vType!=VString )
         {
            JSE_MEMEXT_R void *olddata = SESTRING_GET_DATA(val->data.string_val.data);
            ubyte *newdata = jseMustMalloc(void,((*size)-minidx+1)*sizeof(jsechar));
            assert( minidx <= 0 );
            memcpy(newdata,olddata,(JSE_POINTER_UINDEX)-minidx);
            SESTRING_UNGET_DATA(val->data.string_val.data,olddata);
            memcpy(newdata-minidx,data,*size);
            newdata[-minidx+*size] = '\0';
            /* physically update the old ptr */
            SESTRING_FREE_DATA(val->data.string_val.data);
            SESTRING_PUT_DATA(val->data.string_val.data,newdata,
                              ((*size)-minidx+1)*sizeof(jsechar));
            val->data.string_val.data->length = (*size)-minidx;
         }
         else
#        endif
         {
            JSE_POINTER_UINDEX actual_size = size?(*size):strlen_jsechar((const jsecharptr)data);
            ubyte *newdata = jseMustMalloc(ubyte,(actual_size-minidx+1)*sizeof(jsechar));
            JSE_POINTER_UINDEX s1,s2;
            JSE_MEMEXT_R void *olddata = SESTRING_GET_DATA(val->data.string_val.data);

            assert( minidx <= 0 );
            memcpy(newdata,olddata,s1 = BYTECOUNT_FROM_STRLEN(olddata,
                                                              (JSE_POINTER_UINDEX)-minidx));
            memcpy(newdata+s1,data,
                   s2 = BYTECOUNT_FROM_STRLEN((const jsecharptr)data,actual_size));
            assert( sizeof(jsecharptrdatum) == sizeof_jsechar('\0') );
            *((jsecharptrdatum *)(newdata+s1+s2)) = '\0';
            SESTRING_UNGET_DATA(val->data.string_val.data,olddata);
            /* physically update the old ptr */
            SESTRING_FREE_DATA(val->data.string_val.data);
            SESTRING_PUT_DATA(val->data.string_val.data,newdata,
                              (actual_size-minidx+1)*sizeof(jsechar));
            val->data.string_val.data->length = actual_size-minidx;
         }
      }
      else
      {
         if ( size )
         {
#           if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
            if( vType==VBuffer )
            {
               void *newdata = jseMustMalloc(void,(*size)+sizeof(jsecharptrdatum));
               memcpy(newdata,data,*size);
               *(((ubyte *)newdata)+(*size)) = '\0';
               SESTRING_FREE_DATA(val->data.string_val.data);
               SESTRING_PUT_DATA(val->data.string_val.data,newdata,(*size)+sizeof(jsecharptrdatum));
               val->data.string_val.data->length = *size;
            }
            else
#           endif
            {
               JSE_POINTER_UINDEX len = BYTECOUNT_FROM_STRLEN(data,*size);
               void *newdata = jseMustMalloc(void,len+sizeof(jsecharptrdatum));
               memcpy(newdata,data,len);
               *((jsechar *)(((ubyte *)newdata)+len)) = '\0';
               SESTRING_FREE_DATA(val->data.string_val.data);
               SESTRING_PUT_DATA(val->data.string_val.data,newdata,len+sizeof(jsecharptrdatum));
               val->data.string_val.data->length = *size;
            }
         }
         else
         {
            JSE_POINTER_UINDEX length = strlen_jsechar( (const jsecharptr )data);
            JSE_POINTER_UINDEX len = BYTECOUNT_FROM_STRLEN(data,length);
            void *newdata = jseMustMalloc(void,len+sizeof(jsechar));

            /* only way to not pass length is for null-term string length */
            assert( VString == vType );
            memcpy(newdata,data,len);
            *((jsechar *)(((ubyte *)newdata)+len)) = '\0';
            SESTRING_FREE_DATA(val->data.string_val.data);
            SESTRING_PUT_DATA(val->data.string_val.data,newdata,len+sizeof(jsechar));
            val->data.string_val.data->length = length;
         }
      }

#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
   /* recalculate physical length */
   /* NYI: MBCS byte length probably can be done better in
    *      the individual cases above */
   val->data.string_val.data->bytelength =
      BYTECOUNT_FROM_STRLEN(SESTRING_GET_DATA(val->data.string_val.data),
                            val->data.string_val.data->length);
#  endif
   }

   /* put it back to make sure dynamic changes happen */
   seapiPutValue(call,variable,val);
}

   JSECALLSEQ( void )
jseConvert(jseContext call,jseVariable variable,jseDataType dType)
{
   wSEVar orig;

   JSE_API_STRING(ThisFuncName,"jseConvert");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );


   if( !SEVAR_IS_VALID_TYPE(dType) )
   {
#     if ( 0 < JSE_API_ASSERTLEVEL )
#           if (0!=JSE_API_ASSERTNAMES)
               SetLastApiError(
      UNISTR("%s: Invalid data type"),UNISTR("jseConvert"));
#        else
               SetLastApiError(UNISTR("Invalid data type"));
#        endif
#     endif
   }
   else
   {
      orig = seapiGetValue(call,variable);
      if( SEVAR_GET_TYPE(orig)!=dType )
      {
         orig = STACK_PUSH;
         sevarInitType(call,orig,dType);
         seapiPutValue(call,variable,orig);
         STACK_POP;
      }
   }
}

#pragma codeseg JSELIB2_TEXT

   JSECALLSEQ( jsebool )
jseAssign(jseContext call,jseVariable destVar,jseVariable srcVar)
{
   wSEVar src;

   JSE_API_STRING(ThisFuncName,"jseAssign");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );

   seapiPutValue(call,destVar,src = seapiGetValue(call,srcVar));

#  if ( 0 != JSE_DYNAMIC_OBJ_INHERIT )
   /* if assigning a _prototype to another object, then inherit
    * the dynamic properties of that other object
    */
   if( SEVAR_GET_TYPE(&(destVar->value))==VReference
    && destVar->value.data.ref_val.reference==STOCK_STRING(_prototype)
    && SEVAR_GET_TYPE(src)==VObject )
   {
      uword8 srcFlags;
      rSEObject robj;
      wSEObject wobj;

      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(src));
      srcFlags = SEOBJECT_PTR(robj)->flags;
      SEOBJECT_UNLOCK_R(robj);
      SEOBJECT_ASSIGN_LOCK_W(wobj,destVar->value.data.ref_val.hBase);
      if( (srcFlags & OBJ_IS_DYNAMIC)!=0 )
         SEOBJ_MAKE_DYNAMIC(wobj);
      SEOBJECT_UNLOCK_W(wobj);
   }
#  endif

   return True;
}



#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   static jseVariable
jseMemberGuts(jseContext call,jseVariable objectVar,VarName vName,
              jseDataType DType,uword16 flags,char *FILE,int LINE)
#else
   static jseVariable
jseMemberGuts(jseContext call,jseVariable objectVar,VarName vName,
              jseDataType DType,uword16 flags)
#endif
{
   jseVariable done;
   wSEVar vobj = seapiGetValue(call,objectVar);
   jsebool found = False;
   wSEVar tmpvar = STACK_PUSH;
   wSEVar ret = STACK_PUSH;
   rSEObject robj;
   hSEObject hobj;
   int prop_flags = 0;


   SEVAR_INIT_UNDEFINED(tmpvar);
   SEVAR_INIT_UNDEFINED(ret);

   if( vobj==NULL )
   {
      SEVAR_INIT_OBJECT(tmpvar,CALL_GLOBAL(call));
      vobj = tmpvar;
   }
   else if( SEVAR_GET_TYPE(vobj)!=VObject )
   {
      /* Assert here to help the person track down the problem */
      assert( False );
      return NULL;
   }

   hobj = SEVAR_GET_OBJECT(vobj);
   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);

   if( (flags&jseLockRead)==0 )
      prop_flags |= HP_REFERENCE;
   if( (flags&jseDontSearchPrototype)!=0 )
      prop_flags |= HP_NO_PROTOTYPE;

   found = seobjHasProperty(call,robj,vName,ret,prop_flags);
   SEOBJECT_UNLOCK_R(robj);

   if( !found )
   {
      /* the member is undefined, if we are not supposed to create
       * types, this is a signal to return NULL.
       */
      if( flags & jseDontCreateMember )
      {
         STACK_POPX(2);
         return NULL;
      }
      else
      {
         /* Else we create it with the given type and put it in */
         sevarInitType(call,ret,DType);
         SEVAR_PUT_VALUE(call,vobj,vName,ret);

         /* even if an error, jseMember() (i.e. when the jseDontCreateMember
          * flag is off, this branch of the if) must never return NULL.
          * We still return the reference.
          */
      }
   }

   assert( ret!=NULL );

   /* With lock read, we return that value we found */
   if( (flags & jseLockRead)==0 )
   {
      /* If not lock read, we create a reference so when the user
       * goes to write to it, any dynamic stuff happens. Note that
       * jseLockWrite really has no meaning any more, but the effect
       * will be the same.
       */

      /* if the given member is itself a reference, return
       * it instead, since we don't ever allow 'doubly indirect'
       * stuff. It is pointless to point to a member which
       * just then points to something else, point at that
       * something else instead (plus the internals all
       * assume and assert that this isn't happening.)
       */
      if( SEVAR_GET_TYPE(ret)<VReference )
      {
         SEVAR_INIT_REFERENCE(ret,hobj,vName);
      }
   }
   /* We have something to return, use the CreateVar flag to determine
    * if this should be destroyed by the user.
    */
   done = SEAPI_RETURN(call,ret,(flags&jseCreateVar)!=0,UNISTR("jseMemberEx"));
   STACK_POPX(2);
   return done;
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyMemberInternal(jseContext call,jseVariable objectVar,
                  const jsecharptr Name,
                  jseDataType DType,uword16 flags,char *FILE,int LINE)
{
   uword8 tmp;
   jseVariable ret;

   VarName vName = GrabStringTableEntryStrlen(call,Name,&tmp);
   ret = jseMemberGuts(call,objectVar,vName,DType,flags,FILE,LINE);
   ReleaseStringTableEntry(/*call,*/vName,tmp);
   return ret;
}
#else
   JSECALLSEQ( jseVariable )
jseMemberInternal(jseContext call,jseVariable objectVar,
            const jsecharptr Name,
            jseDataType DType,uword16 flags)
{
   uword8 tmp;
   jseVariable ret;

   VarName vName = GrabStringTableEntryStrlen(call,Name,&tmp);
   ret = jseMemberGuts(call,objectVar,vName,DType,flags);
   ReleaseStringTableEntry(/*call,*/vName,tmp);
   return ret;
}
#endif



#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyIndexMemberEx(jseContext call,jseVariable objectVar,
                       JSE_POINTER_SINDEX index,jseDataType dType,uword16 flags,
                       char *FILE,int LINE)
{
   return jseMemberGuts(call,objectVar,
                        (index<0)?
                        NegativeStringTableEntry(index):
                        PositiveStringTableEntry(index),
                        dType,flags,FILE,LINE);
}
#else
   JSECALLSEQ( jseVariable )
jseIndexMemberEx(jseContext call,jseVariable objectVar,
                 JSE_POINTER_SINDEX index,jseDataType dType,uword16 flags)
{
   return jseMemberGuts(call,objectVar,
                        (index<0)?
                        NegativeStringTableEntry(index):
                        PositiveStringTableEntry(index),
                        dType,flags);
}
#endif


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyGetNextMember(jseContext call,jseVariable objectVariable,
                       jseVariable prevMemberVariable,
                       const jsecharptr * name,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseGetNextMember(jseContext call,jseVariable objectVariable,
                 jseVariable prevMemberVariable,
                 const jsecharptr * name)
#endif
{
   rSEVar objvar;
   wSEVar ret;
   jseVariable apiret;
   hSEObject hobj;
   rSEObject robj;

   JSE_API_STRING(ThisFuncName,"jseGetNextMember");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(name,4,ThisFuncName,return NULL);


   if( objectVariable!=NULL )
   {
      objvar = seapiGetValue(call,objectVariable);
      if( SEVAR_GET_TYPE(objvar)!=VObject ) return NULL;
      hobj = SEVAR_GET_OBJECT(objvar);
   }
   else
   {
      /* NULL = global object */
      hobj = CALL_GLOBAL(call);
   }

   ret = STACK_PUSH;
   if( prevMemberVariable==NULL )
   {
      SEVAR_INIT_REFERENCE_INDEX(ret,hobj,0);
   }
   else
   {
      MemCountUInt index;

      /* the returned variables are references into the object,
       * so the index variable better be indexing into this
       * same object.
       */
      assert( SEVAR_GET_TYPE(&(prevMemberVariable->value))==VReferenceIndex &&
              prevMemberVariable->value.data.ref_val.hBase==hobj );
      index = ((MemCountUInt)(ulong)(prevMemberVariable->value.data.ref_val.reference))+1;
      SEVAR_INIT_REFERENCE_INDEX(ret,hobj,(VarName)index);
   }

   /* check if we have used up all the members */
   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
   if( (MemCountUInt)(ulong)(ret->data.ref_val.reference) >= SEOBJECT_PTR(robj)->used )
   {
      apiret = NULL;
      if( name ) *name = NULL;
   }
   else
   {
      apiret = SEAPI_RETURN(call,ret,False,UNISTR("jseGetNextMember"));
      if( name )
      {
         rSEMembers rMembers;
         VarName n;
         SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);
         n = SEMEMBERS_PTR(rMembers)[(MemCountUInt)(ulong)(ret->data.ref_val.reference)].name;
         SEMEMBERS_UNLOCK_R(rMembers);
         *name = ( n )
               ? GetStringTableEntry(call,n,NULL)
               : NULL ;
      }
   }
   SEOBJECT_UNLOCK_R(robj);

   STACK_POP;

   return apiret;
}

   JSECALLSEQ( void )
jseDeleteMember(jseContext call,jseVariable objectVar,
                const jsecharptr name)
{
   VarName varname;
   rSEVar objVar = seapiGetValue(call,objectVar);
   wSEVar var = STACK_PUSH;

   JSE_API_STRING(ThisFuncName,"jseDeleteMember");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );
   JSE_API_ASSERT_(name,3,ThisFuncName,return);

   if ( objVar == NULL )
   {
      SEVAR_INIT_OBJECT(var,CALL_GLOBAL(call));
      objVar = var;
   }
   else
   {
      SEVAR_INIT_UNDEFINED(var);
   }

   if ( VObject == SEVAR_GET_TYPE(objVar) )
   {
      wSEObject wobj;
      uword8 tmp;
      varname = GrabStringTableEntryStrlen(call,name,&tmp);

      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(objVar));
      seobjDeleteMember(call,wobj,varname,False);
      SEOBJECT_UNLOCK_W(wobj);
      ReleaseStringTableEntry(/*call,*/varname,tmp);
   }

   STACK_POP;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyActivationObject(jseContext call,char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseActivationObject(jseContext call)
#endif
{
   if( call->hVariableObject==hSEObjectNull ) callCreateVariableObject(call,NULL);

   if( call->hVariableObject==hSEObjectNull ||
       call->hVariableObject==call->hGlobalObject )
   {
      return NULL;
   }
   else
   {
      wSEVar retvar = STACK_PUSH;
      jseVariable ret;

      SEVAR_INIT_OBJECT(retvar,call->hVariableObject);
      ret = SEAPI_RETURN(call,retvar,False,UNISTR("jseActivationObject"));
      STACK_POP;
      return ret;
   }
}

   static rSEVar NEAR_CALL
jselibFindFunction(jseContext call,rSEVar FunctionVar,const struct Function **FindFunc,
                   const jsecharptr FunctionName /*null if don't use sub-function*/,
                   rSEObjectMem *rMem/*set SEOBJECTMEM_PTR(rMem) non-NULL if must free*/)
     /* return NULL if not a function object */
{
   rSEVar ret = NULL;
   hSEObject hLook;

   if( FunctionVar == NULL || SEVAR_GET_TYPE(FunctionVar)!=VObject )
   {
      hLook = CALL_GLOBAL(call);
   }
   else
   {
      hLook = SEVAR_GET_OBJECT(FunctionVar);
   }

   if( FunctionName!=NULL )
   {
      uword8 temp;
      rSEObject rLook;
      VarName funcname = GrabStringTableEntryStrlen(call,FunctionName,&temp);
      SEOBJECT_ASSIGN_LOCK_R(rLook,hLook);
      *rMem = rseobjGetMemberStruct(call,rLook,funcname);
      SEOBJECT_UNLOCK_R(rLook);
      ReleaseStringTableEntry(/*call,*/funcname,temp);

      if( NULL != SEOBJECTMEM_PTR(*rMem) )
      {
         ret = SEOBJECTMEM_VAR(*rMem);
         if( SEVAR_GET_TYPE(ret)!=VObject
          || NULL == (*FindFunc = sevarGetFunction(call,ret)) )
         {
            /* failed to find full function - free object mem and return NULL */
            SEOBJECTMEM_UNLOCK_R(*rMem);
            SEOBJECTMEM_PTR(*rMem) = NULL;
            ret = NULL;
         }
      }
   }
   else
   {
      SEOBJECTMEM_PTR(*rMem) = NULL;
      if( NULL != (*FindFunc = sevarGetFunction(call,FunctionVar)) )
      {
         ret = FunctionVar;
      }
   }

   return ret;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyGetFunction(jseContext call,jseVariable object,
                     const jsecharptr functionName,jsebool errorIfNotFound,
                     char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseGetFunction(jseContext call,jseVariable object,
               const jsecharptr functionName,jsebool errorIfNotFound)
#endif
{
   const struct Function *func;
   rSEVar FunctionVar;
   jseVariable ret;
   rSEObjectMem rMem;

   JSE_API_STRING(ThisFuncName,"jseGetFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(functionName,3,ThisFuncName,return NULL);

   FunctionVar = jselibFindFunction(call,seapiGetValue(call,object),&func,functionName,&rMem);
   if ( NULL == FunctionVar )
   {
      if ( errorIfNotFound )
      {
         callQuit(call,textcoreFUNCTION_NAME_NOT_FOUND,functionName);
      }
      ret = NULL;
   }
   else
   {
      ret = SEAPI_RETURN(call,FunctionVar,FALSE,UNISTR("jseGetFunction"));
#     if 0!=JSE_MEMEXT_MEMBERS
         if ( NULL != SEOBJECTMEM_PTR(rMem) )
            SEOBJECTMEM_UNLOCK_R(rMem);
#     endif
   }

   return ret;
}

   static jsebool NEAR_CALL
IsItAFunction(jseContext call,rSEVar functionVariable,
              jsebool TestIfLibraryFunction)
{
   const struct Function *func;
   rSEVar v;
   jsebool ret;
   rSEObjectMem rMem;

   assert( NULL != call );
   v =  jselibFindFunction(call,functionVariable,&func,NULL,&rMem);
   if ( NULL == v )
   {
      ret = False;
   }
   else
   {
      ret = ( !TestIfLibraryFunction || !FUNCTION_IS_LOCAL(func) );
#     if 0!=JSE_MEMEXT_MEMBERS
         if ( NULL != SEOBJECTMEM_PTR(rMem) )
            SEOBJECTMEM_UNLOCK_R(rMem);
#     endif
   }
   return ret;
}

   JSECALLSEQ( jsebool )
jseIsFunction(jseContext call,jseVariable functionVariable)
{
   JSE_API_STRING(ThisFuncName,"jseIsFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );

   return IsItAFunction(call,seapiGetValue(call,functionVariable),False);
}

   JSECALLSEQ(jsebool)
jseIsLibraryFunction(jseContext call,jseVariable functionVariable)
{
   JSE_API_STRING(ThisFuncName,"jseIsLibraryFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );

   return IsItAFunction(call,seapiGetValue(call,functionVariable),True);
}


   void
secallstackPush(/*struct Call *call,*/
                struct seCallStack *This,
                seAPIVar v,jsebool deleteme)
{
   This->vars = jseMustReMalloc(struct seCallStackVar,This->vars,
                                (This->Count+1) * sizeof(This->vars[0]));
   This->vars[This->Count].var = v;
   This->vars[This->Count].free_on_del = deleteme;
   This->Count++;
}


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jsebool )
jseReallyCallFunctionEx(jseContext call,jseVariable jsefunc,jseStack jsestack,
                        jseVariable *retvar,jseVariable thisVar,uint flags,
                        char *FILE,int LINE)
#else
   JSECALLSEQ( jsebool )
jseCallFunctionEx(jseContext call,jseVariable jsefunc,jseStack jsestack,
                  jseVariable *retvar,jseVariable thisVar,uint flags)
#endif
{
   rSEVar rvar,tmp2,ret;
   wSEVar tmp;
   const struct Function *func;
   uint origdepth, depth;
   jsebool retbool;
   jsebool old_must = call->mustPrintError;


   JSE_API_STRING(ThisFuncName,"jseCallFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );
   if( jsestack!=NULL )
   {
      JSE_API_ASSERT_C(jsestack,3,jseStack_cookie,ThisFuncName,return False);
   }

   CALL_SET_ERROR(call,FlowNoReasonToQuit);
   *retvar = NULL;

   rvar = seapiGetValue(call,jsefunc);

#  if ( 0 < JSE_API_ASSERTLEVEL )
   if( SEVAR_GET_TYPE(rvar)!=VObject )
   {
      SetLastApiError( UNISTR("%s: parameter 2 not a function"),ThisFuncName );
      return False;
   }
#  endif

   tmp = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(tmp);
   if( (flags & JSE_FUNC_CONSTRUCT)!=0 )
   {
      rSEObjectMem rvarmem;

      sevarInitNewObject(call,tmp,rvar);
      rvar = seobjGetFuncVar(call,rvar,STOCK_STRING(_construct),&rvarmem);
      tmp = STACK_PUSH;
      SEVAR_COPY(tmp,rvar);
      func = sevarGetFunction(call,rvar);
#     if 0!=JSE_MEMEXT_MEMBERS
         if ( NULL != SEOBJECTMEM_PTR(rvarmem) )
            SEOBJECTMEM_UNLOCK_R(rvarmem);
#     endif
   }
   else
   {
      if( thisVar )
      {
         tmp2 = seapiGetValue(call,thisVar);
         SEVAR_COPY(tmp,tmp2);
      }
      else
      {
         SEVAR_INIT_OBJECT(tmp,CALL_GLOBAL(call));
      }
      func = sevarGetFunction(call,rvar);
      tmp = STACK_PUSH;
      SEVAR_COPY(tmp,rvar);
   }

#  if ( 0 < JSE_API_ASSERTLEVEL )
   if ( NULL == func )
   {
      STACK_POPX(2);
      SetLastApiError( UNISTR("%s: parameter 2 not a function"),ThisFuncName );
      return False;
   }
#  endif

   assert( NULL != func );

   /* transfer the parameters to the real stack */
   if( jsestack!=NULL )
   {
      origdepth = depth = SECALLSTACK_DEPTH(jsestack);
      while( depth-- )
      {
         /* top of the stack is 0 */
         jseVariable param = SECALLSTACK_PEEK(jsestack,depth);
         wSEVar onstack;
         uword8 varAttrib = 0;
         uint index = origdepth-depth-1;

         if( FUNCTION_IS_LOCAL(func) &&
             index < ((struct LocalFunction*)func)->InputParameterCount)
         {
            varAttrib = ((struct LocalFunction*)func)->items[index].VarAttrib;
            assert(varAttrib == 0 || varAttrib == 1);
         }

         onstack = STACK_PUSH;
         if( varAttrib==0 && !FUNCTION_C_BEHAVIOR(func) )
         {
            rSEVar val = seapiGetValue(call,param);
            SEVAR_COPY(onstack,val);
         }
         else
         {
            /* Pass by reference */
            SEVAR_COPY(onstack,&(param->value));
         }
      }
   }

   /* Normally, if we just call a function, the system will think we
    * are just another script function, and will treat errors like
    * we are in the context of our parent - it won't realize we are
    * an API function that gets to specifically determine whether or
    * not to trap errors and will instead try to determine the context
    * of the error and if it should be printed from the state of our
    * parent. That is wrong. Therefore, we turn off error printing
    * so the error will always be trapped, then when we get here,
    * we can go ahead and make sure the error gets printed. If we
    * did not do so, and our parents were trapping errors, then we
    * would also always trap errors. Since the API params determines whether
    * or not he wants to trap the error, that should be the determining
    * case, not the context of the parent.
    */
   call->mustPrintError = False;

   callFunctionFully(call,(uword16)((jsestack==NULL)?0:SECALLSTACK_DEPTH(jsestack)),
                     (flags&JSE_FUNC_CONSTRUCT)!=0);


   call->mustPrintError = old_must;

   retbool = !CALL_ERROR(call);
   ret = retbool?STACK0:&(call->error_var);

   if( retvar ) *retvar = NULL;

   if( retvar && (retbool || (flags&JSE_FUNC_TRAP_ERRORS)!=0) )
   {
      /* If the stack is non-null, we stuff it on there, so it
       * is to be destroyed (when the stack exits.) Alternately,
       * we have no stack to put it on, so make it a tempvar.
       */

      *retvar = SEAPI_RETURN(call,ret,jsestack!=NULL,UNISTR("jseCallFunctionEx"));

      if( jsestack )
      {
         secallstackPush(/*call,*/jsestack,*retvar,True);
      }
   }
   else
   {
      if( !retbool )
      {
         /* error deliberately trapped above, else we will get confused
          * by the stuff that has called on us, when we shouldn't -
          * if we are inside a try/catch block, that is irrelevent because
          * we are called by an API who gets to specify whether or not
          * trapping should occur.
          *
          * In this case, we must print the error.
          */
         call->mustPrintError = True;
         callPrintError(call);
         call->mustPrintError = old_must;
         CALL_SET_ERROR(call,FlowNoReasonToQuit);
      }
   }

   STACK_POP;
   CALL_SET_ERROR(call,FlowNoReasonToQuit);
   call->errorPrinted = False;
   return retbool;
}


#if (0!=JSE_CREATEFUNCTIONTEXTVARIABLE)
#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jseVariable )
jseReallyCreateFunctionTextVariable(jseContext call,jseVariable FuncVar,
                                    char *FILE,int LINE)
#else
   JSECALLSEQ( jseVariable )
jseCreateFunctionTextVariable(jseContext call,jseVariable FuncVar)
#endif
{
   const struct Function *func;
   rSEVar v;
   jseVariable ret;
   rSEObjectMem rMem;

   JSE_API_STRING(ThisFuncName,"jseCreateFunctionTextVariable");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );

   v =  jselibFindFunction(call,seapiGetValue(call,FuncVar),&func,NULL,&rMem);
#  if ( 0 < JSE_API_ASSERTLEVEL )
      if ( NULL == v )
      {
         SetLastApiError( UNISTR("%s: parameter 2 not a function"),ThisFuncName );
         return NULL;
      }
#  endif

   assert( NULL != v );
   assert( NULL != func );
    /* we only want the function so free up the variable */

   functionTextAsVariable(func,call,0);
   v = STACK0;
   ret = SEAPI_RETURN(call,v,TRUE,UNISTR("jseCreateFunctionTextVariable"));
   STACK_POP;
#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEOBJECTMEM_PTR(rMem) )
         SEOBJECTMEM_UNLOCK_R(rMem);
#  endif
   return ret;
}
#endif

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
JSECALLSEQ(jseVariable) jseReallyCreateWrapperFunction(jseContext call,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
                sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData,
                                                 char *FILE,int LINE)
#else
JSECALLSEQ(jseVariable) jseCreateWrapperFunction(jseContext call,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
                sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData)
#endif
{
   struct LibraryFunction *libfunc;
   wSEVar var;
   jseVariable ret;

   JSE_API_STRING(ThisFuncName,"jseCreateWrapperFunction");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_(functionName,2,ThisFuncName,return NULL);
   JSE_API_ASSERT_(funcPtr,3,ThisFuncName,return NULL);

   var = STACK_PUSH;
   SEVAR_INIT_BLANK_OBJECT(call,var);
   libfunc = libfuncNewWrapper(call,functionName,funcPtr,
                               minVariableCount,maxVariableCount,
                               varAttributes,funcAttributes,fData,
                               var);

   seobjSetFunction(call,SEVAR_GET_OBJECT(var),(struct Function *)libfunc);
   ret = SEAPI_RETURN(call,var,TRUE,UNISTR("jseCreateWrapperFunction"));
   STACK_POP;

   return ret;
}

   JSECALLSEQ( void )
jseTerminateExternalLink(jseContext call)
{
   JSE_API_ASSERT_C(call,1,jseContext_cookie,UNISTR("jseTerminateExternalLink"),
                  return);

   assert( call->next==NULL );
   callDelete(call);
}


   JSECALLSEQ( void )
jseDestroyStack(jseContext call,jseStack jsestack)
{
   uint i;

   JSE_API_STRING(ThisFuncName,"jseDestroyStack");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );
   JSE_API_ASSERT_C(jsestack,2,jseStack_cookie,ThisFuncName,return);

   i = jsestack->Count;
   while ( i-- )
   {
      if( jsestack->vars[i].free_on_del )
         jseDestroyVariable(call,jsestack->vars[i].var);
   }
#  if ( 2 <= JSE_API_ASSERTLEVEL )
      jsestack->cookie = 0;
#  endif
   jseMustFree(jsestack->vars);
   jseMustFree(jsestack);
}

#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ(jseVariable)
jseReallyPop(jseContext call, jseStack jsestack,char *FILE,int LINE)
#else
   JSECALLSEQ(jseVariable)
jsePop(jseContext call, jseStack jsestack)
#endif
{
   jseVariable ret;
   JSE_API_STRING(ThisFuncName,"jsePop");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return NULL);
   assert( call->next==NULL );
   JSE_API_ASSERT_C(jsestack,2,jseStack_cookie,ThisFuncName,return NULL);

   jsestack->Count--;
   ret = SEAPI_RETURN(call,&(jsestack->vars[jsestack->Count].var->value),TRUE,UNISTR("jsePop"));
   if( jsestack->vars[jsestack->Count].free_on_del )
      jseDestroyVariable(call,jsestack->vars[jsestack->Count].var);

   return ret;
}

   JSECALLSEQ(void)
jseSetGlobalObject(jseContext call,jseVariable newGlobal)
{
   rSEVar newVar;
   JSE_API_STRING(ThisFuncName,"jseSetGlobalObject");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   newVar = seapiGetValue(call,newGlobal);
   if( SEVAR_GET_TYPE(newVar)==VObject )
   {
      CALL_SET_GLOBAL(call,SEVAR_GET_OBJECT(newVar));
   }
}

#if (0!=JSE_ENABLE_DYNAMETH)
   JSECALLSEQ( jsebool )
jseEnableDynamicMethod(jseContext call,jseVariable obj,
                       const jsecharptr methodName,jsebool enable)
{
#if 0
   wSEVar var;
   VarName vName;
   jsebool was = False; /* if any parameters wrong assume false */
   uword8 offFlag;
   uword8 tmp;
   JSE_API_STRING(ThisFuncName,"jseEnableDynamicMethod");

   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );
   JSE_API_ASSERT_(methodName,3,ThisFuncName,return NULL);

   vName = GrabStringTableEntryStrlen(call,methodName,&tmp);

   var = seapiGetValue(call,obj);

   if( VObject == SEVAR_GET_TYPE(var) )
   {
      struct Global_ *global = call->Global;
      wSEObject obj;

      SEOBJECT_ASSIGN_LOCK_W(obj,SEVAR_GET_OBJECT(var));

      /* find the offFlag that applies to this name (0 if not found) */
      if( vName==STOCK_STRING(_delete) )
         offFlag = OFF_DELETE_PROP;
      else if( vName==STOCK_STRING(_put) )
         offFlag = OFF_PUT_PROP;
      else if( vName==STOCK_STRING(_canPut) )
         offFlag = OFF_CANPUT_PROP;
      else if( vName==STOCK_STRING(_get) )
         offFlag = OFF_GET_PROP;
      else if( vName==STOCK_STRING(_hasProperty) )
         offFlag = OFF_HAS_PROP;
#     if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
      else if( vName==STOCK_STRING(_operator) )
         offFlag = OFF_OPERATOR_PROP;
#     endif
      else
         offFlag = 0;
      if ( 0 != offFlag )
      {
         /* was it enabled (not disabled) */
         was = ( 0 == (SEOBJECT_PTR(obj)->flags & offFlag) );
         /* if enable then turn off offFlag, else turn the flag on */
         if ( enable )
         {
            SEOBJECT_PTR(obj)->flags &= ~offFlag;
         }
         else
         {
            SEOBJECT_PTR(obj)->flags |= offFlag;
         }
      }
      
      SEOBJECT_UNLOCK_W(obj);
   }

   ReleaseStringTableEntry(/*call,*/vName,tmp);

   return was;
#else
   return True;
#endif
}
#endif


/* ---------------------------------------------------------------------- */


#if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
   JSECALLSEQ( jsebool )
jseReallyCallStackInfo(jseContext call,struct jseStackInfo *info,uint depth,
                       char *FILE,int LINE)
#else
   JSECALLSEQ( jsebool )
jseCallStackInfo(jseContext call,struct jseStackInfo *info,uint depth)
#endif
{
   rSEVar func;
   struct Function *funcptr;
   wSEVar fptr;
   hSEObject hvarobj;
   uword16 num_args;
   struct TryBlock *tries;
   wSEVar tmp;
   rSEObject rfuncobj;
   rSEObject rCallScopeChain;
   rSEMembers rMembers;
   MemCountUInt scope_chain_loc;
#  if JSE_MEMEXT_SECODES==1
      ulong iptr_offset;
#  else
      secode iptr;
#  endif
   jsecharptr fname;
   JSE_API_STRING(ThisFuncName,"jseCallStackInfo");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return False);
   assert( call->next==NULL );

   func = FUNCVAR;
   fptr = FRAME;
   if( fptr==NULL ) return False;
   if( CALL_QUIT(call) ) return False;
   hvarobj = call->hVariableObject;
   num_args = call->num_args;
   SEOBJECT_ASSIGN_LOCK_R(rCallScopeChain,call->hScopeChain);
   scope_chain_loc = SEOBJECT_PTR(rCallScopeChain)->used-1;
#  if JSE_MEMEXT_SECODES==1
      iptr_offset = call->iptr - call->base;
#  else
      iptr = call->iptr;
#  endif

   memset(info,0,sizeof(struct jseStackInfo));

   SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rCallScopeChain)->hsemembers);
   while( scope_chain_loc>0
       && SEMEMBERS_PTR(rMembers)[scope_chain_loc].value.type!=VNull )
      scope_chain_loc--;

   while( depth-->0  )
   {
      const struct Function *f = sevarGetFunction(call,func);

      if( FUNCTION_IS_LOCAL(f) )
      {
         while( scope_chain_loc>0
             && SEMEMBERS_PTR(rMembers)[scope_chain_loc].value.type!=VNull )
            scope_chain_loc--;
      }

#     if JSE_MEMEXT_SECODES==1
         iptr_offset = SEVAR_GET_STORAGE_LONG(fptr-IPTR_OFFSET);
#     else
         iptr = SEVAR_GET_STORAGE_PTR(fptr-IPTR_OFFSET);
#     endif

      num_args = (uword16)SEVAR_GET_STORAGE_LONG(fptr-ARGS_OFFSET);
      assert( sizeof(hvarobj) <= sizeof(void *) );
      hvarobj = (hSEObject)SEVAR_GET_STORAGE_PTR(OLD_VAROBJ);
#     if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
         fptr = STACK_FROM_STACKPTR(SEVAR_GET_STORAGE_LONG(fptr));
         if( fptr==call->Global->growingStack )
#     else
         fptr = SEVAR_GET_STORAGE_PTR(fptr);
         if( fptr==NULL )
#     endif
         {
            SEOBJECT_UNLOCK_R(rCallScopeChain);
            return False;
         }

      /* restore func from stack */
      func = fptr - (num_args + FUNC_OFFSET);
   }

   SEMEMBERS_UNLOCK_R(rMembers);

   tmp = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(tmp);

   assert( SEVAR_GET_TYPE(func)==VObject );
   SEOBJECT_ASSIGN_LOCK_R(rfuncobj,SEVAR_GET_OBJECT(func));
   funcptr = SEOBJECT_PTR(rfuncobj)->func;
   SEOBJECT_UNLOCK_R(rfuncobj);
   assert( funcptr!=NULL );

   info->wrapper = !FUNCTION_IS_LOCAL(funcptr);
   info->function = SEAPI_RETURN(call,func,TRUE,UNISTR("jseCallStackInfo"));
   fname = functionName(funcptr,call);
   info->funcname = StrCpyMalloc(LFOM(fname));
   UFOM(fname);

   if( !call->mustPrintError )
   {
      info->trapped = True;
   }
   else
   {
      info->trapped = False;
      for( tries = call->tries; tries!=NULL; tries = tries->prev )
      {
         if( !tries->incatch && tries->catch!=(ADDR_TYPE)-1 &&
             STACK_FROM_STACKPTR(tries->fptr)<=fptr )
         {
            /* found a trap */
            info->trapped = True;
            break;
         }
      }
   }

#  if 0 != JSE_MULTIPLE_GLOBAL
      SEVAR_INIT_OBJECT(tmp,funcptr->hglobal_object?funcptr->hglobal_object:call->hGlobalObject);
#  else
      SEVAR_INIT_OBJECT(tmp,call->hGlobalObject);
#  endif
   info->global = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCallStackInfo"));

   info->filename = UNISTR("no filename");
   info->linenumber = 0;

   if( info->wrapper )
   {
      info->linkdata = (Func_StaticLibrary & funcptr->flags) ?
         *(((struct LibraryFunction *)funcptr)->LibData.DataPtr) :
         ((struct LibraryFunction *)funcptr)->LibData.Data;

      /* return the global also as the var obj */
      info->varObj = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCallStackInfo"));
      info->scopeChain = NULL;
   }
   else
   {
      /* first find the source location */
      wSEObjectMem wMem;
      hSEObject hssc;
      wSEObject wTmp;
      rSEMembers rMembers;
      secode sptr;
#     if JSE_MEMEXT_SECODES==1
         secode base = jsememextLockRead(((struct LocalFunction *)funcptr)->op_handle,
                                         jseMemExtSecodeType);
         secode iptr = base + iptr_offset;
#     else
         secode base = ((struct LocalFunction *)funcptr)->opcodes;

         assert( (iptr-((struct LocalFunction *)funcptr)->opcodes)>=0 );
         assert( (uint)(iptr-((struct LocalFunction *)funcptr)->opcodes)<
                 ((struct LocalFunction *)funcptr)->opcodesUsed );
#     endif

      for( sptr = base;sptr<=iptr;sptr++ )
      {
         if ( seFilename == *sptr )
         {
            info->filename = GetStringTableEntry(call,SECODE_GET_ONLY(sptr+1,VarName),NULL);
            break;
         }
         sptr += SECODE_DATUM_SIZE(*sptr);
      }
      /* search forward for next line number, it must be there */
      for( sptr = iptr;;sptr++ )
      {
         if ( seLineNumber == *sptr  ||  seContinueFunc == *sptr )
         {
            info->linenumber = SECODE_GET_ONLY(sptr+1,CONST_TYPE);
            break;
         }
         sptr += SECODE_DATUM_SIZE(*sptr);
      }

#     if JSE_MEMEXT_SECODES==1
         jsememextUnlockRead(((struct LocalFunction *)funcptr)->op_handle,base,jseMemExtSecodeType);
#     endif

      /* Get the activation object
       */
      SEVAR_INIT_OBJECT(tmp,hvarobj);
      info->varObj = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCallStackInfo"));

      /* get the scope chain and free it below. */
      SEVAR_INIT_OBJECT(tmp,seobjNew(call,False));
      info->scopeChain = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCallStackInfo"));

      SEOBJECT_ASSIGN_LOCK_W(wTmp,SEVAR_GET_OBJECT(tmp));
      SEMEMBERS_ASSIGN_LOCK_W(rMembers,SEOBJECT_PTR(rCallScopeChain)->hsemembers);
      if( SEMEMBERS_PTR(rMembers)[scope_chain_loc].value.type==VNull )
      {
         while( 1 )
         {
            scope_chain_loc++;
            if( scope_chain_loc>=SEOBJECT_PTR(rCallScopeChain)->used
             || SEMEMBERS_PTR(rMembers)[scope_chain_loc].value.type==VNull )
            {
               break;
            }

            /* add a new entry */
            seobjCreateMemberCopy(NULL,call,wTmp,NULL,
                                  &(SEMEMBERS_PTR(rMembers)[scope_chain_loc].value));
         }
      }
      SEMEMBERS_UNLOCK_R(rMembers);

      if( (hssc = func->data.object_val.hSavedScopeChain)!=hSEObjectNull )
      {
         uint lookin;
         rSEObject rssc;

         SEOBJECT_ASSIGN_LOCK_R(rssc,hssc);
	 if (SEOBJECT_PTR(rssc)->used != 0)
	 {
	    SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rssc)->hsemembers);
	    for( lookin=0;lookin<SEOBJECT_PTR(rssc)->used;lookin++ )
	    {
	       seobjCreateMemberCopy(NULL,call,wTmp,NULL,
				     &(SEMEMBERS_PTR(rMembers)[lookin].value));
	    }
	    SEMEMBERS_UNLOCK_R(rMembers);
	 }
	 SEOBJECT_UNLOCK_R(rssc);
      }

      wMem = SEOBJ_CREATE_MEMBER(call,wTmp,NULL);
#     if 0 != JSE_MULTIPLE_GLOBAL
         SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wMem),funcptr->hglobal_object?funcptr->hglobal_object:call->hGlobalObject);
#     else
         SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(wMem),call->hGlobalObject);
#     endif
      SEOBJECTMEM_UNLOCK_W(wMem);
      SEOBJECT_UNLOCK_W(wTmp);
   }

   STACK_POP;

   tmp = (fptr-(THIS_OFFSET+num_args));
   info->thisvar = SEAPI_RETURN(call,tmp,TRUE,UNISTR("jseCallStackInfo"));

   assert( info->filename!=NULL );
   info->filename = StrCpyMalloc(info->filename);

   SEOBJECT_UNLOCK_R(rCallScopeChain);

   return True;
}


   JSECALLSEQ( void )
jseFreeStackInfo(jseContext call,struct jseStackInfo *info)
{
   JSE_API_STRING(ThisFuncName,"jseFreeStackInfo");
   JSE_API_ASSERT_C(call,1,jseContext_cookie,ThisFuncName,return);
   assert( call->next==NULL );

   jseDestroyVariable(call,info->function);
   jseDestroyVariable(call,info->global);
   jseDestroyVariable(call,info->thisvar);
   jseDestroyVariable(call,info->varObj);
   if( info->scopeChain!=NULL ) jseDestroyVariable(call,info->scopeChain);

   jseMustFree((void *)info->filename);
   jseMustFree((void *)info->funcname);
}


/* ---------------------------------------------------------------------- */

/* Get an internal representation of the original string, suitable
 * for passing to API functions that require a member name. You
 * must free that using 'jseFreeString' when finished with it
 */
   JSECALLSEQ(jseString)
jseInternalizeString(jseContext call,const jsecharptr str,
                     JSE_POINTER_UINDEX len)
{
   uword8 tmp;
   VarName result = GrabStringTableEntry(call,str,(stringLengthType)len,&tmp);
   jseString ret = callApiStringEntry(call,result);
   ReleaseStringTableEntry(/*call,*/result,tmp);
   return ret;
}


   JSECALLSEQ(const jsecharptr)
jseGetInternalString(jseContext call,jseString str,
                     JSE_POINTER_UINDEX *len)
{
   struct api_string *it = (struct api_string *)str;
   const jsecharptr ret;

   /* In case the user messed up, make the check */
   if( it>=call->Global->api_strings &&
       it<(call->Global->api_strings + call->Global->api_strings_used) )
   {
      stringLengthType alen;

      /* Note, JSE_POINTER_UINDEX and stringLengthType can be different
       * so cannot merge the call
       */
      ret = GetStringTableEntry(call,it->name,&alen);
      if( len ) *len = alen;
   }
   else
   {
      assert( False );
      ret = NULL;
   }
   return ret;
}


   JSECALLSEQ(void)
jseFreeInternalString(jseContext call,jseString str)
{
   struct api_string *it = (struct api_string *)str;


   /* In case the user messed up, make the check */
   if( it>=call->Global->api_strings &&
       it<(call->Global->api_strings + call->Global->api_strings_used) )
   {

      callRemoveApiStringEntry(call,it);

   }
   else
   {
      assert( False );
   }
}
