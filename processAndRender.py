import glob
import os
import glob
import shlex
import subprocess
from rendFunctions import sceneEditor, createPaths, readCacheFile, assetCheck, getSubjects, processFiles
import csv

#this script executes the texture modulation for the images using Matlab and then renders the scene using PBRT

#currently we are wendering without NoSpecity since it is an albedo modulation -- we can add this in later

#parameters for the scene editor should be 3rd percentiles given by the matlab script 

#dataset at: C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\Practical Rendering\Skin_code\data\ICT_3DRFE_mod

#set options for the script
batchRenderGT = False #will render all the GT scenes in the batch script
reinverseRenderAll = False # shouldn't need to re-inverse render all the subjects if you just want to edit the maps
rewriteCachfiles = False
writeSceneFileGT = False
permuteScene = True
generatePermTextures = True
batchRenderPerms = True    
NoSpec = False#render the NoSpec scenes
LightingCase = 2; # 1 is full file, 2 is without overhead lighting 
fixBandEnd = True # fixes beta and clamps epidermal thickness betwee 0.10 and 0.20mm assuming inverse rendering is done beforehand
SkipMatlab = True #skip the matlab script and just render the scenes for debugging

pathHandle = 'fixBandEnd\\' #customise this for output name
fileHandle = 'SpecAndSmallerEpthValandModalBetaOverHead' #customise this for file details in the name, ensure no overwriting at the least 

expName = fileHandle

#set paths
#get absolute path for current file to avoid cofusion with relative paths
currentPath = os.path.abspath(__file__)

TexPath = f".\\scenes\\textures\\normTex\\"
renderPath = f".\\results\\groundTruth\\"
scenePath = f".\\scenes\\normTexScenes\\"
dataSetPath = ".\\scenes\\PilotDataSet\\"
cachePath = f".\\scenes\\textures\\normTex\\cache\\"
meshPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\geometry\\processed\\" 
pigPath = f"C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\pigmentMaps\\"

#make a dir to store file summaries
if not os.path.exists(".\\fileSummaries\\"):
    os.makedirs(".\\fileSummaries\\")
#write a small summary of the paths for the experiment as a csv file
with open(f"\\fileSummaries\\{expName}.csv", "w") as f:
    f.write(f"TexPath,{TexPath}\n")
    f.write(f"renderPath,{renderPath}\n")
    f.write(f"scenePath,{scenePath}\n")
    f.write(f"dataSetPath,{dataSetPath}\n")
    f.write(f"cachePath,{cachePath}\n")
    f.write(f"meshPath,{meshPath}\n")
    f.write(f"pigPath,{pigPath}\n")


# append handle to relevant paths for new directory
TexPath = os.path.join(TexPath,pathHandle )
renderPath = os.path.join(renderPath,pathHandle )    
scenePath = os.path.join(scenePath,pathHandle )
cachePath = os.path.join(cachePath,pathHandle )
pigPath = os.path.join(pigPath,pathHandle )

#add current path to paths
TexPath = os.path.join(os.path.dirname(currentPath),TexPath)
renderPath = os.path.join(os.path.dirname(currentPath),renderPath)
scenePath = os.path.join(os.path.dirname(currentPath),scenePath)
dataSetPath = os.path.join(os.path.dirname(currentPath),dataSetPath)
cachePath = os.path.join(os.path.dirname(currentPath),cachePath)

#subjects = [0]; #subjects to render -- these are the subjects we are inverse rendering
subjects = [0,3,5,7,22]; 
#subjects =5; 

perms = 'all' #set to 'all' to render all permutations, otherwise select permID's to render
#perms ['1','2','3','4'] #set to 'all' to render all permutations, otherwise select permID's to render

#add the options to an object
options = {
    "batchRenderGT": batchRenderGT,
    "reinverseRenderAll": reinverseRenderAll,
    "reWriteCachfiles": rewriteCachfiles,
    "writeSceneFileGT": writeSceneFileGT,
    "permuteScene": permuteScene,
    "subjects": subjects,
    "generatePermTextures": generatePermTextures,
    "batchRenderPerms": batchRenderPerms,
    "NoSpec": NoSpec,
    "pathHandle": pathHandle,#customise this for output name
    "fileHandle": fileHandle, #customise this for file details
    "fixBandEnd": fixBandEnd,
    "perms": perms,#set to 'all' to render all permutations, otherwise select permID's to render
    "SkipMatlab": SkipMatlab
}

