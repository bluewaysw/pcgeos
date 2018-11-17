/* mathobj.c
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

#ifdef JSE_MATH_ANY

#  if defined(__JSE_GEOS__) && !(defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR))
#  include <math.h>

   static double ceil(double x) {
	double retValue = floor(x);
	if (retValue != x) {
		retValue++;
	}
	return retValue;
   }

#  if defined(JSE_MATH_RANDOM)
#  define RAND_MAX 0x7FFF 
   static int NEAR_CALL rand() {
        return (int) floor(frand() * RAND_MAX);
   }
#  endif

#  endif

#  if (0==JSE_FLOATING_POINT)
#    error  JSE_FLOATING_POINT must be defined to use Ecma Math object
#  endif

#if defined(JSE_MATH_ABS)
/* Math.abs() */
static jseArgvLibFunc(Ecma_Math_abs)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( !jseIsNaN(val)  &&  jseIsNegative(val) )
      val = JSE_FP_NEGATE(val);
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ABS) */

#if defined(JSE_MATH_ACOS)
/* Math.acos() */
static jseArgvLibFunc(Ecma_Math_acos)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( !jseIsNaN(val) )
   {
      if ( JSE_FP_LT(jseOne,val)  ||  JSE_FP_LT(val,jseNegOne) )
      {
         val = jseNaN;
      }
      else
      {
         val = JSE_FP_ACOS(val);
      }
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ACOS) */


#if defined(JSE_MATH_ASIN)
/* Math.asin() */
static jseArgvLibFunc(Ecma_Math_asin)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( !jseIsNaN(val) )
   {
      if ( JSE_FP_LT(jseOne,val)  ||  JSE_FP_LT(val,jseNegOne) )
      {
         val = jseNaN;
      }
      else
      {
         val = JSE_FP_ASIN(val);
      }
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ASIN) */

#if defined(JSE_MATH_ATAN)
/* Math.atan() */
static jseArgvLibFunc(Ecma_Math_atan)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);
   jsebool neg;

   UNUSED_PARAMETER(argc);

   if ( jseIsNaN(val) || jseIsZero(val) )
   {
      /* for NaN, +0, and -0 the value does not change */
   }
   else if ( jseIsFinite(val) )
   {
      val = JSE_FP_ATAN(val);
   }
   else
   {
      /* Infinity or -Infinity is +-PI/2 */
      assert( jseIsInfOrNegInf(val) );
      neg = jseIsNegative(val);
      val = JSE_FP_DIV(jsePI,JSE_FP_CAST_FROM_SLONG(2));
      if ( neg )
      {
         val = JSE_FP_NEGATE(val);
      }
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ATAN) */

