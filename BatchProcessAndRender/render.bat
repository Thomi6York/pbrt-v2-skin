@echo off
setlocal enabledelayedexpansion

REM Define the path to the CSV file
set csv_file=testVal.csv

REM Define a directory to store the scene files and rendered images
set output_dir= "..\Results"

REM Create the output directory if it doesn't exist
if not exist %output_dir% mkdir %output_dir%

rem create the scene files using edit from the csv
rem edit.exe -- currently compiled with gcc etc -- not working for on windows for now so run in VS code env 

REM Loop through the CSV file
for /f "tokens=1,2 delims=," %%a in (%csv_file%) do (
    set param_value1=%%a
    set param_value2=%%b

    REM Define the filename string
    set filename=Eum!param_value1!_Deoxy!param_value2!

    rem echo param_value1: !param_value1!
    rem echo param_value2: !param_value2!
    rem echo filename: !filename!

    REM Render the scene using pbrt and save to outfile
    E:\pbrt-v2-skinPat\bin\pbrt.exe --outfile E:\pbrt-v2-skinPat\results\!filename!.exr E:\pbrt-v2-skinPat\results\!filename!.pbrt

)

endlocal
