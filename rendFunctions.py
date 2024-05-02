import glob
import os
import glob
import shlex
import subprocess
import json
import sys


# pbrt template goes here:
def sceneEditor(params,pathInfo,LightingCase):
    
    #path info is a dictionary containing the path to the texture and the path to the scene file

    #unpack paths from render path info 
    outFilePath = pathInfo["renderPath"]
    albedoTexturePath = pathInfo["albedoTexturePath"]
    specTexturePath = pathInfo["specTexturePath"]
    meshPath = pathInfo["meshPath"]


    #unpack params
    subjNum = params["subjNum"]
    melConc = params["melConc"]
    hemConc = params["hemConc"]
    betaConc = params["betaConc"]
    epThickness = params["epThickness"]
    permID = params["permID"]

    #set the template ID

    if LightingCase == 1:
    #write scene
        template = f"""
            Film "image" "integer xresolution" [1280] "integer yresolution" [720] "string filename" "{outFilePath}"
            LookAt 0.491171 -4.4848 0.897406 0 0 0 0 0 1
            Camera "perspective" "float fov" [30] 
            Sampler "lowdiscrepancy" "integer pixelsamples" 1 #changed to 1 for brute render speed`

            SurfaceIntegrator "multipolesubsurface" #this is likely what controls specularity, and has an effect which overwrites texture input 
            "integer maxdepth" 5 #changed from 5 to 2 -- no effect
            "float maxerror" 0.1
            "float minsampledistance" 0.0015 #beyond 0.0001 causes crash -- making big just makes it grainy 

            WorldBegin


            #overhead light source
            AttributeBegin
                AreaLightSource "area" "color L" [ 3200 3200 3200 ] "integer nsamples" [4]
                Translate -0.0859535 -3 6.00725 #try and move camera up?? in Z axis and back in y 
                Shape "sphere" "float radius" 0.2 # decrease light source radius from 0.2 
            AttributeEnd

            AttributeBegin
                #lights -- this is our isi naturalistic light source -- check for artifacts 
                Scale -1 1 1
                Rotate 90 -1 0 0
                Rotate 90 1 0 0
                Translate 30 30 30
                LightSource "infinite"
                    "string mapname" ["C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\textures\\small_rural_road_equiarea.exr" ]
                    "integer	nsamples" [5] #crank this up to remove grainyness
            AttributeEnd


            Texture "lambertian-norm" "color" "imagemap" "string filename" ""{albedoTexturePath}""
                "string wrap" "clamp" "float gamma" 1 "float scale" 1
            Texture "spec" "color" "imagemap" "string filename"  "{specTexturePath}"
                "string wrap" "clamp" "float gamma" 1 "float scale" 1

            AttributeBegin
                Translate 0 1 -.35 # move up a bit
                Rotate 90  1 0 0
                Scale 3 3 3
                # lets try and run this wihtout loading the textures 
                Material "layeredskin" "float roughness" 0.35 #0.35 is the paper value 
                                    "float nmperunit" 40e6 # nanometers per unit length in world space
                                    #"color Kr" [0 0 0] # no spec
                                    
                                    "color Kt" [0 0 0] # edit did little changing from 1 to zero  -- this is translucency; can't be seen with a black background
                                    # each layer's depth and index of refraction; units are in nanometers

                                    "skinlayer layers" [ {epThickness}e6 1.4 20e6 1.4] # is this the thickness -- or above
                                
                                    "float f_mel" {melConc} #from skin_code tables 
                                    "float f_eu" {betaConc} #clamp this at 0.5 as this is where we make the pigment maps from 
                        
                                    "float f_blood" {hemConc} # abs of whole blood -- where do I get this from 
                                    "float f_ohg" 0.75 #seems to be gamma ratio 
                            
                                    "texture albedo" "lambertian-norm"
                                    "texture Kr" "spec" #specular texture
                                    
                                    
                Include "{meshPath}"
            AttributeEnd
            
            WorldEnd
        """

    elif LightingCase == 2:
        #write scene with no specular light source 
        template = f"""
            Film "image" "integer xresolution" [1280] "integer yresolution" [720] "string filename" "{outFilePath}"
            LookAt 0.491171 -4.4848 0.897406 0 0 0 0 0 1
            Camera "perspective" "float fov" [30] 
            Sampler "lowdiscrepancy" "integer pixelsamples" 1 #changed to 1 for brute render speed`

            SurfaceIntegrator "multipolesubsurface" #this is likely what controls specularity, and has an effect which overwrites texture input 
            "integer maxdepth" 5 #changed from 5 to 2 -- no effect
            "float maxerror" 0.1
            "float minsampledistance" 0.0015 #beyond 0.0001 causes crash -- making big just makes it grainy 

            WorldBegin

            AttributeBegin
            #lights -- this is our isi naturalistic light source -- check for artifacts 
            Scale -1 1 1
            Rotate 90 -1 0 0
            Rotate 90 1 0 0
            Translate 30 30 30
            LightSource "infinite"
                "string mapname" [ "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\scenes\\textures\\small_rural_road_equiarea.exr" ]
                "integer	nsamples" [5] #crank this up to remove grainyness
            AttributeEnd


            Texture "lambertian-norm" "color" "imagemap" "string filename" "{albedoTexturePath}"
            "string wrap" "clamp" "float gamma" 1 "float scale" 1
            Texture "spec" "color" "imagemap" "string filename"  "{specTexturePath}"
            "string wrap" "clamp" "float gamma" 2.2 "float scale" 1

            AttributeBegin
            Translate 0 1 -.35 # move up a bit
            Rotate 90  1 0 0
            Scale 3 3 3
            # lets try and run this wihtout loading the textures 
            Material "layeredskin" "float roughness" 0.35 #0.35 is the paper value 
                        "float nmperunit" 40e6 # nanometers per unit length in world space
                        #"color Kr" [0 0 0] # no spec
                        
                        "color Kt" [0 0 0] # edit did little changing from 1 to zero  -- this is translucency; can't be seen with a black background
                        # each layer's depth and index of refraction; units are in nanometers

                        "skinlayer layers" [ {epThickness}e6 1.4 20e6 1.4] # is this the thickness -- or above
                    
                        "float f_mel" {melConc} #from skin_code tables 
                        "float f_eu" {betaConc} #clamp this at 0.5 as this is where we make the pigment maps from 
                
                        "float f_blood" {hemConc} # abs of whole blood -- where do I get this from 
                        "float f_ohg" 0.75 #seems to be gamma ratio 
                    
                        "texture albedo" "lambertian-norm"
                        "texture Kr" "spec" #specular texture
                        
                        
                Include "{meshPath}"
            AttributeEnd
            
            WorldEnd
        """
        return template

