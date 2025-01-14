# Generate data for Galleria from a set of image folders in the current directory

# Default settings
$default_ext = ".jpg"
$extensions = @(".bmp", ".gif", ".jpeg", ".jpg", ".png", ".tga", ".tif", ".svg", ".webp")

# If you have JSON data in your image folder, you can insert some of its values into
# your 'galleria.js'. For instance, if you have 'title' defined as a JSON value, the
# following will insert it as 'altName' so that Galleria sets it as the gallery name.
# Alternatively, you can also insert the JSON data as is, such as 'artist' or 'tags'.
$data_json = "data.json"
$json_convert = @{
  "title" = "altName"
  "artist" = "artist"
  "type" = "type"
  "tags" = "tags"
  "comments" = "comments"
}

# Get directories in the current folder
$directories = Get-ChildItem -Directory | Sort-Object Name

foreach ($dir in $directories) {
  # Unlike Linux, Windows doesn't have natural order sorting so we have to regexp it
  $ToNaturalOrder = { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) }
  $files = Get-ChildItem $dir -File | Where-Object { $extensions -contains $_.Extension } | Sort-Object $ToNaturalOrder
  $skip_gallery = $false

  # Skip folders without images
  if ($files.Count -eq 0) {
    continue
  }

  # Check if we have JSON data and read values from it if so
  $json_insert = @{}
  if (Get-ChildItem -Path $dir $data_json) {
    $json = Get-Content -Path (Join-Path $dir $data_json) -Raw | ConvertFrom-Json
    foreach ($k in $json_convert.keys) {
      if ($json."$k") {
        $json_insert[$json_convert[$k]] = $json."$k"
      }
    }
  }

  # Try to guess the pattern from the first file listed
  $first_file = $files[0].BaseName
  $prefix = $first_file -replace "\d", ""
  $remainder = $first_file.Substring($prefix.Length)

  # Add the gallery header
  Write-Output "  `"$($dir.Name)`": {"
  Write-Output "    numImages: $($files.Count),"

  # Output the processed JSON data
  foreach ($k in $json_insert.keys) {
    $v = $json_insert[$k] | ConvertTo-Json -Compress
    Write-Output "    $k`: $v,"
  }

  if (-not $remainder -or ($prefix + $remainder) -ne $first_file) {
    # Output all files as a list
    $imageList = $files | ForEach-Object { "`"$_`"" }
    Write-Output "    imageList: [ $($imageList -join ', ') ],"
  } else {
    # Determine the gallery's default extension
    $ext_count = @{}
    foreach ($ext in $extensions) { $ext_count[$ext] = 0 }
    foreach ($file in $files) { $ext_count[$file.Extension]++ }
    $gallery_default_ext = $ext_count.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1 | ForEach-Object Key

    # Handle numeric sequences, skipped files, and extras
    $padding = $remainder.Length
    $seq = [int]$remainder + 1
    $skipped_files = @()
    $extra_files = @{}
    for ($i = 1; $i -lt $files.Count; $i++) {
      $basename = $files[$i].BaseName
      if (-not ($basename -match "\d$")) {
        $extra_files[$i] = $files[$i].Name
        continue
      }
      $seqname = "{0}{1:D$padding}" -f $prefix, $seq
      $num_skipped = 0
      while ($seqname -ne $basename) {
        $skipped_files += "$seqname$gallery_default_ext"
        $seq++
        $seqname = "{0}{1:D$padding}" -f $prefix, $seq

        if (++$num_skipped -gt 10) {
          Write-Output "    // FAILED TO PROCESS GALLERY"
          $skip_gallery = $true
          break
        }
      }
      $seq++
    }

    if ($skip_gallery) {
      continue
    }

    # Output gallery-specific settings
    if ($gallery_default_ext -ne $defaultExt) {
      Write-Output "    defaultExtension: `"$gallery_default_ext`","
    }
    if ($prefix) {
      Write-Output "    imagePrefix: `"$prefix`","
    }
    if ($padding -ne 1) {
      $padNumber = '1'.PadLeft($padding, '0')
      Write-Output "    numberPadding: `"$padNumber`","
    }
    if ($remainder -ne 1) {
      Write-Output "    firstImage: `"$($files[0].Name)`","
    }
    if ($skipped_files.Count -gt 0) {
      $skipImages = $skipped_files | ForEach-Object { "`"$_`"" }
      Write-Output "    skipImage: [ $($skipImages -join ', ') ],"
    }
    if ($extra_files.Count -gt 0) {
      $insertImages = $extra_files.GetEnumerator() | ForEach-Object { "$($_.Key): `"$($_.Value)`"" }
      Write-Output "    insertImage: { $($insertImages -join ', ') },"
    }
    if ($files.Where({ $_.Extension -ne $gallery_default_ext }).Count -gt 0) {
      $customExtensions = $files.Where({ $_.Extension -ne $gallery_default_ext }) | ForEach-Object { "`"$_`"" }
      Write-Output "    customExtension: [ $($customExtensions -join ', ') ],"
    }
  }

  # Add the gallery footer
  Write-Output "  },"
}

Write-Output "}"
