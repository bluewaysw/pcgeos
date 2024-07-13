sub duplo_ui_ui_ui()
 REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
 REM	FILE:		STDINC.BH
 REM	$Id: lv_launc.bas,v 1.1 97/12/02 14:57:10 gene Exp $
 REM
 REM NOTE: This launcher has been MODIFIED for use with the builder.
 REM See comments containing "BUILDER"
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

REM useful color constants
CONST WHITE 		&Hffffffff
CONST BLACK 		&Hff000000
CONST GRAY_50 		&Hff808080, GREY_50 		&Hff808080
CONST DARK_GRAY 	&Hff555555, LIGHT_GRAY		&Hffaaaaaa
CONST DARK_GREY 	&Hff555555, LIGHT_GREY		&Hffaaaaaa
CONST DARK_GREEN	&Hff00aa00, LIGHT_GREEN 	&Hff55ff55
CONST DARK_BLUE 	&Hff0000aa, LIGHT_BLUE		&Hff5555ff
CONST DARK_CYAN		&Hff00aaaa, LIGHT_CYAN		&Hff55ffff
CONST DARK_PURPLE	&Hffaa00aa, LIGHT_PURPLE	&Hffff55ff
CONST DARK_ORANGE	&Hffaa5500, LIGHT_ORANGE	&Hffff5555
CONST YELLOW		&Hffffff55
CONST RED		&Hffaa0000

REM sound constants
CONST SS_ERROR		0
CONST SS_WARNING	1
CONST SS_NOTIFY		2
CONST SS_NO_INPUT	3
CONST SS_KEY_CLICK	4
CONST SS_ALARM		5

CONST MOUSE_PRESS 1, MOUSE_HOLD 2, MOUSE_DRAG 3, MOUSE_TO 4, MOUSE_RELEASE 5
CONST MOUSE_LOST 6, MOUSE_FLY_OVER 7

CONST C_SYS_BACKSPACE		&Hee08
CONST C_SYS_TAB			&Hee09
CONST C_SYS_ENTER		&Hee0d
CONST C_SYS_ESCAPE		&Hee1b
CONST C_SYS_F1			&Hee80
CONST C_SYS_F2			&Hee81
CONST C_SYS_F3			&Hee82
CONST C_SYS_F4			&Hee83
CONST C_SYS_F5			&Hee84
CONST C_SYS_F6			&Hee85
CONST C_SYS_F7			&Hee86
CONST C_SYS_F8			&Hee87
CONST C_SYS_F9			&Hee88
CONST C_SYS_F10			&Hee89
CONST C_SYS_F11			&Hee8a
CONST C_SYS_F12			&Hee8b
CONST C_SYS_F13			&Hee8c
CONST C_SYS_F14			&Hee8d
CONST C_SYS_F15			&Hee8e
CONST C_SYS_F16			&Hee8f
CONST C_SYS_UP			&Hee90
CONST C_SYS_DOWN		&Hee91
CONST C_SYS_RIGHT		&Hee92
CONST C_SYS_LEFT		&Hee93
CONST C_SYS_HOME		&Hee94
CONST C_SYS_END			&Hee95
CONST C_SYS_PREVIOUS		&Hee96
CONST C_SYS_NEXT		&Hee97
CONST C_SYS_INSERT		&Hee98
CONST C_SYS_CLEAR		&Hee99	rem Not used in Geos.
CONST C_SYS_DELETE		&Hee9a
CONST C_SYS_PRINT_SCREEN	&Hee9b
CONST C_SYS_HELP		&Hee9d	rem Not used in Geos.
CONST C_SYS_BREAK		&Hee9e
CONST C_SYS_CAPS_LOCK		&Heee8
CONST C_SYS_NUM_LOCK		&Heee9
CONST C_SYS_SCROLL_LOCK		&Heeea
CONST C_SYS_LEFT_ALT		&Heee0
CONST C_SYS_RIGHT_ALT		&Heee1
CONST C_SYS_LEFT_CTRL		&Heee2
CONST C_SYS_RIGHT_CTRL		&Heee3
CONST C_SYS_LEFT_SHIFT		&Heee4
CONST C_SYS_RIGHT_SHIFT		&Heee5


