/* security.c - Handle the security file.
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

#include "srccore.h"

#if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)

   jsebool NEAR_CALL
checkSecurity(struct Call *call,rSEVar calling_var,uword16 num_args)
{
   rSEObject rCallingObj;
   struct Function *calling;
   struct Security *new;
   struct Security *current;
   jsebool ret;

   SEOBJECT_ASSIGN_LOCK_R(rCallingObj,SEVAR_GET_OBJECT(calling_var));
   calling = SEOBJECT_PTR(rCallingObj)->func;
   new = calling->functionSecurity;
   current = call->currentSecurity;
   ret = True;

   /* We should always have the security equal to the function
    * executing. We determine if it is ok to execute that function
    * precisely because it has different security than the caller.
    * If no function is executing, we have the call's security,
    * i.e. the 'starting' security.
    */
   if( call->funcptr ) current = call->funcptr->functionSecurity;


   /* if we have infinite security, we are allowed to call anything */
   if( current==NULL || current==new )
      goto endCheckSecurity;

   /* can call secure functions */
   if( !FUNCTION_IS_LOCAL(calling) &&
       (((struct LibraryFunction *)calling)->FuncDesc->FuncAttributes&jseFunc_Secure) )
      goto endCheckSecurity;


#  if (0!=JSE_COMPILER)
      /* if within conditional compilation then don't allow insecure
         function */
      if ( call->Global->CompileStatus.NowCompiling )
      {
         callQuit(call,textcoreNO_SECURITY_WHILE_COMPILING);
         ret = False;
         goto endCheckSecurity;
      }
#  endif

   /* Call all functions that are in the current security but not in the
    * new - i.e. upgrade security. If any fail, security has rejected
    * this call. If new is NULL (for wrapper functions for instance),
    * must call all.
    */
   while( current )
   {
      struct Security *loop;
      jsebool found = False;
      wSEVar v;
      rSEVar tmp;
      uint parmidx;


      for( loop = new;loop!=NULL;loop = loop->next )
         if( loop==current )
         {
            found = True;
            break;
         }


      if( !found )
      {
         MemCountUInt i;

         /* If we are initializing security, don't apply that security
          * yet (i.e. the security initialization function.
          */
         if( current->changable )
            goto endCheckSecurity;

         if( calling==NULL )
         {
#if defined(__JSE_PALMOS)
            jsechar buffer[32];
#else
            jsechar buffer[128];
#endif

            FindNames(call,calling_var,(jsecharptr)buffer,sizeof(buffer),
                           LockedStringTableEntry(call,UNISTR("unknown"),7));
            callQuit(call,textcoreNO_APPROVAL_FROM_SECURITY_GUARD,buffer);
            assert( CALL_ERROR(call) );
            ret = False;
            goto endCheckSecurity;
         }

         /* Need to upgrade security. First check this function variable
          * against the list of functions to determine if we should automatically
          * accept it, guard it, or by default reject it.
          */

         for( i=0;i<current->acceptUsed;i++ )
         {
            /* well, if we are just accepting it, viola! */
            if( calling==current->acceptFuncs[i] )
               goto endCheckSecurity;
         }


         for( i=0;i<current->guardUsed;i++ )
         {
            if( calling==current->guardFuncs[i] ) break;
         }
         if( i==current->guardUsed )
         {
	    jsecharptr fname = functionName(calling,call);
            callQuit(call,textcoreNO_APPROVAL_FROM_SECURITY_GUARD,
                     LFOM(fname));
	    UFOM(fname);
            ret = False;
            goto endCheckSecurity;
         }

         /* Else, we have a function that needs to go through the security guard */


         /* push a this */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,CALL_GLOBAL(call));
         /* push function to call */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,current->hjseSecurityGuard);
         /* push private variable */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,current->hPrivateVariable);
         /* push function being called */
         v = STACK_PUSH;
         SEVAR_COPY(v,calling_var);
         /* Copy all the parameters to the stack, then call the function.
          */
         for( parmidx=0;parmidx<num_args;parmidx++ )
         {
            /* on the top of the stack are the arguments and the one
             * variable (the function) we pushed on.
             */
            tmp = STACKX(3+num_args-parmidx);
            v = STACK_PUSH;
            SEVAR_COPY(v,tmp);
         }


         /* Make the current function's security infinite; we
          * are calling the security guard function and that
          * ought not be vetoed. Set it back when we finish.
          */

         if( call->funcptr )
         {
            call->funcptr->functionSecurity = NULL;
         }
         else
         {
            call->currentSecurity = NULL;
         }

         callFunctionFully(call,(uword16)(num_args+2),False);

         if( call->funcptr )
         {
            call->funcptr->functionSecurity = current;
         }
         else
         {
            call->currentSecurity = current;
         }

         /* determine if the security guard said OK */
         if( CALL_QUIT(call) )
         {
            /* if an error occured in the security handler, then we treat
             * that as failed approval.
             */
#           if defined(JSE_GROWABLE_STACK) && (0!=JSE_GROWABLE_STACK)
               STACK_PUSH_ONLY;
#           else
               STACK_PUSH;
#           endif
            ret = False;
            goto endCheckSecurity;
         }
         else
         {
            wSEVar result = STACK0;
            if( !sevarConvertToBoolean(call,result) )
            {
               jsechar buffer[128];

               FindNames(call,calling_var,(jsecharptr)buffer,128,
                         LockedStringTableEntry(call,UNISTR("unknown"),7));
               callQuit(call,textcoreNO_APPROVAL_FROM_SECURITY_GUARD,buffer);
               assert( CALL_ERROR(call) );
               STACK_POP;
               ret = False;
               goto endCheckSecurity;
            }
            STACK_POP;
         }
      }

      current = current->next;
   }

