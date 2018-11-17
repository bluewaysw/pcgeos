# Microsoft Developer Studio Project File - Name="ftplib" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=ftplib - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "ftplib.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ftplib.mak" CFG="ftplib - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ftplib - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "ftplib - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "ftplib"
# PROP Scc_LocalPath "."

!IF  "$(CFG)" == "ftplib - Win32 Release"

# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f ftplib.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "ftplib.exe"
# PROP BASE Bsc_Name "ftplib.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "NMAKE /f ftplib.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "ftplib.exe"
# PROP Bsc_Name "ftplib.bsc"
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "ftplib - Win32 Debug"

# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f ftplib.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "ftplib.exe"
# PROP BASE Bsc_Name "ftplib.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "make.bat"
# PROP Rebuild_Opt "full"
# PROP Target_File "ftplib.geo"
# PROP Bsc_Name "ftplib.bsc"
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "ftplib - Win32 Release"
# Name "ftplib - Win32 Debug"

!IF  "$(CFG)" == "ftplib - Win32 Release"

!ELSEIF  "$(CFG)" == "ftplib - Win32 Debug"

!ENDIF 

# Begin Group "Classes"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\Classes\FTP.GOC
# End Source File
# End Group
# Begin Group "CInclude"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\..\CInclude\Objects\FTPC.GOH
# End Source File
# End Group
# Begin Group "Reference"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\..\CInclude\FILE.H
# End Source File
# Begin Source File

SOURCE=..\..\..\CInclude\SOCKET.GOH
# End Source File
# Begin Source File

SOURCE=..\..\..\CInclude\SOCKMISC.H
# End Source File
# End Group
# Begin Source File

SOURCE=.\INTERNAL.H
# End Source File
# End Target
# End Project
