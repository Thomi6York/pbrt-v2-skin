import csv
import os
import sys


def generate_scene_file(param1, param2,param3,param4, outFile):
    # Create a PBRT scene file using the parameters
    scene_text = f"""
    # PBRT scene file with parameters {param1} and {param2} and {param3} and {param4} saved to {outFile}
      
    Film "image" "integer xresolution" [1280] "integer yresolution" [720] "string filename" "./render_bulk/{outFile}"
LookAt 0.491171 -4.4848 0.897406 0 0 0 0 0 1
Camera "perspective" "float fov" [30] 
Sampler "lowdiscrepancy" "integer pixelsamples" 1 #changed to 1 for brute render speed

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
        "string mapname" [ "E:/pbrt-v2-skinPat/scenes/textures/small_rural_road_equiarea.exr" ]
        "integer	nsamples" [5] #crank this up to remove grainyness
AttributeEnd


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
                           ## this is the best K epid thickness for candiate 0 
                           "float f_mel" {param2} #from skin_code tables 
                           "float f_eu" {param4} #clamp this at 0.5 as this is where we make the pigment maps from 
               
                           "float f_blood" {param1} # abs of whole blood -- where do I get this from 
                           "float f_ohg" 0.75 #seems to be gamma ratio 
                 
                           #"texture albedo" "lambertian-norm"
                           
    Include "E:/pbrt-v2-skinPat/Scenes/geometry/processed/S000Mesh.pbrt"
    AttributeEnd
  
WorldEnd
    """

    return scene_text


def generate_render_commands(output_directory, params):
    # Generate render commands and write them to a batch file
    batch_file_path = os.path.join(output_directory, 'render_all.bat')
    with open(batch_file_path, 'w') as batch_file:
        for i in range(len(params)):
            for j in range(len(params)):
                for k in range(len(params[2][:])):
                    for b in range(len(params[3][:])): # 5 beta values

                        param1, param2,param3,param4, = params[0][i], params[1][j], params[2][k],params[3][b]
                        scene_filename = f'scene_{i}_{j}_{k}_{b}.pbrt'
                        render_command = f'..\\bin\\pbrt.exe {scene_filename} --outfile ..\\render_bulk\\{scene_filename.replace(".pbrt", ".exr")}\n'
                        batch_file.write(render_command)

def write_scene_file(scene_text, output_path):
    # Write the scene text to a .pbrt file
    with open(output_path, 'w') as f:
        f.write(scene_text)

