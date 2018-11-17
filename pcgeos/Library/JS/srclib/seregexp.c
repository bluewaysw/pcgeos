/* seregexp.c   Regular Expression Library
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

#include "jseopt.h"

#if defined(JSE_REGEXP_ANY)
#if !defined(JSE_REGEXP_OBJECT)
#  error must #define JSE_REGEXP_OBJECT 1 or #define JSE_REGEXP_ALL to use JSE_REGEXP_ANY
#endif

static CONST_STRING(compile_MEMBER,"compile");
       CONST_STRING(exec_MEMBER,"exec");
       CONST_STRING(global_MEMBER,"global");
static CONST_STRING(ignoreCase_MEMBER,"ignoreCase");
       CONST_STRING(index_MEMBER,"index");
       CONST_STRING(input_MEMBER,"input");
       CONST_STRING(lastIndex_MEMBER,"lastIndex");
static CONST_STRING(lastMatch_MEMBER,"lastMatch");
static CONST_STRING(lastParen_MEMBER,"lastParen");
static CONST_STRING(leftContext_MEMBER,"leftContext");
static CONST_STRING(multiline_MEMBER,"multiline");
static CONST_STRING(rightContext_MEMBER,"rightContext");
static CONST_STRING(source_MEMBER,"source");
static CONST_STRING(test_MEMBER,"test");

/* PERL ALIASING: callback function to alias $* to multiline, for instance */
   static const jsecharptr NEAR_CALL
EcmaAliasOfPerlName(jseContext jsecontext,jseString perlName) /* return ecma name, else no if no alias */
{
   const jsecharptr perlString;
   JSE_POINTER_UINDEX perlStringLength;
   const jsecharptr ret = NULL;  /* assume it is not an alias */

   perlString = jseGetInternalString(jsecontext,perlName,&perlStringLength);
   if ( 2 == perlStringLength )
   {
#     if defined(JSE_MBCS) && (0!=JSE_MBCS) && !defined(NDEBUG)
      {
         static CONST_STRING(perlAliasChars,"$\'_&`+*");
         /* for faster MBCS checking that none of these are special 2-byte characters */
         assert( strlen(perlAliasChars) == strlen_jsechar(perlAliasChars) );
      }
#     endif
      if ( '$' == ((jsecharptrdatum*)(perlString))[0] )
      {
         switch ( ((jsecharptrdatum*)(perlString))[1] )
         {
            case '\'':  ret = rightContext_MEMBER;       break;
            case '_':   ret = input_MEMBER;              break;
            case '&':   ret = lastMatch_MEMBER;          break;
            case '`':   ret = leftContext_MEMBER;        break;
            case '+':   ret = lastParen_MEMBER;          break;
            case '*':   ret = multiline_MEMBER;          break;
            default:                                     break;
         }
      }
   }
   return ret;
}

   static jseVariable JSE_CFUNC FAR_CALL
regexpGetCallback(jseContext jsecontext,jseVariable obj,jseString prop,jsebool callHint)
{
   const jsecharptr ecmaName = EcmaAliasOfPerlName(jsecontext,prop);
   return ( NULL == ecmaName )
          ? NULL
          : /* perl expression being retrieved; return the ecma version instead */
            jseGetMemberEx(jsecontext,obj,ecmaName,jseCreateVar);
}


   static jsebool JSE_CFUNC FAR_CALL
regexpPutCallback(jseContext jsecontext,jseVariable obj,jseString prop,jseVariable to_put)
{
   const jsecharptr ecmaName = EcmaAliasOfPerlName(jsecontext,prop);
   jseVariable xlat;
   if ( ecmaName == NULL )
      return False; /* default behavior, no translation */

   xlat = jseMemberEx(jsecontext,obj,ecmaName,jseTypeUndefined,jseCreateVar);
   assert( NULL != xlat );
   jseAssign(jsecontext,xlat,to_put);
   jseDestroyVariable(jsecontext,xlat);

   return True;
}

static VAR_DATA(struct jseObjectCallbacks) regexpCallbacks =
   { regexpGetCallback, regexpPutCallback, NULL, NULL, NULL, NULL
#if 0!=JSE_OPERATOR_OVERLOADING
  ,NULL
#endif
   };

