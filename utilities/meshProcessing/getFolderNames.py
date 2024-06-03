import argparse
import os
import sys


def getFolderNames(inPath,outPath):
    #inPath ="C:/Users/tw1700/OneDrive - University of York/Documents/PhDCore/Experiments/PilotDataSet/"
    #outPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Practical\\DJModel\\pbrt-v2-skin\\scenes\\geometry\\ProcDatasetHeads\\"
    # Define the directory path
    # Get a list of folder names in the directory
    folder_names = [d for d in os.listdir(inPath) if os.path.isdir(os.path.join(inPath, d))]

    # Print the list of folder names
    for folder_name in folder_names:
        print(folder_name)

    # Save the folder names to a list
    folder_name_list = folder_names

    # Save the folder names to a text file
    with open(outPath+'folder_names.txt', 'w') as file:
        file.write('\n'.join(folder_name_list))
    print("Written dir names to "+outPath)

## help stuff
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Export directory names for mesh subjects.")
    parser.add_argument("inPath", help="Where the directories are.")
    parser.add_argument("outPath", help="Output path for text file.")

    args = parser.parse_args()

    try:
        getFolderNames(args.inPath, args.outPath)
    except Exception as e:
        print(f"Error: {e}")
        parser.print_help()
        sys.exit(1)


