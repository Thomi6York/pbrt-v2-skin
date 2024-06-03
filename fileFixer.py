# the purpose of this is to fix the incorrectly scaled epidermal thickness data in the .pbrt scene files

import os
import sys
import csv


def fixFile(file):
        #remove the .pbrt extension
        file = file.replace('.pbrt', '')
        #break the filename into the 4 param indices
        filename = file.split('_')

        # extract the parameter values
        paramInd1 = int(filename[1])
        paramInd2 = int(filename[2])
        paramInd3 = int(filename[3])
        paramInd4 = int(filename[4])

        #load the csv file
        with open('PigmentSamplingValuesWThickness.csv', 'r') as f:
            reader = csv.reader(f)
            #thickness is 3rd column
            #load each column into a list
            pigmentValues = list(reader)

            #select correct pigment value using param3
            hemValue = pigmentValues[paramInd1][0]
            MelValue = pigmentValues[paramInd2][1]
            epValue = pigmentValues[paramInd3][2] 
            betaValue = pigmentValues[paramInd4][3]

        return hemValue, MelValue, epValue, betaValue, paramInd1, paramInd2, paramInd3, paramInd4

#loop through all files in output directory
outputDir = "\\output_scenes\\"

count = 0
for file in os.listdir(os.getcwd() + outputDir):
    if file.endswith(".pbrt"):
        print("Checking file: " + file)
        # open file and check for incorrect scaling
        with open(os.getcwd() + outputDir + file, 'r') as f:
            line = f.readlines()[37]  # Read line 38
            # split in between square bracket and e
            splitL = line.split('[')[1:]
            splitL = splitL[0].split('e')[:1]
            thickness = float(splitL[0])
            # if thickness is greater than 1, then it is incorrectly scaled
            if thickness > 1:
                print("Incorrectly scaled file: " + file)
                hemValue, MelValue, epValue, betaValue, paramInd1, paramInd2, paramInd3, paramInd4 = fixFile(file)
                print("Fixed file: " + file)

                # write these to another csv for loading into scenemaker
                with open('correctedValues.csv', 'a') as f:
                    writer = csv.writer(f)
                    # append to bottom of csv
                    if count == 0:
                        writer.writerow(["Hemoglobin", "Melanin", "Thickness", "Beta", "HemIndex", "MelIndex", "ThicknessIndex", "BetaIndex"])
                    # write the values to the csv
                    writer.writerow([hemValue, MelValue, epValue, betaValue, paramInd1, paramInd2, paramInd3, paramInd4])
                count += 1

    
