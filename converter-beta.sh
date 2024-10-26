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
inkscapePath1="/usr/bin/inkscape"
inkscapePath2="/usr/local/bin/inkscape"
inkscapePath3="/usr/bin/inkscape-bin"
inkscapePath4="/usr/local/bin/inkscape-bin"

inkscapePath=""

if [ -x "$inkscapePath1" ]; then
    inkscapePath="$inkscapePath1"
elif [ -x "$inkscapePath2" ]; then
    inkscapePath="$inkscapePath2"
elif [ -x "$inkscapePath3" ]; then
    inkscapePath="$inkscapePath3"
elif [ -x "$inkscapePath4" ]; then
    inkscapePath="$inkscapePath4"
else
    # Ask the user if they are using the AppImage
    read -p "Inkscape binary not found. Are you using an AppImage? (y/n): " appImageResponse
    if [ "$appImageResponse" == "y" ]; then
        read -p "Please enter the path to the Inkscape AppImage: " appImagePath
        if [ -x "$appImagePath" ]; then
            inkscapePath="$appImagePath"
        else
            echo "The AppImage file is not executable or does not exist. Aborting."
            exit 1
        fi
    else
        echo "Can't find Inkscape installation, aborting."
        exit 1
    fi
fi

validInput1="svg"
validInput2="pdf"
validInput3="eps"
validInput4="emf"
validInput5="wmf"
validInput6="sif"
validInput7="png"
validInput8="jpg"
validInput9="webp"

validOutput1="eps"
validOutput2="pdf"
validOutput3="png"
validOutput4="svg"
validOutput5="sif"
validOutput6="jpg"
validOutput7="webp"

inkscapeVersion="$("$inkscapePath" --version)"
inkscapeMajorVersion="${inkscapeVersion:9:1}"

echo ""
echo "This script allows you to convert all files in $inputDirectory from one file type to another"
echo "Running with $inkscapeVersion"
echo "(type q to quit at any question)"
echo ""

echo "Allowed file types for source: $validInput1, $validInput2, $validInput3, $validInput4, $validInput5, $validInput6, $validInput7, $validInput8, $validInput9"

while true; do
    read -p "What file type do you want to use as a source? " sourceType
    if [[ "$sourceType" == "q" ]]; then
        exit 0
    fi
    if [[ "$sourceType" == "$validInput1" || "$sourceType" == "$validInput2" || "$sourceType" == "$validInput3" || "$sourceType" == "$validInput4" || "$sourceType" == "$validInput5" || "$sourceType" == "$validInput6" || "$sourceType" == "$validInput7" || "$sourceType" == "$validInput8" || "$sourceType" == "$validInput9" ]]; then
        break
    else
        echo "Invalid input! Please use one of the following: $validInput1, $validInput2, $validInput3, $validInput4, $validInput5, $validInput6, $validInput7, $validInput8, $validInput9"
    fi
done

echo ""
echo "Allowed file types for output: $validOutput1, $validOutput2, $validOutput3, $validOutput4, $validOutput5, $validOutput6, $validOutput7"

while true; do
    read -p "What file type do you want to convert to? " outputType
    if [[ "$outputType" == "q" ]]; then
        exit 0
    fi
    if [[ "$outputType" == "$validOutput1" || "$outputType" == "$validOutput2" || "$outputType" == "$validOutput3" || "$outputType" == "$validOutput4" || "$outputType" == "$validOutput5" || "$outputType" == "$validOutput6" || "$outputType" == "$validOutput7" ]]; then
        break
    else
        echo "Invalid input! Please use one of the following: $validOutput1, $validOutput2, $validOutput3, $validOutput4, $validOutput5, $validOutput6, $validOutput7"
    fi
done

if [[ "$outputType" == "$sourceType" ]]; then
    echo "Input and Output are the same, no point in doing anything. Exiting..."
    exit 0
fi

echo ""

# Create the output directory if it doesn't exist
mkdir -p "$outputDirectory"

total=$(find "$inputDirectory" -maxdepth 1 -type f -name "*.$sourceType" | wc -l)
echo "Conversion started. Will do $total file(s)."
echo ""

count=0

for file in "$inputDirectory"/*."$sourceType"; do
    ((count++))
    echo "$file -> $outputDirectory/$(basename "$file" ".$sourceType").$outputType [$count/$total]"
    "$inkscapePath" --export-type="$outputType" --export-dpi=300 --batch-process "$file" --export-filename="$outputDirectory/$(basename "$file" ".$sourceType").$outputType"
done

echo ""
echo "$count file(s) converted from $sourceType to $outputType! (Saved in $outputDirectory)"
echo "Using Inkscape binary: $inkscapePath"
echo ""
