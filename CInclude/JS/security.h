/* security.h - Secure-jse
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

#if !defined(_SECURITY_H) && defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
#define _SECURITY_H

struct Security
{
   /* the prev chain chains togethor all security structures in the
    * program so we can delete them all, it is in the call's global
    * section
    */
   struct Security *prev;

   /* Another chain, this one for a particular security chain
    * (i.e. the security functions in effect for a particular
    *  piece of code.)
    */
   struct Security *next;


   /* we keep two lists, functions that are to be accepted and
    * functions that must go through the guard. Since each is just
    * a pointer, it makes most sense to do dynamically allocated
    * arrays. I wouldn't expect more then 10 or 20 functions marked
    * in a particular security level. Allocating them in a linked
    * list makes no sense when each entry is 4 bytes, we will be
    * wasting about 3x as much space in overhead for the allocator.
    * I'll preallocate each to 50 entries - 400 bytes (2x200)
    * is no big deal, especially since it is likely to be only
    * one security structure for the whole program.
    */

   struct Function **acceptFuncs;
   MemCountUInt      acceptUsed,acceptAlloced;

   struct Function **guardFuncs;
   MemCountUInt      guardUsed,guardAlloced;


   hSEObject hPrivateVariable;

   hSEObject hjseSecurityGuard,hjseSecurityInit,hjseSecurityTerm;

   /* Set to true while interpreting the init function, then it is changed
    * to false so that the user cannot then change security.
    */
   jsebool changable;
};

jsebool NEAR_CALL checkSecurity(struct Call *call,rSEVar calling_var,
                                uword16 num_args);
jsebool NEAR_CALL setSecurity(struct Call *call);
void NEAR_CALL cleanupSecurity(struct Call *call);
void NEAR_CALL setupSecurity(struct Call *call);

#endif
