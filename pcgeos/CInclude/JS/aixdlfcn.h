/* aixdlfcn.h -- emulates the SunOS dlopen(), etc on AIX */

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

#if defined(_AIX)

/*
 * @(#)dlfcn.h 1.4 revision of 95/04/25  09:36:52
 * This is an unpublished work copyright (c) 1992 HELIOS Software GmbH
 * 30159 Hannover, Germany
 */

#ifndef __dlfcn_h__
#define __dlfcn_h__

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Mode flags for the dlopen routine.
 */
#define RTLD_LAZY 1  /* lazy function call binding */
#define RTLD_NOW  2  /* immediate function call binding */
#define RTLD_GLOBAL  0x100 /* allow symbols to be global */

/*
 * To be able to intialize, a library may provide a dl_info structure
 * that contains functions to be called to initialize and terminate.
 */
struct dl_info {
   void (*init)(void);
   void (*fini)(void);
};

#if __STDC__ || defined(_IBMR2)
/* This is an AIX system header, these things ARE 'char *',
 * it will be included by files that are not ScriptEase
 * files, so don't change them.
 */
void *dlopen(const char * path, int mode);
void *dlsym(void *handle, const char * symbol);
char * dlerror(void);
int dlclose(void *handle);
#else
void *dlopen();
void *dlsym();
jsecharptr dlerror();
int dlclose();
#endif

#ifdef __cplusplus
}
#endif

#endif /* __dlfcn_h__ */

#endif
