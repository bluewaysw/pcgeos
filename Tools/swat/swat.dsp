# Microsoft Developer Studio Project File - Name="swat" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=swat - Win32 Debug PM
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "swat.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "swat.mak" CFG="swat - Win32 Debug PM"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "swat - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Debug 32bit" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Release 32bit" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Debug PM" (based on "Win32 (x86) Console Application")
!MESSAGE "swat - Win32 Release PM" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "swat"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "swat - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /I "$(PerforceRoot)\G4\pcgeos\Tools\include" /I "$(PerforceRoot)\G4\pcgeos\Tools\utils" /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /map /machine:I386 /libpath:"..\vc++\lib"

!ELSEIF  "$(CFG)" == "swat - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /Gm /GX /Zi /Od /I "$(PerforceRoot)\G4\pcgeos\Tools\include" /I "$(PerforceRoot)\G4\pcgeos\Tools\utils" /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /FR /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compatd.lib utilsd.lib ntcursesd.lib tcld.lib lstd.lib winutild.lib libc.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /pdbtype:sept /libpath:"..\vc++\lib"
# SUBTRACT LINK32 /pdb:none

!ELSEIF  "$(CFG)" == "swat - Win32 Debug 32bit"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "swat___Win32_Debug_32bit"
# PROP BASE Intermediate_Dir "swat___Win32_Debug_32bit"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug32"
# PROP Intermediate_Dir "Debug32"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /Gm /GX /Zi /Od /I "." /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /FR /YX /FD /GZ /c
# ADD CPP /nologo /Gm /GX /Zi /Od /I "$(PerforceRoot)\G4\pcgeos\Tools\include" /I "$(PerforceRoot)\G4\pcgeos\Tools\utils" /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /FR /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compatd.lib utilsd.lib ntcursesd.lib tcld.lib lstd.lib winutild.lib libc.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /pdbtype:sept
# SUBTRACT BASE LINK32 /pdb:none
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compatd.lib utilsd.lib ntcursesd.lib tcld.lib lstd.lib winutild.lib libc.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /out:"Debug32/swat32.exe" /pdbtype:sept /libpath:"..\vc++\lib"
# SUBTRACT LINK32 /pdb:none /map

!ELSEIF  "$(CFG)" == "swat - Win32 Release 32bit"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "swat___Win32_Release_32bit"
# PROP BASE Intermediate_Dir "swat___Win32_Release_32bit"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release32"
# PROP Intermediate_Dir "Release32"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /I "." /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /I "$(PerforceRoot)\G4\pcgeos\Tools\include" /I "$(PerforceRoot)\G4\pcgeos\Tools\utils" /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /map /machine:I386 /out:"Release32/swat32.exe" /libpath:"..\vc++\lib"

!ELSEIF  "$(CFG)" == "swat - Win32 Debug PM"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "swat___Win32_Debug_PM"
# PROP BASE Intermediate_Dir "swat___Win32_Debug_PM"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "DebugPM"
# PROP Intermediate_Dir "DebugPM"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /Gm /GX /Zi /Od /I "." /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /FR /YX /FD /GZ /c
# ADD CPP /nologo /Gm /GX /Zi /Od /I "$(PerforceRoot)\G4\pcgeos\Tools\include" /I "$(PerforceRoot)\G4\pcgeos\Tools\utils" /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /D GEOS32=1 /FR /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compatd.lib utilsd.lib ntcursesd.lib tcld.lib lstd.lib winutild.lib libc.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /out:"Debug32/swat32.exe" /pdbtype:sept
# SUBTRACT BASE LINK32 /pdb:none /map
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compatd.lib utilsd.lib ntcursesd.lib tcld.lib lstd.lib winutild.lib libc.lib /nologo /subsystem:console /debug /machine:I386 /nodefaultlib:"library" /nodefaultlib:"libcd" /out:"DebugPM/swat32.exe" /pdbtype:sept /libpath:"..\vc++\lib"
# SUBTRACT LINK32 /pdb:none /map

