# Set the file path
#file_path = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\Practical\\DJModel\\pbrt-v2-skin\\scenes\\geometry\\ProcDatasetHeads\\S007meshProc.pbrt"

import argparse

def headerRemove(file_path):
    with open(file_path, "r+") as file:
        lines = file.readlines()
        lines[6:10] = ["\n", "\n", "\n"]
        file.seek(0)
        file.writelines(lines)
        file.truncate()

def main():
    parser = argparse.ArgumentParser(description="Remove lines 7, 8, and 9 and overwrite with empty lines.")
    parser.add_argument("file_path", help="Path to the file to edit in-place.")
    args = parser.parse_args()
    
    headerRemove(args.file_path)
    print("Lines 7, 8, and 9 have been overwritten with empty lines.")

if __name__ == "__main__":
    main()