endCheckSecurity:
   SEOBJECT_UNLOCK_R(rCallingObj);
   return ret;
}


static jseLibFunc(Function_setSecurity)
{
   struct Call *call;
   struct Security *current;
   struct Function *func;
   wSEVar param;
   int value;
   MemCountUInt i;
   rSEObject robj;

   call = jsecontext;
   current = call->Global->allSecurity;
   SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(CALL_THIS));
   func = SEOBJECT_PTR(robj)->func;
   SEOBJECT_UNLOCK_R(robj);

   if( func==NULL )
   {
      callError(call,textcoreNOT_FUNCTION_VARIABLE,UNISTR("passed to setSecurity ") );
      return;
   }

   /* It is possible this security block will not be associated with us,
    * but with a previous context. In this case, it is no problem as it
    * will still have the security no longer changable, so we still fail.
    */
   if( !current->changable )
   {
      callError(call,textcoreSECURITY_SET);
      return;
   }

   param = CALL_PARAM(0);
   if( param==NULL ) return; /* error already reported */

   value = (int)JSE_FP_CAST_TO_SLONG(sevarConvertToNumber(call,param));

   /* First remove it from the existing list if it is there */

   for( i=0;i<current->acceptUsed;i++ )
      if( current->acceptFuncs[i]==func )
      {
         if( i<current->acceptUsed-1 )
            memmove(current->acceptFuncs+i,current->acceptFuncs+(i+1),
                    (size_t)((current->acceptUsed-i-1)*sizeof(struct Function *)));
         current->acceptUsed--;
      }
   for( i=0;i<current->guardUsed;i++ )
      if( current->guardFuncs[i]==func )
      {
         if( i<current->guardUsed-1 )
            memmove(current->guardFuncs+i,current->guardFuncs+(i+1),
                    (size_t)((current->guardUsed-i-1)*sizeof(struct Function *)));
         current->guardUsed--;
      }

   switch( value )
   {
      case jseSecureAllow:
         if( current->acceptUsed>=current->acceptAlloced )
         {
            struct Function **newf;

            current->acceptAlloced += 50;
            newf = jseReMalloc(struct Function *,current->acceptFuncs,
                               (uint)(current->acceptAlloced*
                                      sizeof(struct Function *)));
            if( newf==NULL )
            {
               callQuit(call,textcoreOUT_OF_MEMORY);
               current->acceptAlloced -= 50;
               return;
            }
            current->acceptFuncs = newf;
         }
         current->acceptFuncs[current->acceptUsed++] = func;
         break;
      case jseSecureGuard:
      {
         struct Function **newf;

         if( current->guardUsed>=current->guardAlloced )
         {
            current->guardAlloced += 50;
             newf= jseReMalloc(struct Function *,current->guardFuncs,
                               (uint)(current->guardAlloced*
                                      sizeof(struct Function *)));
            if( newf==NULL )
            {
               callQuit(call,textcoreOUT_OF_MEMORY);
               current->guardAlloced -= 50;
               return;
            }
            current->guardFuncs = newf;
         }
         current->guardFuncs[current->guardUsed++] = func;
         break;
      }
      case jseSecureReject:
         /* nothing to do */
         break;
      default:
         callError(call,textcoreSECURITY_BAD);
         break;
   }

   /* this function doesn't return anything */
}

