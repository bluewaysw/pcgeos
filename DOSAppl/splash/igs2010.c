
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) @company 1998.  All rights reserved.
	CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		igs2010.c

AUTHOR:		, Oct 01, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Todd    	10/01/98   	Initial version

DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <dos.h>
#include <alloc.h>
#include <stdio.h>
#include "card.h"
#include "igs_tbls.h"

#define	PRINT_DEBUG_INFO	FALSE



/* --- This is used to call video BIOS to set video mode --- */

#define	VIDEO_BIOS		0x10



#define	ALT_SELECT		0x12

#define	VIDEO_SCREEN_ON_OFF	0x36

#define	VGA_ENABLE_VIDEO 	0x00
#define	VGA_DISABLE_VIDEO	0x01



#define	VESA_BIOS_EXT		0x4F

#define	VESA_SET_MODE		0x02

/* CyberMode enum's */
#define	CM_640x440_8_TV		0x0039
/* VESAMode enum's */
#define	VM_640x480_8		0x0101



/* --- This is used to access TV control registers --- */
unsigned char far *bTVRegBase = (unsigned char far *) 0xB0000000L;
unsigned int far  *TVRegBase  = (unsigned int far *)  0xB0000000L;

/* --- This is used to access video memory --- */
unsigned char far *vidMemBase = (unsigned char far *) 0xA0000000L;
void EnableChip(void);
void InitChip(void);
int  DetectCRT(void);
void SetStandardReg(unsigned char *bPtr);
void SetExtReg(unsigned char *bPtr, int iCounter);
void SetPartExtReg(unsigned char *bPtr, int iCounter);
void SetRamDac(unsigned char *bPtr, int iCounter);
int  GetBpp(void);
void BypassMode(int iOnOff);
void ToggleClock(void);
void CardClearVMem(void);
int  GetVMemSize(void);
int  GetBusWidth(void);
void TurnOnBorder(char bR, char bG, char bB);


/*--- TV related routines ---*/
void SetTVReg(short *wPtr, int iCounter);
short ReadTVReg(short index);
void WriteTVReg(short index, short data);
void LockTVReg(void);
void UnlockTVReg(void);
void EnableTV(int iOnOff, int iTVType);
void TVOn(int iOnOff);
int  DetectTV(void);
void SetTVColor(void);
void SetInterpolation(int iOnOff);
void SetGenericReg(short wPort, char *bPtr, int iCounter);
void WaitCrtHSync(void);


/*--- Video memory detection ---*/
int  DetectVideoMemory(void);
void ResetSeq(void);
void SetBank(int iBankNum);
int  TestVMem(int iBankNum);

/*--- Video Drawing commands ---*/
void CardWriteScan(unsigned char *, unsigned int);
void DrawPixel(unsigned int, unsigned int, unsigned char);

/* Lovely, lovely globals */
char	bReg33, bReg3C;

#if 0


/***********************************************************************
 *				CardInit
 ***********************************************************************
 *
 * SYNOPSIS:	    Initialize the IGS 2010
 * CALLED BY:	    SPLASH.C
 * RETURN:	    0 on success, non-zero on failure
 * SIDE EFFECTS:    Lots.  Resets the card...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
int
CardInit(void)
{
	/* Nudge the chip to wake it up, and then put
	 * it in the predictable 640x480x8@60 mode...
	 */
	EnableChip();	   /* to wake up the chip */
	InitChip();	      /* initialize to default mode */

	/*
	 * Now, see if the board is happy
	 */
	if ( DetectVideoMemory() == -1) {
		return (-1);       /* problem with memory/card */
	};

	/*
	 * Save ext_reg_33 and ext_reg_3C so we
	 * can ensure the TV regs are only accessed
	 * when we want 'em to be.
	 */
	outportb(EXTINDEX, 0x33);
	bReg33 = inportb(EXTDATA);
	outportb(EXTINDEX, 0x3C);
	bReg3C = inportb(EXTDATA);

	/*
	 * All is well and good.
	 */
	return (0);
}	/* End of CardInit.	*/

