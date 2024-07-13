sub duplo_ui_ui_ui()
REM ========================================================================
REM
REM	Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM	FILE: 	newform.bas
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
REM	$Id: newform.bas,v 1.1 97/12/02 14:57:12 gene Exp $
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

	const	FORM_TOP	95
	const	FORM_LEFT	100
	const	FORM_HEIGHT	280
	const	FORM_WIDTH	320
	
	dim hackIntr as component
	hackIntr = MakeComponent("control","app")
	hackIntr!hackSetBuildTime(1)	

   REM
   REM It is very important to declare the new form as component rather 
   REM than as form.  Byte-compiled properties of specific classes can't 
   REM be intercepted by BentClass at build-time - so the form properties 
   REM wouldn't be saved out correctly.
   REM

	dim form1 as component
	form1 = MakeComponent("form","app")
	form1.name     = "form1"
	   form1.proto    = "form1"
	   form1.top   	  = FORM_TOP
	   form1.left     = FORM_LEFT
	   form1.sizeHControl = 0
	   form1.sizeVControl = 0
	   form1.height   = FORM_HEIGHT
	   form1.width    = FORM_WIDTH
	   form1.tile	  = 1
	   form1.visible  = 1

	hackIntr!hackSetBuildTime(0)	
	hackIntr!hackSelectComponent(form1)
	Update()

end sub
