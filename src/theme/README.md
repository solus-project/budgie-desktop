#### Editing the images in the `assets` folder

* Open the `assets.svg` file in inkscape. Each object in the .svg file corresponds to an image in the `assets` folder.

* Find the object you want to edit and make your changes. Important: Don't change the obejct id.

* Save `assets.svg` and delete the images corresponding to the edited .svg objects from the `assets` folder (or just delete everything in the `assets` folder).

* Execute `render-assets.sh` (the script needs inkscape and optipng) to render the png assets.

