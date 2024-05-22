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

sample = 30; #default but will always round up to a power of 2


subjects = [0]; #subjects to render -- these are the subjects we are inverse rendering
#subjects = [0,3,5,7,22]; 
#subjects =22; 

perms = '1' #set to 'all' to render all permutations, otherwise select permID's to render
 #perms ['1','2','3','4'] #set to 'all' to render all permutations, otherwise select permID's to render

#set options for the script
batchRenderGT = False #will render all the GT scenes in the batch script
reinverseRenderAll = False # shouldn't need to re-inverse render all the subjects if you just want to edit the maps
rewriteCachfiles = False #if you want to rewrite the cache files
writeSceneFileGT = True

permuteScene = True # avoid all perms options 
generatePermTextures = False; batchRenderPerms = False; noSpecPerms = False

NoSpec = False #render the NoSpec scenes

LightingCase = 1; # 1 is full file, 2 is without overhead lighting 
fixBandEnd = True # fixes beta and clamps epidermal thickness betwee 0.3 and 0.10 assuming inverse rendering is done beforehand
SkipMatlab = True #skip the matlab script and just render the scenes for debugging

pathHandle = 'reRunCheck\\' #customise this for output name -- don't use end
fileHandle = 'ISONorm' #customise this for file details in the name, ensure no overwriting at the least 

kr1 = True #render with homogenous specularity of 1


fileName = 'normTex' + fileHandle # add extensions later
customName = '30SampleSpecKR1' #custom name for the output file  
outFileName = fileName + customName # to rerun with diff output name


expName = fileHandle


#save the fileName to a .txt to make it global
with open("fileName.txt", "w") as f:
    f.write = fileName

#set paths
#get absolute path for current file to avoid cofusion with relative paths
currentPath = os.path.abspath(__file__)

TexPath = f".\\results\\experiments\\{pathHandle}\\normTex\\"
renderPath = f".\\results\\experiments\\{pathHandle}\\groundTruth\\"
scenePath = f".\\results\\experiments\\{pathHandle}\\scenes"
dataSetPath = ".\\scenes\\PilotDataSet\\"
cachePath = f".\\results\\experiments\\{pathHandle}\\cache\\"
meshPath = f"C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\geometry\\processed\\" 
pigPath = f"C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\experiments\\{pathHandle}\\pigmentMaps\\"

#make a dir to store file summaries
if not os.path.exists(f".fileSummaries\\{pathHandle}\\"):
    os.makedirs(f".fileSummaries\\{pathHandle}\\")
#write a small summary of the paths for the experiment as a csv file
with open(f".fileSummaries\\{pathHandle}\\{expName}.csv", "w") as f:
    f.write(f"TexPath,{TexPath}\n")
    f.write(f"renderPath,{renderPath}\n")
    f.write(f"scenePath,{scenePath}\n")
    f.write(f"dataSetPath,{dataSetPath}\n")
    f.write(f"cachePath,{cachePath}\n")
    f.write(f"meshPath,{meshPath}\n")
    f.write(f"pigPath,{pigPath}\n")

rootPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\" #root path for the project
#add the root path to the paths to avoid issues with relative paths from scene files
TexPath = os.path.join(rootPath,TexPath)
renderPath = os.path.join(rootPath,renderPath)
scenePath = os.path.join(rootPath,scenePath)
dataSetPath = os.path.join(rootPath,dataSetPath)
cachePath = os.path.join(rootPath,cachePath)

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
    "SkipMatlab": SkipMatlab,
    "SkipALL": False,
    "noSpecPerms": noSpecPerms,
    "sample": sample,
    "kr1": kr1,

   
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
    "fileName": fileName,
    "outFileName": outFileName

}


