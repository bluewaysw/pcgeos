/* codeprt2.c   Extension of Code.cpp because it grew too big.
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

#if (0!=JSE_COMPILER) \
 || ( ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) ) \
   && ( defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) ) )
   /* the dot character is placed here intentionally so that it can be ignored
    * if parsing string following a function or cfunction keyword
    */
   CONST_STRING(IllegalVariableChars,".&+-<>|=!*/%^~?:,{};()[]\'\"`#");
#endif

#if (0!=JSE_COMPILER) || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) )
#if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
   jsecharptr NEAR_CALL
CompileRegExpLiteral(struct Call *call,jsecharptr src,jsebool *success,wSEVar wRet)
{
   wSEVar wVar,wTmp,wTmp2;
   rSEVar rVar;
   rSEObjectMem rVarMem;
   jsecharptr pattern;
   jsecharptr flags;
   JSE_POINTER_UINDEX pattern_len = 0,flags_len = 0;
   jsechar c;
   VarName name;


   *success = True;

   /* Parse the regular expression literal */

   JSECHARPTR_INC(src);
   pattern = src;
   c = JSECHARPTR_GETC(src);
   assert( c!='*' ); /* this is a multiline comment and should not get here */
   assert( c!='/' ); /* this is a single line comment and should not get here */
   while( c!='/' )
   {
      pattern_len++;

      if( c=='\r' || c=='\n' )
      {
         callError(call,textcoreNEWLINE_IN_REGEXP);
         *success = False;
         return src;
      }
      else if( c=='\\' )
      {
         pattern_len++;
         JSECHARPTR_INC(src);
         c = JSECHARPTR_GETC(src);
         if( c=='\r' || c=='\n' )
         {
            callError(call,textcoreNEWLINE_IN_REGEXP);
            *success = False;
            return src;
         }
      }

      JSECHARPTR_INC(src);
      c = JSECHARPTR_GETC(src);
   }

   assert( c=='/' );
   JSECHARPTR_INC(src);
   flags = src;

   /* flags are the same characters legal in an identifier */

   while( 1 )
   {
      c = JSECHARPTR_GETC(src);
      if( NULL!=strchr_jsechar((jsecharptr)IllegalVariableChars,c) ||
          IS_WHITESPACE(c) ) break;
      JSECHARPTR_INC(src);
      flags_len++;
   }

   /* Call the constructor to create a new RegExp object */

   /* first look up the RegExp constructor */

   name = LockedStringTableEntry(call,REGEXP_PROPERTY,6);

   wVar = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(wVar);
   if( !callFindAnyVariable(call,name,True,False) || SEVAR_GET_TYPE(wVar)!=VObject )
   {
      callError(call,textcoreNEWLINE_IN_REGEXP);
      *success = False;
      return src;
   }

   /* we need the 'this' first, constructor second, but also cannot
    * have a collection eat something up, hence the unusual code
    * below.
    */
   rVar = seobjGetFuncVar(call,wVar,STOCK_STRING(_construct),&rVarMem);
   wTmp = STACK_PUSH;
   SEVAR_COPY(wTmp,rVar);
   wTmp2 = STACK_PUSH;
   SEVAR_COPY(wTmp2,wTmp);
   sevarInitNewObject(call,wTmp,rVar);
   wTmp = STACK_PUSH;
   SEVAR_INIT_STRING_STRLEN(call,wTmp,pattern,pattern_len);
   if( flags_len!=0 )
   {
      wTmp = STACK_PUSH;
      SEVAR_INIT_STRING_STRLEN(call,wTmp,flags,flags_len);
   }

#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEOBJECTMEM_PTR(rVarMem) )
         SEOBJECTMEM_UNLOCK_R(rVarMem);
#  endif

   callFunctionFully(call,(uword16)((flags_len>0)?2:1),True);

   wTmp = STACK0;

   SEVAR_COPY(wRet,wTmp);

   /* discard return value and found variable (by name) and then return */
   STACK_POPX(2);

   return src;
}
#endif /* defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) */
#endif /* (0!=JSE_COMPILER) || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) ) */


#if (0!=JSE_COMPILER)

   jsecharptr NEAR_CALL