#add path to object
pathInfo = {
    "TexPath": TexPath,
    "renderPath": renderPath,
    "scenePath": scenePath,
    "dataSetPath": dataSetPath,
    "cachePath": cachePath,
    "meshPath": meshPath,
    "pigPath": pigPath,
    "fileHandle": fileHandle,
    "pathHandle": pathHandle,

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
        f.write(f"{str(int(reinverseRenderAll))}{str(int(fixBandEnd))}\n")
    
    #handles creating paths        
    createPaths(pathInfo); 

    # Run MATLAB script using subprocess
    matlab_script = "textureEditor.m"

    if (reinverseRenderAll == True or options["reWriteCachfiles"] == True or options["fixBandEnd"] == True) & options["SkipMatlab"] == False:
        print("Running MATLAB script to generate texture maps/write cache files.")
        subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])


    # Find the generated cache files
    cache_files = glob.glob(f"{cachePath}*.txt")

    # Write batch script to render all scenes using PBRT
    batch_script = "render_NormTex.bat"
    batch_script2 = "render_NoSpec.bat"

    if writeSceneFileGT == True:
        with open(batch_script2, "w") as f2, open(batch_script,"w") as f:
            # Loop through the cache files
            for cache in cache_files:
                
                #read cache file and get params
                params = readCacheFile(cache,subjects)

                #assign params dict to variable names
                subjNum = params["subjNum"]
                permID = params["permID"]
                
                scene_name = f"{subjNum}.pbrt"
                #check permID is empty and we want to render the subject
                if permID == "" and subjNum in subjects:
                    
                        print("Writing scene files and batch script.")
                        #process the file and write a basic scene file
                        overwriteALL, scene_command = processFiles(pathInfo, cache, batch_script, LightingCase, subjects, overwriteALL, fileHandle)
                        scene_file = os.path.join(scenePath, scene_name)
                        # write to batch file
                        f.write(scene_command)

                        if options["NoSpec"] == True and subjNum in subjects and permID == "":
                            # copy the scene file but comment out the NoSpec texture and change the output path
                            scene_name =  f"NoSpec{subjNum}.pbrt"
                            scene_file = os.path.join(scenePath, scene_name)
                            #assign relevant render paths for file writing 
                            outFilePath = f"{pathInfo['renderPath']}\\NoSpec{subjNum}{fileHandle}.exr"
                            albedoTexturePath = f"{pathInfo['TexPath']}normTexISONorm{subjNum}.exr"
                            specTexturePath = f"{pathInfo['dataSetPath']}{subjNum}\\shader\\spec_textureISONorm.exr"
                            meshPath = f"{pathInfo['meshPath']}{subjNum}mesh.pbrt"

                            #add variable to render path info dict to pass to editor 
                            renderPathInfo = {
                                "renderPath": outFilePath,
                                "albedoTexturePath": albedoTexturePath,
                                "specTexturePath": specTexturePath,
                                "meshPath": meshPath
                            }

                            with open(scene_file, "w") as scene_f:
                                #write non NoSpec 
                                scene = sceneEditor(params,renderPathInfo,LightingCase).replace("\\", "\\\\")
                                #comment out NoSpec texture
                                scene.replace('"texture Kr" "spec" #NoSpec texture', '#"texture Kr" "spec" #NoSpec texture')
                                scene_f.write(scene)
                        
                            print("Writing non spec scene files and batch script.")
                            # Write the batch script command to render the scene using PBRT
                            scene_command = f".\\bin\\pbrt.exe \"{scene_file}\"\n"
                            f2.write(scene_command)

                    

    #loop through extreme pigment manipulations -- 4 permutations
    if permuteScene == True:
        #open the batch script to write the permutations
        batch_script = "render_Perms.bat"
        #run the matlab script to generate the permutations
        matlab_script = "textureEditorPermuter.m"
        print("Running MATLAB script to generate permutations.")
        if generatePermTextures == True and options["SkipMatlab"] == False:
            subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])

        with open(batch_script, "w") as f:

            # load the perms path csv file
            permsPath = "permPaths.csv"
            paths = []
            with open(permsPath, 'r') as csvfile:
                reader = csv.reader(csvfile)
                for row in reader:
                    paths.append(row)

            #seperate the paths 
            permMaps = paths[1][0]
            permCache = paths[1][1]
            permTex = paths[1][2]

            # copy path info to new dict
            permPathInfo = pathInfo.copy()
            permPathInfo["TexPath"] = permTex
            permPathInfo["cachePath"] = permCache
            permPathInfo["scenePath"] = scenePath+ "perms\\"

            #check the paths exist
            createPaths(permPathInfo)


            #get cache text file names 
            cache_files = glob.glob(f"{permCache}*.txt")
            #loop through the permutations in the cache file's and generate scenes 
            for index, cache in enumerate(cache_files):

                #get subject and perm ID by reading cache file
                params = readCacheFile(cache,subjects)
                subjNum = params["subjNum"]
                permID = params["permID"]                       
                perms = options["perms"]

                #only process the file if it matches the current subject and permID is not empty
                if (perms == 'all' and subjNum in subjects)|(subjNum in subjects and permID in perms):
                        print(f"Processing permutation {permID} for subject {subjNum}.")
                        #process the file
                        overwriteALL, scene_command = processFiles(permPathInfo, cache, batch_script,LightingCase,subjects, overwriteALL,fileHandle)
                        #write to batch file
                        f.write(scene_command)

    print("Batch script created: render_all.bat")

    print("Script execution completed.")
    if options["NoSpec"] == True:
        print("NoSpec scenes will be rendered.")
        subprocess.run(["render_NoSpec.bat"])
        print("Rendering completed.")

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