# vim-doxygen - (WIP, please be patient)
Your doxygen documentation on vim. 

## Documentation
Please use <:h doxygen> on vim to read the full documentation.

## How to use

Enable automated doxyfile generation
   
``` 
" Create a default doxigen config for the current project (DISABLED BY DEFAULT)
g:doxygen_auto_setup = 0

" OPTIONAL: You can provide a custom doxyfile.
let g:doxygen_clone_config_repo = 'https://github.com/Zeioth/doxygenvim-template.git'
let g:doxygen_clone_destiny_dir = ''
let g:doxygen_clone_cmd = 'git clone'

" Shortcuts to open and generate docs (DISALED BY DEFAULT)
let g:doxygen_shortcut_open = '<C-R>'
let g:doxygen_shortcut_generate = '<C-G>'
```
   
Enable automated doc generation on save
```
" By default, the docs can be accessed on "./.project-documentation/html/index.html".
" This is defined in doxifile.dox
g:doxygen_auto_regen = 1
```

Specify a custom command to generate the doxygen documentation (optional)

```
" By default: ./.project-documentation/doxigen-conf/doxifile.dox"
g:doxygen_cmd = "doxygen -g <config-file>"
```

Change the way the root of the project is detected (optional)

``` 
" By default, we detect the root of the project where the first .git file is found
g:project_root=".git"
```
   
**IMPORTANT**: Please, note that even though g:doxygen_auto_setup will setup doxygen for you, you are still responsable for adding your doxygen directory to the .gitignore if you don't want it to be pushed by accident.

## Credits
This project is a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We take most base functions from that project so please support the the author.


## TODOS

* Feature: Command to generate docs manually.
* Feature: Command to open the docs on the browser.
* Clear boilerplate we don't need.

## Bugs 
* On clone, we must delete the .git directory and similar, to avoid problems.
* The bootstrap version seems outdated. We should distribute a default doxyfile.
* Clone only if the directory doesn't exist already.
