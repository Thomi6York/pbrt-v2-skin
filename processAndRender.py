import glob
import os
import glob
import shlex
import subprocess

#this script executes the texture modulation for the images using Matlab and then renders the scene using PBRT

#currently we are wendering without specularity since it is an albedo modulation -- we can add this in later

#parameters for the scene editor should be 3rd percentiles given by the matlab script 

#dataset at: C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\Practical Rendering\Skin_code\data\ICT_3DRFE_mod


#set options for the script
batchRenderGT = True #will render all the scenes in the batch script
reinverseRenderAll = True
writeSceneFile = True
permuteScene = True
generatePermTextures = True
batchRenderPerms = True

subjects = 0; #subjects to render -- these are the subjects we are inverse rendering
#subjects = [0,3,7,22]; 
#subjects =5; 

#add the options to an object
options = {
    "batchRenderGT": batchRenderGT,
    "reinverseRenderAll": reinverseRenderAll,
    "writeSceneFile": writeSceneFile,
    "permuteScene": permuteScene,
    "subjects": subjects,
    "generatePermTextures": generatePermTextures,
    "batchRenderPerms": batchRenderPerms
}

# pbrt template goes here:
def sceneEditor(OutFilePath, TexPath,subjNum,melConc,hemConc,betaConc,epThickness,texture):
    template = f"""
        Film "image" "integer xresolution" [1280] "integer yresolution" [720] "string filename" "{OutFilePath}"
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
                "string mapname" [ "..\\..\\scenes\\textures\\small_rural_road_equiarea.exr" ]
                "integer	nsamples" [5] #crank this up to remove grainyness
        AttributeEnd


        Texture "lambertian-norm" "color" "imagemap" "string filename" "..\..\{TexPath}{texture}"
            "string wrap" "clamp" "float gamma" 1 "float scale" 1
        Texture "spec" "color" "imagemap" "string filename"  "..\\..\\scenes\\PilotDataSet\\{subjNum}\\shader\\spec_texture.tga"
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
                                
                                
            Include "../../scenes/geometry/processed/{subjNum}Mesh.pbrt"
        AttributeEnd
        
        WorldEnd
    """
    return template

def  createPaths():

    # check texture path exists and create if not
    TexPath = ".\\scenes\\textures\\normTex\\"
    file_list = os.listdir(TexPath)
    print(file_list)
    if not os.path.exists(TexPath):
        os.makedirs(TexPath)
        print("Texture path created.")
    else:
        print("Texture path already exists.")

    #check render path exists and create if not
    renderPath = ".\\results\\groundTruth\\"
    if not os.path.exists(renderPath):
        os.makedirs(renderPath)
        print("Render path created.")
    else:
            print("Render path already exists.")

    scenePath = ".\\scenes\\normTexScenes\\"
    if not os.path.exists(scenePath):
        os.makedirs(scenePath)
        print("Scene path created.")
    else:
        print("Scene path already exists.")


    dataSetPath = ".\\scenes\\PilotDataSet\\"

    return TexPath, renderPath, scenePath, dataSetPath

def readCacheFile(cache_file):
    with open(cache_file, "r") as cache_f:
        lines = cache_f.readlines()
        melConc = float(lines[0].split(":")[1].strip()) #mel
        hemConc = float(lines[1].split(":")[1].strip()) #hem
        betaConc = float(lines[5].split(":")[1].strip()) #beta
        epThickness = float(lines[7].split(":")[1].strip()) #this is epth
        epThickness = epThickness *0.001 #scale 
    return melConc, hemConc, betaConc, epThickness