static jseLibFunc(RegExp_exec);
static jseLibFunc(RegExp_call);
static jseLibFunc(RegExp_compile);
static jseLibFunc(RegExp_test);
static jseLibFunc(RegExp_delete);

static jseLibFunc(RegExp_callexec);

static jseLibFunc(RegExp_toString)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable tmp;
   const jsecharhugeptr orig;
   jsecharptr buf;
   jsecharptr buf2;
   JSE_POINTER_UINDEX len;


   if( !ensure_type(jsecontext,thisVar,REGEXP_PROPERTY) )
      return;

   tmp = jseGetMember(jsecontext,thisVar,source_MEMBER);
   if( tmp!=NULL || jseGetType(jsecontext,tmp)!=jseTypeString )
   {
      /* If it is NULL, this is not really a regexp object */
      orig = jseGetString(jsecontext,tmp,&len);
      buf2 = buf = jseMustMalloc(jsecharptrdatum,(len+6)*sizeof(jsechar));
      assert( buf!=NULL );
      JSECHARPTR_PUTC(buf2,'/');
      JSECHARPTR_INC(buf2);
      strncpy_jsechar(buf2,(jsecharptr)orig,len);
      buf2 = JSECHARPTR_OFFSET(buf2,len);
      JSECHARPTR_PUTC(buf2,'/');
      JSECHARPTR_INC(buf2);

      tmp = jseGetMember(jsecontext,thisVar,global_MEMBER);
      if( tmp!=NULL && jseGetType(jsecontext,tmp)==jseTypeBoolean &&
          jseGetBoolean(jsecontext,tmp) )
      {
         JSECHARPTR_PUTC(buf2,'g');
         JSECHARPTR_INC(buf2);
      }

      tmp = jseGetMember(jsecontext,thisVar,ignoreCase_MEMBER);
      if( tmp!=NULL && jseGetType(jsecontext,tmp)==jseTypeBoolean &&
          jseGetBoolean(jsecontext,tmp) )
      {
         JSECHARPTR_PUTC(buf2,'i');
         JSECHARPTR_INC(buf2);
      }

      tmp = jseGetMember(jsecontext,thisVar,multiline_MEMBER);
      if( tmp!=NULL && jseGetType(jsecontext,tmp)==jseTypeBoolean &&
          jseGetBoolean(jsecontext,tmp) )
      {
         JSECHARPTR_PUTC(buf2,'m');
         JSECHARPTR_INC(buf2);
      }

      JSECHARPTR_PUTC(buf2,'\0');

      tmp = jseCreateVariable(jsecontext,jseTypeString);
      jsePutStringLength(jsecontext,tmp,buf,strlen_jsechar(buf));
      jseReturnVar(jsecontext,tmp,jseRetTempVar);

      jseMustFree(buf);
   }
}

   static void NEAR_CALL
initPerlMatches(jseContext jsecontext, jseVariable obj_var)
{
   jseVariable jseChild;
   int i;

   /* set RegExp.$1 ... RegExp.$9 to be NULL string */
   for( i = 1;  i < 10; i++ )
   {
      jsecharptrdatum perl_num[3];
#     if defined(JSE_MBCS) && (0!=JSE_MBCS)
         assert( sizeof_jsechar('$') == sizeof(jsecharptrdatum) );
         assert( bytestrlen_jsechar("123456789") == 9 );
         assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
#     endif
      perl_num[0] = '$';
      perl_num[1] = (jsecharptrdatum)('0' + i);
      perl_num[2] = '\0';

      jseChild = jseMemberEx(jsecontext,obj_var,perl_num,jseTypeString,jseCreateVar);
      jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
      jsePutString(jsecontext,jseChild,UNISTR(""));
      jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);

      jseDestroyVariable(jsecontext,jseChild);
   }
}

   static jsebool NEAR_CALL
