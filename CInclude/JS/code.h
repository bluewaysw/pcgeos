/* code.h - ScriptEase tokenizer (parsing tokens). Unfortunately, we
 *          historically used the name for 'tokenizing' code, this
 *          is part of the parsing, not precompilation. Still in 'code.h'
 *          for historic reasons.
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

#if !defined(_CODE_H)
#define _CODE_H

#if defined(__cplusplus)
   extern "C" {
#endif

#if (0!=JSE_COMPILER) \
 || ( ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) ) \
   && ( defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS) ) )
   extern CONST_DATA(jsecharptrdatum) IllegalVariableChars[];
#endif

#if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
#  if (0!=JSE_COMPILER) || ( defined(JSE_TOKENDST) && (0!=JSE_TOKENDST) )
      jsecharptr NEAR_CALL
      CompileRegExpLiteral(struct Call *call,jsecharptr src,jsebool *success,wSEVar wRet);
#  endif
#endif

#if (0!=JSE_COMPILER)

#define UNKNOWN_FILENAME UNISTR("no filename")

/* the tok structure now in call.h so we can compile */

   void
tokGetNext(struct tok *dest,struct secompile *compile);

#     define tokGetName(tok) ((tok)->Data.name)
#     define tokGetLine(tok) ((tok)->Data.lineNumber)
#     define tokType(t) ((t)->type)
#     define tokSetNameText(this,call,nam,len) \
        ((this)->Data.name = LockedStringTableEntry((call),(nam),(stringLengthType)(len)))
#     define tokSetName(this,nam) ((this)->Data.name = (nam))
#     define tokSetType(this,t) ((this)->type = (t))
#     define tokGetVarIndex(t) ((t)->Data.const_index)

   void NEAR_CALL
tokSetVar(struct tok *this,struct secompile *loc,rSEVar to_store);
   rSEVar NEAR_CALL
tokGetVar(struct secompile *loc,struct tok *this);


/* look one token ahead. Don't use up the token, the next
 * call to tokNext() should get it.
 */
   void
tokLookAhead(struct secompile *compile,struct tok *dest);

#if defined(JSE_REGEXP_LITERALS) && (0!=JSE_REGEXP_LITERALS)
   void
tokRegExp(struct secompile *compile,struct tok *ret);
#endif

#if (JSE_COMPILER==1) && \
       ( (defined(JSE_DEFINE) && (0!=JSE_DEFINE)) \
       || (defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)) \
       || (defined(JSE_LINK) && (0!=JSE_LINK)) )
   jsebool
PreprocessorDirective(struct Source **source,struct Call *call);
#endif

struct KeyWords_
{
   const jsecharptr Word;
   /* I changed this to an int because the enum being used was 1 byte
    * unsigned, so -1 was converted to '255' which when converted back
    * was not -1!
    */
   setokval Type;
};

extern CONST_DATA(struct KeyWords_) KeyWords[];

#if (0!=JSE_COMPILER)
   ulong BaseToULong(const jsecharptr HexStr,uint Base,uint MaxStrLen,
                     ulong MaxResult,uint *CharsUsed);
#endif

   jsecharptr NEAR_CALL
secompileStringToken(struct tok *tok,struct secompile *loc,
                     jsecharptr src,jsebool *success);
   setokval NEAR_CALL
GetVariableNameOrKeyword(struct tok *this,struct Call *call,
                         jsecharptr *RetSource);

   jsebool
CompileFromText(struct Call *call,jsecharptr * SourceText,jsebool SourceIsFileName);

#endif

#if defined(__cplusplus)
   }
#endif

#endif