secompileStringToken(struct tok *token,struct secompile *compile,
                     jsecharptr src,jsebool *success)
{
   jsecharptr End;
   jsecharptr beyondEnd;
   jsechar c, quoteChar;
   struct Call *call = compile->call;

   /* whatever else goes wrong, calling code expects a variable to be created */
   wSEVar wVar = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(wVar);

   assert( src!=NULL );

   quoteChar = JSECHARPTR_GETC(src);

   assert( quoteChar  &&  strchr_jsechar(UNISTR("`\"\'"),quoteChar) );
   *success = True;

   /* find the end, which is a quote (not preceded by '\\' except with '`' */
   End = src;
   do {
      JSECHARPTR_INC(End);
      c = JSECHARPTR_GETC(End);
      if ( quoteChar == c )
         break;
      if ( UNICHR('\\') == c  &&  UNICHR('`') != quoteChar )
      {
         /* go beyond escape sequence if quote follows it */
         JSECHARPTR_INC(End);
         c = JSECHARPTR_GETC(End);
      }
   } while ( UNICHR('\0') != c );
   if ( c != quoteChar  )
   {
      /* make error in reasonable-sized buffer */
      jsechar ErrorBuf[80];
      strncpy_jsechar((jsecharptr)ErrorBuf,src,(sizeof(ErrorBuf)/sizeof(jsechar))-1);
      callError(call,textcoreNO_TERMINATING_QUOTE,quoteChar,ErrorBuf);
      *success = False;
   }
   else
   {
      jsechar TempSaveBeyondEnd;
      jsebool AssignSuccess;
      /* assign the string to the variable */
      assert( 0 != JSECHARPTR_GETC(End) );
      beyondEnd = End;
      JSECHARPTR_INC(beyondEnd);
      TempSaveBeyondEnd = JSECHARPTR_GETC(beyondEnd);

      JSECHARPTR_PUTC(beyondEnd,UNICHR('\0'));
      assert( *success );
      *success = sevarAssignFromText(wVar,call,src,&AssignSuccess,False,&src);
      SEVAR_CONSTANT_STRING(wVar);
      JSECHARPTR_PUTC(beyondEnd,TempSaveBeyondEnd);
      if ( *success )
      {
         /* check if variable must concatenate with previous variables */
         assert( src == beyondEnd );
         src = End; /* will have gone 1 too many */
         assert( VString == SEVAR_GET_TYPE(wVar) );
      }

   }

   if( call->Global->CompileStatus.c_function &&
       quoteChar=='\'' && SEVAR_STRING_LEN(wVar)==1 )
   {
      /* In cfunction, turn 'a' into the numeric for 'a' */
      JSE_MEMEXT_R jsecharptr data = sevarGetData(call,wVar);
      jsechar cval = JSECHARPTR_GETC(data);
      SEVAR_FREE_DATA(call,data);
      SEVAR_INIT_SLONG(wVar,cval);
   }

   tokSetVar(token,compile,wVar);
   STACK_POP;
   return JSECHARPTR_NEXT(src);
}


#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

CONST_DATA(struct KeyWords_) KeyWords[] =
{
   { UNISTR("this"),            seTokThis },
   { textcorevtype_null,        seTokNull },
   { textcorevtype_bool_true,   seTokTrue },
   { textcorevtype_bool_false,  seTokFalse },
   { textcoreVariableKeyword,   seTokVar },
   { textcoreNewKeyword,        seTokNew },
   { textcoreIfKeyword,         seTokIf },
   { textcoreElseKeyword,       seTokElse },
   { textcoreSwitchKeyword,     seTokSwitch },
   { textcoreCaseKeyword,       seTokCase },
   { textcoreDefaultKeyword,    seTokDefault },
   { textcoreWhileKeyword,      seTokWhile },
   { textcoreDoKeyword,         seTokDo },
   { textcoreForKeyword,        seTokFor },
   { textcoreInKeyword,         seTokIn },
   { textcoreTryKeyword,        seTokTry },
   { textcoreThrowKeyword,      seTokThrow },
   { textcoreCatchKeyword,      seTokCatch },
   { textcoreFinallyKeyword,    seTokFinally },
   { textcoreDeleteKeyword,     seTokDelete },
   { textcoreTypeofKeyword,     seTokTypeof },
   { textcoreInstanceofKeyword, seTokInstanceof},
   { textcoreVoidKeyword,       seTokVoid },
   { textcoreWithKeyword,       seTokWith },
   { textcoreBreakKeyword,      seTokBreak },
   { textcoreContinueKeyword,   seTokContinue },
   { textcoreGotoKeyword,       seTokGoto },
   { textcoreReturnKeyword,     seTokReturn },
   { textcoreFunctionKeyword,   seTokFunction },

#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   { textcoreCFunctionKeyword,  seTokCFunction },
#  endif

   /* reserved for future use as of ECMA2.0 */


   {textcoreAbstractKeyword, seTokUnknown},
   {textcoreBooleanKeyword, seTokUnknown},
   {textcoreByteKeyword, seTokUnknown},
   {textcoreCharKeyword, seTokUnknown},
   {textcoreClassKeyword, seTokUnknown},
   {textcoreConstKeyword, seTokUnknown},
   {textcoreDebuggerKeyword, seTokUnknown},
   {textcoreDoubleKeyword, seTokUnknown},
   {textcoreEnumKeyword, seTokUnknown},
   {textcoreExportKeyword, seTokUnknown},
   {textcoreExtendsKeyword, seTokUnknown},
   {textcoreFinalKeyword, seTokUnknown},
   {textcoreFloatKeyword, seTokUnknown},
   {textcoreImplementsKeyword, seTokUnknown},
   {textcoreImportKeyword, seTokUnknown},
   {textcoreIntKeyword, seTokUnknown},
   {textcoreInterfaceKeyword, seTokUnknown},
   {textcoreLongKeyword, seTokUnknown},
   {textcoreNativeKeyword, seTokUnknown},
   {textcorePackageKeyword, seTokUnknown},
   {textcorePrivateKeyword, seTokUnknown},
   {textcoreProtectedKeyword, seTokUnknown},
   {textcorePublicKeyword, seTokUnknown},
   {textcoreShortKeyword, seTokUnknown},
   {textcoreStaticKeyword, seTokUnknown},
   {textcoreSuperKeyword, seTokUnknown},
   {textcoreSynchronizedKeyword, seTokUnknown},
   {textcoreThrowsKeyword, seTokUnknown},
   {textcoreTransientKeyword, seTokUnknown},
   {textcoreVolatileKeyword, seTokUnknown},

   {NULL}
};