compileRegExp(jseContext jsecontext, jseVariable regexpObject, jsebool initialize )
{
   jseVariable jsePattern, jseOptions;
   const jsecharptr pattern;
   jsecharptr options;
   JSE_POINTER_UINDEX  patternLength, optionsLength;
   jsebool ignoreCase = False, globalMatch = False, setFlags = False;
   jsebool multiline = False;
   int i;
   jseVariable tempMember;

   assert( NULL != regexpObject );
   /* if( regexpObject == NULL )
    *   initialize = True;
    */

   if( jseFuncVarCount(jsecontext) > 0 )
   {
      jsePattern = jseFuncVarNeed(jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      if( jsePattern == NULL )
         return False;
      pattern = (const jsecharptr)jseGetString(jsecontext,jsePattern,&patternLength);
   }
   else
   {
      pattern = UNISTR("");
      patternLength = 0;
   }

   /* For RegExp.compile(), if there is no argument or only one argument
    * passed to the function, the flags need to be set (to be false).
    * otherwise, the RegExp will "remember" the value being set last time. */
   if( jseFuncVarCount(jsecontext) <= 1 && !initialize )
      setFlags = True;

   if( jseFuncVarCount(jsecontext) > 1 )
   {
      setFlags = True;
      jseOptions = jseFuncVarNeed(jsecontext,1,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      if( jseOptions == NULL )
         return False;
      options = (jsecharptr)jseGetString(jsecontext,jseOptions,&optionsLength);


      for( i = 0; (size_t)i < optionsLength; i++, JSECHARPTR_INC(options) )
      {
         switch( JSECHARPTR_GETC(options) )
         {
            case 'i':
               if( ignoreCase )
               {
                  jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_INVALID_OPTIONS));
                  return False;
               }
               ignoreCase = True;
               break;
            case 'g':
               if( globalMatch )
               {
                  jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_INVALID_OPTIONS));
                  return False;
               }
               globalMatch = True;
               break;
            case 'm':
               if( multiline )
               {
                  jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_INVALID_OPTIONS));
                  return False;
               }
               multiline = True;
               break;
            default:
               jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_INVALID_OPTIONS));
               return False;
         }
      }

   }


   /* Ok, as near as I can figure, the intent here is that if we have
    * set flags, we individually turn each on/off. If we have not
    * set them, we do not alter their values. However, we do use
    * jseMemberEx() to make sure the member exists (and will get
    * the default False if being created.)
    */

   /* 'global' property */
   tempMember = jseMemberEx(jsecontext,regexpObject,global_MEMBER,jseTypeBoolean,jseCreateVar);
   if( setFlags )
   {
      jseSetAttributes(jsecontext,tempMember,jseDefaultAttr);
      jsePutBoolean(jsecontext,tempMember,globalMatch);
   }
   jseSetAttributes(jsecontext,tempMember,jseReadOnly|jseDontDelete);
   jseDestroyVariable(jsecontext,tempMember);

   /* 'ignoreCase' property */
   tempMember = jseMemberEx(jsecontext,regexpObject,ignoreCase_MEMBER,jseTypeBoolean,jseCreateVar);
   if( setFlags )
   {
      jseSetAttributes(jsecontext,tempMember,jseDefaultAttr);
      jsePutBoolean(jsecontext,tempMember,ignoreCase);
   }
   jseSetAttributes(jsecontext,tempMember,jseReadOnly|jseDontDelete);
   jseDestroyVariable(jsecontext,tempMember);

   /* 'multiline' property */
   tempMember = jseMemberEx(jsecontext,regexpObject,multiline_MEMBER,jseTypeBoolean,jseCreateVar);
   if( setFlags )
   {
      jseSetAttributes(jsecontext,tempMember,jseDefaultAttr);
      jsePutBoolean(jsecontext,tempMember,multiline);
   }
   jseSetAttributes(jsecontext,tempMember,jseReadOnly|jseDontDelete);
   jseDestroyVariable(jsecontext,tempMember);

   /* 'lastIndex' property */
   if( initialize )
   {
      tempMember = jseMemberEx(jsecontext,regexpObject,lastIndex_MEMBER,
                               jseTypeNumber,jseCreateVar);
      jsePutLong(jsecontext,tempMember,0);
      jseDestroyVariable(jsecontext,tempMember);
   }
   /* 'class' property */
   if( initialize )
   {
      tempMember = jseMemberEx(jsecontext,regexpObject,CLASS_PROPERTY,
                               jseTypeString,jseCreateVar);
      jsePutString(jsecontext,tempMember,REGEXP_PROPERTY);
      jseDestroyVariable(jsecontext,tempMember);
   }

   /* 'source' property */
   tempMember = jseMemberEx(jsecontext,regexpObject,source_MEMBER,jseTypeString,jseCreateVar);
   jseSetAttributes(jsecontext,tempMember,jseDefaultAttr);
   jsePutStringLength(jsecontext,tempMember,pattern,patternLength);
   jseSetAttributes(jsecontext,tempMember,jseReadOnly|jseDontDelete);
   jseDestroyVariable(jsecontext,tempMember);

   if( initialize )
   {
      jseInitializeObject(jsecontext,regexpObject,REGEXP_PROPERTY);
      /* And the 'delete' property */
      jseMemberWrapperFunction(jsecontext,regexpObject,DELETE_PROPERTY,RegExp_delete,1,1,
                               jseReadOnly|jseDontEnum|jseDontDelete,jseFunc_Secure,NULL);

   }

   {
      regex_t *compiled;
      int flags = PCRE_EXTENDED;
      int error;
      const char * asciiPattern;

      /* get pointer to compiled-buffer, create if not there already */
      compiled = jseGetObjectData(jsecontext,regexpObject);
      if ( NULL == compiled )
      {
         compiled = jseMustMalloc(regex_t,sizeof(*compiled));
         compiled->re_pcre = NULL; /* have not compiled yet */
         memset(compiled,0,sizeof(*compiled));
         jseSetObjectData(jsecontext,regexpObject,compiled);
      }

      tempMember = jseGetMemberEx(jsecontext,regexpObject,ignoreCase_MEMBER,
                                  jseCreateVar);
      /* because created above using jseMember() */
      assert( NULL != tempMember );

      if( jseEvaluateBoolean(jsecontext,tempMember) )
         flags |= PCRE_CASELESS;
      jseDestroyVariable(jsecontext,tempMember);

      tempMember = jseGetMemberEx(jsecontext,regexpObject,multiline_MEMBER,
                                  jseCreateVar);
      /* because created above using jseMember() */
      assert( NULL != tempMember );
      if( jseEvaluateBoolean(jsecontext,tempMember) )
         flags |= PCRE_MULTILINE;
      jseDestroyVariable(jsecontext,tempMember);

      asciiPattern = JsecharToAscii(pattern);

      /* if this is already compiled, then free the old one */
      if ( NULL != compiled->re_pcre )
         ecma_regfree(compiled);

      error = ecma_regcomp(compiled,asciiPattern,flags);
      FreeAsciiString(asciiPattern);

      if( error != 0 )
      {
         const jsecharptr errormsg;
         char buffer[256];

         ecma_regerror(error,compiled,buffer,256);

         errormsg = AsciiToJsechar(buffer);
         jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_CANT_COMPILE),errormsg);
         FreeJsecharString(errormsg);

         return False;
      }
   }

   return True;
}

