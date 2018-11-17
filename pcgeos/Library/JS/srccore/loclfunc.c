/* loclfunc.c   Parameters and code cards within a local function.
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


   struct LocalFunction *
localNew(struct Call *call,VarName iFunctionName,
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
           jsebool CBehavior,
#  endif
         rSEVar add_to
         )
{
   struct LocalFunction *this =
      jseMalloc(struct LocalFunction,sizeof(struct LocalFunction));

   if( this==NULL ) return NULL;

   memset(this,0,sizeof(*this));

   this->FunctionName = iFunctionName;

   this->hConstants = seobjNew(call,False);

   assert( add_to!=NULL );

   functionInit(&(this->function),call,add_to,
                (uword8)(iFunctionName==STOCK_STRING(Global_Initialization) ?
                         jseDontEnum :
                         jseDefaultAttr),
                True,
#               if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
                   CBehavior,
#               else
                   False,
#               endif
#               if 0 != JSE_MULTIPLE_GLOBAL
                   True,/* iSwapGlobal */
#               endif
                0);


#  if (0!=JSE_COMPILER)
      /* Add the tokens for the filename and line number */
      this->tok.tokens = jseMalloc(struct tok,sizeof(struct tok)*(this->tok.alloced = 10));
      assert( 0 == this->tok.used );
      if( this->tok.tokens==NULL )
      {
         jseMustFree(this);
         /* I've put 'return NULL;' instead of this = NULL, because the
          * fallthru into 'return this;' may get broken and the person
          * might not realize it was there, even with a comment. Since
          * this failure is a rare situation, that would lead to
          * a highly unpredictable bug.
          */
         return NULL;
      }
#  endif

   return this;
}

#if (0!=JSE_COMPILER)
   void NEAR_CALL
localMinimizeTokens(struct LocalFunction *lf,jsebool FreeAll)
{
   if ( NULL != lf->tok.tokens )
   {
#     if JSE_CREATEFUNCTIONTEXTVARIABLE!=0
         /* get rid of any extra space we aren't using. */
         if( !FreeAll && lf->tok.used )
         {
            lf->tok.tokens = jseMustReMalloc(struct tok,lf->tok.tokens,
               sizeof(struct tok)*(lf->tok.alloced=lf->tok.used));
         }
         else
#     else
         UNUSED_PARAMETER(FreeAll);
#     endif
         {
            jseMustFree(lf->tok.tokens);
            memset(&lf->tok,0,sizeof(lf->tok));
            assert( 0 == lf->tok.alloced );
            assert( 0 == lf->tok.used );
            assert( NULL == lf->tok.tokens );
         }
   }
}

   struct tok *
secompileNextToken(struct secompile *compile)
{
   struct tok *ret;
   struct LocalFunction *lf = compile->locfunc;

   if( lf->tok.used >= lf->tok.alloced )
   {
      assert( lf->tok.used==lf->tok.alloced );
      lf->tok.alloced += 50;
      assert( lf->tok.tokens!=NULL );
      lf->tok.tokens = jseMustReMalloc(struct tok,lf->tok.tokens,
                                   sizeof(struct tok)*lf->tok.alloced);
   }

   ret = lf->tok.tokens + lf->tok.used++;
   tokGetNext(ret,compile);
   return ret;
}
#endif /* #if (0!=JSE_COMPILER) */

   void
localDelete(struct Call *call,struct LocalFunction *this)
{
   /* Parse failure can make this NULL */
#  if JSE_MEMEXT_SECODES==1
      if( this->op_handle ) jsememextFree(this->op_handle,jseMemExtSecodeType);
#  else
      if( this->opcodes!=NULL ) SECODE_DELETE_OPCODES((void *)(this->opcodes));
#  endif

#  if (0!=JSE_COMPILER)
      localMinimizeTokens(this,True);
#  endif

   assert( (this->alloced==0 && this->items==NULL) ||
           (this->alloced!=0 && this->items!=NULL) );
   if( NULL != this->items )
      jseMustFree(this->items);
}


   sint
localAddVarName(struct LocalFunction *this,struct Call * call,VarName name)
{
   UNUSED_PARAMETER(call);

   if( this->InputParameterCount>=this->alloced )
   {
#     if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
      this->alloced++;
#     else
      this->alloced+=5;
#     endif
      this->items = jseMustReMalloc(struct localItem,this->items,
                                    (this->alloced) * sizeof(struct localItem));
   }

   this->items[this->InputParameterCount].VarName = name;
   this->items[this->InputParameterCount].VarAttrib = 0;
   this->items[this->InputParameterCount].VarFunc = -1;

   return (sint) this->InputParameterCount++;
}

