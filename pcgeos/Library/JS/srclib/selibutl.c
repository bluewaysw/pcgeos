/* selibutl.c  - Misc. uitilities for various libraries
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

#if defined(JSE_CLIB_MEMSET)    || \
    defined(JSE_CLIB_MEMCHR)    || \
    defined(JSE_CLIB_STRCHR)    || \
    defined(JSE_CLIB_STRCSPN)   || \
    defined(JSE_CLIB_STRRCHR)   || \
    defined(JSE_CLIB_ISALNUM)   || \
    defined(JSE_CLIB_ISALPHA)   || \
    defined(JSE_CLIB_ISASCII)   || \
    defined(JSE_CLIB_ISCNTRL)   || \
    defined(JSE_CLIB_ISDIGIT)   || \
    defined(JSE_CLIB_ISGRAPH)   || \
    defined(JSE_CLIB_ISLOWER)   || \
    defined(JSE_CLIB_ISPRINT)   || \
    defined(JSE_CLIB_ISPUNCT)   || \
    defined(JSE_CLIB_ISSPACE)   || \
    defined(JSE_CLIB_ISUPPER)   || \
    defined(JSE_CLIB_ISXDIGIT)  || \
    defined(JSE_CLIB_TOASCII)   || \
    defined(JSE_CLIB_TOLOWER)   || \
    defined(JSE_CLIB_TOUPPER)   || \
    defined(JSE_CLIB_PRINTF)    || \
    defined(JSE_CLIB_FPRINTF)   || \
    defined(JSE_CLIB_VPRINTF)   || \
    defined(JSE_CLIB_SPRINTF)   || \
    defined(JSE_CLIB_VSPRINTF)  || \
    defined(JSE_CLIB_RVSPRINTF) || \
    defined(JSE_CLIB_SYSTEM)    || \
    defined(JSE_CLIB_FSCANF)    || \
    defined(JSE_CLIB_VFSCANF)   || \
    defined(JSE_CLIB_SCANF)     || \
    defined(JSE_CLIB_VSCANF)    || \
    defined(JSE_CLIB_SSCANF)    || \
    defined(JSE_CLIB_VSSCANF)   || \
    defined(JSE_CLIB_VA_ARG)    || \
    defined(JSE_CLIB_VA_START)  || \
    defined(JSE_CLIB_VA_END)    || \
    defined(JSE_GD_CHAR)        || \
    defined(JSE_GD_CHARUP)

/* Yes, that is supposed to be a jsechar *, not a jsecharptr */
   jsebool
GetJsecharFromStringOrNumber(jseContext jsecontext,jseVariable var,jsechar * value)
{
   jseDataType vType = jseGetType(jsecontext,var);
   if( jseTypeNumber == vType )
   {
      *value = (jsechar)jseGetByte(jsecontext,var);
      return True;
   }
   if( jseTypeString == vType )
   {
      JSE_POINTER_UINDEX length;
      const jsecharhugeptr str = jseGetString(jsecontext,var,&length);

      if( length == 1 )
      {
         *value = JSECHARPTR_GETC((jsecharptr)str);
         return True;
      }
   }
   else if ( jseTypeBuffer == vType )
   {
      JSE_POINTER_UINDEX length;
      const ubyte _HUGE_ * buf = jseGetBuffer(jsecontext,var,&length);
      if( length == 1 )
      {
         *value = (jsechar)(*buf);
         return True;
      }
   }

   /* This will cause an error to be reported */
   jseVarNeed(jsecontext,var,JSE_VN_BYTE);
   return False;
}

#endif

#if defined(JSE_TOSOURCE_HELPER) \
 || defined(JSE_DSP_ANY)         \
 || defined(JSE_EXCEPTION_ANY)
   void
dynamicBufferInit( struct dynamicBuffer * buf )
{
   buf->allocated = 2;
   buf->buffer = jseMustMalloc(jsecharptrdatum,buf->allocated*sizeof(jsechar));
   buf->used = 1;
   JSECHARPTR_PUTC(buf->buffer,'\0');
}

   void
dynamicBufferTerm( struct dynamicBuffer * buf )
{
   jseMustFree( buf->buffer );
}

   void
