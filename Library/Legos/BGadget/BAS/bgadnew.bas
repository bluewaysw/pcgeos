sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	newctrl.bas
REM	AUTHOR:	Martin Turon, January 24, 1995
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	1/24/95		Initial Version
REM
REM	DESCRIPTION:	Top level component for tool palette.
REM
REM	$Id: bgadnew.bas,v 1.1 98/03/12 20:29:57 martin Exp $
REM     Revision:   1.39
REM
REM ======================================================================

REM *********************************************************************
REM * 		Define This Module's Components
REM **********************************************************************
    const	BBM_NORMAL	0

  DIM BUILDER			as component	REM BuilderComponent
    export BUILDER

    dim newCtrl 		as component	REM control
    dim toolGroupList		as list
    DIM crosshairsTool		as button
    dim toolFrame		as component	REM switchframe

	newCtrl = MakeComponent("control", "top")
	
	toolGroupList = MakeComponent("list", newCtrl)
	  toolGroupList.proto = "toolGroupList"
	  toolGroupList.captions[0] = "Basic UI"
	  toolGroupList.captions[1] = "Primitive"
	  toolGroupList.captions[2] = "Deluxe"
	  toolGroupList.captions[3] = "Service"
	  toolGroupList.captions[4] = "Window"
	  toolGroupList.look = 2
	  toolGroupList.visible = 1

	crosshairsTool = MakeComponent("button", newCtrl)
	   crosshairsTool.caption       = "+"
	   crosshairsTool.visible	= 1
	   crosshairsTool.name		= "crosshairsTool"
	   crosshairsTool.proto		= "crosshairsTool"
	   crosshairsTool.graphic	= GetComplex(0)

REM	 DIM text1			as text
REM 	text1 = MakeComponent("text", newCtrl)
REM 	  text1.text = ""
REM 	  text1.visible = 1

	toolFrame = MakeComponent("switchframe", newCtrl)
	  toolFrame.caption = ""
	  toolFrame.visible = 1

duplo_start()

        newCtrl.visible = 1

end sub

sub duplo_start()

    REM Store some URLs, to be emitted later as LoadModule calls
    REM in duplo_ui
    REM
    REM 20 should be more than enough, but it would be nice
    REM to find some better solution
    REM g_aggLibsOnLiberty is an array of booleans
    REM set if the library exists on liberty.
    REM
  DIM g_numAggLibs as integer
  DIM g_aggLibs[20] as string
  DIM g_aggLibsOnLiberty[20] as integer

    g_numAggLibs = 0

  DIM GUI_MODULE as string
  DIM PRIM_MODULE as string
  DIM DELX_MODULE as string
  DIM SERV_MODULE as string
  DIM MOD_VAR as string
    
    GUI_MODULE = "DOS://~U/BASIC/SN-GUI"
    PRIM_MODULE = "DOS://~U/BASIC/SN-PRIM"
    DELX_MODULE = "DOS://~U/BASIC/SN-DELX"
    SERV_MODULE = "DOS://~U/BASIC/SN-SERV"
REM    MOD_VAR = "int__module"

    CONST WIN_MODULE "DOS://~U/BASIC/SN-WIN"

    newCtrl.name    = "newCtrl"
    newCtrl.proto   = "newCtrl"

    toolGroupList.selectedItem = 0
    toolGroupList_changed(toolGroupList, 0)

end sub

function duplo_description(libertyP as integer) as string
    REM Returns a "description" of this module, to go into duplo_ui
    REM
  DIM desc as string
  DIM i as integer

    IF g_numAggLibs <> 0 THEN
	desc = "REM &bgadnew& " + state_get() + "\r"
REM	desc = desc + "DIM " + MOD_VAR + " as module\r"

	FOR i = 1 TO g_numAggLibs
	    REM Don't loadmodule IF this agg lib isn't available on liberty
	    REM
	    IF (g_aggLibsOnLiberty[i-1] OR (NOT libertyP)) THEN
		desc = desc + "UseLibrary( LoadModuleShared(\""
		desc = desc + g_aggLibs[i-1] + "\") )\r"
	    END IF
	NEXT i
    ELSE
	desc = ""
    END IF
    duplo_description = desc
END function

sub addText(s as string)
    REM text1.text = text1.text+"<"+s+">"
END sub

