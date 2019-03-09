# Microsoft Developer Studio Project File - Name="ntcurses" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=ntcurses - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "ntcurses.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ntcurses.mak" CFG="ntcurses - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ntcurses - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "ntcurses - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "ntcurses"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "ntcurses - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\..\vc++\lib\ntcurses.lib"

!ELSEIF  "$(CFG)" == "ntcurses - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "ntcurses___Win32_Debug"
# PROP BASE Intermediate_Dir "ntcurses___Win32_Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"..\..\vc++\lib\ntcursesd.lib"

!ENDIF 

# Begin Target

# Name "ntcurses - Win32 Release"
# Name "ntcurses - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\attrib.c
# End Source File
# Begin Source File

SOURCE=.\beep.c
# End Source File
# Begin Source File

SOURCE=.\charadd.c
# End Source File
# Begin Source File

SOURCE=.\chardel.c
# End Source File
# Begin Source File

SOURCE=.\charget.c
# End Source File
# Begin Source File

SOURCE=.\charins.c
# End Source File
# Begin Source File

SOURCE=.\charpick.c
# End Source File
# Begin Source File

SOURCE=.\clrtobot.c
# End Source File
# Begin Source File

SOURCE=.\clrtoeol.c
# End Source File
# Begin Source File

SOURCE=.\endwin.c
# End Source File
# Begin Source File

SOURCE=.\initscr.c
# End Source File
# Begin Source File

SOURCE=.\linedel.c
# End Source File
# Begin Source File

SOURCE=.\lineins.c
# End Source File
# Begin Source File

SOURCE=.\longname.c
# End Source File
# Begin Source File

SOURCE=.\move.c
# End Source File
# Begin Source File

SOURCE=.\mvcursor.c
# End Source File
# Begin Source File

SOURCE=.\newwin.c
# End Source File
# Begin Source File

SOURCE=.\ntio.c
# End Source File
# Begin Source File

SOURCE=.\options.c
# End Source File
# Begin Source File

SOURCE=.\overlay.c
# End Source File
# Begin Source File

SOURCE=.\prntscan.c
# End Source File
# Begin Source File

SOURCE=.\refresh.c
# End Source File
# Begin Source File

SOURCE=.\setmode.c
# End Source File
# Begin Source File

SOURCE=.\setterm.c
# End Source File
# Begin Source File

SOURCE=.\stradd.c
# End Source File
# Begin Source File

SOURCE=.\strget.c
# End Source File
# Begin Source File

SOURCE=.\tabsize.c
# End Source File
# Begin Source File

SOURCE=.\termmisc.c
# End Source File
# Begin Source File

SOURCE=.\unctrl.c
# End Source File
# Begin Source File

SOURCE=.\winclear.c
# End Source File
# Begin Source File

SOURCE=.\windel.c
# End Source File
# Begin Source File

SOURCE=.\winerase.c
# End Source File
# Begin Source File

SOURCE=.\winmove.c
# End Source File
# Begin Source File

SOURCE=.\winscrol.c
# End Source File
# Begin Source File

SOURCE=.\wintouch.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\curses.h
# End Source File
# Begin Source File

SOURCE=.\curspriv.h
# End Source File
# Begin Source File

SOURCE=.\initscr.h
# End Source File
# End Group
# End Target
# End Project