CONST KEY_BS 		&Hee08
CONST KEY_DEL 		&Hee9a
CONST KEY_ENTER 	&Hee0d
CONST KEY_KP_RETURN 	&Hffff
CONST KEY_HOME		&Hee94
CONST KEY_TAB		&Hee09
CONST KEY_END		&Hee93
CONST KEY_ESC		&Hee1b
CONST KEY_UP_ARROW	&Hee90
CONST KEY_LEFT_ARROW	&Hee93
CONST KEY_RIGHT_ARROW	&Hee92
CONST KEY_DOWN_ARROW	&Hee91


 REM end of stdinc.bh

DisableEvents()
Dim errorDialog as dialog
errorDialog = MakeComponent("dialog","app")
CompInit errorDialog
proto="errorDialog"
left=2
top=2
width=195
height=120
caption=""
type=3
End CompInit
Dim errorText as text
errorText = MakeComponent("text",errorDialog)
CompInit errorText
proto="errorText"
left=5
top=5
readOnly=1
End CompInit
errorText.name="errorText"
errorText.visible=1
Dim errorButton as button
errorButton = MakeComponent("button",errorDialog)
CompInit errorButton
proto="errorButton"
caption="Okay"
left=63
top=90
closeDialog=1
sizeHControl=0
width=35
sizeVControl=0
height=18
visible=1
End CompInit
errorButton.name="errorButton"
errorDialog.name="errorDialog"
EnableEvents()
duplo_start()
end sub

sub duplo_start()
	REM $Id: lv_launc.bas,v 1.1 97/12/02 14:57:10 gene Exp $
	REM $Revision: 1.1 $
    const EOL -1000

  dim launcher as launcher
    export launcher
    launcher = MakeComponent("launcher", "app")
    launcher.proto = "launcher"
    REM reserve 10k
    launcher.memoryReserve = 20
    dim systemMod as module
    export systemMod
    
    REM
    REM	user-defined  variables for launcher:
    REM	-------------------------------------
    REM
    
    CONST MAX_APPS 20
    CONST MAX_CACHED_APPS 10
    
    REM
    REM This is the LRU list of running applications
    REM
  DIM LRU_apps[0] as module
  dim LRU_size as integer
    LRU_size = 0

    REM The runtime won't let the debugged module be unloaded.
    REM Make sure we don't try to do so.
    REM mainModule is set by lv_systm.bas, with SetMainModule
  dim mainModule as module

    CONST NUM_BUILTIN_APPS 7
  DIM builtinApps[NUM_BUILTIN_APPS] as string

    builtinApps[0] = "PROGMAN"
    builtinApps[1] = "TESTER"
    builtinApps[2] = "MeNu2"
    builtinApps[3] = "CONDEMO"
    builtinApps[4] = "PCV-CALC"
    builtinApps[5] = "PCV-FILE"
    builtinApps[6] = "TETRIS"
    
    REM We probably want to merge the above to arrays and just set a flag
    REM to say which state the app is in.

    SetupDatabase()
end sub

sub SetMainModule(m as module)
REM Synopsis:	Add <m> to the LRU cache and mark it, so it cannot be unloaded
REM Called by:	lv_systm.bas
    mainModule = m
    LRU_Push(m)
end sub

sub ShowFEP()
    onerror goto error_feplite
  dim feplite as module

    REM We open a shared copy, since the system module
    REM should have already loaded FEPLITE
    feplite = LoadModuleShared("FEPLITE")
    
    if IsNull(feplite) then
        ErrorDialog("Can't load FEPLITE")
        goto theEnd
    end if

    onerror goto error_fepshow
    feplite:module_show()
    feplite:TurnOn()
    goto theEnd

    error_feplite:
    ErrorDialog("Could not access system:feplite")
    resume theEnd

    error_fepshow:
    ErrorDialog("Could not call system:feplite:module_show")
    resume theEnd

    theEnd:
    if not IsNull(feplite) then
        UnloadModule(feplite)
    end if