!ELSEIF  "$(CFG)" == "swat - Win32 Release PM"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "swat___Win32_Release_PM"
# PROP BASE Intermediate_Dir "swat___Win32_Release_PM"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "ReleasePM"
# PROP Intermediate_Dir "ReleasePM"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /I "." /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /I "." /I "..\include" /I "..\utils" /I "..\vc++\include" /I "..\pmake\src\lib\lst" /I "..\pmake\src\lib\include" /I "tcl" /I "ntcurses" /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "ISSWAT" /D REGS_32=1 /D GEOS32=1 /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /map /machine:I386 /out:"Release32/swat32.exe"
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib compat.lib utils.lib ntcurses.lib tcl.lib lst.lib winutil.lib /nologo /subsystem:console /map /machine:I386 /out:"ReleasePM/swat32.exe" /libpath:"..\vc++\lib"

!ENDIF 

# Begin Target

# Name "swat - Win32 Release"
# Name "swat - Win32 Debug"
# Name "swat - Win32 Debug 32bit"
# Name "swat - Win32 Release 32bit"
# Name "swat - Win32 Debug PM"
# Name "swat - Win32 Release PM"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\break.c
# End Source File
# Begin Source File

SOURCE=.\buf.c
# End Source File
# Begin Source File

SOURCE=.\cache.c
# End Source File
# Begin Source File

SOURCE=.\cmd.c
# End Source File
# Begin Source File

SOURCE=.\cmdAM.c
# End Source File
# Begin Source File

SOURCE=.\cmdNZ.c
# End Source File
# Begin Source File

SOURCE=.\curses.c
# End Source File
# Begin Source File

SOURCE=.\event.c
# End Source File
# Begin Source File

SOURCE=.\expr.c
# End Source File
# Begin Source File

SOURCE=.\expr.y

!IF  "$(CFG)" == "swat - Win32 Release"

!ELSEIF  "$(CFG)" == "swat - Win32 Debug"

!ELSEIF  "$(CFG)" == "swat - Win32 Debug 32bit"

# Begin Custom Build
InputPath=.\expr.y

"expr.c" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	bison expr.y 
	copy expr.tab.c expr.c 
	
# End Custom Build

!ELSEIF  "$(CFG)" == "swat - Win32 Release 32bit"

# Begin Custom Build
InputPath=.\expr.y

"expr.c" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	bison expr.y 
	copy expr.tab.c expr.c 
	
# End Custom Build

!ELSEIF  "$(CFG)" == "swat - Win32 Debug PM"

# Begin Custom Build
InputPath=.\expr.y

"expr.c" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	bison expr.y 
	copy expr.tab.c expr.c 
	
# End Custom Build

!ELSEIF  "$(CFG)" == "swat - Win32 Release PM"

# Begin Custom Build
InputPath=.\expr.y

"expr.c" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	bison expr.y 
	copy expr.tab.c expr.c 
	
# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\file.c
# End Source File
# Begin Source File

SOURCE=.\gc.c
# End Source File
# Begin Source File

SOURCE=.\handle.c
# End Source File
# Begin Source File

SOURCE=.\help.c
# End Source File
# Begin Source File

SOURCE=.\i86Opc.c
# End Source File
# Begin Source File

SOURCE=.\ibm.c
# End Source File
# Begin Source File

SOURCE=.\ibm86.c
# End Source File
# Begin Source File

SOURCE=.\ibmCache.c
# End Source File
# Begin Source File

SOURCE=.\ibmCmd.c
# End Source File
# Begin Source File

SOURCE=.\ibmXms.c
# End Source File
# Begin Source File

SOURCE=.\mouse.c
# End Source File
# Begin Source File

SOURCE=.\netware.c
# End Source File
# Begin Source File