#if defined(JSE_MATH_ATAN2)
/* Math.atan2() */
static jseArgvLibFunc(Ecma_Math_atan2)
{
   jsenumber y = jseGetNumberDatum(jsecontext,argv[0],NULL);
   jsenumber x = jseGetNumberDatum(jsecontext,argv[1],NULL);
   jsenumber val = jseZero;

   UNUSED_PARAMETER(argc);

   if ( jseIsNaN(y) || jseIsNaN(x) )
   {
      val = jseNaN;
   }
   else
   {
      sint quartPImultiple = 0; /* this will be what to by PI/4 */
      if ( JSE_FP_LT(jseZero,y)   &&  jseIsZero(x) )
      {
         quartPImultiple = 2; /* +PI/2 */
      }
      else if ( jseIsZero(y) )
      {
         if ( jseIsPosZero(y) )
         {
            if ( jseIsNegative(x) )
            {
               quartPImultiple = 4; /* +PI */
            }
            else
            {
               assert( jseIsZero(val) ); /* val = jseZero; */
            }
         }
         else
         {
            assert( jseIsNegZero(y) );
            if ( jseIsNegative(x) )
            {
               quartPImultiple = -4; /* -PI */
            }
            else
            {
               val = jseNegZero;
            }
         }
      }
      else if ( JSE_FP_LT(y,jseZero)  &&  jseIsZero(x) )
      {
         quartPImultiple = -2; /* -PI/2 */
      }
      else if ( jseIsFinite(y)  &&  jseIsInfOrNegInf(x) )
      {
         if ( JSE_FP_LT(jseZero,y) )
         {
            if ( jseIsNegative(x) )
            {
               quartPImultiple = 4 /*PI*/;
            }
            else
            {
               assert( jseIsZero(val) ); /* val = jseZero; */;
            }
         }
         else
         {
            if ( jseIsNegative(x) )
            {
               quartPImultiple = -4 /*-PI*/;
            }
            else
            {
               val = jseNegZero;
            }
         }
      }
      else if ( jseIsInfOrNegInf(y) )
      {
         jsebool yisneg = jseIsNegative(y);
         if ( jseIsFinite(x) )
         {
            quartPImultiple = ( yisneg ) ? -2/*-PI/2*/ : 2/*+PI/2*/ ;
         }
         else
         {
            jsebool xisneg = jseIsNegative(x);
            if ( yisneg )
            {
               quartPImultiple = ( xisneg ) ? -3/*-3PI/4*/ : -1/*-PI/4*/ ;
            }
            else
            {
               quartPImultiple = ( xisneg ) ? 3/*3PI/4*/ : 1/*PI/4*/ ;
            }
         }
      }
      else
      {
         val = JSE_FP_ATAN2(y,x);
      }
      if ( 0 != quartPImultiple )
      {
         val = JSE_FP_MUL(JSE_FP_DIV(jsePI,JSE_FP_CAST_FROM_SLONG(4)),JSE_FP_CAST_FROM_SLONG(quartPImultiple));
      }
   }

   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ATAN2) */

#if defined(JSE_MATH_CEIL)
/* Math.ceil() */
static jseArgvLibFunc(Ecma_Math_ceil)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if( jseIsFinite(val) )
      val = JSE_FP_CEIL(val);

   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_CEIL) */

#if defined(JSE_MATH_COS)
/* Math.cos() */
static jseArgvLibFunc(Ecma_Math_cos)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   return jseCreateNumberVariable(jsecontext,jseIsFinite(val)?JSE_FP_COS(val):jseNaN);
}
#endif /* #if defined(JSE_MATH_COS) */

#if defined(JSE_MATH_EXP)
/* Math.exp() */
static jseArgvLibFunc(Ecma_Math_exp)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( jseIsFinite(val) )
   {
      val = JSE_FP_EXP(val);
   }
   else if ( jseIsNegInfinity(val) )
   {
      val = jseZero;
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_EXP) */

#if defined(JSE_MATH_FLOOR)
/* Math.floor() */
static jseArgvLibFunc(Ecma_Math_floor)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( jseIsFinite(val) )
      val = JSE_FP_FLOOR(val);
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_FLOOR) */

#if defined(JSE_MATH_LOG)
/* Math.log() */
static jseArgvLibFunc(Ecma_Math_log)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( jseIsFinite(val) )
   {
      if ( JSE_FP_LT(val,jseZero) )
         val = jseNaN;
      else if ( jseIsZero(val) )
         val = jseNegInfinity;
      else
         val = JSE_FP_LOG(val);
   }
   else
   {
      if ( jseIsNegInfinity(val) )
         val = jseNaN;
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_LOG) */

#if defined(JSE_MATH_MAX)
/* Math.max() */
/* ECMA2.0: This function can now take any number of arguments, including 0
 *          It also uses the same abstract relational algorithm as in
 *          varECMACompareEquality. This function is based on the ECMAScript
 *          version 2 draft spec, last edited June 4, 1999
 */
static jseArgvLibFunc(Ecma_Math_max)
{
   jsenumber maxval = jseNegInfinity, current;
   int i;

   UNUSED_PARAMETER(argc);

   for( i = 0; i < (int)jseFuncVarCount(jsecontext); i++ )
   {
      current = jseGetNumberDatum(jsecontext,argv[i],NULL);

      /* If it's NaN, then immediately return NaN */
      if( jseIsNaN(current) )
      {
         maxval = current;
         break;
      }

      if ( JSE_FP_LT(maxval,current) )
         maxval = current;
   }

   return jseCreateNumberVariable(jsecontext,maxval);
}
#endif /* #if defined(JSE_MATH_MAX) */

