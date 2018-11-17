/* CmdLine.h   Parse command line into source and parameters
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

#if !defined(_CMDLINE_H)
#define _CMDLINE_H
#ifdef __cplusplus
   extern "C" {
#endif

void ParseIntoSourcefileAndSourcetext(jseContext jsecontext,jseFileFindFunc FileFindFunc,
                                      const jsecharptr CmdLine,jsecharptr *Sourcefile,
                                      jsecharptr *Sourcetext);
   /* call this function when you just have a command line and are not sure which part is the
    * source file and which part are the parameters to the source file, or if there's no
    * source file at all.  On Return *Sourcefile will be set to allocated source file name or NULL
    * if no source file, and *Sourcetext will be set to the rest of the command line.  It
    * is up to the caller to free these variable when done.  This function does not claim
    * to be perfect.
    */

#ifdef __cplusplus
}
#endif
#endif
