/* operator.c
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


   jsenumber NEAR_CALL
SpecialMathOnNonFiniteNumbers(struct Call *call,jsenumber lnum,
                              jsenumber rnum,secodeelem operation)
   /* follow special rules for math on non-finite numbers */
{
   jsenumber ret = jseNaN;
   assert( !jseIsFinite(lnum) || !jseIsFinite(rnum) );

   /* all operators return NaN is either is NaN */
   if ( jseIsNaN(lnum) || jseIsNaN(rnum) )
   {
      if( (jseOptWarnBadMath & call->Global->ExternalLinkParms.options) )
         callError(call,textcoreIS_NAN);
   }
   else
   {
      jsebool lneg, rneg, linf, rinf;
      DoMathAgain:
      /* one or the other of our operators is Infinity or NegInfinty */
      lneg = jseIsNegative(lnum);
      rneg = jseIsNegative(rnum);
      linf = jseIsInfOrNegInf(lnum);
      rinf = jseIsInfOrNegInf(rnum);

      assert( linf || rinf );
      assert( lneg == True  ||  lneg == False );
      assert( rneg == True  ||  rneg == False );
      assert( linf == True  ||  linf == False );
      assert( rinf == True  ||  rinf == False );

      switch( operation )
      {
         case seAdd:
         case seSubtract:
            if ( seSubtract == operation )
            {
               rnum = JSE_FP_NEGATE(rnum);
               operation = seAdd;
               goto DoMathAgain;
            }
            if ( !linf )
            {
               /* eaiest to assume loperator is inf; try again */
               goto SwitchNumbersAndTryAgain;
            }
            assert( linf  &&  seSubtract != operation );
            if ( rinf )
            {
               /* left and right are both inf; if same sign inf else NaN */
               ret = ( lneg == rneg ) ? lnum : jseNaN ;
            }
            else
            {
               /* lnum is inf, and right is finite, so return lnum */
               ret = lnum;
            }
            break;
         case seDivide:
            /* anyinf / anyinf == NaN */
            if ( linf )
            {
               /* numerator is infinite */
               if ( rinf )
               {
                  /* inf / inf is NaN, which is the default */
               }
               else
               {
                  /* inf / anything = inf */
                  ret = ( lneg == rneg ) ? jseInfinity : jseNegInfinity ;
               }
            }
            else
            {
               /* numerator is not inf; denominator is inf */
               assert( rinf );
               ret = (rneg != lneg )? jseNegZero : jseZero ;
            }
            break;
         case seMultiply:
            if ( !linf )
            {
               /* easiest to assume loperator is inf; try again */
               goto SwitchNumbersAndTryAgain;
            }
            if ( rinf || !jseIsZero(rnum) )
            {
               /* inf * inf == inf */
               ret = ( lneg == rneg ) ? jseInfinity : jseNegInfinity ;
            }
            else
            {
               assert( jseIsZero(rnum) );
               /* inf * 0 == NaN */
            }
            break;
         case seModulo:
            if ( linf )
            {
               /* inf % anything == NaN */
            }
            else
            {
               assert( rinf );
               /* anything % inf == anything */
               ret = lnum;
            }
            break;

#        ifndef NDEBUG
         default: assert( False ); break;
#        endif
      }
   }
   return ret;
SwitchNumbersAndTryAgain:
   {
      /* want to swith lnum and rnum */
      jsenumber temp = lnum;
      lnum = rnum;
      rnum = temp;
      goto DoMathAgain;
   }
}


#if (0!=JSE_COMPILER) \
 || ( defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING) )
/* ----------------------------------------------------------------------
 * The operator table used for parsing operators. Contains the various
 * information about the operator: (1) the token, (2) a text version
 * of the token, (3) its priority, and (4) the secode to generate.
 * On (4), if it is -1, that indicates a special operator that
 * requires more complex code to implement.
 *
 * Because the tokens are not contiguous, the table must be searched.
 * No big deal, this happens during compile-time only.
 */
