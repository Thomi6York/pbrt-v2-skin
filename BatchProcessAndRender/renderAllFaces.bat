@echo off
setlocal enabledelayedexpansion

rem set our folder locations
set "ScenePath=..\\scenes\\"
set "SetPath=..\\scenes\\geometry\\processed\\"
set "resultsPath=..\\results\\"


rem the .cpp for obj2pbrt is in src\tools for post 2015 vers of pbrt2. 
rem ^^ i would build with a g++ compiler in vs code and mingw32 for convenience 
rem create a conda environment, and simply use conda install pip and pip install pymeshlab to create the env

rem create symbolic links to get around local search Or just use a copy solution here if you don't want admin privileges 

set "file_name=folder_names.txt"
set "file_path=!SetPath!!file_name!"

rem pull into loop  -- use backq delims handles spaces 
for /f "usebackq delims=" %%i in ("!file_path!") do ( 
    set "directory_path=%%i"
    echo !directory_path!
    set "sceneFile=!ScenePath!!directory_path!Scene.pbrt"
    echo sceneFile is !sceneFile!
    set "exrFile=!resultsPath!!directory_path!.exr "
    echo exrFile is !exrFile!
    
    ..\bin\pbrt.exe !sceneFile! --outfile !exrFile!
)

echo all files rendered

endlocal

