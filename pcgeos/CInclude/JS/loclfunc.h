/* loclfunc.h
 *
 * Handles 'local' functions. These are functions written in Javascript as
 * opposed to wrapper functions in compiled C/C++.
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

#ifndef _LOCLFUNC_H
#define _LOCLFUNC_H


struct localItem
{
   VarName VarName;           /* for locals, if associated VarFunc!=-1
                               * then it could be a dot-named variable
                               */
   uword8  VarAttrib;
   sword16 VarFunc;           /* one of the constants, -1 = not a function */
};


struct LocalFunction
{
   struct Function function;

   /* after the code has been compiled, the following fields will contained
      the compiled information */
#  if JSE_MEMEXT_SECODES==1
      jsememextHandle op_handle;
#  else
      secode opcodes;
#  endif
   uint opcodesUsed;

   uword16 InputParameterCount;
   uword16 num_locals;

   uword16 max_params;

   VarName FunctionName;


   /* This is InputParameterCount+num_locals in size */
   struct localItem *items;
   uword16 alloced;                /* size of the above arrays */


   /* Store all the constants this function uses so the garbage collector
    * can mark it without having to go through all the secodes. Like ScopeChains,
    * it is much easier to use an unordered object to serve storage duties
    */
   hSEObject hConstants;

#  if (0!=JSE_COMPILER)
      struct {
         struct tok *tokens;
         uint alloced;  /* how many allocated */
         uint used;     /* how many of those allocated are used */
      } tok;
#  endif
};

   struct LocalFunction *
localNew(struct Call *call,VarName iFunctionName,
#  if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
           jsebool CBehavior,
#  endif
           rSEVar add_to
         );

   void
localDelete(struct Call *call,struct LocalFunction *lf);

#if (0!=JSE_COMPILER)
   /* grab the next token to the list of tokens and return it */
   struct tok * secompileNextToken(struct secompile *compile);
   /* Put the filename and linenumber at the end too. Shrink
    * number of tokens to exactly needed size
    */
   void NEAR_CALL localMinimizeTokens(struct LocalFunction *lf,jsebool FreeAll/*else condense*/);

#  define LOCL_CURRENT_TOKEN(lf) ((lf)->tok.tokens + (lf)->tok.used - 1)
#  define LOCL_PREV_TOKEN(lf) ((lf)->tok.tokens + (lf)->tok.used - 2)
#  define LOCL_TOKEN(lf,i) ((lf)->tok.tokens + i)
#  define LOCL_CURRENT_TOKEN_INDEX(lf) ((lf)->tok.used - 1)
#  define LOCL_NEW_TOKEN(lf) ((lf)->tok.tokens + ((lf)->tok.used)++)

   /* Delete from i to the end */
#  define LOCL_DELETE_TOKENS(lf,i) ((lf)->tok.used = i)

#endif


   sint
localAddVarName(struct LocalFunction *this,struct Call * call,VarName name);


/* both of the next return -1 = not found */
   sword16
loclFindLocal(struct LocalFunction *this,VarName name);
#if (0!=JSE_COMPILER)
   sword16 loclFindParam(struct LocalFunction *this,VarName name);
#endif
/* A new local variable for this function */
   sword16
loclAddLocal(struct Call *call,struct LocalFunction *this,VarName name);

#if (0!=JSE_COMPILER)
   MemCountUInt secompileCreateConstant(struct secompile *compile,rSEVar constant);
#endif



#define LOCAL_TEST_IF_INIT_FUNCTION(this,call) \
           (STOCK_STRING(Global_Initialization) == (this)->FunctionName)

#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   void NEAR_CALL
localTokenWrite(struct LocalFunction *this,struct Call *call,
                struct TokenSrc *tSrc);
#endif

#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
   void
tokenWriteAllLocalFunctions(struct TokenSrc *this,struct Call *call);
   void
localTokenRead(struct Call *call,struct TokenDst *tDst,rSEVar dest);
#endif



/* ----------------------------------------------------------------------
 * All code tokens are now part of a particular local function and
 * are referenced by index.
 * ----------------------------------------------------------------------
 */

#endif