/*--------------------------------------------------------------------
  EnableChip: Wake up the chip.
  In:	None
  Out:	All I/O registers are fully accessible.
	Video memory is not fully accessible yet (need to set mode).
  --------------------------------------------------------------------*/
void EnableChip()
{
	 outportb(PORT46E8, 0x18);	  /*46E8 is writeable only*/
	 outportb(PORT102,  0x01);	  /*102 is read-writeable*/
	 outportb(PORT46E8, 0x08);

	 outportb(EXTINDEX, 0x33);
	 outportb(EXTDATA,  0x10);	  /* enable banking frame buffer */

	 outportb(CRTINDEX, 0x1F);
	 outportb(CRTDATA,  0x03);	  /* to unlock CRT protection */
}
/*--------------------------------------------------------------------
  InitChip: To initialize the chip to be certain mode
  In:	None
  Out:	Chip is initialized to be 640x480x8 @60Hz.
	Video memory now is fully accessible as packed 8bpp mode.
  --------------------------------------------------------------------*/
void InitChip()
{
	 SetExtReg(ExtRegData, sizeof(ExtRegData)/2);
	 SetStandardReg(S640x480x60);
	 SetRamDac(RamDacData, sizeof(RamDacData)/3);

	 /*choose voltage reference*/
	 outportb(EXTINDEX, 0x56);
	 outportb(EXTDATA, 0x04);
	 outportb(RAMDACMASK, 0x04); 	  /*use VRef*/
	 outportb(EXTDATA, 0);
	 outportb(EXTINDEX, 0x56);
	 outportb(EXTDATA, 0x00);
}
/*-----------------------------------------------------------------------------
  DetectVideoMem: Auto-detect video memory bus width and size.
	  1. Detect Video Memory bus width (32 or 64 bits)
	  2. Detect Video Memory size (1, 2, or 4 MB)
  In:  None
  Out: return 0: success and set register 3CE_72 and 3CE_30 accordingly.
		 non-zero: fail. It means something is wrong with video memory
				 (memory chip defact or memory interface).
-----------------------------------------------------------------------------*/
int DetectVideoMemory(void)
{
	int i, iFlag;
	BYTE_ bData;

	/* 1. Detect Video Memory Bus width */

	bData = 0x05;
	outportb(EXTINDEX, 0x72);
	outportb(EXTDATA, bData);	 /*Temporarily force to be 64Bits/2MB*/
	outportb(EXTINDEX, 0x30);
	outportb(EXTDATA, bData & 0x03);

	ResetSeq();

	iFlag = 0;
	for (i=0; i<32; i++)	{ /*test total 32*64K - 2MB*/
		iFlag += TestVMem(i);
	}

	if (iFlag == 0) {
		bData = 0x06;
		outportb(EXTINDEX, 0x72);
		outportb(EXTDATA, bData);   /*it is 64 bit. Temporarily force to be 4MB*/
		outportb(EXTINDEX, 0x30);
		outportb(EXTDATA, bData & 0x03);
	} else {
		bData = 0x02;
		outportb(EXTINDEX, 0x72);
		outportb(EXTDATA, bData);   /*it is 32 bit. Temporarily force to be 4MB*/
		outportb(EXTINDEX, 0x30);
		outportb(EXTDATA, bData & 0x03);
	}

	/* 2. Detect Video Memory Size */

	ResetSeq();

	iFlag = 0;
	for (i=0; i<64; i++)	{  /*test total 64*64K - 4MB*/
		iFlag += TestVMem(i);
	}

	if (iFlag != 0) {
		outportb(EXTINDEX, 0x72);
		bData = (inportb(EXTDATA) & 0xFC) | 0x01;  /*force to be 2MB*/
		outportb(EXTDATA, bData);
		outportb(EXTINDEX, 0x30);
		outportb(EXTDATA, bData & 0x03);

		iFlag = 0;
		for (i=0; i<32; i++)	{  /*test total 32*64K - 2MB*/
			iFlag += TestVMem(i);
		}

		if (iFlag != 0) {
			bData = 0x00;
			outportb(EXTINDEX, 0x72);
			outportb(EXTDATA,  bData);/*force to be 1MB/32bits*/
			outportb(EXTINDEX, 0x30);
			outportb(EXTDATA, bData & 0x03);

			iFlag = 0;
			for (i=0; i<16; i++)	{  /*test total 16*64K - 1MB*/
				iFlag += TestVMem(i);
			}
		}
	 }

	 return iFlag;
}
/*-----------------------------------------------------------------------------
  ResetSeq: Reset sequencer.
  In:  None
  Out: None
-----------------------------------------------------------------------------*/
void ResetSeq(void)
{
	 outportb(SEQINDEX,0x00);
	 outportb(SEQDATA, 0x01);
	 outportb(SEQINDEX,0x00);
	 outportb(SEQDATA, 0x03);
}
/*-----------------------------------------------------------------------------
  TestVMem: To test 32 bytes video memory.
  In:  iBankNum: 0 - 63  (one bank = 64 KB, maximum 64 banks = 4 MB)
  Out: Return 0 if pass or non-zoro if fail
-----------------------------------------------------------------------------*/
int  TestVMem(int iBankNum)
{
	int i,iFlag;
	BYTE_ bData0, bData1;
	unsigned char far *fpTmp;

	iFlag = 0;
	fpTmp = vidMemBase;

	CardMapPage(iBankNum);

	bData0 = 0x55;
	bData1 = 0xAA;
	for (i=0; i<16; i++) {
		*fpTmp++ = bData0;
		*fpTmp++ = bData1;
	}

	fpTmp = vidMemBase;

	for (i=0; i<16; i++) {
		if ( (*fpTmp++ != bData0) || (*fpTmp++ != bData1) )
			iFlag = 1;
	}

	return iFlag;
}

