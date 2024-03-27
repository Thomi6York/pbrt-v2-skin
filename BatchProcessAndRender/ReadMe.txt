Core pipeline: 

preprocess_and_save.bat takes the folders from the database and preprocess's the mesh to a renderable format 

render.bat does rendering for however many files as a batch job 

I recommend using conda to install pip and then use pip install to get pymeshlab. Make sure to run the batch in the shell or it won't work

You can also intall g compilers and libraries on conda, or do locally using mingw32 to run the obj2pbrt.exe 
