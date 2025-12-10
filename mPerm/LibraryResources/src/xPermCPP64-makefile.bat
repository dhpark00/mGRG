@echo off
REM *** VS2019 x64 native commandline tools environment and MMA12 ***
REM OPEN "x64 Native Tools Command Prompt"

REM my personal dir of Wolfram Engine
SET MY_MMA_DIR=c:\Mathematica14

SET CompAdd=%MY_MMA_DIR%\SystemFiles\Links\MathLink\DeveloperKit\Windows-x86-64\CompilerAdditions
SET MPREP=%CompAdd%\mprep.exe

SET CL=/nologo /c /DWIN32 /D_WINDOWS /W3 /O2 /DNDEBUG /EHsc

SET LINK=/NOLOGO /SUBSYSTEM:windows /INCREMENTAL:no /PDB:NONE kernel32.lib user32.lib gdi32.lib

SET INCLUDE=%CompAdd%;%INCLUDE%

SET LIB=%CompAdd%;%LIB%

%MPREP% xPermCPP.tm -o xPermCPP-prep.cpp

CL xPermCPP-prep.cpp

LINK xPermCPP-prep.obj ml64i4m.lib /OUT:xPermCPP64.mswin

DEL *.obj

DEL xPermCPP-prep.cpp
