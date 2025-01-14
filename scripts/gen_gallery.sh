#!/bin/env bash

# Generate 2000 sequential SVG images in "Gallery G/"
mkdir -p "Gallery G"
for i in {1..2000}; do
cat <<EOF > "Gallery G/$i.svg"
<svg xmlns="http://www.w3.org/2000/svg" width="1000px" height="1500px" viewBox="0 0 1000 1500">
  <rect x="0" y="0" width="100%" height="100%" fill="white" />
  <text x="500" y="750" font-size="10em" text-anchor="middle" fill="black" transform-origin="center" transform="rotate(-45)">Image $i</text>
</svg>
EOF
done