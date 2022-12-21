/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttwidths.h
 *
 * AUTHOR:	  Jirka Kunze: December 20 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	20/12/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_GEN_WIDTHS.
 ***********************************************************************/

#include "ttwidths.h"
#include "../FreeType/ftxkern.h"


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void _pascal TrueType_Gen_Widths( )
{
        word            numKernPairs;
        word            numCharacters;

        //Anzahl KernPairs ermitteln
        //Anzahl der Zeichen ermitteln


}


/********************************************************************
 *                      GenNumKernPairs
 ********************************************************************
 * SYNOPSIS:	  Gets number of kerning pairs.
 * 
 * PARAMETERS:    TT_Face       Face from which the number of kerning 
 *                              pairs is to be determined.
 * 
 * RETURNS:       word          number of kerning pairs
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      A TrueType font usually has a larger number of 
 *                characters than are used in FreeGEOS. Therefore, the
 *                kerning pairs must be filtered so that only pairs 
 *                containing characters from the FreeGEOS character 
 *                set are delivered.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

word GetNumKernPairs( TT_Face face )
{
        TT_Kerning      directory;

        //TODO: implement

        return 0;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void ConvertHeader()
{

}


/********************************************************************
 *                      ConvertKernPairs
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void ConvertKernPairs()
{

}


/********************************************************************
 *                      CalcTransform
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void CalcTransform()
{

}


/********************************************************************
 *                      CalcRoutines
 ********************************************************************
 * SYNOPSIS:	  
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *******************************************************************/

void CalcRoutines()
{

}



void AllocFontBlock( word additionSpaceInBlock,
                     word numOfCharacters,
                     word numOf)
{

        /* Geamtgröße berechnen */


        /* wenn alter Block ReAlloc sonst Alloc */


   /****
    ontAllocFontBlock	proc	near
	uses	ax, cx, dx
	.enter

	shl	ax, 1
	shl	ax, 1				;ax <- # kern pairs * 4
	add	ax, bx				;ax <- added additional space
        --> ax = kernpairs * 4  --> 4 Byte je Kernpair

	mov	bx, di				;bx <- handle or 0
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable cx, dx			;cx == # chars * 8 (or *6)
        --> cx = characters * 6 or 8
	add	ax, cx				;ax <- bytes for ptrs+driver
	add	ax, size FontBuf - size CharTableEntry

        size = sizeOf(FontBuf) +
               #kernPais * 4   +
               #chars * 6 or 8 +
               additinal space
	mov	cx, mask HF_SWAPABLE \
		or mask HF_SHARABLE \
		or mask HF_DISCARDABLE \
		or ((mask HAF_NO_ERR) \
		or (mask HAF_LOCK)) shl 8
	push	ax				;save size
	tst	bx				;test for handle passed
	jne	oldBlock			;branch handle passed
	mov	bx, FONT_MAN_ID			;cx <- make font manager owner
	call	MemAllocSetOwner		;allocate for new pointsize
	;
	; P the new block handle, as fonts require exclusive access
	;
	call	HandleP
afterAlloc:

	mov	es, ax				;es <- seg addr of font
	pop	es:FB_dataSize			;save size in bytes

	.leave
	ret

oldBlock:
	call	MemReAlloc			;reallocate font block
	jmp	afterAlloc
FontAllocFontBlock	endp
    ****/     
}


