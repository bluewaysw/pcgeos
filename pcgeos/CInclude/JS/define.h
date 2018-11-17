/* Define.h    Handle all the #define statements coming
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

#if !defined(_DEFINE_H) && defined(JSE_DEFINE) && (0!=JSE_DEFINE)
#define _DEFINE_H

struct Link
{
   jsecharptr Find;
   jsecharptr Replace;
};

struct Define
{
   /* A sorted array of links */
   struct Link *links;
   uint linksUsed,linksAlloced;

   struct Define *Parent;
};

struct Define * defineNew(struct Define *Parent);
void defineDelete(struct Define *);
const jsecharptr defineFindReplacement(struct Define *def,const jsecharptr FindString);
   /* search here or in parents */
jsebool defineProcessSourceStatement(struct Source **source,struct Call *call);
   /* if error then print error and return False, else return True */

#endif
