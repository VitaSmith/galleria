# Generate data for Galleria from a set of image folders in the current directory
import os
import re
import json
from pathlib import Path
from collections import defaultdict

# Default settings
default_ext = ".jpg"
extensions = [".bmp", ".gif", ".jpeg", ".jpg", ".png", ".tga", ".tif", ".svg", ".webp"]

# If you have JSON data in your image folder, you can insert some of its values into
# your 'galleria.js'. For instance, if you have 'title' defined as a JSON value, the
# following will insert it as 'altName' so that Galleria sets it as the gallery name.
# Alternatively, you can also insert the JSON data as is, such as 'artist' or 'tags'.
data_json = "data.json"
json_convert = {
  "title": "altName",
  "artist": "artist",
  "type": "type",
  "tags": "tags",
  "comments": "comments",
}

print("const galleries = {")

# Get all directories in the current directory
directories = [d for d in Path(".").iterdir() if d.is_dir()]

# Ensure that files and directories are listed in natural order
natural_order = lambda s: [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s.name)]

for directory in sorted(directories, key=natural_order):
    files = sorted(
        [f for f in directory.iterdir() if f.suffix in extensions],
        key=natural_order
    )

    # Skip directories without images
    if not files:
        continue

    # Check if we have JSON data and read values from it if so
    json_insert = {}
    data_file = os.path.join(directory, data_json)
    if (os.path.isfile(data_file)):
        with open(data_file) as f:
            jdata = json.load(f)
            for key in json_convert:
                if key in jdata:
                    json_insert[json_convert[key]] = jdata[key]

    # Guess pattern from the first file
    first_file = files[0].stem
    prefix = ''.join([c for c in first_file if not c.isdigit()])
    remainder = first_file[len(prefix):]

    print(f'  "{directory.name}": {{')
    print(f'    numImages: {len(files)},')

    # Output the processed JSON data
    for key in json_insert:
        print(f'    {key}: {json.dumps(json_insert[key])},')

    if not remainder or not first_file.startswith(prefix + remainder):
        # Output all files as a list
        file_list = ", ".join(f'"{f.name}"' for f in files)
        print(f'    imageList: [ {file_list} ],')
    else:
        # Count the number of files for each extension
        ext_count = defaultdict(int)
        for file in files:
            ext_count[file.suffix] += 1

        # Determine gallery's default extension
        gallery_default_ext = max(ext_count, key=ext_count.get)

        # Handle numeric sequences, skipped files, and extras
        padding = len(remainder)
        skipped_files = []
        extra_files = {}
        seq = int(remainder) + 1

        for i, file in enumerate(files[1:], start=1):
            basename = file.stem
            if re.search(r'\d+$', basename) is None:
                extra_files[i] = file.name
                continue

            seq_name = f"{prefix}{seq:0{padding}}"
            num_skipped = 0

            while seq_name != basename:
                skipped_files.append(f"{seq_name}{gallery_default_ext}")
                seq += 1
                seq_name = f"{prefix}{seq:0{padding}}"
                num_skipped += 1
                if num_skipped > 10:
                    print("    // FAILED TO PROCESS GALLERY")
                    break

            seq += 1

        # Output gallery-specific settings
        if gallery_default_ext != default_ext:
            print(f'    defaultExtension: "{gallery_default_ext}",')

        if prefix:
            print(f'    imagePrefix: "{prefix}",')

        if padding != 1:
            padded_number = str(1).zfill(padding)
            print(f'    numberPadding: "{padded_number}",')

        if int(remainder) != 1:
            print(f'    firstImage: "{files[0].name}",')

        if skipped_files:
            skipped_list = ", ".join(f'"{f}"' for f in skipped_files)
            print(f'    skipImage: [ {skipped_list} ],')

        if extra_files:
            extra_images = ", ".join(f'{i}: "{name}"' for i, name in extra_files.items())
            print(f'    insertImage: {{ {extra_images} }},')

        if ext_count[gallery_default_ext] != len(files):
            custom_ext_files = ", ".join(
                f'"{f.name}"' for f in files if f.suffix != gallery_default_ext
            )
            print(f'    customExtension: [ {custom_ext_files} ],')

    print("  },")

print("}")
