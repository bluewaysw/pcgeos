/* define.c     Handle all the #define statements coming
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

#if defined(JSE_DEFINE) && (0!=JSE_DEFINE)

   struct Define *
defineNew(struct Define *pParent)
{
   struct Define *this = jseMalloc(struct Define,sizeof(struct Define));

   if( this != NULL )
   {
      this->linksAlloced = 10;
      this->linksUsed = 0;
      this->links = jseMalloc(struct Link,sizeof(struct Link)*this->linksAlloced);
      if( this->links==NULL )
      {
         jseMustFree(this);
         return NULL;
      }
      this->Parent = pParent;
   }

   return this;
}

   void
defineDelete(struct Define *this)
{
   uint i;

   for( i=0;i<this->linksUsed;i++ )
   {
      jseMustFree(this->links[i].Find);
      jseMustFree(this->links[i].Replace);
   }
   jseMustFree(this->links);
   jseMustFree(this);
}

   static void NEAR_CALL
defineAddLen(struct Define *this,const jsecharptr FindString,size_t FindStringLen,
             const jsecharptr ReplaceString,size_t ReplaceStringLen)
{
   struct Link *loc;
   uint lower = 0;
   uint middle;
   uint upper = this->linksUsed-1;
   int compare;
   jsebool new_needed = True;

   /* First search to see if already there */

   if( this->linksUsed==0 )
   {
      loc = this->links;
   }
   else for ( ; ; )
   {
      assert( lower<=upper );
      loc = this->links + (middle =  ((lower+upper) >> 1));
      compare = strncmp_jsechar(loc->Find,FindString,FindStringLen);

      /* if so, then the stored string is longer, hence 'bigger' */
      if( compare==0 && strlen_jsechar(loc->Find)>(uint)FindStringLen )
         compare = 1;


      /* found it */
      if( compare==0 )
      {
         new_needed = False;
         break;
      }

      if( compare<0 )
      {
         if( middle==upper )
         {
            /* it should come right after this entry */
            loc += 1;
            break;
         }
         lower = middle + 1;
      }
      else
      {
         if( middle==lower ) break;
         upper = middle - 1;
      }
   }

   if( new_needed )
   {
      uint offset = (uint)(loc - this->links);

      assert( loc >= this->links );

      /* Not found, insert it at this point */
      if( this->linksUsed>=this->linksAlloced )
      {
         this->linksAlloced += 50;
         this->links = jseMustReMalloc(struct Link,this->links,
                                       this->linksAlloced*sizeof(struct Link));
         /* could have moved */
         loc = this->links + offset;
      }
      HugeMemMove(loc+1,loc,(this->linksUsed-offset)*sizeof(struct Link));
      loc->Find = StrCpyMallocLen(FindString,(size_t)FindStringLen);
      this->linksUsed++;
   }
   else
   {
      assert( loc->Replace!=NULL );
      jseMustFree(loc->Replace);
   }

   loc->Replace = StrCpyMallocLen(ReplaceString,(size_t)ReplaceStringLen);
}

   static void NEAR_CALL
defineAdd(struct Define *this,const jsecharptr FindString,
          const jsecharptr ReplaceString)
{
   assert( NULL != FindString  &&  NULL != ReplaceString );
   defineAddLen(this,FindString,strlen_jsechar(FindString),ReplaceString,
                strlen_jsechar(ReplaceString));
}

   static void NEAR_CALL
defineAddInt(struct Define *this,const jsecharptr FindString,slong l)
{
   jsechar buf[50];
   long_to_string(l,(jsecharptr)buf);
   defineAdd(this,FindString,(jsecharptr)buf);
}


   static void NEAR_CALL
defineAddFloat(struct Define *this,const jsecharptr FindString,jsenumber f)
{
   jsechar buf[ECMA_NUMTOSTRING_MAX];
#  if (0!=JSE_FLOATING_POINT)
      JSE_FP_DTOSTR(f,21,buf,UNISTR("g"));
#  else
      long_to_string(f,(jsecharptr)buf);
#  endif
   defineAdd(this,FindString,(jsecharptr)buf);
}

   jsebool
