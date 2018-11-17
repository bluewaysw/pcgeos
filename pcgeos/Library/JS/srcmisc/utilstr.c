/* utilstr.c    Random utilities used by ScriptEase.
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
#include "jsetypes.h"
#include "utilstr.h"
#include "jsemem.h"

#if defined(__JSE_GEOS__)
#  include <Ansi/string.h>
#  include <Ansi/stdlib.h>
#  include <Ansi/ctype.h>
#  include <Ansi/assert.h>
#else
#  include <string.h>
#  include <stdlib.h>
#  include <ctype.h>
#endif
#if !defined(__JSE_MAC__) && !defined(__JSE_GEOS__) && \
    !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#  include <assert.h>
#endif
/* I've overloaded the asert macro, and this will ruin it */

/* To resolve HugeMemCmp */
#include "utilhuge.h"

/* To resolve 'min()' */
#include "sesyshdr.h"


#ifndef UTILSTR_ONLY
/***********************************
 *** RESOURCE STRING TRANSLATION ***
 ***********************************/

#if 1 == JSE_MIN_MEMORY
#  define RESOURCE_XLAT_LEN  256
#else
#  define RESOURCE_XLAT_LEN  1024
#endif

#if defined(JSETOOLKIT_LINK) && defined(__JSE_WIN16__)
   void _FAR_ _cdecl _export
#else
   static void JSE_CFUNC FAR_CALL
#endif
deleteResourceData(void _FAR_ *contextBuffer)
{
   assert( NULL != contextBuffer );
   jseMustFree((void *)contextBuffer);
}

   const jsecharptr
jseGetResource( jseContext jsecontext, const jsecharptr string )
{
   jsecharptr contextBuffer;
   jsecharptr dest;
   const jsecharptr src;
   jsecharptr end;
   size_t diff;
   sint id;
   struct jseExternalLinkParameters *params;
   static CONST_STRING(ResourceSharedDataName,"_getResource_");

   /* Get a buffer that is attached to this context in which to store
    * translated strings.  This is only good until the next call to
    * jseGetResource() for this top-level context.
    */
   contextBuffer = (jsecharptr)jseGetSharedData(jsecontext,ResourceSharedDataName);
   if ( NULL == contextBuffer )
   {
      contextBuffer = jseMustMalloc(jsecharptrdatum,(RESOURCE_XLAT_LEN+1)*sizeof(jsechar));
      jseSetSharedData(jsecontext,ResourceSharedDataName,contextBuffer,deleteResourceData);
   }

   /* First, we'll need to extract the exception name to save and put it back
    * afterwards.
    */
   dest = contextBuffer;
   src = string;

   if( UNICHR('!') == JSECHARPTR_GETC((jsecharptr)src) )
   {
      end = strchr_jsechar( (jsecharptr)src, UNICHR(' ') );

      assert( end != NULL );
      /* If there is no name (just "! "), then this is one of our negative
       * numbers.
       */
      diff = (size_t)JSECHARPTR_DIFF(end,src)+1;
      if( diff > 2 )
      {
         strncpy_jsechar( dest, (jsecharptr)src, diff );

         dest = JSECHARPTR_OFFSET( dest, diff );
      }

      src = JSECHARPTR_NEXT(end);
      JSECHARPTR_PUTC(dest,UNICHR('\0'));
   }

   assert( isdigit_jsechar(JSECHARPTR_GETC(src)) ||
           UNICHR('-') == JSECHARPTR_GETC(src));

   id = (sint)JSE_FP_CAST_TO_SLONG(MY_strtol(src,(jsecharptrdatum **)&end,10)) ;

#  ifndef NDEBUG
      if( id < 0 )
         assert( dest == contextBuffer );
#  endif

   /* if there is no colon next then this is not set up for translation */
   if ( UNICHR(':') == JSECHARPTR_GETC(end) )
   {
      /* If the ID is greater than zero, then we have to copy over the ID number
       * and the colon
       */
      if( id > 0 )
      {
         end = strchr_jsechar( (jsecharptr)src ,UNICHR(':') );
         assert( end != NULL );

         /* Include colon (:) and space */
         end = JSECHARPTR_OFFSET(end,2);

         strncpy_jsechar(dest,(jsecharptr)src,(size_t)JSECHARPTR_DIFF(end,src));
         dest = JSECHARPTR_OFFSET(dest,JSECHARPTR_DIFF(end,src));
         JSECHARPTR_PUTC(dest,UNICHR('\0'));
         src = end;
      }
      else
      {
         src = JSECHARPTR_OFFSET(end,2);
      }
   }

   /* NYI: call callback function with 'id' as parameter */
   params = jseGetExternalLinkParameters(jsecontext);
   if ( NULL == params->GetResourceFunc
     || !(params->GetResourceFunc)(jsecontext,id,dest,
                                   RESOURCE_XLAT_LEN-(size_t)JSECHARPTR_DIFF(dest,contextBuffer)) )
   {
      /* revert to untranslated string */
      strcpy_jsechar(dest,src);
   }

   assert( strlen_jsechar(contextBuffer) <= RESOURCE_XLAT_LEN );

   return (const jsecharptr)contextBuffer;
}
#endif


