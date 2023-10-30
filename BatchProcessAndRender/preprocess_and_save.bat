@echo off
setlocal enabledelayedexpansion

rem set our folder locations
set "OutRep=C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Practical\\DJModel\\pbrt-v2-skin\\scenes\\geometry\\ProcDatasetHeads\\"
set "InRep=C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Experiments\\PilotDataSet\\"

rem the .cpp for obj2pbrt is in src\tools for post 2015 vers of pbrt2. 
rem ^^ i would build with a g++ compiler in vs code and mingw32 for convenience 

rem create symbolic links to get around local search Or just use copy solution here if you don't want admin privileges 

rem get names -- needs to be double quoted to be single argument 
python getFolderNames.py "!InRep!" "!OutRep!"


set "file_name=folder_names.txt"
set "file_path=!OutRep!!file_name!"
rem echo File path is !file_path!

rem pull into loop  -- use backq delims handles spaces 
for /f "usebackq delims=" %%i in ("!file_path!") do (
    set "directory_path=%%i"
    
    rem Add your processing code here for each directory path
    echo Processing directory: !directory_path!
    
    rem preprocess as the function does, and save to same dir
    python argpreprocess.py "!InRep!!directory_path!/mesh.obj" "!OutRep!!directory_path!meshProc.obj" 
    
    rem make header files available to local folder for processing by copying (make symoblic link if you want)
    copy "!OutRep!!directory_path!meshProc.obj.mtl" "".\""

    rem now use the coverter tool to create a pbrt
    obj2pbrt.exe "!OutRep!!directory_path!meshProc.obj" "!OutRep!!directory_path!meshProc.pbrt"

    rem delete headers for tidyness
    del ".\!directory_path!meshProc.obj.mtl"
)

endlocal