def GroundTruthRender(pathInfo,options):
    overwriteALL = False
    skipAll = False

    subjects = getSubjects(options)
    
    sample = options["sample"]

    if reinverseRenderAll:
        print("Re-inverse rendering all subjects.")
    else:
        print("Skipping re-inverse rendering.")
    #write an options file to store the inverse render option
    with open(".\\utilities\\text\\options.txt", "w") as f:
        f.write(f"{str(int(reinverseRenderAll))}{str(int(fixBandEnd))}\n")

    #handles creating paths        
    createPaths(pathInfo); 

    # Run MATLAB script using subprocess
    matlab_script = ".\\utilities\\matlab\\textureEditor.m"

    if (reinverseRenderAll == True or options["reWriteCachfiles"] == True or options["fixBandEnd"] == True) & options["SkipMatlab"] == False:
        print("Running MATLAB script to generate texture maps/write cache files.")
        subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])


    # Find the generated cache files
    cache_files = glob.glob(f"{cachePath}*.txt")

    # Write batch script to render all scenes using PBRT
    batch_script = ".\\utilities\\batch\\render_NormTex.bat"
    batch_script2 = ".\\utilities\\batch\\render_NoSpec.bat"

    fileName = pathInfo["fileName"]
    with open(batch_script, "w") as f:
        with open(batch_script2, "w") as f2:
            # Loop through the cache files
            for cache in cache_files:
                #read cache file and get params
                params = readCacheFile(cache,subjects)

            
                #assign params dict to variable names
                subjNumStr = params["subjNum"]
                subjNumInt = int(subjNumStr[2:])
                permID = params["permID"]

                
                if writeSceneFileGT == True:
                    scene_name = f"{subjNumStr}.pbrt"
                    #check permID is empty and we want to render the subject
                    if permID == "" and subjNumStr in subjects:
                        print("Writing scene files and batch script.")
                        #process the file and write a basic scene file
                        overwriteALL, skipAll, scene_command = processFiles(pathInfo, cache, batch_script, LightingCase, subjects, sample, overwriteALL, skipAll, fileHandle)
                        scene_file = os.path.join(scenePath, scene_name)
                        # write to batch file
                        f.write(scene_command)
            
                if options["NoSpec"] == True and subjNumStr in subjects and permID == "":
            
                    # copy the scene file but comment out the NoSpec texture and change the output path
                    scene_name =  f"NoSpec{subjNumStr}.pbrt"
                    scene_file = os.path.join(scenePath, scene_name)
                    #assign relevant render paths for file writing 
                    outFilePath = f"{pathInfo['renderPath']}\\NoSpec\\{subjNumStr}{outFileName}.exr"

                    #check no spec exists and create if not
                    if not os.path.exists(f"{pathInfo['renderPath']}\\NoSpec\\"):
                        os.makedirs(f"{pathInfo['renderPath']}\\NoSpec\\")

                    albedoTexturePath = f"{pathInfo['TexPath']}{subjNumStr}{fileName}.exr"
                    specTexturePath = f"{pathInfo['dataSetPath']}{subjNumStr}\\shader\\spec_textureISONorm.exr"
                    meshPath = f"{pathInfo['meshPath']}{subjNumStr}mesh.pbrt"

                    #add variable to render path info dict to pass to editor 
                    renderPathInfo = {
                        "renderPath": outFilePath,
                        "albedoTexturePath": albedoTexturePath,
                        "specTexturePath": specTexturePath,
                        "meshPath": meshPath
                    }

            

                    with open(scene_file, "w") as scene_f:
                        if permID == "" and subjNumStr in subjects:
                        #write non NoSpec 
                            scene = sceneEditor(params,renderPathInfo,LightingCase,sample).replace("\\", "\\\\")
                            #comment out NoSpec texture
                            scene = scene.replace('"texture Kr" "spec" #specular texture', '"color Kr" [0 0 0] # no spec')
                            scene_f.write(scene)
                    
                    print("Writing non spec scene files and batch script.")
                    # Write the batch script command to render the scene using PBRT
                    scene_command = f".\\bin\\pbrt.exe \"{scene_file}\"\n"
                    f2.write(scene_command)
    