/***********************************
 *** STRING CONVERSION FUNCTIONS ***
 ***********************************/

#if defined(JSE_UNICODE) && (0!=JSE_UNICODE)

/* unicode conversion functions */
   const char *
JsecharToAscii(const jsecharptr src)
{
   size_t count = strlen_jsechar(src);
   char * dest = jseMustMalloc(char,(count+1)*sizeof(char));
   char * dst = dest;
   while ( count-- )
   {
      *(dst++) = (char)JSECHARPTR_GETC(src);
      JSECHARPTR_INC(src);
   }
   *dst = 0;
   return dest;
}

   const jsecharptr
AsciiLenToJsechar(const char *src,uword32 count)
{
   jsecharptr dest = jseMustMalloc(jsechar,(count+1)*sizeof(jsechar));
   jsecharptr dst = dest;
   while ( count-- )
   {
      JSECHARPTR_PUTC(dst,(jsechar)(*(src++)));
      JSECHARPTR_INC(dst);
   }
   JSECHARPTR_PUTC(dst,'\0');
   return dest;
}

   const jsecharptr
AsciiToJsechar(const char * src)
{
   return AsciiLenToJsechar(src,strlen(src));
}
#endif

#if defined(JSE_MBCS) && (0!=JSE_MBCS)

#if !defined(__JSE_NWNLM__)
size_t sizeof_jsechar(jsechar c)
{
   /* I'm not sure how this will work with endianness */
   return _tclen((TCHAR *)&c);
}
#endif

#if defined(__JSE_NWNLM__)
size_t strlen_jsechar(const jsecharptr str)
{
   size_t total;
   jsecharptrdatum c;
   for ( total = 0; 0 != (c=*str); total++, str++ )
   {
      if ( 1 != NWCharType(c) )
      {
         assert( 2 == NWCharType(c) );
         str++;
      }
   }
   return total;
}
#endif

void STRCPYLEN_JSECHAR(jsecharptr dest, const jsecharptr src, size_t len)
{
   while ( len-- )
   {
      jsechar c = JSECHARPTR_GETC((jsecharptr)src);
      JSECHARPTR_INC(src);
      JSECHARPTR_PUTC(dest,c);
      JSECHARPTR_INC(dest);
   }
   JSECHARPTR_PUTC(dest,UNICHR('\0'));
}

int memcmp_jsechar(const jsecharptr s1, const jsecharptr s2, size_t len )
{
   while ( len-- )
   {
      jsechar c1, c2;
      c1 = JSECHARPTR_GETC((jsecharptr)s1);
      JSECHARPTR_INC(s1);
      c2 = JSECHARPTR_GETC((jsecharptr)s2);
      JSECHARPTR_INC(s2);
      if ( c1 < c2 )
         return -1;
      if ( c2 < c1 )
         return 1;
   }
   return 0;
}

size_t BYTECOUNT_FROM_STRLEN(const jsecharptr str, size_t len)
{
   size_t size = 0;
   while ( len-- )
   {
      size += sizeofnext_jsechar((jsecharptr)str);
      JSECHARPTR_INC(str);
   }
   return size;
}

