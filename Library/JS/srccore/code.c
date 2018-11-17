/* code.c  Determine next code card from the input string.
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
#if (0!=JSE_COMPILER)



   static void NEAR_CALL
tokFilename(struct tok *t,struct Call *call)
{
   const jsecharptr name;
   struct CompileStatus_ *status = &(call->Global->CompileStatus);

   if(  NULL != (status->CompilingFileName =
                 SOURCE_FILENAME(status->src)) )
   {
      name = status->CompilingFileName;
   }
   else
   {
      name = UNKNOWN_FILENAME;
   }
   tokSetType(t,seTokFilename);
   tokSetNameText(t,call,name,strlen_jsechar(name));
}

   static void NEAR_CALL
tokLineNumber(struct tok *t,struct Call *call)
{
   tokSetType(t,seTokLineNumber);
   t->Data.lineNumber = call->Global->CompileStatus.CompilingLineNumber;
}

rSEVar NEAR_CALL tokGetVar(struct secompile *compile,struct tok *this)
{
   assert( NULL != SEMEMBERS_PTR(compile->constMembers) );
   return &((SEMEMBERS_PTR(compile->constMembers) + this->Data.const_index)->value);
}

   void NEAR_CALL
tokSetVar(struct tok *this,struct secompile *compile,rSEVar to_store)
{
   tokSetType(this,seTokConstant);
   this->Data.const_index = secompileCreateConstant(compile,to_store);
}

   jsebool
CompileFromText(struct Call *call,jsecharptr * SourceText,jsebool SourceIsFileName)
{
   struct Source *source,*prev_source;
   struct CompileStatus_ oldStatus;
   struct LocalFunction *newfunc;
   jsebool success;
   struct tok token;
   wSEVar wLocVar;
   jsebool found;
   wSEObject wGlobalObj;
   wSEObjectMem wInitObjectMem;
   struct CompileStatus_ *status = &(call->Global->CompileStatus);

   oldStatus = *status;
   status->NowCompiling++;
   assert( 0 != status->NowCompiling );

#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
   if ( SourceIsFileName )
   {
      source = sourceNewFromFile(call,NULL,*SourceText,&success);
      if ( success )
      {
         jseMustFree(*SourceText);
         *SourceText = StrCpyMalloc(SOURCE_FILENAME(source)
                                   ?(SOURCE_FILENAME(source)):UNISTR("stdin"));
      }
   }
   else
#  endif
   {
      /* source is only from text line */
      source = sourceNewFromText(NULL,*SourceText) ;
      success = True;
   }

   if( !success )
   {
      if( source ) sourceDelete(source,call);
      return False;
   }

   status->src = source;
   status->srcptr = sourceGetPtr(source);

   SEOBJECT_ASSIGN_LOCK_W(wGlobalObj,CALL_GLOBAL(call));
   wInitObjectMem = seobjNewMember(call,wGlobalObj,
                                   STOCK_STRING(Global_Initialization),&found);
   wLocVar = SEOBJECTMEM_VAR(wInitObjectMem);
   SEOBJECT_UNLOCK_W(wGlobalObj);
   SEVAR_INIT_BLANK_OBJECT(call,wLocVar);
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
      newfunc = localNew(call,STOCK_STRING(Global_Initialization),
                         (jsebool)(jseOptDefaultCBehavior &
                                   call->Global->ExternalLinkParms.options),wLocVar);
#  else
      newfunc = localNew(call,STOCK_STRING(Global_Initialization),wLocVar);
#  endif
   if( newfunc==NULL )
   {
      callQuit(call,textcoreOUT_OF_MEMORY);
      return False;
   }
   SEOBJECTMEM_UNLOCK_W(wInitObjectMem);

   status->CompilingFileName =
      SOURCE_FILENAME(status->src);

   success = secompileFunctionBody(newfunc,call,True,&token);
   /* Either there was an error or we parsed it all */
   assert( CALL_QUIT(call) || token.type==seTokEOF );

   /* tell error reporting that no longer compiling */
   status->CompilingFileName = NULL;

   /* delete all source objects */
   source = status->src;
   assert( NULL != source );
   do {
      prev_source = sourcePrev(source);
      sourceDelete(source,call);
   } while ( NULL != (source = prev_source) );

   assert( 0 != status->NowCompiling );
   *status = oldStatus;

   return success;
}