SOURCE=.\win32.md\npipe.c
# End Source File
# Begin Source File

SOURCE=.\win32.md\ntserial.c
# End Source File
# Begin Source File

SOURCE=.\patient.c
# End Source File
# Begin Source File

SOURCE=.\rpc.c
# End Source File
# Begin Source File

SOURCE=.\shell.c
# End Source File
# Begin Source File

SOURCE=.\src.c
# End Source File
# Begin Source File

SOURCE=.\swat.c
# End Source File
# Begin Source File

SOURCE=.\sym.c
# End Source File
# Begin Source File

SOURCE=.\table.c
# End Source File
# Begin Source File

SOURCE=.\tclDebug.c
# End Source File
# Begin Source File

SOURCE=.\type.c
# End Source File
# Begin Source File

SOURCE=.\ui.c
# End Source File
# Begin Source File

SOURCE=.\value.c
# End Source File
# Begin Source File

SOURCE=.\var.c
# End Source File
# Begin Source File

SOURCE=.\vector.c
# End Source File
# Begin Source File

SOURCE=.\version.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\assert.h
# End Source File
# Begin Source File

SOURCE=.\assert.h.new
# End Source File
# Begin Source File

SOURCE=.\break.h
# End Source File
# Begin Source File

SOURCE=.\buf.h
# End Source File
# Begin Source File

SOURCE=.\cache.h
# End Source File
# Begin Source File

SOURCE=.\cmd.h
# End Source File
# Begin Source File

SOURCE=.\cmdNZ.h
# End Source File
# Begin Source File

SOURCE=.\event.h
# End Source File
# Begin Source File

SOURCE=.\expr.h
# End Source File
# Begin Source File

SOURCE=.\file.h
# End Source File
# Begin Source File

SOURCE=.\gc.h
# End Source File
# Begin Source File

SOURCE=.\geos.h
# End Source File
# Begin Source File

SOURCE=.\handle.h
# End Source File
# Begin Source File

SOURCE=.\help.h
# End Source File
# Begin Source File

SOURCE=.\i86Opc.h
# End Source File
# Begin Source File

SOURCE=.\ibm.h
# End Source File
# Begin Source File

SOURCE=.\ibm86.h
# End Source File
# Begin Source File

SOURCE=.\ibmCache.h
# End Source File
# Begin Source File

SOURCE=.\ibmCmd.h
# End Source File
# Begin Source File

SOURCE=.\ibmInt.h
# End Source File
# Begin Source File

SOURCE=.\ibmXms.h
# End Source File
# Begin Source File

SOURCE=.\mouse.h
# End Source File
# Begin Source File

SOURCE=.\netware.h
# End Source File
# Begin Source File

SOURCE=.\npipe.h
# End Source File
# Begin Source File

SOURCE=.\ntserial.h
# End Source File
# Begin Source File

SOURCE=.\patient.h
# End Source File
# Begin Source File

SOURCE=.\private.h
# End Source File
# Begin Source File

SOURCE=.\rpc.h
# End Source File
# Begin Source File

SOURCE=.\safesjmp.h
# End Source File
# Begin Source File

SOURCE=.\serial.h
# End Source File
# Begin Source File

SOURCE=.\setjmp.h
# End Source File
# Begin Source File

SOURCE=.\setjmp.h.new
# End Source File
# Begin Source File

SOURCE=.\shell.h
# End Source File
# Begin Source File

SOURCE=.\src.h
# End Source File
# Begin Source File

SOURCE=.\swat.h
# End Source File
# Begin Source File

SOURCE=.\sym.h
# End Source File
# Begin Source File

SOURCE=.\table.h
# End Source File
# Begin Source File

SOURCE=.\tclDebug.h
# End Source File
# Begin Source File

SOURCE=.\tokens.h
# End Source File
# Begin Source File

SOURCE=.\type.h
# End Source File
# Begin Source File