#if !defined(__JSE_NWNLM__)
void JSECHARPTR_PUTC(jsecharptr str, jsechar c)
{
   _tccpy( (real_jsecharptr) str, (jsecharptr)&c );
}
#endif

real_jsecharptr JSECHARPTR_OFFSET(const jsecharptr str, size_t offset)
{
   while ( offset-- )
   {
      JSECHARPTR_INC(str);
   }
   return (real_jsecharptr)str;
}

size_t JSECHARPTR_DIFF(const jsecharptr s1, const jsecharptr s2)
{
   size_t diff = 0;

   while( s2 != s1 )
   {
      assert( s1 > s2 );  /* We should never go over boundaries */
      JSECHARPTR_INC(s2);
      diff++;
   }

   return diff;
}

   const char *
JsecharToAscii(const jsecharptr src)
{
   size_t count = strlen_jsechar(src);
   char * dest = jseMustMalloc(char,(count+1)*sizeof(char));
   char * dst = dest;
   while ( count-- )
   {
      *(dst++) = (char)(JSECHARPTR_GETC((jsecharptr)src));
      JSECHARPTR_INC(src);
   }
   *dst = 0;
   return dest;
}

   const jsecharptr
AsciiLenToJsechar(const char *src,uword32 count)
{
   jsecharptr dest = jseMustMalloc(jsecharptrdatum,(count+1)*sizeof(jsechar));
   jsecharptr dst = dest;
   while ( count-- )
   {
      JSECHARPTR_PUTC(dst,(jsechar)(*src++));
      JSECHARPTR_INC(dst);
   }
   JSECHARPTR_PUTC(dst,'\0');
   return dest;
}

   const jsecharptr
AsciiToJsechar(const char * src)
{
   return AsciiLenToJsechar(src,strlen(src));
}

#endif

  sint
jsecharCompare(const jsecharhugeptr str1,JSE_POINTER_UINDEX len1,
               const jsecharhugeptr str2,JSE_POINTER_UINDEX len2)
{
   sint result;
   JSE_POINTER_UINDEX lmin = min(len1,len2);
#if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
   result = 0;
   while ( (0 != lmin--)  &&  (0 == (result = JSECHARPTR_GETC(str1) -  JSECHARPTR_GETC(str2))) )
   {
      JSECHARPTR_INC(str1);
      JSECHARPTR_INC(str2);
   }

#else
   result = HugeMemCmp(str1,str2,lmin);
#endif
   if ( 0 == result  &&   len2 != len1 )
   {
      result = ( len1 < len2 ) ? -1 : 1 ;
   }
   return result;
}

   jsenumber
MY_strtol(const jsecharptr s,jsecharptr *endptr,int radix)
/* because Borland's was failing with big hex numbers */
{
   jsenumber result, fradix;
   jsebool isNeg = False;
   assert( s != NULL );

#  if (defined(JSE_MBCS) && (0!=JSE_MBCS)) && !defined(NDEBUG)
   {
      /* MBCS shortcuts that follow rely on all number characters being 1 byte */
      static CONST_STRING(my_strol_chars,"\t\r\n+-xX0123456789abcdefABCDEF");
      assert( strlen(my_strol_chars) == strlen_jsechar(my_strol_chars) );
   }
#  endif

   /* skip all tabs, carriage-returns, and newlines */
#  if defined(JSE_MBCS) && (0!=JSE_MBCS)
      /* faster for mbcs knowing that these characters are all 1 byte */
      s = ((jsecharptrdatum *)s) + strspn(s,"\t\r\n");
#  else
      s += strspn_jsechar(s,UNISTR("\t\r\n"));
#  endif

   /* First check for leading + or - ! */
   if( *(jsecharptrdatum *)s == '+' )
   {
      s = ((jsecharptrdatum *)s) + 1;
   }
   else if ( *(jsecharptrdatum *)s == '-' )
   {
      isNeg = True;
      s = ((jsecharptrdatum *)s) + 1;
   }

   if ( ((jsecharptrdatum*)s)[0]=='0'
     && (((jsecharptrdatum*)s)[1]=='x' || ((jsecharptrdatum*)s)[1]=='X') )
   {
      s = ((jsecharptrdatum *)s) + 2;
      if ( radix == 0 )
         radix = 16;
   }

   if( radix==0 )
   {
      /* octal literals must have at least one character */
      if ( ((jsecharptrdatum*)s)[0]=='0'
        && '0'<=((jsecharptrdatum*)s)[1]
        && ((jsecharptrdatum*)s)[1]<='7'  )
      {
         radix = 8;
      }
      else
      {
         radix = 10;
      }
   }

   /* Do the conversion, if it overflows, infinity will result. */
   result = jseZero;
   fradix = JSE_FP_CAST_FROM_SLONG(radix);
   while( 1 )
   {
      int digit;
      jsecharptrdatum c = ((jsecharptrdatum*)s)[0];

      if ( '0' <= c  &&  c <= '9' )
      {
         digit = c - '0';
      }
#     if defined(JSE_MBCS) && (0!=JSE_MBCS)
      else if( isalpha(c) )
#     else
      else if( isalpha_jsechar(c) )
#     endif
      {
         digit = tolower(c)-'a' + 10;
      }
      else
      {
         break;
      }
      if( radix <= digit ) break;

      result = JSE_FP_ADD(JSE_FP_MUL(fradix,result),JSE_FP_CAST_FROM_SLONG(digit));
      s = ((jsecharptrdatum *)s) + 1;
   }

   if ( endptr != NULL )
   {
      *endptr = (jsecharptr)s;
   } /* endif */

   if ( isNeg )
      result = JSE_FP_NEGATE(result);
   return result;
}