end sub

sub launcher_hardIconPressed(self as launcher, icon as integer)
    REM A hard icon was pressed.
    REM The app that this icon represents is 
    REM stored as a user-defined variable.

    if (icon = 1) then
        ShowFEP()
    else
        
      dim appMLS as string
        onerror goto error_bounds
        appMLS = builtinApps[icon]
        onerror goto 0
        self!SwitchTo(appMLS)
        goto theEnd

    end if

    goto theEnd

    error_bounds:
    ErrorDialog("Unknown hard icon number " + str(icon))
    resume theEnd
    theEnd:
end sub

sub launcher_switchTo(self as launcher, application as string)
    REM  SYNOPSIS:	Brings application to top and goes to the passed 
    REM                 context.
    REM  CALLED BY:	EXTERNAL (other modules)
    
    if (application = "") then
        application = "PROGMAN"
    end if
    CommonLoad(application, 0, "")
end sub

sub launcher_goTo(self as launcher, application as string, context as string)
    REM  SYNOPSIS:	Brings application to top and goes to the passed 
    REM                 context.
    REM  CALLED BY:	EXTERNAL (other modules)
    
    CommonLoad(application, 1, context)
end sub

sub launcher_alarm(self as launcher, application as string, context as string)
    REM  SYNOPSIS:	Brings application to top and goes to the passed 
    REM                 context.  Modified so it doesn't try to load new
    REM			modules -- this would be annoying when debugging.
    REM  CALLED BY:	EXTERNAL (alarm system)
    
  dim index as integer
    index = LRU_GetIndexFromMLS(application)
    REM ErrorDialog("app"+STR(index)+application+" got alarm :"+context+":\r")

    REM BUILDER: don't load any new applications
    if (index >= 0) then
	CommonLoad(application, 1, context)
    end if
END sub

sub launcher_memoryRequest(self as launcher, kilobytesNeeded as integer)
  dim m as module
  dim leastUsed as integer
  dim context as string
  dim restoreMain as integer

  dim ecString as string
    ecString = "Request: "+STR(kilobytesNeeded)+"\r"

    restoreMain = 0
    do while LRU_size > 1 and self.memoryAvailable < kilobytesNeeded
	ecString = ecString + "s: "+STR(LRU_size)+ " m: "+STR(self.memoryAvailable)+"\r"
	leastUsed = LRU_size - 1
	ecString = ecString + STR(leastUsed) + ": "
	if (LRU_apps[leastUsed] = mainModule) THEN
	    ecString = ecString + "removing (main)\r"
	    restoreMain = 1
	ELSE
	    ecString = ecString + "removing\r"
	    context = GetAppContext(LRU_apps[leastUsed])
	    StoreContext(context,GetSource(LRU_apps[leastUsed]))
	    UnloadModule(LRU_apps[leastUsed])
	END IF
	LRU_DeleteIndex(leastUsed)
    loop
    ErrorDialog(ecString)

    REM If we tried to kill the main module, stick it back on the LRU.
    REM Check for IsNull just in case the delete succeeded, though...
    if (restoreMain AND (NOT IsNull(mainModule))) then
	LRU_size = LRU_size + 1
	redim preserve LRU_apps[LRU_size]
	LRU_apps[LRU_size-1] = mainModule
    end if
end sub

function GetAppContext(modl as module) as string
	onerror goto noContext
	GetAppContext = ""
	
	GetAppContext = modl:module_getContext()
	goto done
	noContext:
	resume done
	done:

end function


sub launcher_memoryDemand(self as launcher, kilobytesNeeded as integer)
    REM We are guaranteed here that memoryRequest has been called, so
    REM it is useless to duplicate that code here.