static CONST_DATA(struct opDesc) opDescTable[] =
{
   { 0, UNISTR(""), 0,(secodeelem)-1 },

   /* delete only actually does anything if it is an EXPR_MEMBER or
    * an EXPR_ARRAY, else it becomes always true.
    */
   { seTokDelete,       UNISTR("delete"),       PRI_UNARY,      (secodeelem)-1 },
   /* typeof has to do special if it is EXPR_GLOBAL, namely return
    * "undefined" if the item does not yet exist.
    */
   { seTokTypeof,       UNISTR("typeof"),       PRI_UNARY,      (secodeelem)-1 },

   { seTokInstanceof,   UNISTR("instanceof"),   PRI_RELATIONAL, seInstanceof },
   { seTokIn,           UNISTR("in"),           PRI_RELATIONAL, seIn },

   { seTokDecrement,    UNISTR("--"),           PRI_UNARY,      (secodeelem)-1 },
   { seTokIncrement,    UNISTR("++"),           PRI_UNARY,      (secodeelem)-1 },

   { seTokVoid,         UNISTR("void"),         PRI_UNARY,      (secodeelem)-1 },
   { '!',               UNISTR("!"),            PRI_UNARY,      seBoolNot },
   { '~',               UNISTR("~"),            PRI_UNARY,      seBitNot },

   /* for the assignment operators, the normal operator is in the
    * table, i.e. += is 'seAdd', *= is 'seMultiply', etc.
    */
   { '=',               UNISTR("="),            PRI_ASSIGN,     (secodeelem)-1 },
   { seTokDivEqual,     UNISTR("/="),           PRI_ASSIGN,     seDivide },
   { seTokTimesEqual,   UNISTR("*="),           PRI_ASSIGN,     seMultiply },
   { seTokModEqual,     UNISTR("%="),           PRI_ASSIGN,     seModulo },
   { seTokPlusEqual,    UNISTR("+="),           PRI_ASSIGN,     seAdd },
   { seTokMinusEqual,   UNISTR("-="),           PRI_ASSIGN,     seSubtract },
   { seTokShiftLeftEqual,UNISTR("<<="),         PRI_ASSIGN,     seShiftLeft },
   { seTokSignedShiftRightEqual,UNISTR(">>="),  PRI_ASSIGN,     seSignedShiftRight },
   { seTokUnsignedShiftRightEqual,UNISTR(">>>="),PRI_ASSIGN,    seUnsignedShiftRight },
   { seTokAndEqual,     UNISTR("&="),           PRI_ASSIGN,     seBitAnd },
   { seTokXorEqual,     UNISTR("^="),           PRI_ASSIGN,     seBitXor },
   { seTokOrEqual,      UNISTR("|="),           PRI_ASSIGN,     seBitOr },

   { '/',               UNISTR("/"),            PRI_MULT,       seDivide },
   { '*',               UNISTR("*"),            PRI_MULT,       seMultiply },
   { '%',               UNISTR("%"),            PRI_MULT,       seModulo },

   { '+',               UNISTR("+"),            PRI_ADDITIVE,   seAdd },
   { '-',               UNISTR("-"),            PRI_ADDITIVE,   seSubtract },

   { '<',               UNISTR("<"),            PRI_RELATIONAL, seLess },
   { seTokGreaterEqual, UNISTR(">="),           PRI_RELATIONAL, seGreaterEqual },
   { '>',               UNISTR(">"),            PRI_RELATIONAL, seGreater },
   { seTokLessEqual,    UNISTR("<="),           PRI_RELATIONAL, seLessEqual },

   { seTokEqual,        UNISTR("=="),           PRI_EQUALITY,   seEqual },
   { seTokNotEqual,     UNISTR("!="),           PRI_EQUALITY,   seNotEqual },
   { seTokStrictEqual,  UNISTR("==="),          PRI_EQUALITY,   seStrictEqual },
   { seTokStrictNotEqual,UNISTR("!=="),         PRI_EQUALITY,   seStrictNotEqual },

   { seTokShiftLeft,    UNISTR("<<"),           PRI_SHIFT,      seShiftLeft },
   { seTokSignedShiftRight,UNISTR(">>"),        PRI_SHIFT,      seSignedShiftRight },
   { seTokUnsignedShiftRight,UNISTR(">>>"),     PRI_SHIFT,      seUnsignedShiftRight },
   { '&',               UNISTR("&"),            PRI_BIT_AND,    seBitAnd },
   { '^',               UNISTR("^"),            PRI_BIT_XOR,    seBitXor },
   { '|',               UNISTR("|"),            PRI_BIT_OR,     seBitOr },

   { seTokLogicalAND,   UNISTR("&="),           PRI_LOGICAL_AND,(secodeelem)-1 },
   { seTokLogicalOR,    UNISTR("|="),           PRI_LOGICAL_OR, (secodeelem)-1 },
   { '?',               UNISTR("?"),            PRI_CONDITIONAL,(secodeelem)-1 }
};
#endif