#if !defined(JSE_UNICODE) || (0==JSE_UNICODE)

/* ECMA2.0: added new character constants */

CONST_STRING(WhiteSpace," \t\r\n\f\v\xa0");
CONST_STRING(SameLineWhiteSpace," \t\xa0");
#ifdef __JSE_MAC__
  CONST_STRING(NewLine,"\r");
#else
  CONST_STRING(NewLine,"\r\n");
#endif

#else

CONST_STRING(WhiteSpace," \t\r\n\f\v\xa0");
CONST_STRING(SameLineWhiteSpace," \t\xa0");
#ifdef __JSE_MAC__
  CONST_STRING(NewLine,"\r\x2028\x2029");
#else
  CONST_STRING(NewLine,"\r\n\x2028\x2029");
#endif

#endif

   void
RemoveWhitespaceFromHeadAndTail(const jsecharptr buf)
/* remove whitespace from beginning and end of SourceCmdLine */
{

   /* skip beyond any beginning whitespace */
   uint Len = strlen_jsechar(buf);
   uint Remove = strspn_jsechar(buf,WhiteSpace);
   if ( Remove )
      memmove((void *)buf,(void *)JSECHARPTR_OFFSET(buf,Remove),BYTECOUNT_FROM_STRLEN(buf,(Len -= Remove)+1));
   /* remove any whitespace at the end */
# if !defined(JSE_MBCS) || (0==JSE_MBCS)
      while ( Len  &&  IS_WHITESPACE(buf[--Len]))
      {
         ((jsecharptr)buf)[Len] = '\0';
      }
#  else
      {
         const jsecharptr last;
                 const jsecharptr current;

         last = current = buf;

         while( JSECHARPTR_GETC((jsecharptr)current) != '\0' )
         {
            while( JSECHARPTR_GETC((jsecharptr)current) != '\0' &&
                   !IS_WHITESPACE(JSECHARPTR_GETC((jsecharptr)current)) )
               JSECHARPTR_INC(current);

            last = current;

            if( JSECHARPTR_GETC((jsecharptr)current) == '\0' )
               break;

            while( JSECHARPTR_GETC((jsecharptr)current) != '\0' &&
                   IS_WHITESPACE(JSECHARPTR_GETC((jsecharptr)current)) )
               JSECHARPTR_INC(current);
         }

         JSECHARPTR_PUTC((jsecharptr)last,'\0');
      }
#  endif
}


   jsecharptr
