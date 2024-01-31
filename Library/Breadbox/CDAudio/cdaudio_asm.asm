COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2024 -- All Rights Reserved

PROJECT:	MM-Projekt
MODULE:		(MS)CDEX CDRom Driver
FILE:		CDAudio_asm.asm

AUTHOR:		Falk Rehwagen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	27.01.24	Initial revision

ROUTINES:
	Name			Description
	----			-----------
        CDAGETNUMBEROFDRIVES    Get Number of CD drives.
        CDAGETVERSION           Get (MS)CDEX version number
        CDAGETDRIVELETTERS      Get CD drive letter
        CDACALLDEVICE           Call the CD device drivers Strategy

DESCRIPTION:
	The assembly wrapper code.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def

	SetGeosConvention

global CDAGETNUMBEROFDRIVES:far
global CDAGETVERSION:far
global CDAGETDRIVELETTERS:far
global CDACALLDEVICE:far

ResidentCode	segment	resource

CDAGETNUMBEROFDRIVES    proc far        segm: word, offs: word

        uses    si, di, ds
        .enter

        mov     di, 8
        mov     ds, segm
        mov     si, offs
        call    dword ptr ds:[si]

        .leave
        ret

CDAGETNUMBEROFDRIVES endp

CDAGETVERSION    proc far        segm: word, offs: word

        uses    si, di, ds
        .enter

        mov     di, 10
        mov     ds, segm
        mov     si, offs
        call    dword ptr ds:[si]

        .leave
        ret

CDAGETVERSION endp

CDACALLDEVICE    proc far        segm: word, offs: word, driveLetter: word,
                                 segmBuf: word, offsBuf: word
        uses    si, di, ds, ax, bx, cx
        .enter

        mov     di, 16
        mov     cl, driveLetter.low
        mov     ch,0x00
        mov     ds, segm
        mov     si, offs
        mov     ax, segmBuf
        mov     bx, offsBuf
        call    dword ptr ds:[si]

        .leave
        ret

CDACALLDEVICE endp

CDAGETDRIVELETTERS    proc far        segm: word, offs: word,
                                 segmBuf: word, offsBuf: word
        uses    si, di, ds, ax, bx
        .enter

        mov     di, 12
        mov     ds, segm
        mov     si, offs
        mov     ax, segmBuf
        mov     bx, offsBuf
        call    dword ptr ds:[si]

        .leave
        ret

CDAGETDRIVELETTERS   endp

ResidentCode		ends



