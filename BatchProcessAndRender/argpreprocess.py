import argparse
import pymeshlab as ml
import sys

# Define a function to process a single mesh file which we can call in a batch
def process_mesh(input_file, output_file):
    ms = ml.MeshSet()
    ms.load_new_mesh(input_file)

    

    # Apply your desired mesh processing operations here
    ms.compute_matrix_from_scaling_or_normalization(
        axisx=1.0,
        axisy=1.0,
        axisz=1.0,
        uniformflag=True,
        scalecenter='origin',
        customcenter=[0.0, 0.0, 0.0],
        unitflag=True,
        freeze=True,
        alllayers=True
    )

    ms.apply_normal_normalization_per_vertex()
    ms.compute_texcoord_transfer_wedge_to_vertex()
    
    # Save the processed mesh
    ms.save_current_mesh(output_file,
                         save_wedge_texcoord=False,
                         save_wedge_normal=False,
                         save_vertex_coord=True,
                         save_vertex_normal=True
                         )
    
    print("Mesh saved to " + output_file)

if __name__ == "__main__":
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