#endif	/* if 0 */


/***********************************************************************
 *				CardGetMapSize
 ***********************************************************************
 *
 * SYNOPSIS:	    Return size of mapping windows
 * CALLED BY:	    INTERNAL
 * RETURN:	    64k
 * SIDE EFFECTS:    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
unsigned long
CardGetMapSize (void)
{
	/* One 64k segment */
	return (65536L);
}	/* End of CardGetMapSize.	*/

/***********************************************************************
 *				CardMapPage
 ***********************************************************************
 *
 * SYNOPSIS:	    Map in a particular video page
 * CALLED BY:	    GLOBAL
 * RETURN:	    fptr to base of page
 * SIDE EFFECTS:
 *                  Changes mapping of card
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
unsigned char far *
CardMapPage (int thePage)
{
	if ( thePage <= 0x00FF ) {
		outportb(EXTINDEX, 0x31);	/*write bank*/
		outportb(EXTDATA, thePage);

		outportb(EXTINDEX, 0x32);	/*read bank*/
		outportb(EXTDATA, thePage);
	} else {
		return (NULL);
	}
	return (vidMemBase);
}	/* End of CardMapPage.	*/

/***********************************************************************
 *				CardSetVideoMode
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
#if 0	/* Now we call video BIOS to set video mode */
void
CardSetVideoMode (void)
{
	SetStandardReg(S640x440x60_U);
	SetPartExtReg(E640x440x8x60_U, EXTPARTIALCOUNT);

	/*----------------------------------*\
	|*  TV Out Programming		*|
	\*----------------------------------*/

	EnableTV(ON, NTSC);

	SetTVReg(TV640x480x60_U, sizeof(TV640x480x60_U)/sizeof(TV640x480x60_U[0]));
	WriteTVReg(0xE468, ReadTVReg(0xE468) + 3);
	WriteTVReg(0xE46C, ReadTVReg(0xE46C) + 3);

	TVOn(ON);
	SetTVColor();
}	/* End of CardSetVideoMode.	*/
#endif	/* if 0 */