def main(input_csv_file = 'perms.csv', reRenderInputs = False,archive=False):
     #input_CSV_file is just for the permutations that will be used in the render 
    output_directory = 'output_scenes'
    render_directory = 'render_bulk'
    archive_directory = 'render_archive'
    

    # Create the output directory if it doesn't exist
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Create the render directory if it doesn't exist
    if not os.path.exists(render_directory):
        os.makedirs(render_directory)

    # Create the archive directory if it doesn't exist
    if not os.path.exists(archive_directory):
        os.makedirs(archive_directory)
        
    # Read parameters from CSV
    with open(input_csv_file, 'r') as csv_file:
        csv_reader = csv.reader(csv_file)
        next(csv_reader)  # Skip header row if exists
        params = list(csv_reader)
    params = list(map(list, zip(*params))) #transpose the data to make it sliceable

    # Remove empty elements
    params= [[value for value in row if value.strip()] for row in params]

    # Generate combinations and create scene files
    with open("render_scenes.bat", "w") as batch_file:
        
        '''
        #original permute
        for i in range(len(params)):
            for j in range(len(params)):
                for k in range(len(params[2][:])):
                        for b in range(len(params[3][:])): # 5 beta values
                            param1, param2, param3, param4 = params[0][i], params[1][j], params[2][k],params[3][b]
                            scene_text = generate_scene_file(param1, param2,param3,param4)
                            output_filename = f'scene_{i}_{j}_{k}_{b}.pbrt'
                            output_path = os.path.join(output_directory, output_filename)
                            write_scene_file(scene_text, output_path)
                            # Render the scene using PBRT here if needed
                            # Generate render commands
                            command = f' .\\output_scenes\\{output_filename} '
                            batch_file.write(command)
                            count+=1
                            if count==20:
                                batch_file.write(f'\n .\\bin\\pbrt.exe ')
                                count = 0
    '''

        # if pre-perumted (for limited perms)
        for i in range(len(params[0][:])):
            param1, param2, param3, param4 = params[0][i], params[1][i], params[2][i],params[3][i]
            sub1,sub2,sub3,sub4 = params[4][i], params[5][i], params[6][i],params[7][i] #these are for file naming -- these will have non zero indexing 
            
            output_filename = f'scene_{sub1}_{sub2}_{sub3}_{sub4}.pbrt'
            output_path = os.path.join(output_directory, output_filename)
            #incorporate the file naming into the scene file to make it easier to track and hopefully faster
            scene_text = generate_scene_file(param1, param2,param3,param4, output_filename.replace(".pbrt", ".exr"))
            write_scene_file(scene_text, output_path)
            print(f'Scene file {output_filename} generated successfully!')
            # Render the scene using PBRT here if needed
            # Generate render commands, but only if it hasn't been done already
            
            count = 0
            if not reRenderInputs:
                #check it doesn't exist in the render directory
                if not os.path.exists(f'{render_directory}/{output_filename.replace(".pbrt", ".exr")}'):

                    #make additional checks to see if the scene has already been rendered in archive folder
                    if not os.path.exists(f'{archive_directory}/{output_filename.replace(".pbrt", ".exr")}'):
                        command = f' .\\bin\\pbrt.exe .\\output_scenes\\{output_filename}\n '
                        batch_file.write(command)
                        print(f'Render command for {output_filename} added to batch file')
                    #if it does esist in the archive folder, then we can skip the render command generation and move it to bulk render folder
                    else:
                        os.rename(os.path.join(archive_directory, output_filename.replace(".pbrt", ".exr")), os.path.join(render_directory, output_filename.replace(".pbrt", ".exr")))
                        print(f'{output_filename} already rendered, moving to render directory but skipping render command generation')
                        count += 1
                else:
                    print(f'{output_filename} already rendered in render directory  , skipping render command generation')
                    count += 1
            else: # we always want to render the scene files if reRenderInputs is set to True
                command = f' .\\bin\\pbrt.exe .\\output_scenes\\{output_filename}\n '
                batch_file.write(command)
                print(f'Render command for {output_filename} added to batch file')
                count += 1
    
    print(f'{count} scene files already rendered, skipping render command generation for those scenes')
    #generate_render_commands(output_directory, params)
    print('Scene files generated successfully!')

    if archive == True:
        # Search through the directory and move scenes which have been rendered to the archive directory
        print('Moving rendered scene files to archive directory...')
        count = 0
        for filename in os.listdir(output_directory):
            if filename.endswith('.pbrt'):
                archive_filename = filename.replace('.pbrt', '.pbrt')
                if archive_filename in os.listdir(render_directory):
                    os.rename(os.path.join(output_directory, filename), os.path.join(archive_directory, archive_filename))
                    print(f'Moved {filename} to {archive_directory}/{archive_filename} because it was already rendered')
                    count += 1
                    
        print(f'{count} scene files moved to archive directory')

        # Move rendered exr files not in the perms list to the archive directory
        print('Moving rendered exr files not in the perms list to the archive directory...')
        count = 0
        for filename in os.listdir(render_directory):
            if filename.endswith('.exr'):
                if filename.replace('.exr','.pbrt') not in os.listdir(output_directory):
                    os.rename(os.path.join(render_directory, filename), os.path.join(archive_directory, filename))
                    print(f'Moved {filename} to {archive_directory}/{filename} because it was not in the perms list')
                    count += 1
        
        print(f'{count} exr files moved to archive directory')
        
    
    # Count the number of scene files added to the batch file
    scene_file_count = 0
    with open("render_scenes.bat", "r") as batch_file:
        for line in batch_file:
            if line.strip().endswith('.pbrt'):
                scene_file_count += 1

    # Count the number of scene files that have already been rendered
    rendered_file_count = 0
    for filename in os.listdir(render_directory):
        if filename.endswith('.exr'):
            rendered_file_count += 1

    print(f"Number of scene files added to batch file: {scene_file_count}")
    print(f"Number of scene files already rendered: {rendered_file_count}")
    
    print('Executing render commands...')

    # Execute the batch file to render the scene files
    os.system('render_scenes.bat')

    print('Render commands executed successfully!')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python SceneMaker.py <input_csv_file> <reRenderInputs>")
        sys.exit(1)
    input_csv_file = sys.argv[1]
    print(f"Input CSV file: {input_csv_file}")
    
    #check input file exists
    if not os.path.exists(input_csv_file):
        print(f"Error: {input_csv_file} does not exist")
        sys.exit(1)
    main(input_csv_file,reRenderInputs=sys.argv[2])
