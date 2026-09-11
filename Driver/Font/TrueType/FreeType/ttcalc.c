/*******************************************************************
 *
 *  ttcalc.c
 *
 *    Arithmetic Computations (body).
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 ******************************************************************/

#include "ttcalc.h"
#include "tttables.h"


#pragma code_seg(Resident)

/* Support for 1-complement arithmetic has been totally dropped in this */
/* release.  You can still write your own code if you need it...        */

#ifdef LONG64
 
  static const Long  Roots[63] =
  {
       1,    1,    2,     3,     4,     5,     8,    11,
      16,   22,   32,    45,    64,    90,   128,   181,
     256,  362,  512,   724,  1024,  1448,  2048,  2896,
    4096, 5892, 8192, 11585, 16384, 23170, 32768, 46340,

      65536,   92681,  131072,   185363,   262144,   370727,
     524288,  741455, 1048576,  1482910,  2097152,  2965820,
    4194304, 5931641, 8388608, 11863283, 16777216, 23726566,

      33554432,   47453132,   67108864,   94906265,
     134217728,  189812531,  268435456,  379625062,
     536870912,  759250125, 1073741824, 1518500250,
    2147483647
  };

  EXPORT_FUNC
  TT_Long  TT_MulDiv( TT_Long  a, TT_Long  b, TT_Long  c )
  {
    Long  s;


    s  = a; a = ABS( a );
    s ^= b; b = ABS( b );
    s ^= c; c = ABS( c );

    a = ((TT_Int64)a * b + c/2) / c;
    return ( s < 0 ) ? -a : a;
  }


  EXPORT_FUNC
  TT_Long  TT_MulFix( TT_Long  a, TT_Long  b )
  {
    Long  s;


    s  = a; a = ABS( a );
    s ^= b; b = ABS( b );

    a = ((TT_Int64)a * b + 0x8000) / 0x10000;
    return ( s < 0 ) ? -a : a;
  }


  LOCAL_FUNC
  Int  Order64( TT_Int64  z )
  {
    Int  j = 0;


    while ( z )
    {
      z = (unsigned INT64)z >> 1;
      j++;
    }
    return j - 1;
  }


  LOCAL_FUNC
  TT_Int32  Sqrt64( TT_Int64  l )
  {
    TT_Int64  r, s;


    if ( l <= 0 ) return 0;
    if ( l == 1 ) return 1;

    r = Roots[Order64( l )];

    do
    {
      s = r;
      r = ( r + l/r ) >> 1;
    }
    while ( r > s || r*r > l );

    return r;
  }

#else /* LONG64 */


  /* The TT_MulDiv function has been optimized thanks to ideas from      */
  /* Graham Asher. The trick is to optimize computation when everything  */
  /* fits within 32-bits (a rather common case).                         */
  /*                                                                     */
  /*  we compute 'a*b+c/2', then divide it by 'c'. (positive values)     */
  /*                                                                     */
  /*  46340 is FLOOR(SQRT(2^31-1)).                                      */
  /*                                                                     */
  /*  if ( a <= 46340 && b <= 46340 ) then ( a*b <= 0x7FFEA810 )         */
  /*                                                                     */
  /*  0x7FFFFFFF - 0x7FFEA810 = 0x157F0                                  */
  /*                                                                     */
  /*  if ( c < 0x157F0*2 ) then ( a*b+c/2 <= 0x7FFFFFFF )                */
  /*                                                                     */
  /*  and 2*0x157F0 = 176096                                             */
  /*                                                                     */

  EXPORT_FUNC
  TT_Long  TT_MulDiv( TT_Long  a, TT_Long  b, TT_Long  c )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION

    __asm {
      ; Preserve existing division-by-zero semantics.
      mov     ebx, c
      test    ebx, ebx
      jz      divide_by_zero

      ; a == 0 -> 0
      mov     eax, a
      test    eax, eax
      jz      done

      ; Load b once for the remaining fast paths and multiplication.
      mov     ecx, b

      ; b == 0 -> 0
      test    ecx, ecx
      jz      result_zero

      ; b == c -> a
      cmp     ecx, ebx
      je      done

      ; edx:eax = a * b
      imul    ecx

      ; prepare rounding value: abs(c) / 2
      mov     ecx, ebx
      sar     ecx, 31
      xor     ebx, ecx
      sub     ebx, ecx
      shr     ebx, 1

      ; apply rounding based on the sign of the product
      test    edx, edx
      js      is_negative

      add     eax, ebx
      adc     edx, 0
      jmp     do_div

    is_negative:
      sub     eax, ebx
      sbb     edx, 0

    do_div:
      idiv    c
      jmp     done

    result_zero:
      xor     eax, eax
      jmp     done

    divide_by_zero:
      mov     eax, 7FFFFFFFh

    done:
      ; result into DX:AX
      mov     edx, eax
      shr     edx, 16
    }
  #else
    long   s;


    if ( a == 0 || b == c )
      return a;

    s  = a; a = ABS( a );
    s ^= b; b = ABS( b );
    s ^= c; c = ABS( c );

    if ( a <= 46340 && b <= 46340 && c <= 176095 )
    {
      a = ( a*b + (c >> 1) )/c;
    }
    else
    {
      TT_Int64  temp, temp2;

      MulTo64( a, b, &temp );
      temp2.hi = (TT_Int32)(c >> 31);
      temp2.lo = (TT_Word32)(c >> 1);
      Add64( &temp, &temp2, &temp );
      a = Div64by32( &temp, c );
    }

    return ( s < 0 ) ? -a : a;
  #endif
  }

