/* varutil.c  Access to variables of all kinds.
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

static void NEAR_CALL sevarConvertToPrimitive(struct Call *call,wSEVar to_convert,jseVarType hint);
static void NEAR_CALL sevarDefaultValue(struct Call *call,wSEVar ret,jseVarType hintType);

/* ---------------------------------------------------------------------- */

/* utility type functions */

   void
ConcatenateStrings(struct Call *call,wSEVar dest,rSEVar s1,rSEVar s2)
{
   JSE_POINTER_UINDEX len1,len2;
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
   JSE_POINTER_UINDEX bytelen1,bytelen2;
#  endif
   jsecharptr ConcatMem;
   struct seString *buf;
   JSE_MEMEXT_R void *mem1,*mem2;

   assert( sevarIsValid(call,s1) );
   assert( sevarIsValid(call,s2) );

   /* These asserts true because this routine is only used to concatenate
    * whole strings during compilation
    */
   assert( SEVAR_GET_TYPE(s1)==VString && s1->data.string_val.loffset==0 &&
           s1->data.string_val.data->zoffset==0 );
   assert( SEVAR_GET_TYPE(s2)==VString && s2->data.string_val.loffset==0 &&
           s2->data.string_val.data->zoffset==0 );

   mem1 = SESTRING_GET_DATA(s1->data.string_val.data);
   mem2 = SESTRING_GET_DATA(s2->data.string_val.data);

   len1 = s1->data.string_val.data->length;
   len2 = s2->data.string_val.data->length;
   ConcatMem = (jsecharptr )jseMustMalloc(jsechar,(sizeof(jsechar)*(len1+len2+1)));
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      bytelen1 = s1->data.string_val.data->bytelength;
      bytelen2 = s2->data.string_val.data->bytelength;
      memcpy(ConcatMem,mem1,bytelen1);
      memcpy(((ubyte *)ConcatMem)+bytelen1,mem2,bytelen2);
      ((ubyte *)ConcatMem)[bytelen1+bytelen2] = '\0';
      buf = sestrCreateAllocated(call,ConcatMem,len1+len2,bytelen1+bytelen2,False);
#  else
      STRCPYLEN_JSECHAR(ConcatMem,mem1,len1);
      STRCPYLEN_JSECHAR(JSECHARPTR_OFFSET(ConcatMem,len1),mem2,len2);
      ConcatMem[len1+len2] = '\0';
      buf = sestrCreateAllocated(call,ConcatMem,len1+len2,False);
#  endif

   SESTRING_UNGET_DATA(s1->data.string_val.data,mem1);
   SESTRING_UNGET_DATA(s2->data.string_val.data,mem2);

   SEVAR_INIT_STRING_AS(dest,buf);
}


/* ----------------------------------------------------------------------
 * These routines are used to find the name of a variable to print out
 * in error messages.  This function need not be fast.
 * ---------------------------------------------------------------------- */

   static void NEAR_CALL
ConcatVarPropertyName(struct Call *call,jsecharptr const Buffer,uint BufferLength,
                      VarName vn,jsebool prependDot)
{
   JSECHARPTR_PUTC(Buffer,'\0');

   if ( NULL != vn )
   {
      const jsecharptr name = GetStringTableEntry(call,vn,NULL);
      assert( NULL != name );

      /* for strcats to work must start with null-length string */
      JSECHARPTR_PUTC(Buffer,'\0');
      if ( (uint)(strlen_jsechar(name)+3) < BufferLength )
      {
         jsebool numeric = (jsebool)IsNumericStringTableEntry(vn);
         if ( prependDot )
         {
            strcat_jsechar( Buffer, numeric ? UNISTR("[") : UNISTR(".") );
         }
         strcat_jsechar( Buffer, name );
         if ( prependDot && numeric )
         {
            strcat_jsechar( Buffer, UNISTR("]") );
         }
      }
   }
}

#if defined(SEOBJ_FLAG_BIT)
   static jsebool NEAR_CALL
IsThisTheVariable(struct Call *call,rSEVar me,
                  rSEVar TheVariable,VarName vn,
                  jsecharptr const Buffer,uint BufferLength,
                  jsebool prependDot)
{
   /* check object existance -- brianc 8/16/00 */
   if (SEVAR_GET_TYPE(me) == VObject && SEVAR_GET_OBJECT(me) == NULL)
       return FALSE;

   assert( sevarIsValid(call,me) );
   assert( sevarIsValid(call,TheVariable) );

   if( me==TheVariable ||
       (SEVAR_GET_TYPE(me)==VObject && SEVAR_GET_TYPE(TheVariable)==VObject &&
        SEVAR_GET_OBJECT(me)==SEVAR_GET_OBJECT(TheVariable)) )
   {
      ConcatVarPropertyName(call,Buffer,BufferLength,vn,prependDot);
      return True;
   }

   /* this is a structure, so check each element of structure to see if
    * it is the variable
    */
   if ( VObject == SEVAR_GET_TYPE(me) )
   {
      wSEObject wobj;
      SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(me));
      if ( !SEOBJ_WAS_FLAGGED(wobj) )
      {
         jsecharptr nextBuffer;
         uint nextBufferLen;
         uint i;

         SEOBJ_MARK_FLAGGED(wobj);

         ConcatVarPropertyName(call,Buffer,BufferLength,vn,prependDot);
         for ( nextBuffer = Buffer, nextBufferLen = BufferLength;
               '\0' != JSECHARPTR_GETC(nextBuffer);
               nextBufferLen--, JSECHARPTR_INC(nextBuffer) )
            ;

         for( i=0;i<SEOBJECT_PTR(wobj)->used;i++ )
         {
            rSEObjectMem rMem = rseobjIndexMemberStruct(call,SEOBJECT_CAST_R(wobj),i);
            assert( NULL != SEOBJECTMEM_PTR(rMem) );
            if ( IsThisTheVariable(call,
                                   SEOBJECTMEM_VAR(rMem),
                                   TheVariable,
                                   SEOBJECTMEM_PTR(rMem)->name,
                                   nextBuffer,nextBufferLen,
                                   0 != JSECHARPTR_GETC(Buffer) ) )
            {
               SEOBJECTMEM_UNLOCK_R(rMem);
               SEOBJ_MARK_NOT_FLAGGED(wobj);
               SEOBJECT_UNLOCK_W(wobj);
               return True;
            }
            SEOBJECTMEM_UNLOCK_R(rMem);
         }

         /* restore name to where it ended previously */
         JSECHARPTR_PUTC(Buffer,'\0');

         SEOBJ_MARK_NOT_FLAGGED(wobj);
      }
      SEOBJECT_UNLOCK_W(wobj);
   }
   return False;
}
#else /* #if defined(SEOBJ_FLAG_BIT) */
   static jsebool NEAR_CALL
IsThisTheVariableRecurse(struct Call *call,rSEVar me,
                         rSEVar TheVariable,VarName vn,
                         jsecharptr const Buffer,uint BufferLength,
                         jsebool prependDot,struct VarRecurse *prev)
{
   assert( sevarIsValid(call,me) );
   assert( sevarIsValid(call,TheVariable) );

   if( me==TheVariable
    || ( SEVAR_GET_TYPE(me)==VObject && SEVAR_GET_TYPE(TheVariable)==VObject
      && SEVAR_GET_OBJECT(me)==SEVAR_GET_OBJECT(TheVariable) ) )
   {
      ConcatVarPropertyName(call,Buffer,BufferLength,vn,prependDot);
      return True;
   }

   /* this is a structure, so check each element of structure to see if
    * it is the variable
    */
   if ( VObject == SEVAR_GET_TYPE(me) )
   {
      struct VarRecurse myRecurse;
      CHECK_FOR_RECURSION(prev,myRecurse,SEVAR_GET_OBJECT(me))
      if ( !ALREADY_BEEN_HERE(myRecurse) )
      {
         jsecharptr nextBuffer;
         uint nextBufferLen;
         rSEObject robj;
         JSE_MEMEXT_R struct _SEObjectMem *mem;
         MemCountUInt i, used;

         ConcatVarPropertyName(call,Buffer,BufferLength,vn,prependDot);
         for ( nextBuffer = Buffer, nextBufferLen = BufferLength;
               '\0' != JSECHARPTR_GETC(nextBuffer);
               nextBufferLen--, JSECHARPTR_INC(nextBuffer) )
            ;

         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(me));
         used = SEOBJECT_PTR(robj)->used;
	 if (used == 0)
	 {
	   SEOBJECT_UNLOCK_R(robj);
	 }
	 else
	 {
           rSEMembers rMembers;
	   SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);
	   SEOBJECT_UNLOCK_R(robj);
	   for( i=0, mem=SEMEMBERS_PTR(rMembers); i<used; i++, mem++ )
	   {
            if ( IsThisTheVariableRecurse(call,&(mem->value),TheVariable,mem->name,
                    nextBuffer,nextBufferLen,0 != JSECHARPTR_GETC(Buffer),&myRecurse) )
            {
               SEMEMBERS_UNLOCK_R(rMembers);
               return True;
            }
	   }
           SEMEMBERS_UNLOCK_R(rMembers);
         }

         /* restore name to where it ended previously */
         JSECHARPTR_PUTC(Buffer,'\0');
      }
   }
   return False;
}
#define IsThisTheVariable(call,me,TheVariable,vn,Buffer,BufferLength,prependDot) \
        IsThisTheVariableRecurse((call),(me),(TheVariable),(vn),(Buffer), \
                                 (BufferLength),(prependDot),NULL)
#endif /* #if defined(SEOBJ_FLAG_BIT) */


/* NYI: This fails in certain cases to find a variable name. For instance,
 * 'var a = 10; a();'
 *
 * The reason is that a is thrown on the stack and it is now the constant
 * 10. This is indistinguishable from any other value '10', it does not
 * know where it came from. We could try to look for names by value, but
 * then we would be getting the wrong names if another variable has the
 * same value. Still, I've left this NYI: in if I should come up with a
 * good solution.
 *
 * The only way to guarantee naming of variables is to actually put
 * the needed information in the structure. This would slow us down and
 * increase memory usage. It just doesn't make sense to do so. I'm
 * considering, though, a JSE_ALWAYS_NAME_VARIABLES define to do this
 * sort of thing defaulting to 'OFF'.
 */
   jsebool
FindNames(struct Call *call,rSEVar me,jsecharptr const Buffer,uint BufferLength,
          VarName default_name)
{
   jsebool FoundName = False;
   wSEVar tmp = STACK_PUSH;

   assert( sevarIsValid(call,me) );

   /* We look for a variable's name in two places, either as
    * a global variable, a local variable/param name.
    * All other variable names are derived from it, as all variables
    * can trace their ancestry back to them. In the case in which
    * a variable is created on the fly, that is no problem since
    * we wouldn't have a name for it anyway. For instance,
    *
    * with( new Object() ) a();
    *
    * The new object doesn't have a name anyway. If not found, we
    * use the name in the reference, so it would be just 'a'.
    */


   /* look in locals */

   if( call->hVariableObject==hSEObjectNull ) callCreateVariableObject(call,NULL);
   if( call->hVariableObject )
   {
      SEVAR_INIT_OBJECT(tmp,call->hVariableObject);
      if( IsThisTheVariable(call,tmp,me,NULL,Buffer,BufferLength,False) )
         FoundName = True;
   }

   /* look in the global variables */

   if( !FoundName )
   {
      SEVAR_INIT_OBJECT(tmp,CALL_GLOBAL(call));
      if( IsThisTheVariable(call,tmp,me,NULL,Buffer,BufferLength,False) )
         FoundName = True;
   }

   /* if it is a reference, see if we can find the object that is
    * its base, and return it + ".member", else just return "member"
    */
   if( !FoundName )
   {
      if( SEVAR_GET_TYPE(me)==VReference )
      {
         SEVAR_INIT_OBJECT(tmp,me->data.ref_val.hBase);
         FoundName = FindNames(call,tmp,Buffer,BufferLength,UNISTR(""));
         ConcatVarPropertyName(call,Buffer,BufferLength,me->data.ref_val.reference,FoundName);
      }
      FoundName = True;
   }


   /* else can't find it at all, return default name */
   if( !FoundName && default_name!=NULL )
   {
      ConcatVarPropertyName(call,Buffer,BufferLength,default_name,False);
      FoundName = True;
   }

   STACK_POP;

   return FoundName;
}


#if (0!=JSE_COMPILER)
   static jsebool NEAR_CALL
CreateFromNumberText(struct Call *call,jsecharptr Source,jsecharptr *End,wSEVar var)
{
   jsenumber val;

   UNUSED_PARAMETER(call);

   assert( NULL != End  &&  NULL != Source );

   /* convert to float and to long and use the one that uses the
    * most characters.  If they both use the same number of
    * characters then floating-point wins (to handle very very
    * long values) except if the first character is 0 (to
    * handle octal orhex conversion, in which case integer
    * wins)
    */
   val = MY_strtol(Source,End,0);
#  if (0!=JSE_FLOATING_POINT)
   {
      jsecharptr fEnd;
      jsenumber fVal = JSE_FP_STRTOD(Source,(jsecharptrdatum **)&fEnd);
      if ( *End <= fEnd )
      {
         if ( *End == fEnd )
         {
            /* resolve dispute over long or float, who has better value */
            SKIP_WHITESPACE(Source);
            assert( sizeof_jsechar('+') == sizeof(jsecharptrdatum) );
            assert( sizeof_jsechar('-') == sizeof(jsecharptrdatum) );
            if ( '+' == *(jsecharptrdatum *)Source  ||  '-' == *(jsecharptrdatum *)Source )
               Source = ((jsecharptrdatum *)Source) + 1;
            assert( sizeof_jsechar('0') == sizeof(jsecharptrdatum) );
            if ( '0' == *(jsecharptrdatum *)Source )
               goto ConversionFinished;
         }
         *End = fEnd;
         val = fVal;
      }
   }
   ConversionFinished:
#  endif
   if ( Source < *End )
   {
      SEVAR_INIT_NUMBER(var,val);
      return True;
   }
   else
   {
      return False;
   }
}
#endif