def renderPerms(pathInfo,options): 
    subjects = getSubjects(options)
    createPaths(pathInfo)
    sample = options["sample"]

    overwriteALL = False
    skipAll = False
    # Find the generated cache files
    cachePath = pathInfo["cachePath"]
    cachePath = cachePath + '\\permutedTextures\\'
    cache_files = glob.glob(f"{cachePath}*.txt")
    batch_script1 = ".\\utilities\\batch\\render_Perms.bat"
    batch_script2 = ".\\utilities\\batch\\NoSpecPerms.bat"
    #run the matlab script to generate the permutations
    matlab_script = ".\\utilities\\matlab\\textureEditorPermuter.m"
    if generatePermTextures == True and options["SkipMatlab"] == False:
        subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])

    with open(batch_script1, "w") as f1: 
        with open(batch_script2, "w") as f2: 
            for index, cache in enumerate(cache_files):

                #get subject and perm ID by reading cache file
                params = readCacheFile(cache,subjects)
                subjNumStr = params["subjNum"]
                subjNumInt = int(subjNumStr[2:])
                permID = params["permID"]                       
                perms = options["perms"]

                #loop through extreme pigment manipulations -- 4 permutations
                if permuteScene == True:
                    # copy path info to new dict
                    permPathInfo = pathInfo.copy()
                    permPathInfo["TexPath"] = permPathInfo["TexPath"] + "permutedTextures\\"
                    permPathInfo["cachePath"] = permPathInfo["cachePath"] + "permutedTextures\\"
                    permPathInfo["scenePath"] = scenePath+ "\\perms\\"
                    permPathInfo["renderPath"] = renderPath + "\\perms\\"

                    
                    
                    #get cache text file names 
                    cache_files = glob.glob(f"{permPathInfo["cachePath"]}*.txt")
                    #loop through the permutations in the cache file's and generate scenes 
                    
                    #only process the file if it matches the current subject and permID is not empty
                    if (perms == 'all' and subjNumStr in subjects)|(subjNumStr in subjects and permID in perms):
 
                        print(f"Processing permutation {permID} for subject {subjNumStr}.")
    
                        overwriteALL, skipAll, scene_command = processFiles(permPathInfo, cache, batch_script1,LightingCase,subjects, sample, overwriteALL, skipAll, fileHandle)
                        #write to batch file
                        f1.write(scene_command)
        
                    if (perms == 'all' and subjNumStr in subjects and options["noSpecPerms"] ==True)|(options["noSpecPerms"] == True and subjNumStr in subjects and permID == perms):
                        batch_script2 = '.\\utilities\\batch\\NoSpecPerms.bat'
                        # copy the scene file but comment out the NoSpec texture and change the output path
                        scene_name =  f"NoSpec{subjNumStr}_PermID{permID}.pbrt"
                        scene_file = os.path.join(scenePath, scene_name)
                        #assign relevant render paths for file writing 
                        outFilePath = f"{pathInfo['renderPath']}\\perms\\NoSpec\\{subjNumStr}_permID{permID}{outFileName}.exr"

                        #check no spec exists and create if not
                        if not os.path.exists(f"{pathInfo['renderPath']}\\perms\\NoSpec\\"):
                            os.makedirs(f"{pathInfo['renderPath']}\\perms\\NoSpec\\")

                        albedoTexturePath = f"{pathInfo['TexPath']}\\permutedTextures\\{subjNumStr}PermID{permID}_{fileName}.exr"
                        specTexturePath = f"{pathInfo['dataSetPath']}{subjNumStr}\\shader\\spec_textureISONorm.exr"
                        meshPath = f"{pathInfo['meshPath']}{subjNumStr}mesh.pbrt"
                        

                        #add variable to render path info dict to pass to editor 
                        renderPathInfo = {
                            "renderPath": outFilePath,
                            "albedoTexturePath": albedoTexturePath,
                            "specTexturePath": specTexturePath,
                            "meshPath": meshPath
                        }
                        

                        with open(scene_file, "w") as scene_f:
                            #write non NoSpec 
                            scene = sceneEditor(params,renderPathInfo,LightingCase, options["sample"]).replace("\\", "\\\\")
                            #comment out NoSpec texture
                            scene = scene.replace('"texture Kr" "spec" #specular texture', '"color Kr" [0 0 0] # no spec')
                            scene_f.write(scene)
                    
                        print("Writing non spec scene files and batch script.")
                        # Write the batch script command to render the scene using PBRT
                        scene_command = f".\\bin\\pbrt.exe \"{scene_file}\"\n"
                        f2.write(scene_command)