static jseLibFunc(RegExp_delete)
{
   jseVariable thisVar = jseGetCurrentThisVariable(jsecontext);
   jseVariable jseProperty;
   const jsecharptr property;

   if( !ensure_type(jsecontext,thisVar,REGEXP_PROPERTY) )
      return;

   JSE_FUNC_VAR_NEED(jseProperty,jsecontext,0,JSE_VN_STRING);
   property = (const jsecharptr)jseGetString(jsecontext,jseProperty,NULL);

   if( 0 == strcmp_jsechar(property,DELETE_PROPERTY) )
   {
      regex_t *compiled;

      compiled = jseGetObjectData(jsecontext,thisVar);
      if ( NULL != compiled )
      {
         if ( NULL != compiled->re_pcre )
            ecma_regfree(compiled);
         jseMustFree(compiled);
      }
   }
   else
      jseDeleteMember(jsecontext,thisVar,property);
}


   static void NEAR_CALL
RegExp_CallOrCompile(jseContext jsecontext,jseVariable regexpObject,
                     jsebool initialize)
{
   if (jseFuncVarCount(jsecontext) > 0)
   {
      jseVariable tmp;
      jseVariable jsePattern = jseFuncVarNeed(jsecontext,0,JSE_VN_ANY);

      /* if the pattern is already a RegExp object and
       * 1. if flag is undefined, return the object unchanged
       * 2. if flag is not undefined, throw a TypeError exception
       * otherwise, pass the arguments to constructor.
       */
      if( jseGetType(jsecontext,jsePattern)==jseTypeObject
       && (tmp = jseGetMember(jsecontext,jsePattern,CLASS_PROPERTY))!=NULL
       && strcmp_jsechar(jseGetStringDatum(jsecontext,tmp,NULL,NULL),REGEXP_PROPERTY)==0 )
      {
         if(jseFuncVarCount(jsecontext) == 1)
         {
            jseAssign(jsecontext, regexpObject, jsePattern);
            jseReturnVar(jsecontext,regexpObject,jseRetTempVar);
         }
         else
         {
            jseDestroyVariable(jsecontext,regexpObject);
         }
      }
      else
      {
         if( !compileRegExp(jsecontext,regexpObject,initialize) )
         {
            jseDestroyVariable(jsecontext,regexpObject);
         }
         else
         {
            jseReturnVar(jsecontext,regexpObject,jseRetTempVar);
         }
      }
   }
   else
   {
      if( !compileRegExp(jsecontext,regexpObject,initialize) )
      {
         jseDestroyVariable(jsecontext,regexpObject);
      }
      else
      {
         jseReturnVar(jsecontext,regexpObject,jseRetTempVar);
      }
   }
}