#if (0!=JSE_COMPILER)
   MemCountUInt
secompileCreateConstant(struct secompile *compile,rSEVar constant)
{
   wSEObjectMem wMem;
#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEMEMBERS_PTR(compile->constMembers) )
         SEMEMBERS_UNLOCK_W(compile->constMembers);
#  endif
   seobjCreateMemberCopy(&wMem,compile->call,compile->constObj,NULL,constant);
#  if 0!=JSE_MEMEXT_MEMBERS
      compile->constMembers = wMem.semembers;
#  else
      compile->constMembers = SEOBJECT_PTR(compile->constObj)->hsemembers;
#  endif
   return SEOBJECT_PTR(compile->constObj)->used - 1;
}
#endif

   sword16
loclFindLocal(struct LocalFunction *this,VarName name)
{
   uword16 i;
   struct localItem *names = this->items + this->InputParameterCount;

   for( i=0; i < this->num_locals; i++, names++ )
   {
      if( name==names->VarName ) return (sword16)i;
   }
   return -1;
}


#if (0!=JSE_COMPILER)
   sword16
loclFindParam(struct LocalFunction *this,VarName name)
{
   uword16 i;
   struct localItem *names = this->items + this->InputParameterCount;

   /* Go backwards because a second param with the same name
    * takes precedence over the first one.
    */
   for( i = this->InputParameterCount;i>0;i-- )
   {
      names--;
      if( name==names->VarName ) return (sword16)(i-1);
   }
   return -1;
}
#endif

   sword16
loclAddLocal(struct Call *call,struct LocalFunction *this,VarName name)
{
   sword16 ret;


   if( (ret = loclFindLocal(this,name))!=-1 )
      return ret;

   if( (uint)(this->InputParameterCount+this->num_locals)>=this->alloced )
   {
#     if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
      this->alloced++;
#     else
      this->alloced += 5;
#     endif
      this->items = jseMustReMalloc(struct localItem,this->items,
                                    (this->alloced) * sizeof(struct localItem));
   }

   this->items[this->InputParameterCount+this->num_locals].VarName = name;
   this->items[this->InputParameterCount+this->num_locals].VarAttrib = 0;
   this->items[this->InputParameterCount+this->num_locals].VarFunc = -1;


   return (sword16)(this->InputParameterCount + this->num_locals++);
}

#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   void NEAR_CALL
localTokenWrite(struct LocalFunction *this,struct Call *call,
                struct TokenSrc *tSrc)
{
   uword16 i;
   rSEObject rConstants;
   MemCountUInt used;

   /* save the function's name for error reporting */
   tokenWriteString(call,tSrc,this->FunctionName);
   /* write byte for boolean about whether this is a C function
      and other flags */
   tokenWriteByte(tSrc, (uword8)( FUNCTION_C_BEHAVIOR(&(this->function))
                                  ? '\1' : '\0' ) );
   /* write maximum param size */
   tokenWriteLong(tSrc,(long)this->max_params);
   /* write all the varnames for this function */
   tokenWriteLong(tSrc,(long)this->InputParameterCount);
   tokenWriteLong(tSrc,this->num_locals);
   for ( i = 0; i < this->InputParameterCount+this->num_locals; i++ )
   {
      tokenWriteString(call,tSrc,this->items[i].VarName);
      /* Also include attributes, because this is how we know if something
       * is passed by reference.
       */
      tokenWriteByte(tSrc,this->items[i].VarAttrib);
      tokenWriteLong(tSrc,this->items[i].VarFunc);
   }
   /* write constants used */
   SEOBJECT_ASSIGN_LOCK_R(rConstants,this->hConstants);
   used = SEOBJECT_PTR(rConstants)->used;
   tokenWriteLong(tSrc,(sword32)used);
   if ( used )
   {
      rSEMembers rMembers;
      if (used != 0)
      {
	 SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(rConstants)->hsemembers);
	 for( i=0;i<used;i++ )
	 {
	    TokenWriteVar(call,tSrc,&(SEMEMBERS_PTR(rMembers)[i].value));
	 }
	 SEMEMBERS_UNLOCK_R(rMembers);
      }
   }
   SEOBJECT_UNLOCK_R(rConstants);
   /* write all thetokens that make up this function */
   secodeTokenWriteList(call,tSrc,this);
}

   void