StrCpyMallocLen(const jsecharptr Src,size_t len)
{
   jsecharptr dest;
   uint bytelen;

   /* It's OK to have a length of 0, since we're allocating len+1 bytes */
   assert( NULL != Src  /*||  0 == len*/ );
   assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
   dest = jseMustMalloc(jsecharptrdatum,(bytelen=BYTECOUNT_FROM_STRLEN(Src,len))+sizeof(jsecharptrdatum));
   memcpy(dest,Src,bytelen);
   assert( sizeof_jsechar('\0') == sizeof(jsecharptrdatum) );
   *((jsecharptrdatum *)(((ubyte *)dest)+bytelen)) = 0;
   return(dest);
}

#if defined(__JSE_MAC__) || defined(__DJGPP__) || defined(__JSE_UNIX__) \
 || defined(__JSE_PSX__) || defined(__JSE_390__) || defined(__JSE_EPOC32__) \
 || defined(__JSE_PALMOS__) || defined(__JSE_GEOS__)
   void NEAR_CALL
long_to_string(long i,jsecharptr StringBuffer)
{
   sprintf_jsechar(StringBuffer,UNISTR("%ld"),i);
}
#endif /* JSE_MAC */


#if (0==JSE_FLOATING_POINT) || defined(__JSE_PSX__)
   void
jse_vsprintf(jsecharptr buf,const jsecharptr FormatString,va_list arglist)
{
   /* NYI: Build a more-through version of non-floating sprintf */
   jsechar c;

   while( (c = JSECHARPTR_GETC(FormatString))!='\0' )
   {
      if( c=='%' )
      {
         JSECHARPTR_INC(FormatString);
         switch( JSECHARPTR_GETC(FormatString) )
         {
            case '%':
               JSECHARPTR_PUTC(buf,'%');
               JSECHARPTR_INC(buf);
               break;
            case 's':
            {
               jsecharptr tmp = va_arg(arglist,jsecharptr);

               /* Copy the text, note we don't care about individual
                * characters - even MBCS is just a bunch of bytes
                * followed by a '\0', that's what we need to copy,
                * so no need to use MBCS routines.
                */
               strcpy((char *)buf,(char *)tmp);
               buf = (jsecharptr) (((char *)buf)+strlen((char *)buf));
               break;
            }
            case 'u':
            case 'd':
            {
               int num = va_arg(arglist,int);
               long_to_string(num,buf);
               /* even in MBCS, we don't care about the individual
                * characters, only where the final '\0' is. '\0' on
                * MBCS is the same 1-byte as a normal string, so
                * use the fast 'strlen'
                */
               buf = (jsecharptr)((char *)buf + strlen((char *)buf));
               break;
            }
         }
         JSECHARPTR_INC(FormatString);
      }
      else
      {
         JSECHARPTR_PUTC(buf,c);
         JSECHARPTR_INC(buf);
         JSECHARPTR_INC(FormatString);
      }
   }

   JSECHARPTR_PUTC(buf,'\0');
}

   void
jse_sprintf(jsecharptr buf,const jsecharptr FormatString,...)
{
   va_list arglist;
   va_start(arglist,FormatString);
   jse_vsprintf(buf,FormatString,arglist);
   va_end(arglist);
}
#endif /* (0==JSE_FLOATING_POINT) */

#if defined(__JSE_MAC__) || defined(__JSE_UNIX__) || defined(__JSE_PSX__) \
 || defined(__JSE_390__) || defined(__JSE_EPOC32__)

jsecharptr
#if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
lstrlwr(jsecharptr str)
#else
strlwr(jsecharptr str)
#endif
{
   jsecharptr c;
   for ( c = str; JSECHARPTR_GETC(c)!='\0'; JSECHARPTR_INC(c) )
   {
      JSECHARPTR_PUTC(c,(jsechar) tolower_jsechar(JSECHARPTR_GETC(c)));
   }
   return str;
}


jsecharptr
#if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
lstrupr(jsecharptr str)
#else
strupr(jsecharptr str)
#endif
{
   jsecharptr c;
   for ( c = str; JSECHARPTR_GETC(c)!='\0'; JSECHARPTR_INC(c) )
   {
      JSECHARPTR_PUTC(c,(jsechar) toupper_jsechar(JSECHARPTR_GETC(c)));
   }
   return str;
}


   int
