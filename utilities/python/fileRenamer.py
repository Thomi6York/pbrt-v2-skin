import os
import re

# Define the constant values for the first two zeros
constant_values = (23, 2) # this is for the earliest run in the archives 

# Define the directory containing the files
directory = "E:\\RenderArchives\\RenderArchives\\0.25mmBaseRun\\render_bulk\\"

# Define the pattern to match the filenames
pattern = re.compile(r'scene_(\d+)_(\d+)\.exr')

# Iterate over the files in the directory
for filename in os.listdir(directory):
    # Check if the file matches the pattern
    match = pattern.match(filename)
    if match:
        # Extract the values from the original filename
        value1, value2 = match.groups()

        # Convert value1 and value2 to integers
        value1 = int(value1)
        value2 = int(value2)

        # Add 1 to the values
        value1 += 1
        value2 += 1

        # Convert the values back to strings
        value1 = str(value1)
        value2 = str(value2)

        # Construct the new filename and add index to match new subs
        new_filename = f"scene__{value1}_{value2}_{constant_values[0]}_{constant_values[1]}.exr"

        # Rename the file
        os.rename(os.path.join(directory, filename), os.path.join(directory, new_filename))
        print(f"Renamed {filename} to {new_filename}")
    else:
        print(f"Skipping {filename} as it doesn't match the pattern")