def main(options):

    #give a prompt to ask about repeat the inverse render the subjects
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

    
    if reinverseRenderAll:
        print("Re-inverse rendering all subjects.")
    else:
        print("Skipping re-inverse rendering.")
    #write an options file to store the inverse render option
    with open("options.txt", "w") as f:
            f.write(f"{str(reinverseRenderAll)}\n")

    #print("This script will execute the texture modulation and rendering process for the subjects specified in the subjects.csv file.")
    #this contains the script and image generation code
    
    
    #handles creating paths        
    TexPath, renderPath, scenePath, dataSetPath = createPaths(); 

    # Run MATLAB script using subprocess
    matlab_script = "textureEditor.m"

    if reinverseRenderAll == True:
        print("Running MATLAB script to generate texture maps.")
        subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])


    # Find the generated images by looking for a pattern (assuming they are saved as .exr files)
    image_files = glob.glob(f"{TexPath}*.exr")

    # Write batch script to render all scenes using PBRT
    batch_script = "render_NormTex.bat"

    image_files = glob.glob(f"{TexPath}*.exr")
    if writeSceneFile == True:

        with open(batch_script, "w") as f:

            print("Writing scene files and batch script.")
            
            # Loop through the image files
            for image_file in image_files:

                print(f"Processing image: {image_file}")
                image_name = os.path.basename(image_file).split(".")[0]  # Remove the file extension

                #find the subject number from the image name using the pattern
                subjNum = image_name[-4:]  # Extract the subject number from the image name
                fileHandle = image_name[:-4] #fileHandleTellsUsWhat to save to from different textures 
                #add the extension back on
                image_name = image_name + ".exr"
                # Read the parameter values from the cache text file
                cache_file = f"./results/pigmentMaps/cache_{subjNum}.txt"
                
                #read cache file and get params
                melConc, hemConc, betaConc, epThickness = readCacheFile(cache_file)

                # Check if specular texture is a tga or exr file
                spec_texture_path = os.path.join(dataSetPath, f"{subjNum}//shader//spec_texture.bmp")
                if os.path.exists(spec_texture_path):
                    print("spec texture is a bmp file")
                else:
                    print("spec texture not found") 
                    
                # Write PBRT scene file
                scene_name = image_name.replace(".exr", ".pbrt")
                scene_file = os.path.join(scenePath, scene_name)
                print("writing scene file... to: ", scene_file)

                texture = f"{fileHandle}{subjNum}" #texture you want to use -- this is the texture name

                #only do subjects we want in batch
                if subjNum in subjects:
                    with open(scene_file, "w") as scene_f:
                        # Write the scene contents
                        outFilePath = f"{renderPath}{fileHandle}{subjNum}.exr"
                        scene_f.write(sceneEditor(outFilePath, subjNum, melConc, hemConc, betaConc, epThickness,texture).replace("\\", "\\\\"))
                        print(f"Scene file created for subject {subjNum}.")

                    # Write the batch script command to render the scene using PBRT
                    scene_command = f".\\bin\\pbrt.exe {scene_file}\n"
                    f.write(scene_command)
                    print(f"Added render command for scene {subjNum} to batch script.")

                # copy the scene file but comment out the specular texture and change the output path
                scene_name =  f"NoSpec{subjNum}.pbrt"
                scene_file = os.path.join(scenePath, scene_name)
                with open(scene_file, "w") as scene_f:
                    #write non specular 
                    #remeber paths are set relatve to the pbrt file not the python script
                    outFilePath = f"..\\..\\{renderPath}{fileHandle}{subjNum}NoSpec.exr"
                    scene = sceneEditor(outFilePath, subjNum, melConc, hemConc, betaConc, epThickness,texture).replace("\\", "\\\\")
                    #comment out specular texture
                    scene.replace('"texture Kr" "spec" #specular texture', '#"texture Kr" "spec" #specular texture')
                    scene_f.write(scene)

                # Write the batch script command to render the scene using PBRT
                if subjNum in subjects:
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

                    #these are in the permutations subdirectory 
                    permsPath = ".\\scenes\\textures\\normTex\\permutations\\"

                    #get text file names 
                    permFiles = glob.glob(f"{permsPath}*.txt")
                    #loop through the permutations in the cache file's and generate scenes 
                    for index, permFile in enumerate(permFiles):
                        permFileName = os.path.basename(permFile)
                        #only process the file if it matches the current subject
                        if permFileName[-8:-4] in subjects:
                            with open(permFile, "r") as cache_f:
                                lines = cache_f.readlines()
                                subjNum = lines[0].split(":")[1].strip() # subj ID 
                                melConc = float(lines[1].split(":")[1].strip()) #mel
                                hemConc = float(lines[2].split(":")[1].strip()) #hem
                                betaConc = float(lines[6].split(":")[1].strip()) #beta
                                epThickness = float(lines[8].split(":")[1].strip()) #this is epth
                                epThickness = epThickness*0.001 #scale 
                                permID = lines[9].split(":")[1].strip() #perm ID
                            
                            #remember paths are set relative to the pbrt file not the python script
                            #lets set the saving path with absolute paths to avoid confusion

                            # make a directory for permuted renders if it doesn't exist
                            if not os.path.exists(f"{renderPath}permutations\\"):
                                os.makedirs(f"{renderPath}permutations\\")
                                print("Permutations render path created.")

                            outFilePath = f"C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\results\\groundTruth\\permutations\\{subjNum}_{melConc}_{hemConc}_PermNo_{permID}_Manip.exr"

                            #write the scene file
                            scene_name = f"{subjNum}_{melConc}_{hemConc}_PermNo_{permID}_Manip.pbrt"
                            scene_file = os.path.join(scenePath, scene_name)

                            with open(scene_file, "w") as scene_f:
                                texture = f"PermID{permID}_ISONorm{subjNum}.exr" # get the texture 
                                #check texture exists
                                if not os.path.exists(f"{permsPath}{texture}"):
                                    print(f"Texture {permsPath}{texture} not found.")
                                scene_f.write(sceneEditor(outFilePath, permsPath, subjNum, melConc, hemConc, betaConc, epThickness,texture).replace("\\", "\\\\"))
                                print(f"Perm Scene file {permID} created for subject {subjNum}.")

                            # Append commands to batch script if we want the subject and the .exr doesn't already exist
                            if subjNum in subjects:
                                if not os.path.exists(outFilePath):
                                    scene_command = f".\\bin\\pbrt.exe {scene_file}\n"
                                    f.write(scene_command)
            
    print("Batch script created: render_all.bat")

    print("Script execution completed.")

    '''
    for j in range(4):
        scene_name = f"{subjNum}_{permutations[j][0]}_{permutations[j][1]}Manip.pbrt"
        scene_file = os.path.join(scenePath, scene_name)
        
        melConc = permutations[j][0]
        hemConc = permutations[j][1]

        
        # Write PBRT scene file
        with open(scene_file, "w") as scene_f:
            # Write the scene contents
            outFilePath = f"{renderPath}{subjNum}_{melConc}_{hemConc}Manip.exr"
            scene_f.write(sceneEditor(outFilePath, subjNum, melConc, hemConc, betaConc, epThickness).replace("\\", "\\\\"))
            print(f"Perm Scene file {j} created for subject {subjNum}.")

        # Write the batch script command to render the scene using PBRT
        scene_command = f".\\bin\\pbrt.exe {scene_file}\n"
        f.write(scene_command)
        print(f"Added render command for scene {subjNum}, permutation {j} to batch script.")
    '''
                
    if options["batchRenderGT"]==True:
        print("Rendering scenes...")
        subprocess.run(["render_NormTex.bat"])
        print("Rendering completed.")

    if options["batchRenderPerms"] ==True:
        print("Rendering permutations...")
        subprocess.run(["render_Perms.bat"])
        print("Rendering completed.")
    
    

if __name__ == "__main__":
    main(options)