tokenWriteAllLocalFunctions(struct TokenSrc *this,struct Call *call)
{
   rSEObject robj;
   rSEObjectMem rInit;

   /* Write out the initialization function */
   SEOBJECT_ASSIGN_LOCK_R(robj,CALL_GLOBAL(call));
   rInit = rseobjGetMemberStruct(call,robj,STOCK_STRING(Global_Initialization));
   SEOBJECT_UNLOCK_R(robj);
   assert( SEOBJECTMEM_PTR(rInit)!=NULL );
   assert( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rInit))==VObject );
   SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(rInit)));
   SEOBJECTMEM_UNLOCK_R(rInit);
   assert( SEOBJECT_PTR(robj)->func!=NULL );

   tokenWriteByte(this,(uword8)INITIALIZATION_FUNCTION);
   localTokenWrite(((struct LocalFunction *)SEOBJECT_PTR(robj)->func),call,this);
   SEOBJECT_UNLOCK_R(robj);
}
#endif

#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
   void
localTokenRead(struct Call *call,struct TokenDst *tDst,rSEVar dest)
{
   uint i;
   struct LocalFunction *func;
   uint InputParameterCount;
   uint num_locals;
   VarName varname;
   uint used;
   wSEObject wConstants;

   varname = tokenReadString(call,tDst);

   /* read list of all the tokens that make up this function */
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   func = localNew(call,varname,tokenReadByte(tDst),dest);
#  else
   (void)tokenReadByte(tDst);
   func = localNew(call,varname,dest);
#  endif

   if( func==NULL )
   {
      callQuit(call,textcoreOUT_OF_MEMORY);
      return;
   }

   /* write maximum param size */
   func->max_params = (uword16)tokenReadLong(tDst);
   /* read all the varnames for this function */
   InputParameterCount = (uint)tokenReadLong(tDst);
   num_locals = (uint)tokenReadLong(tDst);
   assert( 0 == func->InputParameterCount );
   for ( i = 0; i < InputParameterCount+num_locals; i++ )
   {
      varname = tokenReadString(call,tDst);
      if ( i < InputParameterCount )
         localAddVarName(func,call,varname);
      else
         loclAddLocal(call,func,varname);
      /* Be sure to read in attributes as well */
      func->items[i].VarAttrib = tokenReadByte(tDst);
      func->items[i].VarFunc = (sword16)tokenReadLong(tDst);
   }
   assert( func->InputParameterCount == InputParameterCount );
   assert( func->num_locals == num_locals );

   used = (uint)tokenReadLong(tDst);
   SEOBJECT_ASSIGN_LOCK_W(wConstants,func->hConstants);
   for( i=0;i<used;i++ )
   {
      wSEObjectMem wMem;
      wMem = SEOBJ_CREATE_MEMBER(call,wConstants,NULL);
      TokenReadVar(call,tDst,SEOBJECTMEM_VAR(wMem));
      SEOBJECTMEM_UNLOCK_W(wMem);
   }
   SEOBJECT_UNLOCK_W(wConstants);
#  if !defined(NDEBUG)
   {
      rSEObject robj;
      SEOBJECT_ASSIGN_LOCK_R(robj,func->hConstants);
      assert( used==SEOBJECT_PTR(robj)->used );
      SEOBJECT_UNLOCK_R(robj);
   }
#  endif

   /* At this point we need to call varSetFunction() again, because the
    * InputParameterCount is actually correct.  Originally, it was set
    * to 0, but now we need to update it
    */
   func->function.params = func->InputParameterCount;
   seobjSetFunction(call,SEVAR_GET_OBJECT(dest),(struct Function *)func);

#  if (0!=JSE_COMPILER)
      /* we don't know what the tokens were, only the bytecodes */
      localMinimizeTokens(func,True);
#  endif

#  ifdef SECODE_LISTINGS
      if( ((struct Function *)func)->flags & Func_CBehavior )
         DebugPrintf(UNISTR("cfunction "));
      else
         DebugPrintf(UNISTR("function "));
      DebugPrintf(UNISTR("%s("),GetStringTableEntry(call,func->FunctionName,NULL));
      for( i=0;i<func->InputParameterCount;i++ )
      {
         DebugPrintf(UNISTR("%s%s%s"),
                     func->items[i].VarAttrib?UNISTR("&"):UNISTR(""),
                     GetStringTableEntry(call,func->items[i].VarName,NULL),
                     i<(uint)(func->InputParameterCount-1)?UNISTR(","):UNISTR(""));
      }
      DebugPrintf(")\n{\n");
#  endif

   /* read the tokens that make the compiled form of this function */
   secodeTokenReadList(call,tDst,func);

#  ifdef SECODE_LISTINGS
   DebugPrintf("}\n");
#  endif
}
#endif