/* If we don't already have a look-ahead token, get one and store it,
 * then return that look ahead token.
 */
   void
tokLookAhead(struct secompile *compile,struct tok *dest)
{
   struct CompileStatus_ *status = &(compile->call->Global->CompileStatus);

   if( !status->look_used )
   {
      tokGetNext(&(status->look_ahead),compile);
      status->look_used = True;
   }

   *dest = status->look_ahead;
}


/* Will always return a token, it returns a seTokEOF on failure
 * (along with an appropriate message to callQuit.)
 */
   void
tokGetNext(struct tok *dest,struct secompile *compile)
{
   uint CommentDepth = 0;
   jsebool success;
   jsechar theChar,nextChar;
   struct Call *call = compile->call;

   struct CompileStatus_ *status = &(call->Global->CompileStatus);

   if( CALL_QUIT(call) ) goto eof_return;

   if( status->look_used )
   {
      *dest = status->look_ahead;
      status->look_used = False;
      return;
   }


   if( status->new_source )
   {
      tokLineNumber(dest,call);
      status->new_source = False;
      return;
   }

   /* else we need to parse the next token out of the source text,
    * link it in, and return it.
    */
   for( ;; )
   {
      if ( UNICHR('\0') == JSECHARPTR_GETC(status->srcptr) )
      {
         /* Set up to process the next source line and return the
          * line number/filename tokens.
          */
      EndOfSourceLine:
         if( status->src==NULL ) goto eof_return;
         if ( !sourceNextLine(status->src,call,
                              0!=CommentDepth,&success) )
         {
            /* no more source from this place, go back to source
             * that included us.
             */
            struct Source *PrevSource;

            PrevSource = sourcePrev(status->src);
            if ( NULL == PrevSource )
            {
               goto eof_return;
            }
            assert( NULL != status->src );
            sourceDelete(status->src,call);
            status->src = PrevSource;

            /* Comments must not span files. */
            if ( CommentDepth )
            {
               callError(call,textcoreEND_COMMENT_NOT_FOUND);
               goto eof_return;
            }
            tokFilename(dest,call);
            /* remind ourselves we will also need to send the linenumber */
            status->new_source = True;
            status->srcptr = sourceGetPtr(status->src);
            return;
         }
         else
         {
            status->srcptr = sourceGetPtr(status->src);
            if( status->src->define==False &&
                0==CommentDepth ) goto eol_return;
         }
      }

      theChar = JSECHARPTR_GETC(status->srcptr);
      nextChar = JSECHARPTR_GETC(JSECHARPTR_NEXT(status->srcptr));
      if ( 0 != CommentDepth )
      {
         if ( UNICHR('*') == theChar )
         {
            if ( UNICHR('/') == nextChar )
            {
               CommentDepth--;
               JSECHARPTR_INC(status->srcptr);
            }
         }
         else if ( UNICHR('/') == theChar )
         {
            if ( UNICHR('*') == nextChar )
            {
               /* CommentDepth++; */
               /* Rich: comments do not nest */
               JSECHARPTR_INC(status->srcptr);
            }
         }
      }
      else if ( !IS_WHITESPACE(theChar) )
      {
         setokval Type = seTokUnknown;
#ifdef __JSE_GEOS__
/* allow HTML style comments in scripts, only checked here */
#define JSE_HTML_COMMENT_STYLE 1
#endif
#        if defined(JSE_HTML_COMMENT_STYLE) && (JSE_HTML_COMMENT_STYLE==1)
         if( !strncmp_jsechar(status->srcptr,UNISTR("<!--"),4) )
         {
            goto EndOfSourceLine;
         }
         else
#        endif
         if ( theChar == nextChar  &&  NULL != strchr_jsechar(UNISTR("+-<>&|=/"),theChar) )
         {
            /* Handle certain cases where two of the same character is
             * different than one.
             */
            JSECHARPTR_INC(status->srcptr);
            switch ( theChar )
            {
               case UNICHR('-'):   Type = seTokDecrement;     break;
               case UNICHR('+'):   Type = seTokIncrement;     break;
               case UNICHR('<'):   Type = seTokShiftLeft;     break;
               case UNICHR('>'):   Type = seTokSignedShiftRight; break;
               case UNICHR('&'):   Type = seTokLogicalAND;    break;
               case UNICHR('|'):   Type = seTokLogicalOR;     break;
               case UNICHR('='):
                  /* Handle strict equality operator (===) */
               {
                  /* Check for a third = in a row */
                  if( UNICHR('=') == JSECHARPTR_GETC(JSECHARPTR_NEXT(status->srcptr)) )
                  {
                     JSECHARPTR_INC(status->srcptr);  /* Skip past third = */
                     Type = seTokStrictEqual;
                  }
                  else
                  {  /* Otherwise this is just a normal == operator */
                     Type = seTokEqual;
                  }
                  break;
               }
               case UNICHR('/'):   /* Comment to end of line (or end of call->Global->CompileStatus.srcptr) */
                  goto EndOfSourceLine;
#              ifndef NDEBUG
               default:
                  assert( JSE_DEBUG_FEEDBACK(False) );
#              endif
            }
            if( Type==seTokSignedShiftRight &&
                JSECHARPTR_GETC(JSECHARPTR_NEXT(status->srcptr))==
                UNICHR('>') )
            {
               JSECHARPTR_INC(status->srcptr);
               Type = seTokUnsignedShiftRight;
            }
         }
         else
         {
            switch( theChar )
            {
               case '*':
                  if ( UNICHR('/') == nextChar )
                  {
                     callError(call,textcoreNO_BEGIN_COMMENT);
                     success = False;
                  }
                  Type = '*';
                  break;
               case '/':
                  if ( UNICHR('*') == nextChar )
                  {
                     /* comment - remove up to "* /" */
                     assert( 0 == CommentDepth );
                     CommentDepth = 1;
                     JSECHARPTR_INC(status->srcptr);
                     JSECHARPTR_INC(status->srcptr);
                     continue;
                  }
                  else
                  {
                     Type = '/';
                  }
                  break;

               case UNICHR('%'): case UNICHR('&'): case UNICHR('^'):
#              if defined(JSE_UNICODE) && (0!=JSE_UNICODE) && defined(__WATCOMC__)
               case UNICHR('\~'):
#              else
               case UNICHR('~'):
#              endif
               case UNICHR('|'): case UNICHR('='): case UNICHR('<'):
               case UNICHR('>'): case UNICHR('?'): case UNICHR(':'):
               case UNICHR(','): case UNICHR('{'): case UNICHR('}'):
               case UNICHR(';'): case UNICHR('('): case UNICHR(')'):
               case UNICHR('['): case UNICHR(']'): case UNICHR('!'):
               case UNICHR('-'): case UNICHR('+'):
                  Type = (setokval)theChar;
                  assert( Type==theChar );
                  break;

               case UNICHR('\''): /* these are the same except that single quote */
               case UNICHR('\"'): /* can be a non-array and if more than one     */
               case UNICHR('`'): /*  then it doesn't end in null. And back-tick */
                  /* means no escape sequences                   */
                  status->srcptr = secompileStringToken(dest,compile,status->srcptr,&success);
                  if( !success )
                     dest->type = seTokEOF;
                  else
                     dest->type = seTokConstant;
                  return;
#              if (defined(JSE_DEFINE) && (0!=JSE_DEFINE)) \
               || (defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)) \
               || (defined(JSE_LINK) && (0!=JSE_LINK))
               case UNICHR('#'):
               {
                  struct Source *old_source = status->src;

                  sourceSetPtr(status->src,
                               status->srcptr);
                  if ( !PreprocessorDirective(&status->src,call) )
                  {
                     goto eof_return;
                  }
                  status->srcptr =
                     sourceGetPtr(status->src);
                  if( old_source != status->src )
                  {
                     tokFilename(dest,call);
                     /* Remind to also send linenumber next time */
                     status->new_source = True;
                     return;
                  }
               }  continue;
#              endif
               case UNICHR('.'):
                  if ( isdigit_jsechar(nextChar) )
                  {
                     /* this is part of a number */
#                    if (0!=JSE_FLOATING_POINT)
                        goto sourceNumber;
#                    else
                        callError(call,textcoreNO_FLOATING_POINT);
                        goto eof_return;
#                    endif
                  }
                  else
                  {
                     Type = '.';
                  }
                  break;
               case UNICHR('0'):case UNICHR('1'):case UNICHR('2'):
               case UNICHR('3'):case UNICHR('4'):case UNICHR('5'):
               case UNICHR('6'):case UNICHR('7'):case UNICHR('8'):
               case UNICHR('9'):
#              if (0!=JSE_FLOATING_POINT)
               sourceNumber:
#              endif
               {
                  wSEVar wVar = STACK_PUSH;
                  jsebool AssignSuccess;

                  SEVAR_INIT_UNDEFINED(wVar);

                  /* seems backwards to set the var then fill it in,
                   * but this prevents the var from being garbage collected
                   * during the lengthy AssignFromText() call
                   */
                  if( !sevarAssignFromText(wVar,call,status->srcptr,
                                           &AssignSuccess,False,
                                           &status->srcptr) )
                  {
                     STACK_POP;
                     goto eof_return;
                  }
                  tokSetVar(dest,compile,wVar);
                  dest->type = seTokConstant;
                  assert( VNumber == SEVAR_GET_TYPE(wVar) );
                  STACK_POP;
                  return;
               }

               default:
                  if( NULL != strchr_jsechar((jsecharptr)IllegalVariableChars,theChar) )
                  {
                     callError(call,textcoreBAD_CHAR,theChar,theChar);
                     goto eof_return;
                  }

                  Type = GetVariableNameOrKeyword(dest,call,
                                                  &status->srcptr);
                  if( Type==seTokUnknown )
                  {
                     goto eof_return;
                  }

#                 if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
                  if ( seTokIdentifier == Type )
                  {
                     const jsecharptr ReplaceCallSource;
                     if ( NULL != (ReplaceCallSource =
                                   defineFindReplacement(call->Definitions,
                                      GetStringTableEntry(call,tokGetName(dest),NULL))) )
                     {
                        /* source points to new code to replace for old.
                         * Since this is a #define, we don't try to change
                         * the filename
                         */
                        sourceSetPtr(status->src,
                                     status->srcptr);
                        status->src =
                           sourceNewFromText(status->src,
                                             ReplaceCallSource);
                        status->srcptr =
                           sourceGetPtr(status->src);
                        status->src->define = True;
                        continue;
                     }
                  }
#                 endif
                  return;
            } /* switch() */
         }

         /* Lots of code cards can be followed by '=' to make them mean
          * something else.  Handle those here.
          */
         if ( UNICHR('=') ==
              JSECHARPTR_GETC(JSECHARPTR_NEXT(status->srcptr)) )
         {
            jsecharptr save = status->srcptr;
            JSECHARPTR_INC(status->srcptr);
            switch ( Type )
            {
               case '*': Type = seTokTimesEqual; break;
               case '/': Type = seTokDivEqual; break;
               case '%': Type = seTokModEqual; break;
               case '+': Type = seTokPlusEqual; break;
               case '-': Type = seTokMinusEqual; break;
               case seTokShiftLeft: Type = seTokShiftLeftEqual; break;
               case seTokSignedShiftRight: Type = seTokSignedShiftRightEqual; break;
               case seTokUnsignedShiftRight: Type = seTokUnsignedShiftRightEqual; break;
               case '&': Type = seTokAndEqual; break;
               case '^': Type = seTokXorEqual; break;
               case '|': Type = seTokOrEqual; break;
               case '<': Type = seTokLessEqual; break;
               case '>': Type = seTokGreaterEqual; break;
               case '!':
               {
                  /* Here we have to check for != and strict compare, !== */
                  if( UNICHR('=') == JSECHARPTR_GETC(JSECHARPTR_NEXT(status->srcptr)) )
                  {
                     JSECHARPTR_INC(status->srcptr);  /* Skip past second equal sign */
                     Type = seTokStrictNotEqual;
                  }
                  else
                  {  /* Otherwise this is just a normal != */
                     Type = seTokNotEqual;
                  }
                  break;
               }
               default:
                  /* not special */ status->srcptr = save;
               break;
            }
         }
         JSECHARPTR_INC(status->srcptr);
         tokSetType(dest,Type);
         return;
      }

      /* else was a whitespace, skip it and continue the outer loop */
      JSECHARPTR_INC(status->srcptr);
      if( CommentDepth==0 && (theChar=='\n' || theChar=='\r'
#         if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
          || theChar==(jsechar)0x2028 || theChar==(jsechar)0x2029
#         endif
          ) )
      {
         /* If we are at the end of a line, we don't want two seTokEOL's
          * showing up.
          */
         if( JSECHARPTR_GETC(status->srcptr)=='\0' )
            continue;

      eol_return:
         /* a newline, add that into the token stream so that auto-semicolon
          * insertion can be done correctly.
          */
         tokSetType(dest,seTokEOL);
         return;
      }
   }

 eof_return:
   if( CommentDepth )
   {
      callError(call,textcoreEND_COMMENT_NOT_FOUND);
   }

   tokSetType(dest,seTokEOF);
   return;
}


