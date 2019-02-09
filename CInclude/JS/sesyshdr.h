/* sesyshdr.h    Include all the system headers needed by any particular OS.
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

#ifndef __SYSHDRS_H
#  define __SYSHDRS_H

#if defined(__JSE_GEOS__)
#  include <geos.h>
#  include <system.h>
#  include <Ansi/stdio.h>
#  include <Ansi/assert.h>
#  include <math.h>
#  include <Ansi/string.h>
#  include <Ansi/stdlib.h>
#  include <Ansi/ctype.h>
#  include <geoMisc.h>

#  define EXIT_FAILURE	1
#  define EXIT_SUCCESS	0

#  define exit(p)

#  define max(a,b)    (((a) > (b)) ? (a) : (b))
#  define min(a,b)    (((a) < (b)) ? (a) : (b))

#else

#  if defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#    define INCLUDE_SHELLAPI_H
#    ifndef WIN32
#      define WIN32
#    endif
#    if !defined(__JSE_NUCLEUS__)
#      include <windows.h>
#    endif
#  endif

#  if !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#     include <assert.h>
#     include <stdio.h>
#  endif
#  include <stdlib.h>
#  include <stdarg.h>
#  include <string.h>
#  include <ctype.h>
#  if !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__) && !defined(__JSE_WINCE__)
#    include <time.h>
#  endif

#  if defined(__cplusplus) && !defined(__JSE_NWNLM__)
#    include <new.h>
#  endif

#  if !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__) && !defined(__JSE_IOS__)
#    include <math.h>
#  endif

#  if defined(__WATCOMC__) && !defined(__JSE_NWNLM__)
#    include <env.h>
#  endif

#  if defined(__JSE_UNIX__) && !defined(__JSE_IOS__)
#    include <stddef.h>
#  endif

#  if !defined(__JSE_CON32__) && !defined(__JSE_PSX__) \
   && !defined(__JSE_PALMOS__) && !defined(__JSE_WINCE__)
#    include <signal.h>
#  endif

#  if defined(__WATCOMC__)
#    include <malloc.h>
#  endif

#  if defined(__JSE_390__)
#     include <errno.h>
#     if !defined(_MAX_PATH)
#        define _MAX_PATH 1024
#     endif
#     if !defined(_MAX_EXT)
#        define _MAX_EXT 3
#     endif
#  endif

#  if defined(__DJGPP__)
#    include <errno.h>
#    include <limits.h>
#    define _MAX_PATH PATH_MAX
#    define _MAX_EXT  3
#  endif

#  if defined(__JSE_ECON32__)
#     define _MAX_PATH FILENAME_MAX
#  endif

#  if !defined(__JSE_MAC__) && !defined(__JSE_UNIX__) && !defined(__WILLOWS__) \
   && !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__) && !defined(__JSE_WINCE__) \
   && !defined(__JSE_390__)
#  if defined(__JSE_NWNLM__)
#     ifdef JSE_NLM_WATCOM_HEADERS
#        include <conio.h>
#     else
#        include <nwconio.h>
#     endif
#  else
#     include <conio.h>
#     include <process.h>
#     include <direct.h>
#  endif
#     if defined( _MSC_VER ) && _MSC_VER == 600
#        include <sys/types.h>
#     endif
#     include <sys/stat.h>
#  endif

#  if !defined(__JSE_UNIX__) && !defined(__JSE_MAC__) && !defined(_MSC_VER) \
   && !defined(__IBMCPP__) && !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__) \
   && !defined(__JSE_390__)
#     if !defined(__JSE_NWNLM__)
#        include <io.h>
#        include <mem.h>
#     endif
#  endif

#  if defined(_MSC_VER) && !defined(__JSE_WINCE__)
#    include <io.h>
#    include <memory.h>
#  endif

#  if defined(__IBMCPP__)
#    include <io.h>
#    include <memory.h>
#  endif

#  if defined(__BORLANDC__)
#    include <limits.h>
#  endif

#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__) || defined(__JSE_DOS32__) \
   || (defined(__JSE_WIN32__) && !defined(__JSE_WINCE__)) \
   || defined(__JSE_CON32__)
#    include <dos.h>
#  endif

#  if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#    define INCL_DOSDATETIME
#    define INCL_DOSERRORS
#    define INCL_DOSFILEMGR
#    define INCL_DOSMODULEMGR
#    define INCL_DOSPROCESS
#    define INCL_DOSSEMAPHORES
#    define INCL_DOSSESMGR
#    define INCL_ERRORS
#    define INCL_ORDINALS
#    define INCL_WINATOM
#    define INCL_WINSWITCHLIST
#    define INCL_DOSDEVICES
#    if defined(__JSE_OS2PM__)
#      define INCL_PM
#    else
#      define INCL_VIO
#      define INCL_KBD
#    endif
#    include <os2.h>
#    include <os2def.h>
#  endif

#  if defined(__JSE_NWNLM__)
#    include <sys\types.h>
#    include <sys\socket.h>
#    include <sys\time.h>
#    include <errno.h>
#    ifdef JSE_NLM_WATCOM_HEADERS
#       include <process.h>
#    else
#       include <nwtime.h>
#       include <nwerrno.h>
#       include <nwthread.h>
#       include <nwfattr.h>
#       include <nwadv.h>
#       include <dirent.h>
#    endif
#    include <sys\filio.h>
#    include <sys\ioctl.h>
#    include <limits.h>
#    ifndef JSE_NLM_WATCOM_HEADERS
#      include <nwmpk.h>
#    endif
#  endif

#  if defined(__JSE_UNIX__)
#     include <dirent.h>
#     include <sys/stat.h>
#     include <sys/time.h>
#     include <errno.h>
#     include <unistd.h>
#     include <termios.h>
#     include <pwd.h>
#     include <sys/types.h>
#     include <sys/wait.h>
#     if !defined(__DJGPP__)
#        include <sys/socket.h>
#        include <netdb.h>
#        include <netinet/in.h>
#     endif
#     if defined(__JSE_IOS__)
#        include "../../os/signal.h"
#     else
#        include <signal.h>
#     endif

/* Please stop adding the damn JSE_LINK #ifdef. Not only is it wrong
 * (you must check if defined before comparing it to a number), but
 * these files are needed anyway for the dynamic link stuff.
 */
