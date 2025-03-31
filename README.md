# Galleria

A self-contained HTML5 local gallery viewer.

- [Galleria](#galleria)
  - [Description](#description)
  - [Features](#features)
  - [Usage](#usage)
    - [Navigation and keybindings](#navigation-and-keybindings)
    - [Data file generation](#data-file-generation)
    - [Examples](#examples)

## Description

Galleria is a no-dependencies HTML5 gallery viewer that can be used with any modern browser,
to browse a set of local galleries, such as photo albums, comics/mangas, etc.

It is designed for the express purpose of being lightweight, self-contained, and easily
configurable, through the editing of a local set of `galleria.js` and `galleria.cfg` files
containing the gallery data and the global configuration respectively.

Considering that every modern browser already has everything required, natively, to provide
great gallery visualization, our design aims at giving you what actually matters (the actual
image data, in all its glory) without the unnecessary, and often unwanted, distractions.

## Features

- Works with any recent browser (Firefox, Edge, Chrome, Safari, Opera).
- **No** requirement for a webserver, even a local one. Just use your browser and go!
- **No** external dependencies (no downloading/querying of external javascript and whatnot).
  Galleria simply works, with all of its features, even if your internet is disconnected.
- Lightweight.
- Highly customizable.
- Can process existing JSON metadata.
- Can handle recursive galleries of galleries.
- With ready-to-use scripts (bash, PowerShell, Python) for automated gallery generation.

## Usage

Download the `galleria.*` files from this repository and copy them to the folder where
you have a set of subfolders containing image sets of photos, comics/mangas, etc.

Then either edit `galleria.js` and `galleria.cfg` manually, according to the layout of your
image sets. Or, use one of the Bash/PowerShell/Python scripts provided, to do that for you.

Once that is done, open `galleria.html` in your browser to navigate/view the galleries.

### Navigation and keybindings

All thumbnail images are clickable and, when clicked, will show the corresponding image in
the browser. You can then click on the right part of that image to navigate to the next
image, or on the left part to go back.

Alternatively, you can use the direction arrows <kbd>←</kbd> and <kbd>→</kbd> keys to go
forward/backward, as well as the <kbd>PageUp</kbd> and <kbd>PageDown</kbd> keys.

Going back on the first image or forward on the last image will bring you back to the global
gallery view. Or you can also just press <kbd>Esc</kbd> at any time to do so.

The <kbd>Home</kbd> and <kbd>End</kbd> keys can also be used to navigate directly to the
first or last image/page.

Pressing <kbd>SPACE</kbd> when viewing an image displays the current gallery as a list of
clickable thumbnails.

Pressing <kbd>F</kbd> when viewing an image toggles between "fit to screen" and actual size.

### Data file generation

Obviously, a local gallery visualizer is only as good as the utilities that can automate the
generation of the gallery data (in our case, that would be the generation of `galleria.js`),
so we are providing not one, not two, but **three** scripts (bash, PowerShell and python)
that can help you do just that on Windows, Linux, MacOS or any other Operating System.

Each script is designed to output the gallery data on the commandline, while automatically
handling prefixing, number padding, missing or added images, default/additional extensions
and so on.

Furthermore, the scripts are also designed to process an optional JSON data file, if one
exists in an individual folder, to further customize the `galleria.js` data for that folder.

For instance, if you have something like `"title": "An alternate title for your gallery"` in
a `data.json` file in a folder, and also defined the relevant options in `galleria.cfg`, you
can have the scripts use that data to set the label for that gallery in Galleria. Or you can
add extra properties like `tags`, `artist` or `comments`, and then customize the HTML to
reference or filter/search from these attributes.

What this means is that, as long as your images don't use a crazy ordering scheme, and you
have attributes that can be parsed, you shouldn't have to do any work at all adding a whole
set of galleries to Galleria, where your existing metadata can be used and referenced.

### Examples

The following assumes that you have `defaultExtension: ".jpg"` in `galleria.js`.

- Add a gallery, labelled `Gallery A` using the sequence of images `./Gallery A/1.jpg` to
`./Gallery A/10.jpg`.

```js
  "Gallery A": {
    images: 10,
  },
```

- Add a gallery, labelled `Some alternate gallery name` using the sequence of images
  `./Gallery B/0.jpg` to `./Gallery B/5.jpg`.

```js
  "Gallery B": {
    images: 6,
    firstImage: "0.jpg",
    altName: "Some alternate gallery name",
  },
```

- Add a gallery, labelled `Gallery C` using the sequence of images `./Gallery C/DSFC0123.jpg`
  to `./Gallery C/DSFC0134.jpg` with images `DSFC0125.jpg` and `DSFC0130.jpg` skipped.

```js
  "Gallery C": {
    images: 10,
    imagePrefix: "DSFC",
    numberPadding: "0001",
    firstImage: "DSFC0123.jpg",
    skipImage: [ "DSFC0125.jpg", "DSFC0130.jpg" ],
  },
```

- Add a gallery, labelled `Gallery D` using the sequence of images `./Gallery D/random.png`,
  `./Gallery D/set.png`, `./Gallery D/of.png`, `./Gallery D/image.png`,
  `./Gallery D/files.png`.

```js
  "Gallery D": {
    imageList: [ "random.png", "set.png", "of.png", "image.png", "files.png" ],
  },
```

- Add a gallery, labelled `Gallery E` using the sequence of images `first.jpg`, `1.jpg`,
  `2.jpg`, `extra.jpg`, `3.jpg`, `4.jpg`, `last.jpg`.

```js
  "Gallery E": {
    images: 7,
    insertImage: { 0: "first.jpg", 3: "extra.jpg", 6: "last.jpg" },
  },
```

- Add a gallery, labelled `Gallery F` using the sequence of images `001.webp`, `002.png`,
  `003.png`, `004.gif`, `005.png`.

```js
  "Gallery F": {
    images: 5,
    numberPadding: "001",
    defaultExtension: ".png",
    customExtension: [ "001.webp", "004.gif" ],
  },
```

For more details, see the default `galleria.js` and `galleria.cfg` from this repository,
along with the sample galleries provided. You can also try to run any of the scripts against
the default galleries, where you will see that, outside of elements that are impossible to
guess (such as where extra images should be inserted, or what order should a list of
unnumbered images be, if not alpahetical), the scripts are smart enough to automatically
generate the gallery layouts above, just by looking at the content of the folders.