dynamicBufferAppend( struct dynamicBuffer * buf, const jsecharptr text )
{
   size_t length = strlen_jsechar(text);

   if( buf->used + length > buf->allocated )
   {
      do {
         buf->allocated *= 2;
      } while( buf->used + length > buf->allocated );

      buf->buffer = jseMustReMalloc(jsecharptrdatum,buf->buffer,
                                    buf->allocated*sizeof(jsechar));
   }

   strcat_jsechar(buf->buffer, text);
   buf->used += length;
}

   void
dynamicBufferAppendLength( struct dynamicBuffer * buf, const jsecharptr text,
                           size_t length )
{
   if( buf->used + length > buf->allocated )
   {
      do {
         buf->allocated *= 2;
      } while( buf->used + length > buf->allocated );

      buf->buffer = jseMustReMalloc(jsecharptrdatum,buf->buffer,
                                    buf->allocated*sizeof(jsechar));
   }

   strncat_jsechar(buf->buffer, text, length);
   buf->used += length;
}
#endif /* #if defined(JSE_TOSOURCE_HELPER) || defined(JSE_DSP_ANY) || defined(JSE_EXCEPTION_ANY) */

#if defined(JSE_TOSOURCE_HELPER)
/* EscapeString - This function will process a string and replace any quotes,
 * backslashes, non-ascii characters, or control characters with an appropriate
 * escaped version.
 */
   struct dynamicBuffer
jseEscapeString( const jsecharptr source, JSE_POINTER_UINDEX length )
{
   struct dynamicBuffer buffer;
   size_t loc, next;
   jsecharptr current = (jsecharptr)source;

   dynamicBufferInit(&buffer);

   for( loc = 0, next = 0; loc < length && next < length; next++, JSECHARPTR_INC(current) )
   {
      if( JSECHARPTR_GETC(current) == '"' ||
          JSECHARPTR_GETC(current) == '\\' )
      {
         dynamicBufferAppendLength(&buffer, JSECHARPTR_OFFSET(source,loc), next-loc);
         dynamicBufferAppend(&buffer, UNISTR("\\"));
         dynamicBufferAppendLength(&buffer,current, 1 );

         loc = next + 1;
      }
      else if( !isprint_jsechar(JSECHARPTR_GETC(current)) )
      {
         dynamicBufferAppendLength(&buffer,JSECHARPTR_OFFSET(source,loc), next-loc);

         switch( JSECHARPTR_GETC(current) )
         {
            case '\r':
               dynamicBufferAppend(&buffer,UNISTR("\\r"));
               break;
            case '\n':
               dynamicBufferAppend(&buffer,UNISTR("\\n"));
               break;
            case '\v':
               dynamicBufferAppend(&buffer,UNISTR("\\v"));
               break;
            case '\t':
               dynamicBufferAppend(&buffer,UNISTR("\\t"));
               break;
            case '\b':
               dynamicBufferAppend(&buffer,UNISTR("\\b"));
               break;
            case '\f':
               dynamicBufferAppend(&buffer,UNISTR("\\f"));
               break;
            default:
               /* If this is a unicode value, then we use the escape sequence
                * \uXXXX.  Otherwise, we use the smaller hex value \xXX
                */
            {
               ujsechar theChar = JSECHARPTR_GETC(current);
               ujsechar buf[10];

#              if defined(JSE_UNICODE) && (0!=JSE_UNICODE) || \
                  defined(JSE_MBCS) && (0!=JSE_MBCS)
                  if( theChar > 0xFF )  /* Use Unicode encoding */
                     sprintf_jsechar((jsecharptr)buf,UNISTR("\\u%04x"),theChar);
                  else
                     sprintf_jsechar((jsecharptr)buf,UNISTR("\\x%02x"),theChar);
#              else
                  sprintf_jsechar((jsecharptr)buf,UNISTR("\\x%02x"),theChar);
#              endif

               dynamicBufferAppend(&buffer,(jsecharptr)buf);
               break;
            }
         }

         loc = next + 1;
      }
   }

   dynamicBufferAppendLength(&buffer,JSECHARPTR_OFFSET(source,loc),next-loc);

   return buffer;
}