static jseLibFunc(RegExp_call)
{
   jseVariable regexpObject = jseCreateWrapperFunction(jsecontext,CALL_PROPERTY,
                    RegExp_callexec,0,1,jseDontEnum,jseFunc_Secure, NULL);

   /* alias some perl versions */
   jseSetObjectCallbacks(jsecontext,regexpObject,&regexpCallbacks);

   RegExp_CallOrCompile(jsecontext,regexpObject,True);

}

static jseLibFunc(RegExp_compile)
{
   jseVariable thisVar;

   if( !ensure_type(jsecontext,jseGetCurrentThisVariable(jsecontext),REGEXP_PROPERTY) )
      return;

   /* create reference to original thisvar */
   thisVar = jseCreateSiblingVariable(jsecontext,jseGetCurrentThisVariable(jsecontext),0);

   RegExp_CallOrCompile(jsecontext,thisVar,False);

}

static void NEAR_CALL RegExp_ExecOrCallOrTest(jseContext jsecontext,jseVariable thisVar, jsebool isTest)
{
   jseVariable jseInput, jseGlobal, jseLastIndex;
   const jsecharptr input;
   const char* asciiInput;
   JSE_POINTER_UINDEX inputLength;
   regex_t *compiled;
   regmatch_t *matches;
   uint nmatch;
   int error;
   slong lastIndex = 0;
   jsebool setIndex = False;
   jsebool badIndex = False;

   if( !ensure_type(jsecontext,thisVar,REGEXP_PROPERTY) )
      return;

   compiled = jseGetObjectData(jsecontext,thisVar);
   assert( NULL != compiled );

   if( jseFuncVarCount(jsecontext) > 0 )
   {
      JSE_FUNC_VAR_NEED(jseInput,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      input = (const jsecharptr)jseGetString(jsecontext,jseInput,&inputLength);
   }
   else
   {
      jseVariable gl_obj = jseFindVariable(jsecontext,REGEXP_PROPERTY,jseCreateVar);
      assert( gl_obj != NULL );

      jseInput = jseGetMember(jsecontext,gl_obj,input_MEMBER);
      if( jseInput != NULL )
      {
         jseVariable converted = jseCreateConvertedVariable(jsecontext,jseInput,jseToString);
         if( converted == NULL )
            return;

         input = (const jsecharptr)jseGetString(jsecontext,converted,&inputLength);
         jseDestroyVariable(jsecontext,converted);
      }
      else
      {
         /* NYI: no specific discription on situation that RegExp.input is undefined,
          * an empty string seems to be the solution from I.E browser.
          */
         jseVariable jseChild = jseMemberEx(jsecontext,gl_obj,input_MEMBER,jseTypeString,jseCreateVar);
         jsePutString(jsecontext,jseChild,UNISTR(""));
         jseDestroyVariable(jsecontext,jseChild);
         input = UNISTR("");
      }

      jseDestroyVariable(jsecontext,gl_obj);
   }

   jseLastIndex = jseMember(jsecontext,thisVar,lastIndex_MEMBER,jseTypeNumber);
   assert( NULL != jseLastIndex );
   jseLastIndex = jseCreateConvertedVariable(jsecontext,jseLastIndex,jseToInteger);
   if( jseLastIndex == NULL )
      return;
   jseDestroyVariable(jsecontext,jseLastIndex);


   jseGlobal = jseMemberEx(jsecontext,thisVar,global_MEMBER,jseTypeBoolean,jseCreateVar);
   assert( NULL != jseGlobal );
   if( jseEvaluateBoolean(jsecontext,jseGlobal) )
   {  /* This is a global search */
      jseVariable converted;

      jseLastIndex = jseMemberEx(jsecontext,thisVar,lastIndex_MEMBER,jseTypeNumber,jseCreateVar);
      assert( NULL != jseLastIndex );
      converted = jseCreateConvertedVariable(jsecontext,jseLastIndex,jseToInteger);
      assert( converted != NULL );
      jseAssign(jsecontext,jseLastIndex,converted);
      jseDestroyVariable(jsecontext,converted);

      lastIndex = jseGetLong(jsecontext,jseLastIndex);
      setIndex = True;
      if( lastIndex > (slong) inputLength )
      {
         jsePutLong(jsecontext,jseLastIndex,0);
         badIndex = True;
      }

      jseDestroyVariable(jsecontext,jseLastIndex);
   }

   jseDestroyVariable(jsecontext,jseGlobal);

   if( badIndex )
   {
      jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeNull),jseRetTempVar);
      return;
   }
   asciiInput = JsecharToAscii(JSECHARPTR_OFFSET(input,lastIndex));
   nmatch = compiled->re_nsub+1;
   /* "*3" in the following lines may be a kludge, but the regex functions seems
    * to want some extra working room or the results aren't always right.  It
    * uses %3 to figure working room so I figure *3 should handle anything - brent
    */
   matches = jseMustMalloc(regmatch_t,(nmatch*3)*sizeof(regmatch_t));
   error = ecma_regexec(compiled,asciiInput,(nmatch*3),matches,0);
   FreeJsecharString(asciiInput);

   if( error == REG_NOMATCH )
   {
      if( setIndex )
      {
         jseLastIndex = jseMemberEx(jsecontext,thisVar,lastIndex_MEMBER,jseTypeNumber,jseCreateVar);
         jsePutLong(jsecontext,jseLastIndex,0);
         jseDestroyVariable(jsecontext,jseLastIndex);
      }

      if( isTest )
      {
         jseVariable jseResults = jseCreateVariable(jsecontext,jseTypeBoolean);
         jsePutBoolean(jsecontext,jseResults,False);
         jseReturnVar(jsecontext,jseResults,jseRetTempVar);
      }
      else
      {
         jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeNull),jseRetTempVar);
      }
   }
   else if( error != 0 )
   {
      const jsecharptr errormsg;
      char buffer[256];

      ecma_regerror(error,compiled,buffer,256);

      errormsg = AsciiToJsechar(buffer);
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibREGEXP_CANT_COMPILE),errormsg);
      FreeJsecharString(errormsg);
   }
   else
   {
      /* OK we have a successful match, finally !*/
      int i;
      jseVariable jseChild, jseResults, gl_obj;

      if (isTest)
      {
         jseResults = jseCreateVariable(jsecontext,jseTypeBoolean);
         jsePutBoolean(jsecontext,jseResults,True);
      }
      else
      {
         jseResults = jseCreateVariable(jsecontext,jseTypeObject);

         jseConstructObject(jsecontext, jseResults, ARRAY_PROPERTY, NULL);

         for( i = 0; (uint)i < nmatch /*&& matches[i].rm_so != -1*/; i++ )
         {
            if ( matches[i].rm_so == -1 )
            {
               jseChild = jseIndexMemberEx(jsecontext,jseResults,i,jseTypeUndefined,jseCreateVar);
            }
            else
            {
               jseChild = jseIndexMemberEx(jsecontext,jseResults,i,jseTypeString,jseCreateVar);
               jsePutStringLength(jsecontext,jseChild,JSECHARPTR_OFFSET(input,lastIndex+matches[i].rm_so),
                                                (JSE_POINTER_UINDEX)(matches[i].rm_eo-matches[i].rm_so));
            }
            jseDestroyVariable(jsecontext,jseChild);
         }
      }

      if( setIndex )
      {
         jseLastIndex = jseMemberEx(jsecontext,thisVar,lastIndex_MEMBER,jseTypeNumber,jseCreateVar);
         assert( jseLastIndex != NULL );
         jsePutLong(jsecontext,jseLastIndex,lastIndex+matches[0].rm_eo);
         jseDestroyVariable(jsecontext,jseLastIndex);
      }

      /* Since we only passed the string starting with the last index,
       * the result will be given back relative to that, we need
       * relative to the whole string.
       */
      if (!isTest)
      {
         jseChild = jseMemberEx(jsecontext,jseResults,index_MEMBER,jseTypeNumber,jseCreateVar);
         jsePutLong(jsecontext,jseChild,matches[0].rm_so+lastIndex);
         jseDestroyVariable(jsecontext,jseChild);

         jseChild = jseMemberEx(jsecontext,jseResults,input_MEMBER,jseTypeString,jseCreateVar);
         jsePutString(jsecontext,jseChild,input);
         jseDestroyVariable(jsecontext,jseChild);

         jseChild = jseMemberEx(jsecontext,jseResults,LENGTH_PROPERTY,jseTypeNumber,jseCreateVar);
         jsePutLong(jsecontext,jseChild,(slong)i);
         jseDestroyVariable(jsecontext,jseChild);
      }

      /* Now we have to update the global RegExp properties */
      gl_obj = jseFindVariable(jsecontext,REGEXP_PROPERTY,jseCreateVar);

      /* For perl users, add RegExp.$1 to RegExp.$9 */
      /* Since RegExp.$1 takes matches[1] as value, RegExp.$2 has matches[2], ...
       * we sould start the index at 1 instead of 0
       */

      initPerlMatches(jsecontext,gl_obj);

      for( i = 1; (uint)i < nmatch  &&  i < 10/*&& matches[i].rm_so != -1*/; i++ )
      {
         jsecharptrdatum perl_num[3];
#        if defined(JSE_MBCS) && (0!=JSE_MBCS)
            assert( sizeof_jsechar('$') == sizeof(jsecharptrdatum) );
            assert( bytestrlen_jsechar("123456789") == 9 );
            assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
#        endif
         perl_num[0] = '$';
         perl_num[1] = (jsecharptrdatum)('0' + i);
         perl_num[2] = '\0';
         if ( matches[i].rm_so == -1 )
         {
            jseChild = jseMemberEx(jsecontext,gl_obj,perl_num,jseTypeUndefined,jseCreateVar);
            jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
         }
         else
         {
            jseChild = jseMemberEx(jsecontext,gl_obj,perl_num,jseTypeString,jseCreateVar);
            jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
            jsePutStringLength(jsecontext,jseChild,
                               JSECHARPTR_OFFSET(input,lastIndex+matches[i].rm_so),
                               (JSE_POINTER_UINDEX)(matches[i].rm_eo-matches[i].rm_so));
            jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
         }
         jseDestroyVariable(jsecontext,jseChild);
      }

      /* lastParen is the last sub-expression matched */
      if ( 0 < nmatch )
      {
         i = nmatch-1;
         if ( matches[i].rm_so == -1 )
         {
            jseChild = jseMemberEx(jsecontext,gl_obj,lastParen_MEMBER,jseTypeUndefined,jseCreateVar);
            jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
         }
         else
         {
            jseChild = jseMemberEx(jsecontext,gl_obj,lastParen_MEMBER,jseTypeString,jseCreateVar);
            jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
            jsePutStringLength(jsecontext,jseChild,
                               JSECHARPTR_OFFSET(input,lastIndex+matches[i].rm_so),
                               (JSE_POINTER_UINDEX)(matches[i].rm_eo-matches[i].rm_so));
            jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
         }
         jseDestroyVariable(jsecontext,jseChild);
      }


      jseChild = jseMemberEx(jsecontext,gl_obj,lastMatch_MEMBER,jseTypeString,jseCreateVar);
      jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
      jsePutStringLength(jsecontext,jseChild,JSECHARPTR_OFFSET(input,lastIndex+matches[0].rm_so),
                                             (JSE_POINTER_UINDEX)(matches[0].rm_eo-matches[0].rm_so));
      jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
      jseDestroyVariable(jsecontext,jseChild);

      jseChild = jseMemberEx(jsecontext,gl_obj,leftContext_MEMBER,jseTypeString,jseCreateVar);
      jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
      jsePutStringLength(jsecontext,jseChild,input,(JSE_POINTER_UINDEX)(matches[0].rm_so + lastIndex));
      jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
      jseDestroyVariable(jsecontext,jseChild);

      jseChild = jseMemberEx(jsecontext,gl_obj,rightContext_MEMBER,jseTypeString,jseCreateVar);
      jseSetAttributes(jsecontext,jseChild,jseDefaultAttr);
      jsePutStringLength(jsecontext,jseChild,JSECHARPTR_OFFSET(input,lastIndex + matches[0].rm_eo),
                         (JSE_POINTER_UINDEX)(inputLength - matches[0].rm_eo - lastIndex));
      jseSetAttributes(jsecontext,jseChild,jseReadOnly|jseDontDelete);
      jseDestroyVariable(jsecontext,jseChild);

      jseDestroyVariable(jsecontext,gl_obj);

      jseReturnVar(jsecontext,jseResults,jseRetTempVar);
   }
   jseMustFree(matches);
}

