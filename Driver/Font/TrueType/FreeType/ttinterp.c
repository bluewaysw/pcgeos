/*******************************************************************
 *
 *  ttinterp.c                                              3.1
 *
 *  TrueType bytecode intepreter.
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *
 *  Changes between 3.1 and 3.0:
 *
 *  - A more relaxed version of the interpreter.  It is now able to
 *    ignore errors like out-of-bound array access and writes in order
 *    to silently support broken glyphs (even if the results are not
 *    always pretty).
 *
 *    Note that one can use the flag TTLOAD_PEDANTIC to force
 *    TrueType-compliant interpretation.
 *
 *  - A big #if used to completely disable the interpreter, which
 *    is due to the Apple patents issues which emerged recently.
 *
 ******************************************************************/

#include "freetype.h"
#include "tttypes.h"
#include "ttcalc.h"
#include "ttmemory.h"
#include "ttinterp.h"


#ifdef TT_CONFIG_OPTION_NO_INTERPRETER

  LOCAL_FUNC
  TT_Error  RunIns( PExecution_Context  exc )
  {
    /* do nothing - always successful */
    (void)exc;
    return TT_Err_Ok;
  }

#else


#ifdef DEBUG_INTERPRETER
#include <memory.h>

/* Define the `getch()' function.  On Unix systems, it is an alias  */
/* for `getchar()', and the debugger front end must ensure that the */
/* `stdin' file descriptor is not in line-by-line input mode.       */
#ifdef OS2
#include <conio.h>
#else
#define getch  getchar
#endif

#endif /* DEBUG_INTEPRETER */


/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT      trace_interp


/* In order to detect infinite loops in the code, we set-up         */
/* a counter within the run loop. a singly stroke of interpretation */
/* is now limited to a maximum number of opcodes defined below..    */
/*                                                                  */
#define MAX_RUNNABLE_OPCODES  1000000


/* There are two kinds of implementations there:              */
/*                                                            */
/* a. static implementation:                                  */
/*                                                            */
/*    The current execution context is a static variable,     */
/*    which fields are accessed directly by the interpreter   */
/*    during execution.  The context is named 'cur'.          */
/*                                                            */
/*    This version is non-reentrant, of course.               */
/*                                                            */
/*                                                            */
/* b. indirect implementation:                                */
/*                                                            */
/*    The current execution context is passed to _each_       */
/*    function as its first argument, and each field is       */
/*    thus accessed indirectly.                               */
/*                                                            */
/*    This version is, however, fully re-entrant.             */
/*                                                            */
/*                                                            */
/*  The idea is that an indirect implementation may be        */
/*  slower to execute on the low-end processors that are      */
/*  used in some systems (like 386s or even 486s).            */
/*                                                            */
/*  When the interpreter started, we had no idea of the       */
/*  time that glyph hinting (i.e. executing instructions)     */
/*  could take in the whole process of rendering a glyph,     */
/*  and a 10 to 30% performance penalty on low-end systems    */
/*  didn't seem much of a good idea.  This question led us    */
/*  to provide two distinct builds of the C version from      */
/*  a single source, with the use of macros (again).          */
/*                                                            */
/*  Now that the engine is working (and working really        */
/*  well!), it seems that the greatest time-consuming         */
/*  factors are: file i/o, glyph loading, rasterizing and     */
/*  _then_ glyph hinting!                                     */
/*                                                            */
/*  Tests performed with two versions of the 'fttimer'        */
/*  program seem to indicate that hinting takes less than 5%  */
/*  of the rendering process, which is dominated by glyph     */
/*  loading and scan-line conversion by an high order of      */
/*  magnitude.                                                */
/*                                                            */
/*  As a consequence, the indirect implementation is now the  */
/*  default, as its performance costs can be considered       */
/*  negligible in our context. Note, however, that we         */
/*  kept the same source with macros because:                 */
/*                                                            */
/*    - the code is kept very close in design to the          */
/*      Pascal one used for development.                      */
/*                                                            */
/*    - it's much more readable that way!                     */
/*                                                            */
/*    - it's still open to later experimentation and tuning   */



#ifndef TT_CONFIG_OPTION_STATIC_INTERPRETER      /* indirect implementation */

#define CUR (*exc)                 /* see ttobjs.h */

#else                              /* static implementation */

#define CUR cur

  static TExecution_Context  cur;  /* static exec. context variable */

  /* apparently, we have a _lot_ of direct indexing when accessing  */
  /* the static 'cur', which makes the code bigger (due to all the  */
  /* four bytes addresses).                                         */

#endif  /* !TT_CONFIG_OPTION_STATIC_INTERPRETER */


#define INS_ARG         EXEC_OPS PStorage args  /* see ttobjs.h */

#define SKIP_Code()     SkipCode( EXEC_ARG )

#define GET_ShortIns()  GetShortIns( EXEC_ARG )

#define COMPUTE_Funcs() Compute_Funcs( EXEC_ARG )

#define NORMalize( x, y, v )  Normalize( EXEC_ARGS x, y, v )

#define SET_SuperRound( scale, flags ) \
                        SetSuperRound( EXEC_ARGS scale, flags )

#define INS_Goto_CodeRange( range, ip ) \
                        Ins_Goto_CodeRange( EXEC_ARGS range, ip )

#ifdef __GEOS__
#define CUR_Func_project( x, y )   ProcCallFixedOrMovable_cdecl( CUR.func_project, EXEC_ARGS x, y )
#else
#define CUR_Func_project( x, y )   CUR.func_project( EXEC_ARGS x, y )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_move( z, p, d )   ProcCallFixedOrMovable_cdecl( CUR.func_move, EXEC_ARGS z, p, d )
#else
#define CUR_Func_move( z, p, d )   CUR.func_move( EXEC_ARGS z, p, d )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_dualproj( x, y )  ProcCallFixedOrMovable_cdecl( CUR.func_dualproj, EXEC_ARGS x, y )
#else
#define CUR_Func_dualproj( x, y )  CUR.func_dualproj( EXEC_ARGS x, y )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_freeProj( x, y )  ProcCallFixedOrMovable_cdecl( CUR.func_freeProj, EXEC_ARGS x, y )
#else
#define CUR_Func_freeProj( x, y )  CUR.func_freeProj( EXEC_ARGS x, y )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_round( d, c )     ProcCallFixedOrMovable_cdecl( CUR.func_round, EXEC_ARGS d, c )
#else
#define CUR_Func_round( d, c )     CUR.func_round( EXEC_ARGS d, c )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_read_cvt( index )  ProcCallFixedOrMovable_cdecl( CUR.func_read_cvt, EXEC_ARGS index ) 
#else
#define CUR_Func_read_cvt( index )  CUR.func_read_cvt( EXEC_ARGS index )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_write_cvt( index, val ) ProcCallFixedOrMovable_cdecl( CUR.func_write_cvt, EXEC_ARGS index, val )
#else
#define CUR_Func_write_cvt( index, val ) CUR.func_write_cvt( EXEC_ARGS index, val )
#endif  /* __GEOS__ */

#ifdef __GEOS__
#define CUR_Func_move_cvt( index, val ) ProcCallFixedOrMovable_cdecl( CUR.func_move_cvt, EXEC_ARGS index, val )
#else
#define CUR_Func_move_cvt( index, val ) CUR.func_move_cvt( EXEC_ARGS index, val )
#endif  /* __GEOS__ */

#define CURRENT_Ratio()  Current_Ratio( EXEC_ARG )
#define CURRENT_Ppem()   Current_Ppem( EXEC_ARG )

#define CALC_Length()  Calc_Length( EXEC_ARG )

#define INS_SxVTL( a, b, c, d ) Ins_SxVTL( EXEC_ARGS a, b, c, d )

#define COMPUTE_Point_Displacement( a, b, c, d ) \
           Compute_Point_Displacement( EXEC_ARGS a, b, c, d )

#define MOVE_Zp2_Point( a, b, c, t )  Move_Zp2_Point( EXEC_ARGS a, b, c, t )

#define CUR_Ppem()  Cur_PPEM( EXEC_ARG )

  /* Instruction dispatch function, as used by the interpreter */
  typedef void  (*TInstruction_Function)( INS_ARG );

#define BOUNDS( x, n )  ( (x) >= (n) )



/*********************************************************************/
/*                                                                   */
/*  Before an opcode is executed, the interpreter verifies that      */
/*  there are enough arguments on the stack, with the help of        */
/*  the Pop_Push_Count table.                                        */
/*                                                                   */
/*  For each opcode, the first column gives the number of arguments  */
/*  that are popped from the stack; the second one gives the number  */
/*  of those that are pushed in result.                              */
/*                                                                   */
/*  Note that for opcodes with a varying number of parameters,       */
/*  either 0 or 1 arg is verified before execution, depending        */
/*  on the nature of the instruction:                                */
/*                                                                   */
/*   - if the number of arguments is given by the bytecode           */
/*     stream or the loop variable, 0 is chosen.                     */
/*                                                                   */
/*   - if the first argument is a count n that is followed           */
/*     by arguments a1..an, then 1 is chosen.                        */
/*                                                                   */
/*********************************************************************/

#undef  PACK
#define PACK( x, y )  ((x << 4) | y)

  static const Byte  Pop_Push_Count[256] =
  {
    /* opcodes are gathered in groups of 16 */
    /* please keep the spaces as they are   */

    /*  SVTCA  y  */  PACK( 0, 0 ),
    /*  SVTCA  x  */  PACK( 0, 0 ),
    /*  SPvTCA y  */  PACK( 0, 0 ),
    /*  SPvTCA x  */  PACK( 0, 0 ),
    /*  SFvTCA y  */  PACK( 0, 0 ),
    /*  SFvTCA x  */  PACK( 0, 0 ),
    /*  SPvTL //  */  PACK( 2, 0 ),
    /*  SPvTL +   */  PACK( 2, 0 ),
    /*  SFvTL //  */  PACK( 2, 0 ),
    /*  SFvTL +   */  PACK( 2, 0 ),
    /*  SPvFS     */  PACK( 2, 0 ),
    /*  SFvFS     */  PACK( 2, 0 ),
    /*  GPV       */  PACK( 0, 2 ),
    /*  GFV       */  PACK( 0, 2 ),
    /*  SFvTPv    */  PACK( 0, 0 ),
    /*  ISECT     */  PACK( 5, 0 ),

    /*  SRP0      */  PACK( 1, 0 ),
    /*  SRP1      */  PACK( 1, 0 ),
    /*  SRP2      */  PACK( 1, 0 ),
    /*  SZP0      */  PACK( 1, 0 ),
    /*  SZP1      */  PACK( 1, 0 ),
    /*  SZP2      */  PACK( 1, 0 ),
    /*  SZPS      */  PACK( 1, 0 ),
    /*  SLOOP     */  PACK( 1, 0 ),
    /*  RTG       */  PACK( 0, 0 ),
    /*  RTHG      */  PACK( 0, 0 ),
    /*  SMD       */  PACK( 1, 0 ),
    /*  ELSE      */  PACK( 0, 0 ),
    /*  JMPR      */  PACK( 1, 0 ),
    /*  SCvTCi    */  PACK( 1, 0 ),
    /*  SSwCi     */  PACK( 1, 0 ),
    /*  SSW       */  PACK( 1, 0 ),

    /*  DUP       */  PACK( 1, 2 ),
    /*  POP       */  PACK( 1, 0 ),
    /*  CLEAR     */  PACK( 0, 0 ),
    /*  SWAP      */  PACK( 2, 2 ),
    /*  DEPTH     */  PACK( 0, 1 ),
    /*  CINDEX    */  PACK( 1, 1 ),
    /*  MINDEX    */  PACK( 1, 0 ),
    /*  AlignPTS  */  PACK( 2, 0 ),
    /*  INS_$28   */  PACK( 0, 0 ),
    /*  UTP       */  PACK( 1, 0 ),
    /*  LOOPCALL  */  PACK( 2, 0 ),
    /*  CALL      */  PACK( 1, 0 ),
    /*  FDEF      */  PACK( 1, 0 ),
    /*  ENDF      */  PACK( 0, 0 ),
    /*  MDAP[0]   */  PACK( 1, 0 ),
    /*  MDAP[1]   */  PACK( 1, 0 ),

    /*  IUP[0]    */  PACK( 0, 0 ),
    /*  IUP[1]    */  PACK( 0, 0 ),
    /*  SHP[0]    */  PACK( 0, 0 ),
    /*  SHP[1]    */  PACK( 0, 0 ),
    /*  SHC[0]    */  PACK( 1, 0 ),
    /*  SHC[1]    */  PACK( 1, 0 ),
    /*  SHZ[0]    */  PACK( 1, 0 ),
    /*  SHZ[1]    */  PACK( 1, 0 ),
    /*  SHPIX     */  PACK( 1, 0 ),
    /*  IP        */  PACK( 0, 0 ),
    /*  MSIRP[0]  */  PACK( 2, 0 ),
    /*  MSIRP[1]  */  PACK( 2, 0 ),
    /*  AlignRP   */  PACK( 0, 0 ),
    /*  RTDG      */  PACK( 0, 0 ),
    /*  MIAP[0]   */  PACK( 2, 0 ),
    /*  MIAP[1]   */  PACK( 2, 0 ),

    /*  NPushB    */  PACK( 0, 0 ),
    /*  NPushW    */  PACK( 0, 0 ),
    /*  WS        */  PACK( 2, 0 ),
    /*  RS        */  PACK( 1, 1 ),
    /*  WCvtP     */  PACK( 2, 0 ),
    /*  RCvt      */  PACK( 1, 1 ),
    /*  GC[0]     */  PACK( 1, 1 ),
    /*  GC[1]     */  PACK( 1, 1 ),
    /*  SCFS      */  PACK( 2, 0 ),
    /*  MD[0]     */  PACK( 2, 1 ),
    /*  MD[1]     */  PACK( 2, 1 ),
    /*  MPPEM     */  PACK( 0, 1 ),
    /*  MPS       */  PACK( 0, 1 ),
    /*  FlipON    */  PACK( 0, 0 ),
    /*  FlipOFF   */  PACK( 0, 0 ),
    /*  DEBUG     */  PACK( 1, 0 ),

    /*  LT        */  PACK( 2, 1 ),
    /*  LTEQ      */  PACK( 2, 1 ),
    /*  GT        */  PACK( 2, 1 ),
    /*  GTEQ      */  PACK( 2, 1 ),
    /*  EQ        */  PACK( 2, 1 ),
    /*  NEQ       */  PACK( 2, 1 ),
    /*  ODD       */  PACK( 1, 1 ),
    /*  EVEN      */  PACK( 1, 1 ),
    /*  IF        */  PACK( 1, 0 ),
    /*  EIF       */  PACK( 0, 0 ),
    /*  AND       */  PACK( 2, 1 ),
    /*  OR        */  PACK( 2, 1 ),
    /*  NOT       */  PACK( 1, 1 ),
    /*  DeltaP1   */  PACK( 1, 0 ),
    /*  SDB       */  PACK( 1, 0 ),
    /*  SDS       */  PACK( 1, 0 ),

    /*  ADD       */  PACK( 2, 1 ),
    /*  SUB       */  PACK( 2, 1 ),
    /*  DIV       */  PACK( 2, 1 ),
    /*  MUL       */  PACK( 2, 1 ),
    /*  ABS       */  PACK( 1, 1 ),
    /*  NEG       */  PACK( 1, 1 ),
    /*  FLOOR     */  PACK( 1, 1 ),
    /*  CEILING   */  PACK( 1, 1 ),
    /*  ROUND[0]  */  PACK( 1, 1 ),
    /*  ROUND[1]  */  PACK( 1, 1 ),
    /*  ROUND[2]  */  PACK( 1, 1 ),
    /*  ROUND[3]  */  PACK( 1, 1 ),
    /*  NROUND[0] */  PACK( 1, 1 ),
    /*  NROUND[1] */  PACK( 1, 1 ),
    /*  NROUND[2] */  PACK( 1, 1 ),
    /*  NROUND[3] */  PACK( 1, 1 ),

    /*  WCvtF     */  PACK( 2, 0 ),
    /*  DeltaP2   */  PACK( 1, 0 ),
    /*  DeltaP3   */  PACK( 1, 0 ),
    /*  DeltaCn[0] */ PACK( 1, 0 ),
    /*  DeltaCn[1] */ PACK( 1, 0 ),
    /*  DeltaCn[2] */ PACK( 1, 0 ),
    /*  SROUND    */  PACK( 1, 0 ),
    /*  S45Round  */  PACK( 1, 0 ),
    /*  JROT      */  PACK( 2, 0 ),
    /*  JROF      */  PACK( 2, 0 ),
    /*  ROFF      */  PACK( 0, 0 ),
    /*  INS_$7B   */  PACK( 0, 0 ),
    /*  RUTG      */  PACK( 0, 0 ),
    /*  RDTG      */  PACK( 0, 0 ),
    /*  SANGW     */  PACK( 1, 0 ),
    /*  AA        */  PACK( 1, 0 ),

    /*  FlipPT    */  PACK( 0, 0 ),
    /*  FlipRgON  */  PACK( 2, 0 ),
    /*  FlipRgOFF */  PACK( 2, 0 ),
    /*  INS_$83   */  PACK( 0, 0 ),
    /*  INS_$84   */  PACK( 0, 0 ),
    /*  ScanCTRL  */  PACK( 1, 0 ),
    /*  SDVPTL[0] */  PACK( 2, 0 ),
    /*  SDVPTL[1] */  PACK( 2, 0 ),
    /*  GetINFO   */  PACK( 1, 1 ),
    /*  IDEF      */  PACK( 1, 0 ),
    /*  ROLL      */  PACK( 3, 3 ),
    /*  MAX       */  PACK( 2, 1 ),
    /*  MIN       */  PACK( 2, 1 ),
    /*  ScanTYPE  */  PACK( 1, 0 ),
    /*  InstCTRL  */  PACK( 2, 0 ),
    /*  INS_$8F   */  PACK( 0, 0 ),

    /*  INS_$90  */   PACK( 0, 0 ),
    /*  INS_$91  */   PACK( 0, 0 ),
    /*  INS_$92  */   PACK( 0, 0 ),
    /*  INS_$93  */   PACK( 0, 0 ),
    /*  INS_$94  */   PACK( 0, 0 ),
    /*  INS_$95  */   PACK( 0, 0 ),
    /*  INS_$96  */   PACK( 0, 0 ),
    /*  INS_$97  */   PACK( 0, 0 ),
    /*  INS_$98  */   PACK( 0, 0 ),
    /*  INS_$99  */   PACK( 0, 0 ),
    /*  INS_$9A  */   PACK( 0, 0 ),
    /*  INS_$9B  */   PACK( 0, 0 ),
    /*  INS_$9C  */   PACK( 0, 0 ),
    /*  INS_$9D  */   PACK( 0, 0 ),
    /*  INS_$9E  */   PACK( 0, 0 ),
    /*  INS_$9F  */   PACK( 0, 0 ),

    /*  INS_$A0  */   PACK( 0, 0 ),
    /*  INS_$A1  */   PACK( 0, 0 ),
    /*  INS_$A2  */   PACK( 0, 0 ),
    /*  INS_$A3  */   PACK( 0, 0 ),
    /*  INS_$A4  */   PACK( 0, 0 ),
    /*  INS_$A5  */   PACK( 0, 0 ),
    /*  INS_$A6  */   PACK( 0, 0 ),
    /*  INS_$A7  */   PACK( 0, 0 ),
    /*  INS_$A8  */   PACK( 0, 0 ),
    /*  INS_$A9  */   PACK( 0, 0 ),
    /*  INS_$AA  */   PACK( 0, 0 ),
    /*  INS_$AB  */   PACK( 0, 0 ),
    /*  INS_$AC  */   PACK( 0, 0 ),
    /*  INS_$AD  */   PACK( 0, 0 ),
    /*  INS_$AE  */   PACK( 0, 0 ),
    /*  INS_$AF  */   PACK( 0, 0 ),

    /*  PushB[0]  */  PACK( 0, 1 ),
    /*  PushB[1]  */  PACK( 0, 2 ),
    /*  PushB[2]  */  PACK( 0, 3 ),
    /*  PushB[3]  */  PACK( 0, 4 ),
    /*  PushB[4]  */  PACK( 0, 5 ),
    /*  PushB[5]  */  PACK( 0, 6 ),
    /*  PushB[6]  */  PACK( 0, 7 ),
    /*  PushB[7]  */  PACK( 0, 8 ),
    /*  PushW[0]  */  PACK( 0, 1 ),
    /*  PushW[1]  */  PACK( 0, 2 ),
    /*  PushW[2]  */  PACK( 0, 3 ),
    /*  PushW[3]  */  PACK( 0, 4 ),
    /*  PushW[4]  */  PACK( 0, 5 ),
    /*  PushW[5]  */  PACK( 0, 6 ),
    /*  PushW[6]  */  PACK( 0, 7 ),
    /*  PushW[7]  */  PACK( 0, 8 ),

    /*  MDRP[00]  */  PACK( 1, 0 ),
    /*  MDRP[01]  */  PACK( 1, 0 ),
    /*  MDRP[02]  */  PACK( 1, 0 ),
    /*  MDRP[03]  */  PACK( 1, 0 ),
    /*  MDRP[04]  */  PACK( 1, 0 ),
    /*  MDRP[05]  */  PACK( 1, 0 ),
    /*  MDRP[06]  */  PACK( 1, 0 ),
    /*  MDRP[07]  */  PACK( 1, 0 ),
    /*  MDRP[08]  */  PACK( 1, 0 ),
    /*  MDRP[09]  */  PACK( 1, 0 ),
    /*  MDRP[10]  */  PACK( 1, 0 ),
    /*  MDRP[11]  */  PACK( 1, 0 ),
    /*  MDRP[12]  */  PACK( 1, 0 ),
    /*  MDRP[13]  */  PACK( 1, 0 ),
    /*  MDRP[14]  */  PACK( 1, 0 ),
    /*  MDRP[15]  */  PACK( 1, 0 ),

    /*  MDRP[16]  */  PACK( 1, 0 ),
    /*  MDRP[17]  */  PACK( 1, 0 ),
    /*  MDRP[18]  */  PACK( 1, 0 ),
    /*  MDRP[19]  */  PACK( 1, 0 ),
    /*  MDRP[20]  */  PACK( 1, 0 ),
    /*  MDRP[21]  */  PACK( 1, 0 ),
    /*  MDRP[22]  */  PACK( 1, 0 ),
    /*  MDRP[23]  */  PACK( 1, 0 ),
    /*  MDRP[24]  */  PACK( 1, 0 ),
    /*  MDRP[25]  */  PACK( 1, 0 ),
    /*  MDRP[26]  */  PACK( 1, 0 ),
    /*  MDRP[27]  */  PACK( 1, 0 ),
    /*  MDRP[28]  */  PACK( 1, 0 ),
    /*  MDRP[29]  */  PACK( 1, 0 ),
    /*  MDRP[30]  */  PACK( 1, 0 ),
    /*  MDRP[31]  */  PACK( 1, 0 ),

    /*  MIRP[00]  */  PACK( 2, 0 ),
    /*  MIRP[01]  */  PACK( 2, 0 ),
    /*  MIRP[02]  */  PACK( 2, 0 ),
    /*  MIRP[03]  */  PACK( 2, 0 ),
    /*  MIRP[04]  */  PACK( 2, 0 ),
    /*  MIRP[05]  */  PACK( 2, 0 ),
    /*  MIRP[06]  */  PACK( 2, 0 ),
    /*  MIRP[07]  */  PACK( 2, 0 ),
    /*  MIRP[08]  */  PACK( 2, 0 ),
    /*  MIRP[09]  */  PACK( 2, 0 ),
    /*  MIRP[10]  */  PACK( 2, 0 ),
    /*  MIRP[11]  */  PACK( 2, 0 ),
    /*  MIRP[12]  */  PACK( 2, 0 ),
    /*  MIRP[13]  */  PACK( 2, 0 ),
    /*  MIRP[14]  */  PACK( 2, 0 ),
    /*  MIRP[15]  */  PACK( 2, 0 ),

    /*  MIRP[16]  */  PACK( 2, 0 ),
    /*  MIRP[17]  */  PACK( 2, 0 ),
    /*  MIRP[18]  */  PACK( 2, 0 ),
    /*  MIRP[19]  */  PACK( 2, 0 ),
    /*  MIRP[20]  */  PACK( 2, 0 ),
    /*  MIRP[21]  */  PACK( 2, 0 ),
    /*  MIRP[22]  */  PACK( 2, 0 ),
    /*  MIRP[23]  */  PACK( 2, 0 ),
    /*  MIRP[24]  */  PACK( 2, 0 ),
    /*  MIRP[25]  */  PACK( 2, 0 ),
    /*  MIRP[26]  */  PACK( 2, 0 ),
    /*  MIRP[27]  */  PACK( 2, 0 ),
    /*  MIRP[28]  */  PACK( 2, 0 ),
    /*  MIRP[29]  */  PACK( 2, 0 ),
    /*  MIRP[30]  */  PACK( 2, 0 ),
    /*  MIRP[31]  */  PACK( 2, 0 )
  };

  static  const  TT_Vector  Null_Vector = {0,0};

