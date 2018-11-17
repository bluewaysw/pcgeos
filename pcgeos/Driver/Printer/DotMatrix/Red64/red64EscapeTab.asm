
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         redwood print driver
FILE:           red64EscapeTab.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    8/93          Initial revision


DESCRIPTION:
        This file contains jumptables to the ESCAPE routines

        $Id: red64EscapeTab.asm,v 1.1 97/04/18 11:55:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------------------------------------------
;       Escape codes supported and routine table
;--------------------------------------------------------------------------

escCodes        label   word            ; escape codes supported
		word	DR_PRINT_ESC_INIT_PRINT_ENGINE
                word    DR_PRINT_ESC_SET_TOD
		word	DR_PRINT_ESC_CAP_HEAD
		word	DR_PRINT_ESC_CLEAN_HEAD
		word	DR_PRINT_ESC_GET_ERRORS
		word	DR_PRINT_ESC_WAIT_FOR_MECH
		word	DR_PRINT_ESC_PARK_HEAD
		word	DR_PRINT_ESC_MOVE_IN_X_ONLY
		word	DR_PRINT_ESC_MOVE_IN_Y_ONLY
		word	DR_PRINT_ESC_INSERT_PAPER
		word	DR_PRINT_ESC_EJECT_PAPER
		word	DR_PRINT_ESC_GET_JOB_STATUS

NUM_ESC_ENTRIES equ     ($ - escCodes)/2


escHanJumpTable label   word
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode
                hptr    handle  CommonCode

escOffJumpTable label   word
                word    offset  PrintInitPrintEngine
                word    offset  PrintSetTOD
                word    offset  PrintCapHead
		word    offset  PrintCleanHead
		word    offset  PrintGetErrors
		word    offset  PrintWaitForMechanism
		word    offset  PrintParkHead
		word    offset  PrintMoveInXOnly
		word    offset  PrintMoveInYOnly
		word    offset  PrintInsertPaper
		word    offset  PrintEjectPaper
		word    offset  PrintGetJobStatus


