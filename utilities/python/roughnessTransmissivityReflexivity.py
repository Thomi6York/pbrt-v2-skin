"""
File: roughnessTransmissivityReflexivity.py
Author: TW
Date: [Current Date]
Description: This is used to iterate over the values of roughness transmissivity and reflectivity for the starter head. Required the basic inverted textures and cache files generated by
processAndRender.py

"""

# Rest of your code goes here...

import glob
import os
import glob
import shlex
import subprocess
from rendFunctions import sceneEditor, createPaths, readCacheFile, assetCheck, getSubjects, processFiles
import csv
import os
import subprocess

# first lets iterate the permutations of roughness, transmissivity and reflectivity, all between 0 and 1 in steps 0f 0.2
transmissivity = [i/5 for i in range(6)]
reflectivity = [i/5 for i in range(6)]
roughness = [i/5 for i in range(6)]

sample = 30; # number of samples to render
LightingCase = 1; # case to render 

# Rest of your code goes here...

#cache file to load
cacheFile = ".\\results\\experiments\\reRunCheck\\cache\\cache_S000normTexISONorm.txt"
tex = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\experiments\\reRunCheck\\normTex\\S000normTexISONorm.exr"
meshPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\geometry\\processed\\S000mesh.pbrt"
outFilePath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\experiments\\transmissivityRoughnessReflectivity\\"

#check output file path exists
if not os.path.exists(outFilePath):
    os.makedirs(outFilePath)

outFileHandle = "testHandle"

params = readCacheFile(cacheFile,'S000')

batchScript = ".\\utilities\\batch\\specularAndTransmissivity.bat"
# loop over the permutations
with open(batchScript,"w") as batch:
    for r in roughness:
        for t in transmissivity:
            for rf in reflectivity:
                
            # edit the scene file with the new values
                renderPathInfo = { "albedoTexturePath" :tex,
                "specTexturePath"  : "..\\", #not using this
                "meshPath" : meshPath,
                "renderPath" : outFilePath + "roughness" + str(int(r*10)).zfill(2) + "transmissivity" + str(int(t*10)).zfill(2) + "reflectivity" + str(int(rf*10)).zfill(2) + outFileHandle + ".exr"
                }
            
                

                scene = sceneEditor(params,renderPathInfo,LightingCase,sample).replace("\\", "\\\\")

                #replace the parts of the scene with out values

                scene = scene.replace("\"texture Kr\" \"spec\" #specular texture",f"\"color Kr\" [{rf} {rf} {rf}]")
                scene = scene.replace("\"float roughness\" 0.35",f"\"float roughness\" {r}")
                scene = scene.replace("\"color Kt\" [0 0 0]",f"\"color Kt\" [{t} {t} {t}]")

                #delete lines 36 and 37
                scene = scene.split("\n")
                scene.pop(35)
                scene.pop(35)
                scene = "\n".join(scene)

                #write the scene to a file
                sceneFileName = outFilePath + "\\scenes\\"+ "roughness" + str(int(r*10)).zfill(2) + "transmissivity" + str(int(t*10)).zfill(2) + "reflectivity" + str(int(rf*10)).zfill(2) + outFileHandle + ".pbrt"

                if not os.path.exists(outFilePath + "\\scenes\\"):
                    os.makedirs(outFilePath + "\\scenes\\")

                with open(sceneFileName, "w") as text_file:
                    text_file.write(scene)
                
                #add command to batch file
                batch.write(f".\\bin\\pbrt.exe \"{sceneFileName}\"\n")

#run the batch file
subprocess.run(batchScript)
print("Batch file run")

            