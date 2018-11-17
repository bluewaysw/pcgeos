/* sefp.h   Handle floating-point math
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

#ifndef _SEFP_H
#define _SEFP_H

#if (0!=JSE_FLOATING_POINT)
   typedef float           float32;
   typedef double          float64;
#  if !defined(_MSC_VER)
      typedef long double  float80;
#  endif
#endif

#if !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR)

   /* JavaScript by default uses a float64 as the number
    * types.  But for implementations that do not want to support
    * floating point numbers the following can be changed to represent
    * any type for a jseNumber
    */
#  if (0!=JSE_FLOATING_POINT)
      typedef float64         jsenumber;
#  else
      typedef sword32         jsenumber;
#  endif

   /* methods for working with special number types that work in any
    * operating system and with any link method.  The following field
    * is initialized in jseengin.cpp for unix systems, and in globldat.cpp
    * for non-unix systems.
    */
#  ifdef __cplusplus
      extern "C" {
#  endif
#  if (0!=JSE_FLOATING_POINT)
#     if defined(__JSE_UNIX__)
         extern VAR_DATA(jsenumber) jse_special_math[4];
#        define jseNegZero     jse_special_math[0]
#        define jseInfinity    jse_special_math[1]
#        define jseNegInfinity jse_special_math[2]
#        define jseNaN         jse_special_math[3]
#     else
         extern CONST_DATA(uword32) jse_special_math[8];
#        define jseNegZero     (*(jsenumber *)(jse_special_math+0))
#        define jseInfinity    (*(jsenumber *)(jse_special_math+2))
#        define jseNegInfinity (*(jsenumber *)(jse_special_math+4))
#        define jseNaN         (*(jsenumber *)(jse_special_math+6))
#     endif
#  ifdef __cplusplus
      }
#  endif

      /* I've replaced the calls to memcmp with this junk. I know it looks ugly,
       * but it is a *lot* faster (wrldfrct is .2 secs faster due to it. Basically,
       * since you can't compare doubles vs NAN (it always succeeds), we take the
       * address of the double to check and the NaN value and cast them to uword32s.
       * Then we can do regular compares on the 8 bytes of memory.
       */
      typedef struct {
         union {
            double  all;
            uword32 w32[2];
            uword16 w16[4];
            /* bit pattern
             *    f:52
             *    e:11
             *    s:1
             */
         } n;
      } jseDouble;
      /* assertions in jseengin.c verify that these are all 64-bit values */
#     if SE_BIG_ENDIAN == True
#        define jseDoubleLo(num)    ((*(jseDouble *)(&(num))).n.w32[1])
#        define jseDoubleHi(num)    ((*(jseDouble *)(&(num))).n.w32[0])
#        define jseDoubleHi16(num)  ((*(jseDouble *)(&(num))).n.w16[0])
#     else
#        define jseDoubleLo(num)    ((*(jseDouble *)(&(num))).n.w32[0])
#        define jseDoubleHi(num)    ((*(jseDouble *)(&(num))).n.w32[1])
#        define jseDoubleHi16(num)  ((*(jseDouble *)(&(num))).n.w16[3])
#     endif

#     define jseIsFinite(num)       (0x7FF0 != (jseDoubleHi16(num) & 0x7FF0))
      /* there are many many options for NaN storage; internally we will nearly
       * always be storing a special representation so that the comparison
       * will be quicker
       */
#     define jseIsNegative(num)     ( 0 != (jseDoubleHi16(num) & 0x8000) )
#     define jseIsInfOrNegInf(num)  ( (0 == jseDoubleLo(num)) \
                                   && (0x7FF00000L == (jseDoubleHi(num) & 0x7FFFFFFFL)) )
#     define jseIsInfinity(num)     ( (0x7FF00000L == jseDoubleHi(num)) \
                                   && (0L == jseDoubleLo(num)) )
