# Microsoft Developer Studio Project File - Name="flllib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=flllib - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "flllib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "flllib.mak" CFG="flllib - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "flllib - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "flllib - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "flllib"
# PROP Scc_LocalPath "."

!IF  "$(CFG)" == "flllib - Win32 Release"

# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f flllib.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "flllib.exe"
# PROP BASE Bsc_Name "flllib.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "NMAKE /f flllib.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "flllib.exe"
# PROP Bsc_Name "flllib.bsc"
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "flllib - Win32 Debug"

# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f flllib.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "flllib.exe"
# PROP BASE Bsc_Name "flllib.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "make.bat"
# PROP Rebuild_Opt "full"
# PROP Target_File "flllib.geo"
# PROP Bsc_Name "flllib.bsc"
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "flllib - Win32 Release"
# Name "flllib - Win32 Debug"

!IF  "$(CFG)" == "flllib - Win32 Release"

!ELSEIF  "$(CFG)" == "flllib - Win32 Debug"

!ENDIF 

# Begin Group "Source"

# PROP Default_Filter "*.goc"
# Begin Source File

SOURCE=.\FILELIST.GOC
# End Source File
# Begin Source File

SOURCE=.\FL_LOCAL.GOC
# End Source File
# Begin Source File

SOURCE=.\FL_PATH.GOC
# End Source File
# Begin Source File

SOURCE=.\FL_VOL.GOC
# End Source File
# End Group
# Begin Group "Headers"

# PROP Default_Filter "*.goh"
# Begin Source File

SOURCE=..\..\..\CInclude\Objects\FILELIST.GOH
# End Source File
# Begin Source File

SOURCE=.\fllui.goh
# End Source File
# Begin Source File

SOURCE=.\internal.goh
# End Source File
# End Group
# Begin Group "Reference"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\..\CInclude\ExtUI\TABLE.GOH
# End Source File
# End Group
# Begin Source File

SOURCE=.\flllib.GP
# End Source File
# Begin Source File

SOURCE=.\todo.txt
# End Source File
# Begin Source File

SOURCE=.\UP.BAT
# End Source File
# End Target
# End Project