void
CardSetVideoMode (void)
{
	struct REGPACK preg = {(VESA_BIOS_EXT << 8) | VESA_SET_MODE};

	preg.r_bx = DetectCRT() ? VM_640x480_8 : CM_640x440_8_TV;
	intr(VIDEO_BIOS, &preg);
}	/* End of CardSetVideoMode.	*/

#if 0

/*--------------------------------------------------------------------
  SetStandardReg: Set standard VGA registers
  In:	bPtr - a BYTE_ pointer to an array of VGA register settings
  Out:	VGA registers are set
  --------------------------------------------------------------------*/
void SetStandardReg(unsigned char *bPtr)
{
	int i;

	/* 1. set sequencer reg */
	outportb(SEQINDEX, 0x00);
	outportb(SEQDATA , 0x00);		 /*seq clear*/

	for (i=0; i<SEQCOUNT; i++) {
		outportb(SEQINDEX, i+1);		 /*start from index 1*/
		outportb(SEQDATA , *bPtr++);
	}

	/* 2. set miscellaneous reg */
	outportb(MISCWRITE, *bPtr++);

	outportb(SEQINDEX, 0x00);
	outportb(SEQDATA , 0x03);		 /*seq normal operation*/

	/* 3. set CRT reg */
	outportb(CRTINDEX, 0x11);
	outportb(CRTDATA , 0x00);		 /*unlock CRT*/

	for (i=0; i<CRTCOUNT; i++) {
		outportb(CRTINDEX, i);
		outportb(CRTDATA , *bPtr++);
	}

	/* 4. set attribute reg */
	i = inportb(ATTRRESET);		     /*reset Attribute*/

	for (i=0; i<ATTRCOUNT; i++) {
		outportb(ATTRINDEX, i);
		outportb(ATTRDATAW, *bPtr++);
	}

	outportb(ATTRINDEX, i);		 /*normal case*/
	outportb(ATTRDATAW, 0x00);	 /*3c0_reg_14 is always 0*/

	outportb(ATTRINDEX, 0x20);		 /*turn on screen*/
	i = inportb(ATTRRESET);		     /*reset Attribute*/

	/* 5. set graphics reg */
	for (i=0; i<GRACOUNT; i++) {
		outportb(GRAINDEX, i);
		outportb(GRADATA , *bPtr++);
	}
}

/*--------------------------------------------------------------------
  SetExtReg: Set IGS extended registers
  In:	bPtr - a BYTE_ pointer to an array of IGS extended register settings
	iCounter - counter of the registers.
  Out:	Full IGS extended registers are set.
  --------------------------------------------------------------------*/
void SetExtReg(unsigned char *bPtr, int iCounter)
{
	int i;
	for (i=0; i<iCounter; i++) {
		outportb(EXTINDEX, *bPtr++);	 /*index*/
		outportb(EXTDATA,  *bPtr++);	 /*data*/
	}

	ToggleClock();	  /*to latch the clock value into working set*/
}
/*--------------------------------------------------------------------
  SetExtReg: Set IGS partial extended registers
  In:	bPtr - a BYTE_ pointer to an array of IGS extended register settings
			 and VGA CRT register 0x13.
	iCounter - a counter of the extended registers only.
  Out:	None
  Note: After initialization, setmode only requires to set VGA registers and
	partial IGS extended registers. Most of the IGS extended registers
	remain no change.
  --------------------------------------------------------------------*/
void SetPartExtReg(unsigned char *bPtr, int iCounter)
{
	int i;
	outportb(CRTINDEX, 0x13);		 /*index*/
	outportb(CRTDATA ,	*bPtr++);	 /*data*/

	for (i=0; i<iCounter; i++) {
		outportb(EXTINDEX, *bPtr++);	 /*index*/
		outportb(EXTDATA,  *bPtr++);	 /*data*/
	}

	ToggleClock();	  /*to latch the clock value into working set*/
}