#     define jseIsNegInfinity(num)  ( (0xFFF00000L == jseDoubleHi(num)) \
                                   && (0L == jseDoubleLo(num)) )
#     define jseIsNaN(num)          (jseDoubleHi16(num)==0x7FF8)
      /* internally we save all our NaN in a special format. But the following macro
       * detects any of the possible bit patterns that are NaN
       */
#     define jseIsAnyNaN(num)       ( !jseIsFinite(num) && !jseIsInfOrNegInf(num) )
      /* In some systems 0==num would compare against +0 or -0, but in other systems
       * that is not true.  The jseIsZero() macro can use straight num==0 or analyze
       * bytes, depending on what works and is fastest on that system.
       * WARNING! do not assume jseIsZero(NaN).  Code must test against jseIsNaN first
       */
#     if defined(__JSE_DOS16__) || defined(__JSE_WIN16__) || defined(__JSE_GEOS__)
#        define jseIsZero(num) \
            ( (0L == jseDoubleLo(num)) \
           && (0L == (jseDoubleHi(num) & 0x7FFFFFFFL)) )
#     else
#        define jseIsZero(num)   (0==(num))
#     endif
#     define jseIsPosZero(num) ( (0L==jseDoubleLo(num)) && (0L==jseDoubleHi(num)) )
#     define jseIsNegZero(num) ( (0x80000000L==jseDoubleHi(num)) && (0L==jseDoubleLo(num)) )

#   else

      /* 0==JSE_FLOATING_POINT */

#     define jseInfinity    0x7FFFFFFFL
#     define jseNaN         0x80000000L
#     define jseNegInfinity 0x80000001L
#     define jseNegZero     0x80000002L

#     define jseIsNaN(A_Number)     ( (A_Number) == jseNaN )
#     define jseIsInfinity(num)     ( (num) == jseInfinity )
#     define jseIsNegInfinity(num)  ( (num) == jseNegInfinity )
#     define jseIsPosZero(num)      ( 0 == (num) )
#     define jseIsNegZero(num)      ( jseNegZero == (num) )
#     define jseIsZero(num)         ( jseIsPosZero((num)) || jseIsNegZero((num)) )
#     define jseIsNegative(num)     ( (num) < 0 )
#     define jseIsInfOrNegInf(num)  ( jseIsInfinity(num) || jseIsNegInfinity(num) )
#     define jseIsFinite(num)       ( ((uword32)(num))<0x7FFFFFFFL || 0x80000001L<((uword32)(num)) )

#  endif

#  define jseZero    (0)
#  define jseOne     (1)
#  define jseNegOne  (-1)

#endif /* #if !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR) */


#if !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR)

   /*********************************************
    * these macros assume that FP is built-in ***
    *********************************************/

#if (0==JSE_FLOATING_POINT)
#  define FPZ(FP)    (jseIsNegZero((FP))?jseZero:(FP))
#else
#  define FPZ(FP)    (FP)
#endif

#  define JSE_FP_ADD(FP1,FP2)    (FPZ(FP1)+FPZ(FP2))
#  define JSE_FP_SUB(FP1,FP2)    (FPZ(FP1)-FPZ(FP2))
#  define JSE_FP_MUL(FP1,FP2)    (FPZ(FP1)*FPZ(FP2))
#  define JSE_FP_DIV(FP1,FP2)    (FPZ(FP1)/FPZ(FP2))
#  if (0==JSE_FLOATING_POINT)
#     define JSE_FP_MOD(FP1,FP2)    (FPZ(FP1)%FPZ(FP2))
#  endif
#  define JSE_FP_EQ(FP1,FP2)     (FPZ(FP1)==FPZ(FP2))
#  define JSE_FP_NEQ(FP1,FP2)    (FPZ(FP1)!=FPZ(FP2))
#  define JSE_FP_LT(FP1,FP2)     (FPZ(FP1)<FPZ(FP2))
#  define JSE_FP_LTE(FP1,FP2)    (FPZ(FP1)<=FPZ(FP2))
#  if (0==JSE_FLOATING_POINT)
      jsenumber JSE_FP_NEGATE(jsenumber FP);
