/* library.c
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

#if JSE_COMPACT_LIBFUNCS==1
static void NEAR_CALL libfuncNewCompact(struct Call *call,hSEObject hObjectToAddTo,
                  struct jseFunctionDescription const *FuncDesc,
                  void _FAR_ * * LibraryDataPtr);
#endif

   static void NEAR_CALL
libDerefer(struct Call *call,wSEVar tmp)
{
   /* A relatively big macro, let's not repeat it too many times */
   SEVAR_DEREFERENCE(call,tmp);
}


   jsebool
libraryAddFunctions(struct Library *this,struct Call *call,
                    const jsecharptr ObjectVarName,
                    struct jseFunctionDescription const * FunctionList,
                    jseLibraryInitFunction pLibInit,
                    jseLibraryTermFunction pLibTerm,
                    void _FAR_ *ParentLibData)
{
   struct Library *ll = (struct Library *)jseMallocWithGC(call,sizeof(struct Library));
   /* determine which object to add this set of functions to */
   wSEVar BeginObjectToAddTo = STACK_PUSH;
   wSEVar ObjectToAddTo = STACK_PUSH;
   wSEVar tmp = STACK_PUSH;
   wSEVar tmp2 = STACK_PUSH;

   if( ll==NULL )
   {
      STACK_POPX(4);
      return False;
   }

   SEVAR_INIT_OBJECT(BeginObjectToAddTo,CALL_GLOBAL(call));
   SEVAR_INIT_UNDEFINED(ObjectToAddTo);
   SEVAR_INIT_UNDEFINED(tmp);
   SEVAR_INIT_UNDEFINED(tmp2);

   ll->ObjectVarName = ObjectVarName;
   ll->FunctionList = FunctionList;

   if ( NULL != ObjectVarName )
   {
      /* find object by name in global variable */
      GetDotNamedVar(call,BeginObjectToAddTo,ObjectVarName,True);
   }
   /* ensure that variable is an object;
    * this variable will be set to initialize, and then if FuncObject
    */
   SEVAR_COPY(ObjectToAddTo,BeginObjectToAddTo);

   /* add each function within this library to our function list */
   for ( ; NULL != FunctionList->FunctionName; FunctionList++ )
   {
      rSEVar SetAttrOnVar = NULL;

      switch ( FunctionList->FuncAttributes & 0x0F )
      {
         case jseFunc_FuncObject:
            SEVAR_COPY(tmp,BeginObjectToAddTo);
            libDerefer(call,tmp);

#           if JSE_COMPACT_LIBFUNCS==1
            libfuncNewCompact(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           else
            libfuncNew(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           endif
            /* ObjectToAddTo should now be switched to the object we
             * just added */
            SEVAR_COPY(ObjectToAddTo,BeginObjectToAddTo);
            GetDotNamedVar(call,ObjectToAddTo,LFOM(FunctionList->FunctionName),True);
	    UFOM(FunctionList->FunctionName);
            break;
         case jseFunc_ObjectMethod:
            SEVAR_COPY(tmp,ObjectToAddTo);
            libDerefer(call,tmp);
#           if JSE_COMPACT_LIBFUNCS==1
            libfuncNewCompact(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           else
            libfuncNew(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           endif
            break;
         case jseFunc_PrototypeMethod:
            SEVAR_COPY(tmp,ObjectToAddTo);
            GetDotNamedVar(call,tmp,ORIG_PROTOTYPE_PROPERTY,True);
            libDerefer(call,tmp);
#           if JSE_COMPACT_LIBFUNCS==1
            libfuncNewCompact(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           else
            libfuncNew(call,SEVAR_GET_OBJECT(tmp),FunctionList,&(ll->LibraryData));
#           endif
            break;
         case jseFunc_AssignToVariable:
            SetAttrOnVar = tmp;
            SEVAR_COPY(tmp,ObjectToAddTo);
            GetDotNamedVar(call,tmp,LFOM(FunctionList->FunctionName),False);
	    UFOM(FunctionList->FunctionName);
            SEVAR_INIT_OBJECT(tmp2,CALL_GLOBAL(call));
            GetDotNamedVar(call,tmp2,
                           (const jsecharptr )(JSE_POINTER_UINT)(LFOM(FunctionList->FuncPtr)),
                           False);
	    UFOM(FunctionList->FuncPtr);
            libDerefer(call,tmp2);

            /* make sure it is not read only anymore */
            assert( SEVAR_GET_TYPE(tmp)==VReference );
            seobjSetAttributes(call,tmp->data.ref_val.hBase,
                               tmp->data.ref_val.reference,0);

            SEVAR_DO_PUT(call,tmp,tmp2);
            break;
         case jseFunc_LiteralValue:
         {
            jsecharptr val;

            SetAttrOnVar = tmp;
            SEVAR_COPY(tmp,ObjectToAddTo);
            GetDotNamedVar(call,tmp,LFOM(FunctionList->FunctionName),False);
	    UFOM(FunctionList->FunctionName);
            val = (jsecharptr )(LFOM(FunctionList->FuncPtr));

            /* a literal is either going to be a number representation (e.g."3.14159",
             * "Infinity", "-Infinity", "NaN", "0x40Fe"), or a string (e.g. "\"My Company\"") or
             * the special cases of "true", "false", or "null".
             */
            if ( UNICHR('\"') == JSECHARPTR_GETC(val) )
            {
               /* literal string, up to ending quote */
               assert( JSECHARPTR_GETC(JSECHARPTR_OFFSET(val,strlen_jsechar(val)-1))=='\"' );
               SEVAR_INIT_STRING_STRLEN(call,tmp2,JSECHARPTR_NEXT(val),strlen_jsechar(val)-2);
            }
            else if ( 0 == strcmp_jsechar(val,textcorevtype_null) )
            {
               SEVAR_INIT_NULL(tmp2);
            }
            else if ( 0 == strcmp_jsechar(val,textcorevtype_bool_true) )
            {
               SEVAR_INIT_BOOLEAN(tmp2,True);
            }
            else if ( 0 == strcmp_jsechar(val,textcorevtype_bool_false) )
            {
               SEVAR_INIT_BOOLEAN(tmp2,False);
            }
            else
            {
               /* all other cases assumed to be a number; if the user
                * did not correctly represent a number then that is a serious
                * bug that they're have to discover in their own code, and they'll
                * probably end up with a NaN
                */
               SEVAR_INIT_NUMBER(tmp2,convertStringToNumber(call,val,strlen_jsechar(val)));
            }
	    UFOM(FunctionList->FuncPtr);

            /* make sure it is not read only anymore */
            assert( SEVAR_GET_TYPE(tmp)==VReference );
            seobjSetAttributes(call,tmp->data.ref_val.hBase,
                               tmp->data.ref_val.reference,0);

            SEVAR_DO_PUT(call,tmp,tmp2);
            break;
         }
         case jseFunc_LiteralNumberPtr:
         {
            SetAttrOnVar = tmp;
            SEVAR_COPY(tmp,ObjectToAddTo);
            GetDotNamedVar(call,tmp,LFOM(FunctionList->FunctionName),False);
	    UFOM(FunctionList->FunctionName);
            SEVAR_INIT_NUMBER(tmp2,
               *((jsenumber *)(JSE_POINTER_UINT)(LFOM(FunctionList->FuncPtr))));
	    UFOM(FunctionList->FuncPtr);
            SEVAR_DO_PUT(call,tmp,tmp2);
            break;
         }
         case jseFunc_SetAttributes:
         {
            SetAttrOnVar = tmp;
            SEVAR_COPY(tmp,ObjectToAddTo);
            GetDotNamedVar(call,tmp,LFOM(FunctionList->FunctionName),False);
	    UFOM(FunctionList->FunctionName);
            break;
         }
#        ifndef NDEBUG
         default:
            InstantDeath(textcoreUNKNOWN_FUNCATTRIBUTE,
                         FunctionList->FuncAttributes & 0x0F);
#        endif
      }
      if ( NULL != SetAttrOnVar )
      {
         assert( SEVAR_GET_TYPE(SetAttrOnVar)==VReference );
         seobjSetAttributes(call,SetAttrOnVar->data.ref_val.hBase,
                            SetAttrOnVar->data.ref_val.reference,
                            FunctionList->VarAttributes);
      }
   }

   /* add this library into the linked library list and
    * call its initialization function */
   ll->prev = this->prev;
#   ifndef NDEBUG
      ll->RememberAddCall = call;
#   endif
   ll->LibInit = pLibInit;
   ll->LibTerm = pLibTerm;
   ll->LibraryData =
                 ( pLibInit ) ?
#               if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__) ) \
                && (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
                   (void _FAR_ *)DispatchToClient(call->Global->
                                                     ExternalDataSegment,
                                                  (ClientFunction)pLibInit,
                                                  (void *)call,ParentLibData)
#               else
                  (*pLibInit)(call,ParentLibData)
#               endif
               : ParentLibData ;
#  if !defined(NDEBUG) && (0<JSE_API_ASSERTLEVEL) && defined(_DBGPRNTF_H)
      if ( !jseApiOK )
      {
         DebugPrintf(UNISTR("Error calling library init function"));
         DebugPrintf(UNISTR("Error message: %s"),jseGetLastApiError());
      }
#  endif
   assert( jseApiOK );
   this->prev = ll;

   STACK_POPX(4);

   return True;
}


#if JSE_COMPACT_LIBFUNCS==1
   static void NEAR_CALL
libfuncNewCompact(struct Call *call,hSEObject hObjectToAddTo,
                  struct jseFunctionDescription const *FuncDesc,
                  void _FAR_ * * LibraryDataPtr)
{
   uword8 attribs = (uword8)FuncDesc->VarAttributes;
   wSEVar dest = STACK_PUSH;
   wSEVar attribvar = STACK_PUSH;
   wSEVar tmp = STACK_PUSH;

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   if( (FuncDesc->FuncAttributes & jseFunc_Secure)==0 )
   {
      /* if it is insecure, we must make it ReadOnly and DontDelete or
       * we have a potential security hole
       */
      attribs |= (jseDontDelete|jseReadOnly);
   }
#  endif

   SEVAR_INIT_OBJECT(dest,hObjectToAddTo);
   GetDotNamedVar(call,dest,LFOM(FuncDesc->FunctionName),False);
   UFOM(FuncDesc->FunctionName);
   SEVAR_COPY(attribvar,dest);

   /* If the item is already an object, then just use the normal
    * object routines. This prevents us from losing members of
    * an already-existing object we are redefining. It is necessary
    * for default prototypes, also because those prototypes are
    * stored with that particular object and so we need to keep
    * using that object.
    *
    * If that is the case, use the regular library initialization
    * code that doesn't try to shrink it.
    */
   SEVAR_COPY(tmp,dest);
   SEVAR_DEREFERENCE(call,tmp);
   if( SEVAR_GET_TYPE(tmp)==VObject )
   {
      libfuncNew(call,hObjectToAddTo,FuncDesc,LibraryDataPtr);
   }
   else
   {
      SEVAR_INIT_LIBFUNC(tmp,FuncDesc,LibraryDataPtr);

      SEVAR_DO_PUT(call,dest,tmp);
   }

   if( attribvar->type==VReference )
   {
      seobjSetAttributes(call,attribvar->data.ref_val.hBase,
                         attribvar->data.ref_val.reference,
                         attribs);
   }

   STACK_POPX(3);
}
#endif
