# Microsoft Developer Studio Project File - Name="glue" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=glue - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "glue.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "glue.mak" CFG="glue - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "glue - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "glue - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""

!IF  "$(CFG)" == "glue - Win32 Release"

# PROP BASE Use_MFC
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f glue.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "glue.exe"
# PROP BASE Bsc_Name "glue.bsc"
# PROP BASE Target_Dir ""
# PROP Use_MFC
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "pmake -n"
# PROP Rebuild_Opt "clean"
# PROP Target_File "win32.md\glue.exe"
# PROP Bsc_Name ""
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "glue - Win32 Debug"

# PROP BASE Use_MFC
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f glue.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "glue.exe"
# PROP BASE Bsc_Name "glue.bsc"
# PROP BASE Target_Dir ""
# PROP Use_MFC
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "pmake"
# PROP Rebuild_Opt "clean"
# PROP Target_File "win32.md\glue.exe"
# PROP Bsc_Name ""
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "glue - Win32 Release"
# Name "glue - Win32 Debug"

!IF  "$(CFG)" == "glue - Win32 Release"

!ELSEIF  "$(CFG)" == "glue - Win32 Debug"

!ENDIF 

# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\borland.c
# End Source File
# Begin Source File

SOURCE=.\codeview.c
# End Source File
# Begin Source File

SOURCE=.\com.c
# End Source File
# Begin Source File

SOURCE=.\exe.c
# End Source File
# Begin Source File

SOURCE=.\font.c
# End Source File
# Begin Source File

SOURCE=.\geo.c
# End Source File
# Begin Source File

SOURCE=.\kernel.c
# End Source File
# Begin Source File

SOURCE=.\library.c
# End Source File
# Begin Source File

SOURCE=.\main.c
# End Source File
# Begin Source File

SOURCE=.\msl.c
# End Source File
# Begin Source File

SOURCE=.\msobj.c
# End Source File
# Begin Source File

SOURCE=.\obj.c
# End Source File
# Begin Source File

SOURCE=.\output.c
# End Source File
# Begin Source File

SOURCE=.\parse.c
# End Source File
# Begin Source File

SOURCE=.\pass1ms.c
# End Source File
# Begin Source File

SOURCE=.\pass1vm.c
# End Source File
# Begin Source File

SOURCE=.\pass2ms.c
# End Source File
# Begin Source File

SOURCE=.\pass2vm.c
# End Source File
# Begin Source File

SOURCE=.\segment.c
# End Source File
# Begin Source File

SOURCE=.\sym.c
# End Source File
# Begin Source File

SOURCE=.\vector.c
# End Source File
# Begin Source File

SOURCE=.\vm.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\borland.h
# End Source File
# Begin Source File

SOURCE=.\codeview.h
# End Source File
# Begin Source File

SOURCE=.\cv.h
# End Source File
# Begin Source File

SOURCE=.\geo.h
# End Source File
# Begin Source File

SOURCE=.\glue.h
# End Source File
# Begin Source File

SOURCE=.\library.h
# End Source File
# Begin Source File

SOURCE=.\msobj.h
# End Source File
# Begin Source File

SOURCE=.\obj.h
# End Source File
# Begin Source File

SOURCE=.\output.h
# End Source File
# Begin Source File

SOURCE=.\parse.h
# End Source File
# Begin Source File

SOURCE=.\segattrs.h
# End Source File
# Begin Source File

SOURCE=.\sym.h
# End Source File
# Begin Source File

SOURCE=.\tokens.h
# End Source File
# Begin Source File

SOURCE=.\vector.h
# End Source File
# End Group
# Begin Source File

SOURCE=.\local.mk
# End Source File
# End Target
# End Project
