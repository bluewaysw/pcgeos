/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	GEOS Bitstream Font Driver
 * MODULE:	C
 * FILE:	TrueType/fixed_pt.c
 * AUTHOR:	Brian Chin
 *
 * DESCRIPTION:
 *	This file contains C code for the GEOS Bitstream Font Driver.
 *
 * RCS STAMP:
 *	$Id: fixed_pt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $
 *
 ***********************************************************************/

#pragma Code ("TTFixedPtCode")

/*
 *	fixed_pt.c:	fixed point arithmetic functions
*/

/*
 *	Revision Control Information

 $Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fixed_pt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $
 $Log:	fixed_pt.c,v $
 * Revision 1.1  97/04/18  11:45:18  newdeal
 * Initial revision
 * 
 * Revision 1.1.7.1  97/03/29  07:06:02  canavese
 * Initial revision for branch ReleaseNewDeal
 * 
 * Revision 1.1  94/04/06  15:14:36  brianc
 * support TrueType
 * 
 * Revision 6.44  93/03/15  13:07:00  roberte
 * Release
 * 
 * Revision 6.8  93/01/19  11:31:00  davidw
 * Removed outdated code
 * 80 column cleanup
 * fixed bug in FracDiv() function (return 0 when x=0, not NEGINFINITY)
 * 
 * Revision 6.7  93/01/18  14:25:56  davidw
 * Replaced FracDiv() fixed point module with floating point temp patch.
 * 
 * Revision 6.6  92/12/29  12:47:41  roberte
 * Now includes "spdo_prv.h" first.
 * 
 * Revision 6.5  92/11/24  13:37:36  laurar
 * include fino.h
 * 
 * Revision 6.4  92/07/28  11:54:25  davidw
 * cleaned up comments, removed debugging messages
 * 
 * Revision 6.3  92/07/28  11:51:53  davidw
 * fixed bugs in new FracDiv() routine
 * 
 * Revision 6.1  91/08/14  16:44:45  mark
 * Release
 * 
 * Revision 5.1  91/08/07  12:25:56  mark
 * Release
 * 
 * Revision 4.2  91/08/07  11:38:46  mark
 * added RCS control strings
 * 
*/

#ifdef RCSSTATUS
static char rcsid[] = "$Header: /staff/pcgeos/Driver/Font/Bitstream/TrueType/fixed_pt.c,v 1.1 97/04/18 11:45:18 newdeal Exp $";
#endif

#include "spdo_prv.h"
#include "fino.h"
#include "fixed.h"

void CompMul();
long CompDiv();

/************************************************************
 * Fixed FixDiv (Fixed x, Fixed y)
 *
 * Perform 16.16 fixed-point division, x / y.
 *
 * Returns: 16.16 fixed-point quotient, if successful
 *          If y is zero, returns: NEGINFINITY if x is negative
 *                                 POSINFINITY if x is pos or zero
 *
 ************************************************************/
Fixed FixDiv (x, y)
Fixed x, y;
{
Fixed quotient;
unsigned long remainder;
Fixed int_part, frac_part, round;
int num_shifts;
int sign;

   /* If denominator is zero, return:
    *	max long if denominator is positive or zero
    *	minus max long if denominator is negative
	*/
         
   if (y == 0) {
      if (x < 0)
         return (NEGINFINITY);
      else 
         return (POSINFINITY);
   }
   
/* If numerator is zero (denominator non-zero),
   return zero */

   if (x == 0)
      return (0);

/* Determine the sign of the quotient. Convert
   operands to positive if needed. */

   sign = 1;

   if (x < 0) {
      x = -x;
      sign = -1;
   }

   if (y < 0) {
      y = -y;
      sign *= -1;
   }

/* Find the integer part of the quotient, then
   get the remainder, to calculate the fraction part */

   int_part = x / y;
   remainder = x % y;

/* If division was exactly even, we're done */

   if (remainder == 0)
      return ((int_part << 16) * sign);
   
/* Shift the remainder as far left as possible (keeping
   track of how much was shifted), so that the quotient
   will preserve the most accuracy. */

   num_shifts = 0;
   while (!(remainder & HIBITSET)) {
      remainder <<= 1;
      num_shifts++;
   }

/* Find the fraction part, then round it off */

   frac_part = remainder / y;
   round = remainder % y;
   if (round >= (y / 2))
      frac_part++;

/* Place frac_part properly within 16-bit word */

   if (num_shifts > 16)
      frac_part >>= (num_shifts - 16);
   else
      frac_part <<= (16 - num_shifts);

/* Shift int_part << 16 and add in frac_part */

   quotient = (int_part << 16) + frac_part;
   return (quotient * sign);
}

