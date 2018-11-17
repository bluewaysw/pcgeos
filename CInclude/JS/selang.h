/* selang.h   Copyright 1998 Nombas, Inc.  All rights reserved
 *
 * Header file for the language pseudo-library
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

#if defined(JSE_LANG_ANY) && !defined(__SELANG_H)
#  define __SELANG_H

#  ifdef __cplusplus
   extern "C" {
#  endif

void NEAR_CALL InitializeLibrary_Lang_Conversion(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Lang_Misc(jseContext jsecontext);

jsebool LoadLibrary_Lang(jseContext jsecontext);

#  ifdef __cplusplus
   }
#  endif

#endif /* JSE_LANG_ANY && !__SELANG_H */