/* ---------------------------------------------------------------------- */

#if (0!=JSE_COMPILER)
   static jsebool NEAR_CALL
CreateFromString(struct Call *call,jsecharptr Source,jsecharptr *iEnd,wSEVar var)
{
   jsecharptrdatum QuoteChar;
   jsecharptr escSeq;
   jsecharptr end;
   JSE_POINTER_UINDEX len;

   /* make sure MBCS assumptions about special characters are valid */
   assert( NULL != iEnd  &&  NULL != Source );
   assert( sizeof_jsechar(JSECHARPTR_GETC(Source)) == sizeof(jsecharptrdatum) );
   QuoteChar = *(jsecharptrdatum *)Source;
   assert( ('\"' == QuoteChar) || ('\'' == QuoteChar) || ('`' == QuoteChar) );
   assert( sizeof_jsechar(QuoteChar) == sizeof(jsecharptrdatum) );
   assert( sizeof_jsechar('\\') == sizeof(jsecharptrdatum) );
   assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );

   /* in the fastest situation this is a plain string, ends in quotechar, and has
    * no escape sequences in the middle.  Let's hope for that case.
    */
   Source = ((jsecharptrdatum *)Source) + 1;
   end = strchr_jsechar(Source,QuoteChar);
   if ( NULL == end )
   {
      goto NoTerminatingQuote;
   }
   /* if no escape sequence then fall into fastest code */
   if ( '`' == QuoteChar
     || NULL == (escSeq=strchr_jsechar(Source,'\\'))
     || end < escSeq )
   {
      /* fast and easy; no allocation; create buffer and go */
      assert( end >= Source );
      len = (JSE_POINTER_UINDEX)JSECHARPTR_DIFF(end,Source);
#     if defined(JSE_MBCS) && (JSE_MBCS!=0)
         SEVAR_INIT_STRING(call,var,Source,len,(char *)end-(char *)Source);
#     else
         SEVAR_INIT_STRING(call,var,Source,len);
#     endif
   }
   else
   {
      /* there is at least one escape sequence; so processing must take place.
       * this will realloc the size of this string (since result of processing
       * escape sequences always shrinks and never grows) and process those
       * characters in-place
       */
      jsecharptr str = jseMustMalloc(jsecharptrdatum,bytestrlen_jsechar(Source));
      jsecharptr cptr;

      for ( len = 0, cptr = str, end = Source;
            QuoteChar != *(jsecharptrdatum *)end;
            JSECHARPTR_INC(end), JSECHARPTR_INC(cptr), len++ )
      {
         jsechar c;

         assert( sizeof(jsecharptrdatum) == sizeof_jsechar('\0') );
         if ( '\0' == *(jsecharptrdatum *)end )
         {
            jseMustFree(str);
            goto NoTerminatingQuote;
         }
         /* code to handle the unicode constants */
         assert( sizeof(jsecharptrdatum) == sizeof_jsechar('\\') );
         if ( '\\' == *(jsecharptrdatum *)end )
         {
            uint used;
            end = ((jsecharptrdatum *)end) + 1;
            c = JSECHARPTR_GETC(end);

            switch ( c )
            {
               case UNICHR('a'): c = UNICHR('\a'); break;
               case UNICHR('b'): c = UNICHR('\b'); break;
               case UNICHR('f'): c = UNICHR('\f'); break;
               case UNICHR('n'): c = UNICHR('\n'); break;
               case UNICHR('r'): c = UNICHR('\r'); break;
               case UNICHR('t'): c = UNICHR('\t'); break;
               case UNICHR('v'): c = UNICHR('\v'); break;
               case UNICHR('u'): case UNICHR('U'):
                  JSECHARPTR_INC(end);
                  c = (jsechar)BaseToULong(end,16,4,MAX_UWORD16,&used);
                  end = JSECHARPTR_OFFSET(end,used - 1);
                  break;
               case UNICHR('x'): case UNICHR('X'):
                  JSECHARPTR_INC(end);
                  c = (jsechar)BaseToULong(end,16,2,MAX_UWORD8,&used);
                  end = JSECHARPTR_OFFSET(end,used - 1);
                  break;
               case UNICHR('0'):case UNICHR('1'):case UNICHR('2'):case UNICHR('3'):
               case UNICHR('4'):case UNICHR('5'):case UNICHR('6'):case UNICHR('7'):
                  c = (jsechar)BaseToULong(end,8,3,MAX_UWORD8,&used);
                  end = JSECHARPTR_OFFSET(end,used - 1);
                  break;
               default:
                  /* all other characters stay just as they are */
                  break;
            }
         }
         else
         {
            c = JSECHARPTR_GETC(end);
         }
         JSECHARPTR_PUTC(cptr,c);
      }

#     if defined(JSE_MBCS) && (JSE_MBCS!=0)
         SEVAR_INIT_STRING(call,var,str,(JSE_POINTER_UINDEX)len,(char *)cptr-(char *)str);
#     else
         SEVAR_INIT_STRING(call,var,str,(JSE_POINTER_UINDEX)len);
#     endif
      jseMustFree(str);
      /* readjust end to point to end of original string */
   }
   assert( *(jsecharptrdatum *)end == QuoteChar );
   assert( sizeof(jsecharptrdatum) == sizeof_jsechar(QuoteChar) );
   *iEnd = (jsecharptr)(((jsecharptrdatum *)end) + 1);
   SEVAR_CONSTANT_STRING(var);
   return True;

NoTerminatingQuote:
   callError(call,textcoreCANNOT_PROCESS_BETWEEN_QUOTES,QuoteChar);
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      SEVAR_INIT_STRING(call,var,"",0,0);
#  else
      SEVAR_INIT_STRING(call,var,"",0);
#  endif
   return True;
}
#endif


#if (0!=JSE_COMPILER)
   jsebool NEAR_CALL
sevarAssignFromText(wSEVar target,struct Call *call,jsecharptr Source,
                    jsebool *AssignSuccess,
                    jsebool MustUseFullSourceString,jsecharptr *End)
{
   jsecharptr EndOfProcessing;
   jsebool success = True;
#if !defined(__JSE_GEOS__)
   jsebool (NEAR_CALL *WhichCreate)
      (struct Call *call,jsecharptr Source,jsecharptr *End,wSEVar loc);
#else
   jsebool result;
#endif

   assert( sevarIsValid(call,target) );

   assert(NULL != Source);
   *AssignSuccess = False;

   SKIP_WHITESPACE(Source);
#if defined(__JSE_GEOS__)
   if ( NULL != strchr_jsechar(UNISTR("\"\'`"),JSECHARPTR_GETC(Source)) ) {
      result = CreateFromString(call,Source,&EndOfProcessing,target);
   } else {
      assert( '{' != JSECHARPTR_GETC(Source) );
      result = CreateFromNumberText(call,Source,&EndOfProcessing,target);
   } /* endif */

   if ( !result )
#else
   if ( NULL != strchr_jsechar(UNISTR("\"\'`"),JSECHARPTR_GETC(Source)) ) 
   {
      /* convert to string(" or `) or character or character array(') */
      WhichCreate = CreateFromString;
   } else {
      assert( '{' != JSECHARPTR_GETC(Source) );
      WhichCreate = CreateFromNumberText;
   }

   if ( !(*WhichCreate)(call,Source,&EndOfProcessing,target) )
#endif  
   {
      success = False;
   } else {
      /* was able to create, so assign to the return variable */
      if ( !MustUseFullSourceString  ||  0 == JSECHARPTR_GETC(EndOfProcessing) )
      {
         *AssignSuccess = True;
         if ( NULL != End )
         {
            *End = EndOfProcessing;
         }
      }
   }

   assert( sevarIsValid(call,target) );

   return success;
}
#endif

/* ---------------------------------------------------------------------- */

/* Convert the given variable in place
 */
   void NEAR_CALL
AutoConvert(struct Call *call,wSEVar me,jseVarNeeded need)
{
   assert( sevarIsValid(call,me) );

   if( need & (JSE_VN_NUMBER | JSE_VN_BYTE | JSE_VN_INT) )
   {
      /* convert to some numeric type */
      sevarConvert(call,me,jseToNumber);
      if ( 0 == (need & JSE_VN_NUMBER) )
      {
         /* convert to a smaller number */
         ulong Mask = (ulong) (( 0 != (need & JSE_VN_INT) ) ? 0xffff : 0xff);
         slong value = SEVAR_GET_SLONG(me);
         SEVAR_PUT_SLONG(me,value & Mask);
      }
   }
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   else if ( need & (JSE_VN_STRING | JSE_VN_BOOLEAN | JSE_VN_BUFFER |
                     JSE_VN_OBJECT | JSE_VN_FUNCTION) )
#  else
   else if ( need & (JSE_VN_STRING | JSE_VN_BOOLEAN | JSE_VN_OBJECT |
                     JSE_VN_FUNCTION) )
#  endif
   {
      /* convert to variable of defined type */
      jseConversionTarget ConvertToType;
      if ( need & (JSE_VN_STRING | JSE_VN_BOOLEAN) )
      {
         ConvertToType = (need & JSE_VN_STRING) ? jseToString : jseToBoolean ;
      }
      else
      {
#        if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
            assert( need & (JSE_VN_BUFFER | JSE_VN_OBJECT | JSE_VN_FUNCTION) );
#        else
            assert( need & (JSE_VN_OBJECT | JSE_VN_FUNCTION) );
#        endif
         ConvertToType =
#           if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
               (need & JSE_VN_BUFFER) ? jseToBuffer :
#           endif
            jseToObject ;
      }
      sevarConvert(call,me,ConvertToType);
   }
   else
   {
      /* directly specifying to convert to NULL or UNDEFINED */
      assert( need & (JSE_VN_NULL | JSE_VN_UNDEFINED) );
      if( need & JSE_VN_NULL )
         SEVAR_INIT_NULL(me);
      else
         SEVAR_INIT_UNDEFINED(me);
   }

   assert( sevarIsValid(call,me) );
}


#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   void
TokenWriteVar(struct Call *call,struct TokenSrc *tSrc,rSEVar me)
{
   jseVarType vType = SEVAR_GET_TYPE(me);


   assert( sevarIsValid(call,me) );

   tokenWriteByte(tSrc,(ubyte)vType);

   switch ( vType )
   {
      case VNumber:
         tokenWriteNumber(tSrc,SEVAR_GET_NUMBER(me));
         break;
      case VBoolean:
         tokenWriteLong(tSrc,SEVAR_GET_BOOLEAN(me));
         break;
      case VString:
      {
         jsecharptr str = (jsecharptr)sevarGetData(call,me);
         stringLengthType length = (stringLengthType)SEVAR_STRING_LEN(me);
         uword8 tmp;

         VarName n = GrabStringTableEntry(call,str,length,&tmp);
         tokenWriteString(call,tSrc,n);
         ReleaseStringTableEntry(/*call,*/n,tmp);

         SEVAR_FREE_DATA(call,str);

         break;
      }

#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER) && !defined(NDEBUG)
      case VBuffer:
         /* there shouldn't be constant buffers, no way to specify them */
         assert( False );
#     endif

      case VObject:
      {
         rSEObject robj;
         SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(me));
#        if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
         /* must be either function literal or regexp literal */
         if( SEOBJECT_PTR(robj)->func!=NULL )
         {
#        else
            assert( SEOBJECT_PTR(robj)->func!=NULL );
#        endif
            tokenWriteByte(tSrc,(uword8)NEW_FUNCTION);
            localTokenWrite(((struct LocalFunction *)(SEOBJECT_PTR(robj)->func)),call,tSrc);
#        if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
         }
         else
         {
            wSEVar strver;
            jsecharptr str;
            stringLengthType length;
            uword8 tmp;
            VarName n;

            /* A regular expression literal */
            tokenWriteByte(tSrc,(uword8)REGEXP_LITERAL);

            /* Convert to a string and write it out */
            strver = STACK_PUSH;
            SEVAR_COPY(strver,me);
            sevarConvertToString(call,strver);
            assert( SEVAR_GET_TYPE(strver)==VString );
            assert( !CALL_QUIT(call) );

            str = (jsecharptr)sevarGetData(call,strver);
            length = (stringLengthType)SEVAR_STRING_LEN(strver);

            n = GrabStringTableEntry(call,str,length,&tmp);
            tokenWriteString(call,tSrc,n);
            ReleaseStringTableEntry(/*call,*/n,tmp);
            SEVAR_FREE_DATA(call,str);

            /* get rid of temp stack space */
            STACK_POP;
         }
#        endif /* #if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) */
         SEOBJECT_UNLOCK_R(robj);
      }  break;

      /* it's enough just to have written the type for any other data type */
   }
}
#endif

#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
   void