/************************************************************
 * Fixed FixMul (Fixed x, Fixed y)
 *
 * Perform 16.16 fixed-point multiplication. Each operand
 * is expressed as the sum of its integer and fractional
 * parts. The operation is then performed as the multiplication
 * of two binomial expressions:
 *  (x_int + x_frac)(y_int + y_frac) = x_int * y_int +
 *                                     x_int * y_frac +
 *                                     x_frac * y_int +
 *                                     x_frac * y_frac
 *
 * The low word of the integer product, and the high word
 * of the fractional product are saved.
 *
 * Returns: 16.16 fixed-point product
 *
 * Note: No special error handling is done for overflow
 *       conditions.
 ************************************************************/
Fixed FixMul (x, y)
Fixed x, y;
{
uint32 x_int, x_frac;
uint32 y_int, y_frac;
Fixed prod;

/* Separate int from fraction part - high 16 bits = integer
   part, low 16 = fraction part */

   x_int = (x >> 16);
   y_int = (y >> 16);

   if (!(x_int || y_int))
        return(((uint32)x * (uint32)y + 0x8000L) >> 16);    /* fast case */

   x_frac = x & 0x0000ffff;
   y_frac = y & 0x0000ffff;

/* Save only the low word of the integer product (the high word
   contains overflow bits), and the high word of the fractional
   product (the low word contains insignificant bits) */ 

   prod = ((x_int * y_int) << 16) +
            x_frac * y_int +
            x_int * y_frac +
          ((x_frac * y_frac) >> 16);

   return (prod);
}

/************************************************************
 * Fract FracDiv (Fract x, Fract y)
 *
 * Perform 2.30 fixed-point division, x / y.
 *
 * Returns: 2.30 fixed-point quotient, if successful
 *          If y is zero, returns: NEGINFINITY if x is negative
 *                                 POSINFINITY if x is pos or zero
 *
 ************************************************************/
Fract FracDiv (x, y)
Fract x, y;
{
/*
 *
 *	22-Jun-92	DKW	Fix for 2.30 div routine
 *				adapted from FixDiv code.
 *				The Fract type is 32 bits wide.
 *
*/
        int negative = FALSE;
        register uint32 hinum;
        register uint32 lownum;
        register uint32 hiden;
        register uint32 lowden;
        register uint32 result;
        register uint32 place;

			/* special case out the asymptotic instance */
        if (y == 0)
			return (x < 0 ) ? NEGINFINITY : POSINFINITY;

			/* special case out the obvious */
        if (x == 0)
			return 0;

			/* record sign, work only with absolute magnititudes */
        if (x < 0) {
			x = -x;
			negative = TRUE;
		}

        if (y < 0) {
			y = -y;
			negative ^= TRUE;
		}

			/* get the integer part */
        hinum = ((uint32)x >> 2);

			/* get the fractional part */
        lownum = ((uint32)x << 30);

        hiden = y;
        lowden = 0;
        result = 0;
        place = HIBITSET;

			/* special case out asymptotic instance */
        if (hinum >= hiden)
			return negative ? NEGINFINITY : POSINFINITY;

		/* Using Knuth's alogrithim, brute force the divide
		 * until the maximum allowable error is reached.
		*/
        while (place) {
        	lowden >>= 1;

        	if (hiden & 1)
				lowden += HIBITSET;

        	hiden >>= 1;

        	if (hiden < hinum) {
				hinum -= hiden;
                hinum -= lowden > lownum;
                lownum -= lowden;
                result += place;
            } else if (hiden == hinum && lowden <= lownum) {
                hinum = 0;
                lownum -= lowden;
                result += place;
            }

            place >>= 1;
        } /* end while (place) */

			/* adjust for sign and return result */
        return (Fract )(negative ? -result : result);

}	/* end FracDiv() */

/************************************************************
 * Fract FracMul (Fract x, Fract y)
 *
 * Perform 2.30 fixed-point multiplication, x * y
 *
 * Returns: 2.30 fixed-point product
 *
 ************************************************************/