def  createPaths(pathInfo):
    #save the paths to a text file matlab can read

    #loop through the pathInfo object and create paths if they don't exist
    for key, value in pathInfo.items():
        
        if key == "pathHandle" or key == "fileHandle":
            continue
        elif not os.path.exists(value):
            os.makedirs(value)
            print(f"{key} path created.")
        else:
            print(f"{key} path already exists.")
       
       
        

        # Convert pathInfo dictionary to a JSON object
        json_object = json.dumps(pathInfo)

        # Save the JSON object to a text file
        with open('pathInfo.txt', 'w') as f:
            f.write(json_object)

def readCacheFile(cache_file,subjects):
    with open(cache_file, "r") as cache_f:

        lines = cache_f.readlines()
        subjNum = lines[0].split(":")[1].strip() # subj ID 
        if subjNum not in subjects:
            print(f"Subject {subjNum} not in subjects list. Skipping.")
            params = { #return dummy object to prevent breaking the code
                "subjNum": subjNum,
                "melConc": 0,
                "hemConc": 0,
                "betaConc": 0,
                "epThickness": 0,
                "permID": ""
            }
            return params
        else:
            subjNum = lines[0].split(":")[1].strip() # subj ID 
            melConc = float(lines[1].split(":")[1].strip()) #mel
            hemConc = float(lines[2].split(":")[1].strip()) #hem
            betaConc = float(lines[6].split(":")[1].strip()) #beta
            epThickness = float(lines[8].split(":")[1].strip()) #this is epth
            epThickness = epThickness*0.001 #scale 
            permID = lines[9].split(":")[1].strip() #perm ID 

            #create a single object for all values
            params = {
                "subjNum": subjNum,
                "melConc": melConc,
                "hemConc": hemConc,
                "betaConc": betaConc,
                "epThickness": epThickness,
                "permID": permID
            }
            return params