END sub

function launcher_outOfMemory(self as launcher) as integer
    REM Return 0 to cause fatal error
    launcher_outOfMemory = 0
END function

sub CommonLoad(application as string, useContext as integer, context as string)
    REM Switch to a given application.
    REM If it is running, bring it forward.
    REM If we cached it, bring it back.
    REM Else, Load it.

REM    LRU_PrintOut("CommonLoad " + application)

    systemMod:busy.Enter()
    Update()

    REM Request that 10k be free. 
    REM Be careful about putting LRU_GetIndexFromMLS() before this
    REM call, as the request memory can invalidate its return value
    REM IF it unloades modules.

    if launcher.memoryAvailable < 20 then
        launcher.RequestMemory(10)
    end if
    
    REM Get the index of the given application in the LRU cache.
    REM index < 0 means app isn't loaded.
    REM index = 0 means app is current app.
    REM index > 0 means app is loaded but not current
  DIM index as integer
    index = LRU_GetIndexFromMLS(application)
 
    REM Currently selected app -- don't need to bring it to fore
    IF (index = 0) THEN
	goto setContext
    END IF
	
    REM Hide the active application
    HideActiveApp()
    
    setContext:

     REM Load the application, or bring it to the front of LRU
  DIM loaded as module
    loaded = LoadApp(index, application)
    REM at this point, loaded is either NULL or the first in the LRU list,
    REM but no module routines have been called on it.

    REM Go to the appropriate context
    IF (useContext <> 0) then
	ModuleGoTo(loaded, context)
    ELSE
	REM FIXME: save context between runs in a database!!!
	REM IF this isn't the active app, tell it to go to its
	    REM default context.
        context = GetContextFromDB(application)
	IF (index <> 0) then
	    ModuleGoTo(loaded, context)
	END IF
    END IF

    REM Show the appropriate application
    ShowActiveApp()
    
    theEnd:
    systemMod:busy.Leave()


REM    LRU_PrintOut("CommonLoad done.")
end sub

function IsNullModule(m as module) as integer
  dim nullModule as module
    if m = nullModule then
	IsNullModule = 1
    else
	IsNullModule = 0
    end if
END function

sub HideActiveApp()
    IF LRU_size > 0 then
	HideModule(LRU_apps[0])
    END IF
END sub

sub ShowActiveApp()
    IF LRU_size > 0 then
	ShowModule(LRU_apps[0])
    END IF
END sub

sub HideModule(m as module)
    REM tell module to "hide" itself
    IF not IsNullModule(m) then
	onerror goto error_no_module_hide
	m:module_hide()
	goto end_if
	
	error_no_module_hide:
	resume try_form1
	
	try_form1:
	onerror goto error_no_form1
	m:form1.visible = 0
	goto end_if
	
	error_no_form1:
	resume end_if
	
    end_if:
end if
end sub

sub ShowModule(m as module)
    REM tell module to "show" itself
	REM tell module to "hide" itself
	IF not IsNullModule(m) then
		onerror goto error_no_module_show
		m:module_show()
		goto end_if

		error_no_module_show:
		resume try_form1

		try_form1:
		onerror goto error_no_form1
		m:form1.visible = 1
		goto end_if

		error_no_form1:
		resume end_if
	
	end_if:
	end if
end sub