Fract FracMul (x, y)
Fract x, y;
{
Fract x_high, x_low, y_high, y_low;
Fract fracx_high, fracx_low;
Fract fracy_high, fracy_low;
Fract prod1, prod2;

    x_high = x >> 30;
    y_high = y >> 30;
    x_low =  x & 0x3fffffff;
    y_low =  y & 0x3fffffff;

    prod1 = ((x_high * y_high) << 30) +
            (x_high * y_low) +
            (y_high * x_low);

    fracx_high = (x_low & 0xffff0000) >> 16;   
    fracx_low = x_low & 0xffff;

    fracy_high = (y_low & 0xffff0000) >> 16;   
    fracy_low = y_low & 0xffff;

    prod2 = ((fracx_high * fracy_high) << 2) +
            ((fracx_low * fracy_high) >> 14) +
            ((fracx_high * fracy_low) >> 14);

    return(prod1 + prod2);
}

/************************************************************
 * Fract FracSqrt (Fract x)
 *
 * Perform square root calculation on 2.30 fixed-point number,
 * using Newton's approximation method.
 *
 * Note: x is treated as an unsigned number with a range of
 *       0 to (4 - (2**30))
 ************************************************************/
Fract FracSqrt(x)
Fract x;
{
UFract x1, approx, fracdiv, square_rt;
int i, shift;

   if (x == 0)
      return(0);

   x1 = x;
   shift = 0;
   while (x1 < FRACONEHALF)
      {
      x1 <<= 2;
      shift++;
      }

   approx = (0x40000000 + x1) >> 1;
    
   for (i=1; i<3; i++) {
      fracdiv = (FracDiv(x1, approx));
      approx = ((fracdiv + approx) >> 1);
   }
   square_rt = (approx >> shift);

   return (square_rt);
}

/************************************************************
 * long LongMulDiv(long a, long b, long c)
 *
 * Returns (a*b)/c
 *
 ************************************************************/
long LongMulDiv(a, b, c)
long a, b, c;
{
        long temp[2];

        CompMul(a, b, temp);
        return CompDiv(c, temp);
}

/************************************************************
 * long ShortFracMul(long a, ShortFrac b)
 * 
 * Returns a * b, where a is a long int, and b is of type
 * ShortFrac, a 2.14 fixed-point number
 *
 ************************************************************/
long ShortFracMul(a, b)
long a;
ShortFrac b;
{
        int negative = FALSE;
        uint16 al, ah;
        uint32 lowlong, midlong, hilong;

        if (a < 0) { a = -a; negative = TRUE; }
        if (b < 0) { b = -b; negative ^= TRUE; }

        al = LOWORD(a); ah = HIWORD(a);

        midlong = USHORTMUL(ah, b);
        hilong = midlong & 0xFFFF0000;
        midlong <<= 16;
        midlong += 1 << 13;
        lowlong = USHORTMUL(al, b) + midlong;
        if (lowlong < midlong)
                hilong += ONEFIX;

        midlong = (lowlong >> 14) | (hilong << 2);
        return negative ? -midlong : midlong;
}

/************************************************************
 * int32 ShortMulDiv(int32 a, int16 b, int16 c)
 * 
 * Returns (a*b)/c
 *
 ************************************************************/
int32 ShortMulDiv(a, b, c)
int32 a;
int16 b;
int16 c;
{
        return LongMulDiv((long)a, (long)b, (long)c);
}

/************************************************************
 * ShortFrac ShortFracDot(ShortFrac a, ShortFrac b)
 * 
 * Returns a * b, where a and b are 2.14 fixed-point numbers
 *
 ************************************************************/
ShortFrac ShortFracDot(a, b)
ShortFrac a;
ShortFrac b;
{
        return SHORTMUL(a,b) + (1 << 13) >> 14;
}

/************************************************************
 *
 * Internal functions
 *
 *   void CompMul(long src1, long src2, long dst[2])
 *   long CompDiv(long src1, long src2[2])
 *
 ************************************************************/
static void CompMul (src1, src2, dst)
  long src1, src2;
  long *dst;
{
        int negative = (src1 ^ src2) < 0;
        register unsigned long dsthi, dstlo;

        if (src1 < 0)
                src1 = -src1;
        if (src2 < 0)
                src2 = -src2;
        {       unsigned short src1hi, src1lo;
                register unsigned short src2hi, src2lo;
                register unsigned long temp;
                src1hi = src1 >> 16;
                src1lo = src1;
                src2hi = src2 >> 16;
                src2lo = src2;
                temp = (unsigned long)src1hi * src2lo + (unsigned long)src1lo * src2hi;
                dsthi = (unsigned long)src1hi * src2hi + (temp >> 16);
                dstlo = (unsigned long)src1lo * src2lo;
                temp <<= 16;
                dsthi += (dstlo += temp) < temp;
                dst[0] = dsthi;
                dst[1] = dstlo;
        }
        if (negative)
                if (dstlo = -dstlo)
                        dsthi = ~dsthi;
                else
                        dsthi = -dsthi;
        dst[0] = dsthi;
        dst[1] = dstlo;
}