#undef  NULL_Vector
#define NULL_Vector (TT_Vector*)&Null_Vector

/*******************************************************************
 *
 *  Function    :  Norm
 *
 *  Description :  Returns the norm (length) of a vector.
 *
 *  Input  :  X, Y   vector
 *
 *  Output :  Returns length in F26dot6.
 *
 *****************************************************************/

  static TT_F26Dot6  Norm( TT_F26Dot6  X, TT_F26Dot6  Y )
  {
    TT_Int64       T1, T2;


    MUL_64( X, X, T1 );
    MUL_64( Y, Y, T2 );

    ADD_64( T1, T2, T1 );

    return (TT_F26Dot6)SQRT_64( T1 );
  }


/*******************************************************************
 *
 *  Function    :  FUnits_To_Pixels
 *
 *  Description :  Scale a distance in FUnits to pixel coordinates.
 *
 *  Input  :  Distance in FUnits
 *
 *  Output :  Distance in 26.6 format.
 *
 *****************************************************************/

  static TT_F26Dot6  FUnits_To_Pixels( EXEC_OPS Short  distance )
  {
    return TT_MulDiv( distance,
                      CUR.metrics.scale1,
                      CUR.metrics.scale2 );
  }


/*******************************************************************
 *
 *  Function    :  Current_Ratio
 *
 *  Description :  Return the current aspect ratio scaling factor
 *                 depending on the projection vector's state and
 *                 device resolutions.
 *
 *  Input  :  None
 *
 *  Output :  Aspect ratio in 16.16 format, always <= 1.0 .
 *
 *****************************************************************/

  static Long  Current_Ratio( EXEC_OP )
  {
    if ( CUR.metrics.ratio )
      return CUR.metrics.ratio;

    if ( CUR.GS.projVector.y == 0 )
      CUR.metrics.ratio = CUR.metrics.x_ratio;

    else if ( CUR.GS.projVector.x == 0 )
      CUR.metrics.ratio = CUR.metrics.y_ratio;

    else
    {
      Long  x, y;


      x = TT_MulDiv( CUR.GS.projVector.x, CUR.metrics.x_ratio, 0x4000 );
      y = TT_MulDiv( CUR.GS.projVector.y, CUR.metrics.y_ratio, 0x4000 );
      CUR.metrics.ratio = Norm( x, y );
    }

    return CUR.metrics.ratio;
  }


  static Long  Current_Ppem( EXEC_OP )
  {
    return TT_MulFix( CUR.metrics.ppem, CURRENT_Ratio() );
  }


  static TT_F26Dot6  Read_CVT( EXEC_OPS ULong  index )
  {
    return CUR.cvt[index];
  }

#ifdef TT_CONGIG_OPTION_SUPPORT_NON_SQUARE_PIXELS
  static TT_F26Dot6  Read_CVT_Stretched( EXEC_OPS ULong  index )
  {
    return TT_MulFix( CUR.cvt[index], CURRENT_Ratio() );
  }
#endif


  static void  Write_CVT( EXEC_OPS ULong  index, TT_F26Dot6  value )
  {
    CUR.cvt[index] = value;
  }

#ifdef TT_CONGIG_OPTION_SUPPORT_NON_SQUARE_PIXELS
  static void  Write_CVT_Stretched( EXEC_OPS ULong  index, TT_F26Dot6  value )
  {
    CUR.cvt[index] = TT_MulDiv( value, 0x10000, CURRENT_Ratio() );
  }
#endif

  static void  Move_CVT( EXEC_OPS ULong  index, TT_F26Dot6  value )
  {
    CUR.cvt[index] += value;
  }

#ifdef TT_CONGIG_OPTION_SUPPORT_NON_SQUARE_PIXELS
  static void  Move_CVT_Stretched( EXEC_OPS ULong  index, TT_F26Dot6  value )
  {
    CUR.cvt[index] += TT_MulDiv( value, 0x10000, CURRENT_Ratio() );
  }
#endif

/******************************************************************
 *
 *  Function    :  Calc_Length
 *
 *  Description :  Computes the length in bytes of current opcode.
 *
 *****************************************************************/

  static Bool  Calc_Length( EXEC_OP )
  {
    CUR.opcode = CUR.code[CUR.IP];

    switch ( CUR.opcode )
    {
    case 0x40:
      if ( CUR.IP + 1 >= CUR.codeSize )
        return FAILURE;

      CUR.length = CUR.code[CUR.IP + 1] + 2;
      break;

    case 0x41:
      if ( CUR.IP + 1 >= CUR.codeSize )
        return FAILURE;

      CUR.length = CUR.code[CUR.IP + 1] * 2 + 2;
      break;

    case 0xB0:
    case 0xB1:
    case 0xB2:
    case 0xB3:
    case 0xB4:
    case 0xB5:
    case 0xB6:
    case 0xB7:
      CUR.length = CUR.opcode - 0xB0 + 2;
      break;

    case 0xB8:
    case 0xB9:
    case 0xBA:
    case 0xBB:
    case 0xBC:
    case 0xBD:
    case 0xBE:
    case 0xBF:
      CUR.length = (CUR.opcode - 0xB8) * 2 + 3;
      break;

    default:
      CUR.length = 1;
      break;
    }

    /* make sure result is in range */

    if ( CUR.IP + CUR.length > CUR.codeSize )
      return FAILURE;

    return SUCCESS;
  }


/*******************************************************************
 *
 *  Function    :  GetShortIns
 *
 *  Description :  Returns a short integer taken from the instruction
 *                 stream at address IP.
 *
 *  Input  :  None
 *
 *  Output :  Short read at Code^[IP..IP+1]
 *
 *  Notes  :  This one could become a Macro in the C version.
 *
 *****************************************************************/

  static Short  GetShortIns( EXEC_OP )
  {
    /* Reading a byte stream so there is no endianess (DaveP) */
    CUR.IP += 2;
    return (Short)((CUR.code[CUR.IP - 2] << 8) + CUR.code[CUR.IP - 1]);
  }


/*******************************************************************
 *
 *  Function    :  Ins_Goto_CodeRange
 *
 *  Description :  Goes to a certain code range in the instruction
 *                 stream.
 *
 *
 *  Input  :  aRange
 *            aIP
 *
 *  Output :  SUCCESS or FAILURE.
 *
 *****************************************************************/

  static Bool  Ins_Goto_CodeRange( EXEC_OPS Int  aRange, ULong  aIP )
  {
    TCodeRange*  WITH;


    if ( aRange < 1 || aRange > 3 )
    {
      CUR.error = TT_Err_Bad_Argument;
      return FAILURE;
    }

    WITH = &CUR.codeRangeTable[aRange - 1];

    if ( WITH->Base == NULL )     /* invalid coderange */
    {
      CUR.error = TT_Err_Invalid_CodeRange;
      return FAILURE;
    }

    /* NOTE: Because the last instruction of a program may be a CALL */
    /*       which will return to the first byte *after* the code    */
    /*       range, we test for aIP <= Size, instead of aIP < Size.  */

    if ( aIP > WITH->Size )
    {
      CUR.error = TT_Err_Code_Overflow;
      return FAILURE;
    }

    CUR.code     = WITH->Base;
    CUR.codeSize = WITH->Size;
    CUR.IP       = aIP;
    CUR.curRange = aRange;

    return SUCCESS;
  }


/*******************************************************************
 *
 *  Function    :  Direct_Move
 *
 *  Description :  Moves a point by a given distance along the
 *                 freedom vector.  The point will be touched.
 *
 *  Input  : point       index of point to move
 *           distance    distance to apply
 *           zone        affected glyph zone
 *
 *  Output :  None
 *
 *****************************************************************/

  static void  Direct_Move( EXEC_OPS PGlyph_Zone zone,
                                     UShort      point,
                                     TT_F26Dot6  distance )
  {
    TT_F26Dot6 v;


    v = CUR.GS.freeVector.x;

    if ( v != 0 )
    {
      zone->cur[point].x += TT_MulDiv( distance,
                                       v * 0x10000L,
                                       CUR.F_dot_P );

      zone->touch[point] |= TT_Flag_Touched_X;
    }

    v = CUR.GS.freeVector.y;

    if ( v != 0 )
    {
      zone->cur[point].y += TT_MulDiv( distance,
                                       v * 0x10000L,
                                       CUR.F_dot_P );

      zone->touch[point] |= TT_Flag_Touched_Y;
    }
  }


/******************************************************************/
/*                                                                */
/* The following versions are used whenever both vectors are both */
/* along one of the coordinate unit vectors, i.e. in 90% cases.   */
/*                                                                */
/******************************************************************/

/*******************************************************************
 * Direct_Move_X
 *
 *******************************************************************/

  static void  Direct_Move_X( EXEC_OPS PGlyph_Zone  zone,
                                       UShort       point,
                                       TT_F26Dot6   distance )
  {
    zone->cur[point].x += distance;
    zone->touch[point] |= TT_Flag_Touched_X;
  }


/*******************************************************************
 * Direct_Move_Y
 *
 *******************************************************************/

  static void  Direct_Move_Y( EXEC_OPS PGlyph_Zone  zone,
                                       UShort       point,
                                       TT_F26Dot6   distance )
  {
    zone->cur[point].y += distance;
    zone->touch[point] |= TT_Flag_Touched_Y;
  }


/*******************************************************************
 *
 *  Function    :  Round_None
 *
 *  Description :  Does not round, but adds engine compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  rounded distance.
 *
 *  NOTE : The spec says very few about the relationship between
 *         rounding and engine compensation.  However, it seems
 *         from the description of super round that we should
 *         should add the compensation before rounding.
 *
 ******************************************************************/

  static TT_F26Dot6  Round_None( EXEC_OPS TT_F26Dot6  distance,
                                          TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = distance + compensation;
      if ( val < 0 )
        val = 0;
    }
    else {
      val = distance - compensation;
      if ( val > 0 )
        val = 0;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_To_Grid
 *
 *  Description :  Rounds value to grid after adding engine
 *                 compensation
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_To_Grid( EXEC_OPS TT_F26Dot6  distance,
                                             TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = distance + compensation + 32;
      if ( val > 0 )
        val &= ~63;
      else
        val = 0;
    }
    else
    {
      val = -( (compensation - distance + 32) & (-64) );
      if ( val > 0 )
        val = 0;
    }

    return  val;
  }


/*******************************************************************
 *
 *  Function    :  Round_To_Half_Grid
 *
 *  Description :  Rounds value to half grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_To_Half_Grid( EXEC_OPS TT_F26Dot6  distance,
                                                  TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = ((distance + compensation) & (-64)) + 32;
      if ( val < 0 )
        val = 0;
    }
    else
    {
      val = -( ((compensation - distance) & (-64)) + 32 );
      if ( val > 0 )
        val = 0;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_Down_To_Grid
 *
 *  Description :  Rounds value down to grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_Down_To_Grid( EXEC_OPS TT_F26Dot6  distance,
                                                  TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = distance + compensation;
      if ( val > 0 )
        val &= ~63;
      else
        val = 0;
    }
    else
    {
      val = -( (compensation - distance) & (-64) );
      if ( val > 0 )
        val = 0;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_Up_To_Grid
 *
 *  Description :  Rounds value up to grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_Up_To_Grid( EXEC_OPS TT_F26Dot6  distance,
                                                TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = distance + compensation + 63;
      if ( val > 0 )
        val &= ~63;
      else
        val = 0;
    }
    else
    {
      val = -( (compensation - distance + 63) & (-64) );
      if ( val > 0 )
        val = 0;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_To_Double_Grid
 *
 *  Description :  Rounds value to double grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_To_Double_Grid( EXEC_OPS TT_F26Dot6  distance,
                                                    TT_F26Dot6  compensation )
  {
    TT_F26Dot6 val;


    if ( distance >= 0 )
    {
      val = distance + compensation + 16;
      if ( val > 0 )
        val &= ~31;
      else
        val = 0;
    }
    else
    {
      val = -( (compensation - distance + 16) & (-32) );
      if ( val > 0 )
        val = 0;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_Super
 *
 *  Description :  Super-rounds value to grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *  NOTE : The spec says very few about the relationship between
 *         rounding and engine compensation.  However, it seems
 *         from the description of super round that we should
 *         should add the compensation before rounding.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_Super( EXEC_OPS TT_F26Dot6  distance,
                                           TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = (distance - CUR.phase + CUR.threshold + compensation) &
              (-CUR.period);
      if ( val < 0 )
        val = 0;
      val += CUR.phase;
    }
    else
    {
      val = -( (CUR.threshold - CUR.phase - distance + compensation) &
               (-CUR.period) );
      if ( val > 0 )
        val = 0;
      val -= CUR.phase;
    }

    return val;
  }


/*******************************************************************
 *
 *  Function    :  Round_Super_45
 *
 *  Description :  Super-rounds value to grid after adding engine
 *                 compensation.
 *
 *  Input  :  distance      : distance to round
 *            compensation  : engine compensation
 *
 *  Output :  Rounded distance.
 *
 *  NOTE : There is a separate function for Round_Super_45 as we
 *         may need a greater precision.
 *
 *****************************************************************/

  static TT_F26Dot6  Round_Super_45( EXEC_OPS TT_F26Dot6  distance,
                                              TT_F26Dot6  compensation )
  {
    TT_F26Dot6  val;


    if ( distance >= 0 )
    {
      val = ( (distance - CUR.phase + CUR.threshold + compensation) /
                CUR.period ) * CUR.period;
      if ( val < 0 )
        val = 0;
      val += CUR.phase;
    }
    else
    {
      val = -( ( (CUR.threshold - CUR.phase - distance + compensation) /
                   CUR.period ) * CUR.period );
      if ( val > 0 )
        val = 0;
      val -= CUR.phase;
    }

    return val;
  }


/*******************************************************************
 * Compute_Round
 *
 *****************************************************************/

  static void  Compute_Round( EXEC_OPS Byte  round_mode )
  {
    switch ( round_mode )
    {
    case TT_Round_Off:
      CUR.func_round = (TRound_Function)Round_None;
      break;

    case TT_Round_To_Grid:
      CUR.func_round = (TRound_Function)Round_To_Grid;
      break;

    case TT_Round_Up_To_Grid:
      CUR.func_round = (TRound_Function)Round_Up_To_Grid;
      break;

    case TT_Round_Down_To_Grid:
      CUR.func_round = (TRound_Function)Round_Down_To_Grid;
      break;

    case TT_Round_To_Half_Grid:
      CUR.func_round = (TRound_Function)Round_To_Half_Grid;
      break;

    case TT_Round_To_Double_Grid:
      CUR.func_round = (TRound_Function)Round_To_Double_Grid;
      break;

    case TT_Round_Super:
      CUR.func_round = (TRound_Function)Round_Super;
      break;

    case TT_Round_Super_45:
      CUR.func_round = (TRound_Function)Round_Super_45;
      break;
    }
  }


/*******************************************************************
 *
 *  Function    :  SetSuperRound
 *
 *  Description :  Sets Super Round parameters.
 *
 *  Input  :  GridPeriod   Grid period
 *            selector     SROUND opcode
 *
 *  Output :  None.
 *
 *****************************************************************/

  static void  SetSuperRound( EXEC_OPS TT_F26Dot6  GridPeriod,
                                       Long        selector )
  {
    switch ( (Int)(selector & 0xC0) )
    {
      case 0:
        CUR.period = GridPeriod / 2;
        break;

      case 0x40:
        CUR.period = GridPeriod;
        break;

      case 0x80:
        CUR.period = GridPeriod * 2;
        break;

      /* This opcode is reserved, but... */

      case 0xC0:
        CUR.period = GridPeriod;
        break;
    }

    switch ( (Int)(selector & 0x30) )
    {
    case 0:
      CUR.phase = 0;
      break;

    case 0x10:
      CUR.phase = CUR.period / 4;
      break;

    case 0x20:
      CUR.phase = CUR.period / 2;
      break;

    case 0x30:
      CUR.phase = GridPeriod * 3 / 4;
      break;
    }

    if ( (selector & 0x0F) == 0 )
      CUR.threshold = CUR.period - 1;
    else
      CUR.threshold = ( (Int)(selector & 0x0F) - 4 ) * CUR.period / 8;

    CUR.period    /= 256;
    CUR.phase     /= 256;
    CUR.threshold /= 256;
  }


/*******************************************************************
 *
 *  Function    :  Project
 *
 *  Description :  Computes the projection of vector given by (v2-v1)
 *                 along the current projection vector.
 *
 *  Input  :  v1, v2    input vector
 *
 *  Output :  Returns distance in F26dot6 format.
 *
 *****************************************************************/

  static TT_F26Dot6  Project( EXEC_OPS TT_Vector*  v1,
                                       TT_Vector*  v2 )
  {
    TT_Int64  T1, T2;


    MUL_64( v1->x - v2->x, CUR.GS.projVector.x, T1 );
    MUL_64( v1->y - v2->y, CUR.GS.projVector.y, T2 );

    ADD_64( T1, T2, T1 );

    return (TT_F26Dot6)DIV_64( T1, 0x4000L );
  }


/*******************************************************************
 *
 *  Function    :  Dual_Project
 *
 *  Description :  Computes the projection of the vector given by
 *                 (v2-v1) along the current dual vector.
 *
 *  Input  :  v1, v2    input vector
 *
 *  Output :  Returns distance in F26dot6 format.
 *
 *****************************************************************/

  static TT_F26Dot6  Dual_Project( EXEC_OPS TT_Vector*  v1,
                                            TT_Vector*  v2 )
  {
    TT_Int64  T1, T2;


    MUL_64( v1->x - v2->x, CUR.GS.dualVector.x, T1 );
    MUL_64( v1->y - v2->y, CUR.GS.dualVector.y, T2 );

    ADD_64( T1, T2, T1 );

    return (TT_F26Dot6)DIV_64( T1, 0x4000L );
  }


/*******************************************************************
 *
 *  Function    :  Free_Project
 *
 *  Description :  Computes the projection of the vector given by
 *                 (v2-v1) along the current freedom vector.
 *
 *  Input  :  v1, v2    input vector
 *
 *  Output :  Returns distance in F26dot6 format.
 *
 *****************************************************************/

  static TT_F26Dot6  Free_Project( EXEC_OPS TT_Vector*  v1,
                                            TT_Vector*  v2 )
  {
    TT_Int64  T1, T2;


    MUL_64( v1->x - v2->x, CUR.GS.freeVector.x, T1 );
    MUL_64( v1->y - v2->y, CUR.GS.freeVector.y, T2 );

    ADD_64( T1, T2, T1 );

    return (TT_F26Dot6)DIV_64( T1, 0x4000L );
  }


/*******************************************************************
 *
 *  Function    :  Project_x
 *
 *  Input  :  Vx, Vy    input vector
 *
 *  Output :  Returns Vx.
 *
 *  Note :    Used as a dummy function.
 *
 *****************************************************************/

  static TT_F26Dot6  Project_x( EXEC_OPS TT_Vector*  v1,
                                         TT_Vector*  v2 )
  {
    return (v1->x - v2->x);
  }


/*******************************************************************
 *
 *  Function    :  Project_y
 *
 *  Input  :  Vx, Vy    input vector
 *
 *  Output :  Returns Vy.
 *
 *  Note :    Used as a dummy function.
 *
 *****************************************************************/

  static TT_F26Dot6  Project_y( EXEC_OPS TT_Vector*  v1,
                                         TT_Vector*  v2 )
  {
    return (v1->y - v2->y);
  }