#if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
/* 'ret' is the old token (either '/' or '/=') which really is starting
 * a regular expression. Replace it with the new value.
 */
   void
tokRegExp(struct secompile *compile,struct tok *ret)
{
   struct Call *call = compile->call;
   struct CompileStatus_ *status = &(call->Global->CompileStatus);
   wSEVar wVar = STACK_PUSH;
   jsebool success;

   SEVAR_INIT_UNDEFINED(wVar);

   assert( ret->type=='/' || ret->type==seTokDivEqual );
   if( ret->type=='/' )
   {
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      assert( JSECHARPTR_GETC((jsecharptr)(((ubyte *)status->srcptr)-
                                     BYTECOUNT_FROM_STRLEN("/",1)))=='/' );
      status->srcptr =
         (jsecharptr)(((ubyte *)status->srcptr)-
                      BYTECOUNT_FROM_STRLEN("/",1));
#  else
      assert( status->srcptr[-1]=='/' );
      status->srcptr--;
#  endif
   }
   else
   {
#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
      assert( JSECHARPTR_GETC((jsecharptr)(((ubyte *)status->srcptr)-
                                        BYTECOUNT_FROM_STRLEN("/=",2)))=='/' );
      status->srcptr =
         (jsecharptr)(((ubyte *)status->srcptr)-
                      BYTECOUNT_FROM_STRLEN("/=",2));
#  else
      assert( status->srcptr[-2]=='/' );
      assert( status->srcptr[-1]=='=' );
      status->srcptr -= 2;
#  endif
   }

   status->srcptr = CompileRegExpLiteral(call,status->srcptr,&success,wVar);
   if( !success )
   {
      tokSetType(ret,seTokEOF);
   }
   else
   {
      tokSetType(ret,seTokConstant);
      tokSetVar(ret,compile,wVar);
   }

   STACK_POP;
}
#endif /* #if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) */

#endif /* #if (0!=JSE_COMPILER) */
