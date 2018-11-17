/* DirParts.h     Find parts of a directory specification
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

#ifndef _DIRPARTS_H
#define _DIRPARTS_H

#if defined (__JSE_GEOS__)
#include <Ansi/string.h>
#endif
#include "jsetypes.h"

#ifdef __cplusplus
extern "C" {
#endif

void FileNameParts(const jsecharptr const FileName,
                   jsecharptr *dir,  uint *dirlen,
                   jsecharptr *name, uint *namelen,
                   jsecharptr *ext,  uint *extlen);

#ifdef __cplusplus
}
#endif

#endif
