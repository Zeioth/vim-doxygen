# doxygen-vim - (WIP, please be patient)
Your doxygen documentation on vim. 

## Documentation
Please use <:h doxygen> on vim to read the full documentation.

## How to use

Enable automated doxyfile generation
   
``` 
" Create a default doxigen config for the current project (DISABLED BY DEFAULT)
g:doxygen_auto_setup = 0

" Shortcuts to open and generate docs (DISALED BY DEFAULT)
let g:doxygen_shortcut_open = '<C-R>'
let g:doxygen_shortcut_generate = '<C-G>'

" OPTIONAL: You can provide a custom doxyfile.
let g:doxygen_clone_config_repo = 'https://github.com/Zeioth/doxygenvim-template.git'
let g:doxygen_clone_subdir = ''
let g:doxygen_clone_cmd = 'git clone'
```
   
Enable automated doc generation on save
```
g:doxygen_auto_regen = 1
```

Specify a custom command to generate the doxygen documentation (optional)

```
" By default: it will take the <config-file> of your g:doxygen_clone_config_repo
g:doxygen:cmd = "doxygen -g <config-file>"
```

Change the way the root of the project is detected (optional)

``` 
" By default, we detect the root of the project where the first .git file is found
g:project_root=".git"
```
   
**IMPORTANT**: Please, note that even though g:doxygen_auto_setup will setup doxygen for you, you are still responsable for adding your doxygen directory to the .gitignore if you don't want it to be pushed by accident.
