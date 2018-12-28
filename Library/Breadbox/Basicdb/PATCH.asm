COMMENT @*******************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      Generic Database System
  MODULE:       Basic Database System
  FILE:         patch.asm

  AUTHOR:       Gerd Boerrigter

  $Header: $

  DESCRIPTION:
    This file contains corrections for C stubs messed up by GeoWorks.
    Currently:
    - ElementArray... : C stubs don't support variable lenght elements.

  REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-03-17  GerdB     Initial version.

***************************************************************************@

include geos.def
include heap.def
include chunkarr.def

SetGeosConvention

global  P_ELEMENTARRAYADDELEMENT:far
global  P_ELEMENTARRAYTOKENTOUSEDINDEX:far


PatchCode   segment resource ;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    P_ElementArrayAddElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:
    Patch to add support for variable lenght elements.

    Note: !!! Does not support callback now !!!


PASS: (on stack)
      optr  arr
      fptr  element
      word  size      !NEW!
      word  cbData
      fptr  callback

RETURN:

REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-03-17  GerdB     Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
P_ELEMENTARRAYADDELEMENT proc far   arr:optr,
                                    element:fptr, elemSize:word,
                                    cbData:word, callback:fptr
        uses    si,di,ds
        .enter

    ;
    ;  Move the parameters into registers.
    ;
        movdw   bxsi, arr
        call    MemDerefDS
        movdw   cxdx, element
        mov     ax, elemSize
        movdw   bxdi, callback
        mov     bp, cbData

        call    ElementArrayAddElement

        .leave
        ret

P_ELEMENTARRAYADDELEMENT  endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    P_ElementArrayTokenToUsedIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:
    Patch.

    Note: !!! Does not support callback now !!!


PASS:

RETURN:

REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-03-17  GerdB     Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
P_ELEMENTARRAYTOKENTOUSEDINDEX proc far   arr:optr,
                                    token:word,
                                    cbData:dword, callback:fptr
        uses    si,di,ds
        .enter

    ;
    ;  Move the parameters into registers.
    ;
        movdw   bxsi, arr
        call    MemDerefDS
        mov     ax, token
        movdw   bxdi, callback
        movdw   cxdx, cbData

        call    ElementArrayTokenToUsedIndex

        .leave
        ret

P_ELEMENTARRAYTOKENTOUSEDINDEX  endp

PatchCode   ends

SetDefaultConvention


;