import subprocess
import glob
import os
import glob

#this script executes the texture modulation for the images using Matlab and then renders the scene using PBRT

#currently we are wendering without specularity since it is an albedo modulation -- we can add this in later

#parameters for the scene editor should be 3rd percentiles given by the matlab script 

# pbrt template goes here:
def sceneEditor(OutPath,subjNum,param1,param2,param3,param4):
    template = f"""
            Film "image" "integer xresolution" [1280] "integer yresolution" [720] "string filename" "{OutPath}{subjNum}noSpec.exr"
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
                "string mapname" [ "..\\..\\scenes\\textures\\small_rural_road_equiarea.exr" ]
                "integer	nsamples" [5] #crank this up to remove grainyness
        AttributeEnd


           Texture "lambertian-norm" "color" "imagemap" "string filename" "..\\..\\scenes\\textures\\normTex\\normTex{subjNum}.exr"
            "string wrap" "clamp" "float gamma" 1 "float scale" 1
            Texture "spec" "color" "imagemap" "string filename"  "..\\..\\scenes\\PilotDataSet\\S000\\shader\\spec_texture.tga"
            "string wrap" "clamp" "float gamma" 2.2 "float scale" 2

        AttributeBegin
            Translate 0 1 -.35 # move up a bit
            Rotate 90  1 0 0
            Scale 3 3 3
            # lets try and run this wihtout loading the textures 
            Material "layeredskin" "float roughness" 0.35 #0.35 is the paper value 
                                "float nmperunit" 40e6 # nanometers per unit length in world space
                                "color Kr" [0 0 0]
                                "color Kt" [0 0 0] # edit did little changing from 1 to zero  -- this is translucency; can't be seen with a black background
                                # each layer's depth and index of refraction; units are in nanometers

                                "skinlayer layers" [ {param3}e6 1.4 20e6 1.4] # is this the thickness -- or above
                               
                                "float f_mel" {param2} #from skin_code tables 
                                "float f_eu" {param4} #clamp this at 0.5 as this is where we make the pigment maps from 
                    
                                "float f_blood" {param1} # abs of whole blood -- where do I get this from 
                                "float f_ohg" 0.75 #seems to be gamma ratio 
                        
                                "texture albedo" "lambertian-norm"
                                
            Include "../../scenes/geometry/processed/{subjNum}Mesh.pbrt"
            AttributeEnd
        
        WorldEnd

        

    """
    return template


def main():
    #this contains the script and image generation code

    # check texture path exists and create if not
    OutPath = ".\\scenes\\textures\\normTex\\"
    file_list = os.listdir(OutPath)
    print(file_list)
    if not os.path.exists(OutPath):
        os.makedirs(OutPath)
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

    # Define the MATLAB script file
    matlab_script = "textureEditor.m"

    dataSetPath = ".\\scenes\\PilotDataSet\\"

    # Run MATLAB script using subprocess
    #subprocess.run(["matlab", "-batch", "run('{}')".format(matlab_script)])


    # Find the generated images by looking for a pattern (assuming they are saved as .exr files)
    image_files = glob.glob(f"{OutPath}*.exr")

    # Write batch script to render all scenes using PBRT
    batch_script = "render_NormTex.bat"

    with open(batch_script, "w") as f:
        image_files = glob.glob(f"{OutPath}*.exr")

        # Loop through the image files
        for image_file in image_files:
            image_name = os.path.basename(image_file).split(".")[0]  # Remove the file extension
            subjNum = image_name[7:]  # Extract the subject number from the image name
            # Read the parameter values from the cache text file
            cache_file = f"./results/pigmentMaps/cache_{subjNum}.txt"
            
            with open(cache_file, "r") as cache_f:
                lines = cache_f.readlines()
                param1 = float(lines[0].split(":")[1].strip()) #mel
                param2 = float(lines[1].split(":")[1].strip()) #hem
                param3 = float(lines[6].split(":")[1].strip()) #beta
                param4 = float(lines[7].split(":")[1].strip()) #this is epth
                param4 = param4 *0.001 #scale 

            #check if specular texture is a tga or exr file
            if os.path.exists(os.path.join(dataSetPath, f"//{subjNum}//shader//spec_texture.exr")):
                print("spec texture is an exr file")
            elif os.path.exists(os.path.join(dataSetPath, f"//{subjNum}//shader//spec_texture.tga")):
                print("spec texture is a tga file")
            elif os.path.exists(os.path.join(dataSetPath, f"//{subjNum}//shader//spec_texture.bmp")):
                print("spec texture is a bmp file")
            else:
                print("spec texture not found") 
                
            # Write PBRT scene file
            scene_name = image_name.replace(".exr", ".pbrt")
            scene_file = os.path.join(scenePath, scene_name)
            print("writing scene file... to: ", scene_file)

            with open(scene_file, "w") as scene_f:
                # Write the scene contents
                scene_f.write(sceneEditor(renderPath, subjNum, param1, param2, param3, param4).replace("\\", "\\\\"))
                print(f"Scene file created for subject {subjNum}.")

            # Write the batch script command to render the scene using PBRT
            f.write(f".\\bin\\pbrt.exe {scene_file}\n")
            print(f"Added render command for scene {subjNum} to batch script.")

    print("Batch script created: render_all.bat")

    print("Script execution completed.")

    print("Rendering scenes...")

    # Render the scenes using PBRT
    subprocess.run(["render_NormTex.bat"])
    
    print("Rendering completed.")

if __name__ == "__main__":
    main()