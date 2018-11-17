COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Power Drivers
FILE:		apmCustom.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	List of files that must be customized	

	$Id: apmCustom.asm,v 1.1 97/04/18 11:48:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMReadRTC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current value from RTC

CALLED BY:	APMUpdateClocks
PASS:		ds	-> dgroup

RETURN:		dh	<- seconds
		dl	<- minutes
		ch	<- hours
		bl	<- month
		bh	<- day
		ax	<- century + year

DESTROYED:	nothing
SIDE EFFECTS:
		Reads from RTC

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMReadRTC	proc	near
	.enter

	.leave
	ret
APMReadRTC	endp
if	HAS_RTC_INTERRUPT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSendRTCAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ACK the RTC hardware for the device

CALLED BY:	APMStrategy
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Presumably, it does an EOI and possibly
			some other stuff as well.

PSEUDO CODE/STRATEGY:
		Dance the polka.
		See if anyone else wants to dance the polka.
		Notice no one does.
		Notice they're all pointing and staring.
		Sit down.
		Look sheepish.
		Desire to crawl under rock and die.
		Look sheepish.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMSendRTCAck	proc	near
	ret
APMSendRTCAck	endp
endif
Resident		ends

Movable			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMCheckForOnOffPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if request came from ON-OFF button

CALLED BY:	APMGetStatusWarnings

PASS:		ds	-> dgroup	

RETURN:		carry set if request not on-off press

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMCheckForOnOffPress	proc	near
	.enter
if	HAS_COMPLEX_ON_OFF_BUTTON

	test	ds:[miscState], mask MS_ON_OFF_PRESS	; clears carry auto.
	jz	done	; => wasn't  on-off

	andnf	ds:[miscState], not (mask MS_ON_OFF_PRESS) ; clear state bit
	stc						; mark asON-OFF

done:
	cmc
else

%out  HEY!  FILL THIS OUT OKAY?

endif	

	.leave
	ret
APMCheckForOnOffPress	endp
Movable			ends

Resident		segment	resource
if	HAS_DETACHABLE_KEYBOARD
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMCheckKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMCheckKeyboard	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	.leave
	ret
APMCheckKeyboard	endp
endif

Resident		ends