#if defined(JSE_MATH_MIN)
/* Math.min() */
/* ECMA2.0: This function can now take any number of arguments, including 0 */
static jseArgvLibFunc(Ecma_Math_min)
{
   jsenumber minval = jseInfinity, current;
   int i;

   UNUSED_PARAMETER(argc);

   for( i = 0; i < (int)jseFuncVarCount(jsecontext); i++ )
   {
      current = jseGetNumberDatum(jsecontext,argv[i],NULL);

      /* If it's NaN, then immediately return NaN */
      if( jseIsNaN(current) )
      {
         minval = current;
         break;
      }

      if( JSE_FP_LT(current,minval) )
         minval = current;
   }

   return jseCreateNumberVariable(jsecontext,minval);
}
#endif /* #if defined(JSE_MATH_MIN) */

#if defined(JSE_MATH_POW)
/* Math.pow() */
static jseArgvLibFunc(Ecma_Math_pow)
{
   jsenumber x = jseGetNumberDatum(jsecontext,argv[0],NULL);
   jsenumber y = jseGetNumberDatum(jsecontext,argv[1],NULL);
   jsenumber val;

   UNUSED_PARAMETER(argc);

   if ( !jseIsFinite(y) || !jseIsFinite(x) )
   {
      if ( jseIsNaN(y) )
      {
         val = jseNaN;
      }
      else if ( jseIsFinite(y)  &&  jseIsZero(y) )
      {
         val = jseOne;
      }
      else if ( jseIsNaN(x) )
      {
         val = jseNaN;
      }
      else if ( jseIsInfOrNegInf(y) )
      {
         jsenumber absx
#        if (0!=JSE_FLOATING_POINT)
            = jseIsNegative(x) ? JSE_FP_NEGATE(x) : x ;
#        else
            = abs(x);
#        endif
         if ( JSE_FP_EQ(absx,jseOne) )
         {
            val = jseNaN;
         }
         else if ( JSE_FP_LT(jseOne,absx)  ||  jseIsInfinity(x) )
         {
            val = jseIsInfinity(y) ? jseInfinity : jseZero ;
         }
         else
         {
            val = jseIsInfinity(y) ? jseZero : jseInfinity ;
         }
      }
      else if ( jseIsInfinity(x) )
      {
         val = JSE_FP_LT(jseZero,y) ? jseInfinity : jseZero ;
      }
      else
      {
         slong ylong = JSE_FP_CAST_TO_SLONG(y);
         assert( jseIsNegInfinity(x) );
         if ( (ylong & 1)
           && JSE_FP_EQ(JSE_FP_CAST_FROM_SLONG(ylong),y) )
         {
            /* y is an odd integer */
            val = JSE_FP_LT(jseZero,y) ? jseNegInfinity : jseNegZero ;
         }
         else
         {
            /* y is not an odd integer */
            val = JSE_FP_LT(jseZero,y) ? jseInfinity : jseZero ;
         }
      }
   }
   else if ( jseIsZero(y) )
   {
      val = jseOne;
   }
   else if ( jseIsZero(x) )
   {
      assert( !jseIsZero(y) );
      if ( jseIsPosZero(x) )
      {
         val = JSE_FP_LT(jseZero,y) ? jseZero : jseInfinity ;
      }
      else
      {
         slong yInteger = JSE_FP_CAST_TO_SLONG(y);
         jsebool yOddInteger = ( JSE_FP_EQ(JSE_FP_CAST_FROM_SLONG(yInteger),y)  &&  (yInteger & 1) );
         assert( jseIsNegZero(x) );
         if ( JSE_FP_LT(y,jseZero) )
         {
            val = yOddInteger ? jseNegInfinity : jseInfinity ;
         }
         else
         {
            val = yOddInteger ? jseNegZero : jseZero ;
         }
      }
   }
   else if ( JSE_FP_LT(x,jseZero)
          && JSE_FP_NEQ(JSE_FP_CAST_FROM_SLONG(JSE_FP_CAST_TO_SLONG(y)),y) )
   {
      val = jseNaN;
   }
   else
   {
      val = JSE_FP_POW(x,y);
   }

   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_POW) */