#ifdef __JSE_GEOS__
/* strings in code segment, include literals */
#pragma option -dc
#endif

static CONST_DATA(struct jseFunctionDescription) FunctionProtoList[] =
{
   JSE_LIBMETHOD( UNISTR("setSecurity"), Function_setSecurity, 1, 1,
                  jseDontEnum,  jseFunc_Secure ),
   JSE_FUNC_DESC_END
};

#define SECURE_GUARD_VALUE    UNISTR("2")
#define SECURE_ALLOW_VALUE    UNISTR("1")
#define SECURE_REJECT_VALUE   UNISTR("0")

static CONST_DATA(struct jseFunctionDescription) SecurityConstantsList[] =
{
   JSE_VARSTRING( UNISTR("jseSecureGuard"),  SECURE_GUARD_VALUE,  jseDontEnum ),
   JSE_VARSTRING( UNISTR("jseSecureAllow"),  SECURE_ALLOW_VALUE,  jseDontEnum ),
   JSE_VARSTRING( UNISTR("jseSecureReject"), SECURE_REJECT_VALUE, jseDontEnum ),
   JSE_FUNC_DESC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif


/* Add the external link parameters security function to our chain,
 * update the security in session, all only if not already part
 * of the chain. This function will only fail due to lack of
 * memory.
 */
jsebool NEAR_CALL setSecurity(struct Call *call)
{
   struct Security *loop;
   rSEVar guardvar = seapiGetValue(call,call->Global->ExternalLinkParms.jseSecurityGuard);
   rSEVar initvar = seapiGetValue(call,call->Global->ExternalLinkParms.jseSecurityInit);
   rSEVar termvar = seapiGetValue(call,call->Global->ExternalLinkParms.jseSecurityTerm);
   rSEVar securityVar = seapiGetValue(call,call->Global->ExternalLinkParms.securityVariable);
   wSEVar v;


   if( initvar==NULL )
   {
      /* there must be a security initialization function or there is
       * no security. Of course, if there is no security, that is
       * a 'successful' initialization.
       */
      return True;
   }

   /* add it */

   loop = jseMalloc(struct Security,sizeof(struct Security));
   if( loop==NULL )
   {
      callQuit(call,textcoreOUT_OF_MEMORY);
      return False;
   }

   assert( loop!=NULL );

   loop->acceptFuncs = jseMalloc(struct Function *,sizeof(struct Function *)*50);
   loop->guardFuncs = jseMalloc(struct Function *,sizeof(struct Function *)*50);

   if( loop->acceptFuncs==NULL || loop->guardFuncs==NULL )
   {
      jseMustFree(loop);
      if( loop->acceptFuncs!=NULL ) jseMustFree(loop->acceptFuncs);
      if( loop->guardFuncs!=NULL ) jseMustFree(loop->guardFuncs);
      return False;
   }


   loop->prev = call->Global->allSecurity;
   call->Global->allSecurity = loop;
   loop->next = call->currentSecurity;
   call->currentSecurity = loop;

   loop->acceptAlloced = 50;
   loop->guardAlloced = 50;
   loop->acceptUsed = 0;
   loop->guardUsed = 0;

   loop->hjseSecurityGuard = guardvar?((SEVAR_GET_TYPE(guardvar)==VObject)?
                                      SEVAR_GET_OBJECT(guardvar):hSEObjectNull):hSEObjectNull;
   loop->hjseSecurityInit = initvar?((SEVAR_GET_TYPE(initvar)==VObject)?
                                    SEVAR_GET_OBJECT(initvar):hSEObjectNull):hSEObjectNull;
   loop->hjseSecurityTerm = termvar?((SEVAR_GET_TYPE(termvar)==VObject)?
                                    SEVAR_GET_OBJECT(termvar):hSEObjectNull):hSEObjectNull;
   loop->hPrivateVariable = securityVar?((SEVAR_GET_TYPE(securityVar)==VObject)?
                                        SEVAR_GET_OBJECT(securityVar):hSEObjectNull):hSEObjectNull;


   if( loop->hPrivateVariable==hSEObjectNull )
   {
      loop->hPrivateVariable = seobjNew(call,True);
   }

   loop->changable = True;

   /* call the initialization function */

   if( loop->hjseSecurityInit )
   {
      /* push this */
      v = STACK_PUSH;
      SEVAR_INIT_OBJECT(v,CALL_GLOBAL(call));
      /* push function to call */
      v = STACK_PUSH;
      SEVAR_INIT_OBJECT(v,loop->hjseSecurityInit);
      /* push private variable */
      v = STACK_PUSH;
      SEVAR_INIT_OBJECT(v,loop->hPrivateVariable);

      callFunctionFully(call,1,False);
   }
   /* else we call nothing - this means if your security init is
    * not really a function, security will end up rejecting all
    * insecure functions
    */

   /* no more changes allowed */

   loop->changable = False;

   /* if the security initialization function failed with an
    * error, then we fail.
    */
   return !CALL_QUIT(call);
}


void NEAR_CALL setupSecurity(struct Call *call)
{
   /* make sure Function.prototype.setSecurity() exists and points to
    * our wrapper function. We reinitialize it in some cases, but this
    * is necessary because most of the time, jseNewSecurity happens
    * due to a jseAllNew.
    */
   jseAddLibrary(call,UNISTR("Function.prototype"),FunctionProtoList,NULL,NULL,NULL);
#  ifndef NDEBUG
      assert( jseSecureReject == atoi_jsechar(SECURE_REJECT_VALUE) );
      assert( jseSecureAllow == atoi_jsechar(SECURE_ALLOW_VALUE) );
      assert( jseSecureGuard == atoi_jsechar(SECURE_GUARD_VALUE) );
#  endif
   jseAddLibrary(call,NULL,SecurityConstantsList,NULL,NULL,NULL);
}


void NEAR_CALL cleanupSecurity(struct Call *call)
{
   struct Global_ *global = call->Global;

   while( global->allSecurity )
   {
      struct Security *p = global->allSecurity->prev;

      if( global->allSecurity->hjseSecurityTerm )
      {
         wSEVar v;
         /* push this */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,CALL_GLOBAL(call));
         /* push function to call */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,global->allSecurity->hjseSecurityTerm);
         /* push private variable */
         v = STACK_PUSH;
         SEVAR_INIT_OBJECT(v,global->allSecurity->hPrivateVariable);

         callFunctionFully(call,1,False);
      }
      jseMustFree(global->allSecurity->acceptFuncs);
      jseMustFree(global->allSecurity->guardFuncs);
      jseMustFree(global->allSecurity);
      global->allSecurity = p;
   }
}

#endif
