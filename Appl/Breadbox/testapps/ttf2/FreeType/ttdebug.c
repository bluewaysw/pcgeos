/* Simple debugging component. Temporary */

#include "ttdebug.h"
#include "tttables.h"
#include "ttobjs.h"


#ifdef DEBUG_LEVEL_TRACE
  char  tt_trace_levels[trace_max];
#endif

#if defined( DEBUG_LEVEL_ERROR ) || defined( DEBUG_LEVEL_TRACE )

#include <stdio.h>
#include <stdarg.h>
#include <string.h>


  static String  tempStr[128];

  static const String*  OpStr[256] =
  {
    "SVTCA y",       /* Set vectors to coordinate axis y    */
    "SVTCA x",       /* Set vectors to coordinate axis x    */
    "SPvTCA y",      /* Set Proj. vec. to coord. axis y     */
    "SPvTCA x",      /* Set Proj. vec. to coord. axis x     */
    "SFvTCA y",      /* Set Free. vec. to coord. axis y     */
    "SFvTCA x",      /* Set Free. vec. to coord. axis x     */
    "SPvTL //",      /* Set Proj. vec. parallel to segment  */
    "SPvTL +",       /* Set Proj. vec. normal to segment    */
    "SFvTL //",      /* Set Free. vec. parallel to segment  */
    "SFvTL +",       /* Set Free. vec. normal to segment    */
    "SPvFS",         /* Set Proj. vec. from stack           */
    "SFvFS",         /* Set Free. vec. from stack           */
    "GPV",           /* Get projection vector               */
    "GFV",           /* Get freedom vector                  */
    "SFvTPv",        /* Set free. vec. to proj. vec.        */
    "ISECT",         /* compute intersection                */

    "SRP0",          /* Set reference point 0               */
    "SRP1",          /* Set reference point 1               */
    "SRP2",          /* Set reference point 2               */
    "SZP0",          /* Set Zone Pointer 0                  */
    "SZP1",          /* Set Zone Pointer 1                  */
    "SZP2",          /* Set Zone Pointer 2                  */
    "SZPS",          /* Set all zone pointers               */
    "SLOOP",         /* Set loop counter                    */
    "RTG",           /* Round to Grid                       */
    "RTHG",          /* Round to Half-Grid                  */
    "SMD",           /* Set Minimum Distance                */
    "ELSE",          /* Else                                */
    "JMPR",          /* Jump Relative                       */
    "SCvTCi",        /* Set CVT                             */
    "SSwCi",         /*                                     */
    "SSW",           /*                                     */

    "DUP",
    "POP",
    "CLEAR",
    "SWAP",
    "DEPTH",
    "CINDEX",
    "MINDEX",
    "AlignPTS",
    "INS_$28",
    "UTP",
    "LOOPCALL",
    "CALL",
    "FDEF",
    "ENDF",
    "MDAP[-]",
    "MDAP[r]",

    "IUP[y]",
    "IUP[x]",
    "SHP[0]",
    "SHP[1]",
    "SHC[0]",
    "SHC[1]",
    "SHZ[0]",
    "SHZ[1]",
    "SHPIX",
    "IP",
    "MSIRP[0]",
    "MSIRP[1]",
    "AlignRP",
    "RTDG",
    "MIAP[-]",
    "MIAP[r]",

    "NPushB",
    "NPushW",
    "WS",
    "RS",
    "WCvtP",
    "RCvt",
    "GC[0]",
    "GC[1]",
    "SCFS",
    "MD[0]",
    "MD[1]",
    "MPPEM",
    "MPS",
    "FlipON",
    "FlipOFF",
    "DEBUG",

    "LT",
    "LTEQ",
    "GT",
    "GTEQ",
    "EQ",
    "NEQ",
    "ODD",
    "EVEN",
    "IF",
    "EIF",
    "AND",
    "OR",
    "NOT",
    "DeltaP1",
    "SDB",
    "SDS",

    "ADD",
    "SUB",
    "DIV",
    "MUL",
    "ABS",
    "NEG",
    "FLOOR",
    "CEILING",
    "ROUND[G]",
    "ROUND[B]",
    "ROUND[W]",
    "ROUND[?]",
    "NROUND[G]",
    "NROUND[B]",
    "NROUND[W]",
    "NROUND[?]",

    "WCvtF",
    "DeltaP2",
    "DeltaP3",
    "DeltaC1",
    "DeltaC2",
    "DeltaC3",
    "SROUND",
    "S45Round",
    "JROT",
    "JROF",
    "ROFF",
    "INS_$7B",
    "RUTG",
    "RDTG",
    "SANGW",
    "AA",

    "FlipPT",
    "FlipRgON",
    "FlipRgOFF",
    "INS_$83",
    "INS_$84",
    "ScanCTRL",
    "SDPVTL[0]",
    "SDPVTL[1]",
    "GetINFO",
    "IDEF",
    "ROLL",
    "MAX",
    "MIN",
    "ScanTYPE",
    "IntCTRL",
    "INS_$8F",

    "INS_$90",
    "INS_$91",
    "INS_$92",
    "INS_$93",
    "INS_$94",
    "INS_$95",
    "INS_$96",
    "INS_$97",
    "INS_$98",
    "INS_$99",
    "INS_$9A",
    "INS_$9B",
    "INS_$9C",
    "INS_$9D",
    "INS_$9E",
    "INS_$9F",

    "INS_$A0",
    "INS_$A1",
    "INS_$A2",
    "INS_$A3",
    "INS_$A4",
    "INS_$A5",
    "INS_$A6",
    "INS_$A7",
    "INS_$A8",
    "INS_$A9",
    "INS_$AA",
    "INS_$AB",
    "INS_$AC",
    "INS_$AD",
    "INS_$AE",
    "INS_$AF",

    "PushB[0]",
    "PushB[1]",
    "PushB[2]",
    "PushB[3]",
    "PushB[4]",
    "PushB[5]",
    "PushB[6]",
    "PushB[7]",
    "PushW[0]",
    "PushW[1]",
    "PushW[2]",
    "PushW[3]",
    "PushW[4]",
    "PushW[5]",
    "PushW[6]",
    "PushW[7]",

    "MDRP[G]",
    "MDRP[B]",
    "MDRP[W]",
    "MDRP[?]",
    "MDRP[rG]",
    "MDRP[rB]",
    "MDRP[rW]",
    "MDRP[r?]",
    "MDRP[mG]",
    "MDRP[mB]",
    "MDRP[mW]",
    "MDRP[m?]",
    "MDRP[mrG]",
    "MDRP[mrB]",
    "MDRP[mrW]",
    "MDRP[mr?]",
    "MDRP[pG]",
    "MDRP[pB]",

    "MDRP[pW]",
    "MDRP[p?]",
    "MDRP[prG]",
    "MDRP[prB]",
    "MDRP[prW]",
    "MDRP[pr?]",
    "MDRP[pmG]",
    "MDRP[pmB]",
    "MDRP[pmW]",
    "MDRP[pm?]",
    "MDRP[pmrG]",
    "MDRP[pmrB]",
    "MDRP[pmrW]",
    "MDRP[pmr?]",

    "MIRP[G]",
    "MIRP[B]",
    "MIRP[W]",
    "MIRP[?]",
    "MIRP[rG]",
    "MIRP[rB]",
    "MIRP[rW]",
    "MIRP[r?]",
    "MIRP[mG]",
    "MIRP[mB]",
    "MIRP[mW]",
    "MIRP[m?]",
    "MIRP[mrG]",
    "MIRP[mrB]",
    "MIRP[mrW]",
    "MIRP[mr?]",
    "MIRP[pG]",
    "MIRP[pB]",

    "MIRP[pW]",
    "MIRP[p?]",
    "MIRP[prG]",
    "MIRP[prB]",
    "MIRP[prW]",
    "MIRP[pr?]",
    "MIRP[pmG]",
    "MIRP[pmB]",
    "MIRP[pmW]",
    "MIRP[pm?]",
    "MIRP[pmrG]",
    "MIRP[pmrB]",
    "MIRP[pmrW]",
    "MIRP[pmr?]"
  };


  const String* Cur_U_Line( void* _exec )
  {
    String  s[32];

    Int  op, i, n;

    PExecution_Context  exec;


    exec = _exec;

    op = exec->code[exec->IP];

    sprintf( tempStr, "%s", OpStr[op] );

    if ( op == 0x40 )
    {
      n = exec->code[exec->IP + 1];
      sprintf( s, "(%d)", n );
      strncat( tempStr, s, 8 );

      if ( n > 20 ) n = 20; /* limit output */

      for ( i = 0; i < n; i++ )
      {
        sprintf( s, " $%02hx", exec->code[exec->IP + i + 2] );
        strncat( tempStr, s, 8 );
      }
    }
    else if ( op == 0x41 )
    {
      n = exec->code[exec->IP + 1];
      sprintf( s, "(%d)", n );
      strncat( tempStr, s, 8 );

      if ( n > 20 ) n = 20; /* limit output */

      for ( i = 0; i < n; i++ )
      {
        sprintf( s, " $%02hx%02hx", exec->code[exec->IP + i*2 + 2],
                                    exec->code[exec->IP + i*2 + 3] );
        strncat( tempStr, s, 8 );
      }
    }
    else if ( (op & 0xF8) == 0xB0 )
    {
      n = op - 0xB0;

      for ( i = 0; i <= n; i++ )
      {
        sprintf( s, " $%02hx", exec->code[exec->IP + i + 1] );
        strncat( tempStr, s, 8 );
      }
    }
    else if ( (op & 0xF8) == 0xB8 )
    {
      n = op-0xB8;

      for ( i = 0; i <= n; i++ )
      {
        sprintf( s, " $%02hx%02hx", exec->code[exec->IP + i*2 + 1],
                                    exec->code[exec->IP + i*2 + 2] );
        strncat( tempStr, s, 8 );
      }
    }

    return (String*)tempStr;
  }


  /* the Print() function is defined in ttconfig.h;  */
  /* it defaults to vprintf on systems which have it */

  void  TT_Message( const String*  fmt, ... )
  {
    va_list  ap;

    va_start( ap, fmt );
    Print( fmt, ap );
    va_end( ap );
  }


  void  TT_Panic( const String*  fmt, ... )
  {
    va_list  ap;

    va_start( ap, fmt );
    Print( fmt, ap );
    va_end( ap );

    exit( EXIT_FAILURE );
  }

#endif /* defined( DEBUG_LEVEL_ERROR ) || defined( DEBUG_LEVEL_TRACE ) */

#if defined( DEBUG_LEVEL_TRACE )

  /* use this function to set the values of tt_trace_levels */

  void  set_tt_trace_levels( int  index, char  value )
  {
    tt_trace_levels[index] = value;
  }

#endif

/* END */
