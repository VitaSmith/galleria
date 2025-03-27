#!/bin/env bash
# Generate data for galleria from a set of image folders in the current directory

# Read our settings from the global config file
config_file="galleria.cfg"
IFS='|'
default_ext=($(grep "defaultExtension" "$config_file" | sed -E 's/.*\"(\..+)\".*/\1/'))
extensions=($(grep "knownExtensions" "$config_file" | sed -E 's/.*\[ +([^]]+) +\].*/\1/' | tr -d '" ' | tr ',' '|'))
ignored_dirs=($(grep "ignoreDirectories" "$config_file" | sed -E 's/.*\[ +([^]]+) +\].*/\1/' | sed -E 's/, +/,/g' | tr -d '"' | tr ',' '|'))
json_file=($(grep "jsonFile" "$config_file" |  sed -E 's/.*\:.*\"(.+)\".*/\1/'))
declare -A json_convert
while IFS=',' read -ra pairs; do
  for pair in "${pairs[@]}"; do
    key=$(echo "$pair" | sed -E 's/.*"([^"]+)":.*/\1/')
    value=$(echo "$pair" | sed -E 's/.*: ?"([^"]+)".*/\1/')
    json_convert["$key"]="$value"
  done
done < <(grep "jsonConvert" "$config_file" | sed -E 's/.*\{(.*)\}.*/\1/' | tr -d ' ')

# May need to escape double quotes in gallery names
esc() {
  printf "%s" "$(LC_ALL=C sed 's/"/\\"/g' <<<"$1")"
}

# Ensure that spaces in folder names are handled properly
IFS='
'
echo "const galleries = {"

# Using -v ensures natural sorting of directories (i.e '11/' listed before '101/')
dirs=($(ls -vd */))
for dir in "${dirs[@]}"; do

  no_pattern=0
  sub_gallery=0
  ignore_dir=0
  dir=${dir::-1}
  for prefix in "${ignored_dirs[@]}"; do [[ "${dir}" == $prefix* ]] && ignore_dir=1 && break; done
  if (( $ignore_dir != 0 )); then
    continue
  fi
  cd "$dir"

  # Check if we have a 'galleria.html+.js' in which case we create a sub-gallery
  if [[ -f "galleria.html" && -f "galleria.js" ]]; then
    sub_gallery=1
  fi

  # Using a variable in an ls wildcard is a bit tricky...
  suffixes=""
  sep=""
  for ext in "${extensions[@]}"; do
    suffixes+="$sep"
    suffixes+="${ext:1}"
    sep=","
    # Manually add uppercase extension, as using 'shopt -s nocaseglob' has side effects
    suffixes+="$sep"
    suffixes+="${ext^^:1}"
  done
  if (( $sub_gallery != 0 )); then
    eval "files=(\$(ls -v */*.{${suffixes}} 2>/dev/null))"
  else
    eval "files=(\$(ls -v *.{${suffixes}} 2>/dev/null))"
  fi

  # Ignore folders with no images
  if [[ ${#files[@]} == 0 ]]; then
    cd ..
    continue
  fi

  # Check if we have JSON data and read values from it if so
  unset json_insert
  declare -A json_insert
  if [[ -f "$json_file" && -x "$(command -v jq)" ]]; then
    for k in "${!json_convert[@]}"; do
      v=$(jq -cr ".$k" "$json_file")
      if [[ "$v" != "null" ]]; then
        json_insert["${json_convert[$k]}"]="$v"
      fi
    done
  fi

  # Try to guess the pattern from the first file listed
  first_file=${files[0]}
  # Get the extension
  extension="${first_file##*.}"
  # Remove extension
  first_file="${first_file%.*}"
  # Check for a prefix
  prefix=$(echo $first_file | sed 's/[0-9]\+$//')
  # Remove the prefix, if any
  rem=${first_file:${#prefix}}

  # Add the gallery header
  echo "  \"$(esc "$dir")\": {"
  echo "    images: ${#files[@]},"

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

  # Create the sub-gallery data if needed
  if (( $sub_gallery != 0 )); then
    gallery_cover="galleria.${extension}"
    if [[ ! -f "${gallery_cover}" ]]; then
      cp "${files[0]}" "${gallery_cover}"
    fi
    echo "    imageList: [ \"${gallery_cover}\" ],"
    echo "  },"
    cd ..
    continue
  fi

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
    prev_seqname=""
    for ((i = 1 ; i < ${#files[@]} && no_pattern == 0; i++ )); do
      basename=${files[$i]}
      basename="${basename%.*}"
      # Check that our basename ends with a number
      if ! [[ "$basename" =~ .*[0-9]+$ ]]; then
        extra_files[$i]="${files[$i]}"
        continue;
      fi
      printf -v seqname "${prefix}%0${padding}g" $seq
      num_skipped=0
      # We might have something like '5.jpg' and '5.png' in the same directory
      if [[ x"$prev_seqname" != x"" && "$seqname" != "$basename" && "$prev_seqname" == "$basename" ]]; then
        extra_files[$i]="${files[$i]}"
        continue;
      fi
      while [[ "$seqname" != "$basename" ]]; do
        skipped_files+=("${seqname}${gallery_default_ext}")
        seq=$((seq + 1))
        printf -v seqname "${prefix}%0${padding}g" $seq
        num_skipped=$((num_skipped + 1))
        if (( num_skipped > 10 )); then
          no_pattern=1
          break;
        fi
      done
      prev_seqname=$seqname
      seq=$((seq + 1))
    done

    # If we couldn't devise a pattern, just ouptut all the files as a list
    if (( no_pattern != 0 )); then
      echo -n "    imageList: [ "
      for file in "${files[@]}"; do
        echo -n "\"${file}\", "
      done
      echo "],"
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
    # Force base 10 to ensure bash doesn't attempt a stupid octal conversion
    if (( $((10#$rem)) != 1 )); then
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
