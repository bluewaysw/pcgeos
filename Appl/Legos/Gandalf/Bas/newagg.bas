sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	newagg.bas
REM	AUTHOR:	Martin Turon, September 18, 1995
REM
REM     REVISION HISTORY
REM   		Name	Date		Description
REM   		----	----		-----------
REM   		martin	9/18/95		Initial Version
REM
REM	DESCRIPTION:	Creates the default form that comes up when 
REM			gandalf is opened, or a new project is started.
REM
REM	$Id: newagg.bas,v 1.1 97/12/02 14:57:14 gene Exp $
REM	$Revision: 1.1 $
REM
REM ======================================================================


   REM
   REM  The hackIntr component is a sneaky way to get the builder to
   REM	do the correct things with our new form by sending it messages 
   REM	directly.  Eventually we need some kind of syntax for sending 
   REM	actions directly to the interpreter:
   REM
   REM		dim intr as interpreter 	(returns optr to interpreter)
   REM		intr!setBuildTime(1)
   REM

    const TRUE 1
    const FALSE 0

    const	AGG_TOP		75
    const	AGG_LEFT	90
    const	AGG_HEIGHT	200
    const	AGG_WIDTH	200

  dim hackIntr as component
    hackIntr = MakeComponent("control","app")
    hackIntr!hackSetBuildTime(1)	

  dim top as component
    top = MakeComponent("form","app")
    top.name		= "top"
    top.caption		= "top"
    top.proto		= "top"
    top.top		= AGG_TOP
    top.left		= AGG_LEFT
    top.height		= AGG_HEIGHT
    top.width		= AGG_WIDTH
    top.tile		= TRUE
    top.sizeHControl	= 0
    top.sizeVControl 	= 0
    top.visible		= TRUE
    top._noOutput	= TRUE

REM  DIM topGroup as component
REM    topGroup = MakeComponent("group", top)
REM    topGroup.name = "topGroup"
REM    topGroup.proto = "topGroup"
REM    topGroup._trueClass = "agggroup"
REM    topGroup.visible = 1

    hackIntr!hackSetBuildTime(0)	
    Update()

end sub
