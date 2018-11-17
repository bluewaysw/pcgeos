
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common print driver tables
FILE:		printcom9Tables.asm

AUTHOR:		Jim DeFrisco, 1 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		initial 2.0 version.


DESCRIPTION:
	This file contains printer jump tables. The escape jump tables
	are in the printer - specific tables files.
		
	$Id: printcomTables.asm,v 1.1 97/04/18 11:50:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------------------------------------------
;	Routines found in Entry module (FIXED)
;--------------------------------------------------------------------------

residentJumpTable label	word
		word	offset PrintInit		; in xxxAdmin.asm
		word	offset PrintExit		; in xxxAdmin.asm
		word	offset PrintSuspend		; in printcomEntry.asm
		word	offset PrintUnsuspend		; in printcomEntry.asm
		word	offset PrintTestDevice		; in printcomInfo.asm
		word	offset PrintSetDevice		; in printcomInfo.asm
		word	offset PrintGetDriverInfo	; in printcomInfo.asm
		word	offset PrintDeviceInfo		; in printcomInfo.asm
		word	offset PrintSetMode		; in printcomInfo.asm
		word	offset PrintSetStream		; in printcomInfo.asm
		word	offset PrintHomeCursor		; in printcomInfo.asm



;--------------------------------------------------------------------------
;	Routines found in CommonCode module
;--------------------------------------------------------------------------

modHanJumpTable hptr		\
		handle	PrintGetCursor,		 ; DR_PRINT_GET_CURSOR
		handle	PrintSetCursor,		 ; DR_PRINT_SET_CURSOR
		handle	PrintGetLineSpacing, 	 ; DR_PRINT_GET_LINE_SPACING
		handle	PrintSetLineSpacing,	 ; DR_PRINT_SET_LINE_SPACING
		handle	PrintSetFont,		 ; DR_PRINT_SET_FONT         
		handle	PrintGetColorFormat,	 ; DR_PRINT_GET_COLOR_FORMAT 
		handle	PrintSetColor,		 ; DR_PRINT_SET_COLOR        
		handle	PrintGetStyles, 		 ; DR_PRINT_GET_STYLES       
		handle	PrintSetStyles,		 ; DR_PRINT_SET_STYLES       
		handle	PrintTestStyles,	 ; DR_PRINT_TEST_STYLES      
		handle	PrintText,		 ; DR_PRINT_TEXT             
		handle	PrintRaw,		 ; DR_PRINT_RAW              
		handle	PrintStyleRun,		 ; DR_PRINT_STYLE_RUN        
						                             
		handle	PrintSwath,		 ; DR_PRINT_SWATH            
						                             
		handle	PrintStartPage,		 ; DR_PRINT_START_PAGE       
		handle	PrintEndPage,		 ; DR_PRINT_END_PAGE         
						                             
		handle	PrintGetPrintArea,	 ; DR_PRINT_GET_PRINT_AREA   
		handle	PrintGetMargins,	 ; DR_PRINT_GET_MARGINS      
		handle	PrintGetPaperPath,	 ; DR_PRINT_GET_PAPER_PATH   
		handle	PrintSetPaperPath,	 ; DR_PRINT_SET_PAPER_PATH   
						                             
		handle	PrintStartJob,		 ; DR_PRINT_START_JOB        
		handle	PrintEndJob,		 ; DR_PRINT_END_JOB          
						                             
		handle	PrintGetMainUI,		 ; DR_PRINT_GET_MAIN_UI      
		handle	PrintGetOptionsUI,	 ; DR_PRINT_GET_OPTIONS_UI   
		handle	PrintEvalUI,		 ; DR_PRINT_EVAL_UI          
		handle	PrintStuffUI		 ; DR_PRINT_STUFF_UI         

modOffJumpTable nptr	\
		offset	PrintGetCursor,
		offset	PrintSetCursor,
		offset	PrintGetLineSpacing ,
		offset	PrintSetLineSpacing,
		offset	PrintSetFont,
		offset	PrintGetColorFormat,
		offset	PrintSetColor,
		offset	PrintGetStyles ,
		offset	PrintSetStyles,
		offset	PrintTestStyles,
		offset	PrintText,
		offset	PrintRaw,
		offset	PrintStyleRun,

		offset	PrintSwath,

		offset	PrintStartPage,
		offset	PrintEndPage,

		offset	PrintGetPrintArea,
		offset	PrintGetMargins,
		offset	PrintGetPaperPath,
		offset	PrintSetPaperPath,

		offset	PrintStartJob,
		offset	PrintEndJob,

		offset	PrintGetMainUI,
		offset	PrintGetOptionsUI,
		offset	PrintEvalUI,
		offset	PrintStuffUI

.assert	length modOffJumpTable eq length modHanJumpTable