#if defined(JSE_MATH_RANDOM)
/* random function needs to know if it was already called and what its seed
 * may be so that we initialize every time but do not repeat the sequence
 */
struct MathObjData
{
   jsebool randInitialized;
#  if (1==JSE_THREADSAFE_POSIX_CRTL)
      uint seed;
#  endif
};

/* Math.random() */
/* This routine no longer relies on the way IEEE doubles are stored. */
static jseArgvLibFunc(Ecma_Math_random)
{
/* If we are GEOS and emulating floating point then do the quikcer easier method */
#if defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR) && defined(__JSE_GEOS__)
   return jseCreateNumberVariable(jsecontext,JSE_FP_RAND());
#else
    uword32 low, high;
   jsenumber num, fhigh, flow;
   int r[5];
   int i;
   struct MathObjData *data = jseLibraryData(jsecontext);
   jsenumber denom;
   jsenumber jseFPx7ffff = JSE_FP_CAST_FROM_SLONG(0x7ffffL);
   jsenumber jseFPxffffffff;
#  if defined(JSE_FP_EMULATOR) && (0!=JSE_FP_EMULATOR)
   {
      jsenumber jseFPx10000 = JSE_FP_CAST_FROM_SLONG(0x10000L);
      jsenumber jseFPx100000000 = JSE_FP_MUL(jseFPx10000,jseFPx10000);
      jseFPxffffffff = JSE_FP_SUB(jseFPx100000000,jseOne);
   }
#  else
      jseFPxffffffff = (jsenumber)0xffffffffL;
#  endif

   UNUSED_PARAMETER(argc);
   UNUSED_PARAMETER(argv);

   assert( NULL != data );
#if 0
   if ( !data->randInitialized )
   {
      /* first time.  Initialize random data */
      time_t t;

      time(&t);
#     if (1==JSE_THREADSAFE_POSIX_CRTL)
         data->seed = (uint)t;
#     else
         srand( (uint)t );
#     endif
      data->randInitialized = True;
   }
#pragma message "Must deal with random seed"
#endif

   /* get 15 bits of random value at a time, need 51 bits */
   for ( i = 0; i < 5; i++ )
   {
#     if (1==JSE_THREADSAFE_POSIX_CRTL)
#     ifdef __hpux__
         rand_r(&data->seed,r+i);
         r[i] &= 0x7fff;
#     else
         r[i] = rand_r(&data->seed) & 0x7fff;
#     endif
#     else
         r[i] = rand() & 0x7fff;
#     endif
   }

   // assert( RAND_MAX>=0x7fff );

   low = (uword32) (r[0] | (r[1]<<15) | (r[2]<<30));
   high = (uword32) ((r[3] | (r[4]<<15)) & 0x7ffffL);

   flow = JSE_FP_CAST_FROM_SLONG(low);
   fhigh = JSE_FP_CAST_FROM_SLONG(high);
   num = JSE_FP_ADD(JSE_FP_MUL(fhigh,jseFPxffffffff),flow);

   denom = JSE_FP_ADD(JSE_FP_MUL(jseFPx7ffff,jseFPxffffffff),jseFPxffffffff);
   return jseCreateNumberVariable(jsecontext,JSE_FP_DIV(num,denom));
#endif
}
#endif /* #if defined(JSE_MATH_RANDOM) */

#if defined(JSE_MATH_ROUND)
/* Math.round() */
static jseArgvLibFunc(Ecma_Math_round)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( jseIsFinite(val) )
   {
      jsenumber half = JSE_FP_DIV(jseOne,JSE_FP_CAST_FROM_SLONG(2));
      val = JSE_FP_FLOOR(JSE_FP_ADD(val,half));
   }

   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_ROUND) */