sub state_set(state as string)
    REM Set the "state" for this module.
    REM It will later be retrieved with state_get
    REM

  DIM m as module
  DIM aggURL as string
  DIM libertyTok as string

    REM we assume state matches "\([^ ]+ \)*" where [^ ]+ is a URL
    REM ... actually, each URL is followed by +LIBERTY or -LIBERTY
    REM depending on whether or not the agg lib exists on liberty
    REM
    g_numAggLibs = 0
    do while (LEN(state) <> 0)
	aggURL = nextToken(state)
	IF aggURL = "" THEN
	    EXIT do
	END IF
	state = popToken(state)
	g_aggLibs[g_numAggLibs] = aggURL

	libertyTok = nextToken(state)
	IF libertyTok = "+LIBERTY" THEN
	    state = popToken(state)
	    g_aggLibsOnLiberty[g_numAggLibs] = 1
	ELSE IF libertyTok = "-LIBERTY" THEN
	    state = popToken(state)
	    g_aggLibsOnLiberty[g_numAggLibs] = 0
	ELSE
	    REM must be a url -- old app that doesn't use the new format
	    REM just use some reasonable default.  Don't pop.
	    g_aggLibsOnLiberty[g_numAggLibs] = 1
	END IF
	g_numAggLibs = g_numAggLibs + 1
    loop

REM     text1.text = text1.text+ "0[" + duplo_description(0) + "]"
REM     text1.text = "1[" + duplo_description(1) + "]\r"
END sub
function state_get() as string
  DIM state as string
  DIM i as integer
    state = ""
    FOR i = 1 TO g_numAggLibs
	state = state + g_aggLibs[i-1] + " "
	IF g_aggLibsOnLiberty[i-1] THEN
	    state = state + "+LIBERTY "
	ELSE
	    state = state + "-LIBERTY "
	END IF
    NEXT i
    state_get = state
END function

sub AddURL(url as string, aggOnLiberty as integer)
    REM Add a URL to our list of URLS that will be written out
    REM with our state; duplicates will be ignored.
    REM
    REM aggOnLiberty is non-zero IF <url> exists on liberty
    REM
    REM SN-DELX calls this.
    REM
  DIM i as integer
  DIM notHere as integer

    notHere = 1

    FOR i = 1 TO g_numAggLibs
	IF g_aggLibs[i-1] = url then
	    notHere = 0
	    exit FOR
	END IF
    NEXT i

    IF (notHere = 1) then
	g_aggLibs[g_numAggLibs] = url
	g_aggLibsOnLiberty[g_numAggLibs] = aggOnLiberty
	g_numAggLibs = g_numAggLibs + 1
    END if
END sub

sub crosshairsTool_pressed (self as component)
    newCtrl!hackSetMode(BBM_NORMAL, 0)
end sub

sub toolGroupList_changed(self as component, index as integer)
  dim url as string
  DIM m as module

    select case index
      case 0  
	m = toolFrame!switchTo(GUI_MODULE)
      case 1  
        m = toolFrame!switchTo(PRIM_MODULE)
      case 2  
        m = toolFrame!switchTo(DELX_MODULE)
rem	m = toolFrame!load(DELX_MODULE)
	m:parentModule = CurModule()
      case 3  
	m = toolFrame!switchTo(SERV_MODULE)
      case 4  
	m = toolFrame!switchTo(WIN_MODULE)
    end select
    m:BUILDER = BUILDER
end sub

function nextToken(s as string) as string
  DIM start as integer
  DIM l as integer
    
    REM skip initial whitespace
    FOR l = 1 TO len(s)
	IF ASC(MID(s,l,1)) <> 32 THEN
	    EXIT FOR
	END IF
    NEXT l

    start = l

    FOR l = start to len(s)
	REM Look for a space (ascii 32) at index l
	IF ASC(MID(s,l,1)) = 32 THEN
	    EXIT FOR
	END IF
    NEXT l
    nextToken = MID(s, start, l-start)
END function

function popToken(s as string) as string
  DIM l as integer
    
    REM skip initial whitespace
    FOR l = 1 TO len(s)
	IF ASC(MID(s,l,1)) <> 32 THEN
	    EXIT FOR
	END IF
    NEXT l

    FOR l = l to len(s)
	REM Look for a space (ascii 32) at index l
	IF ASC(MID(s,l,1)) = 32 THEN
	    EXIT FOR
	END IF
    NEXT l
    popToken = MID(s, l, 30000)

END function

sub ConnectToBuilder(optr as component)
    REM Called when this prop box is enabled
    BUILDER = optr
end sub
