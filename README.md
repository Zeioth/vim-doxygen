# vim-doxygen
Your doxygen documentation on vim. (This project is functional already, but under heavy development. If you find some bug, please submit an issue or PR and I will look into it.

## Documentation
Please use <:h doxygen> on vim to read the full documentation.

## How to use

Enable automated doxyfile generation
   
``` 
" Create a default doxigen config for the current project (DISABLED BY DEFAULT)
g:doxygen_auto_setup = 0

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
" This is defined in doxifile.dox
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
g:doxygen_project_root=".git"
```
   
**IMPORTANT**: Please, note that even though g:doxygen_auto_setup will setup doxygen for you, you are still responsable for adding your doxygen directory to the .gitignore if you don't want it to be pushed by accident.

## HOW TO: Disable the plugin for an specific project
Create .nodoxygen in the project root.


## Credits
This project started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!


## TODOS

* Record a cool video.

## Bugs 
* Clone only if the destiny directory doesn't exist already. This will save useless requests to github.
* After cloning, we should delete the .git directory and similar, to avoid problems.
* The bootstrap version seems outdated. We should distribute a default doxyfile for now.


## Improvements
* If the user tries to open the doxigen web and it has not been generated yet, echo an error.

## Help needed
* Windows support: It should be functional, but if it isn't, please consider submitting a PR so everyone can benefit.