defineProcessSourceStatement(struct Source **source,struct Call *call)
{
   jsecharptr src = sourceGetPtr(*source);
   jsecharptr end = JSECHARPTR_OFFSET(src,strlen_jsechar(src));
   int in_string = 0;

   /* replace all commented areas on this line with spaces, so that comments
    * don't confuse our parsing. Do not do this if within a string.
    */

   jsebool WithinComment = False;
   jsecharptr BeginComment = NULL;
   jsecharptr c;

   for ( c = src; 0 != JSECHARPTR_GETC(c); JSECHARPTR_INC(c) )
   {
      jsechar theChar = JSECHARPTR_GETC(c);
      jsechar nextChar = JSECHARPTR_GETC(JSECHARPTR_NEXT(c));

      if( theChar == UNICHR('"') )
         in_string = 1 - in_string;
      if ( !in_string && !WithinComment )
      {
         if ( UNICHR('/') == theChar )
         {
            if ( UNICHR('/') == nextChar ) {
               /* all the rest of the line is comment, and so end it here */
               end = c;
               break;
            } else if ( UNICHR('*') == nextChar ) {
               BeginComment = c;
               WithinComment = True;
               JSECHARPTR_INC(c); /* so won't see the '*' as a possible end-comment */
            }
         }
      }
      else
      {
         if ( UNICHR('*') == theChar  &&  UNICHR('/') == nextChar)
         {
            /* end of comment, so compact comment into a single space */
            JSECHARPTR_PUTC(BeginComment,UNICHR(' '));
            memmove(JSECHARPTR_NEXT(BeginComment),JSECHARPTR_OFFSET(c,2),
                    bytestrsize_jsechar(JSECHARPTR_OFFSET(c,2)));
            c = BeginComment;
            end = JSECHARPTR_OFFSET(c,strlen_jsechar(c));
            WithinComment = False;
         }
      }
   }
   if ( WithinComment )
   {
      /* if ended within comment, then stop where that comment begins */
      end = BeginComment;
   }

   sourceSetPtr(*source,end); /* will continue parsing from here */

   /* remove whitespace from beginning of line */
   SKIP_WHITESPACE(src);

   /* remove whitespace from end */
#  if !defined(JSE_MBCS) || (0==JSE_MBCS)
      while ( IS_WHITESPACE(end[-1])  &&  src < end )
      {
         end--;
      }
#  else
      {
         /* For MBCS this is going to be harder */
         jsecharptr last = src;
         jsecharptr current = src;
         while( JSECHARPTR_GETC(current) != '\0' )
         {
            while( !IS_WHITESPACE(JSECHARPTR_GETC(current)) )
            {
               JSECHARPTR_INC(current);
            }

            last = current;

            SKIP_WHITESPACE(current);
         }
         end = last;
      }
#  endif

   assert( src <= end );
   if ( src < end )
   {
      jsecharptr Find = src;
      int FindLen;
      jsecharptr Replace;
      int ReplaceLen;

      assert( 0 != JSECHARPTR_GETC(src) );
      /* get Find label, which is text up to whitespace */
      while ( (src = JSECHARPTR_NEXT(src)) < end  &&  !IS_WHITESPACE(JSECHARPTR_GETC(src)) )
         ;
      FindLen = JSECHARPTR_DIFF(src,Find);
      /* get the replacement string */
      assert( src <= end );
      Replace = UNISTR(" ");
      ReplaceLen = 1; /* default in case nothing found */
      while( src < end  &&  IS_WHITESPACE(JSECHARPTR_GETC(src)) ) { JSECHARPTR_INC(src); }
      assert( src <= end );
      if ( src < end )
      {
         /* get replacement string, which is string up to end */
         Replace = src;
         ReplaceLen = JSECHARPTR_DIFF(end,src);
      }
      assert( FindLen >= 0 );
      assert( ReplaceLen >= 0 );
      defineAddLen(call->Definitions,Find,(uint)FindLen,Replace,(uint)ReplaceLen);
   }
   return True;
}

JSECALLSEQ( void ) jsePreDefineLong(jseContext jsecontext,
                                    const jsecharptr FindString,
                                    slong ReplaceL)
{
   JSE_API_STRING(ThisFuncName,"jsePreDefineLong");

   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,ThisFuncName,return);
   JSE_API_ASSERT_(FindString,2,ThisFuncName,return);

   defineAddInt(jsecontext->Definitions,FindString,ReplaceL);
}

   JSECALLSEQ( void )
jsePreDefineNumber(jseContext jsecontext,const jsecharptr findString,
                   jsenumber replaceL)
{
   JSE_API_STRING(ThisFuncName,"jsePreDefineNumber");

   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,ThisFuncName,return);
   JSE_API_ASSERT_(findString,2,ThisFuncName,return);

   defineAddFloat(jsecontext->Definitions,findString,replaceL);
}

   JSECALLSEQ( void )
jsePreDefineString(jseContext jsecontext,const jsecharptr FindString,
                   const jsecharptr ReplaceString)
{
   JSE_API_STRING(ThisFuncName,"jsePreDefineString");

   JSE_API_ASSERT_C(jsecontext,1,jseContext_cookie,ThisFuncName,return);
   JSE_API_ASSERT_(FindString,2,ThisFuncName,return);
   JSE_API_ASSERT_(ReplaceString,3,ThisFuncName,return);

   defineAdd(jsecontext->Definitions,FindString,ReplaceString);
}


/* search this context, and parent contexts for replacement string */
   const jsecharptr
defineFindReplacement(struct Define *this,const jsecharptr FindString)
{
   struct Define *define = this;
   do {
      struct Link *loc;
      uint lower = 0;
      uint middle;
      uint upper = define->linksUsed-1;
      int compare;

      if( define->linksUsed>0 )
      {
         for ( ; ; )
         {
            assert( lower<=upper );
            loc = define->links + (middle =  ((lower+upper) >> 1));
            compare = strcmp_jsechar(loc->Find,FindString);

            /* found it */
            if( compare==0 ) return loc->Replace;

            if( compare<0 )
            {
               if( middle==upper ) break;
               lower = middle + 1;
            }
            else
            {
               if( middle==lower ) break;
               upper = middle - 1;
            }
         }
      }
   } while ( NULL != (define = define->Parent) );
   return NULL;
}

#endif