#pragma code_seg()

  /* The optimization for TT_MulFix is different. We could simply be     */
  /* happy by applying the same principles than with TT_MulDiv, because  */
  /*                                                                     */
  /*    c = 0x10000 < 176096                                             */
  /*                                                                     */
  /* however, in most cases, we have a 'b' with a value around 0x10000   */
  /* which is greater than 46340.                                        */
  /*                                                                     */
  /* According to Graham's testing, most cases have 'a' < 100, so a good */
  /* idea is to use bounds like 1024 and 2097151 (= floor(2^31-1)/1024 ) */
  /* for 'a' and 'b' respectively..                                      */
  /*                                                                     */

  EXPORT_FUNC
  TT_Long   TT_MulFix( TT_Long  a, TT_Long  b )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION
     __asm {
        ; Load a.  Keep it in EAX because EAX is also the
        ; result register for the general multiplication.
        mov     eax, a

        ; a == 0 -> 0
        test    eax, eax
        jz      mulfix_done

        ; a == 1.0 -> b
        cmp     eax, 0x10000
        je      mulfix_return_b

        ; Load b once.  ECX can later be used directly by IMUL.
        mov     ecx, b

        ; b == 0 -> 0
        test    ecx, ecx
        jz      mulfix_zero

        ; b == 1.0 -> a
        cmp     ecx, 0x10000
        je      mulfix_done

        ; signed multiplication
        ; EDX:EAX = a * b
        imul    ecx

        ; round to nearest, preserving the existing
        ; symmetric handling of negative values
        bt      edx, 31
        cmc
        adc     eax, 0x7fff
        adc     edx, 0

        ; fixed point scaling
        shrd    eax, edx, 16
        jmp     mulfix_done

    mulfix_return_b:
        mov     eax, b
        jmp     mulfix_done

    mulfix_zero:
        xor     eax, eax

    mulfix_done:
        ; Return Long in DX:AX
        mov     edx, eax
        shr     edx, 16
    }
  #else
    long   s;

    if ( a == 0 || b == 0x10000 )
      return a;

    s  = a; a = ABS( a );
    s ^= b; b = ABS( b );

    if ( a <= 1024 && b <= 2097151 )
    {
      a = ( a*b + 0x8000 ) >> 16;
    }
    else
    {
      TT_Int64  temp, temp2;

      MulTo64( a, b, &temp );
      temp2.hi = 0;
      temp2.lo = 0x8000;
      Add64( &temp, &temp2, &temp );
      a = Div64by32( &temp, 0x10000 );
    }

    return ( s < 0 ) ? -a : a;
  #endif
  }


  LOCAL_FUNC
  void  Neg64( TT_Int64*  x )
  {
    /* Remember that -(0x80000000) == 0x80000000 with 2-complement! */
    /* We take care of that here.                                   */

    x->hi ^= 0xFFFFFFFFUL;
    x->lo ^= 0xFFFFFFFFUL;
    x->lo++;

    if ( !x->lo )
    {
      x->hi++;
      if ( x->hi == 0x80000000UL )  /* Check -MaxInt32 - 1 */
      {
        x->lo--;
        x->hi--;  /* We return 0x7FFFFFFF! */
      }
    }
  }


  LOCAL_FUNC
  void  Add64( TT_Int64*  x, TT_Int64*  y, TT_Int64*  z )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION
    __asm {
        mov     eax, x           ; Load pointer to x into eax
        mov     edx, y           ; Load pointer to y into edx
        mov     ecx, z           ; Load pointer to z into ecx

        ; Add lower 32 bits
        mov     ebx, [eax]       ; Load x->lo into ebx
        add     ebx, [edx]       ; Add y->lo to ebx
        mov     [ecx], ebx       ; Store result in z->lo

        ; Add upper 32 bits with carry
        mov     ebx, [eax + 4]   ; Load x->hi into ebx
        adc     ebx, [edx + 4]   ; Add y->hi to ebx with carry
        mov     [ecx + 4], ebx   ; Store result in z->hi
    }
  #else
    register TT_Word32  lo, hi;


    lo = x->lo + y->lo;
    hi = x->hi + y->hi + ( lo < x->lo );

    z->lo = lo;
    z->hi = hi;
  #endif
  }


  LOCAL_FUNC
  void  MulTo64( TT_Int32  x, TT_Int32  y, TT_Int64*  z )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION
    __asm {
        mov     eax, x           ; Load x into eax
        imul    y                ; Signed multiply eax by y

        mov     ecx, z           ; Load address of z into esi
        mov     [ecx], eax       ; Store low 32 bits (eax) into z->lo
        mov     [ecx + 4], edx   ; Store high 32 bits (edx) into z->hi
    }
  #else
    TT_Int32   s;
    TT_Word32  lo1, hi1, lo2, hi2, lo, hi, i1, i2;


    s  = x; x = ABS( x );
    s ^= y; y = ABS( y );

    lo1 = x & 0x0000FFFF;  hi1 = x >> 16;
    lo2 = y & 0x0000FFFF;  hi2 = y >> 16;

    lo = lo1*lo2;
    i1 = lo1*hi2;
    i2 = lo2*hi1;
    hi = hi1*hi2;

    /* Check carry overflow of i1 + i2 */

    if ( i2 )
    {
      if ( i1 >= (TT_Word32)-(TT_Int32)i2 ) hi += 1L << 16;
      i1 += i2;
    }

    i2 = i1 >> 16;
    i1 = i1 << 16;

    /* Check carry overflow of i1 + lo */
    if ( i1 )
    {
      if ( lo >= (TT_Word32)-(TT_Int32)i1 ) ++hi;
      lo += i1;
    }

    hi += i2;

    z->lo = lo;
    z->hi = hi;

    if ( s < 0 ) Neg64( z );
  #endif
  }


  LOCAL_FUNC
  TT_Int32  Div64by32( TT_Int64*  x, TT_Int32  y )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION
    __asm {
        mov     ecx, y                ; load divisor
        test    ecx, ecx              ; check for zero
        jz      overflow

        mov     esi, x                ; pointer to x
        mov     eax, [esi]            ; low 32 bits
        mov     edx, [esi+4]          ; high 32 bits
        
        idiv    ecx                   ; result in EAX
        jmp     done

    overflow:
        mov     eax, [esi+4]          ; sign of dividend
        sar     eax, 31               ; 0xFFFFFFFF if neg, 0 if pos
        mov     edx, eax              ; temp storage
        xor     eax, 0x7FFFFFFF       ; flip bits: 0x7FFFFFFF (pos) or 0x80000000 (neg)

    done:
        mov     edx, eax              ; store result in dx:ax
        shr     edx, 16
    }
  #else
    TT_Int32   s;
    TT_Word32  q, r, i, lo;


    s  = x->hi; if ( s < 0 ) Neg64( x );
    s ^= y;     y = ABS( y );

    /* Shortcut */
    if ( x->hi == 0 )
    {
      q = x->lo / y;
      return ( s < 0 ) ? -(TT_Int32)q : (TT_Int32)q;
    }

    r  = x->hi;
    lo = x->lo;

    if ( r >= (TT_Word32)y )   /* we know y is to be treated as unsigned here */
      return ( s < 0 ) ? 0x80000001UL : 0x7FFFFFFFUL;
                            /* Return Max/Min Int32 if divide overflow */
                            /* This includes division by zero!         */
    q = 0;
    for ( i = 0; i < 32; ++i )
    {
      r <<= 1;
      q <<= 1;
      r  |= lo >> 31;

      if ( r >= (TT_Word32)y )
      {
        r -= y;
        q |= 1;
      }
      lo <<= 1;
    }

    return ( s < 0 ) ? -(TT_Int32)q : (TT_Int32)q;
  #endif
  }

  LOCAL_FUNC
  TT_Int32  Sqrt64( TT_Int64*  l )
  {
  #ifdef TT_CONFIG_OPTION_USE_ASSEMBLER_IMPLEMENTATION
    __asm {
        push    es

        les     si, l                     ; es:si = l
        mov     eax, dword ptr es:[si]    ; edx:eax = l
        mov     edx, dword ptr es:[si+4]

        test    edx, edx                  ; handle 0 and 1
        jnz     sqrt_start
        test    eax, eax
        jz      sqrt_done
        cmp     eax, 1
        je      sqrt_done

  sqrt_start:
        ; determine floor(log2(l))
        test    edx, edx
        jnz     sqrt_guess_hi

        bsr     ecx, eax
        jmp     sqrt_set_guess

sqrt_guess_hi:
        bsr     ecx, edx
        add     ecx, 32

sqrt_set_guess:
        shr     ecx, 1
        inc     ecx

        mov     ebx, 1
        shl     ebx, cl

sqrt_loop:
        ; quotient = l / x
        mov     eax, dword ptr es:[si]
        mov     edx, dword ptr es:[si+4]
        div     ebx

        ; next = (x + quotient) / 2
        add     eax, ebx
        rcr     eax, 1

        cmp     eax, ebx
        jae     sqrt_finished
        mov     ebx, eax
        jmp     sqrt_loop

sqrt_finished:
        mov     eax, ebx

sqrt_done:
        pop     es

        mov     edx, eax      ; store result in dx:ax
        shr     edx, 16
    }
#else
	  long  x = l->hi ? l->hi >> 1 : l->lo >> 1;
	
    if (l->hi == 0 )
    {
      if ( l->lo == 0 ) return 0;
      if ( l->hi == 1 ) return 1;
    }
        	
    /* Newton-Raphson iteration for square root approximation */
    while (1) 
    {
      // Combined calculation: (x + value/x) / 2
      long next = (x + Div64by32( l, x )) >> 1;

      // Check for convergence
      if (next >= x)
        return x;

      // Update approximation
      x = next;
    }
  #endif
  }

#endif /* LONG64 */


/* This convenience function applies TT_MulDiv to a list.                  */
/* Its main purpose is to reduce the number of inter-module calls in GEOS. */

LOCAL_FUNC
void  MulDivList( TT_Long*  a, UShort  n, TT_Short*  b, TT_Long  c, TT_Long  d )
{
  UShort i;

  for ( i = 0; i < n; ++i )
    a[i] = TT_MulDiv( b[i], c, d );
}

/* This convenience function applies a matrix  to a list of vectors.       */
/* Its main purpose is to reduce the number of inter-module calls in GEOS. */

LOCAL_FUNC
void  TransVecList( TT_Vector*  vec, UShort  n, TT_Matrix*  matrix )
{
    UShort   i;
    TT_Long  x, y;

    for ( i = 0; i < n; ++i )
    {
      x = TT_MulFix( vec->x, matrix->xx ) + TT_MulFix( vec->y, matrix->xy );
      y = TT_MulFix( vec->x, matrix->yx ) + TT_MulFix( vec->y, matrix->yy );

      vec->x = x;
      vec->y = y;
      ++vec;
    }  
}

/* END */
