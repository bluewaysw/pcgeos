COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common power management code
FILE:		powerStrings.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial revision

DESCRIPTION:
	This is common battery code

	$Id: IdlePowerStrings.asm,v 1.1 97/04/18 11:48:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringsUI segment lmem LMEM_TYPE_GENERAL

; PW_MAIN_BATTERY
MainWarningString	chunk.char	\
	"The main battery is low.", 0

; PW_BACKUP_BATTERY
	chunk.char	\
	"The backup battery is low.", 0

; PW_PCMCIA_SLOT_1_BATTERY
	chunk.char	\
	"The battery in the card in slot 1 is low.", 0

; PW_PCMCIA_SLOT_2_BATTERY
	chunk.char	\
	"The battery in the card in slot 2 is low.", 0

; PW_PCMCIA_SLOT_3_BATTERY
	chunk.char	\
	"The battery in the card in slot 3 is low.", 0

; PW_PCMCIA_SLOT_4_BATTERY
	chunk.char	\
	"The battery in the card in slot 4 is low.", 0

; PW_NO_POWER_SAMPLE_CUSTOM_WARNING
	chunk.char	\
	"This is a sample of a custom warning.", 0

; Open port strings
OpenCOM1String	chunk.char	"Power Driver: Opening COM1...", 0
OpenCOM2String	chunk.char	"Power Driver: Opening COM2...", 0
OpenCOM3String	chunk.char	"Power Driver: Opening COM3...", 0
OpenCOM4String	chunk.char	"Power Driver: Opening COM4...", 0

OpenPCOM1String	chunk.char	"Power Driver: Opening COM1 (passive)...", 0
OpenPCOM2String	chunk.char	"Power Driver: Opening COM2 (passive)...", 0
OpenPCOM3String	chunk.char	"Power Driver: Opening COM3 (passive)...", 0
OpenPCOM4String	chunk.char	"Power Driver: Opening COM4 (passive)...", 0

OpenLPT1String	chunk.char	"Power Driver: Opening LPT1...", 0
OpenLPT2String	chunk.char	"Power Driver: Opening LPT2...", 0
OpenLPT3String	chunk.char	"Power Driver: Opening LPT3...", 0

StringsUI ends
