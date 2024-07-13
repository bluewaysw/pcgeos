sub duplo_ui_ui_ui()
 REM	$Id: g_system.bas,v 1.1 97/12/02 14:57:08 gene Exp $

 REM NOTE: This launcher has been MODIFIED for use with the builder.
 REM See comments containing "BUILDER"
 REM 
 REM G_SYSTM.BAS is used by gandalf so that aggregates may reference
 REM system components at build time.  G_SYSTM.BAS was copied from
 REM LV_SYSTM.BAS so that the power component might be handled
 REM specially.*  In the future, other components requiring special
 REM handling at build time may be modified in this file.
 REM					  	-Jonathan 10/7/96
 REM
	
	STRUCT TimeOfDay
	    DIM hour as integer
	    DIM minute as integer
	    DIM second as integer
	END STRUCT
	
	STRUCT Date
	    DIM year as integer
	    DIM month as integer
	    DIM day as integer
	END STRUCT
	
	STRUCT Notification
	    DIM arg1 as integer
	    DIM arg2 as integer
	    DIM arg3 as integer
	    DIM arg4 as integer
	    DIM arg5 as string
	    DIM arg6 as complex
	END STRUCT
	
	
	
	duplo_start()
end sub

sub duplo_start( )
REM
REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
REM
REM	FILE:		system.bas
REM	AUTHOR:		Matt Armstrong, Dec 15, 1995
REM	DESCRIPTION:
REM		Implements the system module.
REM
REM		$Id: g_system.bas,v 1.1 97/12/02 14:57:08 gene Exp $
REM      $Revision: 1.1 $				
	
    Dim display as display
	export display
	display = MakeComponent("display", "app")
	display.proto = "display"
	
    Dim sound as sound
	export sound
	sound = MakeComponent("sound", "app")
	sound.proto = "sound"
	
    Dim busy as component
	export busy
	busy = MakeComponent("busy","app")
	busy.proto = "busy"
	
	
    Dim timedate as timedate
	export timedate
	timedate = MakeComponent("timedate", "app")
	timedate.proto = "timedate"
	
    Dim clipboard as clipboard
	export clipboard
	clipboard = MakeComponent("clipboard", "app")
	clipboard.proto = "clipboard"

    DIM launcher as component
	export launcher
    DIM launcherModule as module
	launcherModule = LoadModuleShared("LV_LAUNC")
	launcher = launcherModule:launcher
	launcherModule:systemMod = CurModule()
	
    DIM productName AS string
	export productName
	productName = "New Deal office"
	
    DIM underlyingOS AS string
	export underlyingOS
	underlyingOS = "Geos"
	
	REM
	REM Components needed to indicate busy state.
	REM These aren't in a seperate module as that would
	REM probably be slower and this is fairly small.
	
    dim busyFloater as dialog
	busyFloater = MakeComponent("dialog", "app")
	CompInit busyFloater
		top = 70
		left = 70
		height = 40
		width = 60
		type = 4
		visible = 0
	End CompInit
	
    dim busyLabel as label
	busyLabel = MakeComponent("label", busyFloater)
	CompInit busyLabel
		top = 10
		left = 10
		caption = "Busy"
		visible = 1
	End CompInit
	
end sub

    
sub lview_register(lview_module as module)
    REM for BUILDER support -- lview.bh header inserts a call to this
    REM when a module is run from the builder.
    launcherModule:SetMainModule(lview_module)
END sub

function runTimeError(m as module, error as integer) as integer
REM
REM This function is called by the interpreter when a runtime error in 
REM another module is not handled with.
REM
REM Return zero to invoke the standard system error handling (putting up
REM a dialog and perhaps rebooting the device).
REM Return non-zero to indicate that the error has been handled
REM appropriately and no additional action is necessary. 
REM
	runTimeError = 0

end function

sub SwitchTo(mls as string)
	launcher!SwitchTo(mls)
END sub

sub Unload(m as module)
REM
REM Unload has been added so that the tethered debugger can ask that
REM the module it's loaded can be cleanly unloaded when time to do so.
REM
	UnloadModule(m)
END sub

function DateToInteger(date as STRUCT Date) as integer
	REM Argument is a Date STRUCT.	Returns the date
	REM packed as hour:5 min:6 sec:5, with the sign big flipped.
	
	REM Check for valid ranges
    DIM year as integer
    DIM month as integer
    DIM day as integer
	year = date.year
	month = date.month
	day = date.day
	
	const YEAR_HIGH &h0040
	const YEAR_MASK (YEAR_HIGH - 1)
	const YEAR_MULT &h0200
	
	const MONTH_MULT &h0020
	
    DIM carry as integer
	year = year - 1980
	carry = year BITAND YEAR_HIGH
	year = (year BITAND YEAR_MASK) * YEAR_MULT
	month = month * MONTH_MULT
	
    DIM total as integer
	DateToInteger = year BITOR month BITOR day
	if carry then
		DateToInteger = DateToInteger BITOR &H8000
	end if
	
	REM This is so earlier dates are smaller
	if (DateToInteger BITAND &h8000) then
		DateToInteger = DateToInteger BITAND &h7FFF
	else
		DateToInteger = DateToInteger BITOR &h8000
	end if
