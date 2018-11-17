/* jseValue.h  Simplified access to primitive variable data
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

#define JSEVAL_THISVAR        ((jseVariable)(-1))
#define JSEVAL_GLOBALVAR      ((jseVariable)NULL)
#define JSEVAL_FUNCPARM(PARM) ((jseVariable)(PARM+1))


void jseValPutNumber(jseContext jsecontext,jseVariable var,
                     const jsecharptr propname,jsenumber number);
   /* will set number; if variable does not exist then will
    * be created.  If variable is not a number type then it will
    * be made into a number type.
    */

jsenumber jseValGetNumber(jseContext jsecontext,jseVariable var,
                          const jsecharptr propname);
   /* will return a number, or jseNaN if number cannot be returned */