#  else
#     if defined(__WATCOMC__) \
      && ( defined(__JSE_DOS16__) || defined(__JSE_WIN16__) )
         /* these systems do not convert -0 to jseNegZero */
#        define JSE_FP_NEGATE(FP)      (jseIsPosZero((FP))?jseNegZero:(-(FP)))
#     else
#      if defined(__JSE_GEOS__)
	  /* same here, as long as we emulate FP with math library */
#        define JSE_FP_NEGATE(FP)      (jseIsPosZero((FP))?jseNegZero:(-(FP)))
#      else
#        define JSE_FP_NEGATE(FP)      (-(FP))
#      endif
#     endif
#  endif
#  if (0==JSE_FLOATING_POINT)
#     define JSE_FP_ADD_EQ(FP1,FP2) ((FP1)=FPZ(FP1)+FPZ(FP2))
#     define JSE_FP_SUB_EQ(FP1,FP2) ((FP1)=FPZ(FP1)-FPZ(FP2))
#     define JSE_FP_MUL_EQ(FP1,FP2) ((FP1)=FPZ(FP1)*FPZ(FP2))
#     define JSE_FP_DIV_EQ(FP1,FP2) ((FP1)=FPZ(FP1)/FPZ(FP2))
#  else
#     define JSE_FP_ADD_EQ(FP1,FP2) ((FP1)+=(FP2))
#     define JSE_FP_SUB_EQ(FP1,FP2) ((FP1)-=(FP2))
#     define JSE_FP_MUL_EQ(FP1,FP2) ((FP1)*=(FP2))
#     define JSE_FP_DIV_EQ(FP1,FP2) ((FP1)/=(FP2))
#  endif

#  define JSE_FP_FMOD(FP1,FP2)   fmod((FP1),(FP2))
#  define JSE_FP_FLOOR(FP)       floor(FP)

#  if (0==JSE_FLOATING_POINT)
#     define JSE_FP_INCREMENT(FP)   if(jseIsNegZero(FP)) (FP)=jseOne; else (FP)++
#     define JSE_FP_DECREMENT(FP)   if(jseIsNegZero(FP)) (FP)=jseNegOne; else (FP)--
#  else
#     define JSE_FP_INCREMENT(FP)   (FP++)
#     define JSE_FP_DECREMENT(FP)   (FP--)
#  endif

#  define JSE_FP_CAST_FROM_SLONG(L)   ((jsenumber)(L))
#  define JSE_FP_CAST_TO_SLONG(F)   ((slong)(F))

#  define JSE_FP_STRTOD( __NPTR, __ENDPTR ) strtod_jsechar((__NPTR),(__ENDPTR))
#  define ECMA_NUMTOSTRING_MAX  100

#if defined(__JSE_PALMOS__)
/* NYI: A better way of formatting Floats. */
#  define JSE_FP_DTOSTR(theNum,precision,buffer,type) \
{FlpCompDouble d;d.d = theNum;FlpFToA( d.fd, buffer );}

#else
   void JSE_FP_DTOSTR(jsenumber theNum,int precision,jsechar buffer[ECMA_NUMTOSTRING_MAX],const jsecharptr type);
      /* type is "g", "f", or "e" */
#  define JSE_FP_DTOSTR(theNum,precision,buffer,type) \
      jse_sprintf((jsecharptr)(buffer),UNISTR("%.*") type,(precision),(theNum));

#endif

   /****************************************************************
    *** FUNCTIONS USED BY LIBRARIES.  WHAT YOU NEED TO IMPLEMENT ***
    *** DEPENDS ON THE LIBRARY FUNCTIONS YOU SUPPORT.  LET YOUR  ***
    *** LINKER TELL YOU WHAT'S MISSING.                          ***
    ****************************************************************/

