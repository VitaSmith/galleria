/* Galleria - settings and data file */

const settings = {
  // Set to true if you want large images to be zoomed out to fit the browser window.
  // Set to false otherwise. Can also be toggled when viewing images with the <F> key.
  fitToPage: true,
  // Default image extension (can be overridden on a gallery by gallery basis).
  defaultExtension: ".svg",
  // Maximum default dimensions for thumbnails.
  thumbnailMaxWidth: "400px",
  thumbnailMaxHeight: "400px",
  // Default backgroung color
  defaultBackgroundColor: "black",
  // Default text color
  defaultTextColor: "white",
};

const galleries = {
  "Gallery A": {
    // Sequential gallery of 10 images starting at '1.svg' and ending at '10.svg'.
    numImages: 10,
  },
  "Gallery B": {
    alt: "Some alternate gallery name",
    numImages: 5,
  },
  "Gallery C": {
    numImages: 10,
  },
  "Gallery D": {
    // If your images have random nonsequential names, you can provide them in an imageList.
    // Note that imageList takes precedence over all other image naming options.
    imageList: [ "random.svg", "set.svg", "of.svg", "image.svg", "files.svg" ],
  },
  "Gallery E": {
    numImages: 10,
  },
  "Gallery F": {
    // Default image extension for this specific gallery (overrides the one from settings).
    defaultExtension: ".jpg",
    // If some images don't use the default extension, list them in customExtension.
    customExtension: [ "1.png", "4.jpeg" ],
    numImages: 5,
  },
};