function LoadApp(LRU_index as integer, mls as string) as module

    IF LRU_index >= 0 then
	REM
	REM The caller found the app in the app cache,
	REM so just bring it to the front
	REM
	LoadApp = LRU_apps[LRU_index]
	if (LRU_index > 0) then
	    LRU_Delete(LoadApp)
	    LRU_Push(LoadApp)
	END IF
	goto theEnd
    END IF

    REM
    REM Because case difference problems are a pain to deal with
    REM we try to get around them by making a case insensitive
    REM loader.
    REM
  DIM trys[3] as string
    trys[0] = mls
    trys[1] = ToUpper(mls)
    trys[2] = ToLower(mls)

  DIM try as integer
  DIM tryString as string
  DIM errorString as string

    REM
    REM Begin the loop.  We can't use a FOR loop here because you
    REM can't have error handlers inside FOR loops (at least today
    REM you can't).
    REM
    try = 0
    tryAgain:
    onerror goto loadError

    REM
    REM Try loading this module
    REM
    LoadApp = LoadModule(trys[try])
    goto endLoad

    REM
    REM Okay, that didn't work...make a note of why so we can
    REM report a better error message later on.
    REM
    loadError:
    errorString = errorString + "as: " + trys[try] + " error " + str(GetError()) + "\r"
    resume nextTry

    nextTry:
    try = try + 1
    REM skip one we've seen before
    if try = 1 and trys[1] = trys[0] then
       try = 2
    end if
    if try = 2 and trys[2] = trys[0] then
       try = 3
    end if
    IF (try < 3) then
	goto tryAgain
    END IF

    endLoad:
    
    IF IsNull(LoadApp) then
        ErrorDialog("Error loading application\r" + errorString)
    ELSE
        LRU_Push(LoadApp)
    END IF
    
    theEnd:
END function

sub ModuleGoTo(m as module, context as string)
    onerror goto recover
    m:module_goTo(context)
    goto theEnd
    recover:
    resume theEnd
    theEnd:
END sub

sub LRU_Squeeze()
    REM Remove all null modules from the LRU array
    REM They can pop up if modules get unloaded for whatever reason
  dim i as integer
    i = 0
    do while (i < LRU_size)
	if (IsNull(LRU_apps[i])) then
	    LRU_DeleteIndex(i)
	else
	    i = i + 1
	end if
    loop
end sub

function LRU_GetIndexFromMLS(mls as string) as integer
  DIM stripped_mls as string
  DIM i as integer

    LRU_GetIndexFromMLS = -1
    stripped_mls = StripMLS(mls)
    for i = 0 to LRU_size - 1
	IF StrComp(StripMLS(GetSource(LRU_apps[i])), stripped_mls, 1) = 0 then
	    LRU_GetIndexFromMLS = i
	    exit for
	END IF
    NEXT i
theEnd:
END function

function LRU_GetIndexFromModule(m as module) as integer
  DIM i as integer
    LRU_Squeeze()
    LRU_GetIndexFromModule = -1
    for i = 0 to LRU_size - 1
	IF LRU_apps[i] = m then
	    LRU_GetIndexFromModule = i
	    exit for
	END IF
    NEXT i
theEnd:
END function

sub LRU_Push(m as module)
    onerror goto whoopse

    LRU_Squeeze()
    LRU_size = LRU_size + 1
    redim preserve LRU_apps[LRU_size]

    REM Copy existing ones down and stick the new one in front
    LRU_CopyDown(0)
    LRU_apps[0] = m

    goto theEnd
whoopse:
    resume theEnd
theEnd:
END sub

sub LRU_Delete(m as module)
    if (IsNull(m)) then
	LRU_Squeeze()
    else
	LRU_DeleteIndex(LRU_GetIndexFromModule(m))
    end if
END sub

sub LRU_CopyDown(from as integer)
  DIM i as integer
    for i = LRU_size - 1 to from - 1 step - 1
	if (i > 0) then
		LRU_apps[i] = LRU_apps[i - 1]
	end if
    NEXT i
END sub

sub LRU_CopyUp(copyto as integer)
  DIM i as integer
    for i = copyto to LRU_size - 2
	LRU_apps[i] = LRU_apps[i + 1]
    NEXT i
END sub

sub LRU_PrintOut(when as string)
    launcher.da_print = "LRU" 
    launcher.da_print = when
    launcher.da_print = "------------------"
    launcher.da_print = EOL
  DIM i as integer
    for i = 0 to LRU_size - 1
	launcher.da_print = i
	launcher.da_print = LRU_apps[i]
	launcher.da_print = GetSource(LRU_apps[i])
	launcher.da_print = EOL
    NEXT i
    launcher.da_print = "-------------------"
    launcher.da_print = EOL

	theEnd:
