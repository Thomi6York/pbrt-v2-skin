@echo off
setlocal enabledelayedexpansion

rem set our folder locations
set "OutRep=..\\scenes\geometry\\processed\\"
set "InRep=..\\scenes\\PilotDataSet\\"

rem the .cpp for obj2pbrt is in src\tools for post 2015 vers of pbrt2. 
rem ^^ i would build with a g++ compiler in vs code and mingw32 for convenience 
rem create a conda environment, and simply use conda install pip and pip install pymeshlab to create the env

rem create symbolic links to get around local search Or just use a copy solution here if you don't want admin privileges 

rem get names -- needs to be double-quoted to be a single argument 
python getFolderNames.py "!InRep!" "!OutRep!"

set "file_name=folder_names.txt"
set "file_path=!OutRep!!file_name!"

rem pull into loop  -- use backq delims handles spaces 
for /f "usebackq delims=" %%i in ("!file_path!") do ( 
    set "directory_path=%%i"
    echo !directory_path!
    set "inFile=!InRep!!directory_path!\\mesh.obj"
    echo inFile is !inFile!
    set "procFile=!OutRep!!directory_path!meshProc.obj"
    echo procFile is !procFile!
    set "pbrtFile=!OutRep!!directory_path!mesh.pbrt"
    echo pbrtFile is !pbrtFile!

    rem Add your processing code here for each directory path
    echo Processing directory: !directory_path!
    
    rem preprocess as the function does, and save to the same dir
    rem rememember directory_path is the folder name for input and output as a file name 
    python argpreprocess.py "!inFile!" "!procFile!" 
    
    rem make header files available to local folder for processing by copying (make symoblic link if you want)
    copy "!OutRep!!directory_path!meshProc.obj.mtl" ".\\"

    rem now use the converter tool to create a pbrt
    obj2pbrt.exe "!procFile!" "!pbrtFile!"

    rem delete headers for tidiness
    del ".\!directory_path!meshProc.obj.mtl"

    rem remove pbrt headers which disrupt texture 
    python headerRemove.py "!pbrtFile!"

    echo processed !directory_path! 
)

echo all files processed 

endlocal

