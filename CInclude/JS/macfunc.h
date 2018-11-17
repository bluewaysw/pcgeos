/* macfunc.h - Needed functions for the Macintosh
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

#if defined(__JSE_MAC__)  && !defined(_MAC_FUNC_H)
#define _MAC_FUNC_H
#ifdef __cplusplus
   extern "C" {
#endif

#include <files.h>
#include <types.h>
#if defined(_MSC_VER)
  #include <macos\windows.h>
  #include <macname1.h>
  #include <macname2.h>
#endif
#if defined(__MWERKS__)
  #include <windows.h>
  #include <events.h>
  #include <controls.h>
#endif
#include <textedit.h>

#define _MAX_EXT 256

jsecharptr GetExecutablePath( void );
const jsecharptr MakeCompletePath( jseContext jsecontext, const jsecharptr partial );
jsebool isFullPath( const jsecharptr path );

pascal OSErr FSSpecToFullPath(const FSSpec *spec, short length, jsecharptr fullPath);

typedef void (*IterateFilterProcPtr) (const CInfoPBRec * const cpbPtr,
                                      Boolean *quitFlag,
                                      void *yourDataPtr);

/* Directory functions ( From MoreFiles ) */
OSErr IterateDirectory(short vRefNum,
                       long dirID,
                       StringPtr name,
                       unsigned short maxLevels,
                       IterateFilterProcPtr iterateFilter,
                       void *yourDataPtr);
OSErr GetDirectoryID(short vRefNum,
                     long dirID,
                     StringPtr name,
                     long *theDirID,
                     Boolean *isDirectory);
#define CallIterateFilterProc(userRoutine, cpbPtr, quitFlag, yourDataPtr) \
           (*(userRoutine))((cpbPtr), (quitFlag), (yourDataPtr))

struct MacTextBox {
  TEHandle      textBox;
  WindowPtr     window;
  ControlHandle OKButton;
};

struct MacTextBox * NewMacTextBox();
void DeleteMacTextBox( struct MacTextBox * This );
void MacTextBoxSet( struct MacTextBox * This, const jsecharptr message );
void MacTextBoxShow( struct MacTextBox * This, void (*eventHandler)(WindowPtr window, EventRecord * event));
#define  MacTextBoxIsValid( This )   \
   ( (This)->window != NULL && (This)->textBox != NULL && (This)->OKButton != NULL )
void  DoMacTextBox( const jsecharptr message, void (*eventHandler)(WindowPtr window, EventRecord * event));

#ifdef __cplusplus
}
#endif
#endif /* __JSE_MAC__ && !_MAC_FUNC_H */