#if defined(JSE_MATH_SIN)
/* Math.sin() */
static jseArgvLibFunc(Ecma_Math_sin)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   return jseCreateNumberVariable(jsecontext,jseIsFinite(val)?JSE_FP_SIN(val):jseNaN);
}
#endif /* #if defined(JSE_MATH_SIN) */

#if defined(JSE_MATH_SQRT)
/* Math.sqrt() */
static jseArgvLibFunc(Ecma_Math_sqrt)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   if ( jseIsFinite(val) )
   {
      val = JSE_FP_LT(val,jseZero) ? jseNaN : JSE_FP_SQRT(val) ;
   }
   else
   {
      if ( jseIsNegInfinity(val) )
         val = jseNaN;
   }
   return jseCreateNumberVariable(jsecontext,val);
}
#endif /* #if defined(JSE_MATH_SQRT) */

#if defined(JSE_MATH_TAN)
/* Math.tan() */
static jseArgvLibFunc(Ecma_Math_tan)
{
   jsenumber val = jseGetNumberDatum(jsecontext,argv[0],NULL);

   UNUSED_PARAMETER(argc);

   return jseCreateNumberVariable(jsecontext,jseIsFinite(val)?JSE_FP_TAN(val):jseNaN);
}
#endif /* #if defined(JSE_MATH_TAN) */

/* ---------------------------------------------------------------------- */

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

#if defined(JSE_MATH_E)
#  define E_VALUE       UNISTR("2.7182818284590452354")
#endif
#if defined(JSE_MATH_LN10)
#  define LN10_VALUE    UNISTR("2.302585092994046")
#endif
#if defined(JSE_MATH_LN2)
#  define LN2_VALUE     UNISTR("0.6931471805599453")
#endif
#if defined(JSE_MATH_LOG2E)
#  define LOG2E_VALUE   UNISTR("1.4426950408889634")
#endif
#if defined(JSE_MATH_LOG10E)
#  define LOG10E_VALUE  UNISTR("0.4342944819032518")
#endif
#if defined(JSE_MATH_PI)
#  define PI_VALUE      UNISTR("3.14159265358979323846")
#endif
#if defined(JSE_MATH_SQRT1_2)
#  define SQRT1_2_VALUE UNISTR("0.7071067811865476")
#endif
#if defined(JSE_MATH_SQRT2)
#  define SQRT_VALUE    UNISTR("1.4142135623730951")
#endif