#if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
/* Operator overloading - This is a Nombas extension which allows C++ style operator
 * overloading.  If the left variable is an object and has the special _operator property,
 * then we will call that with the name of the operator and the optional right variable,
 * if this operator has a right variable.
 */
   static struct opDesc * NEAR_CALL
getOpDescription(secodeelem operator)
{
   struct opDesc * ret;

   /* condense all crement operators down to these few cases. */
   if( operator==seIncOnlyLocal )
   {
      ret = getTokDescription(seTokIncrement);
   }
   else if( operator==seDecOnlyLocal )
   {
      ret = getTokDescription(seTokDecrement);
   }
   else
   {
      ret = (struct opDesc *)opDescTable + (sizeof(opDescTable)/sizeof(opDescTable[0]));
      while ( opDescTable != --ret )
      {
         if ( ret->operator == operator  &&  PRI_ASSIGN != ret->priority )
            break;
      }
   }
   assert( opDescTable < ret  );
   return ret;
}

   jsebool NEAR_CALL
doOperatorOverloading( struct Call * call, wSEVar lhs, rSEVar rhs, secodeelem op )
{
   VarName operatorName;
   jsecharptr desc;
   wSEVar res;
   jsebool ret;
   rSEObject robj;

#  if (!defined(JSE_INLINES) || (0==JSE_INLINES)) || 0!=JSE_MEMEXT_OBJECTS
   if( VObject != SEVAR_GET_TYPE(lhs) )
   {
      return False;
   }
   else
   {
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(lhs));
      if( !SEOBJ_IS_DYNAMIC(robj) )
      {
         SEOBJECT_UNLOCK_R(robj);
         return False;
      }
   }
#  else
      SEOBJECT_ASSIGN_LOCK_R(robj,SEVAR_GET_OBJECT(lhs));
#  endif

   assert( SEVAR_GET_TYPE(lhs)==VObject );

   /* Operators (if overloaded) are few in number and probably will be used
    * multiple times, so it makes more sense to lock it.
    */
   desc = (op==seAssignLocal)?UNISTR("="):getOpDescription(op)->as_text;
   operatorName = LockedStringTableEntry(call,desc,(stringLengthType)strlen_jsechar(desc));

   res = STACK_PUSH;
   SEVAR_INIT_UNDEFINED(res);

   /* Can't just overwrite lhs, as we are passing along a member of it */
   ret = seobjCallDynamicProperty(call,robj,dynacallOperator,operatorName,rhs,res);
   SEOBJECT_UNLOCK_R(robj);

   if( ret )
   {
      SEVAR_COPY(lhs,res);
   }

   /* If 2nd operator, and we are not doing the regular thing, get rid of it */
   if( ret && op!=seAssignLocal && rhs!=NULL )
   {
      STACK_POPX(2);
   }
   else
   {
      STACK_POP;
   }

   return ret;
}

#endif

#if (0!=JSE_COMPILER)
   struct opDesc * NEAR_CALL
getTokDescription(setokval token)
{
   struct opDesc * ret = (struct opDesc *)opDescTable + (sizeof(opDescTable)/sizeof(opDescTable[0]));
   while ( opDescTable != --ret ) /* return initial entry if not found */
   {
      if ( ret->token == token )
         break;
   }
   return ret;
}
#endif
