

/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- IBM PC definitions
 * FILE:	  ibm.h
 *
 * AUTHOR:  	  Adam de Boor: Jul 18, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/18/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for interfacing to an IBM PC. Included by both
 *	the patient-dependent and machine-dependent interfaces for
 *	the IBM.
 *
 *
* 	$Id: ibm.h,v 4.6 97/04/18 15:47:54 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _IBM_H_
#define _IBM_H_

/*
 * Assignment of constants to register names. All registers except REG_IP,
 * REG_LONG_SP and REG_LONG_BP are ordered the same as the processor orders
 * them in its opcodes.
 */
#define REG_AX	  	0
#define REG_BX	  	3
#define	REG_CX	  	1
#define	REG_DX	  	2
#define REG_SP	  	4
#define REG_BP	  	5
#define REG_SI	  	6
#define	REG_DI	  	7

#define REG_ES	  	8
#define REG_CS	  	9
#define REG_SS	  	10
#define REG_DS	  	11

#define REG_AL	  	12
#define REG_BL	  	15
#define REG_CL	  	13
#define REG_DL	  	14
#define REG_AH	  	16
#define REG_BH	  	19
#define REG_CH	  	17
#define REG_DH	  	18

#define REG_IP	  	20  	/* As opposed to REG_PC, which is CS:IP as
				 * a 32-bit address */
#if REGS_32
#define REG_EAX	  	21
#define REG_EBX	  	24
#define	REG_ECX	  	22
#define	REG_EDX	  	23
#define REG_ESP	  	25
#define REG_EBP	  	26
#define REG_ESI	  	27
#define	REG_EDI	  	28
#define	REG_FS	  	29
#define	REG_GS	  	30
#define	REG_EIP	  	31
#endif

/*
 * Flags register bits
 */
#define REG_OF	    0x0800
#define REG_DF	    0x0400
#define REG_IF	    0x0200
#define REG_TF	    0x0100
#define REG_SF	    0x0080
#define REG_ZF	    0x0040
#define REG_AF	    0x0010
#define REG_PF	    0x0004
#define REG_CF	    0x0001

#include <os90.h>

#if REGS_32
typedef dword regval ;
#else
typedef word regval ;
#endif

/*
 * Structure used for easy recording of segmented addresses.
 */
typedef struct {
    word	offset;
    word	segment;
} SegAddr;

#define SegToAddr(sa)	((Address)(((sa).segment << SEGMENT_SHIFT) + (sa).offset))

/*
 * Structure used for easy recording of addresses in PC GEOS. Since almost
 * all memory references must be done via a handle, we need both the
 * handle and the offset.
 */
typedef struct {
    Handle  	  	handle;
    Address    	  	offset;
} GeosAddr;

typedef enum
{
    ST_NONE,
    ST_NON_EC_S,
    ST_EC_S,
    ST_NON_EC,
    ST_EC
} StartupType;

/*
 * Type descriptions for fetching data from the patient, since we will
 * probably need to byte-swap the stuff.
 */
extern Type	    typeSegAddr;

extern Boolean	Ibm_ReadBytes (int numBytes, Handle handle,
				    Address patientAddress,
				    genptr swatAddress);

extern Boolean	Ibm_WriteBytes (int numBytes, genptr swatAddress,
				Handle handle, Address patientAddress);
extern Boolean	Ibm_ReadRegister (RegType regType, int regNum,
				  regval *valuePtr);
extern Boolean	Ibm_ReadRegister16 (RegType regType, int regNum,
				  word *valuePtr);
extern Boolean	Ibm_WriteRegister (RegType regType, int regNum,
				   regval value);
extern Boolean	Ibm_SingleStep (void);
extern Boolean	Ibm_Continue (void);
extern void	Ibm_Stop (void);
extern void	Ibm_LostContact (void);
extern char 	*Ibm_FindFile (char *file, char *path);
extern word	Ibm_EndStack (void);
extern int      Ibm_ReadFromObjectFile(Patient patient, word size, 	
				       dword offset, genptr destination,
				       int seektype, word dataType,   
				       word dataValue1, word dataValue2);
extern Patient	Ibm_NewGeode (Handle core, word id, Address dataAddress,
			      int paraSize);
extern Handle   Ibm_NewThread (word id, word ownerID, regval ss, regval sp,
			       Boolean notify, int flags);
extern void     Ibm_LoaderMoved(word baseSeg);
extern Handle   Ibm_StackHandle (void);
extern Boolean  Ibm_MaybeUnignore (char *name);
extern Boolean  Ibm_PingPC(Boolean initialized);
extern void     Ibm_Init (char *file, int *argcPtr, char **argv,
			  StartupType startup);

#endif /* _IBM_H_ */
