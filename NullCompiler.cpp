#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <map>
#include <iomanip>
#include <fstream>
#include <filesystem>

namespace fs = std::filesystem;

const std::map<std::string, int> TYPE_SIZES = {
    {"small", 1},
    {"data",  4},
    {"large", 8}
};

struct Variable {
    std::string type;
    std::string name;
    int size_bytes;
    int memory_address;
};

std::vector<std::string> tokenize(const std::string& content) {
    std::vector<std::string> tokens;
    std::stringstream ss(content);
    std::string token;

    while (ss >> token) {
        if (!token.empty() && token.back() == ';') token.pop_back();
        if (!token.empty()) tokens.push_back(token);
    }
    return tokens;
}

int main() {
    std::string target_folder = ".";
    std::string full_project_folder = "";

    std::cout << "=======================================\n";
    std::cout << "             Null Compiler             \n";
    std::cout << "=======================================\n";
    std::cout << "[*] Scanning directory: \"" << target_folder << "\" for source files...\n";

    std::string raw_source_code = "";
    try {
        for (const auto& entry : fs::directory_iterator(target_folder)) {
            if (entry.is_regular_file() && entry.path().extension() == ".null") {
                std::ifstream file(entry.path());
                if (file.is_open()) {
                    std::stringstream buffer;
                    buffer << file.rdbuf();
                    raw_source_code += buffer.str() + " ";
                    std::cout << "[*] Loaded file: " << entry.path().filename() << "\n";
                }
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "[-] Error scanning directory: " << e.what() << "\n";
        return 1;
    }

    if (raw_source_code.empty()) {
        std::cout << "[!] No .null files found. Using hardcoded test string.\n";
        raw_source_code = "small test_byte data system_clock large memory_bank";
    }

    std::vector<std::string> tokens = tokenize(raw_source_code);
    std::vector<Variable> memory_belt;
    int current_memory_pointer = 0;

    size_t i = 0;
    while (i < tokens.size()) {
        if (TYPE_SIZES.count(tokens[i])) {
            if (i + 1 < tokens.size()) {
                std::string type = tokens[i];
                std::string name = tokens[i + 1];
                int byte_size = TYPE_SIZES.at(type);

                Variable var = {type, name, byte_size, current_memory_pointer};
                memory_belt.push_back(var);

                current_memory_pointer += byte_size;
                i += 2;
            }
            else {
                std::cerr << "[-] Error: Trailing type identifier without variable name.\n";
                break;
            }
        } else {
            i++;
        }
    }

    std::cout << "\n--- Generated Binary Memory Layout ---\n";
    for (const auto& var : memory_belt) {
        std::cout << "Address Offset [" << std::setw(2) << var.memory_address << "] | ";
        for (int b = 0; b < var.size_bytes; ++b) {
            std::cout << "[BYTE] ";
        }
        std::cout << " -> (" << var.type << " " << var.name << " [" << var.size_bytes << " bytes])\n";
    }
    std::cout << "--------------------------------------\n";
    std::cout << "Total Binary Payload Size: " << current_memory_pointer << " Bytes.\n";

    std::string output_filename = target_folder + "/output.bin";
    std::ofstream binary_file(output_filename, std::ios::out | std::ios::binary);

    if (binary_file.is_open()) {
        std::vector<char> raw_binary_payload(current_memory_pointer, 0);

        binary_file.write(raw_binary_payload.data(), raw_binary_payload.size());
        binary_file.close();

        std::cout << "[+] Successfully exported raw binary: " << output_filename
                  << "  (" << current_memory_pointer << " bytes)\n";
    } else {
        std::cerr << "[-] Error: Could not generate raw binary file.\n";
    }

    return 0;
}