jseVariable jseConvertToSource(jseContext jsecontext, jseVariable var)
{
   jseVariable ret;

   switch( jseGetType(jsecontext,var) )
   {
      /* String type:  "value" */
      case jseTypeString:
      {
         struct dynamicBuffer buffer, strBuffer;
         JSE_POINTER_UINDEX strLength;
         const jsecharptr str = (const jsecharptr)jseGetString(jsecontext,
                                                               var,&strLength);

         dynamicBufferInit(&buffer);
         dynamicBufferAppend(&buffer,UNISTR("\"") );

         strBuffer = jseEscapeString(str,strLength);
         dynamicBufferAppend(&buffer,dynamicBufferGetString(&strBuffer));
         dynamicBufferTerm(&strBuffer);
         dynamicBufferAppend(&buffer,UNISTR("\""));

         /* Now put it into the return variable */
         ret = jseCreateVariable(jsecontext,jseTypeString);
         jsePutString(jsecontext,ret,dynamicBufferGetString(&buffer));

         dynamicBufferTerm(&buffer);
      }
      break;

      case jseTypeBoolean:
      case jseTypeNumber:
      case jseTypeNull:
         ret = jseCreateConvertedVariable(jsecontext,var,jseToString);
         break;

      case jseTypeUndefined:
      {
         ret = jseCreateVariable(jsecontext,jseTypeString);
         jsePutString(jsecontext,ret,UNISTR("void 0"));
      }
      break;

      case jseTypeObject:
      {
         jseVariable toSourceFunc =jseGetMember(jsecontext,var,TOSOURCE_PROPERTY);
         jseStack stack = jseCreateStack(jsecontext);

         if( toSourceFunc == NULL ||
             !jseIsFunction(jsecontext,toSourceFunc) )
         {
            jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibOBJECT_HAS_NO_TOSOURCE));
            jseDestroyStack(jsecontext,stack);
            return NULL;
         }

         if( !jseCallFunction(jsecontext,toSourceFunc,stack,&ret,var) )
         {
            if( !jseQuitFlagged(jsecontext) )
               jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibERROR_IN_TOSOURCE));
            jseDestroyStack(jsecontext,stack);
            return NULL;
         }
         else if( jseGetType(jsecontext,ret) == jseTypeNull )
         {
            jseDestroyStack(jsecontext,stack);
            return NULL;
         }
         else if( jseGetType(jsecontext,ret) != jseTypeString )
         {
            jseLibErrorPrintf(jsecontext,textlibGet(jsecontext,textlibTOSOURCE_MUST_RETURN_OBJECT));
            jseDestroyStack(jsecontext,stack);
            return NULL;
         }
         else
         {
            /* Finally.  We're sure that we have a successful call */
            const jsecharptr buffer = (const jsecharptr)jseGetString(jsecontext,
                                                                     ret,NULL);
            ret = jseCreateVariable(jsecontext,jseTypeString);
            jsePutString(jsecontext,ret,buffer);
            jseDestroyStack(jsecontext,stack);
         }
         break;
      }

#if   defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      case jseTypeBuffer:
      {
         jseVariable var2 = jseCreateConvertedVariable(jsecontext,var,jseToString);
         struct dynamicBuffer buffer, strBuffer;
         JSE_POINTER_UINDEX strLength;
         const jsecharptr str = (const jsecharptr)jseGetString(jsecontext,
                                                               var2,&strLength);

         dynamicBufferInit(&buffer);
         dynamicBufferAppend(&buffer,UNISTR("\"") );

         strBuffer = jseEscapeString(str,strLength);
         dynamicBufferAppend(&buffer,dynamicBufferGetString(&strBuffer));
         dynamicBufferTerm(&strBuffer);
         dynamicBufferAppend(&buffer,UNISTR("\""));

         /* Now put it into the return variable */
         ret = jseCreateVariable(jsecontext,jseTypeString);
         jsePutString(jsecontext,ret,dynamicBufferGetString(&buffer));

         dynamicBufferTerm(&buffer);

         jseDestroyVariable(jsecontext,var2);
      }
      break;
#     endif

      default:
         assert( False );
   }

   return ret;
}
#endif /* #if defined(JSE_TOSOURCE_HELPER) */

ALLOW_EMPTY_FILE


