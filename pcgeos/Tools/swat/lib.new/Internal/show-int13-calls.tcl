##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	show-int13-calls.tcl
# AUTHOR: 	Chris Hawley-Ruppel, 3/14/94
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cbh	3/14/94		Initial Revision
#
# DESCRIPTION:
#	A function for displaying some int 13h and int 21h calls as they
#	happen in DOS.
#
#	$Id: show-int13-calls.tcl,v 1.1 94/04/04 12:47:04 chris Exp $
#
###############################################################################

[defcommand show-int13-calls {} profile
{Usage:
	show-int13-calls

Synopsis:
	When assembling a DOS driver with DEBUG_BOOT_SECTOR_CALLS = TRUE,
	allows shadowing of all int 13h calls, except for read and write
	sector calls to drives other than drive B.  Also shows some Int 21h
	calls.   Modify DebugBootSectorCalls in IFS/DOS/Common et al for other 
	behavior.
}
{
	brk ms4::EnterInt13Call print-rgs
	brk ms4::LeaveInt13Call print-rgs2
	brk ms4::LeaveBootSectorCall print-boot-sec
	brk ms4::DOSUtilInt21Debug print-rgs21
	brk ms4::DOSUtilInt21Debug::done print-rgs21-end
}
]


[defsubr print-rgs {} {
    echo -n {    }
    echo -n [penum BiosInt13Func [read-reg ah]]
    echo [format { cx=%04xh dx=%04xh bp=%04xh} [read-reg ah]
			[read-reg cx] [read-reg dx] [read-reg bp]]
    return 0
}]
[defsubr print-rgs2 {} {
    echo [format {    Returns ax=%04xh, cx=%04xh dx=%04xh bp=%04xh} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    echo
    return 0
}]
[defsubr print-boot-sec {} {
    print ms4::bootSectorParams.ms4::BSPL_returnData.BS_volumeLabel
    print ms4::bootSectorParams.ms4::BSPL_returnData.BS_bpbNumSectors
    echo
    return 0
}]

[defsubr print-rgs21 {} {
    echo --------------------------------------------------------------------
    echo -n [penum Int21Call [read-reg ah]]
    echo [format { cx=%04xh dx=%04xh bp=%04xh} [read-reg ah]
			[read-reg cx] [read-reg dx] [read-reg bp]]
    return 0
}]
[defsubr print-rgs21-end {} {
    echo [format {Returns ax=%04xh, cx=%04xh dx=%04xh bp=%04xh} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    echo --------------------------------------------------------------------
    return 0
}]


