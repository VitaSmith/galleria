Galleria - A self-contained HTML5 local gallery viewer
======================================================

## Description

Galleria is a no-dependencies HTML5 gallery viewer that can be used locally, with any modern
browser, to browse a set of galleries, such as a set of photo albums, mangas, etc.

It is designed for the express purpose of being lightweight, self-contained, and easily
configurable through the edition of a simple local `data.js` file.

Considering that every modern browser already has everything required, natively, to provide
great gallery visualization, our design aims at giving you what actually matters (the actual
image data, in all its glory) without any unnecessary, and oft unwanted, distractions.

## Features

- Works with any recent browser (Firefox, Edge, Chrome).
- **No** external dependencies (no downloading of external javascript or whatnot).
  Galleria simply works, with all of its features, even if your internet is disconnected.
- Lightweight.
- Customizable.

## Usage

Assuming that you have a set of individual folders containing a sequential series of image,
such as `Gallery A/`, `Gallery B/` etc in the same directory as the `index.html` and
`data.js` files from this repository, you first should edit the `const galleries` section of
the `data.js` file according to the content of each folder.

Once that is done, simply open `index.html` which will display the global gallery view in
which a cover page/cover image from each gallery is displayed as a thumbnail, that can be
clicked to bring you to the first image for that gallery.

You can then click on the right part of that image to view the next image, or on the left
part to go back. Note that going back on the first image or forward on the last image will
brings you back to the global gallery view. Or you can just press <kbd>Esc</kbd> to do so.

In individual image viewing mode, you can also press the <kbd>F</kbd> key to toggle "fit to
page" vs "original size" or you can press <kbd>SPACE</kbd> to display the current gallery as
a list of clickable thumbnails.

## Notes

- The example galleries provided with this project are mostly `.svg` files due to size
  considerations. But of course, any image type supported by your browser is also supported
  by Galleria.