def renderWithHomogenousSpec(pathInfo,options): 
    batch_script = ".\\utilities\\batch\\render_HomogenousSpec.bat"
    sample = options["sample"]
    # Find the generated cache files
    cachePath = pathInfo["cachePath"]
    cachePath = cachePath + '\\permutedTextures\\'
    cache_files = glob.glob(f"{cachePath}*.txt")
    batch_script1 = ".\\utilities\\batch\\render_Perms.bat"
    batch_script2 = ".\\utilities\\batch\\NoSpecPerms.bat"
    #run the matlab script to generate the permutations
    matlab_script = ".\\utilities\\matlab\\textureEditorPermuter.m"

   
    createPaths(pathInfo)
    
 

    
    subjects = getSubjects(options)
    #get cache text file names 
    cache_files = glob.glob(f"{pathInfo["cachePath"]}*.txt")
    with open(batch_script, "w") as f1: 
        for index, cache in enumerate(cache_files):
            params = readCacheFile(cache,subjects)
            
            #get subject and perm ID by reading cache file
            subjNumStr = params["subjNum"]
            subjNumInt = int(subjNumStr[2:])
            permID = params["permID"]                       
            perms = options["perms"]
            overwriteALL = False
            skipAll = False
                    
            albedoTexturePath = f"{pathInfo['TexPath']}{subjNumStr}{fileName}.exr"
            specTexturePath = f"{pathInfo['dataSetPath']}{subjNumStr}\\shader\\spec_textureISONorm.exr"
            meshPath = f"{pathInfo['meshPath']}{subjNumStr}mesh.pbrt"
            outFilePath = f"{pathInfo['renderPath']}\\NoSpec\\{subjNumStr}_KR1.exr"

            #add variable to render path info dict to pass to editor 
            renderPathInfo = {
            "renderPath": outFilePath,
            "albedoTexturePath": albedoTexturePath,
            "specTexturePath": specTexturePath,
            "meshPath": meshPath
            }


            #only process the file if it matches the current subject and permID is not empty
            if (perms == 'all' and subjNumStr in subjects)|(subjNumStr in subjects and permID in perms):
                scene_name =  f"NoSpec{subjNumStr}_Kr1.pbrt"
                scene_file = os.path.join(scenePath, scene_name)
                with open(scene_file, "w") as scene_f:
                            #write non NoSpec 
                            scene = sceneEditor(params,renderPathInfo,LightingCase, options["sample"]).replace("\\", "\\\\")
                            #comment out NoSpec texture
                            scene = scene.replace('"texture Kr" "spec" #specular texture', '"color Kr" [1 1 1] # no spec')
                            scene_f.write(scene)
                #write to batch file
                f1.write(f" .\\bin\\pbrt.exe \"{scene_file}\"\n")

def renderExecution(options): # this executes the batch scripts to render the scenes
    if options["batchRenderGT"]==True:
        print("Rendering scenes...")
        subprocess.run([".\\utilities\\batch\\render_NormTex.bat"])
        print("Rendering completed.")

    if options["batchRenderPerms"] ==True:
        print("Rendering permutations...")
        subprocess.run([".\\utilities\\batch\\render_Perms.bat"])
        print("Rendering completed.")

    if options["NoSpec"] == True:
        print("NoSpec scenes will be rendered.")
        subprocess.run([".\\utilities\\batch\\render_NoSpec.bat"])
        print("Rendering completed.")

    if options["noSpecPerms"] == True:
        print("NoSpec perm scenes will be rendered.")
        subprocess.run([".\\utilities\\batch\\NoSpecPerms.bat"])
        print("Rendering completed.")
    if options["kr1"] == True:
        print("Rendering scenes with homogenous specularity of 1.")
        subprocess.run([".\\utilities\\batch\\render_HomogenousSpec.bat"])

    print("Script execution completed.")

def main(pathInfo,options):
   
    GroundTruthRender(pathInfo,options)

    renderPerms(pathInfo,options)                    
    
    if options["kr1"] == True:
        renderWithHomogenousSpec(pathInfo,options)

    renderExecution(options)


    print("End of main script.")
    

#if __name__ == "__main__":
main(pathInfo,options)