strnicmp_jsechar(const jsecharptr str1,const jsecharptr str2,size_t len)
{
   int result = 0;
   while ( 0 != len--
        && 0 == (result = tolower(JSECHARPTR_GETC(str1)) - tolower(JSECHARPTR_GETC(str2)))
        && 0 != JSECHARPTR_GETC(str1) )
   {
      JSECHARPTR_INC(str1);
      JSECHARPTR_INC(str2);
   }
   return result;
}

   int
stricmp_jsechar(const jsecharptr str1,const jsecharptr str2)
{
   int result;
   while ( 0 == (result = tolower(JSECHARPTR_GETC(str1)) - tolower(JSECHARPTR_GETC(str2)))
       &&  0 != JSECHARPTR_GETC(str1) )
   {
      JSECHARPTR_INC(str1);
      JSECHARPTR_INC(str2);
   }
   return result;
}

#endif /* __JSE_MAC__ || __JSE_UNIX__ */



#if (0!=JSE_FLOATING_POINT) \
 && (defined(JSE_NUMTOSTRING_ROUNDING) && (0!=JSE_NUMTOSTRING_ROUNDING))
   static CONST_STRING(RoundDown,"00000");
#  define RoundDownCharCount 5 /* must match number of 0s above */
#  define RoundDownOffsetFromDecimal   6
   static CONST_STRING(RoundUp,"99999");
#  define RoundUpCharCount 5 /* must match number of 9s above */
#  define RoundUpOffsetFromDecimal     5
#endif

   void
