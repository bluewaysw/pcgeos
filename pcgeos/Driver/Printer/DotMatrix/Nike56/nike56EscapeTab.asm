
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         Brother NIKE 56-jet print driver
FILE:           nike56EscapeTab.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94          Initial revision


DESCRIPTION:
        This file contains jumptables to the ESCAPE routines

        $Id: nike56EscapeTab.asm,v 1.1 97/04/18 11:55:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------------------------------------------
;       Escape codes supported and routine table
;--------------------------------------------------------------------------

escCodes        label   word            ; escape codes supported
		word	DR_PRINT_ESC_INIT_PRINT_ENGINE
		word	DR_PRINT_ESC_CAP_HEAD
		word	DR_PRINT_ESC_GET_ERRORS
		word	DR_PRINT_ESC_WAIT_FOR_MECH
		word	DR_PRINT_ESC_PARK_HEAD
		word	DR_PRINT_ESC_MOVE_IN_X_ONLY
		word	DR_PRINT_ESC_MOVE_IN_Y_ONLY
		word	DR_PRINT_ESC_INSERT_PAPER
		word	DR_PRINT_ESC_EJECT_PAPER
		word	DR_PRINT_ESC_GET_JOB_STATUS
		word	DR_PRINT_ESC_SET_JOB_STATUS
		word	DR_PRINT_ESC_PROCESS_ERRORS
		word	DR_PRINT_ESC_CLEAN_HEAD
		word	DR_PRINT_ESC_CHANGE_INK_CARTRIDGE

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
                hptr    handle  CommonCode
                hptr    handle  CommonCode

escOffJumpTable label   word
                word    offset  PrintInitPrintEngine
                word    offset  PrintCapHead
		word    offset  PrintGetErrors
		word    offset  PrintWaitForMechanism
		word    offset  PrintParkHead
		word    offset  PrintMoveInXOnly
		word    offset  PrintMoveInYOnly
		word    offset  PrintInsertPaper
		word    offset  PrintEjectPaper
		word    offset  PrintGetJobStatus
		word    offset  PrintSetJobStatus
		word    offset  PrintProcessErrors
		word	offset	PrintCleanPrintHead
		word	offset	PrintChangeInkCartridge