TokenReadVar(struct Call *call,struct TokenDst *tDst,wSEVar var)
{
   jseVarType vType = (jseVarType)tokenReadCode(tDst);

   switch ( vType )
   {
      case VNumber:
         SEVAR_INIT_NUMBER(var,tokenReadNumber(tDst));
         break;
      case VBoolean:
         SEVAR_INIT_BOOLEAN(var,tokenReadLong(tDst)==0?False:True);
         break;
      case VString:
      {
         VarName n;
         stringLengthType len;
         const jsecharptr str;

         n = tokenReadString(call,tDst);
         str = GetStringTableEntry(call,n,&len);
         SEVAR_INIT_STRING_STRLEN(call,var,(jsecharptr)str,len);
         SESTR_MAKE_CONSTANT(SEVAR_GET_STRING(var).data);
         break;
      }

#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER) && !defined(NDEBUG)
      case VBuffer:
         /* there shouldn't be constant buffers, no way to specify them */
         assert( False );
#     endif

      case VObject:
      {
         uword8 type = tokenReadByte(tDst);
#        if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
         if( type == (uword8)NEW_FUNCTION )
#        endif
         {
            assert( type == (uword8)NEW_FUNCTION );
            SEVAR_INIT_BLANK_OBJECT(call,var);
            /* a function variable */
            localTokenRead(call,tDst,var);
         }
#        if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
         else
         {
            VarName n;
            stringLengthType len;
            const jsecharptr str;
            jsebool success;

            /* Must be a regular expression literal */
            assert( type==(uword8)REGEXP_LITERAL );
            n = tokenReadString(call,tDst);
            str = GetStringTableEntry(call,n,&len);

            CompileRegExpLiteral(call,(jsecharptr)str,&success,var);

            /* we read in the literal we wrote out, which should
             * be good. Only a program bug can make it not good.
             */
            assert( success );

            break;
         }
#        endif /* if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) */
      }
      default:
         /* any other types do nothing special */
         var->type = vType;
         break;
   }

   assert( sevarIsValid(call,var) );
}
#endif


/* ---------------------------------------------------------------------- */
/* ECMA comparison operators, part 1 - relational comparisons             */
/* ---------------------------------------------------------------------- */

/* For the relational operators, everything is described in terms of
 * 'less-than'. This routine does the comparison. It returns '1' (true)
 * '0' (false) or -1 (undefined). See 11.8.5. This routine knows nothing
 * about our special buffer type or about strings in cfunctions. Buffers are
 * treated just like strings.
 */
#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
 static
#endif
   sint NEAR_CALL
sevarECMACompareLess(struct Call *call,wSEVar vx,wSEVar vy)
{
   sint result; /* all paths must set this to some value */
   jsenumber x,y;
   int num = 0;
   wSEVar tmp;

   assert( sevarIsValid(call,vx) );
   assert( sevarIsValid(call,vy) );

   /* steps 1 and 2 - to save time, we only convert to primitive if it is
    * already not a primitive.
    */
   if( SEVAR_GET_TYPE(vx)==VObject )
   {
      num++;
      tmp = STACK_PUSH;
      SEVAR_COPY(tmp,vx);
      sevarConvert(call,tmp,jseToPrimitive);
      vx = tmp;
      assert( SEVAR_GET_TYPE(vx)!=VObject );
   }
   if( SEVAR_GET_TYPE(vy)==VObject )
   {
      num++;
      tmp = STACK_PUSH;
      SEVAR_COPY(tmp,vy);
      sevarConvert(call,tmp,jseToPrimitive);
      vy = tmp;
      assert( SEVAR_GET_TYPE(vy)!=VObject );
   }


   /* at this point, we may have some stuff on the stack - no
    * 'return'ing from the middle of this function!
    */

   if ( SEVAR_GET_TYPE(vx)==SEVAR_GET_TYPE(vy) &&
        SEVAR_ARRAY_PTR(vx) )
   {
      /* Both are strings or both are buffers */
      const jsecharhugeptr str1 = sevarGetData(call,vx);
      const jsecharhugeptr str2 = sevarGetData(call,vy);
      JSE_POINTER_UINDEX lx = SEVAR_STRING_LEN(vx);
      JSE_POINTER_UINDEX ly = SEVAR_STRING_LEN(vy);

#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      if ( VBuffer == SEVAR_GET_TYPE(vx) )
      {
         /* compare two buffers */
         JSE_POINTER_UINDEX lmin = min(lx,ly);
         result = HugeMemCmp(str1,str2,lmin);
         if ( 0 == result )
            result = ( lx < ly ) ? 1 : 0 ;
      }
      else
#     endif
      {
         /* compare two strings */
         result = jsecharCompare(str1,lx,str2,ly);
      }
      result = ( result < 0 ) ? 1 : 0 ;

      SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)str1);
      SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)str2);
   }
   else
   {
      /* step 4, they are not both strings or both buffers */

      /* neither are objects, so only strings and buffers need be translated.
       * The reason is that varGetNumber() knows how to extract the correct value
       * from all the other types without going through the hassle of
       * explictly translating them. It helps speed.
       */
      x = sevarConvertToNumber(call,vx);
      y = sevarConvertToNumber(call,vy);

      /* step 6 */

      if( jseIsNaN(x) || jseIsNaN(y) )
      {
         if( jseOptWarnBadMath & call->Global->ExternalLinkParms.options )
         {
            callError(call,textcoreIS_NAN);
         }
         result = -1;
      }
      else
      {
         /* step 8 */
         if( JSE_FP_EQ(x,y) )
         {
            result = 0;
         }
         else
         {
            /* step 11 */
            if( jseIsInfinity(x) )
               result = 0;
            /* step 12 */
            else if( jseIsInfinity(y) )
               result = 1;
            /* step 13 */
            else if( jseIsNegInfinity(y) )
               result = 0;
            /* step 14 */
            else if( jseIsNegInfinity(x) )
               result = 1;

            /* step 15 */
            else if( JSE_FP_LT(x,y) )
               result = 1;
            else
               result = 0;
         }
      }
   }

   STACK_POPX(num);

   assert( result == 0   ||  result == 1  ||  result == -1 );
   return result;
}


/* This routine understands the special cases that require us to compare
 * unusually. If it is not one of those cases, we use the ECMA comparison.
 * We return 1,-0, or -1 exactly like the ECMA compare routine.
 */
#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   sint NEAR_CALL
SEVAR_COMPARE_LESS(struct Call *call,wSEVar vx,wSEVar vy)
{
   sint result;

   assert( sevarIsValid(call,vx) );
   assert( sevarIsValid(call,vy) );

   /* Special case: both numbers. This is most common, so make it
    * as efficient as possible
    */
   if( SEVAR_GET_TYPE(vx)==VNumber && SEVAR_GET_TYPE(vy)==VNumber )
   {
      jsenumber nx = SEVAR_GET_NUMBER(vx);
      jsenumber ny = vy->data.num_val;

      /* Unfortunately, Watcom (and others?) doesn't handle
       * infinity correctly, so this check is necessary
       */
      if( jseIsFinite(nx) && jseIsFinite(ny) )
         return JSE_FP_LT(nx,ny) ? 1 : 0;
   }

   /* do C-like pointer behavor if this is a C-function and both are
    * strings or both are buffers.  Also, if one of the two types
    * is a literal then default to standard ecma behavior
    */
   if( !CALL_CBEHAVIOR
    || SEVAR_GET_TYPE(vx)!=SEVAR_GET_TYPE(vy)
    || !SEVAR_ARRAY_PTR(vx) )
   {
      result = sevarECMACompareLess(call,vx,vy);
   }
   else if( SEVAR_GET_STRING(vx).data!=SEVAR_GET_STRING(vy).data )
   {
      /* C-like comparison of strings or buffers */
      result = -1; /* cannot compare from different addresses */
   }
   else
   {
      result = (SEVAR_GET_STRING(vx).loffset<SEVAR_GET_STRING(vy).loffset) ? 1 : 0 ;
   }
   assert( result == 0   ||  result == 1  ||  result == -1 );
   return result;
}
#endif  /* defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS) */


/* Unfortunately, our previous comparison routine did not match well to
 * Javascript. Javascript expects to know what you are looking for. One
 * can use one 'less' comparison to do any relational comparison but you
 * have to know which comparison (less than, greater than, etc) you want in
 * advance to determine if you need to swap the operands. We cannot do that,
 * hence we need to do the comparison twice. Yuck.
 */
   jsebool NEAR_CALL
sevarCompare(struct Call *call,wSEVar vx,wSEVar vy,slong *CompareResult)
{
   /* Unfortunately, ECMA only compares based on less-than. To simulate gathering
    * all three possibilities, we must call this routine twice. This routine
    * will mimic the translation done by the less-than so that the values are
    * not translated more than once.
    *
    * Less than can give you any information you need (by swapping the order
    * of the comparison if necessary) but you need to know which information
    * you are searching for.
    */

   int less_than,greater_than;


   assert( sevarIsValid(call,vx) );
   assert( sevarIsValid(call,vy) );

   /* Do the conversion of the operands before calling these so not
    * done twice.
    */
   /* This doesn't really matter.  The only place that this function is called
    * is in jseCompare, and only when using the old-style comparison.  The
    * overhead of converting the variables twice doesn't matter, since this
    * function is virtually unused.
    */
   less_than = SEVAR_COMPARE_LESS(call,vx,vy);
   greater_than = SEVAR_COMPARE_LESS(call,vy,vx);

   if( less_than==-1 || greater_than==-1 )
   {
      /* if one of the operands is NaN, it should show up both ways */
      assert( less_than==-1 && greater_than==-1 );
      *CompareResult = 0;
      /* it means that any test ought to fail. We can't give a relationship
       * between them, ALL relationships are untrue (i.e. it is not less than,
       * not greater than, not less than or equal, etc.) So, the comparison
       * 'fails'.
       */
      return False;
   }

   /* it can't be both, but it can be neither */
   assert( less_than==0 || greater_than==0 );
   if( less_than==1 )
      *CompareResult = -1;
   else if( greater_than==1 )
      *CompareResult = 1;
   else
      *CompareResult = 0;
   return True;
}


/* ---------------------------------------------------------------------- */
/* ECMA comparison operators, part 2 - equality comparisons               */
/* ---------------------------------------------------------------------- */


/* This routine implements ECMAscript spec 11.9.3 determining equality.
 * Like its relational counterpart, it knows nothing about our special
 * c-function string rules and treats buffers identically to strings.
 *
 * Also compares two variables according to ECMA strict comparison rules.  This is
 * equivalent to the === operator in scripts.
 */
   jsebool NEAR_CALL
sevarECMACompareEquality(struct Call *call,rSEVar vx,rSEVar vy,jsebool strictEquality)
{
   /* don't initialize it as all paths ought to set it */
   jsebool result;
   jseVarType tx = SEVAR_GET_TYPE(vx);
   jseVarType ty = SEVAR_GET_TYPE(vy);

   assert( sevarIsValid(call,vx) );
   assert( sevarIsValid(call,vy) );

   if( tx==ty
   || ( !strictEquality
     && ( (tx==VBoolean && ty==VNumber) || (tx==VNumber && ty==VBoolean) ) ) )
   {
      /* step 2 */

      if( tx==VUndefined || tx==VNull )
      {
         result = True;
      }
      else
      {
         /* step 12 as well */
         if( tx==VNumber || tx==VBoolean )
         {
            /* step 5 */
            jsenumber x = (tx==VNumber) ? SEVAR_GET_NUMBER(vx) : (SEVAR_GET_BOOLEAN(vx)?jseOne:jseZero);
            jsenumber y = (ty==VNumber) ? SEVAR_GET_NUMBER(vy) : (SEVAR_GET_BOOLEAN(vy)?jseOne:jseZero);
            if( jseIsNaN(x) || jseIsNaN(y) )
            {
               /* any comparison to NaN fails, even comparing it to itself! */
               result = False;
            }
            else
            {
               /* step 7 */
               if( JSE_FP_EQ(x,y) )
                  result = True;
               else
                  result = False;
            }
         }
         else
         {
            /* step 11 */
            if( SEVAR_ARRAY_PTR(vx) )
            {
               JSE_POINTER_UINDEX lx = SEVAR_STRING_LEN(vx);
               JSE_POINTER_UINDEX ly = SEVAR_STRING_LEN(vy);

               if ( lx != ly )
               {
                  result = False;
               }
               else
               {
                  const jsecharhugeptr sx = sevarGetData(call,vx);
                  const jsecharhugeptr sy = sevarGetData(call,vy);
#                 if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
#                    if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
                        if ( VString == tx )
#                    endif
                           lx *= sizeof(jsechar);
#                 endif
                  result = ( 0 == HugeMemCmp(sx,sy,lx) );
                  SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)sx);
                  SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)sy);
               }
            }
            else
            {
               /* step 13 */
               assert( tx==VObject );
               /* true if they refer to the same object */
               result = SEVAR_GET_OBJECT(vx)==SEVAR_GET_OBJECT(vy);
            }
         }
      }
   }
   else if ( strictEquality )
   {
      /* for strict equality different types are always !== */
      result = False;
   }
   else
   {
      /* step 14 - the types are not the same */

      if( tx==VNull && ty==VUndefined )
         result = True;
      else if( tx==VUndefined && ty==VNull )
         result = True;
      else
      {
         wSEVar tmp = STACK_PUSH;
         if( tx==VNumber && SEVAR_ARRAY_PTR(vy) )
         {
            /* step 16 */
            SEVAR_COPY(tmp,vy);
            sevarConvert(call,tmp,jseToNumber);
            result = sevarECMACompareEquality(call,vx,tmp,False);
         }
         else if( ty==VNumber && SEVAR_ARRAY_PTR(vx) )
         {
            /* step 17 */
            SEVAR_COPY(tmp,vx);
            sevarConvert(call,tmp,jseToNumber);
            result = sevarECMACompareEquality(call,tmp,vy,False);
         }
         else if( tx==VBoolean )
         {
            /* step 18 */
            SEVAR_INIT_NUMBER(tmp,SEVAR_GET_BOOLEAN(vx) ? jseOne : jseZero );
            result = sevarECMACompareEquality(call,tmp,vy,False);
         }
         else if( ty==VBoolean )
         {
            /* step 19 */
            SEVAR_INIT_NUMBER(tmp,SEVAR_GET_BOOLEAN(vy) ? jseOne : jseZero );
            result = sevarECMACompareEquality(call,vx,tmp,False);
         }
         else if( ty==VObject && (SEVAR_ARRAY_PTR(vx) || tx==VNumber) )
         {
            SEVAR_COPY(tmp,vy);
            sevarConvertToPrimitive(call,tmp,tx);
            result = sevarECMACompareEquality(call,vx,tmp,False);
         }
         else if( tx==VObject && (SEVAR_ARRAY_PTR(vy) || ty==VNumber) )
         {
            /* step 21 */
            SEVAR_COPY(tmp,vx);
            sevarConvertToPrimitive(call,tmp,ty);
            result = sevarECMACompareEquality(call,tmp,vy,False);
         }
         /* This is not an officialy ECMAScript step, but ECMAScript does not
          * have the Buffer type.  This case is to handle comparison between a
          * buffer and a string
          */
#        if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
         else if( (tx==VBuffer && ty==VString) || (tx==VString && ty==VBuffer) )
         {
            if( tx == VBuffer )
            {
               SEVAR_COPY(tmp,vx);
               sevarConvert(call,tmp,jseToString);
               result = sevarECMACompareEquality(call,tmp,vy,False);
            }
            else
            {
               SEVAR_COPY(tmp,vy);
               sevarConvert(call,tmp,jseToString);
               result = sevarECMACompareEquality(call,vx,tmp,False);
            }
         }
#        endif
         else
         {
            result = False;
         }
         STACK_POP;
      }
   }

   return result;
}