END function

sub IntegerToDate(in as integer, out as struct Date)
	REM Argument is an integer packed by DateToInteger()
	REM returns a Date STRUCT
	
	REM This is so earlier dates are smaller
	if (in BITAND &h8000) then
		in = in BITAND &h7FFF
	else
		in = in BITOR &h8000
	end if
	
    DIM carry as integer
	carry = in BITAND &h8000
	in = in BITAND &h7fff
	
	out.day = in BITAND &h001f
	out.month = (in / 32) BITAND &h000f
	out.year = (in / 512) BITAND &h007f
	if (carry) then
		out.year = out.year BITOR &h0040
	end if
	out.year = out.year + 1980
END sub

function TimeToLong(time as struct TimeOfDay) as long
	REM Argument is a Date STRUCT.	Returns the date
	REM packed as hour:5 min:6 sec:6
	
	REM Check for valid ranges
    DIM hour as long
    DIM minute as long
    DIM second as long
	hour = time.hour
	minute = time.minute
	second = time.second
	
	hour = hour * 4096
	minute = minute * 64
	
	TimeToLong = hour BITOR minute BITOR second
end function

sub LongToTime(in as long, out as struct TimeOfDay)
	out.hour = (in / 4096) BITAND &h001f
	out.minute = (in / 64) BITAND &h003f
	out.second = in BITAND &h003f	
end sub

function DateTimeToLong(date as STRUCT Date, time as STRUCT TimeOfDay) as long
	REM
	REM Returns the date and time packed as follows:
	REM year:7 month:4 day:5 hour:5 min:6 sec:5.
	REM Year is expressed as realYear - 1980
	REM sec is divided by 2
	REM The high bit is flipped in the final 4 byte value.
	REM
    DIM year as long
    DIM month as long
    DIM day as long
    DIM hour as long
    DIM minute as long
    DIM second as long
	
	year = date.year - 1980
	month = date.month
	day = date.day
	hour = time.hour
	minute = time.minute
	second = time.second
	
    DIM carry as long
	carry = year BITAND &H0040
	
	year = year BITAND &H003f
	
	const DTL_YEAR	  &h02000000
	const DTL_MONTH	  &h00200000
	const DTL_DAY	  &h00010000
	const DTL_HOUR	  &h0800
	const DTL_MINUTE  &h0020
	
	const BIT_7_MASK   &h7f
	const BIT_6_MASK   &h3f
	const BIT_5_MASK   &h1f
	const BIT_4_MASK   &h0f
	
	year = year * DTL_YEAR
	month = month * DTL_MONTH
	day = day * DTL_DAY
	hour = hour * DTL_HOUR
	minute = minute * DTL_MINUTE
	second = second / 2
	DateTimeToLong = year + month + day + hour + minute + second
	
	if carry then
		DateTimeToLong = DateTimeToLong BITOR &h80000000
	end if
	
	if (DateTimeToLong BITAND &h80000000) then
		DateTimeToLong = DateTimeToLong BITAND &h7FFFFFFF
	else
		DateTimeToLong = DateTimeToLong BITOR &h80000000
	end if
END function

sub LongToDateTime(in as long, outDate as STRUCT Date, outTime as STRUCT TimeOfDay)
    DIM year as long
    DIM month as long
    DIM day as long
    DIM hour as long
    DIM minute as long
    DIM second as long
	
	if (in BITAND &h80000000) then
		in = in BITAND &h7FFFFFFF
	else
		in = in BITOR &h80000000
	end if
	
    DIM carry as long
	carry = in BITAND &h80000000
	in = &h7FFFFFFF BITAND in
	
	year = ((in / DTL_YEAR) BITAND BIT_7_MASK)
	if carry then
		year = year BITOR &h40
	end if
	year = year + 1980
	month = (in / DTL_MONTH) BITAND BIT_4_MASK
	day = (in / DTL_DAY) BITAND BIT_5_MASK
	hour = (in / DTL_HOUR) BITAND BIT_5_MASK
	minute = (in / DTL_MINUTE) BITAND BIT_6_MASK
	second = (in BITAND BIT_5_MASK)
	second = second * 2
	
	outDate.year = year
	outDate.month = month
	outDate.day = day
	outTime.hour = hour
	outTime.minute = minute
	outTime.second = second
END sub

sub busy_busyTotalChanged(self as busy)
	busyFloater.visible = self.busyCount
	
end sub

