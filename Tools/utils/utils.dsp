# Microsoft Developer Studio Project File - Name="utils" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=utils - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "utils.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "utils.mak" CFG="utils - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "utils - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "utils - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName "utils"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "utils - Win32 Release"

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
# ADD LIB32 /nologo /out:"..\vc++\lib\utils.lib"

!ELSEIF  "$(CFG)" == "utils - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
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
# ADD LIB32 /nologo /out:"..\vc++\lib\utilsd.lib"

!ENDIF 

# Begin Target

# Name "utils - Win32 Release"
# Name "utils - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\fileargs.c
# End Source File
# Begin Source File

SOURCE=.\fileUtil.c
# End Source File
# Begin Source File

SOURCE=.\geode.c
# End Source File
# Begin Source File

SOURCE=.\hash.c
# End Source File
# Begin Source File

SOURCE=.\localize.c
# End Source File
# Begin Source File

SOURCE=.\malErr.c
# End Source File
# Begin Source File

SOURCE=.\malloc.c
# End Source File
# Begin Source File

SOURCE=.\memAl.c
# End Source File
# Begin Source File

SOURCE=.\memAlLkd.c
# End Source File
# Begin Source File

SOURCE=.\memFree.c
# End Source File
# Begin Source File

SOURCE=.\memInfo.c
# End Source File
# Begin Source File

SOURCE=.\memLock.c
# End Source File
# Begin Source File

SOURCE=.\memRAl.c
# End Source File
# Begin Source File

SOURCE=.\memRAlLk.c
# End Source File
# Begin Source File

SOURCE=.\memUtils.c
# End Source File
# Begin Source File

SOURCE=.\objSwap.c
# End Source File
# Begin Source File

SOURCE=.\printf.c
# End Source File
# Begin Source File

SOURCE=.\stClose.c
# End Source File
# Begin Source File

SOURCE=.\stCreate.c
# End Source File
# Begin Source File

SOURCE=.\stDest.c
# End Source File
# Begin Source File

SOURCE=.\stDup.c
# End Source File
# Begin Source File

SOURCE=.\stEnt.c
# End Source File
# Begin Source File

SOURCE=.\stEntNL.c
# End Source File
# Begin Source File

SOURCE=.\stHash.c
# End Source File
# Begin Source File

SOURCE=.\stIndex.c
# End Source File
# Begin Source File

SOURCE=.\stLook.c
# End Source File
# Begin Source File

SOURCE=.\stLookNL.c
# End Source File
# Begin Source File

SOURCE=.\stReloc.c
# End Source File
# Begin Source File

SOURCE=.\stSearch.c
# End Source File
# Begin Source File

SOURCE=.\sttab.c
# End Source File
# Begin Source File

SOURCE=.\vmAl.c
# End Source File
# Begin Source File

SOURCE=.\vmAlRd.c
# End Source File
# Begin Source File

SOURCE=.\vmAlUnas.c
# End Source File
# Begin Source File

SOURCE=.\vmAttach.c
# End Source File
# Begin Source File

SOURCE=.\vmAttr.c
# End Source File
# Begin Source File

SOURCE=.\vmClose.c
# End Source File
# Begin Source File

SOURCE=.\vmDetach.c
# End Source File
# Begin Source File

SOURCE=.\vmDirty.c
# End Source File
# Begin Source File

SOURCE=.\vmEmpty.c
# End Source File
# Begin Source File

SOURCE=.\vmFAl.c
# End Source File
# Begin Source File

SOURCE=.\vmFFree.c
# End Source File
# Begin Source File

SOURCE=.\vmFind.c
# End Source File
# Begin Source File

SOURCE=.\vmFree.c
# End Source File
# Begin Source File

SOURCE=.\vmGVers.c
# End Source File
# Begin Source File

SOURCE=.\vmHeader.c
# End Source File
# Begin Source File

SOURCE=.\vmInfo.c
# End Source File
# Begin Source File

SOURCE=.\vmLock.c
# End Source File
# Begin Source File

SOURCE=.\vmMapBlk.c
# End Source File
# Begin Source File

SOURCE=.\vmModUID.c
# End Source File
# Begin Source File

SOURCE=.\vmOpen.c
# End Source File
# Begin Source File

SOURCE=.\vmSetRel.c
# End Source File
# Begin Source File

SOURCE=.\vmUpdate.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\fileargs.h
# End Source File
# Begin Source File

SOURCE=.\fileUtil.h
# End Source File
# Begin Source File

SOURCE=.\geodeUt.h
# End Source File
# Begin Source File

SOURCE=.\localize.h
# End Source File
# Begin Source File

SOURCE=.\malErr.h
# End Source File
# Begin Source File

SOURCE=.\mallint.h
# End Source File
# Begin Source File

SOURCE=.\malloc.h
# End Source File
# Begin Source File

SOURCE=.\mem.h
# End Source File
# Begin Source File

SOURCE=.\memInt.h
# End Source File
# Begin Source File

SOURCE=.\objSwap.h
# End Source File
# Begin Source File

SOURCE=.\PHARLAP.H
# End Source File
# Begin Source File

SOURCE=.\putc.h
# End Source File
# Begin Source File

SOURCE=.\st.h
# End Source File
# Begin Source File

SOURCE=.\stInt.h
# End Source File
# Begin Source File

SOURCE=.\sttab.h
# End Source File
# Begin Source File

SOURCE=.\vm.h
# End Source File
# Begin Source File

SOURCE=.\vmInt.h
# End Source File
# End Group
# End Target
# End Project