#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   jsebool NEAR_CALL
SEVAR_COMPARE_EQUALITY(struct Call *call,rSEVar vx,rSEVar vy)
{
   assert( sevarIsValid(call,vx) );
   assert( sevarIsValid(call,vy) );

   /* do C-like pointer behavor if this is a C-function and both are
    * strings or both are buffers.  Also, if one of the two types
    * is a literal then default to standard ecma behavior
    */
   if( !CALL_CBEHAVIOR ||
       SEVAR_GET_TYPE(vx)!=SEVAR_GET_TYPE(vy) ||
       !SEVAR_ARRAY_PTR(vx) ||
   /* For literal strings, always compare ecma-like */
       SESTR_IS_CONSTANT(SEVAR_GET_STRING(vx).data) ||
       SESTR_IS_CONSTANT(SEVAR_GET_STRING(vy).data) )
      return sevarECMACompareEquality(call,vx,vy,False);

   return SEVAR_GET_STRING(vx).data==SEVAR_GET_STRING(vy).data &&
          SEVAR_GET_STRING(vx).loffset==SEVAR_GET_STRING(vy).loffset;
}
#endif  /* defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS) */


   JSE_POINTER_UINDEX NEAR_CALL
sevarGetArrayLength(struct Call *call,rSEVar this,JSE_POINTER_SINDEX *MinIndex)
{
   assert( sevarIsValid(call,this) );

   if( SEVAR_ARRAY_PTR(this) )
   {
      if( MinIndex )
      {
         *MinIndex = -(JSE_POINTER_SINDEX)(SEVAR_GET_STRING(this).loffset
                                          +SEVAR_GET_STRING(this).data->zoffset);
      }
      return SEVAR_STRING_LEN(this);
   }
   else
   {
      JSE_POINTER_SINDEX MinIdx, MaxIdx;
      MemCountUInt x, used;
      rSEObject robj;
      rSEMembers rMembers;
      const struct _SEObjectMem *omem;

      MaxIdx = -1;
      MinIdx = 0;

      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(this));
      used = SEOBJECT_PTR(robj)->used;
      if (used == 0)
      {
	SEOBJECT_UNLOCK_R(robj);
      }
      else
      {
        SEMEMBERS_ASSIGN_LOCK_R(rMembers,SEOBJECT_PTR(robj)->hsemembers);
        SEOBJECT_UNLOCK_R(robj);
	for( x=0, omem=SEMEMBERS_PTR(rMembers); x<used; x++, omem++ )
	{
         VarName entry = omem->name;
         if( IsNumericStringTableEntry(entry) )
         {
            JSE_POINTER_SINDEX Idx =
               (JSE_POINTER_SINDEX)GetNumericStringTableEntry(entry);
            if ( Idx < MinIdx )
               MinIdx = Idx;
            if ( MaxIdx < Idx )
               MaxIdx = Idx;
         }
	}
	SEMEMBERS_UNLOCK_R(rMembers);
      }
      if( MinIndex ) *MinIndex = MinIdx;
      return (JSE_POINTER_UINDEX)(1+MaxIdx);
   }
}


   wSEObjectMem
seobjNewMember(struct Call *call,wSEObject obj,
               VarName members,jsebool *found)
{
   /* NYI: this is inefficient, to look it up then add it, when
    * needs to look up where it goes again. Optimize it
    */
   wSEObjectMem ret;
   
   SEOBJECTMEM_CAST_R(ret) = wseobjGetMemberStruct(call,SEOBJECT_CAST_R(obj),members);

   if( !(*found = (NULL != SEOBJECTMEM_PTR(ret))) )
   {
      ret = SEOBJ_CREATE_MEMBER(call,obj,members);
   }
   return ret;
}


   static wSEObjectMem NEAR_CALL
seobjCreateMemberGeneric(struct Call *call,wSEObject this,VarName name)
{
   MemCountUInt x;
   wSEMembers wMembers;
   wSEObjectMem ret;
   
   assert( name==NULL || SEOBJECTMEM_PTR(rseobjGetMemberStruct(call,SEOBJECT_CAST_R(this),name))==NULL );
   assert( (SEOBJECT_PTR(this)->flags & SEOBJ_FREE_LIST_BIT)==0 );

   /* When packing objects, it is possible for the members to be
    * initially unallocated. In addition, we have no 'alloced' field.
    * Instead the 'used' field always is exactly the number alloced.
    * We increment it below when adding the member.
    */
#  if JSE_PACK_OBJECTS==1
   if( SEOBJECT_PTR(this)->used==0 )
   {
#ifdef MEM_TRACKING
#if 0==JSE_DONT_POOL
      if (call->Global->memPoolCount==0) 
#endif
      {
        call->Global->all_mem_count++;
        if (call->Global->all_mem_count > call->Global->all_mem_maxCount)
   	    call->Global->all_mem_maxCount = call->Global->all_mem_count;
        call->Global->all_mem_size += sizeof(struct _SEObjectMem);
        if (call->Global->all_mem_size > call->Global->all_mem_maxSize)
	    call->Global->all_mem_maxSize = call->Global->all_mem_size;
      }
#endif
      SEOBJECT_PTR(this)->hsemembers =
#     if 0==JSE_DONT_POOL
         (call->Global->memPoolCount!=0)?
         call->Global->mem_pool[--call->Global->memPoolCount] :
#     endif
#     if JSE_MEMEXT_MEMBERS==0
         jseMustMalloc(struct _SEObjectMem,sizeof(struct _SEObjectMem)) ;
#     else
         semembersAlloc(1) ;
#     endif
   }
   else
   {
#ifdef MEM_TRACKING
      call->Global->all_mem_size += sizeof(struct _SEObjectMem);
      if (call->Global->all_mem_size > call->Global->all_mem_maxSize)
	  call->Global->all_mem_maxSize = call->Global->all_mem_size;
#endif
#     if ( 0 == JSE_MEMEXT_MEMBERS )
      SEOBJECT_PTR(this)->hsemembers =
         jseMustReMalloc(struct _SEObjectMem,SEOBJECT_PTR(this)->hsemembers,
                         (size_t)(sizeof(struct _SEObjectMem)*(SEOBJECT_PTR(this)->used+1)));
#     else
      SEOBJECT_PTR(this)->hsemembers = 
         semembersRealloc(SEOBJECT_PTR(this)->hsemembers,SEOBJECT_PTR(this)->used+1);
      if( SEOBJECT_PTR(this)->hsemembers == hSEMembersNull )
      {
         jseInsufficientMemory();
      }
#     endif
   }
#  else
   
   assert( SEOBJECT_PTR(this)->used <= SEOBJECT_PTR(this)->alloced );
   assert( SEOBJECT_PTR(this)->alloced!=0 );
   if( SEOBJECT_PTR(this)->used == SEOBJECT_PTR(this)->alloced )
   {
#ifdef MEM_TRACKING
      call->Global->all_mem_size += sizeof(struct _SEObjectMem)*this->alloced;
      if (call->Global->all_mem_size > call->Global->all_mem_maxSize)
	  call->Global->all_mem_maxSize = call->Global->all_mem_size;
#endif
      SEOBJECT_PTR(this)->alloced *= 2;
#     if ( 0 == JSE_MEMEXT_MEMBERS )
         SEOBJECT_PTR(this)->hsemembers =
            jseMustReMalloc(struct _SEObjectMem,SEOBJECT_PTR(this)->hsemembers,
                            (size_t)(sizeof(struct _SEObjectMem)*SEOBJECT_PTR(this)->alloced));
#     else
         SEOBJECT_PTR(this)->hsemembers = 
            semembersRealloc(SEOBJECT_PTR(this)->hsemembers,SEOBJECT_PTR(this)->alloced);
      if( SEOBJECT_PTR(this)->hsemembers==NULL )
      {
         jseInsufficientMemory();
      }
#     endif
   }
   assert( SEOBJECT_PTR(this)->used < SEOBJECT_PTR(this)->alloced );
#  endif
   
   SEMEMBERS_ASSIGN_LOCK_W(wMembers,SEOBJECT_PTR(this)->hsemembers);

   /* find out where this member ought to be put. */
   if( SEOBJECT_PTR(this)->flags & SEOBJ_DONT_SORT )
   {
      x = SEOBJECT_PTR(this)->used;
   }
   else
   {
      assert( name!=NULL );
      x = SEOBJECT_PTR(this)->used;
      /* mgroeber 08/05/00: pointers are compared as 16-bit by default */
      while( x>0 && (dword)name<(dword)SEMEMBERS_PTR(wMembers)[x-1].name )
         x--;
   }

   if( x < SEOBJECT_PTR(this)->used )
   {
      memmove((void *)(SEMEMBERS_PTR(wMembers)+x+1),(void *)(SEMEMBERS_PTR(wMembers)+x),
              (uint)((SEOBJECT_PTR(this)->used-x)*sizeof(struct _SEObjectMem)));
   }
   SEOBJECT_PTR(this)->used++;
   SEOBJECTMEM_ASSIGN_INDEX(ret,wMembers,x);
   SEOBJECTMEM_PTR(ret)->name = name;
   SEOBJECTMEM_PTR(ret)->attributes = 0;
   SEVAR_INIT_UNDEFINED(SEOBJECTMEM_VAR(ret));
#  if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
   if( !SEOBJ_IS_DYNAMIC(this) &&
      (
       name==STOCK_STRING(_delete) ||
       name==STOCK_STRING(_put) ||
       name==STOCK_STRING(_canPut) ||
       name==STOCK_STRING(_get) ||
       name==STOCK_STRING(_hasProperty) ||
       name==STOCK_STRING(_defaultValue)
#      if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
       || name==STOCK_STRING(_operator)
#      endif
       )
       )
      SEOBJ_MAKE_DYNAMIC(this);
#  endif

   /* Special case code for ECMA arrays - if we create a new numeric
    * entry, update the length accordingly.
    */
   if( (SEOBJECT_PTR(this)->flags&IS_ARRAY) && IsNumericStringTableEntry(name) )
   {
      wSEObjectMem len;
      SEOBJECTMEM_CAST_R(len) = wseobjGetMemberStruct(call,SEOBJECT_CAST_R(this),STOCK_STRING(length));
      if ( NULL != SEOBJECTMEM_PTR(len) )
      {
         if ( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(len))==VNumber )
         {
            slong val = GetNumericStringTableEntry(name)+1;
            if( SEVAR_GET_SLONG(SEOBJECTMEM_VAR(len))<val )
            {
               SEVAR_PUT_SLONG(SEOBJECTMEM_VAR(len),val);
            }
         }
         SEOBJECTMEM_UNLOCK_W(len);
      }
   }

   return ret;
}

   void NEAR_CALL
seobjCreateMemberCopy(wSEObjectMem *retObjectMem,struct Call *call,wSEObject obj,
                      VarName member,rSEVar copyFrom)
{
   wSEObjectMem it = seobjCreateMemberGeneric(call,obj,member);
   assert( sevarIsValid(call,copyFrom) );
   SEVAR_COPY(SEOBJECTMEM_VAR(it),copyFrom);
   if ( NULL == retObjectMem )
      SEOBJECTMEM_UNLOCK_W(it);  
   else
      *retObjectMem = it;      
}

   wSEObjectMem NEAR_CALL
seobjCreateMemberType(struct Call *call,wSEObject this,VarName name,jseVarType type)
{
   wSEObjectMem it = seobjCreateMemberGeneric(call,this,name);
   sevarInitType(call,SEOBJECTMEM_VAR(it),type);
   return it;
}

   void NEAR_CALL
sevarInitType(struct Call *call,wSEVar dest,jseVarType type)
{
   switch( type )
   {
      case VString:
#        if defined(JSE_MBCS) && (JSE_MBCS!=0)
            SEVAR_INIT_STRING(call,dest,UNISTR(""),0,0);
#        else
            SEVAR_INIT_STRING(call,dest,UNISTR(""),0);
#        endif
         break;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
         SEVAR_INIT_BUFFER(call,dest,"",0);
         break;
#     endif
      case VObject:
         SEVAR_INIT_BLANK_OBJECT(call,dest);
         break;
      case VBoolean:
         SEVAR_INIT_BOOLEAN(dest,False);
         break;
      default:
         dest->type = type;
         dest->data.num_val = jseZero;
         break;
   }
   assert( sevarIsValid(call,dest) );
}

   void NEAR_CALL
