/* function.c   All that is left is the function->text routine
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


#if (0!=JSE_CREATEFUNCTIONTEXTVARIABLE)

/* ----------------------------------------------------------------------
   ------- start of writing function out as text ------------------------ */

/* We may want to move these functions out of the core
 * because they are big and rarely called.
 * MBCS Note: these functions are simplified for MBCS by always
 * allocating the max size that may be needed for MBCS.  When it
 * is all finally put into a string that will be optimized for
 * memory and the extra memory will be released.
 */

struct GrowingBuffer
{
   jsecharptr data;
   uint datalen;
   uint indent;
   jsebool do_indent;
};


   static jsebool NEAR_CALL
growingInit(struct Call *call,struct GrowingBuffer *this,uint init_indent)
{
   this->data = (jsecharptr) jseMallocWithGC(call,sizeof(jsechar));

   if( this->data==NULL ) return False;

   JSECHARPTR_PUTC(this->data,'\0');
   this->datalen = 0;
   this->indent = init_indent;
   this->do_indent = 0;

   return True;
}


   static void NEAR_CALL
growingTerm(struct GrowingBuffer *this)
{
   jseMustFree(this->data);
}

   static void NEAR_CALL
growingAddTo(struct GrowingBuffer *this,const jsecharptr text)
{
   uint newsize;
   uint i;

   if( strcmp_jsechar(text,UNISTR("}"))==0 )
   {
      assert( this->indent != 0 );
      this->indent--;
   }
   if( this->do_indent )
   {
      this->do_indent = False;
      for( i=0;i<this->indent;i++ )
         growingAddTo(this,UNISTR("   "));
   }

   newsize = this->datalen + strlen_jsechar(text);
   this->data = (jsecharptr) jseMustReMalloc(jsechar,this->data,(newsize+1)*sizeof(jsechar));
   strcat_jsechar(JSECHARPTR_OFFSET(this->data,this->datalen),text);
   this->datalen = newsize;

   if( strcmp_jsechar(text,UNISTR("\r\n"))==0 )
   {
      this->do_indent = True;
   }
   else if( strcmp_jsechar(text,UNISTR("{"))==0 )
   {
      this->indent++;
   }
}


static const jsecharptr tok_text[] =
{
   UNISTR("=="),
   UNISTR("==="),
   UNISTR("!="),
   UNISTR("++"),
   UNISTR("--"),
   UNISTR("<<"),
   UNISTR(">>>"),
   UNISTR(">>"),
   UNISTR("&&"),
   UNISTR("||"),
   UNISTR("*="),
   UNISTR("/="),
   UNISTR("%="),
   UNISTR("+="),
   UNISTR("-="),
   UNISTR("<<="),
   UNISTR(">>="),
   UNISTR(">>>="),
   UNISTR("&="),
   UNISTR("^="),
   UNISTR("|="),
   UNISTR("<="),
   UNISTR(">="),
   UNISTR("!==")
};


   void NEAR_CALL
