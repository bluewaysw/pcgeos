/*******************************************************************
 *
 *  ttcalc.h
 *
 *    Arithmetic Computations (specification).
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

#ifndef TTCALC_H
#define TTCALC_H

#include "ttconfig.h"
#include "freetype.h"


#ifdef __cplusplus
  extern "C" {
#endif

#ifdef LONG64

  typedef INT64  TT_Int64;

#define ADD_64( x, y, z )  z = x + y
#define SUB_64( x, y, z )  z = x - y
#define MUL_64( x, y, z )  z = (TT_Int64)(x) * (y)

#define DIV_64( x, y )     ( (x) / (y) )

#define SQRT_64( x )       Sqrt64( x )
#define SQRT_32( x )       Sqrt32( x )

  LOCAL_DEF TT_Int32  Sqrt64( TT_Int64  l );

#else /* LONG64 */

  struct  TT_Int64_
  {
    TT_Word32  lo;
    TT_Word32  hi;
  };

  typedef struct TT_Int64_  TT_Int64;

#define ADD_64( x, y, z )  Add64( &x, &y, &z )
#define SUB_64( x, y, z )  Sub64( &x, &y, &z )
#define MUL_64( x, y, z )  MulTo64( x, y, &z )

#define DIV_64( x, y )     Div64by32( &x, y )

#define SQRT_64( x )       Sqrt64( &x )
#define SQRT_32( x )       Sqrt32( x )

  LOCAL_DEF void  Add64( TT_Int64*  x, TT_Int64*  y, TT_Int64*  z );
  LOCAL_DEF void  Sub64( TT_Int64*  x, TT_Int64*  y, TT_Int64*  z );

  LOCAL_DEF void  MulTo64( TT_Int32  x, TT_Int32  y, TT_Int64*  z );

  LOCAL_DEF TT_Int32  Div64by32( TT_Int64*  x, TT_Int32  y );

  LOCAL_DEF int  Order64( TT_Int64*  z );

  LOCAL_DEF TT_Int32  Sqrt64( TT_Int64*  l );

#endif /* LONG64 */

  /* The two following functions are now part of the API!          */

  /* TT_Long  TT_MulDiv( TT_Long  a, TT_Long  b, TT_Long  c );     */
  /* TT_Long  TT_MulFix( TT_Long  a, TT_Long  b );                 */


#define INT_TO_F26DOT6( x )    ( (Long)(x) << 6  )
#define INT_TO_F2DOT14( x )    ( (Long)(x) << 14 )
#define INT_TO_FIXED( x )      ( (Long)(x) << 16 )
#define F2DOT14_TO_FIXED( x )  ( (Long)(x) << 2  )
#define FLOAT_TO_FIXED( x )    ( (Long)(x * 65536.0) )

#define ROUND_F26DOT6( x )     ( x >= 0 ? (   ((x) + 32) & -64) \
                                        : ( -((32 - (x)) & -64) ) )

#ifdef __cplusplus
  }
#endif

#endif /* TTCALC_H */

/* END */