sevarInitNewObject(struct Call *call,wSEVar thisvar,rSEVar thefunc)
{
   rSEObjectMem prop;
   rSEObject robj;

   SEVAR_INIT_BLANK_OBJECT(call,thisvar);
   assert( SEVAR_GET_TYPE(thisvar)==VObject );
   assert( SEVAR_GET_TYPE(thefunc)==VObject );

   assert( sevarIsValid(call,thisvar) );
   assert( sevarIsValid(call,thefunc) );

   /* Copy the _prototype from the constructor.prototype, but if there
    * is not a .prototype then do nothing and let this object
    * default to Object.prototype - new Foo() produces an _object_, NOT
    * a function.
    */
   SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(thefunc));
   prop = rseobjGetMemberStruct(call,robj,STOCK_STRING(prototype));
   if ( NULL != SEOBJECTMEM_PTR(prop) )
   {
      rSEVar vprop = SEOBJECTMEM_VAR(prop);
      if( SEVAR_GET_TYPE(vprop)==VObject
       && SEVAR_GET_OBJECT(vprop)!=call->hObjectPrototype /* default */ )
      {
         wSEObject wobj;
         SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(thisvar));
         seobjCreateMemberCopy(NULL,call,wobj,STOCK_STRING(_prototype),vprop);
#        if ( 0 != JSE_DYNAMIC_OBJ_INHERIT )
         if( SEOBJ_IS_DYNAMIC(robj) )
            SEOBJ_MAKE_DYNAMIC(wobj);
#        endif
         seobjSetAttributes(call,SEVAR_GET_OBJECT(thisvar),
                            STOCK_STRING(_prototype),
                            jseDontEnum);
         SEOBJECT_UNLOCK_W(wobj);
      }
      SEOBJECTMEM_UNLOCK_R(prop);
   }
   SEOBJECT_UNLOCK_R(robj);
}

   rSEVar NEAR_CALL
seobjGetFuncVar(struct Call *call,rSEVar thefunc,
                VarName entry,
                rSEObjectMem *rMem)
{
   rSEVar var;
   rSEObject robj;

   assert( sevarIsValid(call,thefunc) );

   assert( SEVAR_GET_TYPE(thefunc)==VObject );
   /* don't inherit _call's or _constructors, that would make no sense! */
   SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(thefunc));
   *rMem = rseobjGetMemberStruct(call,robj,entry);
   if ( NULL == SEOBJECTMEM_PTR(*rMem) )
      var = NULL;
   else
      var = SEOBJECTMEM_VAR(*rMem);

   if( NULL==var  ||  !SEVAR_IS_FUNCTION(call,var) )
   {
#     if 0!=JSE_MEMEXT_MEMBERS
         if ( NULL != var )
         {
            SEOBJECTMEM_UNLOCK_R(*rMem);
            SEOBJECTMEM_PTR(*rMem) = NULL;
         }
#     endif
      var = ( SEVAR_GET_TYPE(thefunc)==VObject  &&  SEOBJECT_PTR(robj)->func!=NULL )
          ? thefunc
          : NULL ;
   }
   SEOBJECT_UNLOCK_R(robj);
   return var;
}

/* ----------------------------------------------------------------------
 * conversion routines
 * ---------------------------------------------------------------------- */

#pragma codeseg VARUTIL2_TEXT

   static void NEAR_CALL
sevarConvertToPrimitive(struct Call *call,wSEVar to_convert,jseVarType hint)
{
   assert( sevarIsValid(call,to_convert) );

   if( SEVAR_GET_TYPE(to_convert)==VObject )
   {
      sevarDefaultValue(call,to_convert,hint);
      if( SEVAR_GET_TYPE(to_convert)==VObject )
      {
         callError(call,textcoreCANNOT_CONVERT_OBJECT);
      }
   }
}


   jsebool NEAR_CALL
sevarConvertToBoolean(struct Call *call,wSEVar var)
{
   jsebool result = False;

   assert( sevarIsValid(call,var) );

   if( SEVAR_GET_TYPE(var)==VObject &&
       jseOptToBooleanObjectEval & call->Global->ExternalLinkParms.options )
   {
      sevarConvertToPrimitive(call,var,VBoolean);
   }

   /* return true or false on how ecma would evaluate as a boolean */
   switch( SEVAR_GET_TYPE(var) )
   {
      case VUndefined:
      case VNull:
         result = False;
         break;
      case VBoolean:
         result = SEVAR_GET_BOOLEAN(var);
         break;
      case VNumber:
      {
         jsenumber value = SEVAR_GET_NUMBER(var);
         result = (jseIsZero(value) || jseIsNaN(value)) ? False : True ;
         break;
      }
      case VString:
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
#     endif
      {
         result = SEVAR_STRING_LEN(var)!=0;
         break;
      }
      case VObject:
         /* ECMAScript has ToBoolean always return True */
         result = True;
         break;
#     ifndef NDEBUG
      default:
         assert( False );
#     endif
   }
   return result;
}


   jsenumber NEAR_CALL
sevarConvertToNumber(struct Call *call,wSEVar SourceVar)
{
   jsenumber val;

   assert( sevarIsValid(call,SourceVar) );

   if( SEVAR_GET_TYPE(SourceVar)==VObject )
   {
      sevarConvertToPrimitive(call,SourceVar,VNumber);
   }

   switch( SEVAR_GET_TYPE(SourceVar) )
   {
      case VUndefined:
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
#     endif
         val = jseNaN;
         break;
      case VNull:
         val = jseZero;
         break;
      case VNumber:
         val = SEVAR_GET_NUMBER(SourceVar);
         break;
      case VBoolean:
         val = SEVAR_GET_BOOLEAN(SourceVar) ? jseOne : jseZero ;
         break;
      case VString:
      {
         const jsecharptr tmp = sevarGetData(call,SourceVar);
         val = convertStringToNumber(call,(jsecharptr)tmp,
                                     (size_t)SEVAR_STRING_LEN(SourceVar));
         SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)tmp);
         break;
      }
#     ifndef NDEBUG
      default:
         assert( False );
#     endif
   }

   return val;
}


   jsenumber NEAR_CALL
convertToSomeInteger(jsenumber val,jseConversionTarget dest_type)
{
   jsenumber value;

   assert( jseToInteger==dest_type || jseToInt32==dest_type ||
           jseToUint32==dest_type || jseToUint16==dest_type );

   if ( jseIsZero(val)  ||  !jseIsFinite(val) )
   {
      value = jseZero;
   }
   else
   {
      /* Note for jseToInt32 and jseToUint32: As far as I can tell, the spec
       * simply does the standard'C' conversion to an int. Fortunately, due to
       * 2's complement integer storage, the correct value is automatically
       * generated regardless of whether the target is signed or not.
       * Gotta love it.
       */
      /* The above is NOT true.  The spec converts the integer with Modulo
       * 2^32.  The "standard C conversion" doesn't when dealing with
       * floating point values.
       */
      if( jseToUint16 == dest_type )
      {
#        if (0!=JSE_FLOATING_POINT)
         {
            jsebool isNeg = jseIsNegative(val);
            if ( isNeg )
               val = JSE_FP_NEGATE(val);
            val = JSE_FP_FLOOR(val);
            if ( isNeg )
               val = JSE_FP_NEGATE(val);
            value = JSE_FP_FMOD(val,jseFPx10000);
            if( jseIsNegative(val) )
               JSE_FP_ADD_EQ(value,jseFPx10000);
         }
#        else
            /* This WAS the default behavior, but it is incorrect */
            value = (sword32)val & 0xffff;
#        endif
      }
      else
      {
         assert( jseToInt32==dest_type || jseToUint32==dest_type ||
                 jseToInteger==dest_type );
#        if (0!=JSE_FLOATING_POINT)
         {
            jsebool isNeg = jseIsNegative(val);
            if ( isNeg )
               val = JSE_FP_NEGATE(val);
            value = JSE_FP_FLOOR(val);
            if ( isNeg )
               value = JSE_FP_NEGATE(value);
         }
#        else
            value = val;
#        endif
         if ( jseToInteger != dest_type )
         {
#           if (0!=JSE_FLOATING_POINT)
            {
               value = JSE_FP_FMOD(value,jseFPx100000000);
               if( jseIsNegative(value) )
                  JSE_FP_ADD_EQ(value,jseFPx100000000);
               if( jseToInt32 == dest_type  &&  JSE_FP_LT(jseFPx7fffffff,value) )
                  JSE_FP_SUB_EQ(value,jseFPx100000000);
            }
#           else
               /* This WAS the default behavior, but it is incorrect */
               value = (sword32)value;
#           endif
         }
      }
   }

   return value;
}


   static void NEAR_CALL
sevarConvertToSomeInteger(struct Call *call,wSEVar SourceVar,jseConversionTarget dest_type)
{
   jsenumber val;

   assert( sevarIsValid(call,SourceVar) );
   val = sevarConvertToNumber(call,SourceVar);
   val = convertToSomeInteger(val,dest_type);
   SEVAR_INIT_NUMBER(SourceVar,val);
   assert( sevarIsValid(call,SourceVar) );
}


   void NEAR_CALL
sevarConvertToString(struct Call *call,wSEVar SourceVar)
{
   assert( sevarIsValid(call,SourceVar) );

   if( SEVAR_GET_TYPE(SourceVar)==VObject )
   {
      sevarConvertToPrimitive(call,SourceVar,VString);
   }

   switch( SEVAR_GET_TYPE(SourceVar) )
   {
      case VUndefined:
         SEVAR_INIT_STRING_NULLLEN(call,SourceVar,UNISTR("undefined"),9);
         break;
      case VNull:
         SEVAR_INIT_STRING_NULLLEN(call,SourceVar,UNISTR("null"),4);
         break;
      case VBoolean:
         if( SEVAR_GET_BOOLEAN(SourceVar) )
         {
            SEVAR_INIT_STRING_NULLLEN(call,SourceVar,UNISTR("true"),4);
         }
         else
         {
            SEVAR_INIT_STRING_NULLLEN(call,SourceVar,UNISTR("false"),5);
         }
         break;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
      {
         JSE_POINTER_UINDEX bmax = SEVAR_STRING_LEN(SourceVar);
         if ( 0 < bmax )   /* alloc and copy if no bytes to transfer */
         {
            jsecharhugeptr tmpbuf;
            ubyte _HUGE_ * origbuf = (ubyte _HUGE_ *)sevarGetData(call,SourceVar);
            jsecharhugeptr save;
            uint x;

#           ifdef HUGE_MEMORY
            assert( bmax*sizeof(jsechar)<HUGE_MEMORY );
#           endif
            tmpbuf = (jsecharptr) jseMustMalloc(jsechar,(uint)(bmax*sizeof(jsechar)));
            save = tmpbuf;
            for( x=0;x<bmax;x++ )
            {
               JSECHARPTR_PUTC(tmpbuf,(jsechar)origbuf[x]);
               JSECHARPTR_INC(tmpbuf);
            }
            SEVAR_INIT_STRING_STRLEN(call,SourceVar,(jsecharptr)save,bmax);

            jseMustFree((void *)save);

            SEVAR_FREE_DATA(call,origbuf);
         }
         else
         {
#           if defined(JSE_MBCS) && (JSE_MBCS!=0)
            SEVAR_INIT_STRING(call,SourceVar,UNISTR(""),0,0);
#           else
            SEVAR_INIT_STRING(call,SourceVar,UNISTR(""),0);
#           endif
         }
         break;
      }
#     endif
      case VNumber:
      {
         jsechar buffer[ECMA_NUMTOSTRING_MAX];
         EcmaNumberToString(buffer,SEVAR_GET_NUMBER(SourceVar));
         SEVAR_INIT_STRING_NULLLEN(call,SourceVar,(jsecharptr)buffer,
                                   strlen_jsechar((jsecharptr)buffer));
         break;
      }
   }
   assert( sevarIsValid(call,SourceVar) );
}


#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   static void NEAR_CALL
sevarConvertToBytes(struct Call *call,wSEVar SourceVar)
{
   assert( sevarIsValid(call,SourceVar) );

   if( SEVAR_GET_TYPE(SourceVar)==VObject )
      sevarConvertToPrimitive(call,SourceVar,VString);

   switch( SEVAR_GET_TYPE(SourceVar) )
   {
      case VUndefined:
         SEVAR_INIT_BUFFER(call,SourceVar,"",0);
         break;
      case VNull:
      {
         void *ptr = NULL;
         SEVAR_INIT_BUFFER(call,SourceVar,&ptr,sizeof(void *));
         break;
      }
      case VBoolean:
      {
         jsebool val = SEVAR_GET_BOOLEAN(SourceVar);
         SEVAR_INIT_BUFFER(call,SourceVar,(void *)&val,sizeof(val));
         break;
      }
      case VString:
      {
         JSE_MEMEXT_R void *data = sevarGetData(call,SourceVar);
         JSE_POINTER_UINDEX len = SEVAR_STRING_LEN(SourceVar);
         SEVAR_INIT_BUFFER(call,SourceVar,data,len*sizeof(jsechar));
         SEVAR_FREE_DATA(call,data);
         break;
      }
      case VNumber:
      {
         jsenumber val = SEVAR_GET_NUMBER(SourceVar);
         SEVAR_INIT_BUFFER(call,SourceVar,(void *)&val,sizeof(val));
         break;
      }
   }
   assert( sevarIsValid(call,SourceVar) );
}
#endif

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   static void NEAR_CALL
sevarConvertToBuffer(struct Call *call,wSEVar SourceVar)
{
   JSE_POINTER_UINDEX length;

   assert( sevarIsValid(call,SourceVar) );
   sevarConvertToString(call,SourceVar);
   length = SEVAR_STRING_LEN(SourceVar);

   if ( 0 < length ) /* don't allocate if no bytes */
   {
      ubyte _HUGE_ *buffer = (ubyte _HUGE_ *)jseMustHugeMalloc(length);
      jsecharhugeptr oldbuf = (jsecharhugeptr )(sevarGetData(call,SourceVar));
      JSE_POINTER_UINDEX x;

      assert( NULL != buffer );

      for( x=0;x<length;x++ )
      {
         buffer[x] = (ubyte)(JSECHARPTR_GETC(oldbuf));
         JSECHARPTR_INC(oldbuf);
      }
      SEVAR_INIT_BUFFER(call,SourceVar,(void *)buffer,length);
      HugeFree(buffer);
      SEVAR_FREE_DATA(call,oldbuf);
   }
   else
   {
      SEVAR_INIT_BUFFER(call,SourceVar,"",0);
   }
   assert( sevarIsValid(call,SourceVar) );
}
#endif


   void NEAR_CALL
