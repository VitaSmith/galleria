#!/bin/env bash
# Generate data for galleria from a set of image folders in the current directory

# Default settings
default_ext=".jpg"
extensions=(".bmp" ".gif" ".jpeg" ".jpg" ".png" ".tga" ".tif" ".svg" ".webp")

# If you have JSON data in your image folder, you can insert some of its values into
# your 'galleria.js'. For instance, if you have 'title' defined as a JSON value, the
# following will insert it as 'altName' so that Galleria sets it as the gallery name.
# Alternatively, you can also insert the JSON data as is, such as 'artist' or 'tags'.
# Note that this require the 'jq' command to be available on your platform.
data_json="data.json"
declare -A json_convert=(
  ["title"]="altName"
  ["artist"]="artist"
  ["type"]="type"
  ["tags"]="tags"
  ["comments"]="comments"
)

# You should not have to change anything below this
cat << EOF
/* Galleria - Settings and data file */

const settings = {
  // Set to true if you want large images to be zoomed out to fit the browser window.
  // Set to false otherwise. Can also be toggled when viewing images with the <F> key.
  fitToPage: true,
  // Default image extension (can be overridden on a gallery by gallery basis).
  defaultExtension: "${default_ext}",
  // Maximum default dimensions for thumbnails.
  thumbnailMaxWidth: "400px",
  thumbnailMaxHeight: "400px",
  // Default backgroung color
  defaultBackgroundColor: "black",
  // Default text color
  defaultTextColor: "lightgrey",
  // Defauilt font family and style
  defaultFont: "Tahoma",
  defaultFontStyle: "italic",
};

EOF

# Ensure that spaces in folder names are handled properly
IFS='
'

echo "const galleries = {"

# Using -v ensures natural sorting of directories (i.e '11/' listed before '101/')
dirs=($(ls -vd */))
for dir in "${dirs[@]}"; do

  skip_gallery=0
  dir=${dir::-1}
  cd "$dir"

  # Using a variable in an ls wildcard is a bit tricky...
  suffixes=""
  sep=""
  for ext in "${extensions[@]}"; do
    suffixes+="$sep"
    suffixes+="${ext:1}"
    sep=","
  done
  eval "files=(\$(ls -v *.{${suffixes}} 2>/dev/null))"

  # Ignore folders with no images
  if [[ ${#files[@]} == 0 ]]; then
    cd ..
    continue
  fi

  # Check if we have JSON data and read values from it if so
  unset json_insert
  declare -A json_insert
  if [[ -f "$data_json" && -x "$(command -v jq)" ]]; then
    for k in "${!json_convert[@]}"; do
      v=$(jq -cr ".$k" "$data_json")
      if [[ "$v" != "null" ]]; then
        json_insert["${json_convert[$k]}"]="$v"
      fi
    done
  fi

  # Try to guess the pattern from the first file listed
  first_file=${files[0]}
  # Remove extension
  first_file="${first_file%.*}"
  # Check for a prefix
  prefix=$(echo $first_file | tr -d '[:digit:]')
  # Remove the prefix, if any
  rem=${first_file:${#prefix}}

  # Add the gallery header
  echo "  \"${dir}\": {"
  echo "    numImages: ${#files[@]},"

  # Output the processed JSON data
  for k in "${!json_insert[@]}"; do
    v="${json_insert[$k]}"
    # Add double quotes as needed
    if [[ ${v:0:1} != '"' && ${v:0:1} != '[' && ${v:0:1} != '{' ]]; then
      echo "    $k: \"${json_insert[$k]}\","
    else
      echo "    $k: ${json_insert[$k]},"
    fi
  done

  if [[ -z "$rem" || "$prefix$rem" != "$first_file" ]]; then

    # Can't build a numeric sequence => just ouptut all the files as a list
    echo -n "    imageList: [ "
    for file in "${files[@]}"; do
      echo -n "\"${file}\", "
    done
    echo "],"

  else

    # Count the number of files for each extension
    declare -A ext_count
    for ext in "${extensions[@]}"; do
      ext_count[$ext]=0
      for file in "${files[@]}"; do
        if [[ "$file" == *"$ext" ]]; then
          ext_count[$ext]=$((ext_count[$ext] + 1))
        fi
      done
    done
    last_count=0
    gallery_default_ext=""
    for ext in "${extensions[@]}"; do
      if (( ${ext_count[$ext]} > $last_count )); then
        gallery_default_ext=$ext
        last_count=${ext_count[$ext]}
      fi
    done

    # Find if we have missing or extra images in the sequence and store them into arrays
    padding=${#rem}
    unset extra_files
    declare -A extra_files
    skipped_files=()
    seq=$((10#$rem + 1))
    for ((i = 1 ; i < ${#files[@]} ; i++ )); do
      basename=${files[$i]}
      basename="${basename%.*}"
      # Check that our basename ends with a number
      if ! [[ "$basename" =~ .*[0-9]+$ ]]; then
        extra_files[$i]="${files[$i]}"
        continue;
      fi
      printf -v seqname "${prefix}%0${padding}g" $seq
      num_skipped=0
      while [[ "$seqname" != "$basename" ]]; do
        skipped_files+=("${seqname}${gallery_default_ext}")
        seq=$((seq + 1))
        printf -v seqname "${prefix}%0${padding}g" $seq
        num_skipped=$((num_skipped + 1))
        if (( num_skipped > 10 )); then
          skip_gallery=1
          break;
        fi
      done
      seq=$((seq + 1))
    done

    # Check for error condition
    if (( skip_gallery != 0 )); then
      echo "    // FAILED TO PROCESS GALLERY"
      echo "  },"
      cd ..
      continue;
    fi

    # Set the gallery default extension, if different from global one
    if [[ "$gallery_default_ext" != "$default_ext" ]]; then
      echo "    defaultExtension: \"$gallery_default_ext\","
    fi

    # Set the image prefix, if any
    if [[ ! -z "$prefix" ]]; then
      echo "    imagePrefix: \"${prefix}\","
    fi

    # Set the number padding, if any
    if (( ${#rem} != 1 )); then
      echo "    numberPadding: \"$rem\","
    fi

    # Set the first image, if needed
    if (( $((rem)) != 1 )); then
      echo "    firstImage: \"${files[0]}\","
    fi

    # Declare the files to skip in the sequence
    if (( ${#skipped_files[@]} != 0 )); then
      echo -n "    skipImage: [ "
      for file in "${skipped_files[@]}"; do
        echo -n "\"${file}\", "
      done
      echo "],"
    fi

    # Declare the files to add to the sequence
    if (( ${#extra_files[@]} != 0 )); then
      echo -n "    insertImage: { "
      for i in "${!extra_files[@]}"; do
        echo -n "$i: \"${extra_files[$i]}\", "
      done
      echo "},"
    fi

    # Add the files with different base extension if needed
    if (( ${ext_count[$gallery_default_ext]} != ${#files[@]} )); then
      echo -n "    customExtension: [ "
      for file in "${files[@]}"; do
        if [[ "$file" != *"$gallery_default_ext" ]]; then
          echo -n "\"$file\", "
        fi
      done
      echo "],"
    fi

  fi

  # Add the gallery footer
  echo "  },"
  cd ..

done

echo "}"
