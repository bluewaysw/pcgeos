/***************************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      Generic Database System
  MODULE:       Basic Database System
  FILE:         patch.h

  AUTHOR:       Gerd Boerrigter

  $Header: /Home Bulletin Board/Library/BasicDB/PATCH.H 19    7/16/98 18:29 Gerdb $

  DESCRIPTION:
    This file contains prototypes for new C stubs.

  REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-03-17  GerdB     Initial version.

***************************************************************************/

#ifndef __PATCH_H
#define __PATCH_H

extern
word _pascal
P_ElementArrayAddElement( optr arr, void *element, word size,
                             word callbackData,
                             PCB(Boolean, callback, (void *elementToAdd,
                                                void *elementFromArray,
                                                dword valueForCallback)));

#define P_ElementArrayAddElementHandles(mh, ch, el, size, cbd, cb) \
                P_ElementArrayAddElement(ConstructOptr(mh, ch), el, size, cbd, cb)



extern
word _pascal
P_ElementArrayTokenToUsedIndex( optr arr, word token, dword callbackData,
                              PCB(Boolean, callback, (void *element,
                                                     dword cbData)));

#define P_ElementArrayTokenToUsedIndexHandles(mh, ch, in, cbd, cb) \
        P_ElementArrayTokenToUsedIndex(ConstructOptr(mh, ch), in, cbd, cb)


#endif /* __PATCH_H */