#  define JSE_FP_COS(FP)         cos(FP)
#  define JSE_FP_ACOS(FP)        acos(FP)
#  define JSE_FP_COSH(FP)        cosh(FP)
#  define JSE_FP_SIN(FP)         sin(FP)
#  define JSE_FP_ASIN(FP)        asin(FP)
#  define JSE_FP_SINH(FP)        sinh(FP)
#  define JSE_FP_TAN(FP)         tan(FP)
#  define JSE_FP_ATAN(FP)        atan(FP)
#  define JSE_FP_TANH(FP)        tanh(FP)
#  define JSE_FP_ATAN2(FP1,FP2)  atan2((FP1),(FP2))
#  define jsePI                  (3.14159265358979323846)
#  define JSE_FP_CEIL(FP)        ceil(FP)
#  define JSE_FP_EXP(FP)         exp(FP)
#  define JSE_FP_LOG(FP)         log(FP)
#  define JSE_FP_LOG10(FP)       log10(FP)
#  define JSE_FP_POW(FP1,FP2)    pow(FP1,FP2)
#  define JSE_FP_SQRT(FP)        sqrt(FP)
#  define JSE_FP_FABS(FP)        fabs(FP)
#  define JSE_FP_ATOF(STR)       atof(STR)
#  define JSE_FP_FREXP(FP,EXP)   frexp(FP,EXP)
#  define JSE_FP_LDEXP(FP,EXP)   ldexp(FP,EXP)
#  define JSE_FP_MODF(FP1,FP2)   modf(FP1,FP2)

#  define JSE_FP_CAST_FROM_ULONG(U) ((jsenumber)(U))
#  define JSE_FP_CAST_TO_ULONG(FP)  ((ulong)(FP))

   /* casting from and to double is rare - may not be needed */
#  define JSE_FP_CAST_FROM_DOUBLE(D)   ((jsenumber)(D))
#  define JSE_FP_CAST_TO_DOUBLE(F)     ((double)(F))