SOURCE=.\ui.h
# End Source File
# Begin Source File

SOURCE=.\value.h
# End Source File
# Begin Source File

SOURCE=.\var.h
# End Source File
# Begin Source File

SOURCE=.\vector.h
# End Source File
# Begin Source File

SOURCE=.\vmsym.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# Begin Group "lib.new"

# PROP Default_Filter ""
# Begin Group "Internal"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\lib.new\Internal\1XERRS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\ATRON.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\BULLET.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\CHART.TCL
# End Source File
# Begin Source File

SOURCE=".\lib.new\Internal\check-handles.tcl"
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\CLAVIN.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\COVERAGE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\CWATCH.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\DDEBUG.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\DRIVE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\DUMPTEXT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\EMACS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\FOAM.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\GEODE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\geoplanner.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\GEOWRITE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\GLOSS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\GMGR.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\helpInt.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\HTREE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\ICLAS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\MAKEDISK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\MAKEFREF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\MAKEREF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\NETLIB.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\NIMBUS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PBLK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PCM.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PHELP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PKMAP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PRINTQ.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\PSCRIPT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\RAMDISK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SHELL.TCL
# End Source File
# Begin Source File

SOURCE=".\lib.new\Internal\show-int13-calls.tcl"
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SNAP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SOCKET.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SPLINE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SWAP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\SWAPDR.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\TCP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\TELNET.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\TMP1.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\TPRINT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\trackResourceCall.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\UIPERF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\UNIX.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\VIDEO.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\WPROC.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\Internal\WSHELL.TCL
# End Source File
# End Group
# Begin Source File

SOURCE=.\lib.new\APPCACHE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\ASSIGN.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\ATS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\AUTOLOAD.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\BITS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\BORROW.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\BPTUTILS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\BRKLOAD.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CALL.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CELL.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CHUNKARR.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CLASS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CLIPBRD.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CURREGS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CURSES.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\CWD.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\DB.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\DBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\DDETACH.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\DEBUG.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\DOC.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\dos.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\EC.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\EVENT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\FATALERR.TCL
# End Source File
# Begin Source File

SOURCE=".\lib.new\FILE-ERR.TCL"
# End Source File
# Begin Source File

SOURCE=.\lib.new\FILEXFER.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\FLAGS.TCL
# End Source File
# Begin Source File

SOURCE=".\lib.new\FMT-INST.TCL"
# End Source File
# Begin Source File

SOURCE=.\lib.new\FP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\FS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\GCN.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\GEODEX.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\GRAB.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\GROBJ.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HEAP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HELP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HISTORY.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HUGEARR.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HUGELMEM.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\HWBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\IACP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\IBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\IGNERR.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\INPUT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\INT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\IRLMP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\ISTEP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\LISP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\LIST.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\LM.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\LOG.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\LOOP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\MEMORY.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\MOUSE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\NAVHELP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJCOUNT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJECT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJPROF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJTREE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\OBJWATCH.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PATCH.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PATIENT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PINI.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\POBJECT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PRGFLOAT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PRINT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PROCESS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PROCLOG.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PSSHEET.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\ptext.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\PUTILS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\PVARDATA.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\pvm.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\PWWF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\REF.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\REFCOUNT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\REGION.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\RESOLVER.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\RTCM.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\SAMPLE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\SETCC.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\SHOWCALL.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\SMATCH.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\SRCLIST.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\STACK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\swat.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\TBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\THREAD.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\TIMEBRK.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\TIMER.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\TIMING.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\TOPLEVEL.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\USER.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\VERBKEYS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\VERBOSE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\vm.tcl
# End Source File
# Begin Source File

SOURCE=.\lib.new\WHATAT.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\WHATIS.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\WINTREE.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\X11.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\XIP.TCL
# End Source File
# Begin Source File

SOURCE=.\lib.new\ZAP.TCL
# End Source File
# End Group
# End Target
# End Project
