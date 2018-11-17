/* sefmtio.h Copyright
 *
 * Support functions for printf and scanf
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

#if !defined(__FMT_IO_H)
#define  __FMT_IO_H
#ifdef __cplusplus
   extern "C" {
#endif


#if defined(__JSE_UNIX__)
#  include "clib/sestdarg.h"
#elif defined(__JSE_MAC__)
#  include "sestdarg.h"
#elif defined(__JSE_390__)
#  include "SESTDARH"
#else
#  include "clib\sestdarg.h"
#endif

#if   defined(JSE_CLIB_PRINTF)    || \
      defined(JSE_CLIB_FPRINTF)   || \
      defined(JSE_CLIB_VPRINTF)   || \
      defined(JSE_CLIB_SPRINTF)   || \
      defined(JSE_CLIB_VSPRINTF)  || \
      defined(JSE_CLIB_RVSPRINTF) || \
      defined(JSE_CLIB_SYSTEM)    || \
      defined(JSE_CLIB_FSCANF)    || \
      defined(JSE_CLIB_VFSCANF)   || \
      defined(JSE_CLIB_SCANF)     || \
      defined(JSE_CLIB_VSCANF)    || \
      defined(JSE_CLIB_SSCANF)    || \
      defined(JSE_CLIB_VSSCANF)

struct FmtIO {
   const jsecharptr InitialFormatString;
   jsecharptr pFormat; /* reallocated version of format so match jse to underlying compiler library */
   struct VariableArgList *VList;
   uint NextFormatOffset;
   struct VariableArgs variableargs;
};

void NEAR_CALL fmtioTerm(struct FmtIO *This);

#endif

#if   defined(JSE_CLIB_PRINTF)    || \
      defined(JSE_CLIB_FPRINTF)   || \
      defined(JSE_CLIB_VPRINTF)   || \
      defined(JSE_CLIB_SPRINTF)   || \
      defined(JSE_CLIB_VSPRINTF)  || \
      defined(JSE_CLIB_RVSPRINTF) || \
      defined(JSE_CLIB_SYSTEM)

struct xPrintF {
   struct FmtIO fmtio;
   size_t space_needed;
};

void NEAR_CALL xprintfInit(struct xPrintF *This,jseContext jsecontext,uint FormatOffset,jsebool UseVaList,jsebool *Success);
#define xprintfTerm(THIS)  fmtioTerm(&((THIS)->fmtio))
/*ulong NEAR_CALL xprintfMaxNeededSize(struct xPrintF *This); */
   /* if !Success then error message already printed and context flag already set */
#endif

#if   defined(JSE_CLIB_FSCANF)    || \
      defined(JSE_CLIB_VFSCANF)   || \
      defined(JSE_CLIB_SCANF)     || \
      defined(JSE_CLIB_VSCANF)    || \
      defined(JSE_CLIB_SSCANF)    || \
      defined(JSE_CLIB_VSSCANF)

struct xScanF {
   struct FmtIO fmtio;
};

void xscanfInit(struct xScanF *This,jseContext jsecontext,uint FormatOffset,jsebool UseVaList,jsebool *Success);
   /* if !Success then error message already printed and context flag already set */
#define xscanfTerm(THIS)  fmtioTerm(&((THIS)->fmtio))

#endif

#ifdef __cplusplus
}
#endif
#endif
