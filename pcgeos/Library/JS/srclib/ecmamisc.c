/* ecmamisc.c
 *
 * Set of miscellaneous global functions for the Ecma library.  Contains source
 * for the following:
 *   eval, parseInt, parseFloat, escape, unescape, isNaN, isFinite
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

/* extern means it is defined elsewhere and only declared here. By
 * definition, if you have an initializer, it is not extern
 */
CONST_STRING(InsufficientMemory,"0003: Insufficient Memory to continue operation.");

#if defined(JSE_ECMAMISC_ANY)

/* eval() */
#if defined(JSE_ECMAMISC_EVAL)
static jseLibFunc(Ecma_eval)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable ReturnVar;
   const jsecharptr text;


   if( v==NULL || jseGetType(jsecontext,v)!=jseTypeString )
   {
      jseReturnVar(jsecontext,jseCreateSiblingVariable(jsecontext,v,0),jseRetTempVar);
      return;
   }

   text = (const jsecharptr )jseGetString(jsecontext,v,NULL);
   if ( !jseInterpret(jsecontext,NULL,text,NULL,
                      jseNewNone,JSE_INTERPRET_KEEPTHIS|JSE_INTERPRET_TRAP_ERRORS,
                      NULL,&ReturnVar))
   {
      /* error parsing it - make an error in the context. */
      /* replace that error with the existing error object */
      if( ReturnVar!=NULL )
      {
         jseReturnVar(jsecontext,ReturnVar,jseRetTempVar);
      }
      jseLibSetErrorFlag(jsecontext);
      return;
   }
   else
   {
      assert( NULL != ReturnVar );
   }
   jseReturnVar(jsecontext,ReturnVar,jseRetTempVar);
}
#endif

