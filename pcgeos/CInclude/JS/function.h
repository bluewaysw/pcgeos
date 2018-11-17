/* Function.h  Generic function stuff
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

#ifndef _FUNCTION_H
#define _FUNCTION_H

struct Function
{
   struct Function *next;

#  if 0 != JSE_MULTIPLE_GLOBAL
      hSEObject hglobal_object; /* NULL for jseFunc_NoGlobalSwitch */
#  endif

#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
      /* the security that this function has */
      struct Security *functionSecurity;
#  endif

   uword8 flags;          /* or of any of the following (used here and in
                             loclfunc.h and library.h) */
   uword8 attributes;


   /* Can't have more than 32K named parameters. */
   uword16 params;
};

#define Func_LocalFunction   0x01   /* else library function */
#define Func_CBehavior       0x02   /* else default javascript */
#define Func_SweepBit        0x20
#define Func_StaticLibrary   0x80   /* for library function: if True then must
                                     * free no data, else it's a dynamic
                                     * wrapper and data is not static */

#define FUNCTION_PARAM_COUNT(this) ((this)->params)

#define FUNCTION_IS_LOCAL(f) (((f)->flags & Func_LocalFunction)!=0)
#define FUNCTION_C_BEHAVIOR(f) (((f)->flags & Func_CBehavior)!=0)

   void NEAR_CALL
functionFullCall(struct Function *this,struct Call *CallerCall,uword8 attribs,
                 uint InputVariableCount,hSEObject hThisVar,jsebool constructor);
   jsebool NEAR_CALL
functionDoCall(struct Function *this,struct Call *CallerCall,
               uint InputVariableCount,hSEObject hthis_var_obj,uword8 attributes,
               jsebool constructor);

   const jsecharptr
functionName(const struct Function *this,struct Call *call);

   void
functionInit(struct Function *this,
             struct Call *call,
             rSEVar  ObjectToAddTo,
             jseVarAttributes FunctionVariableAttributes,
             jsebool iLocalFunction, /*else library*/
             jsebool iCBehavior,
                  /*else default javascript behavior*/
#            if 0 != JSE_MULTIPLE_GLOBAL
                jsebool iSwapGlobal,
#            endif
             sword16 Params);
   void
functionDelete(struct Function *this,struct Call *call);

   void NEAR_CALL
functionTextAsVariable(const struct Function *this,struct Call *call,uint indent);

#endif