#endif	/* if 0 */

/*--------------------------------------------------------------------
  SetRamDac: Program look up table. This is needed only for 256 color mode
  In:	bPtr - a BYTE_ pointer to an array of RGB color look up table.
	iCounter - counter of the RGB data (usually it is 256).
  Out:	VGA 256 default color table is set.
  --------------------------------------------------------------------*/
void SetRamDac(unsigned char *bPtr, int iCounter)
{
	int i;

	outportb(RAMDACINDEXW, 0);		 /*start from index 0*/
	for (i=0; i<iCounter; i++) {
		outportb(RAMDACDATA, *bPtr++);	 /*R*/
		outportb(RAMDACDATA, *bPtr++);	 /*G*/
		outportb(RAMDACDATA, *bPtr++);	 /*B*/
	}
	outportb(RAMDACMASK, 0xff); 	 /*Mask register*/
}

/***********************************************************************
 *				CardSetPalette
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
void
CardSetPalette (unsigned char *paletteData)
{
	unsigned char   index = 0;
	unsigned char  *color = paletteData;
	unsigned char	 red = 0, green = 0, blue = 0;

	/*--------------------------------------------*\
	|* Set RAMDAC as we're in 256 colors mode	  *|
	\*--------------------------------------------*/
	BypassMode(OFF);     /*don't want index mode*/

	do {
		green = color[1];
		green = green>>2;
		blue = color[2];
		blue = blue>>2;
		red = color[0];
		red = red>>2;

		*color++ = red;
		*color++ = green;
		*color++ = blue;

#if	PRINT_DEBUG_INFO
		fprintf(stdout, "Prog:%u r:%u g:%u b:%u\n", index, (unsigned int) red, (unsigned int)green, (unsigned int) blue);
#endif	/* PRINT_DEBUG_INFO */

		// Advance to next entry
		index++;
	} while (index != 0);
	 SetRamDac(paletteData, 256);
}	/* End of CardSetPalette.	*/


/***********************************************************************
 *				CardDisableOutput
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
void
CardDisableOutput (void)
{
	struct REGPACK preg = {(ALT_SELECT << 8) | VGA_DISABLE_VIDEO,
				VIDEO_SCREEN_ON_OFF};

	intr(VIDEO_BIOS, &preg);
}	/* End of CardDisableOutput.	*/

/***********************************************************************
 *				CardEnableOutput
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial Revision
 *
 ***********************************************************************/
void
CardEnableOutput (void)
{
	struct REGPACK preg = {(ALT_SELECT << 8) | VGA_ENABLE_VIDEO,
				VIDEO_SCREEN_ON_OFF};

	intr(VIDEO_BIOS, &preg);
}	/* End of CardEnableOutput.	*/

#if 0

/*---------------------------------------------------------
  TVOn: Turn on or turn off TV.
  In:  iOnOff - on: TV on
		off:TV off
  Out: TV will be on or off.
  Note: This routine provides a fast and separate control to
	turn on or turn off TV with the TV DAC enabled.

		 |-------------------------------|
		 |EnableTV() | TVOn() | TV Screen|
		 |-------------------------------|
		 |  ON	   |  ON    | TV is on |
		 |-------------------------------|
		 |  OFF	   |  ON    | TV is off|
		 |-------------------------------|
		 |  ON	   |  OFF   | TV is off|
		 |-------------------------------|
		 |  OFF	   |  OFF   | TV is off|
		 |-------------------------------|

 ----------------------------------------------------------*/
void TVOn(int iOnOff)
{
	 if (iOnOff == ON) {
		outportb(EXTINDEX, 0x5C);
		outportb(EXTDATA, inportb(EXTDATA) | 0x20);
	 } else {
		outportb(EXTINDEX, 0x5C);
		outportb(EXTDATA, inportb(EXTDATA) & ~0x20);
	 }
}

