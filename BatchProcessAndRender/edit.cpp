#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

int main() {
    // Define the CSV input file path -- just change val in testval
    std::string csvFile = "E:\\pbrt-v2-skinPat\\BatFiles\\testVal.csv";
    std::string outpath = "E:\\pbrt-v2-skinPat\\results\\";

    // Open the CSV input file
    std::ifstream inputFile(csvFile);
    if (!inputFile.is_open()) {
        std::cerr << "Error: Unable to open input file." << std::endl;
        return 1;
    }

    // Read and process each line of the CSV
    std::string line;
    while (std::getline(inputFile, line)) {
        std::istringstream iss(line);
        std::string param1Str, param2Str;
        

        if (std::getline(iss, param1Str, ',') && std::getline(iss, param2Str, ',')) {
            // Convert the parameter values to the appropriate data types
            float param1 = std::stof(param1Str);
            float param2 = std::stof(param2Str);

            std::string pbrtSceneFileName = outpath + "Eum" + param1Str + '_' + "Deoxy" + param2Str+ ".pbrt";

            // Open the template .pbrt file for reading
            std::ifstream templateFile("E:\\pbrt-v2-skinPat\\scenes\\template.pbrt");
            if (!templateFile.is_open()) {
                std::cerr << "Error: Unable to open template file." << std::endl;
                return 1;
            }

        
            

            // Create a new .pbrt scene file for writing
            std::ofstream pbrtSceneFile(pbrtSceneFileName);
            if (!pbrtSceneFile.is_open()) {
                std::cerr << "Error: Unable to create .pbrt scene file." << std::endl;
                templateFile.close();
                return 1;
            }

            // Replace placeholders in the template file with parameter values
            std::string templateLine;
            while (std::getline(templateFile, templateLine)) {
                // Replace placeholders PARAM1 and PARAM2 with parameter values
                size_t param1Pos = templateLine.find("0.6"); //orginal value for eum
                if (param1Pos != std::string::npos) {
                    templateLine.replace(param1Pos, 6, std::to_string(param1));
                }

                size_t param2Pos = templateLine.find("0.009"); //I just use the original values here to make it easier -f_blood here
                if (param2Pos != std::string::npos) {
                    templateLine.replace(param2Pos, 6, std::to_string(param2));
                }

                // Write the modified line to the new .pbrt scene file
                pbrtSceneFile << templateLine << std::endl;
            }

            // Close the template and output .pbrt files
            templateFile.close();
            pbrtSceneFile.close();
        }
    }
    

    // Close the input CSV file
    inputFile.close();

    std::cout << "Scene files generation complete." << std::endl;

    return 0;
}