functionTextAsVariable(const struct Function *this,struct Call *call,uint indent)
{
   wSEVar wRet = STACK_PUSH;
   struct GrowingBuffer buff;
   uint i;
   jsecharptr fname;

   SEVAR_INIT_UNDEFINED(wRet);

   if( !growingInit(call,&buff,indent) )
   {
      SEVAR_INIT_STRING_NULLLEN(call,wRet,UNISTR(""),0);
   }

# if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
   growingAddTo(&buff,( Func_CBehavior & this->flags )
                ? textcoreCFunctionKeyword : textcoreFunctionKeyword );
# else
   growingAddTo(&buff, textcoreFunctionKeyword );
# endif
   growingAddTo(&buff,UNISTR(" "));
   fname = functionName(this,call);
   growingAddTo(&buff,LFOM(fname));
   UFOM(fname);

   /* We can only print out the actual text of the function if it is a
    * localfunction (i.e. constructed from ScriptEase text.)
    */
   if( FUNCTION_IS_LOCAL(this) &&
       ((struct LocalFunction *)this)->tok.tokens!=NULL )
   {
      uint count;
      struct LocalFunction *func = (struct LocalFunction *)this;
      uint tok_index;
      struct tok *c;

      /* ----------------------------------------------------------------------
       * First spit out the parameters
       * ----------------------------------------------------------------------
       */

      growingAddTo(&buff,UNISTR("("));

      assert( !LOCAL_TEST_IF_INIT_FUNCTION((struct LocalFunction*)this,call) );

      for( count=0;count<func->InputParameterCount;count++ )
      {
         if( count )
            growingAddTo(&buff,UNISTR(","));

         /* In this case, we have a pass-by-reference parameter, so add & */
         if( func->items[count].VarAttrib )
            growingAddTo(&buff,UNISTR("&"));

         growingAddTo(&buff,GetStringTableEntry(call,func->items[count].VarName,NULL));
      }
      growingAddTo(&buff,UNISTR(")"));
      growingAddTo(&buff,UNISTR("\r\n"));
      growingAddTo(&buff,UNISTR("{"));
      growingAddTo(&buff,UNISTR("\r\n"));

      /* ----------------------------------------------------------------------
       * next spit out the locals, as either a 'var xxx;' or a 'function xxx'
       * based on the type.
       * ---------------------------------------------------------------------- */

      for( i=0;i<func->num_locals;i++ )
      {
         sword16 c;

         if( (c = func->items[i+func->InputParameterCount].VarFunc)!=-1 )
         {
            rSEVar rItVar;
            JSE_MEMEXT_R jsecharptr text;
            const struct Function *nextFunc;

            /* get the constant from local function to write to stack recursively */
            {
               /* this chunk of code is just to get nextFunc and free everything else */
               rSEObject robj;
               rSEObjectMem rMem;

               SEOBJECT_ASSIGN_LOCK_R(robj,func->hConstants);
               rMem = rseobjIndexMemberStruct(call,robj,c);
               SEOBJECT_UNLOCK_R(robj);
               assert( NULL != SEOBJECTMEM_PTR(rMem) );
               assert( jseTypeObject == SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem)) );
               SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(SEOBJECTMEM_VAR(rMem)));
               SEOBJECTMEM_UNLOCK_R(rMem);
               nextFunc = SEOBJECT_PTR(robj)->func;
               SEOBJECT_UNLOCK_R(robj);
            }
            functionTextAsVariable(nextFunc,call,buff.indent);
            rItVar = STACK0;
            assert( SEVAR_GET_TYPE(rItVar)==VString );
            text = sevarGetData(call,rItVar);
            growingAddTo(&buff,text);
            SEVAR_FREE_DATA(call,text);
            STACK_POP;
            growingAddTo(&buff,UNISTR("\r\n"));
         }
      }

      /* ----------------------------------------------------------------------
       * Then the body of the function
       * ----------------------------------------------------------------------
       */

      tok_index = 0;
      c = LOCL_TOKEN((struct LocalFunction *)this,tok_index);
      /* Skip initial EOLs */
      while( tokType(c)==seTokEOL )
      {
         c = LOCL_TOKEN((struct LocalFunction *)this,++tok_index);
      }

      while( tok_index<=LOCL_CURRENT_TOKEN_INDEX((struct LocalFunction *)this) &&
             tokType(c)!=seTokEOF )
      {
         setokval type = tokType(c);

         if( type<=127 )
         {
            jsechar buf[2];

            buf[0] = (jsechar)type;
            buf[1] = '\0';
            growingAddTo(&buff,(jsecharptr)buf);
         }
         else
         {
            uint j;

            for( j=0;KeyWords[j].Word!=NULL;j++ )
            {
               if( KeyWords[j].Type==type )
               {
                  growingAddTo(&buff,KeyWords[j].Word);
                  growingAddTo(&buff,UNISTR(" "));
                  break;
               }
            }
            if( KeyWords[j].Word==NULL )
            {
               if( type==seTokEOL )
               {
                  growingAddTo(&buff,UNISTR("\r\n"));
               }
               else if( type>=seTokEqual && type<=seTokStrictNotEqual )
               {
                  growingAddTo(&buff,tok_text[type-seTokEqual]);
               }
               else if( type==seTokIdentifier )
               {
                  growingAddTo(&buff,GetStringTableEntry(call,tokGetName(c),NULL));
               }
               else if( type==seTokConstant )
               {
                  rSEObject robj;
                  rSEObjectMem rMem;

                  SEOBJECT_ASSIGN_LOCK_R(robj,func->hConstants);
                  rMem = rseobjIndexMemberStruct(call,robj,c->Data.const_index);
                  SEOBJECT_UNLOCK_R(robj);
                  assert( NULL != SEOBJECTMEM_PTR(rMem) );

                 if( SEVAR_GET_TYPE(SEOBJECTMEM_VAR(rMem))!=VString )
                 {
                     wSEVar wVal = STACK_PUSH;
                     const jsecharptr tmp;

                     SEVAR_COPY(wVal,SEOBJECTMEM_VAR(rMem));
                     sevarConvertToString(call,wVal);
                     tmp = sevarGetData(call,wVal);
                     growingAddTo(&buff,tmp);
                     SEVAR_FREE_DATA(call,(JSE_MEMEXT_R void *)tmp);
                     STACK_POP;
                  }
                  else
                  {
                     jsecharptr val;
                     jsechar c;

                     growingAddTo(&buff,UNISTR("\""));

                     for( val = (jsecharptr)sevarGetData(call,SEOBJECTMEM_VAR(rMem));
                          0 != (c = JSECHARPTR_GETC(val));
                          JSECHARPTR_INC(val) )
                     {
                        jsechar tbuf[5];
                        jsecharptr tptr = (jsecharptr) tbuf;

                        /* We must escape quotes, otherwise "\"" will end up
                         * being """.  Similarly, we must escape \ to be \\
                         */
                        if( '\"' == c  ||  '\\' == c )
                        {
                           JSECHARPTR_PUTC(tptr,'\\');
                           JSECHARPTR_INC(tptr);
                           JSECHARPTR_PUTC(tptr,c);
                           JSECHARPTR_INC(tptr);
                           JSECHARPTR_PUTC(tptr,'\0');
                        }
                        else if( isprint_jsechar(c) )
                        {
                           JSECHARPTR_PUTC(tptr,c);
                           JSECHARPTR_INC(tptr);
                           JSECHARPTR_PUTC(tptr,'\0');
                        }
                        else
                        {
                           jse_sprintf(tptr,UNISTR("\\x%02x"),c);
                           /* if not enough characters, like "\3" insert extra 0 */
                        }
                        assert( strlen_jsechar((jsecharptr)tbuf) < sizeof(tbuf)/sizeof(jsechar) );
                        growingAddTo(&buff,(jsecharptr)tbuf);
                     }
                     growingAddTo(&buff,UNISTR("\""));
                     SEVAR_FREE_DATA(call,val);
                  }
                  SEOBJECTMEM_UNLOCK_R(rMem);
               }
            }
         }

         /* this cause an extra space in "Object .member"
         growingAddTo(&buff,UNISTR(" ")); */

         c = LOCL_TOKEN((struct LocalFunction *)this,++tok_index);
      }
      growingAddTo(&buff,UNISTR("}"));
      growingAddTo(&buff,UNISTR("\r\n"));
   }
   else
   {
       /* While this is not technically valid Javascript, it is a close
        * as we can come - there is no way to print out the text of a wrapper
        * function, which is written in C.
        */
       growingAddTo(&buff,UNISTR("();\r\n"));
   }

   SEVAR_INIT_STRING_NULLLEN(call,wRet,buff.data,buff.datalen);

   growingTerm(&buff);
}

/* ------- end of writing function out as text --------------------------
   ---------------------------------------------------------------------- */
#endif /* #if (0!=JSE_CREATEFUNCTIONTEXTVARIABLE) */