static CONST_DATA(struct jseFunctionDescription) MathLibFunctionList[] = {

   /* First the properties for the math object */
#  if defined(JSE_MATH_E)
      JSE_VARSTRING(UNISTR("E"),       E_VALUE,        jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_LN10)
      JSE_VARSTRING(UNISTR("LN10"),    LN10_VALUE,     jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_LN2)
      JSE_VARSTRING(UNISTR("LN2"),     LN2_VALUE,      jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_LOG2E)
      JSE_VARSTRING(UNISTR("LOG2E"),   LOG2E_VALUE,    jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_LOG10E)
      JSE_VARSTRING(UNISTR("LOG10E"),  LOG10E_VALUE,   jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_PI)
      JSE_VARSTRING(UNISTR("PI"),      PI_VALUE,       jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_SQRT1_2)
      JSE_VARSTRING(UNISTR("SQRT1_2"), SQRT1_2_VALUE,  jseDontEnum|jseDontDelete|jseReadOnly),
#  endif
#  if defined(JSE_MATH_SQRT2)
      JSE_VARSTRING(UNISTR("SQRT2"),   SQRT_VALUE,     jseDontEnum|jseDontDelete|jseReadOnly),
#  endif

   /* now the methods for the math object */
#  if defined(JSE_MATH_ABS)
      JSE_ARGVLIBMETHOD(UNISTR("abs"),    Ecma_Math_abs,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_ACOS)
      JSE_ARGVLIBMETHOD(UNISTR("acos"),   Ecma_Math_acos,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_ASIN)
      JSE_ARGVLIBMETHOD(UNISTR("asin"),   Ecma_Math_asin,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_ATAN)
      JSE_ARGVLIBMETHOD(UNISTR("atan"),   Ecma_Math_atan,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_ATAN2)
      JSE_ARGVLIBMETHOD(UNISTR("atan2"),  Ecma_Math_atan2,  2,    2,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_CEIL)
      JSE_ARGVLIBMETHOD(UNISTR("ceil"),   Ecma_Math_ceil,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_COS)
      JSE_ARGVLIBMETHOD(UNISTR("cos"),    Ecma_Math_cos,    1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_EXP)
      JSE_ARGVLIBMETHOD(UNISTR("exp"),    Ecma_Math_exp,    1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_FLOOR)
      JSE_ARGVLIBMETHOD(UNISTR("floor"),  Ecma_Math_floor,  1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_LOG)
      JSE_ARGVLIBMETHOD(UNISTR("log"),    Ecma_Math_log,    1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_MAX)
      JSE_ARGVLIBMETHOD(UNISTR("max"),    Ecma_Math_max,    0,    -1,     jseDontEnum,    jseFunc_Secure ),
      JSE_VARSTRING(UNISTR("max.length"), UNISTR("2"), jseDontEnum|jseReadOnly|jseDontDelete),
#  endif
#  if defined(JSE_MATH_MIN)
      JSE_ARGVLIBMETHOD(UNISTR("min"),    Ecma_Math_min,    0,    -1,     jseDontEnum,    jseFunc_Secure ),
      JSE_VARSTRING(UNISTR("min.length"), UNISTR("2"), jseDontEnum|jseReadOnly|jseDontDelete),
#  endif
#  if defined(JSE_MATH_POW)
      JSE_ARGVLIBMETHOD(UNISTR("pow"),    Ecma_Math_pow,    2,    2,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_SIN)
      JSE_ARGVLIBMETHOD(UNISTR("sin"),    Ecma_Math_sin,    1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_SQRT)
      JSE_ARGVLIBMETHOD(UNISTR("sqrt"),   Ecma_Math_sqrt,   1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_TAN)
      JSE_ARGVLIBMETHOD(UNISTR("tan"),    Ecma_Math_tan,    1,    1,      jseDontEnum,    jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_RANDOM)
      JSE_ARGVLIBMETHOD( UNISTR("random"),  Ecma_Math_random,  0,       0, jseDontEnum , jseFunc_Secure ),
#  endif
#  if defined(JSE_MATH_ROUND)
      JSE_ARGVLIBMETHOD(UNISTR("round"),   Ecma_Math_round,   1,       1,      jseDontEnum , jseFunc_Secure ),
#  endif
   JSE_FUNC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

#if defined(JSE_MATH_RANDOM)
   static void _FAR_ * JSE_CFUNC
MathLibInitFunction(jseContext jsecontext,void _FAR_ *unused)
{
   jseVariable v;
   struct MathObjData *data;
   UNUSED_PARAMETER(unused);
   v = jseMemberEx(jsecontext,NULL,UNISTR("Math"),jseTypeObject,jseCreateVar);
   jseSetAttributes(jsecontext,v,jseDontEnum);
   jseDestroyVariable(jsecontext,v);

   /* allocate and return structure used for Math.random() */
   data = jseMustMalloc(struct MathObjData,sizeof(*data));
   data->randInitialized = False;

   return data;
}

   static void JSE_CFUNC
MathLibTermFunction(jseContext jsecontext,void _FAR_ *InstanceLibraryData)
{
   UNUSED_PARAMETER(jsecontext);

   assert( NULL != InstanceLibraryData );
   jseMustFree(InstanceLibraryData);
}
#endif /* #if defined(JSE_MATH_RANDOM) */

   void NEAR_CALL
InitializeLibrary_Ecma_Math(jseContext jsecontext)
{
#  if defined(JSE_MATH_RANDOM)
      jseAddLibrary(jsecontext,UNISTR("Math"),MathLibFunctionList,NULL,
                    MathLibInitFunction,MathLibTermFunction);
#  else
      jseAddLibrary(jsecontext,UNISTR("Math"),MathLibFunctionList,NULL,
                    NULL,NULL);

#  endif
}

#endif /* #ifdef JSE_MATH_ANY */

ALLOW_EMPTY_FILE