END sub

sub ErrorDialog(error as string)
    errorText.text = error
    errorDialog.left = 5
    errorDialog.top = 5
    errorDialog.visible = 1
END sub

sub errorButton_pressed(self as button)
	errorText.text = ""
end sub

sub LRU_DeleteIndex(LRU_index as integer)
    IF LRU_index >= 0 and LRU_index < LRU_size then
	LRU_CopyUp(LRU_index)
	LRU_size = LRU_size - 1
	redim preserve LRU_apps[LRU_size]
    END IF
end sub

function StripMLS(mls as string) as string
    REM Strip an MLS of its qualifier.  For example ROM://foo -> foo
  dim index as integer
    index = 0
    do
	mls = mid(mls, index+1, 32000)
	index = InStr(mls, "/")
	if (index = 0)
	    StripMLS = mls
	    exit do
	end if
    loop
end function

sub P(s as string)
    launcher.da_print = s
    launcher.da_print = EOL
END sub

function ToLower(s as string) as string
    if s = "" then
	ToLower = ""
    else
      dim first as string
	first = Left(s, 1)
	select case Asc(first)
	  case &H41 to &H5A
	    first = Chr((Asc(first) - &H41) + &H61)
	end select
	ToLower = first + ToLower(Right(s, Len(s) - 1))
    end if
end function

function ToUpper(s as string) as string
    if s = "" then
	ToUpper = ""
    else
      dim first as string
	first = Left(s, 1)
	select case Asc(first)
	  case &H61 to &H7A
	    first = Chr((Asc(first) - &H61) + &H41)
	end select
	ToUpper = first + ToUpper(Right(s, Len(s) - 1))
    end if
end function

sub errorDialog_aboutToOpen(self as dialog)
	errorText.width = 180
	errorText.height = 72
end sub

sub SetupDatabase() global
	REM
	REM Open the database for storing app's contexts.
	REM If the database does not exist, create it.
	REM If it already exists, that is fine.
	REM

    dim database as database
	database = MakeComponent("database", "app")
	CreateDatabase()

	
end sub


sub CreateDatabase()
	
	onerror goto res
	goto startFunc
	res:
	resume done
	startFunc:

    dim keyFields[0] as string
    dim keySort[0] as integer
	const DB_FILE_NAME "Apps"
	database.CreateDatabase(DB_FILE_NAME,		\
	4,						\
	0,						\
	keyFields,					\
	keyFields,					\
	keySort,					\
	keySort)

	database.AddField("app", "string", 0)
	database.AddField("context", "string", 0)
	database.CloseDatabase()
	done:
End Sub


function GetContextFromDB(applicationMLS as string) as string
REM  SYNOPSIS:	Searches the database for a context for the app
REM  CALLED BY:	CommonLoad
	dim errorCode as integer
	GetContextFromDB = ""
	database.OpenDatabase(DB_FILE_NAME, 2)
	REM
	REM if there are no rows, then the database will crash.
	if database.numRecords <> 0 then
		errorCode = database.SearchString("app", applicationMLS, 0, 0)
	else
		errorCode =1
	end if
	
	if errorCode = 0 then
		GetContextFromDB = database.GetField("app")
	end if
	database.CloseDatabase()
end function

Sub StoreContext(context as string, applicationMLS as string)
	dim errorCode as integer
	database.OpenDatabase(DB_FILE_NAME,2)
	errorCode= database.SearchString("app", applicationMLS, 0, 0)
	if errorCode then
		database.NewRecord()
	end if
	database.PutField("app", applicationMLS)
	database.PutField("context", context)
	database.PutRecord()
	REM
	REM Delete this next line (and this line)
	database.debugd = database.numRecords
	database.CloseDatabase()

end sub


    