/*--------------------------------------------------------------------
  ToggleClock: Toggle a control bit to latch pixel and video memory clock
  related registers 3CE_B0/3CE_B1/3CE_B2/3CE_B3 into working set.
  In:  3CE_B0/3CE_B1/3CE_B2/3CE_B3 must be set correctly.
  Out: New values of pixel/memory clock take effect.
  Note: Normally only pixel clock setting (3CE_B0/_B1) changes and memory
	clock setting (3CE_B2/_B3) remain the same when resolution or
	refresh rate changes.
  --------------------------------------------------------------------*/
void ToggleClock(void)
{
	BYTE_ bTmp;

	outportb(EXTINDEX, 0xB9);	/*bit <7> is the control bit*/
	bTmp = inportb(EXTDATA);

	outportb(EXTDATA, bTmp & 0x7F);
	outportb(EXTDATA, bTmp | 0x80);
	outportb(EXTDATA, bTmp & 0x7F);
}
/*---------------------------------------------------------
  SetTVReg: Program TV registers.
  In:  wPtr - a WORD_ pointer to an array of TV register settings
	iCounter - counter of the TV registers.
  Out: Full range of TV registers are set.
 ----------------------------------------------------------*/
void SetTVReg(short *wPtr, int iCounter)
{
	WORD_ wTVIndex, wTVValue;
	int i;

	iCounter >>= 1;

	for (i=0; i<iCounter; i++) {
		wTVIndex = *wPtr++;
		wTVValue = *wPtr++;

		WriteTVReg(wTVIndex, wTVValue);
	}
}


/*---------------------------------------------------------
  ReadTVReg: Read a 16-bit value from a TV register.
  In:  Index - TV register index.
  Out: Return a 16-bit value of the TV register.
  Note: TV register read must be two 8-bit read, not a 16-bit read.
 ----------------------------------------------------------*/
short ReadTVReg(short index)
{
	WORD_ value;

	BYTE_ valueL;
	BYTE_ valueH;

	UnlockTVReg();

	valueL =  *(bTVRegBase + index);
	valueH =  *(bTVRegBase + index +1);

	value = (WORD_) (valueL + (valueH << 8) );

	LockTVReg();

	return value;
}


/*---------------------------------------------------------
  WriteTVReg: Write a 16-bit value into a TV register.
  In:  Index - TV register index.
  Out: Return a 16-bit value of the TV register.
  Note: TV register write must be a 16-bit write, not two 8-bit write.
	Make sure your compilers handle it correctly.
 ----------------------------------------------------------*/
void WriteTVReg(short index, short data)
{
	UnlockTVReg();

	*((volatile unsigned short far *)(bTVRegBase + index)) = data;

	LockTVReg();
}


/*---------------------------------------------------------
  UnlockTVReg: Allow the access to TV registers.
  In: None
  Out: TV register can be accessed.
 ----------------------------------------------------------*/
void UnlockTVReg(void)
{
	outportb(EXTINDEX,0x33);
	outportb(EXTDATA,bReg33|0x08);

	outportb(EXTINDEX,0x3C);
	outportb(EXTDATA,bReg3C|0x80);
}


/*---------------------------------------------------------
  LockTVReg: Deny the access to TV registers.
  In: None
  Out: TV register can not be accessed.
 ----------------------------------------------------------*/
void LockTVReg(void)
{
	outportb(EXTINDEX,0x3C);
	outportb(EXTDATA,bReg3C);

	outportb(EXTINDEX,0x33);
	outportb(EXTDATA,bReg33);
}

/*---------------------------------------------------------
  EnableTV: Enable or Disable TV out, set NTSC or PAL.
  In:  iOnOff - ON or OFF.
		 iTVType - NTSC or PAL.
  Out: TV DAC will be enabled or disabled.
 ----------------------------------------------------------*/