/*******************************************************************
 *
 *  Function    :  Compute_Funcs
 *
 *  Description :  Computes the projections and movement function
 *                 pointers according to the current graphics state.
 *
 *  Input  :  None
 *
 *****************************************************************/

  static void  Compute_Funcs( EXEC_OP )
  {
    if ( CUR.GS.freeVector.x == 0x4000 )
    {
      CUR.func_freeProj = (TProject_Function)Project_x;
      CUR.F_dot_P       = CUR.GS.projVector.x * 0x10000L;
    }
    else
    {
      if ( CUR.GS.freeVector.y == 0x4000 )
      {
        CUR.func_freeProj = (TProject_Function)Project_y;
        CUR.F_dot_P       = CUR.GS.projVector.y * 0x10000L;
      }
      else
      {
        CUR.func_freeProj = (TProject_Function)Free_Project;
        CUR.F_dot_P = (Long)CUR.GS.projVector.x * CUR.GS.freeVector.x * 4 +
                      (Long)CUR.GS.projVector.y * CUR.GS.freeVector.y * 4;
      }
    }

    CUR.cached_metrics = FALSE;

    if ( CUR.GS.projVector.x == 0x4000 )
      CUR.func_project = (TProject_Function)Project_x;
    else
    {
      if ( CUR.GS.projVector.y == 0x4000 )
        CUR.func_project = (TProject_Function)Project_y;
      else
        CUR.func_project = (TProject_Function)Project;
    }

    if ( CUR.GS.dualVector.x == 0x4000 )
      CUR.func_dualproj = (TProject_Function)Project_x;
    else
    {
      if ( CUR.GS.dualVector.y == 0x4000 )
        CUR.func_dualproj = (TProject_Function)Project_y;
      else
        CUR.func_dualproj = (TProject_Function)Dual_Project;
    }

    CUR.func_move = (TMove_Function)Direct_Move;

    if ( CUR.F_dot_P == 0x40000000L )
    {
      if ( CUR.GS.freeVector.x == 0x4000 )
        CUR.func_move = (TMove_Function)Direct_Move_X;
      else
      {
        if ( CUR.GS.freeVector.y == 0x4000 )
          CUR.func_move = (TMove_Function)Direct_Move_Y;
      }
    }

    /* at small sizes, F_dot_P can become too small, resulting   */
    /* in overflows and 'spikes' in a number of glyphs like 'w'. */

    if ( ABS( CUR.F_dot_P ) < 0x4000000L )
      CUR.F_dot_P = 0x40000000L;

    /* Disable cached aspect ratio */
    CUR.metrics.ratio = 0;
  }


/*******************************************************************
 *
 *  Function    :  Normalize
 *
 *  Description :  Norms a vector
 *
 *  Input  :  Vx, Vy    input vector
 *            R         normed unit vector
 *
 *  Output :  Returns FAILURE if a vector parameter is zero.
 *
 *****************************************************************/

  static Bool  Normalize( EXEC_OPS TT_F26Dot6      Vx,
                                   TT_F26Dot6      Vy,
                                   TT_UnitVector*  R )
  {
    TT_F26Dot6  W;
    Bool        S1, S2;


    if ( ABS( Vx ) < 0x10000L && ABS( Vy ) < 0x10000L )
    {
      Vx *= 0x100;
      Vy *= 0x100;

      W = Norm( Vx, Vy );

      if ( W == 0 )
      {
        /* XXX : UNDOCUMENTED! It seems that it's possible to try  */
        /*       to normalize the vector (0,0). Return immediately */
        return SUCCESS;
      }

      R->x = (TT_F2Dot14)TT_MulDiv( Vx, 0x4000L, W );
      R->y = (TT_F2Dot14)TT_MulDiv( Vy, 0x4000L, W );

      return SUCCESS;
    }

    W = Norm( Vx, Vy );

    Vx = TT_MulDiv( Vx, 0x4000L, W );
    Vy = TT_MulDiv( Vy, 0x4000L, W );

    W = Vx * Vx + Vy * Vy;

    /* Now, we want that Sqrt( W ) = 0x4000 */
    /* Or 0x1000000 <= W < 0x1004000        */

    if ( Vx < 0 )
    {
      Vx = -Vx;
      S1 = TRUE;
    }
    else
      S1 = FALSE;

    if ( Vy < 0 )
    {
      Vy = -Vy;
      S2 = TRUE;
    }
    else
      S2 = FALSE;

    while ( W < 0x1000000L )
    {
      /* We need to increase W, by a minimal amount */
      if ( Vx < Vy )
        Vx++;
      else
        Vy++;

      W = Vx * Vx + Vy * Vy;
    }

    while ( W >= 0x1004000L )
    {
      /* We need to decrease W, by a minimal amount */
      if ( Vx < Vy )
        Vx--;
      else
        Vy--;

      W = Vx * Vx + Vy * Vy;
    }

    /* Note that in various cases, we can only  */
    /* compute a Sqrt(W) of 0x3FFF, eg. Vx = Vy */

    if ( S1 )
      Vx = -Vx;

    if ( S2 )
      Vy = -Vy;

    R->x = (TT_F2Dot14)Vx;   /* Type conversion */
    R->y = (TT_F2Dot14)Vy;   /* Type conversion */

    return SUCCESS;
  }