#        if defined(__hpux__)
#           include <dl.h>
#        elif !defined(_AIX) && !defined(__DJGPP__) && !defined(__JSE_BEOS__)
#           include <dlfcn.h>
#        else
#           include "aixdlfcn.h"
#        endif

#     include <sys/file.h>

#     if !defined(__sun__)
#        include <sys/ioctl.h>
#     endif
#     if !defined(__DJGPP__) && !defined(__JSE_BEOS__)
#        include <arpa/inet.h>
#     endif

#     include <fcntl.h>

      /* this IS a char, it is compiler-defined. */
      extern char **environ; /* seems not correctly defined on every system. */
#  endif

#  if defined(__JSE_MAC__)
#    if defined(_MSC_VER)
#      include <sys\stat.h>
#    endif
#    if defined(__MWERKS__)
#      include <stat.h>
#      include <unistd.h>
#      include <sioux.h>
#      include <console.h>
#    endif
#    include <errno.h>
#  endif

#  if defined(__WATCOMC__)
#     include <unistd.h>
#  endif

#  if defined(__JSE_WIN16__)
#    include <commdlg.h>
#    include <toolhelp.h>
#    if defined(__WATCOM__)
#      include <i86.h>
#    endif
#    include <share.h>
#    include <stddef.h>
#    include <windowsx.h>
#    if defined(_MSC_VER) || defined(__BORLANDC__)
#      include <shellapi.h>
#    endif
#  endif

#  ifndef max
#    define max(a,b)            (((a) > (b)) ? (a) : (b))
#  endif
#  ifndef min
#    define min(a,b)            (((a) < (b)) ? (a) : (b))
#  endif
#endif

#endif