void EnableTV(int iOnOff, int iTVType)
{
	BYTE_ iTmp;

	outportb(EXTINDEX, 0xFA);		 /*Banking I/O control*/
	outportb(EXTDATA, 0x05);

	if (iOnOff == ON) {
		outportb(EXTINDEX, 0x4E);
		iTmp = inportb(EXTDATA) & ~0x05;	 /*bit <2,0>*/

		if (iTVType == NTSC)
			outportb(EXTDATA, iTmp | 0x04);
		else if (iTVType == PAL)
			outportb(EXTDATA, iTmp | 0x05);
	} else {
		outportb(EXTINDEX, 0x4E);
		outportb(EXTDATA, inportb(EXTDATA) & ~0x04);
	}
}
/*----------------------------------------------------------------------
  SetTVColor: It corrects TV color each time when a new mode is set.
  In:  wScnHeight was set.
  Out: None
  Note: This routine should be called each time after setting a new mode,
	otherwise, you might experience the wrong TV color. It has no effect
	to CRT.
 -----------------------------------------------------------------------*/
void SetTVColor()
{
	BYTE_ bData;
	WORD_ iTmp;
	WORD_ wTmp1;
	int i;
	wTmp1 = ReadTVReg(0xE4FC); 	 /*save regs*/

	WriteTVReg(0xE4FC, 0xC0C0);

	BypassMode(OFF);			 /*disable bypass mode*/

	/* set RAMDAC to blue */
	outportb(RAMDACINDEXW, 0); 	 /*start from index 0*/
	for (i=0; i<256; i++) {
		 outportb(RAMDACDATA, 0x00);	 /*R*/
		 outportb(RAMDACDATA, 0x00);	 /*G*/
		 outportb(RAMDACDATA, 0xFF);	 /*B*/
	}

	/* Reset FSC: 3CE_4E<1>=1 */
	outportb(EXTINDEX, 0xFA);
	outportb(EXTDATA, 0x05);
	outportb(EXTINDEX, 0x4E);
	outportb(EXTDATA, inportb(EXTDATA) | 0x02);

	bData = 0;
	/* Wait for Vertical Display Enable */
	while ( ( inportb(ATTRRESET) & 0x08 ) == 0x00);  /*search until 1*/
	while ( ( inportb(ATTRRESET) & 0x08 ) != 0x00);  /*search until 0	active low*/
	do { /*Wait for display scan line to get into middle of the screen*/
		outportb(EXTINDEX, 0x18);	 /*vertical counter lo: 8 bits*/
		iTmp = (WORD_) inportb(EXTDATA);

		outportb(EXTINDEX, 0x19);	 /*vertical counter hi: 3 bits*/
		iTmp += ( (WORD_) (inportb(EXTDATA) & 0x07) << 8);
	}
	while ( (iTmp < 440/2) || (iTmp > 440) );
	outportb(EXTINDEX, 0x5C);
	if (inportb(EXTDATA) & 0x80)
		bData++;

	if (bData)
		 bData = 0x00;
	else
		 bData = 0x08;			 /*for toggle color bit<3>*/

	/* clear FSC: 3CE_4E<1>=0 and toggle 3CE_4E<3> accordingly */
	outportb(EXTINDEX, 0xFA);
	outportb(EXTDATA, 0x05);
	outportb(EXTINDEX, 0x4E);
	outportb(EXTDATA, (inportb(EXTDATA) & ~0x02) ^ bData);

	WriteTVReg(0xE4FC,wTmp1);		 /*restore regs*/
}

#endif	/* if 0 */

/*--------------------------------------------------------------------
  BypassMode: Enable or disable RGB look up table bypass mode.
  In:  iOnOff: ON - enable bypass mode (used for 16/24/32).
			 OFF- disable bypass mode (used for 8 bpp).
  Out: RGB look up table is bypassed or indexed.
  Note: When enabling bypass mode, video memory data will go to DAC directly.
	When disabling bypass mode, video memory data will be the index to
	RGB look up table and then selected RGB will go to DAC.
  --------------------------------------------------------------------*/