/************************************************************/
static long CompDiv (src1, src2)
  long  src1;
  long *src2;
{
        register unsigned long src2hi = src2[0], src2lo = src2[1];
        int negative = (long)(src2hi ^ src1) < 0;

        if ((long)src2hi < 0)
                if (src2lo = -src2lo)
                        src2hi = ~src2hi;
                else
                        src2hi = -src2hi;
        if (src1 < 0)
                src1 = -src1;
        {       register unsigned long src1hi, src1lo;
                unsigned long result = 0, place = 0x40000000;

                if ((src1hi = src1) & 1)
                        src1lo = 0x80000000;
                else
                        src1lo = 0;

                src1hi >>= 1;
                src2hi += (src2lo += src1hi) < src1hi;          /* round the result */

                if (src2hi > src1hi || src2hi == src1hi && src2lo >= src1lo)
                        if (negative)
                                return NEGINFINITY;
                        else
                                return POSINFINITY;
                while (place && src2hi)
                {       src1lo >>= 1;
                        if (src1hi & 1)
                                src1lo += 0x80000000;
                        src1hi >>= 1;
                        if (src1hi < src2hi)
                        {       src2hi -= src1hi;
                                src2hi -= src1lo > src2lo;
                                src2lo -= src1lo;
                                result += place;
                        }
                        else if (src1hi == src2hi && src1lo <= src2lo)
                        {       src2hi = 0;
                                src2lo -= src1lo;
                                result += place;
                        }
                        place >>= 1;
                }
                if (src2lo >= src1)
                        result += src2lo/src1;
                if (negative)
                        return -result;
                else
                        return result;
        }
}


/************************************************************
 * Total precision routine to multiply two 26.6 numbers <3>
 *
 *
 ************************************************************/
F26Dot6 Mul26Dot6 (a, b)
  F26Dot6  a, b;
{
        int negative = FALSE;
        uint16 al, bl, ah, bh;
        uint32 lowlong, midlong, hilong;

        if ((a <= FASTMUL26LIMIT) && (b <= FASTMUL26LIMIT) && (a >= -FASTMUL26LIMIT) && (b >= -FASTMUL26LIMIT))
                return a * b + (1 << 5) >> 6;                                           /* fast case */

        if (a < 0) { a = -a; negative = TRUE; }
        if (b < 0) { b = -b; negative ^= TRUE; }

        al = LOWORD(a); ah = HIWORD(a);
        bl = LOWORD(b); bh = HIWORD(b);

        midlong = USHORTMUL(al, bh) + USHORTMUL(ah, bl);
        hilong = USHORTMUL(ah, bh) + HIWORD(midlong);
        midlong <<= 16;
        midlong += 1 << 5;
        lowlong = USHORTMUL(al, bl) + midlong;
        hilong += lowlong < midlong;

        midlong = (lowlong >> 6) | (hilong << 26);
        return negative ? -midlong : midlong;
}

/************************************************************
 * Total precision routine to divide two 26.6 numbers
 *
 *
 ************************************************************/
F26Dot6 Div26Dot6 (num, den)
  F26Dot6 num, den;
{
        int negative = FALSE;
        register uint32 hinum, lownum, hiden, lowden, result, place;

        if (den == 0) return (num < 0 ) ? NEGINFINITY : POSINFINITY;

        if ( (num <= FASTDIV26LIMIT) && (num >= -FASTDIV26LIMIT) )                      /* fast case */
                return (num << 6) / den;

        if (num < 0) { num = -num; negative = TRUE; }
        if (den < 0) { den = -den; negative ^= TRUE; }

        hinum = ((uint32)num >> 26);
        lownum = ((uint32)num << 6);
        hiden = den;
        lowden = 0;
        result = 0;
        place = HIBITSET;

        if (hinum >= hiden) return negative ? NEGINFINITY : POSINFINITY;

        while (place)
        {
                lowden >>= 1;
                if (hiden & 1) lowden += HIBITSET;
                hiden >>= 1;
                if (hiden < hinum)
                {
                        hinum -= hiden;
                        hinum -= lowden > lownum;
                        lownum -= lowden;
                        result += place;
                }
                else if (hiden == hinum && lowden <= lownum)
                {
                        hinum = 0;
                        lownum -= lowden;
                        result += place;
                }
                place >>= 1;
        }

        return negative ? -result : result;
}


/* EOF: fixed_pt.c */



#pragma Code()