static jseLibFunc(RegExp_exec)
{
   RegExp_ExecOrCallOrTest(jsecontext,jseGetCurrentThisVariable(jsecontext),False);
}

static jseLibFunc(RegExp_callexec)
{
   RegExp_ExecOrCallOrTest(jsecontext,jseCurrentFunctionVariable(jsecontext),False);
}

static jseLibFunc(RegExp_test)
{
   /* the behavor of RegExp_test is same as RegExp_exec except that
    * regexp.test() returns true (instead of the matched string)
    * if there is a match, and false otherwise.
    * if regexp.test() finds a match, various static properties
    * should be updated, just like in regexp.exec()
    */
   RegExp_ExecOrCallOrTest(jsecontext,jseGetCurrentThisVariable(jsecontext),True);
}

static struct jseFunctionDescription RegExpFunctionTable[] = {

  JSE_LIBOBJECT( REGEXP_PROPERTY, RegExp_call,   0,  2,  jseDontEnum, jseFunc_Secure ),

  JSE_VARSTRING( PROTOCLASS_PROPERTIES,  REGEXP_PROPERTY,  jseDontEnum),

  JSE_PROTOMETH( compile_MEMBER,    RegExp_compile,  0, 2, jseDontEnum, jseFunc_Secure ),
  JSE_PROTOMETH( exec_MEMBER,       RegExp_exec,     0, 1, jseDontEnum, jseFunc_Secure ),
  JSE_PROTOMETH( test_MEMBER,       RegExp_test,     0, 1, jseDontEnum, jseFunc_Secure ),
  JSE_PROTOMETH( TOSTRING_PROPERTY, RegExp_toString, 0, 0, jseDontEnum, jseFunc_Secure ),

  JSE_FUNC_END
};

static jseLibInitFunc(RegExpInitFunction)
{
   jseVariable rvar;
   /* alias some perl versions */
   rvar = jseGetMemberEx(jsecontext,NULL,REGEXP_PROPERTY,jseCreateVar);
   assert( NULL != rvar );
   jseSetObjectCallbacks(jsecontext,rvar,&regexpCallbacks);
   jseDestroyVariable(jsecontext,rvar);

   return rvar;
}

void NEAR_CALL
InitializeLibrary_Ecma_RegExp(jseContext jsecontext)
{
   jseAddLibrary(jsecontext,NULL,RegExpFunctionTable,NULL,RegExpInitFunction,NULL);
}

#endif /* JSE_REGEXP_ANY */