#else

   /*
    * the following routines must be handled by an emulator
    *
    *    jsenumber JSE_FP_ADD(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_SUB(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_MUL(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_DIV(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_EQ(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_NEQ(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_LT(jsenumber FP1,jsenumber FP2);
    *    jsebool JSE_FP_LTE(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_NEGATE(jsenumber FP);
    *    #define JSE_FP_ADD_EQ(FP1,FP2) ((FP1) = JSE_FP_ADD((FP1),(FP2)))
    *    #define JSE_FP_SUB_EQ(FP1,FP2) ((FP1) = JSE_FP_SUB((FP1),(FP2)))
    *    #define JSE_FP_MUL_EQ(FP1,FP2) ((FP1) = JSE_FP_MUL((FP1),(FP2)))
    *    #define JSE_FP_DIV_EQ(FP1,FP2) ((FP1) = JSE_FP_DIV((FP1),(FP2)))
    *
    *    jsenumber JSE_FP_FMOD(jsenumber FP1,jsenumber FP2);
    *    jsenumber JSE_FP_FLOOR(jsenumber FP);
    *
    *    void JSE_FP_INCREMENT_ptr(jsenumber *FP);
    *    #define JSE_FP_INCREMENT(FP) JSE_FP_INCREMENT_ptr(&(FP))
    *    void JSE_FP_DECREMENT_ptr(jsenumber *FP);
    *    #define JSE_FP_DECREMENT(FP) JSE_FP_DECREMENT_ptr(&(FP))
    *
    *    jsenumber JSE_FP_CAST_FROM_SLONG(slong L);
    *    slong JSE_FP_CAST_TO_SLONG(jsenumber f);
    *
    *    jsenumber JSE_FP_STRTOD( const jsecharptr __nptr, jsecharptr *__endptr );
    *    #define ECMA_NUMTOSTRING_MAX  100
    *    void JSE_FP_DTOSTR(jsenumber theNum,int precision,
    *                       jsechar buffer[ECMA_NUMTOSTRING_MAX],const jsecharptr type);
    *                                                            type is "g", "f", or "e"
    *
    *    extern VAR_DATA(jsenumber) jseNaN;
    *    extern VAR_DATA(jsenumber) jseInfinity;
    *    extern VAR_DATA(jsenumber) jseNegInfinity;
    *    extern VAR_DATA(jsenumber) jseZero;
    *    extern VAR_DATA(jsenumber) jseNegZero;
    *    extern VAR_DATA(jsenumber) jseOne;
    *    extern VAR_DATA(jsenumber) jseNegOne;
    *    jsebool jseIsNaN(jsenumber num);
    *    jsebool jseIsFinite(jsenumber num);
    *    jsebool jseIsNegative(jsenumber num);
    *    jsebool jseIsInfOrNegInf(jsenumber num);
    *    jsebool jseIsInfinity(jsenumber num);
    *    jsebool jseIsNegInfinity(jsenumber num);
    *    jsebool jseIsZero(jsenumber num);
    *    jsebool jseIsNegZero(jsenumber num);
    *    jsebool jseIsPosZero(jsenumber num);
    *
    *     ****************************************************************
    *     *** FUNCTIONS USED BY LIBRARIES.  WHAT YOU NEED TO IMPLEMENT ***
    *     *** DEPENDS ON THE LIBRARY FUNCTIONS YOU SUPPORT.  LET YOUR  ***
    *     *** LINKER TELL YOU WHAT'S MISSING.                          ***
    *     ****************************************************************
    *
    *    jsenumber JSE_FP_COS(jsenumber fp);
    *    jsenumber JSE_FP_ACOS(jsenumber fp);
    *    jsenumber JSE_FP_COSH(jsenumber fp);
    *    jsenumber JSE_FP_SIN(jsenumber fp);
    *    jsenumber JSE_FP_ASIN(jsenumber fp);
    *    jsenumber JSE_FP_SINH(jsenumber fp);
    *    jsenumber JSE_FP_TAN(jsenumber fp);
    *    jsenumber JSE_FP_ATAN(jsenumber fp);
    *    jsenumber JSE_FP_TANH(jsenumber fp);
    *    jsenumber JSE_FP_ATAN2(jsenumber fp1,jsenumber fp2);
    *    extern VAR_DATA(jsenumber) jsePI;
    *    extern VAR_DATA(jsenumber) jse_DBL_MAX;
    *    extern VAR_DATA(jsenumber) jse_DBL_MIN;
    *    jsenumber JSE_FP_CEIL(jsenumber FP);
    *    jsenumber JSE_FP_EXP(jsenumber fp);
    *    jsenumber JSE_FP_LOG(jsenumber fp);
    *    jsenumber JSE_FP_LOG10(jsenumber fp);
    *    jsenumber JSE_FP_POW(jsenumber fp1,jsenumber fp2);
    *    jsenumber JSE_FP_SQRT(jsenumber fp);
    *    jsenumber JSE_FP_FABS(jsenumber fp);
    *    jsenumber JSE_FP_ATOF(const char *str);
    *    jsenumber JSE_FP_FREXP(jsenumber fp,int *exp);
    *    jsenumber JSE_FP_LDEXP(jsenumber fp,int exp);
    *    jsenumber JSE_FP_MODF(jsenumber fp1,jsenumber *fp2);
    *
    *    jsenumber JSE_FP_CAST_FROM_ULONG(ulong u);
    *    ulong JSE_FP_CAST_TO_ULONG(jsenumber fp);
    *
    *    * casting from and to double is rare - may not be needed *
    *    jsenumber JSE_FP_CAST_FROM_DOUBLE(double D);
    *    double JSE_FP_CAST_TO_DOUBLE(jsenumber F);
    */

#include "fp_emul.h"

#endif /* !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR) */

#endif /* #ifndef _SEFP_H */
