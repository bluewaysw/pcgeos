/* operator.h  handle all numeric Javascript operators such as +, *, etc.
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

#ifndef _OPERATOR_H
#define _OPERATOR_H


#if (0!=JSE_COMPILER)
#  define PRI_ASSIGN         1
#  define PRI_CONDITIONAL    2
#  define PRI_LOGICAL_OR     3
#  define PRI_LOGICAL_AND    4
#  define PRI_BIT_OR         5
#  define PRI_BIT_XOR        6
#  define PRI_BIT_AND        7
#  define PRI_EQUALITY       8
#  define PRI_RELATIONAL     9
#  define PRI_SHIFT          10
#  define PRI_ADDITIVE       11
#  define PRI_MULT           12
#  define PRI_UNARY          13
#endif


struct opDesc
{
   setokval      token;
   jsecharptr    as_text;
   uword8        priority;
   secodeelem    operator;
};


#if (0!=JSE_COMPILER)
   struct opDesc * NEAR_CALL getTokDescription(setokval token);
#endif

   jsenumber NEAR_CALL
SpecialMathOnNonFiniteNumbers(struct Call *call,jsenumber lnum,
                              jsenumber rnum,secodeelem operation);

#if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
   jsebool NEAR_CALL
doOperatorOverloading( struct Call * call, wSEVar lhs, rSEVar rhs, secodeelem op );

#  if (defined(JSE_INLINES) && (0!=JSE_INLINES)) && 0==JSE_MEMEXT_OBJECTS
#     define IF_OPERATOR_NOT_OVERLOADED(call,lhs,rhs,op)                        \
         if( SEVAR_GET_TYPE(lhs)!=VObject ||                                    \
             !SEOBJ_IS_DYNAMIC(SEVAR_GET_OBJECT(lhs)) ||                        \
             !doOperatorOverloading(call,lhs,rhs,op) )
#  else
#     define IF_OPERATOR_NOT_OVERLOADED(call,lhs,rhs,op)                        \
         if( !doOperatorOverloading(call,lhs,rhs,op) )
#  endif

#else
#  define IF_OPERATOR_NOT_OVERLOADED(call,lhs,rhs,op)   /* nothing */
#endif

#endif