EcmaNumberToString(jsechar buffer[ECMA_NUMTOSTRING_MAX],jsenumber theNum)
   /* convert number to string following the rules in ecma document 9.8.1 */
{
#  if !defined(NDEBUG) && defined(JSE_MBCS) && (0!=JSE_MBCS)
   {
      /* for faster MBCS, lets ensure that all characters are single-bytes */
      const jsecharptr used_nums = "0123456789.+-e";
      assert( strlen(used_nums) == strlen_jsechar(used_nums) );
   }
#  endif

   if ( !jseIsFinite(theNum) )
   {
      if( jseIsNaN(theNum) )
      {
         strcpy_jsechar((jsecharptr)buffer,UNISTR("NaN"));
      }
      else
      {
         assert( jseIsInfinity(theNum) || jseIsNegInfinity(theNum) );
         strcpy_jsechar((jsecharptr)buffer,jseIsInfinity(theNum)?UNISTR(""):UNISTR("-"));
         strcat_jsechar((jsecharptr)buffer,UNISTR("Infinity"));
      }
   }
   else if ( jseIsZero(theNum) )
   {
      strcpy_jsechar((jsecharptr)buffer,UNISTR("0"));
   }
   else
   {
#     if (0!=JSE_FLOATING_POINT)
         jsecharptr expPtr;

#        if !defined(JSE_NUMTOSTRING_ROUNDING) || (0==JSE_NUMTOSTRING_ROUNDING)
#	    if defined(__JSE_GEOS__)
	      union
	      {
		double db;
	 	IEEE64FloatNum  ieee64;
	      } dnum;
	      dnum.db = theNum;
	      FloatFloatIEEE64ToAscii_StdFormat(buffer, dnum.ieee64, 
		                            	FFAF_FROM_ADDR | FFAF_NO_TRAIL_ZEROS, 
						DECIMAL_PRECISION, DECIMAL_PRECISION);
#	    else
              JSE_FP_DTOSTR(theNum,21,buffer,UNISTR("g"));
#	    endif
#        else
         {
            /* convert starting at .21g but working down until there is no longer a
             * need to round up-down
             */
            int Precision;

#         if defined(__JSE_GEOS__)
            for ( Precision = DECIMAL_PRECISION; ; Precision-- )
#         else
            for ( Precision = 21; ; Precision-- )
#         endif
            {
               jsecharptr decimal;
               size_t len;

               assert( 0 != Precision );

#	       if defined(__JSE_GEOS__)
               {
#                if defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR)
                    FloatNum f = JSE_GEOS_FP_TO_FLOAT(theNum) ;
                    FloatFloatToAscii_StdFormat(
                        buffer, 
                        &f, 
                        FFAF_FROM_ADDR | FFAF_NO_TRAIL_ZEROS, 
		        DECIMAL_PRECISION, 
                        Precision);
#                else
	             union
                     {
	               double db;
	               IEEE64FloatNum  ieee64;
                     } dnum;
	             dnum.db = theNum;
         
	             FloatFloatIEEE64ToAscii_StdFormat(buffer, dnum.ieee64, 
		                            	       FFAF_FROM_ADDR | FFAF_NO_TRAIL_ZEROS, 
						       DECIMAL_PRECISION, Precision);
#                endif
               }
#              else
                 JSE_FP_DTOSTR(theNum,Precision,buffer,UNISTR("g"));
#	       endif
            
               if ( 0 == Precision )
               {
                  /* cannot get any smaller */
                  break;
               }

#              if !defined(NDEBUG) && defined(JSE_MBCS) && (0!=JSE_MBCS)
               {
                  /* for faster MBCS, lets ensure that all characters are single-bytes */
                  assert( strlen((char *)buffer) == strlen_jsechar((jsecharptr)buffer) );
               }
#              endif

               if ( NULL == (decimal=strchr_jsechar((jsecharptr)buffer,'.')) )
               {
                  /* no decimal in string, so don't bother rounding */
                  break;
               }

               assert( sizeof_jsechar(JSECHARPTR_GETC(decimal)) == sizeof(jsecharptrdatum) );
               decimal = ((jsecharptrdatum *)decimal) + 1;
               len = strlen_jsechar(decimal);

               /* if too many 999999s or too many 00000s appear in the new string after
                * the decimal then round
                */
               if ( RoundDownOffsetFromDecimal < len /* don't start beyond string */
                 && 0 == strncmp_jsechar((jsecharptrdatum*)decimal+RoundDownOffsetFromDecimal,RoundDown,RoundDownCharCount) )
               {
                  /* too many 0s, try again */
               }
               else
               if ( RoundUpOffsetFromDecimal < len /* don't start beyond string */
                 && 0 == strncmp_jsechar((jsecharptrdatum*)decimal+RoundUpOffsetFromDecimal,RoundUp,RoundUpCharCount) )
               {
                  /* too many 9s, try again */
               }
               else
               {
                  /* not too many 0s or 9s; let it pass */
                  break;
               }
            }
         }
#        endif

         assert( strlen_jsechar((jsecharptr)buffer) < ECMA_NUMTOSTRING_MAX );
         /* assume that the result does not start off with any space characters */
         assert( !isspace_jsechar(JSECHARPTR_GETC((jsecharptr)buffer)) );

         /* remove leading zeros from the e portion, if there is one */
         if( (expPtr=strchr_jsechar((jsecharptr)buffer,'e'))!=NULL )
         {
            jsecharptr e = JSECHARPTR_NEXT(expPtr);
            if ( JSECHARPTR_GETC(e) == UNICHR('+')  ||  JSECHARPTR_GETC(e) == UNICHR('-') )
               JSECHARPTR_INC(e);
            while ( JSECHARPTR_GETC(e) == UNICHR('0') )
               memmove(e,JSECHARPTR_NEXT(e),bytestrsize_jsechar(JSECHARPTR_NEXT(e)));
         }

#        if 0
         {
            This section of code has been removed because the default conversion operator
            no longer leaves trailing zeros after the decimal.  If some compiler does not
            automatically remove trailing zeros then this section must be redone
            if( (decimalptr=strchr_jsechar((jsecharptr)buffer,'.'))!=NULL )
            {
               /* get rid of trailing zeroes. We need to have all the precision forced
                * otherwise the value gets rounded which is bad.  But if this is a
                * trailing zero because it follows "e".
                */
               if ( strchr_jsechar(decimalptr,'e')==NULL )
               {
                  while( buffer[strlen_jsechar(buffer)-1]=='0' && strlen_jsechar(buffer)>1 )
                     buffer[strlen_jsechar(buffer)-1] = '\0';
               }
            }
         }
#        endif
#     else
         /* 0==JSE_FLOATING_POINT */
         long_to_string(theNum,(jsecharptr)buffer);
#     endif
   }
   assert( strlen_jsechar((jsecharptr)buffer) < ECMA_NUMTOSTRING_MAX );
}