sevarConvertToObject(struct Call *call,wSEVar SourceVar)
{
   const jsecharptr type = NULL;

   assert( sevarIsValid(call,SourceVar) );
   switch ( SEVAR_GET_TYPE(SourceVar) )
   {
      SEDBG( default: assert( False ); )
      SEDBG( case VObject: break; )
      case VUndefined:
      case VNull:
         callError(call,textcoreCANNOT_CONVERT_TO_OBJECT);
         /* expect to return some variable, so create a dummy */
         /* Functions expect that this will return an object, so use VObject instead
          * of VUndefined like this used to
          */
         SEVAR_INIT_BLANK_OBJECT(call,SourceVar);
         return;
      case VBoolean:
         type = UNISTR("Boolean");
         break;
      case VNumber:
         type = UNISTR("Number");
         break;
      case VString:
      {
         wSEObjectMem mem;
         wSEObject wobj;
         wSEVar new_var2;

         new_var2 = STACK_PUSH;
         SEVAR_INIT_BLANK_OBJECT(call,new_var2);

         /* Make it a String */
         assert( call->hStringPrototype!=hSEObjectNull );
         SEOBJECT_ASSIGN_LOCK_W(wobj,SEVAR_GET_OBJECT(new_var2));
         mem = SEOBJ_CREATE_MEMBER(call,wobj,STOCK_STRING(_prototype));
         SEVAR_INIT_OBJECT(SEOBJECTMEM_VAR(mem),call->hStringPrototype);
         SEOBJECTMEM_UNLOCK_W(mem);

         /* Set its value to the string, note we make it the same variable so
          * changes affect both 'sides', as the String wrapper IS the string
          */
         mem = SEOBJ_CREATE_MEMBER(call,wobj,STOCK_STRING(_value));
         SEVAR_COPY(SEOBJECTMEM_VAR(mem),SourceVar);
         SEOBJECTMEM_UNLOCK_W(mem);

         /* Set up its length */
         mem = SEOBJ_CREATE_MEMBER(call,wobj,STOCK_STRING(length));
         SEVAR_INIT_SLONG(SEOBJECTMEM_VAR(mem),SEVAR_STRING_LEN(SourceVar));
         SEOBJECTMEM_UNLOCK_W(mem);

         SEOBJECT_UNLOCK_W(wobj);

         SEVAR_COPY(SourceVar,new_var2);
         STACK_POP;
         return;
      }

#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case VBuffer:
         type = UNISTR("Buffer");
         break;
#     endif
   }

   if ( NULL != type )
   {
      rSEVar loc = STACK_PUSH;


      /* This is a standard ECMA string, it seems a good idea to lock into
       * memory. If this is even used, it will be locked in by the global
       * variable for the life of the program anyway.
       */
      VarName name = LockedStringTableEntry(call,type,(stringLengthType)strlen_jsechar(type));

      if( !callFindAnyVariable(call,name,True,False) )
      {
         SEVAR_INIT_BLANK_OBJECT(call,SourceVar);
      }
      else
      {
         sevarCallConstructor(call,loc,SourceVar,SourceVar);
      }
      STACK_POP;
   }
   assert( sevarIsValid(call,SourceVar) );
}


/* Take the given variable and convert it to a new variable using the
 * ECMAScript conversion operators
 */
   void NEAR_CALL
sevarConvert(struct Call *call,wSEVar SourceVar,jseConversionTarget dest_type)
{
   assert( sevarIsValid(call,SourceVar) );

   /* NOTE: this is all very ugly. Just see the section 9.x of the language
    * spec for what it is doing. */
   switch( dest_type )
   {
      case jseToPrimitive:
         sevarConvertToPrimitive(call,SourceVar,VUndefined);
         break;
      case jseToBoolean:
         SEVAR_INIT_BOOLEAN(SourceVar,sevarConvertToBoolean(call,SourceVar));
         break;
      case jseToNumber:
         SEVAR_INIT_NUMBER(SourceVar,sevarConvertToNumber(call,SourceVar));
         break;
      case jseToInteger:
      case jseToInt32:
      case jseToUint32:
      case jseToUint16:
         sevarConvertToSomeInteger(call,SourceVar,dest_type);
         break;
      case jseToString:
         sevarConvertToString(call,SourceVar);
         break;
#     if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case jseToBytes:
         sevarConvertToBytes(call,SourceVar);
         break;
      case jseToBuffer:
         sevarConvertToBuffer(call,SourceVar);
         break;
#     endif
      case jseToObject:
         sevarConvertToObject(call,SourceVar);
         break;
   }
   assert( sevarIsValid(call,SourceVar) );
}

/* ----------------------------------------------------------------------
 * The dynamic functions
 * ---------------------------------------------------------------------- */


   jsebool NEAR_CALL
seobjCanPut(struct Call *call,rSEObject obj,VarName name)
{
   jsebool ret;
   wSEVar value;

   /* if doesn't have a function as a canput property, then can put. */
   assert( SEOBJ_IS_DYNAMIC(obj) );

   value = STACK_PUSH;

   /* Make sure that we initialize it in case GC happens */
   SEVAR_INIT_UNDEFINED(value);
   if( seobjCallDynamicProperty(call,obj,dynacallCanput,name,NULL,value) )
   {
      ret = ( VUndefined == SEVAR_GET_TYPE(value) ) ?
         True : sevarConvertToBoolean(call,value);
   }
   else
   {
      /* the regular thing is always can put */
      ret = True;
   }

   STACK_POP;

   return ret;
}

/* The variable is the return value which you must destroy when done.
 */
   jsebool NEAR_CALL
sevarCallConstructor(struct Call *call,rSEVar this,rSEVar SourceVar,wSEVar new_var)
{
   wSEVar tmp;
   rSEVar tmp2;
   rSEObjectMem tmp2objmem;

   assert( sevarIsValid(call,SourceVar) );
   assert( sevarIsValid(call,new_var) );

   tmp = STACK_PUSH;
   sevarInitNewObject(call,tmp,this);
   /* we need to make the constructed object inherit from the
    * constructor, but then call the constructor's construct
    * function, even if redirected. We do not make the object
    * inherit from the redirected constructor. For instance,
    *
    *    var a = new Object();
    *    a._construct = func;
    *
    *    var b = new a();
    *
    * 'b' is still an object of type 'a', not of 'func'.
    */
   tmp2 = seobjGetFuncVar(call,this,STOCK_STRING(_construct),&tmp2objmem);
   if( tmp2==NULL )
   {
#     if 0!=JSE_MEMEXT_MEMBERS
         if ( NULL != SEOBJECTMEM_PTR(tmp2objmem) )
            SEOBJECTMEM_UNLOCK_R(tmp2objmem);
#     endif
      STACK_POP;
      return False;
   }

   tmp = STACK_PUSH;
   SEVAR_COPY(tmp,tmp2);

#  if 0!=JSE_MEMEXT_MEMBERS
      if ( NULL != SEOBJECTMEM_PTR(tmp2objmem) )
         SEOBJECTMEM_UNLOCK_R(tmp2objmem);
#  endif

   tmp = STACK_PUSH;
   SEVAR_COPY(tmp,SourceVar);

   callFunctionFully(call,1,True);

   tmp = STACK0;
   SEVAR_COPY(new_var,tmp);
   STACK_POP;

   return True;
}


JSE_POINTER_UINDEX NEAR_CALL SEVAR_STRING_LEN(rSEVar v)
{
   JSE_POINTER_UINDEX slen = SEVAR_GET_STRING(v).data->length
                           - SEVAR_GET_STRING(v).data->zoffset;
   if( SEVAR_GET_STRING(v).loffset>0 &&
       (JSE_POINTER_UINDEX)SEVAR_GET_STRING(v).loffset>slen )
   {
      /* we are off the right-end of the string, the string is
       * considered to be empty */
      return 0;
   }
   return slen - SEVAR_GET_STRING(v).loffset;
}


#if JSE_MEMEXT_STRINGS==1
struct stringTrack
{
   struct stringTrack *prev,*next;

   jsememextHandle handle;
   JSE_MEMEXT_R void *data;
   JSE_MEMEXT_R void *findval;

   int flags;
};

   struct stringTrack *
findStringTrack(struct Call *call,JSE_MEMEXT_R void *data)
{
   struct stringTrack *loop = call->Global->tracks;

   while( loop )
   {
      if( loop->findval==data ) return loop;
      loop = loop->next;
   }

   return NULL;
}

#define NOTE_NOUNLOCK 0
#define NOTE_UNLOCK 1

   void
SEVAR_FREE_DATA(struct Call *call,JSE_MEMEXT_R void *data)
{
   struct stringTrack *st = findStringTrack(call,data);

   assert( st!=NULL );

   if( (st->flags & NOTE_UNLOCK)!=0 )
      jsememextUnlockRead(st->handle,st->data,jseMemExtStringType);
   if( st->prev )
      st->prev->next = st->next;
   else
      call->Global->tracks = st->next;
   if( st->next )
      st->next->prev = st->prev;
   jseMustFree(st);
}

   void
sevarNoteData(struct Call *call,jsememextHandle handle,
              JSE_MEMEXT_R void *data,JSE_MEMEXT_R void *findval,
              int flags)
{
   struct stringTrack *tr = jseMustMalloc(struct stringTrack,sizeof(struct stringTrack));

   tr->prev = NULL;
   tr->next = call->Global->tracks;
   if( tr->next ) tr->next->prev = tr;
   call->Global->tracks = tr;

   tr->handle = handle;
   tr->data = data;
   tr->findval = findval;

   tr->flags = flags;
}
#endif


JSE_MEMEXT_R void * NEAR_CALL sevarGetData(struct Call *call,rSEVar v)
{
   uword32 slen;
   JSE_MEMEXT_R void *data;
   JSE_MEMEXT_R void *ret;


   assert( sevarIsValid(call,v) );
   assert( SEVAR_ARRAY_PTR(v) );

   slen = SEVAR_GET_STRING(v).data->length -
      SEVAR_GET_STRING(v).data->zoffset;
   /* we are off the right end of the string, considered to be empty */
   if( SEVAR_GET_STRING(v).loffset>0 &&
       (uword32)SEVAR_GET_STRING(v).loffset>slen )
   {
      ret = "";
#     if JSE_MEMEXT_STRINGS==1
         sevarNoteData(call,SEVAR_GET_STRING(v).data->stringdata,ret,ret,NOTE_NOUNLOCK);
#     endif
      return ret;
   }

   /* if we are off the left end of string, make sure that area exists */
   if( SEVAR_GET_STRING(v).loffset<0 &&
       (uword32)(-SEVAR_GET_STRING(v).loffset)>SEVAR_GET_STRING(v).data->zoffset )
   {
      sevarValidateIndex(call,&(SEVAR_GET_STRING(v)),0,0,SEVAR_GET_TYPE(v)!=VString);
   }

   data = SESTRING_GET_DATA(SEVAR_GET_STRING(v).data);
   if( SEVAR_GET_TYPE(v)==VString )
   {
      ret = JSECHARPTR_OFFSET((JSE_MEMEXT_R jsecharptr)data,
         SEVAR_GET_STRING(v).data->zoffset +
         SEVAR_GET_STRING(v).loffset);
   }
   else
   {
      ret = ((JSE_MEMEXT_R ubyte *)data) +
         SEVAR_GET_STRING(v).data->zoffset +
         SEVAR_GET_STRING(v).loffset;
   }

#  if JSE_MEMEXT_STRINGS==1
      sevarNoteData(call,SEVAR_GET_STRING(v).data->stringdata,data,ret,NOTE_UNLOCK);
#  endif
   return ret;
}

/* Update 'me' */
   void NEAR_CALL
GetDotNamedVar(struct Call *call,wSEVar me,const jsecharptr NameWithDots,
               jsebool FinalMustBeVObject)
{
   VarName varname;
   rSEObjectMem robjmem;
   rSEObject robj;
   hSEObject hobj;
   jsecharptr dotFound;

   assert( sevarIsValid(call,me) );
   assert( NameWithDots!=NULL );

   /* for each element in NameWithDots add a sub object */
   dotFound = ( NULL == NameWithDots ) ? (jsecharptr )NULL :
      strchr_jsechar((jsecharptr)NameWithDots,'.');

   /* This function is used for internal stuff, like function names - things
    * that will be around for the whole program execution.
    */

   if ( NULL != dotFound )
   {
      varname = LockedStringTableEntry(call,NameWithDots,
                                       (stringLengthType)JSECHARPTR_DIFF(dotFound,NameWithDots));
   }
   else
   {
      varname = LockedStringTableEntry(call,NameWithDots,(stringLengthType)strlen_jsechar(NameWithDots));
   }

   SEVAR_DEREFERENCE(call,me);
   hobj = SEVAR_GET_OBJECT(me);
   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
   robjmem = rseobjGetMemberStruct(call,robj,varname);

   if( NULL == SEOBJECTMEM_PTR(robjmem) )
   {
      wSEObject wobj;
      wSEObjectMem wobjmem;
      jsebool dyn = SEOBJ_IS_DYNAMIC(robj);
      wSEVar objvar;

      if( dyn )
      {
         objvar = STACK_PUSH;
      }
      else
      {
         SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
         wobjmem = SEOBJ_CREATE_MEMBER(call,wobj,varname);
         SEOBJECT_UNLOCK_W(wobj);
         objvar = SEOBJECTMEM_VAR(wobjmem);
      }

      if( dotFound || FinalMustBeVObject )
         SEVAR_INIT_BLANK_OBJECT(call,objvar);
      else
         SEVAR_INIT_UNDEFINED(objvar);

      if( dyn )
      {
         sevarPutValueEx(call,me,varname,objvar,False);
         STACK_POP;
      }
      else
      {
         SEOBJECTMEM_UNLOCK_W(wobjmem);
      }
   }
   else if( (dotFound || FinalMustBeVObject)
         && SEVAR_GET_TYPE(SEOBJECTMEM_VAR(robjmem))!=VObject )
   {
      wSEObjectMem wobjmem;

      assert( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(robjmem))!=VStorage );
#     if JSE_COMPACT_LIBFUNCS==1
         assert( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(robjmem))!=VLibFunc );
