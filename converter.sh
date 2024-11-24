#!/bin/bash

# Ask the user for the location of the files
read -p "Enter the directory where the files are located: " inputDirectory

# Check if the input directory exists
if [ ! -d "$inputDirectory" ]; then
    echo "Directory '$inputDirectory' does not exist or is not accessible."
    exit 1
fi

# Set the output directory
outputDirectory="$inputDirectory/output"

# Possible paths to check for the installation
inkscapePaths=(
    "/usr/bin/inkscape"
    "/usr/local/bin/inkscape"
    "/usr/bin/inkscape-bin"
    "/usr/local/bin/inkscape-bin"
    "$(flatpak info org.inkscape.Inkscape &>/dev/null && echo 'flatpak')"
)

availableInkscapes=()

# Find available Inkscape installations
for path in "${inkscapePaths[@]}"; do
    if [ "$path" == "flatpak" ]; then
        flatpakInkscape="$(flatpak list | grep -o 'org.inkscape.Inkscape')"
        if [ -n "$flatpakInkscape" ]; then
            availableInkscapes+=("$flatpakInkscape (Flatpak)")
        fi
    elif [ -x "$path" ]; then
        availableInkscapes+=("$path")
    fi
done

# Prompt the user to choose an Inkscape installation
if [ "${#availableInkscapes[@]}" -eq 0 ]; then
    read -p "No Inkscape installation found. Are you using an AppImage? (y/n): " appImageResponse
    if [ "$appImageResponse" == "y" ]; then
        read -p "Please enter the path to the Inkscape AppImage: " appImagePath
        if [ -x "$appImagePath" ]; then
            inkscapePath="$appImagePath"
        else
            echo "The AppImage file is not executable or does not exist. Aborting."
            exit 1
        fi
    else
        echo "No Inkscape installation found. Aborting."
        exit 1
    fi
else
    echo "Available Inkscape installations:"
    for i in "${!availableInkscapes[@]}"; do
        echo "$((i + 1))) ${availableInkscapes[i]}"
    done
    read -p "Choose the Inkscape installation to use (1-${#availableInkscapes[@]}): " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#availableInkscapes[@]}" ]; then
        echo "Invalid choice. Aborting."
        exit 1
    fi
    selectedPath="${availableInkscapes[$((choice - 1))]}"
    if [[ "$selectedPath" == *"(Flatpak)"* ]]; then
        inkscapePath="flatpak run org.inkscape.Inkscape"
    else
        inkscapePath="$selectedPath"
    fi
fi

# Allowed file types
validInput=("svg" "pdf" "eps" "emf" "wmf" "sif")
validOutput=("eps" "pdf" "png" "svg" "sif")

inkscapeVersion="$($inkscapePath --version)"
echo ""
echo "This script allows you to convert all files in $inputDirectory from one file type to another"
echo "Running with $inkscapeVersion"
echo "(type q to quit at any question)"
echo ""

# Choose source type
echo "Allowed file types for source: ${validInput[*]}"
while true; do
    read -p "What file type do you want to use as a source? " sourceType
    if [[ "$sourceType" == "q" ]]; then
        exit 0
    fi
    if [[ " ${validInput[*]} " == *" $sourceType "* ]]; then
        break
    else
        echo "Invalid input! Please use one of the following: ${validInput[*]}"
    fi
done

# Choose output type
echo ""
echo "Allowed file types for output: ${validOutput[*]}"
while true; do
    read -p "What file type do you want to convert to? " outputType
    if [[ "$outputType" == "q" ]]; then
        exit 0
    fi
    if [[ " ${validOutput[*]} " == *" $outputType "* ]]; then
        break
    else
        echo "Invalid input! Please use one of the following: ${validOutput[*]}"
    fi
done

if [[ "$outputType" == "$sourceType" ]]; then
    echo "Input and Output are the same, no point in doing anything. Exiting..."
    exit 0
fi

# Create the output directory if it doesn't exist
mkdir -p "$outputDirectory"

total=$(find "$inputDirectory" -maxdepth 1 -type f -name "*.$sourceType" | wc -l)
echo "Conversion started. Will do $total file(s)."
echo ""

count=0

for file in "$inputDirectory"/*."$sourceType"; do
    ((count++))
    echo "$file -> $outputDirectory/$(basename "$file" ".$sourceType").$outputType [$count/$total]"
    $inkscapePath --export-type="$outputType" --export-dpi=300 --batch-process "$file" --export-filename="$outputDirectory/$(basename "$file" ".$sourceType").$outputType"
done

echo ""
echo "$count file(s) converted from $sourceType to $outputType! (Saved in $outputDirectory)"
echo "Using Inkscape binary: $inkscapePath"
echo ""
