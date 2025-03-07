# Generate data for Galleria from a set of image folders in the current directory
import os
import re
import json
import shutil
from pathlib import Path
from collections import defaultdict

# Read our settings from the global config file
config_file = "galleria.cfg"
json_convert = {}
with open(config_file, "r") as file:
    for line in file:
        if "defaultExtension" in line:
            match = re.search(r'defaultExtension:\s*\"(.+)\"', line)
            default_ext = match.group(1)
        if "knownExtensions" in line:
            match = re.search(r'knownExtensions:\s*\[(.+)\]', line)
            content = match.group(1)
            extensions = re.findall(r'"([^"]+)"|\'([^\']+)\'', content)
            extensions = [ext[0] or ext[1] for ext in extensions]
        if "ignoreDirectories" in line:
            match = re.search(r'ignoreDirectories:\s*\[(.+)\]', line)
            content = match.group(1)
            ignored_dirs = re.findall(r'"([^"]+)"|\'([^\']+)\'', content)
            ignored_dirs = [dir[0] or dir[1] for dir in ignored_dirs]
        if "jsonFile" in line:
            match = re.search(r'jsonFile:\s*\"(.+)\"', line)
            json_file = match.group(1)
        if "jsonConvert" in line:
            match = re.search(r'jsonConvert:\s*\{(.+)\}', line)
            if match:
                content = match.group(1)
                pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', content)
                for key, value in pairs:
                    json_convert[key] = value

print("const galleries = {")

# Get all directories in the current directory
directories = [d for d in Path(".").iterdir() if d.is_dir()]

# Ensure that files and directories are listed in natural order
natural_order = lambda s: [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s.name)]

for directory in sorted(directories, key = natural_order):

    if directory.name in ignored_dirs:
        continue;

    # Check if we have a 'galleria.html+.js' in which case we create a sub-gallery
    sub_gallery = (
        os.path.isfile(os.path.join(directory, "galleria.html")) and
        os.path.isfile(os.path.join(directory, "galleria.js"))
    )

    if sub_gallery:
        files = []
        subdirs = [d for d in Path(directory).iterdir() if d.is_dir()]
        for subdir in sorted(subdirs, key = natural_order):
            files += sorted(
                [f for f in subdir.iterdir() if f.suffix.lower() in extensions],
                key = natural_order
            )
    else:
        files = sorted(
            [f for f in directory.iterdir() if f.suffix.lower() in extensions],
            key = natural_order
        )

    # Skip directories without images
    if not files:
        continue

    # Check if we have JSON data and read values from it if so
    json_insert = {}
    data_file = os.path.join(directory, json_file)
    if (os.path.isfile(data_file)):
        with open(data_file) as f:
            jdata = json.load(f)
            for key in json_convert:
                if key in jdata:
                    json_insert[json_convert[key]] = jdata[key]

    # Guess pattern from the first file
    first_file = files[0].stem
    extension = files[0].suffix
    prefix = ''.join([c for c in first_file if not c.isdigit()])
    remainder = first_file[len(prefix):]

    print(f'  "{directory.name}": {{')
    print(f'    images: {len(files)},')

    # Output the processed JSON data
    for key in json_insert:
        print(f'    {key}: {json.dumps(json_insert[key], ensure_ascii = False)},')

    # Create the sub-gallery data if needed
    if sub_gallery:
        gallery_cover = os.path.join(directory, "galleria" + extension)
        if not os.path.isfile(gallery_cover):
            shutil.copyfile(files[0], gallery_cover)
        print(f'    imageList: [ "galleria{extension}" ],')
        print('  },')
        continue

    no_pattern = False
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
        gallery_default_ext = max(ext_count, key = ext_count.get)

        # Handle numeric sequences, skipped files, and extras
        padding = len(remainder)
        skipped_files = []
        extra_files = {}
        seq = int(remainder) + 1
        prev_seqname = ""
        for i, file in enumerate(files[1:], start = 1):
            basename = file.stem
            if re.search(r'\d+$', basename) is None:
                extra_files[i] = file.name
                continue

            seqname = f"{prefix}{seq:0{padding}}"
            num_skipped = 0

            # We might have something like '5.jpg' and '5.png' in the same directory
            if prev_seqname and seqname != basename and prev_seqname == basename:
                extra_files[i] = file.name
                continue;

            while seqname != basename:
                skipped_files.append(f"{seqname}{gallery_default_ext}")
                seq += 1
                seqname = f"{prefix}{seq:0{padding}}"
                num_skipped += 1
                if num_skipped > 10:
                    no_pattern = True
                    break

            prev_seqname = seqname
            seq += 1

        # If we couldn't devise a pattern, just ouptut all the files as a list
        if no_pattern:
            # Output all files as a list
            file_list = ", ".join(f'"{f.name}"' for f in files)
            print(f'    imageList: [ {file_list} ],')
            print('  },')
            continue;

        # Output gallery-specific settings
        if gallery_default_ext != default_ext:
            print(f'    defaultExtension: "{gallery_default_ext}",')

        if prefix:
            print(f'    imagePrefix: "{prefix}",')

        if padding != 1:
            padded_number = str(1).zfill(padding)
            print(f'    numberPadding: "{padded_number}",')

        if int(remainder.lstrip("0") or "0") != 1:
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

    print('  },')

print('}')
