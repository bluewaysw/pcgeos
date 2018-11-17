/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		lzw1.c

AUTHOR:		Maryann Simmons, Feb 13, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/13/92   	Initial version.

DESCRIPTION:
	

	$Id: lzw1.c,v 1.1 97/04/07 11:27:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/




/*MS-Idont know why this is here(also in lzw.c???????
  or what these parameters are supposed to do
int 	
LzwDeOpen (dwMaxOutBytes, phTable, phExpCodesBuf)
   {
     DWORD dwMaxOutBytes;
     
   WORD   tbytes = sizeof(TREENODE) * MAXTABENTRIES;
   register WORD	nRoots = 1<<CHARBITS;
   register WORD	ii;
   LPTREENODE	lpNode=NULL;
			
  
   lpNode = (LPTREENODE)_fmalloc(tbytes);

   if (!lpNode)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   // allocate the string table
   // useful to avoid special case for <old> 

   (lpNode + CLEARCODE)->StringLength = 1;	

   for (ii = 0; ii < nRoots; ii++, lpNode++) 
	    {
	    lpNode->Suffix = (BYTE)ii;
	    lpNode->StringLength = 1;
	    lpNode->Parent = MAXWORD;	// signals the top of the tree 
	    }

		
   err=LzwProcNextCode(lpNode);

   cu0:

   if (lpNode)             // release memory used for tree table
       _ffree(lpNode);


   return err;
   }


HSI_ERROR_CODE
LzwProcNextCode(LPTREENODE lpNode)
   {
   WORD    NextOne = EOICODE + 1;
   static  BYTE    b;
   short   err=0;
   WORD    bcnt=0;
   WORD	BitsLeft = 16;
   register WORD	diff;
   register WORD	Code;
   register WORD	Mask;
   WORD	ComprSize;
   WORD	NextBoundary;

   ComprSize = CHARBITS + 1;
   NextBoundary = 1 << ComprSize;
   Mask = CalcMask(ComprSize);
		
   do {
	    // There should be a better apprach to get the next code!!!

       n=fread(&Code,sizeof(WORD),1,Infile);
       if (n==0) break;    // all done

	    if ( BitsLeft > ComprSize ) 
		    {
		    BitsLeft -= ComprSize;   // set and stay in same word 
           Code = (Word >> BitsLeft) & Mask;
		    } 
	    else 
	    if (BitsLeft < ComprSize) 
		    {
		    // Code is across a word boundary 
		    diff = ComprSize - BitsLeft;
		    Code = (Word << diff) & Mask;
           n=fread(&Word,sizeof(WORD),1,Infile);     // get next byte
           bcnt+=2;
		    BitsLeft = 16 - diff;
		    Code |= (Code >> BitsLeft);
		    } 
	    else 
		    {	
		    // set and move on to the next word 
		    Code = Code & Mask;
           bcnt+=2;
		    BitsLeft = 16;
		    }

       err=LzwDecodeOneByte(Code,lpNode);
       if (err) goto cu0;

	    if (Code == CLEARCODE) 	   // check for CLEAR code 
		    {
		    NextOne = EOICODE + 1;
		    ComprSize = CHARBITS + 1;
		    NextBoundary = 1 << ComprSize;
		    Mask = CalcMask(ComprSize);
		    }	
	    else // if at bit boundary, adjust compression size 
	    if (++NextOne == NextBoundary) 
		    {
		    ComprSize++;

		    if (ComprSize > MAXCODEWIDTH) 
			    {
			    err = IE_BUG;
			    goto cu2;
			    }

		    NextBoundary <<= 1;
		    Mask = CalcMask(ComprSize);
		    }
	    } 
   while (Code != EOICODE);
		

   cu0:

   return err;
   }



int
LzwDecodeOneByte(WORD Code, LPTREENODE lpNode)
   {
   short err=0;

	if (Code == CLEARCODE) 
	    {
	    Empty = EOICODE + 1;	    // do the clear
	    Old = Code;
	    FirstChar = (BYTE)Code;

       err=WirteByte(Code,1);
       if (err) goto cu0;

       goto cu0;
   	}  // end of clear-handler 

	if (Code < Empty) 
	    {
	    StringToWrite = Code;

       // Old to Code, 5-5, 3pm 
	    OutStringLength = (lpNode + Code)->StringLength;
	    lpUnChunk += OutStringLength;
	    lpOutPtr = lpUnChunk;
	    }
	else 
	if (Code == Empty) 
	    {
	    StringToWrite = Old;
	    OutStringLength = (lpNode + Old)->StringLength + 1;
	    lpUnChunk += OutStringLength;
	    lpOutPtr = lpUnChunk;
	    *--lpOutPtr = FirstChar;
	    } 
	else 
	    {
	    err = IE_BUG;
	    goto cu0;
	    }
		
	// write out the rest of the string, by walking up the tree	 
	{
	register LPTREENODE	lpNode1;
	register WORD		TabIndex = StringToWrite;
	register LPBYTE		lpOutPtr2;

	lpOutPtr2 = lpOutPtr;

	do {
	    lpNode1 = lpNode + TabIndex;
	    *--lpOutPtr = lpNode1->Suffix;
	    TabIndex = lpNode1->Parent;
	    } while (TabIndex != MAXWORD);

	lpOutPtr = lpOutPtr2;
				
	// keep the first char around, so that when we need
	// the first char of <old>, it will be available
	
	FirstChar = lpNode1->Suffix;
	}

	// add the correct entry to our table 
	{
	register LPTREENODE	lpNode1;
				
	lpNode1 = lpNode + Empty++;		// our new table entry 
	lpNode1->Suffix = FirstChar;
	lpNode1->StringLength = (lpNode + Old)->StringLength + 1;
	lpNode1->Parent = Old;			// parent is always Old 

	} // end of entry-adding 
	
	// <old> = <code> 
	Old = Code;
			
	// check for overflow 

	if (Empty >= MAXTABENTRIES) 
	    {
	    err = HSI_EC_INVALIDFILE;
	    goto cu0;
	    }

   cu0:

   return err;
   }



*/
