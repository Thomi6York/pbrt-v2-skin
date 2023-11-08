import argparse
import pymeshlab as ml
import sys

# Define a function to process a single mesh file which we can call in a batch
def process_mesh(input_file, output_file):
    ms = ml.MeshSet()
    ms.load_new_mesh(input_file)

    

    # Apply your desired mesh processing operations here
    ms.compute_matrix_from_scaling_or_normalization( #should scale and normalize as gui, but ignores normals for some reason 
        axisx=1.0, #axis limits 
        axisy=1.0,
        axisz=1.0,
        uniformflag=True,
        scalecenter='origin', #scale to origin of space
        customcenter=[0.0, 0.0, 0.0], #custom centre if you want one
        unitflag=True, #bounding box
        freeze=True, # freeze matrix values 
        alllayers=True #apply to all visible layers
    )

    ms.apply_normal_normalization_per_vertex() #normalize normals
    ms.compute_texcoord_transfer_wedge_to_vertex() #covert wedge coord to tex coords [may not be the case for Will]
    
    # Save the processed mesh
    ms.save_current_mesh(output_file,
                         save_wedge_texcoord=False,
                         save_wedge_normal=False,
                         save_vertex_coord=True,
                         save_vertex_normal=True
                         )
    
    print("Mesh saved to " + output_file)

if __name__ == "__main__": #this is so I can call as an arg in a cmd line 
    parser = argparse.ArgumentParser(description="Process 3D mesh files.")
    parser.add_argument("input_file", help="Input mesh file to process.")
    parser.add_argument("output_file", help="Output path for the processed mesh.")

    args = parser.parse_args()

    try:
        process_mesh(args.input_file, args.output_file)
    except Exception as e:
        print(f"Error: {e}")
        parser.print_help()
        sys.exit(1)
