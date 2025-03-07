# Generate data for Galleria from a set of image folders in the current directory

# Read our settings from the global config file
$config_file = "galleria.cfg"
Get-Content $config_file | ForEach-Object {
  if ($_ -match 'defaultExtension:\s*\"(.+)\"') {
    $default_ext = $Matches[1]
  } elseif ($_ -match 'knownExtensions:\s*\[(.+)\]') {
    $content = $Matches[1]
    $extensions = ($content -split ',') -replace '["\s]', ''
  } elseif ($_ -match 'ignoreDirectories:\s*\[(.+)\]') {
    $content = $Matches[1]
    $ignored_dirs = ($content -split ',') -replace '["]', ''
    $ignored_dirs = $ignored_dirs | ForEach-Object -MemberName Trim
  } elseif ($_ -match 'jsonFile:\s*\"(.+)\"') {
    $json_file = $Matches[1]
  } elseif ($_ -match 'jsonConvert:\s*\{(.+)\}') {
    $content = $Matches[1]
    $json_convert = @{}
    $content -split ',' | ForEach-Object {
      if ($_ -match '"([^"]+)":\s*"([^"]+)"') {
        $key = $Matches[1]
        $value = $Matches[2]
        $json_convert[$key] = $value
      }
    }
  }
}

# Get directories in the current folder
$directories = Get-ChildItem -Directory | Sort-Object Name

foreach ($dir in $directories) {
  if ($ignored_dirs -contains $dir) {
    continue;
  }

  $no_pattern = $false
  # Check if we have a 'galleria.html+.js' in which case we create a sub-gallery
  $sub_gallery = (Get-ChildItem $dir -File -Filter "galleria.html") -and (Get-ChildItem $dir -File -Filter "galleria.js")

  # Unlike Linux, Windows doesn't have natural order sorting so we have to regexp it
  $ToNaturalOrder = { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) }
  if ($sub_gallery) {
    $files = Get-ChildItem "$dir\*\*" -File | Where-Object { $extensions -contains $_.Extension.ToLower() } | Sort-Object $ToNaturalOrder
  } else {
    $files = Get-ChildItem $dir -File | Where-Object { $extensions -contains $_.Extension.ToLower() } | Sort-Object $ToNaturalOrder
  }

  # Skip folders without images
  if ($files.Count -eq 0) {
    continue
  }

  # Check if we have JSON data and read values from it if so
  $json_insert = @{}
  if (Get-ChildItem -Path $dir $json_file) {
    $json = Get-Content -Path (Join-Path $dir $json_file) -Raw | ConvertFrom-Json
    foreach ($k in $json_convert.keys) {
      if ($json."$k") {
        $json_insert[$json_convert[$k]] = $json."$k"
      }
    }
  }

  # Try to guess the pattern from the first file listed
  $first_file = $files[0].BaseName
  $extension = $files[0].Extension
  $prefix = $first_file -replace "\d", ""
  $remainder = $first_file.Substring($prefix.Length)

  # Add the gallery header
  Write-Output "  `"$($dir.Name)`": {"
  Write-Output "    images: $($files.Count),"

  # Output the processed JSON data
  foreach ($k in $json_insert.keys) {
    $v = $json_insert[$k] | ConvertTo-Json -Compress
    Write-Output "    $k`: $v,"
  }

  # Create the sub-gallery data if needed
  if ($sub_gallery) {
    $gallery_cover = Join-Path -Path $dir -ChildPath ("galleria" + $extension)
    if (!(Test-Path -Path $gallery_cover)) {
      Copy-Item $files[0] -Destination $gallery_cover
    }
    Write-Output "    imageList = [ `"galleria$extension`" ],"
    Write-Output "  },"
    continue
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
    $prev_seqname = ""
    for ($i = 1; ($i -lt $files.Count) -and ($no_pattern -eq $false); $i++) {
      $basename = $files[$i].BaseName
      if (-not ($basename -match "\d$")) {
        $extra_files[$i] = $files[$i].Name
        continue
      }
      $seqname = "{0}{1:D$padding}" -f $prefix, $seq
      $num_skipped = 0
      if ($prev_seqname -and $seqname -ne $basename -and $prev_seqname -eq $basename) {
        $extra_files[$i] = $files[$i].Name
        continue
      }
      while ($seqname -ne $basename) {
        $skipped_files += "$seqname$gallery_default_ext"
        $seq++
        $seqname = "{0}{1:D$padding}" -f $prefix, $seq

        if (++$num_skipped -gt 10) {
          $no_pattern = $true
          break
        }
      }
      $prev_seqname = $seqname
      $seq++
    }

    # If we couldn't devise a pattern, just ouptut all the files as a list
    if ($no_pattern) {
      $imageList = $files | ForEach-Object { "`"$_`"" }
      Write-Output "    imageList: [ $($imageList -join ', ') ],"
      Write-Output "  },"
      $no_pattern = $false
      continue
    }

    # Output gallery-specific settings
    if ($gallery_default_ext -ne $default_ext) {
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