/****************************************************************
 *
 *  Opcodes
 *
 ****************************************************************/


  static Bool  Ins_SxVTL( EXEC_OPS  UShort          aIdx1,
                                    UShort          aIdx2,
                                    Int             aOpc,
                                    TT_UnitVector*  Vec )
  {
    Long       A, B, C;
    TT_Vector* p1;
    TT_Vector* p2;


    if ( BOUNDS( aIdx1, CUR.zp2.n_points ) ||
         BOUNDS( aIdx2, CUR.zp1.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return FAILURE;
    }

    p1 = CUR.zp1.cur + aIdx2;
    p2 = CUR.zp2.cur + aIdx1;

    A = p1->x - p2->x;
    B = p1->y - p2->y;

    if ( (aOpc & 1) != 0 )
    {
      C =  B;   /* CounterClockwise rotation */
      B =  A;
      A = -C;
    }

    NORMalize( A, B, Vec );
    return SUCCESS;
  }


/* When not using the big switch statements, the interpreter uses a */
/* call table defined later below in this source.  Each opcode must */
/* thus have a corresponding function, even trivial ones.           */
/*                                                                  */
/* They're all defined there.                                       */

#define DO_SVTCA                       \
  {                                    \
    Short  A, B;                       \
                                       \
                                       \
    A = (Short)(CUR.opcode & 1) << 14; \
    B = A ^ (Short)0x4000;             \
                                       \
    CUR.GS.freeVector.x = A;           \
    CUR.GS.projVector.x = A;           \
    CUR.GS.dualVector.x = A;           \
                                       \
    CUR.GS.freeVector.y = B;           \
    CUR.GS.projVector.y = B;           \
    CUR.GS.dualVector.y = B;           \
                                       \
    COMPUTE_Funcs();                   \
  }


#define DO_SPVTCA                      \
  {                                    \
    Short  A, B;                       \
                                       \
                                       \
    A = (Short)(CUR.opcode & 1) << 14; \
    B = A ^ (Short)0x4000;             \
                                       \
    CUR.GS.projVector.x = A;           \
    CUR.GS.dualVector.x = A;           \
                                       \
    CUR.GS.projVector.y = B;           \
    CUR.GS.dualVector.y = B;           \
                                       \
    COMPUTE_Funcs();                   \
  }


#define DO_SFVTCA                      \
  {                                    \
    Short  A, B;                       \
                                       \
                                       \
    A = (Short)(CUR.opcode & 1) << 14; \
    B = A ^ (Short)0x4000;             \
                                       \
    CUR.GS.freeVector.x = A;           \
    CUR.GS.freeVector.y = B;           \
                                       \
    COMPUTE_Funcs();                   \
  }


#define DO_SPVTL                                     \
    if ( INS_SxVTL( (UShort)args[1],                 \
                    (UShort)args[0],                 \
                    CUR.opcode,                      \
                    &CUR.GS.projVector) == SUCCESS ) \
    {                                                \
      CUR.GS.dualVector = CUR.GS.projVector;         \
      COMPUTE_Funcs();                               \
    }


#define DO_SFVTL                                     \
    if ( INS_SxVTL( (UShort)args[1],                 \
                    (UShort)args[0],                 \
                    CUR.opcode,                      \
                    &CUR.GS.freeVector) == SUCCESS ) \
      COMPUTE_Funcs();


#define DO_SFVTPV                          \
    CUR.GS.freeVector = CUR.GS.projVector; \
    COMPUTE_Funcs();


#define DO_SPVFS                                \
  {                                             \
    Short  S;                                   \
    Long   X, Y;                                \
                                                \
                                                \
    /* Only use low 16bits, then sign extend */ \
    S = (Short)args[1];                         \
    Y = (Long)S;                                \
    S = (Short)args[0];                         \
    X = (Long)S;                                \
                                                \
    NORMalize( X, Y, &CUR.GS.projVector );      \
                                                \
    CUR.GS.dualVector = CUR.GS.projVector;      \
    COMPUTE_Funcs();                            \
  }


#define DO_SFVFS                                \
  {                                             \
    Short  S;                                   \
    Long   X, Y;                                \
                                                \
                                                \
    /* Only use low 16bits, then sign extend */ \
    S = (Short)args[1];                         \
    Y = (Long)S;                                \
    S = (Short)args[0];                         \
    X = S;                                      \
                                                \
    NORMalize( X, Y, &CUR.GS.freeVector );      \
    COMPUTE_Funcs();                            \
  }


#define DO_GPV                     \
    args[0] = CUR.GS.projVector.x; \
    args[1] = CUR.GS.projVector.y;


#define DO_GFV                     \
    args[0] = CUR.GS.freeVector.x; \
    args[1] = CUR.GS.freeVector.y;


#define DO_SRP0  \
    CUR.GS.rp0 = (UShort)args[0];


#define DO_SRP1  \
    CUR.GS.rp1 = (UShort)args[0];


#define DO_SRP2  \
    CUR.GS.rp2 = (UShort)args[0];


#define DO_RTHG                                           \
    CUR.GS.round_state = TT_Round_To_Half_Grid;           \
    CUR.func_round = (TRound_Function)Round_To_Half_Grid;


#define DO_RTG                                       \
    CUR.GS.round_state = TT_Round_To_Grid;           \
    CUR.func_round = (TRound_Function)Round_To_Grid;


#define DO_RTDG                                             \
    CUR.GS.round_state = TT_Round_To_Double_Grid;           \
    CUR.func_round = (TRound_Function)Round_To_Double_Grid;


#define DO_RUTG                                         \
    CUR.GS.round_state = TT_Round_Up_To_Grid;           \
    CUR.func_round = (TRound_Function)Round_Up_To_Grid;


#define DO_RDTG                                           \
    CUR.GS.round_state = TT_Round_Down_To_Grid;           \
    CUR.func_round = (TRound_Function)Round_Down_To_Grid;


#define DO_ROFF                                   \
    CUR.GS.round_state = TT_Round_Off;            \
    CUR.func_round = (TRound_Function)Round_None;


#define DO_SROUND                                  \
    SET_SuperRound( 0x4000L, args[0] );            \
    CUR.GS.round_state = TT_Round_Super;           \
    CUR.func_round = (TRound_Function)Round_Super;


#define DO_S45ROUND                                   \
    SET_SuperRound( 0x2D41L, args[0] );               \
    CUR.GS.round_state = TT_Round_Super_45;           \
    CUR.func_round = (TRound_Function)Round_Super_45;


#define DO_SLOOP                       \
    if ( args[0] < 0 )                 \
      CUR.error = TT_Err_Bad_Argument; \
    else                               \
      CUR.GS.loop = args[0];


#define DO_SMD  \
    CUR.GS.minimum_distance = (TT_F26Dot6)args[0];


#define DO_SCVTCI  \
    CUR.GS.control_value_cutin = (TT_F26Dot6)args[0];


#define DO_SSWCI  \
    CUR.GS.single_width_cutin = (TT_F26Dot6)args[0];


    /* XXX : UNDOCUMENTED! or bug in the Windows engine?  */
    /*                                                    */
    /* It seems that the value that is read here is       */
    /* expressed in 16.16 format, rather than in          */
    /* font units..                                       */
    /*                                                    */
#define DO_SSW  \
    CUR.GS.single_width_value = (TT_F26Dot6)(args[0] >> 10);


#define DO_FLIPON  \
    CUR.GS.auto_flip = TRUE;


#define DO_FLIPOFF  \
    CUR.GS.auto_flip = FALSE;


#define DO_SDB  \
    CUR.GS.delta_base = (Short)args[0];


#define DO_SDS  \
    CUR.GS.delta_shift = (Short)args[0];


#define DO_MD  /* nothing */


#define DO_MPPEM  \
    args[0] = CURRENT_Ppem();


#define DO_MPS  \
    args[0] = CUR.metrics.pointSize;


#define DO_DUP  \
    args[1] = args[0];


#define DO_CLEAR  \
    CUR.new_top = 0;


#define DO_SWAP        \
  {                    \
    Long  L;           \
                       \
    L       = args[0]; \
    args[0] = args[1]; \
    args[1] = L;       \
  }


#define DO_DEPTH  \
    args[0] = CUR.top;


#define DO_CINDEX                           \
  {                                         \
    Long  L;                                \
                                            \
                                            \
    L = args[0];                            \
                                            \
    if ( L <= 0 || L > CUR.args )           \
      CUR.error = TT_Err_Invalid_Reference; \
    else                                    \
      args[0] = CUR.stack[CUR.args - L];    \
  }


#define DO_JROT               \
    if ( args[1] != 0 )       \
    {                         \
      CUR.IP      += args[0]; \
      CUR.step_ins = FALSE;   \
    }


#define DO_JMPR             \
    CUR.IP      += args[0]; \
    CUR.step_ins = FALSE;


#define DO_JROF               \
    if ( args[1] == 0 )       \
    {                         \
      CUR.IP      += args[0]; \
      CUR.step_ins = FALSE;   \
    }


#define DO_LT  \
    args[0] = (args[0] < args[1]);


#define DO_LTEQ  \
    args[0] = (args[0] <= args[1]);


#define DO_GT  \
    args[0] = (args[0] > args[1]);


#define DO_GTEQ  \
    args[0] = (args[0] >= args[1]);


#define DO_EQ  \
    args[0] = (args[0] == args[1]);


#define DO_NEQ  \
    args[0] = (args[0] != args[1]);


#define DO_ODD  \
    args[0] = ( (CUR_Func_round( args[0], 0 ) & 127) == 64 );


#define DO_EVEN  \
    args[0] = ( (CUR_Func_round( args[0], 0 ) & 127) == 0 );


#define DO_AND  \
    args[0] = ( args[0] && args[1] );


#define DO_OR  \
    args[0] = ( args[0] || args[1] );


#define DO_NOT  \
    args[0] = !args[0];


#define DO_ADD  \
    args[0] += args[1];


#define DO_SUB  \
    args[0] -= args[1];


#define DO_DIV                                      \
    if ( args[1] == 0 )                             \
      CUR.error = TT_Err_Divide_By_Zero;            \
    else                                            \
      args[0] = TT_MulDiv( args[0], 64L, args[1] );


#define DO_MUL  \
    args[0] = TT_MulDiv( args[0], args[1], 64L );


#define DO_ABS  \
    args[0] = ABS( args[0] );


#define DO_NEG  \
    args[0] = -args[0];


#define DO_FLOOR  \
    args[0] &= -64;


#define DO_CEILING  \
    args[0] = (args[0] + 63) & (-64);


#define DO_RS                                                   \
   {                                                            \
     ULong  I = (ULong)args[0];                                 \
     if ( BOUNDS( I, CUR.storeSize ) )                          \
     {                                                          \
       if ( CUR.pedantic_hinting )                              \
       {                                                        \
         ARRAY_BOUND_ERROR;                                     \
       }                                                        \
       else                                                     \
         args[0] = 0;                                           \
     }                                                          \
     else                                                       \
       args[0] = CUR.storage[I];                                \
   }


#define DO_WS  \
   {                                                            \
     ULong  I = (ULong)args[0];                                 \
     if ( BOUNDS( I, CUR.storeSize ) )                          \
     {                                                          \
       if ( CUR.pedantic_hinting )                              \
       {                                                        \
         ARRAY_BOUND_ERROR;                                     \
       }                                                        \
     }                                                          \
     else                                                       \
       CUR.storage[I] = args[1];                                \
   }



#define DO_RCVT                              \
   {                                                            \
     ULong  I = (ULong)args[0];                                 \
     if ( BOUNDS( I, CUR.cvtSize ) )                            \
     {                                                          \
       if ( CUR.pedantic_hinting )                              \
       {                                                        \
         ARRAY_BOUND_ERROR;                                     \
       }                                                        \
       else                                                     \
         args[0] = 0;                                           \
     }                                                          \
     else                                                       \
       args[0] = CUR_Func_read_cvt(I);                          \
   }


#define DO_WCVTP                             \
   {                                                            \
     ULong  I = (ULong)args[0];                                 \
     if ( BOUNDS( I, CUR.cvtSize ) )                            \
     {                                                          \
       if ( CUR.pedantic_hinting )                              \
       {                                                        \
         ARRAY_BOUND_ERROR;                                     \
       }                                                        \
     }                                                          \
     else                                                       \
       CUR_Func_write_cvt( I, args[1] );                        \
   }


#define DO_WCVTF                                                   \
   {                                                               \
     ULong  I = (ULong)args[0];                                    \
     if ( BOUNDS( I, CUR.cvtSize ) )                               \
     {                                                             \
       if ( CUR.pedantic_hinting )                                 \
       {                                                           \
         ARRAY_BOUND_ERROR;                                        \
       }                                                           \
     }                                                             \
     else                                                          \
       CUR.cvt[I] = FUnits_To_Pixels( EXEC_ARGS (Short)args[1] );  \
   }


#define DO_DEBUG  \
    CUR.error = TT_Err_Debug_OpCode;


#define DO_ROUND                                                            \
    args[0] = CUR_Func_round( args[0],                                      \
                              CUR.metrics.compensations[CUR.opcode-0x68] );


#define DO_NROUND                                                         \
    args[0] = Round_None( EXEC_ARGS                                       \
                          args[0],                                        \
                          CUR.metrics.compensations[CUR.opcode - 0x6C] );


#define DO_MAX               \
    if ( args[1] > args[0] ) \
      args[0] = args[1];


#define DO_MIN               \
    if ( args[1] < args[0] ) \
      args[0] = args[1];


#ifndef TT_CONFIG_OPTION_INTERPRETER_SWITCH


#undef  ARRAY_BOUND_ERROR
#define ARRAY_BOUND_ERROR                    \
     {                                       \
       CUR.error = TT_Err_Invalid_Reference; \
       return;                               \
     }


/*******************************************/
/* SVTCA[a]  : Set F and P vectors to axis */
/* CodeRange : $00-$01                     */
/* Stack     : -->                         */

  static void  Ins_SVTCA( INS_ARG )
  {
    DO_SVTCA
  }


/*******************************************/
/* SPVTCA[a] : Set PVector to Axis         */
/* CodeRange : $02-$03                     */
/* Stack     : -->                         */

  static void  Ins_SPVTCA( INS_ARG )
  {
    DO_SPVTCA
  }


/*******************************************/
/* SFVTCA[a] : Set FVector to Axis         */
/* CodeRange : $04-$05                     */
/* Stack     : -->                         */

  static void  Ins_SFVTCA( INS_ARG )
  {
    DO_SFVTCA
  }

/*******************************************/
/* SPVTL[a]  : Set PVector to Line         */
/* CodeRange : $06-$07                     */
/* Stack     : uint32 uint32 -->           */

  static void  Ins_SPVTL( INS_ARG )
  {
    DO_SPVTL
  }


/*******************************************/
/* SFVTL[a]  : Set FVector to Line         */
/* CodeRange : $08-$09                     */
/* Stack     : uint32 uint32 -->           */

  static void  Ins_SFVTL( INS_ARG )
  {
    DO_SFVTL
  }


/*******************************************/
/* SFVTPV[]  : Set FVector to PVector      */
/* CodeRange : $0E                         */
/* Stack     : -->                         */

  static void  Ins_SFVTPV( INS_ARG )
  {
    DO_SFVTPV
  }


/*******************************************/
/* SPVFS[]   : Set PVector From Stack      */
/* CodeRange : $0A                         */
/* Stack     : f2.14 f2.14 -->             */

  static void  Ins_SPVFS( INS_ARG )
  {
    DO_SPVFS
  }


/*******************************************/
/* SFVFS[]   : Set FVector From Stack      */
/* CodeRange : $0B                         */
/* Stack     : f2.14 f2.14 -->             */

  static void  Ins_SFVFS( INS_ARG )
  {
    DO_SFVFS
  }


/*******************************************/
/* GPV[]     : Get Projection Vector       */
/* CodeRange : $0C                         */
/* Stack     : ef2.14 --> ef2.14           */

  static void  Ins_GPV( INS_ARG )
  {
    DO_GPV
  }


/*******************************************/
/* GFV[]     : Get Freedom Vector          */
/* CodeRange : $0D                         */
/* Stack     : ef2.14 --> ef2.14           */

  static void  Ins_GFV( INS_ARG )
  {
    DO_GFV
  }


/*******************************************/
/* SRP0[]    : Set Reference Point 0       */
/* CodeRange : $10                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SRP0( INS_ARG )
  {
    DO_SRP0
  }


/*******************************************/
/* SRP1[]    : Set Reference Point 1       */
/* CodeRange : $11                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SRP1( INS_ARG )
  {
    DO_SRP1
  }


/*******************************************/
/* SRP2[]    : Set Reference Point 2       */
/* CodeRange : $12                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SRP2( INS_ARG )
  {
    DO_SRP2
  }


/*******************************************/
/* RTHG[]    : Round To Half Grid          */
/* CodeRange : $19                         */
/* Stack     : -->                         */

  static void  Ins_RTHG( INS_ARG )
  {
    DO_RTHG
  }


/*******************************************/
/* RTG[]     : Round To Grid               */
/* CodeRange : $18                         */
/* Stack     : -->                         */

  static void  Ins_RTG( INS_ARG )
  {
    DO_RTG
  }


/*******************************************/
/* RTDG[]    : Round To Double Grid        */
/* CodeRange : $3D                         */
/* Stack     : -->                         */

  static void  Ins_RTDG( INS_ARG )
  {
    DO_RTDG
  }


/*******************************************/
/* RUTG[]    : Round Up To Grid            */
/* CodeRange : $7C                         */
/* Stack     : -->                         */

  static void  Ins_RUTG( INS_ARG )
  {
    DO_RUTG
  }


/*******************************************/
/* RDTG[]    : Round Down To Grid          */
/* CodeRange : $7D                         */
/* Stack     : -->                         */

  static void  Ins_RDTG( INS_ARG )
  {
    DO_RDTG
  }


/*******************************************/
/* ROFF[]    : Round OFF                   */
/* CodeRange : $7A                         */
/* Stack     : -->                         */

  static void  Ins_ROFF( INS_ARG )
  {
    DO_ROFF
  }


/*******************************************/
/* SROUND[]  : Super ROUND                 */
/* CodeRange : $76                         */
/* Stack     : Eint8 -->                   */

  static void  Ins_SROUND( INS_ARG )
  {
    DO_SROUND
  }


/*******************************************/
/* S45ROUND[]: Super ROUND 45 degrees      */
/* CodeRange : $77                         */
/* Stack     : uint32 -->                  */

  static void  Ins_S45ROUND( INS_ARG )
  {
    DO_S45ROUND
  }


/*******************************************/
/* SLOOP[]   : Set LOOP variable           */
/* CodeRange : $17                         */
/* Stack     : int32? -->                  */

  static void  Ins_SLOOP( INS_ARG )
  {
    DO_SLOOP
  }


/*******************************************/
/* SMD[]     : Set Minimum Distance        */
/* CodeRange : $1A                         */
/* Stack     : f26.6 -->                   */

  static void  Ins_SMD( INS_ARG )
  {
    DO_SMD
  }


/**********************************************/
/* SCVTCI[]  : Set Control Value Table Cut In */
/* CodeRange : $1D                            */
/* Stack     : f26.6 -->                      */

  static void  Ins_SCVTCI( INS_ARG )
  {
    DO_SCVTCI
  }


/**********************************************/
/* SSWCI[]   : Set Single Width Cut In        */
/* CodeRange : $1E                            */
/* Stack     : f26.6 -->                      */

  static void  Ins_SSWCI( INS_ARG )
  {
    DO_SSWCI
  }


/**********************************************/
/* SSW[]     : Set Single Width               */
/* CodeRange : $1F                            */
/* Stack     : int32? -->                     */

  static void  Ins_SSW( INS_ARG )
  {
    DO_SSW
  }


/**********************************************/
/* FLIPON[]  : Set Auto_flip to On            */
/* CodeRange : $4D                            */
/* Stack     : -->                            */

  static void  Ins_FLIPON( INS_ARG )
  {
    DO_FLIPON
  }


/**********************************************/
/* FLIPOFF[] : Set Auto_flip to Off           */
/* CodeRange : $4E                            */
/* Stack     : -->                            */

  static void  Ins_FLIPOFF( INS_ARG )
  {
    DO_FLIPOFF
  }


/**********************************************/
/* SANGW[]   : Set Angle Weight               */
/* CodeRange : $7E                            */
/* Stack     : uint32 -->                     */

  static void  Ins_SANGW( INS_ARG )
  {
    /* instruction not supported anymore */
  }


/**********************************************/
/* SDB[]     : Set Delta Base                 */
/* CodeRange : $5E                            */
/* Stack     : uint32 -->                     */

  static void  Ins_SDB( INS_ARG )
  {
    DO_SDB
  }


/**********************************************/
/* SDS[]     : Set Delta Shift                */
/* CodeRange : $5F                            */
/* Stack     : uint32 -->                     */

  static void  Ins_SDS( INS_ARG )
  {
    DO_SDS
  }


/**********************************************/
/* MPPEM[]   : Measure Pixel Per EM           */
/* CodeRange : $4B                            */
/* Stack     : --> Euint16                    */

  static void  Ins_MPPEM( INS_ARG )
  {
    DO_MPPEM
  }


/**********************************************/
/* MPS[]     : Measure PointSize              */
/* CodeRange : $4C                            */
/* Stack     : --> Euint16                    */

  static void  Ins_MPS( INS_ARG )
  {
    DO_MPS
  }

/*******************************************/
/* DUP[]     : Duplicate top stack element */
/* CodeRange : $20                         */
/* Stack     : StkElt --> StkElt StkElt    */

  static void  Ins_DUP( INS_ARG )
  {
    DO_DUP
  }


/*******************************************/
/* POP[]     : POPs the stack's top elt.   */
/* CodeRange : $21                         */
/* Stack     : StkElt -->                  */

  static void  Ins_POP( INS_ARG )
  {
    /* nothing to do */
  }


/*******************************************/
/* CLEAR[]   : Clear the entire stack      */
/* CodeRange : $22                         */
/* Stack     : StkElt... -->               */

  static void  Ins_CLEAR( INS_ARG )
  {
    DO_CLEAR
  }


/*******************************************/
/* SWAP[]    : Swap the top two elements   */
/* CodeRange : $23                         */
/* Stack     : 2 * StkElt --> 2 * StkElt   */

  static void  Ins_SWAP( INS_ARG )
  {
    DO_SWAP
  }


/*******************************************/
/* DEPTH[]   : return the stack depth      */
/* CodeRange : $24                         */
/* Stack     : --> uint32                  */

  static void  Ins_DEPTH( INS_ARG )
  {
    DO_DEPTH
  }


/*******************************************/
/* CINDEX[]  : copy indexed element        */
/* CodeRange : $25                         */
/* Stack     : int32 --> StkElt            */

  static void  Ins_CINDEX( INS_ARG )
  {
    DO_CINDEX
  }


/*******************************************/
/* EIF[]     : End IF                      */
/* CodeRange : $59                         */
/* Stack     : -->                         */

  static void  Ins_EIF( INS_ARG )
  {
    /* nothing to do */
  }


/*******************************************/
/* JROT[]    : Jump Relative On True       */
/* CodeRange : $78                         */
/* Stack     : StkElt int32 -->            */

  static void  Ins_JROT( INS_ARG )
  {
    DO_JROT
  }


/*******************************************/
/* JMPR[]    : JuMP Relative               */
/* CodeRange : $1C                         */
/* Stack     : int32 -->                   */

  static void  Ins_JMPR( INS_ARG )
  {
    DO_JMPR
  }


/*******************************************/
/* JROF[]    : Jump Relative On False      */
/* CodeRange : $79                         */
/* Stack     : StkElt int32 -->            */

  static void  Ins_JROF( INS_ARG )
  {
    DO_JROF
  }


/*******************************************/
/* LT[]      : Less Than                   */
/* CodeRange : $50                         */
/* Stack     : int32? int32? --> bool      */

  static void  Ins_LT( INS_ARG )
  {
    DO_LT
  }


/*******************************************/
/* LTEQ[]    : Less Than or EQual          */
/* CodeRange : $51                         */
/* Stack     : int32? int32? --> bool      */

  static void  Ins_LTEQ( INS_ARG )
  {
    DO_LTEQ
  }


/*******************************************/
/* GT[]      : Greater Than                */
/* CodeRange : $52                         */
/* Stack     : int32? int32? --> bool      */

  static void  Ins_GT( INS_ARG )
  {
    DO_GT
  }


/*******************************************/
/* GTEQ[]    : Greater Than or EQual       */
/* CodeRange : $53                         */
/* Stack     : int32? int32? --> bool      */

  static void  Ins_GTEQ( INS_ARG )
  {
    DO_GTEQ
  }


/*******************************************/
/* EQ[]      : EQual                       */
/* CodeRange : $54                         */
/* Stack     : StkElt StkElt --> bool      */

  static void  Ins_EQ( INS_ARG )
  {
    DO_EQ
  }


/*******************************************/
/* NEQ[]     : Not EQual                   */
/* CodeRange : $55                         */
/* Stack     : StkElt StkElt --> bool      */

  static void  Ins_NEQ( INS_ARG )
  {
    DO_NEQ
  }


/*******************************************/
/* ODD[]     : Odd                         */
/* CodeRange : $56                         */
/* Stack     : f26.6 --> bool              */

  static void  Ins_ODD( INS_ARG )
  {
    DO_ODD
  }


/*******************************************/
/* EVEN[]    : Even                        */
/* CodeRange : $57                         */
/* Stack     : f26.6 --> bool              */

  static void  Ins_EVEN( INS_ARG )
  {
    DO_EVEN
  }


/*******************************************/
/* AND[]     : logical AND                 */
/* CodeRange : $5A                         */
/* Stack     : uint32 uint32 --> uint32    */

  static void  Ins_AND( INS_ARG )
  {
    DO_AND
  }


/*******************************************/
/* OR[]      : logical OR                  */
/* CodeRange : $5B                         */
/* Stack     : uint32 uint32 --> uint32    */

  static void  Ins_OR( INS_ARG )
  {
    DO_OR
  }


/*******************************************/
/* NOT[]     : logical NOT                 */
/* CodeRange : $5C                         */
/* Stack     : StkElt --> uint32           */

  static void  Ins_NOT( INS_ARG )
  {
    DO_NOT
  }


/*******************************************/
/* ADD[]     : ADD                         */
/* CodeRange : $60                         */
/* Stack     : f26.6 f26.6 --> f26.6       */

  static void  Ins_ADD( INS_ARG )
  {
    DO_ADD
  }


/*******************************************/
/* SUB[]     : SUBstract                   */
/* CodeRange : $61                         */
/* Stack     : f26.6 f26.6 --> f26.6       */

  static void  Ins_SUB( INS_ARG )
  {
    DO_SUB
  }


/*******************************************/
/* DIV[]     : DIVide                      */
/* CodeRange : $62                         */
/* Stack     : f26.6 f26.6 --> f26.6       */

  static void  Ins_DIV( INS_ARG )
  {
    DO_DIV
  }


/*******************************************/
/* MUL[]     : MULtiply                    */
/* CodeRange : $63                         */
/* Stack     : f26.6 f26.6 --> f26.6       */

  static void  Ins_MUL( INS_ARG )
  {
    DO_MUL
  }


/*******************************************/
/* ABS[]     : ABSolute value              */
/* CodeRange : $64                         */
/* Stack     : f26.6 --> f26.6             */

  static void  Ins_ABS( INS_ARG )
  {
    DO_ABS
  }


/*******************************************/
/* NEG[]     : NEGate                      */
/* CodeRange : $65                         */
/* Stack     : f26.6 --> f26.6             */

  static void  Ins_NEG( INS_ARG )
  {
    DO_NEG
  }


/*******************************************/
/* FLOOR[]   : FLOOR                       */
/* CodeRange : $66                         */
/* Stack     : f26.6 --> f26.6             */

  static void  Ins_FLOOR( INS_ARG )
  {
    DO_FLOOR
  }


/*******************************************/
/* CEILING[] : CEILING                     */
/* CodeRange : $67                         */
/* f26.6 --> f26.6                         */

  static void  Ins_CEILING( INS_ARG )
  {
    DO_CEILING
  }

/*******************************************/
/* RS[]      : Read Store                  */
/* CodeRange : $43                         */
/* Stack     : uint32 --> uint32           */

  static void  Ins_RS( INS_ARG )
  {
    DO_RS
  }


/*******************************************/
/* WS[]      : Write Store                 */
/* CodeRange : $42                         */
/* Stack     : uint32 uint32 -->           */

  static void  Ins_WS( INS_ARG )
  {
    DO_WS
  }


/*******************************************/
/* WCVTP[]   : Write CVT in Pixel units    */
/* CodeRange : $44                         */
/* Stack     : f26.6 uint32 -->            */

  static void  Ins_WCVTP( INS_ARG )
  {
    DO_WCVTP
  }


/*******************************************/
/* WCVTF[]   : Write CVT in FUnits         */
/* CodeRange : $70                         */
/* Stack     : uint32 uint32 -->           */

  static void  Ins_WCVTF( INS_ARG )
  {
    DO_WCVTF
  }


/*******************************************/
/* RCVT[]    : Read CVT                    */
/* CodeRange : $45                         */
/* Stack     : uint32 --> f26.6            */

  static void  Ins_RCVT( INS_ARG )
  {
    DO_RCVT
  }


/********************************************/
/* AA[]        : Adjust Angle               */
/* CodeRange   : $7F                        */
/* Stack       : uint32 -->                 */

  static void  Ins_AA( INS_ARG )
  {
    /* Intentional - no longer supported */
  }


/********************************************/
/* DEBUG[]     : DEBUG. Unsupported         */
/* CodeRange   : $4F                        */
/* Stack       : uint32 -->                 */

/* NOTE : The original instruction pops a value from the stack */

  static void  Ins_DEBUG( INS_ARG )
  {
    DO_DEBUG
  }

/*******************************************/
/* ROUND[ab] : ROUND value                 */
/* CodeRange : $68-$6B                     */
/* Stack     : f26.6 --> f26.6             */

  static void  Ins_ROUND( INS_ARG )
  {
    DO_ROUND
  }

/*******************************************/
/* NROUND[ab]: No ROUNDing of value        */
/* CodeRange : $6C-$6F                     */
/* Stack     : f26.6 --> f26.6             */

  static void  Ins_NROUND( INS_ARG )
  {
    DO_NROUND
  }



/*******************************************/
/* MAX[]     : MAXimum                     */
/* CodeRange : $68                         */
/* Stack     : int32? int32? --> int32     */

  static void  Ins_MAX( INS_ARG )
  {
    DO_MAX
  }


/*******************************************/
/* MIN[]     : MINimum                     */
/* CodeRange : $69                         */
/* Stack     : int32? int32? --> int32     */

  static void  Ins_MIN( INS_ARG )
  {
    DO_MIN
  }


#endif  /* !TT_CONFIG_OPTION_INTERPRETER_SWITCH */


/* The following functions are called as is within the switch statement */

/*******************************************/
/* MINDEX[]  : move indexed element        */
/* CodeRange : $26                         */
/* Stack     : int32? --> StkElt           */

  static void  Ins_MINDEX( INS_ARG )
  {
    Long  L, K;


    L = args[0];

    if ( L <= 0 || L > CUR.args )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    K = CUR.stack[CUR.args - L];

    MEM_Move( (&CUR.stack[CUR.args - L    ]),
              (&CUR.stack[CUR.args - L + 1]),
              (L - 1) * sizeof ( Long ) );

    CUR.stack[CUR.args - 1] = K;
  }


/*******************************************/
/* ROLL[]    : roll top three elements     */
/* CodeRange : $8A                         */
/* Stack     : 3 * StkElt --> 3 * StkElt   */

  static void  Ins_ROLL( INS_ARG )
  {
    Long  A, B, C;


    A = args[2];
    B = args[1];
    C = args[0];

    args[2] = C;
    args[1] = A;
    args[0] = B;
  }



/****************************************************************/
/*                                                              */
/* MANAGING THE FLOW OF CONTROL                                 */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

  static Bool  SkipCode( EXEC_OP )
  {
    CUR.IP += CUR.length;

    if ( CUR.IP < CUR.codeSize )
      if ( CALC_Length() == SUCCESS )
        return SUCCESS;

    CUR.error = TT_Err_Code_Overflow;
    return FAILURE;
  }


/*******************************************/
/* IF[]      : IF test                     */
/* CodeRange : $58                         */
/* Stack     : StkElt -->                  */

  static void  Ins_IF( INS_ARG )
  {
    Int   nIfs;
    Bool  Out;


    if ( args[0] != 0 )
      return;

    nIfs = 1;
    Out = 0;

    do
    {
      if ( SKIP_Code() == FAILURE )
        return;

      switch ( CUR.opcode )
      {
      case 0x58:      /* IF */
        nIfs++;
        break;

      case 0x1b:      /* ELSE */
        Out = (nIfs == 1);
        break;

      case 0x59:      /* EIF */
        nIfs--;
        Out = (nIfs == 0);
        break;
      }
    } while ( Out == 0 );
  }


/*******************************************/
/* ELSE[]    : ELSE                        */
/* CodeRange : $1B                         */
/* Stack     : -->                         */

  static void  Ins_ELSE( INS_ARG )
  {
    Int  nIfs;


    nIfs = 1;

    do
    {
      if ( SKIP_Code() == FAILURE )
        return;

      switch ( CUR.opcode )
      {
      case 0x58:    /* IF */
        nIfs++;
        break;

      case 0x59:    /* EIF */
        nIfs--;
        break;
      }
    } while ( nIfs != 0 );
  }


/****************************************************************/
/*                                                              */
/* DEFINING AND USING FUNCTIONS AND INSTRUCTIONS                */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

  static PDefRecord  Locate_FDef( EXEC_OPS Int n, Bool new_def )
  {
    PDefRecord  def;
    UShort      hash;
    UShort      cnt;

    /* The function table is interpreted as a simple hash table     */
    /* with indexes computed modulo maxFDefs and the linear search  */
    /* of free cells in the case of a collision.                    */
    /* Except for some old Apple fonts, all functions in a TrueType */
    /* font fit into 0..maxFDefs - 1 range and the lookup is        */
    /* reduced to a single step.                                    */

    /* Minor optimization. */
    if ( !new_def && ( n < 0 || n > CUR.maxFunc ) )
      return NULL;

    for ( cnt = 0; cnt < CUR.maxFDefs; ++cnt )
    {
      hash = ( (UShort)n + cnt ) % CUR.maxFDefs;
      def  = &CUR.FDefs[ hash ];
      if ( !def->Active )
        return new_def ? def : NULL;
      if ( def->Opc == n )
        return def;
    }

    /* The table is full and the entry has not been found. */
    return NULL;
  }


/*******************************************/
/* FDEF[]    : Function DEFinition         */
/* CodeRange : $2C                         */
/* Stack     : uint32 -->                  */

  static void  Ins_FDEF( INS_ARG )
  {
    Int         n;
    PDefRecord  def;


    /* check that there is enough room */
    if ( CUR.numFDefs >= CUR.maxFDefs )
    {
      /* We could introduce a new error message, but we're too close */
      /* from the release to change all the 'po' files again..       */
      CUR.error = TT_Err_Too_Many_Ins;
      return;
    }

    n = (Int)args[0];
    if ( n < 0 || (ULong)n != args[0] )
    {
      /* Gotcha. Function index is uint32 according to the specs */
      /* but TDefRecord.Opc is defined as Int. We cannot store   */
      /* the definition of this function.                        */
      CUR.error = TT_Err_Bad_Argument;
      return;
    }

    def = Locate_FDef( EXEC_ARGS n, TRUE );
    if ( !def )
    {
      /* Oh, oh. Something is wrong. Locate_FDef should never fail here. */
      CUR.error = TT_Err_Too_Many_Ins;
      return;
    }

    /* Some font programs are broken enough to redefine functions! */
    if ( !def->Active )
      CUR.numFDefs++;

    def->Range  = CUR.curRange;
    def->Opc    = n;
    def->Start  = CUR.IP + 1;
    def->Active = TRUE;

    if ( n > CUR.maxFunc )
      CUR.maxFunc = n;

    /* Now skip the whole function definition. */
    /* We don't allow nested IDEFS & FDEFs.    */

    while ( SKIP_Code() == SUCCESS )
    {
      switch ( CUR.opcode )
      {
      case 0x89:    /* IDEF */
      case 0x2c:    /* FDEF */
        CUR.error = TT_Err_Nested_DEFS;
        return;
      case 0x2d:   /* ENDF */
        return;
      }
    }
  }


/*******************************************/
/* ENDF[]    : END Function definition     */
/* CodeRange : $2D                         */
/* Stack     : -->                         */

  static void  Ins_ENDF( INS_ARG )
  {
    PCallRecord  pRec;


    if ( CUR.callTop <= 0 )     /* We encountered an ENDF without a call */
    {
      CUR.error = TT_Err_ENDF_In_Exec_Stream;
      return;
    }

    CUR.callTop--;

    pRec = &CUR.callStack[CUR.callTop];

    pRec->Cur_Count--;

    CUR.step_ins = FALSE;

    if ( pRec->Cur_Count > 0 )
    {
      CUR.callTop++;
      CUR.IP = pRec->Cur_Restart;
    }
    else
      /* Loop through the current function */
      INS_Goto_CodeRange( pRec->Caller_Range,
                          pRec->Caller_IP );

    /* Exit the current call frame.                       */

    /* NOTE: When the last intruction of a program        */
    /*       is a CALL or LOOPCALL, the return address    */
    /*       is always out of the code range.  This is    */
    /*       a valid address, and it's why we do not test */
    /*       the result of Ins_Goto_CodeRange() here!     */
  }


/*******************************************/
/* CALL[]    : CALL function               */
/* CodeRange : $2B                         */
/* Stack     : uint32? -->                 */

  static void  Ins_CALL( INS_ARG )
  {
    Int          n;
    PDefRecord   def;
    PCallRecord  pCrec;


    n = (Int)args[0];
    def = Locate_FDef( EXEC_ARGS n, FALSE );
    if ( !def )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* check call stack */
    if ( CUR.callTop >= CUR.callSize )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    pCrec = CUR.callStack + CUR.callTop;

    pCrec->Caller_Range = CUR.curRange;
    pCrec->Caller_IP    = CUR.IP + 1;
    pCrec->Cur_Count    = 1;
    pCrec->Cur_Restart  = def->Start;

    CUR.callTop++;

    INS_Goto_CodeRange( def->Range,
                        def->Start );

    CUR.step_ins = FALSE;
  }


/*******************************************/
/* LOOPCALL[]: LOOP and CALL function      */
/* CodeRange : $2A                         */
/* Stack     : uint32? Eint16? -->         */

  static void  Ins_LOOPCALL( INS_ARG )
  {
    Int          n;
    Long         count;
    PDefRecord   def;
    PCallRecord  pTCR;


    n = (Int)args[1];
    def = Locate_FDef( EXEC_ARGS n, FALSE );
    if ( !def )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( CUR.callTop >= CUR.callSize )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    count = (Long)args[0];
    if ( count <= 0 )
      return;

    pTCR = &CUR.callStack[CUR.callTop];

    pTCR->Caller_Range = CUR.curRange;
    pTCR->Caller_IP    = CUR.IP + 1;
    pTCR->Cur_Count    = count;
    pTCR->Cur_Restart  = def->Start;

    CUR.callTop++;

    INS_Goto_CodeRange( def->Range,
                        def->Start );

    CUR.step_ins = FALSE;
  }


/*******************************************/
/* IDEF[]    : Instruction DEFinition      */
/* CodeRange : $89                         */
/* Stack     : Eint8 -->                   */

  static void Ins_IDEF( INS_ARG )
  {
    Byte        opcode;
    PDefRecord  def;
    PDefRecord  limit;


    opcode = (Byte)args[0];

    /* First of all, look for the same instruction in our table */
    def   = CUR.IDefs;
    limit = def + CUR.numIDefs;
    for ( ; def < limit; def++ )
      if ( def->Opc == opcode )
        break;
    
    if ( def == limit )
    {
      /* check that there is enough room for a new instruction */
      if ( CUR.numIDefs >= CUR.maxIDefs )
      {
        /* XXX Bad error code. See FDEF[]. */
        CUR.error = TT_Err_Too_Many_Ins;
        return;
      }
      CUR.numIDefs++;
    }

    def->Opc    = opcode;
    def->Start  = CUR.IP + 1;
    def->Range  = CUR.curRange;
    def->Active = TRUE;

    if ( opcode > CUR.maxIns )
      CUR.maxIns = opcode;

    /* Now skip the whole function definition */
    /* We don't allow nested IDEFs & FDEFs.   */

    while ( SKIP_Code() == SUCCESS )
    {
      switch ( CUR.opcode )
      {
      case 0x89:   /* IDEF */
      case 0x2c:   /* FDEF */
        CUR.error = TT_Err_Nested_DEFS;
        return;
      case 0x2d:   /* ENDF */
        return;
      }
    }
  }


/****************************************************************/
/*                                                              */
/* PUSHING DATA ONTO THE INTERPRETER STACK                      */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

/*******************************************/
/* NPUSHB[]  : PUSH N Bytes                */
/* CodeRange : $40                         */
/* Stack     : --> uint32...               */

  static void  Ins_NPUSHB( INS_ARG )
  {
    UShort  L, K;


    L = (UShort)CUR.code[CUR.IP + 1];

    if ( BOUNDS( L, CUR.stackSize + 1 - CUR.top ) )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    for ( K = 1; K <= L; K++ )
      args[K - 1] = CUR.code[CUR.IP + K + 1];

    CUR.new_top += L;
  }


/*******************************************/
/* NPUSHW[]  : PUSH N Words                */
/* CodeRange : $41                         */
/* Stack     : --> int32...                */

  static void  Ins_NPUSHW( INS_ARG )
  {
    UShort  L, K;


    L = (UShort)CUR.code[CUR.IP + 1];

    if ( BOUNDS( L, CUR.stackSize + 1 - CUR.top ) )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    CUR.IP += 2;

    for ( K = 0; K < L; K++ )
      args[K] = GET_ShortIns();

    CUR.step_ins = FALSE;
    CUR.new_top += L;
  }


/*******************************************/
/* PUSHB[abc]: PUSH Bytes                  */
/* CodeRange : $B0-$B7                     */
/* Stack     : --> uint32...               */

  static void  Ins_PUSHB( INS_ARG )
  {
    UShort  L, K;


    L = (UShort)CUR.opcode - 0xB0 + 1;

    if ( BOUNDS( L, CUR.stackSize + 1 - CUR.top ) )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    for ( K = 1; K <= L; K++ )
      args[K - 1] = CUR.code[CUR.IP + K];
  }


/*******************************************/
/* PUSHW[abc]: PUSH Words                  */
/* CodeRange : $B8-$BF                     */
/* Stack     : --> int32...                */

  static void  Ins_PUSHW( INS_ARG )
  {
    UShort  L, K;


    L = (UShort)CUR.opcode - 0xB8 + 1;

    if ( BOUNDS( L, CUR.stackSize + 1 - CUR.top ) )
    {
      CUR.error = TT_Err_Stack_Overflow;
      return;
    }

    CUR.IP++;

    for ( K = 0; K < L; K++ )
      args[K] = GET_ShortIns();

    CUR.step_ins = FALSE;
  }



/****************************************************************/
/*                                                              */
/* MANAGING THE GRAPHICS STATE                                  */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

/**********************************************/
/* GC[a]     : Get Coordinate projected onto  */
/* CodeRange : $46-$47                        */
/* Stack     : uint32 --> f26.6               */

/* BULLSHIT: Measures from the original glyph must be taken */
/*           along the dual projection vector!              */

  static void  Ins_GC( INS_ARG )
  {
    ULong       L;
    TT_F26Dot6  R;


    L = (ULong)args[0];

    if ( BOUNDS( L, CUR.zp2.n_points ) )
    {
      if ( CUR.pedantic_hinting )
      {
        CUR.error = TT_Err_Invalid_Reference;
        return;
      }
      else
        R = 0;
    }
    else
    {
      if ( CUR.opcode & 1 )
        R = CUR_Func_dualproj( CUR.zp2.org + L, NULL_Vector );
      else
        R = CUR_Func_project( CUR.zp2.cur + L, NULL_Vector );
    }

    args[0] = R;
  }


/**********************************************/
/* SCFS[]    : Set Coordinate From Stack      */
/* CodeRange : $48                            */
/* Stack     : f26.6 uint32 -->               */
/*                                            */
/* Formula:                                   */
/*                                            */
/*   OA := OA + ( value - OA.p )/( f.p ) * f  */
/*                                            */

  static void  Ins_SCFS( INS_ARG )
  {
    Long    K;
    UShort  L;


    L = (UShort)args[0];

    if ( BOUNDS( L, CUR.zp2.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    K = CUR_Func_project( CUR.zp2.cur + L, NULL_Vector );

    CUR_Func_move( &CUR.zp2, L, args[1] - K );

    /* not part of the specs, but here for safety */

    if ( CUR.GS.gep2 == 0 )
      CUR.zp2.org[L] = CUR.zp2.cur[L];
  }


/**********************************************/
/* MD[a]     : Measure Distance               */
/* CodeRange : $49-$4A                        */
/* Stack     : uint32 uint32 --> f26.6        */

/* BULLSHIT: Measure taken in the original glyph must be along */
/*           the dual projection vector.                       */

/* Second BULLSHIT: Flag attributes are inverted!                */
/*                  0 => measure distance in original outline    */
/*                  1 => measure distance in grid-fitted outline */

/* Third one !! : zp0 - zp1, and not "zp2 - zp1" !!!             */
/*                                                               */

  static void  Ins_MD( INS_ARG )
  {
    UShort      K, L;
    TT_F26Dot6  D;


    K = (UShort)args[1];
    L = (UShort)args[0];

    if( BOUNDS( L, CUR.zp0.n_points ) ||
        BOUNDS( K, CUR.zp1.n_points ) )
    {
      if ( CUR.pedantic_hinting )
      {
        CUR.error = TT_Err_Invalid_Reference;
        return;
      }
      else
        D = 0;
    }
    else
    {
      if ( CUR.opcode & 1 )
        D = CUR_Func_project( CUR.zp0.cur + L, CUR.zp1.cur + K );
      else
        D = CUR_Func_dualproj( CUR.zp0.org + L, CUR.zp1.org + K );
    }

    args[0] = D;
  }


/*******************************************/
/* SDPVTL[a] : Set Dual PVector to Line    */
/* CodeRange : $86-$87                     */
/* Stack     : uint32 uint32 -->           */

  static void  Ins_SDPVTL( INS_ARG )
  {
    Long    A, B, C;
    UShort  p1, p2;   /* was Int in pas type ERROR */


    p1 = (UShort)args[1];
    p2 = (UShort)args[0];

    if ( BOUNDS( p2, CUR.zp1.n_points ) ||
         BOUNDS( p1, CUR.zp2.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    {
      TT_Vector* v1 = CUR.zp1.org + p2;
      TT_Vector* v2 = CUR.zp2.org + p1;


      A = v1->x - v2->x;
      B = v1->y - v2->y;
    }

    if ( (CUR.opcode & 1) != 0 )
    {
      C =  B;   /* CounterClockwise rotation */
      B =  A;
      A = -C;
    }

    NORMalize( A, B, &CUR.GS.dualVector );

    {
      TT_Vector*  v1 = CUR.zp1.cur + p2;
      TT_Vector*  v2 = CUR.zp2.cur + p1;


      A = v1->x - v2->x;
      B = v1->y - v2->y;
    }

    if ( (CUR.opcode & 1) != 0 )
    {
      C =  B;   /* CounterClockwise rotation */
      B =  A;
      A = -C;
    }

    NORMalize( A, B, &CUR.GS.projVector );

    COMPUTE_Funcs();
  }


/*******************************************/
/* SZP0[]    : Set Zone Pointer 0          */
/* CodeRange : $13                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SZP0( INS_ARG )
  {
    switch ( (Int)args[0] )
    {
    case 0:
      CUR.zp0 = CUR.twilight;
      break;

    case 1:
      CUR.zp0 = CUR.pts;
      break;

    default:
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    CUR.GS.gep0 = (UShort)args[0];
  }


/*******************************************/
/* SZP1[]    : Set Zone Pointer 1          */
/* CodeRange : $14                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SZP1( INS_ARG )
  {
    switch ( (Int)args[0] )
    {
    case 0:
      CUR.zp1 = CUR.twilight;
      break;

    case 1:
      CUR.zp1 = CUR.pts;
      break;

    default:
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    CUR.GS.gep1 = (UShort)args[0];
  }


/*******************************************/
/* SZP2[]    : Set Zone Pointer 2          */
/* CodeRange : $15                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SZP2( INS_ARG )
  {
    switch ( (Int)args[0] )
    {
    case 0:
      CUR.zp2 = CUR.twilight;
      break;

    case 1:
      CUR.zp2 = CUR.pts;
      break;

    default:
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    CUR.GS.gep2 = (UShort)args[0];
  }


/*******************************************/
/* SZPS[]    : Set Zone Pointers           */
/* CodeRange : $16                         */
/* Stack     : uint32 -->                  */

  static void  Ins_SZPS( INS_ARG )
  {
    switch ( (Int)args[0] )
    {
    case 0:
      CUR.zp0 = CUR.twilight;
      break;

    case 1:
      CUR.zp0 = CUR.pts;
      break;

    default:
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    CUR.zp1 = CUR.zp0;
    CUR.zp2 = CUR.zp0;

    CUR.GS.gep0 = (UShort)args[0];
    CUR.GS.gep1 = (UShort)args[0];
    CUR.GS.gep2 = (UShort)args[0];
  }


/*******************************************/
/* INSTCTRL[]: INSTruction ConTRol         */
/* CodeRange : $8e                         */
/* Stack     : int32 int32 -->             */

  static void  Ins_INSTCTRL( INS_ARG )
  {
    Long  K, L;


    K = args[1];
    L = args[0];

    if ( K < 1 || K > 2 )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( L != 0 )
        L = K;

    CUR.GS.instruct_control = 
      (Byte)( CUR.GS.instruct_control & ~(Byte)K ) | (Byte)L;
  }


/*******************************************/
/* SCANCTRL[]: SCAN ConTRol                */
/* CodeRange : $85                         */
/* Stack     : uint32? -->                 */

  static void  Ins_SCANCTRL( INS_ARG )
  {
    Int  A;


    /* Get Threshold */
    A = (Int)(args[0] & 0xFF);

    if ( A == 0xFF )
    {
      CUR.GS.scan_control = TRUE;
      return;
    }
    else if ( A == 0 )
    {
      CUR.GS.scan_control = FALSE;
      return;
    }

    A *= 64;

    if ( (args[0] & 0x100) != 0 && CUR.metrics.pointSize <= A )
      CUR.GS.scan_control = TRUE;

    if ( (args[0] & 0x200) != 0 && FALSE ) //rotated
      CUR.GS.scan_control = TRUE;

    if ( (args[0] & 0x400) != 0 && FALSE ) //stetched
      CUR.GS.scan_control = TRUE;

    if ( (args[0] & 0x800) != 0 && CUR.metrics.pointSize > A )
      CUR.GS.scan_control = FALSE;

    if ( (args[0] & 0x1000) != 0 && FALSE ) //rotated
      CUR.GS.scan_control = FALSE;

    if ( (args[0] & 0x2000) != 0 && FALSE ) //stretched
      CUR.GS.scan_control = FALSE;
}


/*******************************************/
/* SCANTYPE[]: SCAN TYPE                   */
/* CodeRange : $8D                         */
/* Stack     : uint32? -->                 */

  static void  Ins_SCANTYPE( INS_ARG )
  {
    /* For compatibility with future enhancements, */
    /* we must ignore new modes                    */

    if ( args[0] >= 0 && args[0] <= 5 )
    {
      if ( args[0] == 3 )
        args[0] = 2;

      CUR.GS.scan_type = (Int)args[0];
    }
  }



/****************************************************************/
/*                                                              */
/* MANAGING OUTLINES                                            */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

/**********************************************/
/* FLIPPT[]  : FLIP PoinT                     */
/* CodeRange : $80                            */
/* Stack     : uint32... -->                  */

  static void  Ins_FLIPPT( INS_ARG )
  {
    UShort  point;


    if ( CUR.top < CUR.GS.loop )
    {
      CUR.error = TT_Err_Too_Few_Arguments;
      return;
    }

    while ( CUR.GS.loop > 0 )
    {
      CUR.args--;

      point = (UShort)CUR.stack[CUR.args];

      if ( BOUNDS( point, CUR.pts.n_points ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
        CUR.pts.touch[point] ^= TT_Flag_On_Curve;

      CUR.GS.loop--;
    }

    CUR.GS.loop = 1;
    CUR.new_top = CUR.args;
  }


/**********************************************/
/* FLIPRGON[]: FLIP RanGe ON                  */
/* CodeRange : $81                            */
/* Stack     : uint32 uint32 -->              */
/*             (but UShorts are sufficient)   */

  static void  Ins_FLIPRGON( INS_ARG )
  {
    UShort  I, K, L;


    K = (UShort)args[1];
    L = (UShort)args[0];

    if ( BOUNDS( K, CUR.pts.n_points ) ||
         BOUNDS( L, CUR.pts.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    for ( I = L; I <= K; I++ )
      CUR.pts.touch[I] |= TT_Flag_On_Curve;
  }


/**********************************************/
/* FLIPRGOFF : FLIP RanGe OFF                 */
/* CodeRange : $82                            */
/* Stack     : uint32 uint32 -->              */
/*             (but UShorts are sufficient)   */

  static void  Ins_FLIPRGOFF( INS_ARG )
  {
    UShort  I, K, L;


    K = (UShort)args[1];
    L = (UShort)args[0];

    if ( BOUNDS( K, CUR.pts.n_points ) ||
         BOUNDS( L, CUR.pts.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    for ( I = L; I <= K; I++ )
      CUR.pts.touch[I] &= ~TT_Flag_On_Curve;
  }


  static Bool  Compute_Point_Displacement( EXEC_OPS
                                           PCoordinates  x,
                                           PCoordinates  y,
                                           PGlyph_Zone   zone,
                                           UShort*       refp )
  {
    TGlyph_Zone  zp;
    UShort       p;
    TT_F26Dot6   d;


    if ( CUR.opcode & 1 )
    {
      zp = CUR.zp0;
      p  = CUR.GS.rp1;
    }
    else
    {
      zp = CUR.zp1;
      p  = CUR.GS.rp2;
    }

    if ( BOUNDS( p, zp.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Displacement;
      return FAILURE;
    }

    *zone = zp;
    *refp = p;

    d = CUR_Func_project( zp.cur + p, zp.org + p );

    *x = TT_MulDiv(d, (Long)CUR.GS.freeVector.x * 0x10000L, CUR.F_dot_P );
    *y = TT_MulDiv(d, (Long)CUR.GS.freeVector.y * 0x10000L, CUR.F_dot_P );

    return SUCCESS;
  }


  static void  Move_Zp2_Point( EXEC_OPS
                               UShort      point,
                               TT_F26Dot6  dx,
                               TT_F26Dot6  dy,
                               Bool        touch )
  {
    if ( CUR.GS.freeVector.x != 0 )
    {
      CUR.zp2.cur[point].x += dx;
      if ( touch )
        CUR.zp2.touch[point] |= TT_Flag_Touched_X;
    }

    if ( CUR.GS.freeVector.y != 0 )
    {
      CUR.zp2.cur[point].y += dy;
      if ( touch )
        CUR.zp2.touch[point] |= TT_Flag_Touched_Y;
    }
  }


/**********************************************/
/* SHP[a]    : SHift Point by the last point  */
/* CodeRange : $32-33                         */
/* Stack     : uint32... -->                  */

  static void  Ins_SHP( INS_ARG )
  {
    TGlyph_Zone zp;
    UShort      refp;

    TT_F26Dot6  dx,
                dy;
    UShort      point;


    if ( CUR.top < CUR.GS.loop )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( COMPUTE_Point_Displacement( &dx, &dy, &zp, &refp ) )
      return;

    while ( CUR.GS.loop > 0 )
    {
      CUR.args--;
      point = (UShort)CUR.stack[CUR.args];

      if ( BOUNDS( point, CUR.zp2.n_points ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
        /* UNDOCUMENTED! SHP touches the points */
        MOVE_Zp2_Point( point, dx, dy, TRUE );

      CUR.GS.loop--;
    }

    CUR.GS.loop = 1;
    CUR.new_top = CUR.args;
  }


/**********************************************/
/* SHC[a]    : SHift Contour                  */
/* CodeRange : $34-35                         */
/* Stack     : uint32 -->                     */

  static void  Ins_SHC( INS_ARG )
  {
    TGlyph_Zone zp;
    UShort      refp;
    TT_F26Dot6  dx,
                dy;

    Short       contour;
    UShort      first_point, last_point, i;


    contour = (UShort)args[0];

    if ( BOUNDS( contour, CUR.pts.n_contours ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( COMPUTE_Point_Displacement( &dx, &dy, &zp, &refp ) )
      return;

    if ( contour == 0 )
      first_point = 0;
    else
      first_point = CUR.pts.contours[contour - 1] + 1;

    last_point = CUR.pts.contours[contour];

    /* XXX: this is probably wrong... at least it prevents memory */
    /*      corruption when zp2 is the twilight zone              */
    if ( last_point > CUR.zp2.n_points )
    {
      if ( CUR.zp2.n_points > 0 )
        last_point = CUR.zp2.n_points - 1;
      else
        last_point = 0;
    }

    /* UNDOCUMENTED! SHC doesn't touch the points */
    for ( i = first_point; i <= last_point; i++ )
    {
      if ( zp.cur != CUR.zp2.cur || refp != i )
        MOVE_Zp2_Point( i, dx, dy, FALSE );
    }
  }


/**********************************************/
/* SHZ[a]    : SHift Zone                     */
/* CodeRange : $36-37                         */
/* Stack     : uint32 -->                     */

  static void  Ins_SHZ( INS_ARG )
  {
    TGlyph_Zone zp;
    UShort      refp;
    TT_F26Dot6  dx,
                dy;

    UShort  last_point, i;


    if ( BOUNDS( args[0], 2 ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( COMPUTE_Point_Displacement( &dx, &dy, &zp, &refp ) )
      return;

    if ( CUR.zp2.n_points > 0 )
      last_point = CUR.zp2.n_points - 1;
    else
      last_point = 0;

    /* UNDOCUMENTED! SHZ doesn't touch the points */
    for ( i = 0; i <= last_point; i++ )
    {
      if ( zp.cur != CUR.zp2.cur || refp != i )
        MOVE_Zp2_Point( i, dx, dy, FALSE );
    }
  }


/**********************************************/
/* SHPIX[]   : SHift points by a PIXel amount */
/* CodeRange : $38                            */
/* Stack     : f26.6 uint32... -->            */

  static void  Ins_SHPIX( INS_ARG )
  {
    TT_F26Dot6  dx, dy;
    UShort      point;


    if ( CUR.top < CUR.GS.loop + 1 )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    dx = TT_MulDiv( args[0],
                    (Long)CUR.GS.freeVector.x,
                    0x4000 );
    dy = TT_MulDiv( args[0],
                    (Long)CUR.GS.freeVector.y,
                    0x4000 );

    while ( CUR.GS.loop > 0 )
    {
      CUR.args--;

      point = (UShort)CUR.stack[CUR.args];

      if ( BOUNDS( point, CUR.zp2.n_points ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
        MOVE_Zp2_Point( point, dx, dy, TRUE );

      CUR.GS.loop--;
    }

    CUR.GS.loop = 1;
    CUR.new_top = CUR.args;
  }


/**********************************************/
/* MSIRP[a]  : Move Stack Indirect Relative   */
/* CodeRange : $3A-$3B                        */
/* Stack     : f26.6 uint32 -->               */

  static void  Ins_MSIRP( INS_ARG )
  {
    UShort      point;
    TT_F26Dot6  distance;


    point = (UShort)args[0];

    if ( BOUNDS( point,      CUR.zp1.n_points ) ||
         BOUNDS( CUR.GS.rp0, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* XXX: UNDOCUMENTED! behaviour */
    if ( CUR.GS.gep0 == 0 )   /* if in twilight zone */
    {
      CUR.zp1.org[point] = CUR.zp0.org[CUR.GS.rp0];
      CUR.zp1.cur[point] = CUR.zp1.org[point];
    }

    distance = CUR_Func_project( CUR.zp1.cur + point,
                                 CUR.zp0.cur + CUR.GS.rp0 );

    CUR_Func_move( &CUR.zp1, point, args[1] - distance );

    CUR.GS.rp1 = CUR.GS.rp0;
    CUR.GS.rp2 = point;

    if ( (CUR.opcode & 1) != 0 )
      CUR.GS.rp0 = point;
  }


/**********************************************/
/* MDAP[a]   : Move Direct Absolute Point     */
/* CodeRange : $2E-$2F                        */
/* Stack     : uint32 -->                     */

  static void  Ins_MDAP( INS_ARG )
  {
    UShort      point;
    TT_F26Dot6  cur_dist,
                distance;


    point = (UShort)args[0];

    if ( BOUNDS( point, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* XXX: Is there some undocumented feature while in the */
    /*      twilight zone? ?                                */
    if ( (CUR.opcode & 1) != 0 )
    {
      cur_dist = CUR_Func_project( CUR.zp0.cur + point, NULL_Vector );
      distance = CUR_Func_round( cur_dist,
                                 CUR.metrics.compensations[0] ) - cur_dist;
    }
    else
      distance = 0;

    CUR_Func_move( &CUR.zp0, point, distance );

    CUR.GS.rp0 = point;
    CUR.GS.rp1 = point;
  }


/**********************************************/
/* MIAP[a]   : Move Indirect Absolute Point   */
/* CodeRange : $3E-$3F                        */
/* Stack     : uint32 uint32 -->              */

  static void  Ins_MIAP( INS_ARG )
  {
    ULong       cvtEntry;
    UShort      point;
    TT_F26Dot6  distance,
                org_dist;


    cvtEntry = (ULong)args[1];
    point    = (UShort)args[0];

    if ( BOUNDS( point,    CUR.zp0.n_points ) ||
         BOUNDS( cvtEntry, CUR.cvtSize )      )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* UNDOCUMENTED!                                     */
    /*                                                   */
    /* The behaviour of an MIAP instruction is quite     */
    /* different when used in the twilight zone.         */
    /*                                                   */
    /* First, no control value cutin test is performed   */
    /* as it would fail anyway.  Second, the original    */
    /* point, i.e. (org_x,org_y) of zp0.point, is set    */
    /* to the absolute, unrounded distance found in      */
    /* the CVT.                                          */
    /*                                                   */
    /* This is used in the CVT programs of the Microsoft */
    /* fonts Arial, Times, etc., in order to re-adjust   */
    /* some key font heights.  It allows the use of the  */
    /* IP instruction in the twilight zone, which        */
    /* otherwise would be "illegal" according to the     */
    /* specs :)                                          */
    /*                                                   */
    /* We implement it with a special sequence for the   */
    /* twilight zone. This is a bad hack, but it seems   */
    /* to work.                                          */

    distance = CUR_Func_read_cvt( cvtEntry );

    if ( CUR.GS.gep0 == 0 )   /* If in twilight zone */
    {
      CUR.zp0.org[point].x = TT_MulDiv( CUR.GS.freeVector.x,
                                        distance, 0x4000L );
      CUR.zp0.org[point].y = TT_MulDiv( CUR.GS.freeVector.y,
                                        distance, 0x4000L );
      CUR.zp0.cur[point] = CUR.zp0.org[point];
    }

    org_dist = CUR_Func_project( CUR.zp0.cur + point, NULL_Vector );

    if ( (CUR.opcode & 1) != 0 )   /* rounding and control cutin flag */
    {
      if ( ABS( distance - org_dist ) > CUR.GS.control_value_cutin )
        distance = org_dist;

      distance = CUR_Func_round( distance, CUR.metrics.compensations[0] );
    }

    CUR_Func_move( &CUR.zp0, point, distance - org_dist );

    CUR.GS.rp0 = point;
    CUR.GS.rp1 = point;
  }


/**********************************************/
/* MDRP[abcde] : Move Direct Relative Point   */
/* CodeRange   : $C0-$DF                      */
/* Stack       : uint32 -->                   */

  static void  Ins_MDRP( INS_ARG )
  {
    UShort      point;
    TT_F26Dot6  org_dist, distance;


    point = (UShort)args[0];

    if ( BOUNDS( point,      CUR.zp1.n_points ) ||
         BOUNDS( CUR.GS.rp0, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* XXX: Is there some undocumented feature while in the */
    /*      twilight zone?                                  */

    org_dist = CUR_Func_dualproj( CUR.zp1.org + point,
                                  CUR.zp0.org + CUR.GS.rp0 );

    /* single width cutin test */

    if ( ABS( org_dist ) < CUR.GS.single_width_cutin )
    {
      if ( org_dist >= 0 )
        org_dist = CUR.GS.single_width_value;
      else
        org_dist = -CUR.GS.single_width_value;
    }

    /* round flag */

    if ( (CUR.opcode & 4) != 0 )
      distance = CUR_Func_round( org_dist,
                                 CUR.metrics.compensations[CUR.opcode & 3] );
    else
      distance = Round_None( EXEC_ARGS
                             org_dist,
                             CUR.metrics.compensations[CUR.opcode & 3]  );

    /* minimum distance flag */

    if ( (CUR.opcode & 8) != 0 )
    {
      if ( org_dist >= 0 )
      {
        if ( distance < CUR.GS.minimum_distance )
          distance = CUR.GS.minimum_distance;
      }
      else
      {
        if ( distance > -CUR.GS.minimum_distance )
          distance = -CUR.GS.minimum_distance;
      }
    }

    /* now move the point */

    org_dist = CUR_Func_project( CUR.zp1.cur + point,
                                 CUR.zp0.cur + CUR.GS.rp0 );

    CUR_Func_move( &CUR.zp1, point, distance - org_dist );

    CUR.GS.rp1 = CUR.GS.rp0;
    CUR.GS.rp2 = point;

    if ( (CUR.opcode & 16) != 0 )
      CUR.GS.rp0 = point;
  }


/**********************************************/
/* MIRP[abcde] : Move Indirect Relative Point */
/* CodeRange   : $E0-$FF                      */
/* Stack       : int32? uint32 -->            */

  static void  Ins_MIRP( INS_ARG )
  {
    UShort      point;
    ULong       cvtEntry;

    TT_F26Dot6  cvt_dist,
                distance,
                cur_dist,
                org_dist;


    point    = (UShort)args[0];
    cvtEntry = (ULong)(args[1] + 1);

    /* XXX: UNDOCUMENTED! cvt[-1] = 0 always */

    if ( BOUNDS( point,      CUR.zp1.n_points ) ||
         BOUNDS( cvtEntry,   CUR.cvtSize + 1 )  ||
         BOUNDS( CUR.GS.rp0, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    if ( !cvtEntry )
      cvt_dist = 0;
    else
      cvt_dist = CUR_Func_read_cvt( cvtEntry - 1 );

    /* single width test */

    if ( ABS( cvt_dist ) < CUR.GS.single_width_cutin )
    {
      if ( cvt_dist >= 0 )
        cvt_dist =  CUR.GS.single_width_value;
      else
        cvt_dist = -CUR.GS.single_width_value;
    }

    /* XXX : UNDOCUMENTED! -- twilight zone */

    if ( CUR.GS.gep1 == 0 )
    {
      CUR.zp1.org[point].x = CUR.zp0.org[CUR.GS.rp0].x +
                             TT_MulDiv( cvt_dist,
                                        CUR.GS.freeVector.x,
                                        0x4000 );

      CUR.zp1.org[point].y = CUR.zp0.org[CUR.GS.rp0].y +
                             TT_MulDiv( cvt_dist,
                                        CUR.GS.freeVector.y,
                                        0x4000 );

      CUR.zp1.cur[point] = CUR.zp1.org[point];
    }

    org_dist = CUR_Func_dualproj( CUR.zp1.org + point,
                                  CUR.zp0.org + CUR.GS.rp0 );

    cur_dist = CUR_Func_project( CUR.zp1.cur + point,
                                 CUR.zp0.cur + CUR.GS.rp0 );

    /* auto-flip test */

    if ( CUR.GS.auto_flip )
    {
      if ( (org_dist ^ cvt_dist) < 0 )
        cvt_dist = -cvt_dist;
    }

    /* control value cutin and round */

    if ( (CUR.opcode & 4) != 0 )
    {
      /* XXX: UNDOCUMENTED!  Only perform cut-in test when both points */
      /*      refer to the same zone.                                  */

      if ( CUR.GS.gep0 == CUR.GS.gep1 )
        if ( ABS( cvt_dist - org_dist ) >= CUR.GS.control_value_cutin )
          cvt_dist = org_dist;

      distance = CUR_Func_round( cvt_dist,
                                 CUR.metrics.compensations[CUR.opcode & 3] );
    }
    else
      distance = Round_None( EXEC_ARGS
                             cvt_dist,
                             CUR.metrics.compensations[CUR.opcode & 3] );

    /* minimum distance test */

    if ( (CUR.opcode & 8) != 0 )
    {
      if ( org_dist >= 0 )
      {
        if ( distance < CUR.GS.minimum_distance )
          distance = CUR.GS.minimum_distance;
      }
      else
      {
        if ( distance > -CUR.GS.minimum_distance )
          distance = -CUR.GS.minimum_distance;
      }
    }

    CUR_Func_move( &CUR.zp1, point, distance - cur_dist );

    CUR.GS.rp1 = CUR.GS.rp0;

    if ( (CUR.opcode & 16) != 0 )
      CUR.GS.rp0 = point;

    /* UNDOCUMENTED! */

    CUR.GS.rp2 = point;
  }


/**********************************************/
/* ALIGNRP[]   : ALIGN Relative Point         */
/* CodeRange   : $3C                          */
/* Stack       : uint32 uint32... -->         */

  static void  Ins_ALIGNRP( INS_ARG )
  {
    UShort      point;
    TT_F26Dot6  distance;


    if ( CUR.top < CUR.GS.loop ||
         BOUNDS( CUR.GS.rp0, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    while ( CUR.GS.loop > 0 )
    {
      CUR.args--;

      point = (UShort)CUR.stack[CUR.args];

      if ( BOUNDS( point, CUR.zp1.n_points ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
      {
        distance = CUR_Func_project( CUR.zp1.cur + point,
                                     CUR.zp0.cur + CUR.GS.rp0 );

        CUR_Func_move( &CUR.zp1, point, -distance );
      }

      CUR.GS.loop--;
    }

    CUR.GS.loop = 1;
    CUR.new_top = CUR.args;
  }


/**********************************************/
/* ISECT[]     : moves point to InterSECTion  */
/* CodeRange   : $0F                          */
/* Stack       : 5 * uint32 -->               */

  static void  Ins_ISECT( INS_ARG )
  {
    UShort  point,
            a0, a1,
            b0, b1;

    TT_F26Dot6  discriminant;

    TT_F26Dot6  dx,  dy,
                dax, day,
                dbx, dby;

    TT_F26Dot6  val;

    TT_Vector   R;


    point = (UShort)args[0];

    a0 = (UShort)args[1];
    a1 = (UShort)args[2];
    b0 = (UShort)args[3];
    b1 = (UShort)args[4];

    if ( BOUNDS( b0, CUR.zp0.n_points ) ||
         BOUNDS( b1, CUR.zp0.n_points ) ||
         BOUNDS( a0, CUR.zp1.n_points ) ||
         BOUNDS( a1, CUR.zp1.n_points ) ||
         BOUNDS( point, CUR.zp2.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    dbx = CUR.zp0.cur[b1].x - CUR.zp0.cur[b0].x;
    dby = CUR.zp0.cur[b1].y - CUR.zp0.cur[b0].y;

    dax = CUR.zp1.cur[a1].x - CUR.zp1.cur[a0].x;
    day = CUR.zp1.cur[a1].y - CUR.zp1.cur[a0].y;

    dx = CUR.zp0.cur[b0].x - CUR.zp1.cur[a0].x;
    dy = CUR.zp0.cur[b0].y - CUR.zp1.cur[a0].y;

    CUR.zp2.touch[point] |= TT_Flag_Touched_Both;

    discriminant = TT_MulDiv( dax, -dby, 0x40L ) +
                   TT_MulDiv( day, dbx, 0x40L );

    if ( ABS( discriminant ) >= 0x40 )
    {
      val = TT_MulDiv( dx, -dby, 0x40L ) + TT_MulDiv( dy, dbx, 0x40L );

      R.x = TT_MulDiv( val, dax, discriminant );
      R.y = TT_MulDiv( val, day, discriminant );

      CUR.zp2.cur[point].x = CUR.zp1.cur[a0].x + R.x;
      CUR.zp2.cur[point].y = CUR.zp1.cur[a0].y + R.y;
    }
    else
    {
      /* else, take the middle of the middles of A and B */

      CUR.zp2.cur[point].x = ( CUR.zp1.cur[a0].x +
                               CUR.zp1.cur[a1].x +
                               CUR.zp0.cur[b0].x +
                               CUR.zp0.cur[b1].x ) / 4;
      CUR.zp2.cur[point].y = ( CUR.zp1.cur[a0].y +
                               CUR.zp1.cur[a1].y +
                               CUR.zp0.cur[b0].y +
                               CUR.zp0.cur[b1].y ) / 4;
    }
  }


/**********************************************/
/* ALIGNPTS[]  : ALIGN PoinTS                 */
/* CodeRange   : $27                          */
/* Stack       : uint32 uint32 -->            */

  static void  Ins_ALIGNPTS( INS_ARG )
  {
    UShort      p1, p2;
    TT_F26Dot6  distance;


    p1 = (UShort)args[0];
    p2 = (UShort)args[1];

    if ( BOUNDS( args[0], CUR.zp1.n_points ) ||
         BOUNDS( args[1], CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    distance = CUR_Func_project( CUR.zp0.cur + p2,
                                 CUR.zp1.cur + p1 ) / 2;

    CUR_Func_move( &CUR.zp1, p1, distance );
    CUR_Func_move( &CUR.zp0, p2, -distance );
  }


/**********************************************/
/* IP[]        : Interpolate Point            */
/* CodeRange   : $39                          */
/* Stack       : uint32... -->                */

  static void  Ins_IP( INS_ARG )
  {
    TT_F26Dot6  org_a, org_b, org_x,
                cur_a, cur_b, cur_x,
                distance;
    UShort      point;


    if ( CUR.top < CUR.GS.loop )
    {
      CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    /* XXX: there are some glyphs in some braindead but popular  */
    /*      fonts out there (e.g. [aeu]grave in monotype.ttf)    */
    /*      calling IP[] with bad values of rp[12]               */
    /*      do something sane when this odd thing happens        */

    if ( BOUNDS( CUR.GS.rp1, CUR.zp0.n_points ) ||
         BOUNDS( CUR.GS.rp2, CUR.zp1.n_points ) )
    {
      org_a = cur_a = 0;
      org_b = cur_b = 0;
    }
    else
    {
      org_a = CUR_Func_dualproj( CUR.zp0.org + CUR.GS.rp1, NULL_Vector );
      org_b = CUR_Func_dualproj( CUR.zp1.org + CUR.GS.rp2, NULL_Vector );

      cur_a = CUR_Func_project( CUR.zp0.cur + CUR.GS.rp1, NULL_Vector );
      cur_b = CUR_Func_project( CUR.zp1.cur + CUR.GS.rp2, NULL_Vector );
    }

    while ( CUR.GS.loop > 0 )
    {
      CUR.args--;

      point = (UShort)CUR.stack[CUR.args];
      if ( BOUNDS( point, CUR.zp2.n_points ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
      {
        org_x = CUR_Func_dualproj( CUR.zp2.org + point, NULL_Vector );
        cur_x = CUR_Func_project ( CUR.zp2.cur + point, NULL_Vector );

        if ( ( org_a <= org_b && org_x <= org_a ) ||
             ( org_a >  org_b && org_x >= org_a ) )

          distance = ( cur_a - org_a ) + ( org_x - cur_x );

        else if ( ( org_a <= org_b  &&  org_x >= org_b ) ||
                  ( org_a >  org_b  &&  org_x <  org_b ) )

          distance = ( cur_b - org_b ) + ( org_x - cur_x );

        else
           /* note: it seems that rounding this value isn't a good */
           /*       idea (cf. width of capital 'S' in Times)       */

           distance = TT_MulDiv( cur_b - cur_a,
                                 org_x - org_a,
                                 org_b - org_a ) + ( cur_a - cur_x );

        CUR_Func_move( &CUR.zp2, point, distance );
      }

      CUR.GS.loop--;
    }

    CUR.GS.loop = 1;
    CUR.new_top = CUR.args;
  }


/**********************************************/
/* UTP[a]      : UnTouch Point                */
/* CodeRange   : $29                          */
/* Stack       : uint32 -->                   */

  static void  Ins_UTP( INS_ARG )
  {
    UShort  point;
    Byte    mask;


    point = (UShort)args[0];

    if ( BOUNDS( point, CUR.zp0.n_points ) )
    {
      if ( CUR.pedantic_hinting )
        CUR.error = TT_Err_Invalid_Reference;
      return;
    }

    mask = 0xFF;

    if ( CUR.GS.freeVector.x != 0 )
      mask &= ~TT_Flag_Touched_X;

    if ( CUR.GS.freeVector.y != 0 )
      mask &= ~TT_Flag_Touched_Y;

    CUR.zp0.touch[point] &= mask;
  }


  /* Local variables for Ins_IUP: */
  struct LOC_Ins_IUP
  {
    TT_Vector*  orgs;   /* original and current coordinate */
    TT_Vector*  curs;   /* arrays                          */
  };


  static void  Shift( UShort               p1,
                      UShort               p2,
                      UShort               p,
                      struct LOC_Ins_IUP*  LINK )
  {
    UShort      i;
    TT_F26Dot6  x;


    x = LINK->curs[p].x - LINK->orgs[p].x;

    for ( i = p1; i < p; i++ )
      LINK->curs[i].x += x;

    for ( i = p + 1; i <= p2; i++ )
      LINK->curs[i].x += x;
  }


  static void  Interp( UShort               p1,
                       UShort               p2,
                       UShort               ref1,
                       UShort               ref2,
                       struct LOC_Ins_IUP*  LINK )
  {
    UShort      i;
    TT_F26Dot6  x, x1, x2, d1, d2;


    if ( p1 > p2 )
      return;

    x1 = LINK->orgs[ref1].x;
    d1 = LINK->curs[ref1].x - LINK->orgs[ref1].x;
    x2 = LINK->orgs[ref2].x;
    d2 = LINK->curs[ref2].x - LINK->orgs[ref2].x;

    if ( x1 == x2 )
    {
      for ( i = p1; i <= p2; i++ )
      {
        x = LINK->orgs[i].x;

        if ( x <= x1 )
          x += d1;
        else
          x += d2;

        LINK->curs[i].x = x;
      }
      return;
    }

    if ( x1 < x2 )
    {
      for ( i = p1; i <= p2; i++ )
      {
        x = LINK->orgs[i].x;

        if ( x <= x1 )
          x += d1;
        else
        {
          if ( x >= x2 )
            x += d2;
          else
            x = LINK->curs[ref1].x +
                  TT_MulDiv( x - x1,
                             LINK->curs[ref2].x - LINK->curs[ref1].x,
                             x2 - x1 );
        }
        LINK->curs[i].x = x;
      }
      return;
    }

    /* x2 < x1 */

    for ( i = p1; i <= p2; i++ )
    {
      x = LINK->orgs[i].x;
      if ( x <= x2 )
        x += d2;
      else
      {
        if ( x >= x1 )
          x += d1;
        else
          x = LINK->curs[ref1].x +
              TT_MulDiv( x - x1,
                         LINK->curs[ref2].x - LINK->curs[ref1].x,
                         x2 - x1 );
      }
      LINK->curs[i].x = x;
    }
  }


/**********************************************/
/* IUP[a]      : Interpolate Untouched Points */
/* CodeRange   : $30-$31                      */
/* Stack       : -->                          */

  static void  Ins_IUP( INS_ARG )
  {
    struct LOC_Ins_IUP  V;
    Byte                mask;

    UShort  first_point;   /* first point of contour        */
    UShort  end_point;     /* end point (last+1) of contour */

    UShort  first_touched; /* first touched point in contour   */
    UShort  cur_touched;   /* current touched point in contour */

    UShort  point;         /* current point   */
    Short   contour;       /* current contour */


    if ( CUR.opcode & 1 )
    {
      mask   = TT_Flag_Touched_X;
      V.orgs = CUR.pts.org;
      V.curs = CUR.pts.cur;
    }
    else
    {
      mask   = TT_Flag_Touched_Y;
      V.orgs = (TT_Vector*)( ((TT_F26Dot6*)CUR.pts.org) + 1 );
      V.curs = (TT_Vector*)( ((TT_F26Dot6*)CUR.pts.cur) + 1 );
    }

    contour = 0;
    point   = 0;

    do
    {
      end_point   = CUR.pts.contours[contour];
      first_point = point;

      while ( point <= end_point && (CUR.pts.touch[point] & mask) == 0 )
        point++;

      if ( point <= end_point )
      {
        first_touched = point;
        cur_touched   = point;

        point++;

        while ( point <= end_point )
        {
          if ( (CUR.pts.touch[point] & mask) != 0 )
          {
            if ( point > 0 )
              Interp( cur_touched + 1,
                      point - 1,
                      cur_touched,
                      point,
                      &V );
            cur_touched = point;
          }

          point++;
        }

        if ( cur_touched == first_touched )
          Shift( first_point, end_point, cur_touched, &V );
        else
        {
          Interp( cur_touched + 1,
                  end_point,
                  cur_touched,
                  first_touched,
                  &V );

          if ( first_touched > 0 )
            Interp( first_point,
                    first_touched - 1,
                    cur_touched,
                    first_touched,
                    &V );
        }
      }
      contour++;
    } while ( contour < CUR.pts.n_contours );
  }


/**********************************************/
/* DELTAPn[]   : DELTA Exceptions P1, P2, P3  */
/* CodeRange   : $5D,$71,$72                  */
/* Stack       : uint32 (2 * uint32)... -->   */

  static void  Ins_DELTAP( INS_ARG )
  {
    ULong   nump, k;
    UShort  A;
    ULong   C;
    Long    B;


    nump = (ULong)args[0];      /* some points theoretically may occur more
                                   than once, thus UShort isn't enough */

    for ( k = 1; k <= nump; ++k )
    {
      if ( CUR.args < 2 )
      {
        CUR.error = TT_Err_Too_Few_Arguments;
        return;
      }

      CUR.args -= 2;

      A = (UShort)CUR.stack[CUR.args + 1];
      B = CUR.stack[CUR.args];

      /* XXX : because some popular fonts contain some invalid DeltaP */
      /*       instructions, we simply ignore them when the stacked   */
      /*       point reference is off limit, rather than returning an */
      /*       error. As a delta instruction doesn't change a glyph   */
      /*       in great ways, this shouldn't be a problem..           */

      if ( !BOUNDS( A, CUR.zp0.n_points ) )
      {
        C = ((ULong)B & 0xF0) >> 4;

        switch ( CUR.opcode )
        {
        case 0x5d:
          break;

        case 0x71:
          C += 16;
          break;

        case 0x72:
          C += 32;
          break;
        }

        C += CUR.GS.delta_base;

        if ( CURRENT_Ppem() == (Long)C )
        {
          B = ((ULong)B & 0xF) - 8;
          if ( B >= 0 )
            B++;
          B = B * 64L / (1L << CUR.GS.delta_shift);

          CUR_Func_move( &CUR.zp0, A, B );
        }
      }
      else
        if ( CUR.pedantic_hinting )
          CUR.error = TT_Err_Invalid_Reference;
    }

    CUR.new_top = CUR.args;
  }


/**********************************************/
/* DELTACn[]   : DELTA Exceptions C1, C2, C3  */
/* CodeRange   : $73,$74,$75                  */
/* Stack       : uint32 (2 * uint32)... -->   */

  static void  Ins_DELTAC( INS_ARG )
  {
    ULong  nump, k;
    ULong  A, C;
    Long   B;


    nump = (ULong)args[0];

    for ( k = 1; k <= nump; ++k )
    {
      if ( CUR.args < 2 )
      {
        CUR.error = TT_Err_Too_Few_Arguments;
        return;
      }

      CUR.args -= 2;

      A = (ULong)CUR.stack[CUR.args + 1];
      B = CUR.stack[CUR.args];

      if ( BOUNDS( A, CUR.cvtSize ) )
      {
        if ( CUR.pedantic_hinting )
        {
          CUR.error = TT_Err_Invalid_Reference;
          return;
        }
      }
      else
      {
        C = ((ULong)B & 0xF0) >> 4;

        switch ( CUR.opcode )
        {
        case 0x73:
          break;

        case 0x74:
          C += 16;
          break;

        case 0x75:
          C += 32;
          break;
        }

        C += CUR.GS.delta_base;

        if ( CURRENT_Ppem() == (Long)C )
        {
          B = ((ULong)B & 0xF) - 8;
          if ( B >= 0 )
            B++;
          B = B * 64L / (1L << CUR.GS.delta_shift);

          CUR_Func_move_cvt( A, B );
        }
      }
    }

    CUR.new_top = CUR.args;
  }



/****************************************************************/
/*                                                              */
/* MISC. INSTRUCTIONS                                           */
/*                                                              */
/****************************************************************/


/**********************************************/
/* GETINFO[]   : GET INFOrmation              */
/* CodeRange   : $88                          */
/* Stack       : uint32 --> uint32            */

/* XXX According to Apple specs, bits 1 & 2 of the argument ought to be */
/*     consulted before rotated / stretched info is returned            */

  static void  Ins_GETINFO( INS_ARG )
  {
    Long  K;


    K = 0;

    /* We return then Windows 3.1 version number */
    /* for the font scaler                       */
    if ( (args[0] & 1) != 0 )
      K = 3;

    /* Has the glyph been rotated ? */
/*    if ( CUR.metrics.rotated )
      K |= 0x80; */

    /* Has the glyph been stretched ? */
 /*   if ( CUR.metrics.stretched )
      K |= 0x100; */

    args[0] = K;
  }


  static void  Ins_UNKNOWN( INS_ARG )
  {
    /* look up the current instruction in our table */
    PDefRecord  def, limit;
    
    def   = CUR.IDefs;
    limit = def + CUR.numIDefs;
    for ( ; def < limit; def++ )
    {
      if ( def->Opc == CUR.opcode && def->Active )
      {
        PCallRecord  pCrec;

        /* implement instruction as a function call */

        /* check call stack */
        if ( CUR.callTop >= CUR.callSize )
        {
          CUR.error = TT_Err_Stack_Overflow;
          return;
        }

        pCrec = CUR.callStack + CUR.callTop;
    
        pCrec->Caller_Range = CUR.curRange;
        pCrec->Caller_IP    = CUR.IP + 1;
        pCrec->Cur_Count    = 1;
        pCrec->Cur_Restart  = def->Start;
    
        CUR.callTop++;
    
        INS_Goto_CodeRange( def->Range,
                            def->Start );
    
        CUR.step_ins = FALSE;
        return;
      }
    }

    CUR.error = TT_Err_Invalid_Opcode;
  }


#ifndef TT_CONFIG_OPTION_INTERPRETER_SWITCH
  static TInstruction_Function  Instruct_Dispatch[256] =
  {
    /* Opcodes are gathered in groups of 16. */
    /* Please keep the spaces as they are.   */

    /*  SVTCA  y  */  Ins_SVTCA,
    /*  SVTCA  x  */  Ins_SVTCA,
    /*  SPvTCA y  */  Ins_SPVTCA,
    /*  SPvTCA x  */  Ins_SPVTCA,
    /*  SFvTCA y  */  Ins_SFVTCA,
    /*  SFvTCA x  */  Ins_SFVTCA,
    /*  SPvTL //  */  Ins_SPVTL,
    /*  SPvTL +   */  Ins_SPVTL,
    /*  SFvTL //  */  Ins_SFVTL,
    /*  SFvTL +   */  Ins_SFVTL,
    /*  SPvFS     */  Ins_SPVFS,
    /*  SFvFS     */  Ins_SFVFS,
    /*  GPV       */  Ins_GPV,
    /*  GFV       */  Ins_GFV,
    /*  SFvTPv    */  Ins_SFVTPV,
    /*  ISECT     */  Ins_ISECT,

    /*  SRP0      */  Ins_SRP0,
    /*  SRP1      */  Ins_SRP1,
    /*  SRP2      */  Ins_SRP2,
    /*  SZP0      */  Ins_SZP0,
    /*  SZP1      */  Ins_SZP1,
    /*  SZP2      */  Ins_SZP2,
    /*  SZPS      */  Ins_SZPS,
    /*  SLOOP     */  Ins_SLOOP,
    /*  RTG       */  Ins_RTG,
    /*  RTHG      */  Ins_RTHG,
    /*  SMD       */  Ins_SMD,
    /*  ELSE      */  Ins_ELSE,
    /*  JMPR      */  Ins_JMPR,
    /*  SCvTCi    */  Ins_SCVTCI,
    /*  SSwCi     */  Ins_SSWCI,
    /*  SSW       */  Ins_SSW,

    /*  DUP       */  Ins_DUP,
    /*  POP       */  Ins_POP,
    /*  CLEAR     */  Ins_CLEAR,
    /*  SWAP      */  Ins_SWAP,
    /*  DEPTH     */  Ins_DEPTH,
    /*  CINDEX    */  Ins_CINDEX,
    /*  MINDEX    */  Ins_MINDEX,
    /*  AlignPTS  */  Ins_ALIGNPTS,
    /*  INS_$28   */  Ins_UNKNOWN,
    /*  UTP       */  Ins_UTP,
    /*  LOOPCALL  */  Ins_LOOPCALL,
    /*  CALL      */  Ins_CALL,
    /*  FDEF      */  Ins_FDEF,
    /*  ENDF      */  Ins_ENDF,
    /*  MDAP[0]   */  Ins_MDAP,
    /*  MDAP[1]   */  Ins_MDAP,

    /*  IUP[0]    */  Ins_IUP,
    /*  IUP[1]    */  Ins_IUP,
    /*  SHP[0]    */  Ins_SHP,
    /*  SHP[1]    */  Ins_SHP,
    /*  SHC[0]    */  Ins_SHC,
    /*  SHC[1]    */  Ins_SHC,
    /*  SHZ[0]    */  Ins_SHZ,
    /*  SHZ[1]    */  Ins_SHZ,
    /*  SHPIX     */  Ins_SHPIX,
    /*  IP        */  Ins_IP,
    /*  MSIRP[0]  */  Ins_MSIRP,
    /*  MSIRP[1]  */  Ins_MSIRP,
    /*  AlignRP   */  Ins_ALIGNRP,
    /*  RTDG      */  Ins_RTDG,
    /*  MIAP[0]   */  Ins_MIAP,
    /*  MIAP[1]   */  Ins_MIAP,

    /*  NPushB    */  Ins_NPUSHB,
    /*  NPushW    */  Ins_NPUSHW,
    /*  WS        */  Ins_WS,
    /*  RS        */  Ins_RS,
    /*  WCvtP     */  Ins_WCVTP,
    /*  RCvt      */  Ins_RCVT,
    /*  GC[0]     */  Ins_GC,
    /*  GC[1]     */  Ins_GC,
    /*  SCFS      */  Ins_SCFS,
    /*  MD[0]     */  Ins_MD,
    /*  MD[1]     */  Ins_MD,
    /*  MPPEM     */  Ins_MPPEM,
    /*  MPS       */  Ins_MPS,
    /*  FlipON    */  Ins_FLIPON,
    /*  FlipOFF   */  Ins_FLIPOFF,
    /*  DEBUG     */  Ins_DEBUG,

    /*  LT        */  Ins_LT,
    /*  LTEQ      */  Ins_LTEQ,
    /*  GT        */  Ins_GT,
    /*  GTEQ      */  Ins_GTEQ,
    /*  EQ        */  Ins_EQ,
    /*  NEQ       */  Ins_NEQ,
    /*  ODD       */  Ins_ODD,
    /*  EVEN      */  Ins_EVEN,
    /*  IF        */  Ins_IF,
    /*  EIF       */  Ins_EIF,
    /*  AND       */  Ins_AND,
    /*  OR        */  Ins_OR,
    /*  NOT       */  Ins_NOT,
    /*  DeltaP1   */  Ins_DELTAP,
    /*  SDB       */  Ins_SDB,
    /*  SDS       */  Ins_SDS,

    /*  ADD       */  Ins_ADD,
    /*  SUB       */  Ins_SUB,
    /*  DIV       */  Ins_DIV,
    /*  MUL       */  Ins_MUL,
    /*  ABS       */  Ins_ABS,
    /*  NEG       */  Ins_NEG,
    /*  FLOOR     */  Ins_FLOOR,
    /*  CEILING   */  Ins_CEILING,
    /*  ROUND[0]  */  Ins_ROUND,
    /*  ROUND[1]  */  Ins_ROUND,
    /*  ROUND[2]  */  Ins_ROUND,
    /*  ROUND[3]  */  Ins_ROUND,
    /*  NROUND[0] */  Ins_NROUND,
    /*  NROUND[1] */  Ins_NROUND,
    /*  NROUND[2] */  Ins_NROUND,
    /*  NROUND[3] */  Ins_NROUND,

    /*  WCvtF     */  Ins_WCVTF,
    /*  DeltaP2   */  Ins_DELTAP,
    /*  DeltaP3   */  Ins_DELTAP,
    /*  DeltaCn[0] */ Ins_DELTAC,
    /*  DeltaCn[1] */ Ins_DELTAC,
    /*  DeltaCn[2] */ Ins_DELTAC,
    /*  SROUND    */  Ins_SROUND,
    /*  S45Round  */  Ins_S45ROUND,
    /*  JROT      */  Ins_JROT,
    /*  JROF      */  Ins_JROF,
    /*  ROFF      */  Ins_ROFF,
    /*  INS_$7B   */  Ins_UNKNOWN,
    /*  RUTG      */  Ins_RUTG,
    /*  RDTG      */  Ins_RDTG,
    /*  SANGW     */  Ins_SANGW,
    /*  AA        */  Ins_AA,

    /*  FlipPT    */  Ins_FLIPPT,
    /*  FlipRgON  */  Ins_FLIPRGON,
    /*  FlipRgOFF */  Ins_FLIPRGOFF,
    /*  INS_$83   */  Ins_UNKNOWN,
    /*  INS_$84   */  Ins_UNKNOWN,
    /*  ScanCTRL  */  Ins_SCANCTRL,
    /*  SDPVTL[0] */  Ins_SDPVTL,
    /*  SDPVTL[1] */  Ins_SDPVTL,
    /*  GetINFO   */  Ins_GETINFO,
    /*  IDEF      */  Ins_IDEF,
    /*  ROLL      */  Ins_ROLL,
    /*  MAX       */  Ins_MAX,
    /*  MIN       */  Ins_MIN,
    /*  ScanTYPE  */  Ins_SCANTYPE,
    /*  InstCTRL  */  Ins_INSTCTRL,
    /*  INS_$8F   */  Ins_UNKNOWN,

    /*  INS_$90  */   Ins_UNKNOWN,
    /*  INS_$91  */   Ins_UNKNOWN,
    /*  INS_$92  */   Ins_UNKNOWN,
    /*  INS_$93  */   Ins_UNKNOWN,
    /*  INS_$94  */   Ins_UNKNOWN,
    /*  INS_$95  */   Ins_UNKNOWN,
    /*  INS_$96  */   Ins_UNKNOWN,
    /*  INS_$97  */   Ins_UNKNOWN,
    /*  INS_$98  */   Ins_UNKNOWN,
    /*  INS_$99  */   Ins_UNKNOWN,
    /*  INS_$9A  */   Ins_UNKNOWN,
    /*  INS_$9B  */   Ins_UNKNOWN,
    /*  INS_$9C  */   Ins_UNKNOWN,
    /*  INS_$9D  */   Ins_UNKNOWN,
    /*  INS_$9E  */   Ins_UNKNOWN,
    /*  INS_$9F  */   Ins_UNKNOWN,

    /*  INS_$A0  */   Ins_UNKNOWN,
    /*  INS_$A1  */   Ins_UNKNOWN,
    /*  INS_$A2  */   Ins_UNKNOWN,
    /*  INS_$A3  */   Ins_UNKNOWN,
    /*  INS_$A4  */   Ins_UNKNOWN,
    /*  INS_$A5  */   Ins_UNKNOWN,
    /*  INS_$A6  */   Ins_UNKNOWN,
    /*  INS_$A7  */   Ins_UNKNOWN,
    /*  INS_$A8  */   Ins_UNKNOWN,
    /*  INS_$A9  */   Ins_UNKNOWN,
    /*  INS_$AA  */   Ins_UNKNOWN,
    /*  INS_$AB  */   Ins_UNKNOWN,
    /*  INS_$AC  */   Ins_UNKNOWN,
    /*  INS_$AD  */   Ins_UNKNOWN,
    /*  INS_$AE  */   Ins_UNKNOWN,
    /*  INS_$AF  */   Ins_UNKNOWN,

    /*  PushB[0]  */  Ins_PUSHB,
    /*  PushB[1]  */  Ins_PUSHB,
    /*  PushB[2]  */  Ins_PUSHB,
    /*  PushB[3]  */  Ins_PUSHB,
    /*  PushB[4]  */  Ins_PUSHB,
    /*  PushB[5]  */  Ins_PUSHB,
    /*  PushB[6]  */  Ins_PUSHB,
    /*  PushB[7]  */  Ins_PUSHB,
    /*  PushW[0]  */  Ins_PUSHW,
    /*  PushW[1]  */  Ins_PUSHW,
    /*  PushW[2]  */  Ins_PUSHW,
    /*  PushW[3]  */  Ins_PUSHW,
    /*  PushW[4]  */  Ins_PUSHW,
    /*  PushW[5]  */  Ins_PUSHW,
    /*  PushW[6]  */  Ins_PUSHW,
    /*  PushW[7]  */  Ins_PUSHW,

    /*  MDRP[00]  */  Ins_MDRP,
    /*  MDRP[01]  */  Ins_MDRP,
    /*  MDRP[02]  */  Ins_MDRP,
    /*  MDRP[03]  */  Ins_MDRP,
    /*  MDRP[04]  */  Ins_MDRP,
    /*  MDRP[05]  */  Ins_MDRP,
    /*  MDRP[06]  */  Ins_MDRP,
    /*  MDRP[07]  */  Ins_MDRP,
    /*  MDRP[08]  */  Ins_MDRP,
    /*  MDRP[09]  */  Ins_MDRP,
    /*  MDRP[10]  */  Ins_MDRP,
    /*  MDRP[11]  */  Ins_MDRP,
    /*  MDRP[12]  */  Ins_MDRP,
    /*  MDRP[13]  */  Ins_MDRP,
    /*  MDRP[14]  */  Ins_MDRP,
    /*  MDRP[15]  */  Ins_MDRP,

    /*  MDRP[16]  */  Ins_MDRP,
    /*  MDRP[17]  */  Ins_MDRP,
    /*  MDRP[18]  */  Ins_MDRP,
    /*  MDRP[19]  */  Ins_MDRP,
    /*  MDRP[20]  */  Ins_MDRP,
    /*  MDRP[21]  */  Ins_MDRP,
    /*  MDRP[22]  */  Ins_MDRP,
    /*  MDRP[23]  */  Ins_MDRP,
    /*  MDRP[24]  */  Ins_MDRP,
    /*  MDRP[25]  */  Ins_MDRP,
    /*  MDRP[26]  */  Ins_MDRP,
    /*  MDRP[27]  */  Ins_MDRP,
    /*  MDRP[28]  */  Ins_MDRP,
    /*  MDRP[29]  */  Ins_MDRP,
    /*  MDRP[30]  */  Ins_MDRP,
    /*  MDRP[31]  */  Ins_MDRP,

    /*  MIRP[00]  */  Ins_MIRP,
    /*  MIRP[01]  */  Ins_MIRP,
    /*  MIRP[02]  */  Ins_MIRP,
    /*  MIRP[03]  */  Ins_MIRP,
    /*  MIRP[04]  */  Ins_MIRP,
    /*  MIRP[05]  */  Ins_MIRP,
    /*  MIRP[06]  */  Ins_MIRP,
    /*  MIRP[07]  */  Ins_MIRP,
    /*  MIRP[08]  */  Ins_MIRP,
    /*  MIRP[09]  */  Ins_MIRP,
    /*  MIRP[10]  */  Ins_MIRP,
    /*  MIRP[11]  */  Ins_MIRP,
    /*  MIRP[12]  */  Ins_MIRP,
    /*  MIRP[13]  */  Ins_MIRP,
    /*  MIRP[14]  */  Ins_MIRP,
    /*  MIRP[15]  */  Ins_MIRP,

    /*  MIRP[16]  */  Ins_MIRP,
    /*  MIRP[17]  */  Ins_MIRP,
    /*  MIRP[18]  */  Ins_MIRP,
    /*  MIRP[19]  */  Ins_MIRP,
    /*  MIRP[20]  */  Ins_MIRP,
    /*  MIRP[21]  */  Ins_MIRP,
    /*  MIRP[22]  */  Ins_MIRP,
    /*  MIRP[23]  */  Ins_MIRP,
    /*  MIRP[24]  */  Ins_MIRP,
    /*  MIRP[25]  */  Ins_MIRP,
    /*  MIRP[26]  */  Ins_MIRP,
    /*  MIRP[27]  */  Ins_MIRP,
    /*  MIRP[28]  */  Ins_MIRP,
    /*  MIRP[29]  */  Ins_MIRP,
    /*  MIRP[30]  */  Ins_MIRP,
    /*  MIRP[31]  */  Ins_MIRP
  };
#endif


/****************************************************************/
/*                                                              */
/*                    RUN                                       */
/*                                                              */
/*  This function executes a run of opcodes.  It will exit      */
/*  in the following cases:                                     */
/*                                                              */
/*   - Errors (in which case it returns FALSE)                  */
/*                                                              */
/*   - Reaching the end of the main code range (returns TRUE).  */
/*     Reaching the end of a code range within a function       */
/*     call is an error.                                        */
/*                                                              */
/*   - After executing one single opcode, if the flag           */
/*     'Instruction_Trap' is set to TRUE (returns TRUE).        */
/*                                                              */
/*  On exit whith TRUE, test IP < CodeSize to know wether it    */
/*  comes from a instruction trap or a normal termination.      */
/*                                                              */
/*                                                              */
/*     Note:  The documented DEBUG opcode pops a value from     */
/*            the stack.  This behaviour is unsupported, here   */
/*            a DEBUG opcode is always an error.                */
/*                                                              */
/*                                                              */
/* THIS IS THE INTERPRETER'S MAIN LOOP                          */
/*                                                              */
/*  Instructions appear in the specs' order.                    */
/*                                                              */
/****************************************************************/

  LOCAL_FUNC
#ifndef DEBUG_INTERPRETER
  TT_Error  RunIns( PExecution_Context  exc )
#else
  TT_Error  RunIns2( PExecution_Context  exc )
#endif
  {
    UShort       A;
    PDefRecord   WITH;
    PCallRecord  WITH1;

    Long         ins_counter = 0;  /* executed instructions counter */

#ifdef TT_CONFIG_OPTION_STATIC_INTERPRETER
    cur = *exc;
#endif

    /* set CVT functions */
    CUR.metrics.ratio = 0;
#ifdef TT_CONGIG_OPTION_SUPPORT_NON_SQUARE_PIXELS
    if ( CUR.metrics.x_ppem != CUR.metrics.y_ppem )
    {
      /* non-square pixels, use the stretched routines */
      CUR.func_read_cvt  = Read_CVT_Stretched;
      CUR.func_write_cvt = Write_CVT_Stretched;
      CUR.func_move_cvt  = Move_CVT_Stretched;
    }
    else
#endif /* TT_CONGIG_OPTION_SUPPORT_NON_SQUARE_PIXELS */
    {
      /* square pixels, use normal routines */
      CUR.func_read_cvt  = Read_CVT;
      CUR.func_write_cvt = Write_CVT;
      CUR.func_move_cvt  = Move_CVT;
    }

    COMPUTE_Funcs();
    Compute_Round( EXEC_ARGS (Byte)exc->GS.round_state );

    do
    {
      if ( CALC_Length() != SUCCESS )
      {
        CUR.error = TT_Err_Code_Overflow;
        goto LErrorLabel_;
      }

      /* First, let's check for empty stack and overflow */

      CUR.args = CUR.top - (Pop_Push_Count[CUR.opcode] >> 4);

      /* `args' is the top of the stack once arguments have been popped. */
      /* One can also interpret it as the index of the last argument.    */

      if ( CUR.args < 0 )
      {
        CUR.error = TT_Err_Too_Few_Arguments;
        goto LErrorLabel_;
      }

      CUR.new_top = CUR.args + (Pop_Push_Count[CUR.opcode] & 15);

      /* `new_top' is the new top of the stack, after the instruction's */
      /* execution.  `top' will be set to `new_top' after the 'switch'  */
      /* statement.                                                     */

      if ( CUR.new_top > CUR.stackSize )
      {
        CUR.error = TT_Err_Stack_Overflow;
        goto LErrorLabel_;
      }

      CUR.step_ins = TRUE;
      CUR.error    = TT_Err_Ok;

#ifdef TT_CONFIG_OPTION_INTERPRETER_SWITCH
      {
        PStorage  args   = CUR.stack + CUR.args;
        Byte      opcode = CUR.opcode;


#undef   ARRAY_BOUND_ERROR
#define  ARRAY_BOUND_ERROR   goto Set_Invalid_Ref

        switch ( opcode )
        {
        case 0x00:  /* SVTCA y  */
        case 0x01:  /* SVTCA x  */
        case 0x02:  /* SPvTCA y */
        case 0x03:  /* SPvTCA x */
        case 0x04:  /* SFvTCA y */
        case 0x05:  /* SFvTCA x */
          {
            Short AA, BB;


            AA = (Short)(opcode & 1) << 14;
            BB = AA ^ (Short)0x4000;

            if ( opcode < 4 )
            {
              CUR.GS.projVector.x = AA;
              CUR.GS.projVector.y = BB;

              CUR.GS.dualVector.x = AA;
              CUR.GS.dualVector.y = BB;
            }

            if ( (opcode & 2) == 0 )
            {
              CUR.GS.freeVector.x = AA;
              CUR.GS.freeVector.y = BB;
            }

            COMPUTE_Funcs();
          }
          break;

        case 0x06:  /* SPvTL // */
        case 0x07:  /* SPvTL +  */
          DO_SPVTL
          break;

        case 0x08:  /* SFvTL // */
        case 0x09:  /* SFvTL +  */
          DO_SFVTL
          break;

        case 0x0A:  /* SPvFS */
          DO_SPVFS
          break;

        case 0x0B:  /* SFvFS */
          DO_SFVFS
          break;

        case 0x0C:  /* GPV */
          DO_GPV
          break;

        case 0x0D:  /* GFV */
          DO_GFV
          break;

        case 0x0E:  /* SFvTPv */
          DO_SFVTPV
          break;

        case 0x0F:  /* ISECT  */
          Ins_ISECT( EXEC_ARGS  args );
          break;

        case 0x10:  /* SRP0 */
          DO_SRP0
          break;

        case 0x11:  /* SRP1 */
          DO_SRP1
          break;

        case 0x12:  /* SRP2 */
          DO_SRP2
          break;

        case 0x13:  /* SZP0 */
          Ins_SZP0( EXEC_ARGS  args );
          break;

        case 0x14:  /* SZP1 */
          Ins_SZP1( EXEC_ARGS  args );
          break;

        case 0x15:  /* SZP2 */
          Ins_SZP2( EXEC_ARGS  args );
          break;

        case 0x16:  /* SZPS */
          Ins_SZPS( EXEC_ARGS  args );
          break;

        case 0x17:  /* SLOOP */
          DO_SLOOP
          break;

        case 0x18:  /* RTG */
          DO_RTG
          break;

        case 0x19:  /* RTHG */
          DO_RTHG
          break;

        case 0x1A:  /* SMD */
          DO_SMD
          break;

        case 0x1B:  /* ELSE */
          Ins_ELSE( EXEC_ARGS  args );
          break;

        case 0x1C:  /* JMPR */
          DO_JMPR
          break;

        case 0x1D:  /* SCVTCI */
          DO_SCVTCI
          break;

        case 0x1E:  /* SSWCI */
          DO_SSWCI
          break;

        case 0x1F:  /* SSW */
          DO_SSW
          break;

        case 0x20:  /* DUP */
          DO_DUP
          break;

        case 0x21:  /* POP */
          /* nothing :-) !! */
          break;

        case 0x22:  /* CLEAR */
          DO_CLEAR
          break;

        case 0x23:  /* SWAP */
          DO_SWAP
          break;

        case 0x24:  /* DEPTH */
          DO_DEPTH
          break;

        case 0x25:  /* CINDEX */
          DO_CINDEX
          break;

        case 0x26:  /* MINDEX */
          Ins_MINDEX( EXEC_ARGS  args );
          break;

        case 0x27:  /* ALIGNPTS */
          Ins_ALIGNPTS( EXEC_ARGS  args );
          break;

        case 0x28:  /* ???? */
          Ins_UNKNOWN( EXEC_ARGS  args );
          break;

        case 0x29:  /* UTP */
          Ins_UTP( EXEC_ARGS  args );
          break;

        case 0x2A:  /* LOOPCALL */
          Ins_LOOPCALL( EXEC_ARGS  args );
          break;

        case 0x2B:  /* CALL */
          Ins_CALL( EXEC_ARGS  args );
          break;

        case 0x2C:  /* FDEF */
          Ins_FDEF( EXEC_ARGS  args );
          break;

        case 0x2D:  /* ENDF */
          Ins_ENDF( EXEC_ARGS  args );
          break;

        case 0x2E:  /* MDAP */
        case 0x2F:  /* MDAP */
          Ins_MDAP( EXEC_ARGS  args );
          break;


        case 0x30:  /* IUP */
        case 0x31:  /* IUP */
          Ins_IUP( EXEC_ARGS  args );
          break;

        case 0x32:  /* SHP */
        case 0x33:  /* SHP */
          Ins_SHP( EXEC_ARGS  args );
          break;

        case 0x34:  /* SHC */
        case 0x35:  /* SHC */
          Ins_SHC( EXEC_ARGS  args );
          break;

        case 0x36:  /* SHZ */
        case 0x37:  /* SHZ */
          Ins_SHZ( EXEC_ARGS  args );
          break;

        case 0x38:  /* SHPIX */
          Ins_SHPIX( EXEC_ARGS  args );
          break;

        case 0x39:  /* IP    */
          Ins_IP( EXEC_ARGS  args );
          break;

        case 0x3A:  /* MSIRP */
        case 0x3B:  /* MSIRP */
          Ins_MSIRP( EXEC_ARGS  args );
          break;

        case 0x3C:  /* AlignRP */
          Ins_ALIGNRP( EXEC_ARGS  args );
          break;

        case 0x3D:  /* RTDG */
          DO_RTDG
          break;

        case 0x3E:  /* MIAP */
        case 0x3F:  /* MIAP */
          Ins_MIAP( EXEC_ARGS  args );
          break;

        case 0x40:  /* NPUSHB */
          Ins_NPUSHB( EXEC_ARGS  args );
          break;

        case 0x41:  /* NPUSHW */
          Ins_NPUSHW( EXEC_ARGS  args );
          break;

        case 0x42:  /* WS */
          DO_WS
          break;

    Set_Invalid_Ref:
          CUR.error = TT_Err_Invalid_Reference;
          break;

        case 0x43:  /* RS */
          DO_RS
          break;

        case 0x44:  /* WCVTP */
          DO_WCVTP
          break;

        case 0x45:  /* RCVT */
          DO_RCVT
          break;

        case 0x46:  /* GC */
        case 0x47:  /* GC */
          Ins_GC( EXEC_ARGS  args );
          break;

        case 0x48:  /* SCFS */
          Ins_SCFS( EXEC_ARGS  args );
          break;

        case 0x49:  /* MD */
        case 0x4A:  /* MD */
          Ins_MD( EXEC_ARGS  args );
          break;

        case 0x4B:  /* MPPEM */
          DO_MPPEM
          break;

        case 0x4C:  /* MPS */
          DO_MPS
          break;

        case 0x4D:  /* FLIPON */
          DO_FLIPON
          break;

        case 0x4E:  /* FLIPOFF */
          DO_FLIPOFF
          break;

        case 0x4F:  /* DEBUG */
          DO_DEBUG
          break;

        case 0x50:  /* LT */
          DO_LT
          break;

        case 0x51:  /* LTEQ */
          DO_LTEQ
          break;

        case 0x52:  /* GT */
          DO_GT
          break;

        case 0x53:  /* GTEQ */
          DO_GTEQ
          break;

        case 0x54:  /* EQ */
          DO_EQ
          break;

        case 0x55:  /* NEQ */
          DO_NEQ
          break;

        case 0x56:  /* ODD */
          DO_ODD
          break;

        case 0x57:  /* EVEN */
          DO_EVEN
          break;

        case 0x58:  /* IF */
          Ins_IF( EXEC_ARGS  args );
          break;

        case 0x59:  /* EIF */
          /* do nothing */
          break;

        case 0x5A:  /* AND */
          DO_AND
          break;

        case 0x5B:  /* OR */
          DO_OR
          break;

        case 0x5C:  /* NOT */
          DO_NOT
          break;

        case 0x5D:  /* DELTAP1 */
          Ins_DELTAP( EXEC_ARGS  args );
          break;

        case 0x5E:  /* SDB */
          DO_SDB
          break;

        case 0x5F:  /* SDS */
          DO_SDS
          break;

        case 0x60:  /* ADD */
          DO_ADD
          break;

        case 0x61:  /* SUB */
          DO_SUB
          break;

        case 0x62:  /* DIV */
          DO_DIV
          break;

        case 0x63:  /* MUL */
          DO_MUL
          break;

        case 0x64:  /* ABS */
          DO_ABS
          break;

        case 0x65:  /* NEG */
          DO_NEG
          break;

        case 0x66:  /* FLOOR */
          DO_FLOOR
          break;

        case 0x67:  /* CEILING */
          DO_CEILING
          break;

        case 0x68:  /* ROUND */
        case 0x69:  /* ROUND */
        case 0x6A:  /* ROUND */
        case 0x6B:  /* ROUND */
          DO_ROUND
          break;

        case 0x6C:  /* NROUND */
        case 0x6D:  /* NROUND */
        case 0x6E:  /* NRRUND */
        case 0x6F:  /* NROUND */
          DO_NROUND
          break;

        case 0x70:  /* WCVTF */
          DO_WCVTF
          break;

        case 0x71:  /* DELTAP2 */
        case 0x72:  /* DELTAP3 */
          Ins_DELTAP( EXEC_ARGS  args );
          break;

        case 0x73:  /* DELTAC0 */
        case 0x74:  /* DELTAC1 */
        case 0x75:  /* DELTAC2 */
          Ins_DELTAC( EXEC_ARGS  args );
          break;

        case 0x76:  /* SROUND */
          DO_SROUND
          break;

        case 0x77:  /* S45Round */
          DO_S45ROUND
          break;

        case 0x78:  /* JROT */
          DO_JROT
          break;

        case 0x79:  /* JROF */
          DO_JROF
          break;

        case 0x7A:  /* ROFF */
          DO_ROFF
          break;

        case 0x7B:  /* ???? */
          Ins_UNKNOWN( EXEC_ARGS  args );
          break;

        case 0x7C:  /* RUTG */
          DO_RUTG
          break;

        case 0x7D:  /* RDTG */
          DO_RDTG
          break;

        case 0x7E:  /* SANGW */
        case 0x7F:  /* AA    */
          /* nothing - obsolete */
          break;

        case 0x80:  /* FLIPPT */
          Ins_FLIPPT( EXEC_ARGS  args );
          break;

        case 0x81:  /* FLIPRGON */
          Ins_FLIPRGON( EXEC_ARGS  args );
          break;

        case 0x82:  /* FLIPRGOFF */
          Ins_FLIPRGOFF( EXEC_ARGS  args );
          break;

        case 0x83:  /* UNKNOWN */
        case 0x84:  /* UNKNOWN */
          Ins_UNKNOWN( EXEC_ARGS  args );
          break;

        case 0x85:  /* SCANCTRL */
          Ins_SCANCTRL( EXEC_ARGS  args );
          break;

        case 0x86:  /* SDPVTL */
        case 0x87:  /* SDPVTL */
          Ins_SDPVTL( EXEC_ARGS  args );
          break;

        case 0x88:  /* GETINFO */
          Ins_GETINFO( EXEC_ARGS  args );
          break;

        case 0x89:  /* IDEF */
          Ins_IDEF( EXEC_ARGS  args );
          break;

        case 0x8A:  /* ROLL */
          Ins_ROLL( EXEC_ARGS  args );
          break;

        case 0x8B:  /* MAX */
          DO_MAX
          break;

        case 0x8C:  /* MIN */
          DO_MIN
          break;

        case 0x8D:  /* SCANTYPE */
          Ins_SCANTYPE( EXEC_ARGS  args );
          break;

        case 0x8E:  /* INSTCTRL */
          Ins_INSTCTRL( EXEC_ARGS  args );
          break;

        case 0x8F:
          Ins_UNKNOWN( EXEC_ARGS  args );
          break;

        default:
          if ( opcode >= 0xE0 )
            Ins_MIRP( EXEC_ARGS  args );
          else if ( opcode >= 0xC0 )
            Ins_MDRP( EXEC_ARGS  args );
          else if ( opcode >= 0xB8 )
            Ins_PUSHW( EXEC_ARGS  args );
          else if ( opcode >= 0xB0 )
            Ins_PUSHB( EXEC_ARGS  args );
          else
            Ins_UNKNOWN( EXEC_ARGS  args );
        }

      }
#else
      Instruct_Dispatch[CUR.opcode]( EXEC_ARGS &CUR.stack[CUR.args] );
#endif
      if ( CUR.error != TT_Err_Ok )
      {
        switch ( (Int)(CUR.error) )
        {
        case TT_Err_Invalid_Opcode: /* looking for redefined instructions */
          A = 0;

          while ( A < CUR.numIDefs )
          {
            WITH = &CUR.IDefs[A];

            if ( WITH->Active && CUR.opcode == WITH->Opc )
            {
              if ( CUR.callTop >= CUR.callSize )
              {
                CUR.error = TT_Err_Invalid_Reference;
                goto LErrorLabel_;
              }

              WITH1 = &CUR.callStack[CUR.callTop];

              WITH1->Caller_Range = CUR.curRange;
              WITH1->Caller_IP    = CUR.IP + 1;
              WITH1->Cur_Count    = 1;
              WITH1->Cur_Restart  = WITH->Start;

              if ( INS_Goto_CodeRange( WITH->Range, WITH->Start ) == FAILURE )
                goto LErrorLabel_;

              goto LSuiteLabel_;
            }
            else
            {
              A++;
              continue;
            }
          }

          CUR.error = TT_Err_Invalid_Opcode;
          goto LErrorLabel_;
/*        break;   Unreachable code warning suppress.  Leave in case a later
                   change to remind the editor to consider break; */

        default:
          goto LErrorLabel_;
/*        break; */
        }
      }

      CUR.top = CUR.new_top;

      if ( CUR.step_ins )
        CUR.IP += CUR.length;

      /* increment instruction counter and check if we didn't   */
      /* run this program for too long ?? (e.g. infinite loops) */
      if ( ++ins_counter > MAX_RUNNABLE_OPCODES )
      {
        CUR.error = TT_Err_Execution_Too_Long;
        goto LErrorLabel_;
      }

  LSuiteLabel_:

      if ( CUR.IP >= CUR.codeSize )
      {
        if ( CUR.callTop > 0 )
        {
          CUR.error = TT_Err_Code_Overflow;
          goto LErrorLabel_;
        }
        else
          goto LNo_Error_;
      }
    } while ( !CUR.instruction_trap );

  LNo_Error_:
    CUR.error = TT_Err_Ok;

  LErrorLabel_:
  
#ifdef TT_CONFIG_OPTION_STATIC_INTERPRETER
    *exc = cur;
#endif
    
    return CUR.error;
    
  
  }


#ifdef DEBUG_INTERPRETER

  /* This function must be declared by the debugger front end */
  /* in order to specify which code range to debug.           */

  int  debug_coderange = TT_CodeRange_Glyph;


  LOCAL_FUNC
  TT_Error  RunIns( PExecution_Context  exc )
  {
    Int    A, diff;
    ULong  next_IP;
    Char   ch, oldch;
    char   *temp;
    int    key;

    TT_Error  error = 0;

    TGlyph_Zone  save;
    TGlyph_Zone  pts;

#define TT_Round_Off             5
#define TT_Round_To_Half_Grid    0
#define TT_Round_To_Grid         1
#define TT_Round_To_Double_Grid  2
#define TT_Round_Up_To_Grid      4
#define TT_Round_Down_To_Grid    3
#define TT_Round_Super           6
#define TT_Round_Super_45        7

    const String*  round_str[8] =
    {
      "to half-grid",
      "to grid",
      "to double grid",
      "down to grid",
      "up to grid",
      "off",
      "super",
      "super 45"
    };

    /* Check that we're running the code range that is effectively */
    /* asked by the debugger front end.                            */
    if ( exc->curRange != debug_coderange )
      return RunIns2( exc );

    pts = exc->pts;

    save.n_points   = pts.n_points;
    save.n_contours = pts.n_contours;

    MEM_Alloc( save.org, sizeof ( TT_Vector ) * save.n_points );
    MEM_Alloc( save.cur, sizeof ( TT_Vector ) * save.n_points );
    MEM_Alloc( save.touch, sizeof ( Byte ) * save.n_points );

    exc->instruction_trap = 1;

    oldch = '\0';

    do
    {
      if ( exc->IP < exc->codeSize )
      {
#ifdef TT_CONFIG_OPTION_STATIC_INTERPRETER
        cur = *exc;
#endif
        CALC_Length();

        exc->args = exc->top - (Pop_Push_Count[exc->opcode] >> 4);

        /* `args' is the top of the stack once arguments have been popped. */
        /* One can also interpret it as the index of the last argument.    */

        /* Print the current line.  We use a 80-columns console with the   */
        /* following formatting:                                           */
        /*                                                                 */
        /* [loc]:[addr] [opcode]  [disassemby]          [a][b]|[c][d]      */
        /*                                                                 */

        {
          char      temp[80];
          int       n, col, pop;
          int       args = CUR.args;


          sprintf( temp, "%78c\n", ' ' );

          /* first letter of location */
          switch ( CUR.curRange )
          {
          case TT_CodeRange_Glyph:
            temp[0] = 'g';
            break;
          case TT_CodeRange_Cvt:
            temp[0] = 'c';
            break;
          default:
            temp[0] = 'f';
          }

          /* current IP */
          sprintf( temp+1, "%04lx: %02x  %-36.36s",
                   CUR.IP,
                   CUR.opcode,
                   Cur_U_Line(&CUR) );

          strncpy( temp+46, " (", 2 );

          args = CUR.top - 1;
          pop  = Pop_Push_Count[CUR.opcode] >> 4;
          col  = 48;
          for ( n = 6; n > 0; n-- )
          {
            if ( pop == 0 )
              temp[col-1] = (temp[col-1] == '(' ? ' ' : ')' );

            if ( args < CUR.top && args >= 0 )
              sprintf( temp+col, "%04lx", CUR.stack[args] );
            else
              sprintf( temp+col, "    " );

            temp[col+4] = ' ';
            col += 5;
            pop--;
            args--;
          }
          temp[78] = '\n';
          temp[79] = '\0';
          PTRACE0(( temp ));
        }

        /* First, check for empty stack and overflow */
        if ( CUR.args < 0 )
        {
          PTRACE0(( "ERROR : Too few arguments\n" ));
          exc->error = TT_Err_Too_Few_Arguments;
          goto LErrorLabel_;
        }

        CUR.new_top = CUR.args + (Pop_Push_Count[CUR.opcode] & 15);

      /* new_top  is the new top of the stack, after the instruction's */
      /* execution. top will be set to new_top after the 'case'        */

        if ( CUR.new_top > CUR.stackSize )
        {
          PTRACE0(( "ERROR : Stack overflow\n" ));
          exc->error = TT_Err_Stack_Overflow;
          goto LErrorLabel_;
        }
      }
      else
        PTRACE0(( "End of program reached.\n" ));

      key = 0;
      do
      {
       /* read keyboard */

        ch = getch();

        switch ( ch )
        {
        /* Help - show keybindings */
        case '?':
          PTRACE0(( "FDebug Help\n\n" ));
          PTRACE0(( "?   Show this page\n" ));
          PTRACE0(( "q   Quit debugger\n" ));
          PTRACE0(( "n   Skip to next instruction\n" ));
          PTRACE0(( "s   Step into\n" ));
          PTRACE0(( "v   Show vector info\n" ));
          PTRACE0(( "g   Show graphics state\n" ));
          PTRACE0(( "p   Show points zone\n\n" ));
          break;

        /* Show vectors */
        case 'v':
          PTRACE0(( "freedom    (%04hx,%04hx)\n", exc->GS.freeVector.x,
                                                  exc->GS.freeVector.y ));
          PTRACE0(( "projection (%04hx,%04hx)\n", exc->GS.projVector.x,
                                                  exc->GS.projVector.y ));
          PTRACE0(( "dual       (%04hx,%04hx)\n\n", exc->GS.dualVector.x,
                                                    exc->GS.dualVector.y ));
          break;

        /* Show graphics state */
        case 'g':
          PTRACE0(( "rounding   %s\n", round_str[exc->GS.round_state] ));
          PTRACE0(( "min dist   %04lx\n", exc->GS.minimum_distance ));
          PTRACE0(( "cvt_cutin  %04lx\n", exc->GS.control_value_cutin ));
          break;

        /* Show points table */
        case 'p':
          for ( A = 0; A < exc->pts.n_points; A++ )
          {
            PTRACE0(( "%02hx  ", A ));
            PTRACE0(( "%08lx,%08lx - ", pts.org[A].x, pts.org[A].y ));
            PTRACE0(( "%08lx,%08lx\n",  pts.cur[A].x, pts.cur[A].y ));
          }
          PTRACE0(( "\n" ));
          break;

        default:
          key = 1;
        }
      } while ( !key );

      MEM_Copy( save.org,   pts.org, pts.n_points * sizeof ( TT_Vector ) );
      MEM_Copy( save.cur,   pts.cur, pts.n_points * sizeof ( TT_Vector ) );
      MEM_Copy( save.touch, pts.touch, pts.n_points );

      /* a return indicate the last command */
      if (ch == '\r')
        ch = oldch;

      switch ( ch )
      {
      /* Quit debugger */
      case 'q':
        goto LErrorLabel_;

      /* Step over */
      case 'n':
        if ( exc->IP < exc->codeSize )
        {
          /* `step over' is equivalent to `step into' except if  */
          /* the current opcode is a CALL or LOOPCALL            */
          if ( CUR.opcode != 0x2a && CUR.opcode != 0x2b )
            goto Step_into;

          /* otherwise, loop execution until we reach the next opcode */
          next_IP = CUR.IP + CUR.length;
          while ( exc->IP != next_IP )
          {
            if ( ( error = RunIns2( exc ) ) )
              goto LErrorLabel_;
          }
        }
        oldch = ch;
        break;

      /* Step into */
      case 's':
        if ( exc->IP < exc->codeSize )

      Step_into:
          if ( ( error = RunIns2( exc ) ) )
            goto LErrorLabel_;
        oldch = ch;
        break;

      default:
        PTRACE0(( "unknown command. Press ? for help\n" ));
        oldch = '\0';
      }

      for ( A = 0; A < pts.n_points; A++ )
      {
        diff = 0;
        if ( save.org[A].x != pts.org[A].x ) diff |= 1;
        if ( save.org[A].y != pts.org[A].y ) diff |= 2;
        if ( save.cur[A].x != pts.cur[A].x ) diff |= 4;
        if ( save.cur[A].y != pts.cur[A].y ) diff |= 8;
        if ( save.touch[A] != pts.touch[A] ) diff |= 16;

        if ( diff )
        {
          PTRACE0(( "%02hx  ", A ));

          if ( diff & 16 ) temp = "(%01hx)"; else temp = " %01hx ";
          PTRACE0(( temp, save.touch[A] & 7 ));

          if ( diff & 1 ) temp = "(%08lx)"; else temp = " %08lx ";
          PTRACE0(( temp, save.org[A].x ));

          if ( diff & 2 ) temp = "(%08lx)"; else temp = " %08lx ";
          PTRACE0(( temp, save.org[A].y ));

          if ( diff & 4 ) temp = "(%08lx)"; else temp = " %08lx ";
          PTRACE0(( temp, save.cur[A].x ));

          if ( diff & 8 ) temp = "(%08lx)"; else temp = " %08lx ";
          PTRACE0(( temp, save.cur[A].y ));

          PTRACE0(( "\n" ));

          PTRACE0(( "%02hx  ", A ));

          if ( diff & 16 ) temp = "[%01hx]"; else temp = " %01hx ";
          PTRACE0(( temp, pts.touch[A] & 7 ));

          if ( diff & 1 ) temp = "[%08lx]"; else temp = " %08lx ";
          PTRACE0(( temp, pts.org[A].x ));

          if ( diff & 2 ) temp = "[%08lx]"; else temp = " %08lx ";
          PTRACE0(( temp, pts.org[A].y ));

          if ( diff & 4 ) temp = "[%08lx]"; else temp = " %08lx ";
          PTRACE0(( temp, pts.cur[A].x ));

          if ( diff & 8 ) temp = "[%08lx]"; else temp = " %08lx ";
          PTRACE0(( temp, pts.cur[A].y ));

          PTRACE0(( "\n\n" ));
        }
      }
    } while ( TRUE );

  LErrorLabel_:

    return error;
  }

#endif /* DEBUG_INTERPRETER */


#endif /* TT_CONFIG_OPTION_NO_INTERPRETER */

/* END */