#     endif
      /* we have to trash the existing contents and make sure
       * we are looking at an object to find the next section in.
       */
      SEOBJECTMEM_UNLOCK_R(robjmem);
      SEOBJECTMEM_CAST_R(wobjmem) = wseobjGetMemberStruct(call,robj,varname);
      assert( NULL != SEOBJECTMEM_PTR(wobjmem) );
      SEVAR_INIT_BLANK_OBJECT(call,SEOBJECTMEM_VAR(wobjmem));

      if( SEOBJ_IS_DYNAMIC(robj) )
      {
         sevarPutValueEx(call,me,varname,SEOBJECTMEM_VAR(wobjmem),False);
         STACK_POP;
      }
      SEOBJECTMEM_UNLOCK_W(wobjmem);
   }
   else
   {
      SEOBJECTMEM_UNLOCK_R(robjmem);
   }

   SEOBJECT_UNLOCK_R(robj);

   SEVAR_INIT_REFERENCE(me,hobj,varname);

   /* go down chain */
   if( dotFound!=NULL )
      GetDotNamedVar(call,me,JSECHARPTR_NEXT(dotFound),FinalMustBeVObject);

   assert( sevarIsValid(call,me) );
   assert( SEVAR_GET_TYPE(me)==VReference );
}


jsebool NEAR_CALL seobjDeleteMember(struct Call *call,wSEObject this,VarName member,
                                    jsebool testDontDeleteAttribute)
{
   VarName Name;
   wSEMembers wMembers;
   MemCountUInt elem_num;
   wSEObjectMem it;
   
   SEOBJECTMEM_CAST_R(it) = wseobjGetMemberStruct(call,SEOBJECT_CAST_R(this),member);

   /* find the members (return NULL if not there) and get its index */
   if ( NULL == SEOBJECTMEM_PTR(it) )
   {
      /* member doesn't exist; don't delete what does not exist */
      return False;
   }
   if ( testDontDeleteAttribute
     && (SEOBJECTMEM_PTR(it)->attributes & jseDontDelete)!=0 )
   {
      SEOBJECTMEM_UNLOCK_W(it);
      return False;
   }
#  if 0==JSE_MEMEXT_MEMBERS
      wMembers = SEOBJECT_PTR(this)->hsemembers;
#  else
      wMembers = it.semembers;
#  endif
   elem_num = SEOBJECTMEM_PTR(it) - SEMEMBERS_PTR(wMembers);

   assert( elem_num<SEOBJECT_PTR(this)->used );
   Name = SEOBJECTMEM_PTR(it)->name;
#  if 0==JSE_PER_OBJECT_CACHE
      call->Global->recentObjectCache.hobj = hSEObjectNull;
#  else
      SEOBJECT_PTR(this)->cache = 0;
#  endif

   /* Currently, once a dynamic object, always a dynamic object.
    * This only will slow down such an object, it will still
    * look for the dynamic property, note it is not there, and
    * then do the 'regular thing'.
    */
   /* once an array always an array */

   if ( 0 != --(SEOBJECT_PTR(this)->used) )
   {
      if( elem_num < SEOBJECT_PTR(this)->used )
      {
         memmove((void *)SEOBJECTMEM_PTR(it),(void *)(SEOBJECTMEM_PTR(it)+1),
              (size_t)((SEOBJECT_PTR(this)->used-elem_num)*sizeof(struct _SEObjectMem)));
      }
   }

   /* Special case code for ECMA arrays - if we remove the highest numeric
    * entry, update the length to be the highest remaining entry
    */
   if( (SEOBJECT_PTR(this)->flags&IS_ARRAY) && IsNumericStringTableEntry(Name) )
   {
      struct _SEObjectMem *lengthMem = NULL;
      VarName lengthEntry = STOCK_STRING(length);
      struct _SEObjectMem *mem;
      JSE_POINTER_SINDEX MaxIdx;
      MemCountUInt x;

      MaxIdx = 0;
      for ( x=SEOBJECT_PTR(this)->used, mem = SEMEMBERS_PTR(wMembers); x--; mem++ )
      {
         VarName entry = mem->name;
         if( IsNumericStringTableEntry(entry) )
         {
            JSE_POINTER_SINDEX Idx = (JSE_POINTER_SINDEX)GetNumericStringTableEntry(entry);
            if ( MaxIdx < Idx )
               MaxIdx = Idx;
         }
         else if ( entry == lengthEntry )
         {
            lengthMem = mem;
         }
      }
      if ( NULL != lengthMem )
         /* Length is max index + 1, not MaxIdx */
         SEVAR_INIT_SLONG(&(lengthMem->value),MaxIdx+1);
   }
   SEMEMBERS_UNLOCK_W(wMembers);
   return True;
}


   jsebool NEAR_CALL
seobjFullDeleteMember(struct Call *call,hSEObject hobj,VarName member)
{
   wSEObject wobj;
   jsebool ret;
   SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);

#  if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
      if( SEOBJ_IS_DYNAMIC(wobj) )
      {
         /* this can be very inefficient, all the converting from wobj to robj,
          * but given the rarity of overriding _delete the inefficiency will
          * probably never be noticed.
          */
         rSEObject robj;
         SEOBJECT_UNLOCK_W(wobj);
         SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
         if ( seobjCallDynamicProperty(call,robj,dynacallDelete,member,NULL,NULL) )
         {
            SEOBJECT_UNLOCK_R(robj);
            return True;
         }
         SEOBJECT_UNLOCK_R(robj);
         SEOBJECT_ASSIGN_LOCK_W(wobj,hobj);
      }
#  endif
   ret = seobjDeleteMember(call,wobj,member,True);
   SEOBJECT_UNLOCK_W(wobj);
   return ret;
}

#define DYNARECURSE_TOO_DEEP  300

   static jsebool NEAR_CALL
preventRecursion(struct Call *call,hSEObject hobj,enum whichDynamicCall whichCall,
                 struct dynacallRecurse *recurStruct)
{
   /* if already doing this function return False, else link this new one in */
   struct dynacallRecurse *prev;

   for ( prev = call->Global->dynacallRecurseList; NULL != prev; prev = prev->prev )
   {
      if ( prev->whichObject == hobj  &&  prev->whichCall == whichCall )
      {
         /* been here before */
         return False;
      }
   }

   /* in a rare case that we're going way way too deep, stop it here */
   assert( call->Global->dynacallDepth < DYNARECURSE_TOO_DEEP );
   if ( DYNARECURSE_TOO_DEEP <= call->Global->dynacallDepth )
      return False;
   call->Global->dynacallDepth++;

   recurStruct->whichCall = whichCall;
   recurStruct->whichObject = hobj;
   recurStruct->prev = call->Global->dynacallRecurseList;
   call->Global->dynacallRecurseList = recurStruct;
   return True;
}

   static void NEAR_CALL
undoRecursion(struct Call *call,struct dynacallRecurse *recurStruct)
{
   assert( 0 < call->Global->dynacallDepth );
   call->Global->dynacallDepth--;
   call->Global->dynacallRecurseList = recurStruct->prev;;
}

/*
 * This is it, the dynamic property caller - all of the dynamic property
 * functions do some setup work then go through this call. It returns the
 * result into the given variable. A return of False means the
 * regular, default action should be taken.
 */
  jsebool NEAR_CALL