void BypassMode(int iOnOff)
{
	BYTE_ bTmp;

	outportb(EXTINDEX, 0x56);
	bTmp = inportb(EXTDATA);
	outportb(EXTDATA, bTmp | 0x04);

	if (iOnOff == ON)
		outportb(RAMDACMASK, inportb(RAMDACMASK) | 0x10);
	else
		outportb(RAMDACMASK, inportb(RAMDACMASK) & ~0x10);

	outportb(EXTDATA, bTmp & ~0x04);

}

#if 0

/*----------------------------------------------------------------------
	CardClearVMem: Clears entire video memory to be 0.
	In:	None
	Out: None
 -----------------------------------------------------------------------*/
void CardClearVMem(void)
{
	unsigned int far *fpTmp;
	WORD_ wData = 0x00;
	int iMaxBankNum;
	WORD_ i, j;

  /*
	 Here the code uses banking scheme (since it is a DOS program).
	 One bank = 64KB (from 0xA0000 to 0xAFFFF in CPU memory range)
	 One MB = 16 x 64 KB = 1024 KB

	 If linear frame buffer is used (which is the case), no banking
	 programming is required at all.
  */
	switch (GetVMemSize()) {
	case 0:
		iMaxBankNum = 16;
		break;

	case 1:
		iMaxBankNum = 32;
		break;

	case 2:
		iMaxBankNum = 64;
		break;
	}

	for (i=0; i<iMaxBankNum; i++) {
		CardMapPage(i);

		fpTmp = (WORD_ far *) vidMemBase;
		for (j=0; j<(WORD_)(32*1024); j++)
			*fpTmp++ = wData;
	}
}

/*----------------------------------------------------------------------
  GetVMemSize: obtain the size of current video memory
  In:  None
  Out: Return 0: 1MB, 1: 2MB, 2: 4MB
 -----------------------------------------------------------------------*/
int GetVMemSize(void)
{
	BYTE_ bData;

	outportb(EXTINDEX, 0x72);
	bData = inportb(EXTDATA) & 0x03;  /*0: 1MB, 1: 2MB, 2: 4MB.*/
	return bData;
}

/*----------------------------------------------------------------------
  GetBusWidth: obtain current video memory bus width
  In:  None
  Out: Return 0: 32 bits; 1: 64 bits
 -----------------------------------------------------------------------*/
int GetBusWidth(void)
{
	BYTE_ bData;

	outportb(EXTINDEX, 0x72);
	bData = inportb(EXTDATA) & 0x04;  /*0: 32 bits; 1: 64 bits.*/
	return (bData >> 2);
}

void
CardWriteScan(unsigned char *data, unsigned int scan)
{
	unsigned int	x;

	for ( x = 0; x < 640; x++) {
		DrawPixel(x, scan, data[x]);
	}

}

/*---------------------------------------------------------
  DrawPixel: Draw a single pixel to the screen.
  In:  x, y - screen position of the pixel.
		 wScnWidth was set.
  Out: None
---------------------------------------------------------*/
void DrawPixel(WORD_ x, WORD_ y, BYTE_ bData)
{
	 unsigned char far *fpTmp;
	 DWORD_ dLinearOffset;

	 dLinearOffset = ((DWORD_) y * 640 + x);

	 fpTmp = vidMemBase + (dLinearOffset & 0xFFFF);

	 CardMapPage((BYTE_) (dLinearOffset>>16));

	 *fpTmp = bData;
}

#endif	/* if 0 */

/*----------------------------------------------------------------------
  DetectCRT: Determine whether CRT (monitor) is hooked up or not.
  In:	None
  Out:	Return TRUE if CRT is hooked up.
----------------------------------------------------------------------*/
int DetectCRT(void)
{
	BYTE_ bData;

	/* Banking control */
	outportb(EXTINDEX, 0xBF);
	outportb(EXTDATA, 0x01);

	outportb(EXTINDEX, 0xB1);
	bData = inportb(EXTDATA);

	/* Banking control */
	outportb(EXTINDEX, 0xBF);
	outportb(EXTDATA, 0x00);

	return !(bData & 0x40);
}
