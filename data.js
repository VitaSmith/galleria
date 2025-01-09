/* Galleria - Settings and data file */

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
  defaultTextColor: "lightgrey",
  // Defauilt font family and style
  defaultFont: "Tahoma",
  defaultFontStyle: "italic",
};

const galleries = {
  "Gallery A": {
    // Sequential gallery of 10 images starting at '1.svg' and ending at '10.svg'.
    numImages: 10,
  },
  "Gallery B": {
    // Sequential gallery of 6 images starting at '0.svg' and ending at '5.svg'.
    numImages: 6,
    firstImage: "0.svg",
    // Alternate display name for the gallery
    altName: "Some super, long-ass, mega long, but really rea-hee-hee-heally long alternate gallery name that could probably be even longer",
  },
  "Gallery C": {
    // Sequential set of 10 images starting at 'DSFC0123.svg' and ending at 'DSFC0134.svg',
    // with images 'DSFC0125.svg' and 'DSFC0130.svg' skipped.
    numImages: 10,
    imagePrefix: "DSFC",
    numberPadding: "0001",
    firstImage: "DSFC0123.svg",
    skipImage: [ "DSFC0125.svg", "DSFC0130.svg" ],
  },
  "Gallery D": {
    // If your images have random nonsequential names, you can provide them in an imageList.
    // Note that imageList takes precedence over all other image naming options.
    imageList: [ "random.svg", "set.svg", "of.svg", "image.svg", "files.svg" ],
    altName: "How long can this gallery label be I don't know you tell me okay that should do",
  },
  "Gallery E": {
    // Sequential gallery of 13 images starting at '1.svg' and ending at '10.svg' with extra
    // images that don't follow the sequential scheme added at position 0 (first image), 3
    // and 12 (last image)
    numImages: 13,
    insertImage: { 0: "first.svg", 3: "extra.svg", 12: "last.svg" },
  },
  "Gallery F": {
    numImages: 5,
    numberPadding: "001",
    // Default image extension for this specific gallery (overrides the one from settings).
    defaultExtension: ".jpg",
    // If some images follow the sequential scheme but don't use the default extension, list
    // them in customExtension.
    customExtension: [ "001.png", "004.jpeg" ],
  },
  // Uncomment this after running 'gen_gallery.sh', to test a very large set of images.
  // "Gallery G": { numImages: 2000 },
};
