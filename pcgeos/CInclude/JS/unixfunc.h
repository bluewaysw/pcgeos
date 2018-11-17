/* unixfunc.h - Needed functions/includes for Unix
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

#if defined(__JSE_UNIX__) && !defined(__DJGPP__)
#include <errno.h>


#if !defined(EXIT_FAILURE) && !defined(_AIX) && !defined(__osf__)
#  define EXIT_FAILURE 1
#  define EXIT_SUCCESS 0
#endif

#include <time.h>

#if defined(__sun__) && !defined(CLOCKS_PER_SEC)
#  define CLOCKS_PER_SEC 100
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__sun__)
   double difftime(time_t t1,time_t t2);
#endif

#ifndef _MAX_PATH
#  define _MAX_PATH 1024
#endif
#ifndef _MAX_EXT
#  define _MAX_EXT 256
#endif

int tty_cbreak(int fd);
int tty_reset(int fd);

int getch(void);
int getche(void);
int kbhit(void);

char *get_termcap(char *str);
void termcap_print(char *str);

int MakeFullPath(char *buffer,const char *path,unsigned int buflen);

#ifdef __cplusplus
};
#endif

#endif