seobjCallDynamicProperty(struct Call *call,rSEObject robj,
                         enum whichDynamicCall whichCall,
                         VarName PropertyName,rSEVar Parameter2,
                         wSEVar  result)
{
   rSEObjectMem property;
   const struct jseObjectCallbacks *callbacks;
   hSEObject hobj;
   struct dynacallRecurse myRecurse;
   jsebool ret;
#  if !defined(NDEBUG) && defined(JSE_TRACKVARS) && JSE_TRACKVARS==1
      char *FILE = "ScriptEase runtime engine";
      int LINE = 0;
#  endif

   assert( result==NULL || sevarIsValid(call,result) );

   assert( SEOBJ_IS_DYNAMIC(robj) );

   if ( (SEOBJECT_PTR(robj)->flags & SEOBJ_DYNAMIC_UNDEFINED)!=0
     && whichCall < dynaBeginAlwaysCall )
   {
      /* If the member exists, do the 'regular thing' on it. */
      assert( PropertyName!=NULL );
      property = rseobjGetMemberStruct(call,robj,PropertyName);
      if ( NULL != SEOBJECTMEM_PTR(property) )
      {
         SEOBJECTMEM_UNLOCK_R(property);
         return False;
      }
   }

   hobj = SEOBJECT_HANDLE(robj);

   if( (callbacks=SEOBJECT_PTR(robj)->callbacks) != NULL )
   {
      wSEVar objtmp;
      jseVariable this;
      seAPIVar mark;
      jseString name;
      jseVariable value UNUSED_INITIALIZER(NULL);
      jseVariable ret;
      jsebool done;

      /* if this has a callback structure, then whether to go or not
       * depends on if that entry point is NULL.  If it is NULL then
       * return False to do the regular thing.  This next statement
       * relies on the fields in the callback structure being in
       * the same order as enum whichDynamicCall.
       */
      if ( NULL == ((void **)callbacks)[whichCall] )
         /* there is no entry for this function.  Don't call it. */
         goto no_callback;

      /* if already doing this function then don't do it again */
      if ( !preventRecursion(call,hobj,whichCall,&myRecurse) )
	return False;

      mark = call->tempvars;
      name = PropertyName ? callApiStringEntry(call,PropertyName) : NULL ;
      ret = NULL;
      done = True;

      if ( dynacallGet == whichCall )
      {
         /* parameter2 is really a boolean */
      }
      else
      {
         value = Parameter2
               ? SEAPI_RETURN(call,Parameter2,FALSE,UNISTR("Internal: Dynamic Function Call"))
               : NULL ;
      }

#     ifndef NDEBUG
         if( dynacallDefaultvalue == whichCall )
         {
            assert( name==NULL );
         }
         else
         {
            assert( name!=NULL );
         }
#     endif

      objtmp = STACK_PUSH;
      SEVAR_INIT_OBJECT(objtmp,hobj);
      this = SEAPI_RETURN(call,objtmp,FALSE,UNISTR("Internal: Dynamic Function Call"));
      STACK_POP;

#     ifndef NDEBUG
         if( dynacallPut == whichCall
#         if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
          || dynacallOperator == whichCall
#         endif
          || dynacallDefaultvalue == whichCall )
         {
            assert( Parameter2!=NULL );
         }
         else if ( dynacallGet == whichCall )
         {
            assert( False == (jsebool)(JSE_POINTER_UINT)Parameter2 \
                 || True == (jsebool)(JSE_POINTER_UINT)Parameter2 );
         }
         else
         {
            assert( Parameter2==NULL );
         }
#     endif

#     if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) \
      && (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
#        define DYNA_CALLBACK1(FUNC,PARM1) \
            DispatchToClient(call->Global->ExternalDataSegment,(ClientFunction)(FUNC),\
                             (void *)call,this,(PARM1),NULL)
#        define DYNA_CALLBACK2(FUNC,PARM1,PARM2) \
            DispatchToClient(call->Global->ExternalDataSegment,(ClientFunction)(FUNC),\
                             (void *)call,this,(PARM1),(PARM2))
#     else
#        define DYNA_CALLBACK1(FUNC,PARM1) (FUNC)(call,this,(PARM1))
#        define DYNA_CALLBACK2(FUNC,PARM1,PARM2) (FUNC)(call,this,(PARM1),(PARM2))
#     endif

      switch( whichCall )
      {
         case dynacallGet:
            ret = DYNA_CALLBACK2(callbacks->get,name,(jsebool)(JSE_POINTER_UINT)Parameter2);
            if( ret==NULL ) done = False;
            assert( result!=NULL );
            break;
         case dynacallPut:
            done = DYNA_CALLBACK2(callbacks->put,name,value);
            assert( result==NULL );
            break;
         case dynacallCanput:
         {  jsebool cp = DYNA_CALLBACK1(callbacks->canPut,name);
            assert( result!=NULL );
            SEVAR_INIT_BOOLEAN(result,cp);
         }  break;
         case dynacallHas:
         {
            int cp = DYNA_CALLBACK1(callbacks->hasProp,name);
            assert( result!=NULL );
            if( cp==-1 )
               done = False;
            else
               SEVAR_INIT_BOOLEAN(result,cp);
         }  break;
         case dynacallDelete:
            done = DYNA_CALLBACK1(callbacks->deleteFunc,name);
            assert( result==NULL );
            break;
         case dynacallDefaultvalue:
            ret = (jseVariable)DYNA_CALLBACK1(callbacks->defaultValue,value);
            if( ret==NULL ) done = False;
            assert( result!=NULL );
            break;
#        if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
         case dynacallOperator:
            ret = (jseVariable)DYNA_CALLBACK2(callbacks->operatorFunc,name,value);
            if( ret==NULL ) done = False;
            assert( result!=NULL );
            break;
#        endif
#        ifndef NDEBUG
            default: assert( False );
#        endif
      }

      undoRecursion(call,&myRecurse);

      if( ret!=NULL )
      {
         rSEVar delvar = seapiGetValue(call,ret);
         done = ( SEVAR_GET_TYPE(delvar)!=VObject ||
                  SEVAR_GET_OBJECT(delvar)!=call->hDynamicDefault );
         if( done && result!=NULL )
         {
            SEVAR_COPY(result,delvar);
         }
         seapiDeleteVariable(call,ret);
      }

      if( name!=NULL ) callRemoveApiStringEntry(call,name);

      CALL_KILL_TEMPVARS(call,mark);

      return ( done || CALL_QUIT(call) );
   }

 no_callback:
   {
      /* get the property for this whichCall, relying on the following array to
       * match the same order as enum whichDynamicCall
       */
      static VarName whichDynamicNames[] = {
         STOCK_STRING(_get)
        ,STOCK_STRING(_put)
        ,STOCK_STRING(_canPut)
        ,STOCK_STRING(_hasProperty)
        ,STOCK_STRING(_delete)
        ,STOCK_STRING(_defaultValue)
#        if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
        ,STOCK_STRING(_operator)
#        endif
      };
      property = seobjChildMemberStruct(call,robj,whichDynamicNames[whichCall]);

      if ( NULL == SEOBJECTMEM_PTR(property)
        || SEVAR_GET_TYPE(SEOBJECTMEM_VAR(property))!=VObject
        || !SEVAR_IS_FUNCTION(call,SEOBJECTMEM_VAR(property)) )
      {
#        if 0!=JSE_MEMEXT_MEMBERS
            if ( NULL != SEOBJECTMEM_PTR(property) )
               SEOBJECTMEM_UNLOCK_R(property);
#        endif
         return False;
      }
      assert( sevarIsValid(call,SEOBJECTMEM_VAR(property)) );
   }

   /* if already doing this function then don't do it again */
   if ( !preventRecursion(call,hobj,whichCall,&myRecurse) )
   {
      SEOBJECTMEM_UNLOCK_R(property);
      ret = False;
   }
   else
   {
      uword8 RememberReasonToQuit = call->state;
      uword16 depth = 0;
      /* Basically because destructors can be called during error condition */
      wSEVar namevar;
      const jsecharptr nameval;
      wSEVar tmp;

      CALL_SET_ERROR(call,FlowNoReasonToQuit);

      /* push this */
      tmp = STACK_PUSH;
      SEVAR_INIT_OBJECT(tmp,hobj);

      /* push function */
      tmp = STACK_PUSH;
      SEVAR_COPY(tmp,SEOBJECTMEM_VAR(property));
      SEOBJECTMEM_UNLOCK_R(property);

      if( PropertyName!=NULL )
      {
         stringLengthType PropertyNameLen;
         depth = 1;
         namevar = STACK_PUSH;
         nameval = GetStringTableEntry(call,PropertyName,&PropertyNameLen);
         SEVAR_INIT_STRING_STRLEN(call,namevar,(jsecharptr)nameval,PropertyNameLen);
      }

      if ( dynacallGet == whichCall )
      {
         /* for get the second parameter is really a boolean hint variable */
         wSEVar hintVar = STACK_PUSH;
         SEVAR_INIT_BOOLEAN(hintVar,(jsebool)(JSE_POINTER_UINT)Parameter2);
         depth++;
      }
      else if ( NULL != Parameter2 )
      {
         namevar = STACK_PUSH;
         SEVAR_COPY(namevar,Parameter2);
         depth++;
      }

      callFunctionFully(call,depth,False);

      /* check the result against 'DYN_DEFAULT' and if so, eventually
       * return False, else return True, if False, don't overwrite
       * return value
       */

      tmp = STACK0;
      if( SEVAR_GET_TYPE(tmp)==VObject &&
          SEVAR_GET_OBJECT(tmp)==call->hDynamicDefault )
      {
         ret = False;
      }
      else
      {
         ret = True;
         if( result!=NULL )
         {
            SEVAR_COPY(result,tmp);
         }
      }

      /* discard result and tmp */
      STACK_POP;

      undoRecursion(call,&myRecurse);

      /* Don't restore a valid quit reason if calling a destructor failed -
       * that's still a failure
       */
      if( !CALL_QUIT(call) )
         CALL_SET_ERROR(call,RememberReasonToQuit);
   }
   return ret;
}

/* Must provide a variable that will be destroyed later */
   static void NEAR_CALL
sevarDefaultValue(struct Call *call,wSEVar this,jseVarType hintType)
{
   int count;
   rSEObjectMem valuemem;
   jsebool hintstring = (VString == hintType);
   rSEObject robj;
   hSEObject hobj = SEVAR_GET_OBJECT(this);

   assert( sevarIsValid(call,this) );
   assert( VObject == SEVAR_GET_TYPE(this) );

   SEOBJECT_ASSIGN_LOCK_R(robj,hobj);

   /* check to see if its one of the ECMA ones. This means a BIG
    * performance boost to not have to call the function
    */
   valuemem = rseobjGetMemberStruct(call,robj,STOCK_STRING(_value));
   if( NULL != SEOBJECTMEM_PTR(valuemem) )
   {
      /* only valid if this is same type as return wanted */
      if ( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(valuemem)) == (hintstring ? VString : VNumber) )
      {
         SEVAR_COPY(this,SEOBJECTMEM_VAR(valuemem));

         if( hintstring )
         {
            /* Make a copy of the data */
            sevarDuplicateString(call,this);
         }

         SEOBJECTMEM_UNLOCK_R(valuemem);
         SEOBJECT_UNLOCK_R(robj);
         return;
      }
      SEOBJECTMEM_UNLOCK_R(valuemem);
   }

   if( SEOBJ_IS_DYNAMIC(robj) )
   {
      /* call the default value routine */
      wSEVar hint = STACK_PUSH;
      /* Ahhh! God knows how long it took to track this one down... */
      /* hint->type = (jseVarType)(hintstring?VString:VNumber); */
      if( hintstring )
      {
#        if defined(JSE_MBCS) && (JSE_MBCS!=0)
            SEVAR_INIT_STRING(call,hint,UNISTR(""),0,0);
#        else
            SEVAR_INIT_STRING(call,hint,UNISTR(""),0);
#        endif
      }
      else if( VNumber == hintType )
      {
         SEVAR_INIT_NUMBER(hint,jseZero);
      }
      else
      {
         SEVAR_INIT_UNDEFINED(hint);
      }

      if( seobjCallDynamicProperty(call,robj,dynacallDefaultvalue,
                                   NULL,hint,this) )
      {
         STACK_POP;

         if( SEVAR_GET_TYPE(this) == VObject )
         {
            callQuit(call,textcoreDEFAULTVALUE_RETURN_PRIMITIVE,DEFAULT_PROPERTY);
            SEVAR_INIT_UNDEFINED(this);
         }
         SEOBJECT_UNLOCK_R(robj);
         return;
      }
      else
      {
         STACK_POP;
      }
   }

   /* if not, do the standard thing, which is to call valueof or tostring, whichever
    * one first succeeds at returning a primitive, trying tostring first if hinstring
    * else trying tovalue
    */
   for( count = 0; count < 2; count++, hintstring = !hintstring )
   {
      rSEObjectMem tostring;
      VarName funcname = (hintstring)
                       ? STOCK_STRING(toString)
                       : STOCK_STRING(valueOf) ;

#     if JSE_MEMEXT_OBJECTS!=0
         if ( NULL == SEOBJECT_PTR(robj) )
            SEOBJECT_ASSIGN_LOCK_R(robj,hobj);
#     endif      

      tostring = seobjChildMemberStruct(call,robj,funcname);
      if ( NULL != SEOBJECTMEM_PTR(tostring) )
      {
         if ( SEVAR_IS_FUNCTION(call,SEOBJECTMEM_VAR(tostring)))
         {
            rSEVar ret;
            wSEVar tmp;

            /* 'this' is the this */
            tmp = STACK_PUSH;
            SEVAR_COPY(tmp,this);
            tmp = STACK_PUSH;
            SEVAR_COPY(tmp,SEOBJECTMEM_VAR(tostring));

            SEOBJECTMEM_UNLOCK_R(tostring);

#           if JSE_MEMEXT_OBJECTS!=0
               SEOBJECT_UNLOCK_R(robj);
               SEOBJECT_PTR(robj) = NULL;
#           endif               
            callFunctionFully(call,0,False);

            /* if the return variable is a primitive (i.e. not object) then it is OK,
             * else throw it back and try again
             */
            ret = STACK0;
            if( SEVAR_GET_TYPE(ret)!=VObject )
            {
               SEVAR_COPY(this,ret);
               STACK_POP;
               break;
            }
            else
            {
               STACK_POP;
            }
         }
         else
         {
            SEOBJECTMEM_UNLOCK_R(tostring);
         }
      }
   }
#  if JSE_MEMEXT_OBJECTS!=0
      if ( NULL != SEOBJECT_PTR(robj) )
         SEOBJECT_UNLOCK_R(robj);
#  endif               
   if( count == 2 )
   {
      /* unable to convert this to a primitive */
#     if !defined(JSE_SHORT_RESOURCE) || (0==JSE_SHORT_RESOURCE)
         jsechar VarName[60];
         if ( FindNames(call,this,JSECHARPTR_NEXT((jsecharptr)VarName),
                        sizeof(VarName)/sizeof(VarName[0])-5,UNISTR("")) )
         {
            VarName[0] = '(';
            strcat_jsechar((jsecharptr)VarName,UNISTR(") "));
         }
         callQuit(call,textcoreNO_DEFAULT_VALUE,VarName);
#     else
         callQuit(call,textcoreNO_DEFAULT_VALUE,"");
#     endif
         SEVAR_INIT_UNDEFINED(this);
   }
}



/* Check if the property exists. If 'dest' is not NULL, also get
 * the value of the property to it. The reason? After checking for
 * the property, we will use it. Since checking for it entails
 * finding it, we can just give the value too, rather than looking
 * for it again.
 */
   jsebool NEAR_CALL
seobjHasProperty(struct Call *call,rSEObject robj,VarName propname,wSEVar dest,
                 int flags)
{
   jsebool handled = False;
   rSEObjectMem it;
#  if defined(JSE_DYNAMIC_OBJS)
   jsebool has_says_yes = False;
#  endif

   if( dest ) SEVAR_INIT_UNDEFINED(dest);
   assert( sevarIsValid(call,dest) );

#  if defined(JSE_DYNAMIC_OBJS)
   if( SEOBJ_IS_DYNAMIC(robj) )
   {
      wSEVar value = STACK_PUSH;
      jsebool ret;

      SEVAR_INIT_UNDEFINED(value);
      /* Make sure that we initialize it in case GC happens */
      handled = seobjCallDynamicProperty(call,robj,dynacallHas,propname,NULL,value);

      /* If we don't need the value, just return whether it has it
       * or not. If not found, return that. Else we need to also
       * return the actual value. If the hasProperty routine returns
       * True, but we cannot actually find the property, the routine
       * will actually return False. This routine cares whether or
       * not the result can be gotten, not what hasProperty says.
       * Basically, hasProperty has the opportunity to return False,
       * and that's it.
       */
      /* mgroeber: somewhat rearranged to short circuit if handled==False */
      if(handled)
      {
	 ret = (jsebool)JSE_FP_CAST_TO_SLONG(SEVAR_GET_NUMBER_VALUE(value));
	 STACK_POP;
	 if(ret==False || dest==NULL) return ret;
      }
      else
	 STACK_POP;

      /* Call the 'get' to get the property */

      if( handled && (flags&HP_REFERENCE)!=0 && dest!=NULL )
      {
         SEVAR_INIT_REFERENCE(dest,SEOBJECT_HANDLE(robj),propname);
         return True;
      }
      if( handled ) has_says_yes = True;
   }
   /* pass hint about whether this is being retrieved to be called
    * as a function
    */
   if( SEOBJ_IS_DYNAMIC(robj) )
   {
      /* got to do a dynamic get because we need the value */
      wSEVar rhs = STACK_PUSH;


      SEVAR_INIT_OBJECT(rhs,SEOBJECT_HANDLE(robj));
      if( dest==NULL ) dest = rhs;
      /* can't use SEVAR_DEREFERENCE because this
       * could be a real dynamic object
       */

      if( seobjCallDynamicProperty(call,robj,dynacallGet,propname,False,dest) )
      {
         /* If hasProperty says yes, then undefined means undefined. Otherwise,
          * Undefined is the only way to differentiate a has it from does not
          * have it.
          */
         jsebool ret = (SEVAR_GET_TYPE(dest)!=VUndefined) || has_says_yes;
         if( (flags&HP_REFERENCE)!=0 && dest!=rhs )
         {
            SEVAR_INIT_REFERENCE(dest,SEOBJECT_HANDLE(robj),propname);
         }
         STACK_POP;
         return ret;
      }
      STACK_POP;
   }
#  endif
   if( ((flags&HP_NO_PROTOTYPE)==0 &&
        SEOBJECTMEM_PTR(it = seobjChildMemberStruct(call,robj,propname)) != NULL) ||
       ((flags&HP_NO_PROTOTYPE)!=0 &&
        SEOBJECTMEM_PTR(it = rseobjGetMemberStruct(call,robj,propname)) != NULL) )
   {
      if( dest )
      {
         if( (flags&HP_REFERENCE)!=0 )
         {
            if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(it))>=VReference )
               SEVAR_COPY(dest,SEOBJECTMEM_VAR(it));
            else
               SEVAR_INIT_REFERENCE(dest,SEOBJECT_HANDLE(robj),propname);
         }
         else
         {
            SEVAR_COPY(dest,SEOBJECTMEM_VAR(it));
            SEVAR_DEREFERENCE(call,dest);
         }
         assert( sevarIsValid(call,dest) );
      }
      SEOBJECTMEM_UNLOCK_R(it);
      return True;
   }
   return False;
}