def assetCheck(renderPathInfo):
    # check all the assets exist for the scene file
    for key, value in renderPathInfo.items():
        if key == "renderPath":
            continue
        elif not os.path.exists(value):
            print(f"{key} does not exist. Please check the path.")
            sys.exit()  # Terminate the script
        else:
            print(f"{key} exists.")

def  getSubjects(options):
    #these are the subjects we are inverse rendering. If parameter maps are already rendered they will also be rendered
    with open("subjects.csv", "w") as f:
            if type(options["subjects"]) == int:
                f.write(f"{options['subjects']}\n")
            else:
                    for i in options["subjects"]:
                        f.write(f"{i}\n")
    
    
    #convert the subjects integers to a string in correct format
    if type(options["subjects"]) == int:
        subjects = [("S" + str(options["subjects"]).zfill(3))]
    else:
        subjects = [("S" + str(i).zfill(3)) for i in options["subjects"]]

    return subjects

def processFiles(pathInfo, cacheFile,batch_script,LightingCase,subjects,overwriteALL=False,handle = None):
    #check if we want to overwrite all files
    #set default handle to empty string
    if handle == None:
        handle = ""
    #with open(batch_script, "w") as f:
                            
    #remember paths are set relative to the pbrt file not the python script
    #lets set the saving path with absolute paths to avoid confusion
    textureDir = pathInfo["TexPath"]
    # read cache file and get params
    params = readCacheFile(cacheFile,subjects)

    #assign params dict to variable names
    subjNum = params["subjNum"]
    melConc = params["melConc"]
    hemConc = params["hemConc"]
    permID = params["permID"]
    scenePath = pathInfo["scenePath"]
    #unpack paths from render path info
    renderDir = pathInfo["renderPath"]
    if permID == "" or permID == '':
        renderPath = f"{renderDir}{subjNum}"
        scene_name = f"{subjNum}_{handle}.pbrt"
        texture = f"normTexISONorm{subjNum}.exr" # get the texture
    else:
        renderPath = f"{renderDir}{subjNum}_{melConc}_{hemConc}_PermNo_{permID}_Manip"
        scene_name = f"{subjNum}_{melConc}_{hemConc}_PermNo_{permID}_Manip{handle}.pbrt"
        texture = f"PermID{permID}_{subjNum}.exr" # get the texture 
    

    #add additional name if exists]
    if handle != "":
        renderPath = f"{renderPath}{handle}"
    #append exr to render path
    renderPath = f"{renderPath}.exr"

    albedoTexturePath = f"{textureDir}{texture}"
    meshPath = pathInfo["meshPath"]
    dataSetPath = pathInfo["dataSetPath"]

    #write the scene file
    scene_file = os.path.join(scenePath, scene_name)

    with open(scene_file, "w") as scene_f:
        
        #define path info for the scene editor
        renderPathInfo = {
            "renderPath": renderPath,
            "albedoTexturePath": albedoTexturePath,
            "meshPath": f"{meshPath}{subjNum}mesh.pbrt",
            "specTexturePath": f"{dataSetPath}{subjNum}\\shader\\spec_textureISONorm.exr" 
        }

        #check all renderPath assets exist
        assetCheck(renderPathInfo)

        scene_f.write(sceneEditor(params,renderPathInfo, LightingCase).replace("\\", "\\\\"))
        if permID == "" or permID == '':
            print(f"Ground truth Scene file for subject {subjNum} created.")
            
        else:
            print(f"Perm Scene file {permID} created for subject {subjNum}.")
    scene_command = f'".\\bin\\pbrt.exe" "{scene_file}"\n'

    # Append commands to batch script if we want the subject and the .exr doesn't already exist
    if not os.path.exists(renderPath) | overwriteALL == True:
        scene_command = f'".\\bin\\pbrt.exe" "{scene_file}"\n'
        #f.write(scene_command)
    else :
        print(f"Scene {renderPath} already rendered. Overwrite?")
        #give a warning that the file already exists and ask if we want to overwrite
        #if we do, append the command to the batch script
        input("Press Y to overwrite or any other key to skip, or YY for all:")
        if input == "Y" or "YY":
            scene_command = f'".\\bin\\pbrt.exe" "{scene_file}"\n'
            #f.write(scene_command)
            if input == "YY":
                print("Overwriting all files.")
                overwriteALL = True
        else:
            print(f"Skipping {subjNum}.")
            scene_command = ""
        #if we don't, skip the subject
        
    return  overwriteALL, scene_command