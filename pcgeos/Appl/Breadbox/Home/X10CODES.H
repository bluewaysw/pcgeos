/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
FILE:		X10Codes.h

AUTHOR:		Fred Goya

DESCRIPTION:
	This file contains the constants which make life easier for an application
	calling the X-10 powercode driver. Incidentally, I've tried to design the
	setup so we can use other powercode standards or extend the drivers without
	needing to recode--just by changing the driver.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <driver.h>

#define DR_POWERCODE_SEND_COMMAND		8
#define DR_POWERCODE_CHANGE_PORT		10
#define DR_POWERCODE_CHANGE_SETTINGS	12
#define DR_POWERCODE_GET_PORT			14

byte HousePowerCodes[16] = {
	0x06,
	0x07,
	0x04,
	0x05,
	0x08,
	0x09,
	0x0A,
	0x0B,
	0x0E,
	0x0F,
	0x0C,
	0x0D,
	0x00,
	0x01,
	0x02,
	0x03,
};

byte UnitNumberCodes[16] ={
	0x06,
	0x07,
	0x04,
	0x05,
	0x08,
	0x09,
	0x0A,
	0x0B,
	0x0E,
	0x0F,
	0x0C,
	0x0D,
	0x00,
	0x01,
	0x02,
	0x03,
};

byte FunctionPowerCodes[8] = {
	0x10,
	0x18,
	0x14,
	0x1C,
	0x12,
	0x1A,
	0x16,
	0x15
};

/*******************************************************************************
* FUNCTION PROTOTYPES                                                          *
*******************************************************************************/
void PowerCodeSendUnitNumber(Handle driver, HouseCodes house, UnitNumbers unit);

void PowerCodeSendCommand(Handle driver, HouseCodes house, FunctionCodes function,
								byte dimBrightCount);

word PowerCodeChangePort(Handle driver, word port);

word PowerCodeGetPort(Handle driver);

/*******************************************************************************
* FUNCTION DEFINITIONS                                                         *
*******************************************************************************/
void PowerCodeSendUnitNumber(Handle driver, HouseCodes house, UnitNumbers unit)
{
	byte hcode, unumb;
	DriverInfoStruct *x10Struct;

	if (driver == NullHandle)
		return;
		
	hcode = HousePowerCodes[house];
	unumb = UnitNumberCodes[unit];
	x10Struct = GeodeInfoDriver(driver);
	asm {
		mov AH, hcode
		mov	AL, unumb
		xor	CL, CL
		mov	DI, DR_POWERCODE_SEND_COMMAND
	}
	x10Struct->DIS_strategy();
	return;
}

void PowerCodeSendCommand(Handle driver, HouseCodes house, FunctionCodes function,
								byte dimBrightCount)
{
	byte hcode, func;
	DriverInfoStruct *x10Struct;

	if (driver == NullHandle)
		return;
		
	hcode = HousePowerCodes[house];
	func = FunctionPowerCodes[function];
	x10Struct = GeodeInfoDriver(driver);
	asm {
		mov AH, hcode
		mov	AL, func
		mov CL, dimBrightCount
		mov	DI, DR_POWERCODE_SEND_COMMAND
	}
	x10Struct->DIS_strategy();
	return;
}

word PowerCodeChangePort(Handle driver, word port) {
	DriverInfoStruct *x10Struct;

	if (driver == NullHandle)
		return;
		
	x10Struct = GeodeInfoDriver(driver);
	asm {
		mov	CX, port
		mov	DI, DR_POWERCODE_CHANGE_PORT;
	}
	x10Struct->DIS_strategy();
	/* we should probably return an error code if the function comes back with
		dx set. */
	asm {
		cmp	DX, 0
		je		retOK
	}
	return 1;

  retOK:	
	return(0);
}

word PowerCodeGetPort(Handle driver)
{
	DriverInfoStruct *x10Struct;

	if (driver == NullHandle)
		return;
		
	x10Struct = GeodeInfoDriver(driver);
	asm {
		mov	DI, DR_POWERCODE_GET_PORT;
	}
	x10Struct->DIS_strategy();

	/* Port is returned in CX register */
	return(_CX);
}
