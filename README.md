# vim-doxygen
Out of the box, this plugin automatically creates a doxyfile for your project, and regenerates the Doxygen documentation on save. It also has keybindings to open the Doxygen documentation quickly when you are coding. All this behaviors can be customized. This project is functional already, but under heavy development. If you find some bug that is not listed below, please submit an issue or PR and I will look into it.

## Documentation
Please use <:h doxygen> on vim to read the full documentation.

## How to use

Enable automated doxyfile generation
   
``` 
" Create a default doxigen config for the current project (ENABLED BY DEFAULT)
g:doxygen_auto_setup = 1

" OPTIONAL: You can provide a custom doxyfile.
let g:doxygen_clone_config_repo = 'https://github.com/Zeioth/doxygenvim-template.git'
let g:doxygen_clone_destiny_dir = './.project-documentation'
let g:doxygen_clone_cmd = 'git clone'

" Shortcuts to open and generate docs (DISALED BY DEFAULT)
let g:doxygen_shortcut_open = '<C-k>'
let g:doxygen_shortcut_generate = '<C-h>'

" You can configure how the docs are open when using g:doxygen_shortcut_open
let g:doxygen_browser_cmd = 'xdg-open'
let g:doxygen_browser_file = './.project-documentation/html/index.html'
```
   
Enable automated doc generation on save
```
" By default, the docs can be accessed on "./.project-documentation/html/index.html".
" This is defined in doxyfile.dox
g:doxygen_auto_regen = 1
```

Specify a custom command to generate the doxygen documentation (optional)

```
" Go to a directory and run doxygen'
g:doxygen_cmd = 'cd ./.project-documentation/doxygen-conf/ && doxygen ./doxyfile.dox'
```

Change the way the root of the project is detected (optional)

``` 
" By default, we detect the root of the project where the first .git file is found
g:doxygen_project_root = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
```

## Final notes

Please, note that even though g:doxygen_auto_setup will setup doxygen for you, you are still responsable for adding your doxygen directory to the .gitignore if you don't want it to be pushed by accident.

It is also possible to disable this plugin for a single project. For that, create .nodoxygen file in the project root directory.


## Credits
This project started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!


## TODOS

* Record a cool video.

## Bugs 
* After cloning, we should delete the .git directory and similar, to avoid potential problems.
* The bootstrap version seems outdated. We should distribute a default doxyfile for now.

## Improvements
* If the user tries to open the doxigen docs and they have not been generated yet, throw an error.
* Offer a way to use a local doxyfile.
* Use the helpers to make sure all directories defined by default work on all operative systems.

## Help needed
* Windows support: It should be functional, but if it isn't, please consider submitting a PR so everyone can benefit.
