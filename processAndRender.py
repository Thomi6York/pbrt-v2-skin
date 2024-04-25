import glob
import os
import glob
import shlex
import subprocess
from rendFunctions import sceneEditor, createPaths, readCacheFile, assetCheck, getSubjects, processFiles

#this script executes the texture modulation for the images using Matlab and then renders the scene using PBRT

#currently we are wendering without specularity since it is an albedo modulation -- we can add this in later

#parameters for the scene editor should be 3rd percentiles given by the matlab script 

#dataset at: C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\Practical Rendering\Skin_code\data\ICT_3DRFE_mod

#set options for the script
batchRenderGT = True #will render all the scenes in the batch script
reinverseRenderAll = False
rewriteCachfiles = False
writeSceneFile = True
permuteScene = False
generatePermTextures = False
batchRenderPerms = False    
specular = False
templateID = 2; # 1 is full file, 2 is without overhead lighting 

#set paths
#get absolute path for current file to avoid cofusion with relative paths
currentPath = os.path.abspath(__file__)

TexPath = ".\\scenes\\textures\\normTex\\" #make sure TexPath is set to the correct path in matlab and here
renderPath = ".\\results\\groundTruth\\noOverhead\\"
scenePath = ".\\scenes\\normTexScenes\\noOverhead\\"
dataSetPath = ".\\scenes\\PilotDataSet\\"
cachePath = ".\\scenes\\textures\\normTex\\cache\\"
meshPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\geometry\\processed\\" 
pigPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\pigmentMaps\\"

#add current path to paths
TexPath = os.path.join(os.path.dirname(currentPath),TexPath)
renderPath = os.path.join(os.path.dirname(currentPath),renderPath)
scenePath = os.path.join(os.path.dirname(currentPath),scenePath)
dataSetPath = os.path.join(os.path.dirname(currentPath),dataSetPath)
cachePath = os.path.join(os.path.dirname(currentPath),cachePath)

subjects = 0; #subjects to render -- these are the subjects we are inverse rendering
#subjects = [0,3,7,22]; 
#subjects =5; 

#add the options to an object
options = {
    "batchRenderGT": batchRenderGT,
    "reinverseRenderAll": reinverseRenderAll,
    "reWriteCachfiles": rewriteCachfiles,
    "writeSceneFile": writeSceneFile,
    "permuteScene": permuteScene,
    "subjects": subjects,
    "generatePermTextures": generatePermTextures,
    "batchRenderPerms": batchRenderPerms,
    "specular": specular,
    "handle": 'noOverheadLight'#customise this for output name
}

#add path to object
pathInfo = {
    "TexPath": TexPath,
    "renderPath": renderPath,
    "scenePath": scenePath,
    "dataSetPath": dataSetPath,
    "cachePath": cachePath,
    "meshPath": meshPath,
    "pigPath": pigPath
}


def main(pathInfo,options):
    overwriteALL = False

    subjects = getSubjects(options)
    
    if reinverseRenderAll:
        print("Re-inverse rendering all subjects.")
    else:
        print("Skipping re-inverse rendering.")
    #write an options file to store the inverse render option
    with open("options.txt", "w") as f:
            f.write(f"{str(reinverseRenderAll)}\n")
    
    #handles creating paths        
    createPaths(pathInfo); 

    # Run MATLAB script using subprocess
    matlab_script = "textureEditor.m"

    if reinverseRenderAll == True or options["reWriteCachfiles"] == True:
        print("Running MATLAB script to generate texture maps/write cache files.")
        subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])


    # Find the generated cache files
    cache_files = glob.glob(f"{cachePath}*.txt")

    # Write batch script to render all scenes using PBRT
    batch_script = "render_NormTex.bat"

    if writeSceneFile == True:

        with open(batch_script, "w") as f:

            print("Writing scene files and batch script.")
            
            # Loop through the cache files
            for cache in cache_files:
                
                #read cache file and get params
                params = readCacheFile(cache,subjects)

                #assign params dict to variable names
                subjNum = params["subjNum"]
                permID = params["permID"]
                
                #check permID is empty and we want to render the subject
                if permID == "" and subjNum in subjects:

                    #process the file and write a basic scene file
                     texture = processFiles(pathInfo, cache,batch_script,templateID,subjects, overwriteALL)

                if options["specular"] == True:
                    # copy the scene file but comment out the specular texture and change the output path
                    scene_name =  f"NoSpec{subjNum}.pbrt"
                    scene_file = os.path.join(scenePath, scene_name)

                    #change the outFilePath 
                    pathInfo["outFilePath"] = f"{renderPath}{subjNum}NoSpec.exr"

                    with open(scene_file, "w") as scene_f:
                        #write non specular 
                        scene = sceneEditor(pathInfo, params,texture).replace("\\", "\\\\")
                        #comment out specular texture
                        scene.replace('"texture Kr" "spec" #specular texture', '#"texture Kr" "spec" #specular texture')
                        scene_f.write(scene)

                    # Write the batch script command to render the scene using PBRT
                    scene_command = f".\\bin\\pbrt.exe {scene_file}\n"
                    f.write(scene_command)

        #loop through extreme pigment manipulations -- 4 permutations
        if permuteScene == True:
                #open the batch script to write the permutations
            batch_script = "render_Perms.bat"
            #run the matlab script to generate the permutations
            matlab_script = "textureEditorPermuter.m"
            print("Running MATLAB script to generate permutations.")
            if generatePermTextures == True:
                subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])

            with open(batch_script, "w") as f:

                    #change texture path to permutation subfolder
                    permsPath = "\\scenes\\textures\\normTex\\permutations\\"
                    permsPath = os.path.join(os.path.dirname(currentPath),permsPath)
                    pathInfo["texturePath"] = permsPath

                    #make sure paths exist  
                    createPaths(pathInfo)

                    #get cache text file names 
                    cache_files = glob.glob(f"{TexPath}*.txt")
                    #loop through the permutations in the cache file's and generate scenes 
                    for index, cache in enumerate(cache_files):

                        #get subject and perm ID by reading cache file
                        params = readCacheFile(cache,subjects)
                        subjNum = params["subjNum"]
                        permID = params["permID"]
                        
                        #only process the file if it matches the current subject and permID is not empty
                        if subjNum in subjects and permID != "":
                            print(f"Processing permutation {permID} for subject {subjNum}.")
                            #process the file
                            texture = processFiles(pathInfo, cache, batch_script,templateID,subjects,handle)
            
    print("Batch script created: render_all.bat")

    print("Script execution completed.")
                
    if options["batchRenderGT"]==True:
        print("Rendering scenes...")
        subprocess.run(["render_NormTex.bat"])
        print("Rendering completed.")

    if options["batchRenderPerms"] ==True:
        print("Rendering permutations...")
        subprocess.run(["render_Perms.bat"])
        print("Rendering completed.")
    
    

if __name__ == "__main__":
    main(pathInfo,options)