@echo off
setlocal enabledelayedexpansion

rem set our folder locations, use double slash for python
set "OutRep=C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Practical\\DJModel\\pbrt-v2-skin\\scenes\\geometry\\ProcDatasetHeads\\"
set "InRep=C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Experiments\\PilotDataSet\\"

rem the .cpp for obj2pbrt is in src\tools for post-2015 vers of pbrt2. pbrt3 onwards accept .ply directly
rem ^^ I would build with a g++ compiler in VS Code and Mingw32 for convenience 

rem create symbolic links to get around local search Or just use a copy solution here if you don't want admin privileges 

rem get names -- needs to be double-quoted to be a single argument 
python getFolderNames.py "!InRep!" "!OutRep!"

set "file_name=folder_names.txt"
set "file_path=!OutRep!!file_name!"
echo File path is !file_path!

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
    
    rem make header files available to the local folder for processing by copying (make symbolic link if you want)
    copy "!procFile!.mtl" ".\"

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