#ifdef __JSE_GEOS__
#pragma option -dc-

#include <heap.h>
#endif

   setokval NEAR_CALL
GetVariableNameOrKeyword(struct tok *this,struct Call *call,jsecharptr *RetSource)
{
   jsecharptr Start;
   jsecharptr End;
   jsechar tmpChar;
   setokval Type;
   sint VarNameLen;
   struct KeyWords_ const *Key;
#ifdef __JSE_GEOS__
   jsechar *kw;
#endif   

   assert( 0 != JSECHARPTR_GETC(*((const jsecharptr *)RetSource)) );
   assert( !IS_WHITESPACE(JSECHARPTR_GETC(*RetSource)) );
   assert( NULL == strchr_jsechar((jsecharptr)IllegalVariableChars,JSECHARPTR_GETC(*((const jsecharptr *)RetSource))) );
   for ( End = Start = *RetSource, VarNameLen = 0;
         0 != (tmpChar=JSECHARPTR_GETC(End))  &&  !IS_WHITESPACE(tmpChar)
         &&  NULL == strchr_jsechar((jsecharptr)IllegalVariableChars,tmpChar);
         JSECHARPTR_INC(End) )
   {
      VarNameLen++;
   }
   assert( End != Start );
   assert( 0 < VarNameLen ); /* else almostAlmostEnd is invalid */

   for ( Key = KeyWords; NULL != Key->Word; Key++ )
   {
#ifdef __JSE_GEOS__
      kw = MemLockFixedOrMovable(Key->Word);
      if ( 0 == strncmp_jsechar(Start,kw,(size_t)VarNameLen)
	   && (size_t)VarNameLen == strlen_jsechar(kw) ) {
	 MemUnlockFixedOrMovable(Key->Word);
         break;
      }
      MemUnlockFixedOrMovable(Key->Word);
#else
      if ( 0 == strncmp_jsechar(Start,Key->Word,(size_t)VarNameLen)
        && (size_t)VarNameLen == strlen_jsechar(Key->Word) )
         break;
#endif
   }
   *RetSource = End;


   if ( NULL != Key->Word )
   {
      if( (Type = Key->Type) == seTokUnknown )
      {
         jsechar buffer[100];
         if( VarNameLen > 99 ) VarNameLen = 99;
         memset(buffer,0,sizeof(buffer)); /* assure null-terminated */
         strncpy_jsechar((jsecharptr)buffer,Start,(size_t)VarNameLen);
         callError(call,textcoreRESERVED_KEYWORD,buffer);
         tokSetNameText(this,call,(jsecharptr)buffer,VarNameLen);
         return seTokUnknown;
      }
   }
   else
   {
      /* save this variable name */
      Type = seTokIdentifier;
      tokSetNameText(this,call,Start,VarNameLen);
   }

   this->type = Type;
   return Type;
}


#endif /* #if (0!=JSE_COMPILER) */