/* parseInt() */
#if defined(JSE_ECMAMISC_PARSEINT)
static jseLibFunc(Ecma_parseInt)
{
   jseVariable strvar;
   jsecharptr str;
   jsebool isNeg = False;
   long radix = 0;
   jsenumber fradix;
   jsenumber result = jseNaN;

   if ( 0 < jseFuncVarCount(jsecontext) )
   {
      JSE_FUNC_VAR_NEED(strvar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      str = ( jsecharptr )jseGetString( jsecontext, strvar, NULL);

      SKIP_WHITESPACE(str);

      if( JSECHARPTR_GETC(str) == UNICHR('-') || JSECHARPTR_GETC(str) == UNICHR('+') )
      {
         if( JSECHARPTR_GETC(str) == UNICHR('-') )
            isNeg = True;
         JSECHARPTR_INC(str);
      }


      if( 1 < jseFuncVarCount(jsecontext) )
      {
         jseVariable r = jseCreateConvertedVariable(jsecontext,jseFuncVar(jsecontext,1),
                                                    jseToInt32);

         if( jseQuitFlagged(jsecontext) )
            return;

         radix = jseGetLong(jsecontext,r);
         jseDestroyVariable(jsecontext,r);

         if( radix != 0 && (radix<2 || radix>36) )
         {
            result = jseNaN; radix = -1;
         }
      }

      if( radix!=-1 )
      {
         int ok;

         if( radix==0 )
         {
            radix = 10;

            if( '0' == JSECHARPTR_GETC(str) )
            {
               radix = 8;

               if( 'X' == toupper_jsechar(JSECHARPTR_GETC(JSECHARPTR_NEXT(str))) )
               {
                  str = JSECHARPTR_OFFSET(str,2);
                  radix = 16;
               }
            }
         }

         if (radix == 16)
         {
            if ( '0' == JSECHARPTR_GETC(str) &&
               'X' == toupper_jsechar(JSECHARPTR_GETC(JSECHARPTR_NEXT(str))))
                  str = JSECHARPTR_OFFSET(str,2);
         }
         result = jseZero;
         ok = 0;
         fradix = JSE_FP_CAST_FROM_SLONG(radix);
         while( JSECHARPTR_GETC(str) )
         {
            int val;

            if( isdigit_jsechar(JSECHARPTR_GETC(str)))
            {
               val = JSECHARPTR_GETC(str)-'0';
            }
            else
            {
               val = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
            }
            JSECHARPTR_INC(str);

            if( val<0 || val>radix-1 ) break;
            ok = 1;
            result = JSE_FP_ADD(JSE_FP_MUL(fradix,result),JSE_FP_CAST_FROM_SLONG(val));
         }
         if( !ok ) result = jseNaN;
      }
   }
   if ( isNeg  &&  !jseIsNaN(result) )
   {
      result = JSE_FP_NEGATE(result);
   }
   jseReturnNumber(jsecontext,result);
}
#endif


/* parseFloat() */
#ifdef JSE_ECMAMISC_PARSEFLOAT
/* This function is basically identical to 'ToNumber' for strings. */
static jseLibFunc(Ecma_parseFloat)
{
   jseVariable strvar;
   jsecharptr str;
   jsecharptr parseEnd;
   jsenumber val;

   if ( jseFuncVarCount(jsecontext) < 1 )
   {
      val = jseNaN;
   }
   else
   {
      jsebool neg;
      JSE_FUNC_VAR_NEED(strvar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      str = ( jsecharptr )jseGetString( jsecontext, strvar, NULL);

      SKIP_WHITESPACE(str);

      if ( '-' == JSECHARPTR_GETC(str) )
      {
         JSECHARPTR_INC(str);
         neg = True;
      }
      else
      {
         neg = False;
         if ( '+' == JSECHARPTR_GETC(str) )
         {
            JSECHARPTR_INC(str);
         }
      }

      val = JSE_FP_STRTOD(str,(jsecharptrdatum **)&parseEnd);
      if ( jseIsZero(val) )
      {
         if ( parseEnd == str )
         {
            /* either parsed nothing, or Infinity */
            val = strncmp_jsechar(str,UNISTR("Infinity"),8) ? jseNaN : jseInfinity ;
         }
      }
      if ( neg  &&  !jseIsNaN(val) )
         val = JSE_FP_NEGATE(val);
   }
   jseReturnNumber(jsecontext,val);
}
#endif


#  define CHARS_OK UNISTR("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./")

/* escape() */
#ifdef JSE_ECMAMISC_ESCAPE
static jseLibFunc(Ecma_escape)
{
   jseVariable ret;

   if ( jseFuncVarCount(jsecontext) < 1 )
   {
      /* if no parameter passed in then return string "undefined" */
      ret = jseCreateVariable(jsecontext,jseTypeString);
      jsePutString(jsecontext,ret,UNISTR("undefined"));
   }
   else
   {
      jseVariable strvar;
      jsecharptr str;
      JSE_POINTER_UINDEX srcLength;

      JSE_FUNC_VAR_NEED(strvar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      str = (jsecharptr)jseGetString( jsecontext, strvar, &srcLength);

      ret = jseCreateVariable(jsecontext,jseTypeString);

      if ( 0 != srcLength )
      {
         jsecharptr string = NULL;
         uint x, count = 0;
         jsechar c;

         for( x=0;x<srcLength;x++, JSECHARPTR_INC(str) )
         {
            if( (0 != (c=JSECHARPTR_GETC(str)))  &&  strchr_jsechar(CHARS_OK,c))
            {
               string = jseMustReMalloc(jsecharptrdatum,string,BYTECOUNT_FROM_STRLEN(string,count)+2*sizeof(jsechar));
               JSECHARPTR_PUTC(JSECHARPTR_OFFSET(string,count),c);
               count++;
            }
            else
            {
               jsechar buffer[20];
               jsecharptr tmp;
               jsecharptr current;

#              if (defined(JSE_UNICODE) && (0!=JSE_UNICODE)) \
               || (defined(JSE_MBCS) && (0!=JSE_MBCS))
                  if( 0xFF<c )
                  {
                     jsechar c1 = (jsechar)((c&0xF000)>>12),
                             c2 = (jsechar)((c&0x0F00)>>8),
                             c3 = (jsechar)((c&0x00F0)>>4),
                             c4 = (jsechar)(c&0x000F);

                     tmp = (jsecharptr) buffer;
                     JSECHARPTR_PUTC(tmp,'%');
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,'u');
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((c1<0x0A) ? '0' + c1 : 'A' + (c1 - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((c2<0x0A) ? '0' + c2 : 'A' + (c2 - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((c3<0x0A) ? '0' + c3 : 'A' + (c3 - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((c4<0x0A) ? '0' + c4 : 'A' + (c4 - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,'\0');

                     string = jseMustReMalloc(jsecharptrdatum,string,
                                              (string == NULL ? 0 : BYTECOUNT_FROM_STRLEN(string,count))+
                                              bytestrlen_jsechar((jsecharptr)buffer)+
                                              sizeof(jsechar));
                     current = JSECHARPTR_OFFSET(string,count);
                     tmp = (jsecharptr) buffer;

                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));

                     count += 6;
                  }
                  else
#              endif
                  {
                     jsechar hi = (jsechar)((c&0xF0)>>4),
                             lo = (jsechar)(c&0x0F);

                     tmp = (jsecharptr) buffer;
                     JSECHARPTR_PUTC(tmp,'%');
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((hi<0x0A) ? '0' + hi : 'A' + (hi - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,(jsechar)((lo<0x0A) ? '0' + lo : 'A' + (lo - 0x0A)));
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(tmp,'\0');

                     string = jseMustReMalloc(jsecharptrdatum,string,
                                              (string == NULL ? 0 : BYTECOUNT_FROM_STRLEN(string,count))+
                                              bytestrlen_jsechar((jsecharptr)buffer)+
                                              sizeof(jsechar));
                     current = JSECHARPTR_OFFSET(string,count);
                     tmp = (jsecharptr) buffer;

                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));
                     JSECHARPTR_INC(current);
                     JSECHARPTR_INC(tmp);
                     JSECHARPTR_PUTC(current,JSECHARPTR_GETC(tmp));

                     count += 3;
                  }
            }
         }
         assert( NULL != string );
         jsePutStringLength(jsecontext,ret,string,count);
         jseMustFree(string);
      }
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

/* unescape() */
#ifdef JSE_ECMAMISC_UNESCAPE
static jseLibFunc(Ecma_unescape)
{
   jseVariable ret;

   if ( jseFuncVarCount(jsecontext) < 1 )
   {
      /* if no parameter passed in then return string "undefined" */
      ret = jseCreateVariable(jsecontext,jseTypeString);
      jsePutString(jsecontext,ret,UNISTR("undefined"));
   }
   else
   {
      jseVariable strvar;
      jsecharptr str;
      jsecharptr string = NULL;
      JSE_POINTER_UINDEX count, x, strLength;

      JSE_FUNC_VAR_NEED(strvar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
      str = (jsecharptr)jseGetString(jsecontext,strvar,&strLength);

      ret = jseCreateVariable(jsecontext,jseTypeString);

      count = 0;
      for( x=0; x < strLength; x++, JSECHARPTR_INC(str) )
      {
         jsecharptr current;
         jsecharptr newString = ( NULL == string )
                              ? jseMustMalloc(jsecharptrdatum,sizeof(jsechar))
                              : jseMustReMalloc(jsecharptrdatum,string,(count+1)*sizeof(jsechar)) ;
         string = newString;
         current = JSECHARPTR_OFFSET((jsecharptr)newString,count);
         count++;

         JSECHARPTR_PUTC(current,JSECHARPTR_GETC(str));
         if( '%' == JSECHARPTR_GETC(str) )
         {
            int v1,v2,v3,v4;

            JSECHARPTR_INC(str);

            /* check to see if it is a unicode escaped character (indicated by a 'u') */
            if( JSECHARPTR_GETC(str) == 'u' )
            {
               JSECHARPTR_INC(str);

               if( JSECHARPTR_GETC(str) >='A' )
                  v1 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v1 = JSECHARPTR_GETC(str)-'0';

               JSECHARPTR_INC(str);

               if( JSECHARPTR_GETC(str)>='A' )
                  v2 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v2 = JSECHARPTR_GETC(str)-'0';

               JSECHARPTR_INC(str);

               if( JSECHARPTR_GETC(str)>='A' )
                  v3 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v3 = JSECHARPTR_GETC(str)-'0';

               JSECHARPTR_INC(str);

               if( JSECHARPTR_GETC(str)>='A' )
                  v4 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v4 = JSECHARPTR_GETC(str)-'0';

               x += 5;
               JSECHARPTR_PUTC(current,(jsechar)(v1*0x1000 + v2*0x100 + v3*0x10 + v4));

            }
            else
            {
               if( JSECHARPTR_GETC(str) >='A' )
                  v1 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v1 = JSECHARPTR_GETC(str)-'0';

               JSECHARPTR_INC(str);

               if( JSECHARPTR_GETC(str)>='A' )
                  v2 = toupper_jsechar(JSECHARPTR_GETC(str))-'A'+10;
               else
                  v2 = JSECHARPTR_GETC(str)-'0';

               x += 2;
               JSECHARPTR_PUTC(current,(jsechar)(v1*16+v2));
            }
         }
      }

      jsePutStringLength(jsecontext,ret,string,count);
      if ( NULL != string )
         jseMustFree(string);
   }

   jseReturnVar(jsecontext,ret,jseRetTempVar);
}
#endif

/* isNaN() */
#ifdef JSE_ECMAMISC_ISNAN
static jseLibFunc(Ecma_isNaN)
{
   jseVariable num;
   jsenumber val;
   jseVariable retVar;

   JSE_FUNC_VAR_NEED(num,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
   if( !jseQuitFlagged(jsecontext) )
   {
      val = jseGetNumber(jsecontext,num);
      retVar = jseCreateVariable(jsecontext,jseTypeBoolean);
      jsePutBoolean(jsecontext,retVar, jseIsNaN(val) );
      jseReturnVar(jsecontext,retVar,jseRetTempVar);
   }
}
#endif

/* isFinite() */
#ifdef JSE_ECMAMISC_ISFINITE
static jseLibFunc(Ecma_isFinite)
{
   jseVariable num;
   jsenumber val;
   jseVariable retVar;

   JSE_FUNC_VAR_NEED(num,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_NUMBER));
   if( !jseQuitFlagged(jsecontext) )
   {
      val = jseGetNumber(jsecontext,num);
      retVar = jseCreateVariable(jsecontext,jseTypeBoolean);
      jsePutBoolean(jsecontext,retVar, jseIsFinite(val) );
      jseReturnVar(jsecontext,retVar,jseRetTempVar);
   }
}
#endif



/* URI encode/decode functions */

#if defined(JSE_ECMAMISC_DECODEURI) || defined(JSE_ECMAMISC_DECODEURICOMPONENT)

static ulong
OctetsToUlong( jsechar *octets, uint octetCount )
{
   ulong val = 0;

   assert( 4>=octetCount );

   if( 1==octetCount )
      val = octets[0];
   else if( 2==octetCount )
   {
      val |= (0x1F & octets[0]) << 6;
      val |= (0x3F & octets[1]);
   }
   else if( 3==octetCount )
   {
      val |= (0x0F & octets[0]) << 12;
      val |= (0x3F & octets[1]) << 6;
      val |= (0x3F & octets[2]);
   }
   else if( 4==octetCount )
   {
      uint valA, valB;
      uint u = 0;

      valA = 0xD800;
      valB = 0xDC00;

      u |= ((0x03 & octets[0]) << 2) | ((0x30 & octets[1]) >> 4);
      valA |= (u-1) << 6;
      valA |= (0x0F & octets[2]) << 2;
      valA |= (0x30 & octets[2]) >> 4;

      valB |= (0x0F & octets[2]) << 6;
      valB |= (0x3F & octets[3]);

      val = (valA << 16) | valB;
   }

   return val;
}

/* URIDecode, used by decodeURI and decodeURIComponent */
#define URIDECODE_COPY_BUFFER_SIZE 50
static jsecharptr
URIDecode(jsecharptr uri,jsecharptr unescapedSet)
{
   /* variable naming conventions & function algorithm based on psueudocode from the
      ECMAScript Language Specification, section 15.1.3 */
   uint uriLen;
   jsecharptr decodedURIStr = NULL;
   uint k;
   jsecharptr currCharPtr = uri;
   jsechar s[URIDECODE_COPY_BUFFER_SIZE];
   jsebool oneChar;

   uriLen = strlen_jsechar(uri);

   k = 0;

   while( k!=uriLen )
   {
      jsechar c = JSECHARPTR_GETC(currCharPtr);
      jsechar c1, c2;
      jsechar b;

      oneChar = False;

      if( '%'==c )
      {
         jsecharptr start = currCharPtr;

         if( k+2>=uriLen )
            /* bad!  We need to have at least three characters ('%xy') */
            goto URIError;

         /* fetch the next two characters in the string to be decoded */
         JSECHARPTR_INC(currCharPtr);
         c1 = (jsechar)toupper_jsechar(JSECHARPTR_GETC(currCharPtr));
         JSECHARPTR_INC(currCharPtr);
         c2 = (jsechar)toupper_jsechar(JSECHARPTR_GETC(currCharPtr));

         /* make sure the characters are valid hexadecimal */
         if( (!((((c1>='0') && (c1<='9')) || ((c1>='A') && (c1<='F'))) &&
                (((c2>='0') && (c2<='9')) || ((c2>='A') && (c2<='F'))))) )
            /* signal that we need to throw an exception */
            goto URIError;

         /* combine the characters into a hexadecimal number */
         b = (jsechar)((c1>='0') && (c1<='9') ? c1 - '0' : c1 - 'A' + 0x0A);
         b <<= 4;
         b |= (c2>='0') && (c2<='9') ? (jsechar)(c2 - '0') : (jsechar)(c2 - 'A' + 0x0A);

         k += 2;

         if( 0x80<=(ujsechar)b )
         {
            uint n, j;
            jsechar octets[4];
            ulong v;

            /* compute smallest non-negative integer n such that (B << n) & 0x80 is zero */
            n = 1;

            while( (4>=n) && (0!=(jsechar)(((b<<n)&0x80))) )
               n++;

            if( (1==n) || (4<n) || (k + (3 * (n - 1)) >= uriLen) )
               /* signal that we need to throw an exception */
               goto URIError;

            octets[0] = b;

            j = 1;

            while( j<n )
            {
               ++k;

               if( k+2>=uriLen )
                  /* bad!  We need to have at least three characters ('%xy') */
                  goto URIError;

               JSECHARPTR_INC(currCharPtr);
               c = JSECHARPTR_GETC(currCharPtr);

               JSECHARPTR_INC(currCharPtr);
               c1 = (jsechar)toupper_jsechar(JSECHARPTR_GETC(currCharPtr));
               JSECHARPTR_INC(currCharPtr);
               c2 = (jsechar)toupper_jsechar(JSECHARPTR_GETC(currCharPtr));
               if( ('%'!=c) ||
                  (!((((c1>='0') && (c1<='9')) || ((c1>='A') && (c1<='F'))) &&
                     (((c2>='0') && (c2<='9')) || ((c2>='A') && (c2<='F'))))) )
                  /* throw an exception because the next character didn't indicate an
                     escape sequence, or the characters that followed weren't hex */
                  goto URIError;

               /* combine the characters into a hexadecimal number */
               b = (jsechar)((c1>='0') && (c1<='9') ? c1 - '0' : c1 - 'A' + 0x0A);
               b <<= 4;
               b |= (c2>='0') && (c2<='9') ? (jsechar)(c2 - '0') : (jsechar)(c2 - 'A' + 0x0A);

               if( 0x80 != (b & 0xC0) )
                  /* two most significant bits must be 10 */
                  goto URIError;

               k+=2;
               octets[j] = b;

               ++j;
            }

            v = OctetsToUlong( octets, n );

            if( 0x10000<=v )
            {
               ulong l,h;
               jsecharptr tmp = (jsecharptr)s;

               if( 0x10FFFF<v )
                  goto URIError;

               l = (((v - 0x10000) & 0x03FF) + 0xDC00);
               h = ((((v - 0x10000) >> 10) & 0x03FF) + 0xD800);

               assert( l<=0xFFFF );
               assert( h<=0xFFFF );

               JSECHARPTR_PUTC(tmp,(jsechar)h);
               JSECHARPTR_INC(tmp);
               JSECHARPTR_PUTC(tmp,(jsechar)l);
               JSECHARPTR_INC(tmp);
               JSECHARPTR_PUTC(tmp,'\0');
            }
            else
            {
               c = (jsechar)v;
               oneChar = True;
            }
         }
         else
         {
            c = b;
            oneChar = True;
         }

         if( oneChar )
         {
            if( NULL==strchr_jsechar(unescapedSet,c) )
            {
               jsecharptr tmp = (jsecharptr)s;
               JSECHARPTR_PUTC(tmp,c);
               JSECHARPTR_INC(tmp);
               JSECHARPTR_PUTC(tmp,'\0');
            }
            else
            {
               assert( JSECHARPTR_DIFF(currCharPtr,start)>0 );
               assert( JSECHARPTR_DIFF(currCharPtr,start)<URIDECODE_COPY_BUFFER_SIZE );

               strncpy_jsechar((jsecharptr)s,start,(size_t)JSECHARPTR_DIFF(currCharPtr,start));
            }
         }
      }
      else
      {
         jsecharptr tmp = (jsecharptr)s;
         JSECHARPTR_PUTC(tmp,c);
         JSECHARPTR_INC(tmp);
         JSECHARPTR_PUTC(tmp,'\0');
      }

      /* allocate whatever additional memory is required, and concatenate s to decodedURIStr */
      if( NULL==decodedURIStr )
         decodedURIStr = StrCpyMalloc((jsecharptr)s);
      else
      {
         decodedURIStr = jseMustReMalloc(jsecharptrdatum,decodedURIStr,
                                         bytestrlen_jsechar(decodedURIStr) +
                                            bytestrsize_jsechar((jsecharptr)s));
         strcat_jsechar(decodedURIStr,(jsecharptr)s);
      }

      ++k;
      JSECHARPTR_INC(currCharPtr);
   }

   return decodedURIStr;

URIError:
   /* clean up and then exit */
  if( NULL!=decodedURIStr )
     jseMustFree( decodedURIStr );
  return NULL;
}
#endif

/* decodeURI() */
#if defined(JSE_ECMAMISC_DECODEURI)
static jseLibFunc(Ecma_decodeURI)
{
   jseVariable encodedURIVar;
   jsecharptr encodedURIStr;
   JSE_POINTER_UINDEX encodedURILength;

   jseVariable retVar;
   jsecharptr retStr;

   /* get the argument */
   JSE_FUNC_VAR_NEED(encodedURIVar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   encodedURIStr = (jsecharptr)jseGetString(jsecontext,encodedURIVar,&encodedURILength);
   assert( NULL != encodedURIStr );

   /* pass off string, and unescaped set to decode helper function */
   retStr = URIDecode(encodedURIStr,UNISTR(";/?:@&=+$,#"));
   if( NULL==retStr )
   {
      /* handle the exception */
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibINVALID_URIDECODE_STRING));
      return;
   }

   /* return the result */
   retVar = jseCreateVariable(jsecontext,jseTypeString);
   assert( NULL != retVar );
   jsePutString(jsecontext,retVar,retStr);
   jseMustFree(retStr);
   jseReturnVar(jsecontext,retVar,jseRetTempVar);
}
#endif

/* decodeURIComponent() */
#if defined(JSE_ECMAMISC_DECODEURICOMPONENT)
static jseLibFunc(Ecma_decodeURIComponent)
{
   jseVariable encodedURIVar;
   jsecharptr encodedURIStr;
   JSE_POINTER_UINDEX encodedURILength;

   jseVariable retVar;
   jsecharptr retStr;

   /* get the argument */
   JSE_FUNC_VAR_NEED(encodedURIVar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   encodedURIStr = (jsecharptr)jseGetString(jsecontext,encodedURIVar,&encodedURILength);
   assert( NULL != encodedURIStr );

   /* pass off string, and unescaped set to decode helper function */
   retStr = URIDecode(encodedURIStr,UNISTR(""));
   if( NULL==retStr )
   {
      /* handle the exception */
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibINVALID_URIDECODECOMPONENT_STRING));
      return;
   }

   /* return the result */
   retVar = jseCreateVariable(jsecontext,jseTypeString);
   assert( NULL != retVar );
   jsePutString(jsecontext,retVar,retStr);
   jseMustFree(retStr);
   jseReturnVar(jsecontext,retVar,jseRetTempVar);
}
#endif

#if defined(JSE_ECMAMISC_ENCODEURI) || defined(JSE_ECMAMISC_ENCODEURICOMPONENT)

static void
UlongToOctets( ulong v, jsechar *octets, uint *octetCount )
{
   ulong hi,lo;
   ulong t;

   if( /*(v>=0x0000) &&*/ (v<=0x007F) )
   {
      (*octetCount) = 1;

      t = v;
      assert( t<=0xFF );
      octets[0] = (jsechar)t;

      return;
   }

   if( (v>=0x0080) && (v<=0x7FF) )
   {
      (*octetCount) = 2;

      t = 0x00C0 | ((v & 0x07C0) >> 6);
      assert( t<=0xFF );
      octets[0] = (jsechar)t;

      t = 0x0080 | (v & 0x003F);
      assert( t<=0xFF );
      octets[1] = (jsechar)t;
      return;
   }

   if( ((v>=0x0800) && (v<=0xD7FF)) ||
       ((v>=0xE000) && (v<=0xFFFF)) )
   {
      (*octetCount) = 3;

      t = 0x00E0 | ((v & 0x7800) >> 12);
      assert( t<=0xFF );
      octets[0] = (jsechar)t;

      t = 0x0080 | ((v & 0x0FC0) >> 6);
      assert( t<=0xFF );
      octets[1] = (jsechar)t;

      t = 0x0080 | (v & 0x003F);
      assert( t<=0xFF );
      octets[2] = (jsechar)t;

      return;
   }

   hi = (v & 0xFFFF0000) >> 16;
   lo = (v & 0x0000FFFF);
   if( (hi>=0xD800) && (hi<=0xDBFF) )
   {
      if( (lo>=0xDC00) && (lo<=0xDFFF) )
      {
         ulong u;

         (*octetCount) = 4;

         u = ((0x03C0 & hi) >> 6) + 1;;

         t = 0x00F0 | (( u & 0x001C) >> 2);
         assert( t<=0xFF );
         octets[0] = (jsechar)t;

         t = 0x0080 | (( u & 0x0003) << 4) | ((hi & 0x003C) >> 2);
         assert( t<=0xFF );
         octets[1] = (jsechar)t;

         t = 0x0080 | ((hi & 0x0003) << 4) | ((lo & 0x03C0) >> 6);
         assert( t<=0xFF );
         octets[2] = (jsechar)t;

         t = 0x0080 | (lo & 0x003F);
         assert( t<=0xFF );
         octets[3] = (jsechar)t;

         return;
      }
      else
      {
         (*octetCount) = 0;
         return;
      }
   }

   if( (v>=0xDC00) && (v<=0xDFFF) )
   {
      (*octetCount) = 0;
      return;
   }

   (*octetCount) = 0;
}

/* URIEncode, used by encodeURI and encodeURIComponent */
#define URIENCODE_COPY_BUFFER_SIZE 50
static jsecharptr
URIEncode(jsecharptr uri,jsecharptr unescapedSet)
{
   /* variable naming conventions & function algorithm based on psueudocode from the
      ECMAScript Language Specification, section 15.1.3 */
   uint uriLen;
   jsecharptr encodedURIStr = NULL;
   uint k;
   jsecharptr currCharPtr = uri;
   jsechar s[URIENCODE_COPY_BUFFER_SIZE];

   uriLen = strlen_jsechar(uri);

   k = 0;

   while( k!=uriLen )
   {
      jsechar c = JSECHARPTR_GETC(currCharPtr);
      jsebool oneChar;

      if( NULL!=strchr_jsechar(unescapedSet,c) )
      {
         jsecharptr tmp = (jsecharptr)s;
         JSECHARPTR_PUTC(tmp,c);
         JSECHARPTR_INC(tmp);
         JSECHARPTR_PUTC(tmp,'\0');
         oneChar = True;
      }
      else
      {
         ulong v;
         uint l,j;
         jsechar octets[4];

         oneChar = False;


#        if (defined(JSE_UNICODE) && (0!=JSE_UNICODE)) \
         || (defined(JSE_MBCS) && (0!=JSE_MBCS))
            if( (c>=0xDC00) && (c<=0xDFFF) )
               goto URIError;
#        endif

#        if (defined(JSE_UNICODE) && (0!=JSE_UNICODE)) \
         || (defined(JSE_MBCS) && (0!=JSE_MBCS))
            if( !((c<0xD800) || (c>0xDBFF)) )
            {
               jsechar c2;

               ++k;

               if( k==uriLen )
                  goto URIError;

               JSECHARPTR_INC(currCharPtr);
               c2 = JSECHARPTR_GETC(currCharPtr);

               if( (c2 < 0xDC00) || (c2 > 0xDFFF) )
                  goto URIError;

               v = (ulong)((c - 0xD800) * 0x400 + (c2 - 0xDC00) + 0x10000);
            }
            else
#        endif
            {
               v = (ujsechar)c;
            }

         UlongToOctets(v,octets,&l);

         /* if UlongToOctets returns a zero, throw a URIError exception */
         if( 0==l )
            goto URIError;

         assert( (l>0) && (l<=4) );

         j = 0;

         while( j<l )
         {
            jsecharptr tmp = (jsecharptr)s;
            jsechar hi = (jsechar)((octets[j]&0xF0)>>4),
                    lo = (jsechar)(octets[j]&0x0F);

            JSECHARPTR_PUTC(tmp,'%');
            JSECHARPTR_INC(tmp);
            JSECHARPTR_PUTC(tmp,(jsechar)((hi<0x0A) ? '0' + hi : 'A' + (hi - 0x0A)));
            JSECHARPTR_INC(tmp);
            JSECHARPTR_PUTC(tmp,(jsechar)((lo<0x0A) ? '0' + lo : 'A' + (lo - 0x0A)));
            JSECHARPTR_INC(tmp);
            JSECHARPTR_PUTC(tmp,'\0');

            /* allocate whatever additional memory is required */
               if( NULL==encodedURIStr )
                  encodedURIStr = StrCpyMalloc((jsecharptr)s);
               else
               {
                  encodedURIStr = jseMustReMalloc(jsecharptrdatum,encodedURIStr,
                                                  bytestrlen_jsechar(encodedURIStr) +
                                                     bytestrsize_jsechar((jsecharptr)s));
                  strcat_jsechar(encodedURIStr,(jsecharptr)s);
               }

            ++j;
         }
      }

      if( oneChar )
      {
         /* allocate whatever additional memory is required, and concatenate s to encodedURIStr */
         if( NULL==encodedURIStr )
            encodedURIStr = StrCpyMalloc((jsecharptr)s);
         else
         {
            encodedURIStr = jseMustReMalloc(jsecharptrdatum,encodedURIStr,
                                            bytestrlen_jsechar(encodedURIStr) +
                                               bytestrsize_jsechar((jsecharptr)s));
            strcat_jsechar(encodedURIStr,(jsecharptr)s);
         }
      }

      ++k;
      JSECHARPTR_INC(currCharPtr);
   }

   return encodedURIStr;

URIError:
   /* clean up and then exit */
   if( NULL!=encodedURIStr )
      jseMustFree( encodedURIStr );
   return NULL;
}

#endif

/* encodeURI() */
#if defined(JSE_ECMAMISC_ENCODEURI)
static jseLibFunc(Ecma_encodeURI)
{
   jseVariable decodedURIVar;
   jsecharptr decodedURIStr;
   JSE_POINTER_UINDEX decodedURILength;

   jseVariable retVar;
   jsecharptr retStr;

   /* get the argument */
   JSE_FUNC_VAR_NEED(decodedURIVar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   decodedURIStr = (jsecharptr)jseGetString(jsecontext,decodedURIVar,&decodedURILength);
   assert( NULL != decodedURIStr );

   /* pass off string, and unescaped set to decode helper function */
   retStr = URIEncode(decodedURIStr,
                      UNISTR("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.!~*'();/?:@&=+$,#"));
   if( NULL==retStr )
   {
      /* handle the exception */
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibINVALID_URIENCODE_STRING));
      return;
   }

   /* return the result */
   retVar = jseCreateVariable(jsecontext,jseTypeString);
   assert( NULL != retVar );
   jsePutString(jsecontext,retVar,retStr);
   jseMustFree(retStr);
   jseReturnVar(jsecontext,retVar,jseRetTempVar);
}
#endif

/* encodeURIComponent() */
#if defined(JSE_ECMAMISC_ENCODEURICOMPONENT)
static jseLibFunc(Ecma_encodeURIComponent)
{
   jseVariable decodedURIVar;
   jsecharptr decodedURIStr;
   JSE_POINTER_UINDEX decodedURILength;

   jseVariable retVar;
   jsecharptr retStr;

   /* get the argument */
   JSE_FUNC_VAR_NEED(decodedURIVar,jsecontext,0,JSE_VN_CONVERT(JSE_VN_ANY,JSE_VN_STRING));
   decodedURIStr = (jsecharptr)jseGetString(jsecontext,decodedURIVar,&decodedURILength);
   assert( NULL != decodedURIStr );

   /* pass off string, and unescaped set to decode helper function */
   retStr = URIEncode(decodedURIStr,UNISTR("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.!~*'()"));
   if( NULL==retStr )
   {
      /* handle the exception */
      jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibINVALID_URIENCODECOMPONENT_STRING));
      return;
   }

   /* return the result */
   retVar = jseCreateVariable(jsecontext,jseTypeString);
   assert( NULL != retVar );
   jsePutString(jsecontext,retVar,retStr);
   jseMustFree(retStr);
   jseReturnVar(jsecontext,retVar,jseRetTempVar);
}
#endif

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

static CONST_DATA(struct jseFunctionDescription) EcmaMiscFunctionList[] =
{
   /* ---------------------------------------------------------------------- */
   /* Some global values */
   /* ---------------------------------------------------------------------- */
   /* ECMA2.0: These global variables have DontDelete */
#  if defined(JSE_ECMAMISC_NAN)
      JSE_VARNUMBER( UNISTR("NaN"),      &seNaN,      jseDontEnum | jseDontDelete),
#  endif
#  if defined(JSE_ECMAMISC_INFINITY)
      JSE_VARNUMBER( UNISTR("Infinity"), &seInfinity, jseDontEnum | jseDontDelete ),
#  endif

#  if defined(JSE_ECMAMISC_EVAL)
      JSE_LIBMETHOD( UNISTR("eval"),        Ecma_eval,          1,      1,
                     jseDontEnum,  jseFunc_NoGlobalSwitch | jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_PARSEINT)
      JSE_LIBMETHOD( UNISTR("parseInt"),    Ecma_parseInt,      0,      2,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_PARSEFLOAT)
      JSE_LIBMETHOD( UNISTR("parseFloat"),  Ecma_parseFloat,    0,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_ESCAPE)
      JSE_LIBMETHOD( UNISTR("escape"),      Ecma_escape,        0,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_UNESCAPE)
      JSE_LIBMETHOD( UNISTR("unescape"),    Ecma_unescape,      0,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_ISNAN)
      JSE_LIBMETHOD( UNISTR("isNaN"),       Ecma_isNaN,         1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_ISFINITE)
      JSE_LIBMETHOD( UNISTR("isFinite"),    Ecma_isFinite,      1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_DECODEURI)
      JSE_LIBMETHOD( UNISTR("decodeURI"),   Ecma_decodeURI,     1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_DECODEURICOMPONENT)
      JSE_LIBMETHOD( UNISTR("decodeURIComponent"), Ecma_decodeURIComponent, 1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_ENCODEURI)
      JSE_LIBMETHOD( UNISTR("encodeURI"),   Ecma_encodeURI,     1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_ECMAMISC_ENCODEURICOMPONENT)
      JSE_LIBMETHOD( UNISTR("encodeURIComponent"), Ecma_encodeURIComponent, 1,      1,
                     jseDontEnum,  jseFunc_Secure ),
#  endif
   JSE_FUNC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

void NEAR_CALL InitializeLibrary_Ecma_Misc(jseContext jsecontext)
{
   jseAddLibrary(jsecontext,NULL,EcmaMiscFunctionList,NULL,NULL,NULL);
}

#endif /* #if defined(JSE_ECMAMISC_ANY) */

ALLOW_EMPTY_FILE
