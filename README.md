# vim-doxygen
Out of the box, this plugin automatically creates a doxyfile for your project, and regenerates the Doxygen documentation on save. It also has keybindings to open the Doxygen documentation quickly when you are coding. All this behaviors can be customized. 

## Dependencies

You must have 

    doxygen 
    
installed in your system.

## Video tutorial
https://www.youtube.com/watch?v=rim6tW2ZXyg

## Documentation
Please use <:h doxygen> on vim to read the [full documentation](https://github.com/Zeioth/vim-doxygen/blob/main/doc/doxygen.txt).

## How to use

Copy this in your vimconfig:

```
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim doxygen
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Enable it for the next languages
let g:doxygen_include_filetypes = ['c', 'cpp', 'cs', 'python', 'd', 'fortran', 'java', 'perl', 'vhdl', 'objc', 'php']

" Enable the keybindings, for the included_filetypes
augroup doxygen_mappings
  for ft in g:doxygen_include_filetypes
    execute 'autocmd FileType ' . ft . ' nnoremap <buffer> <C-h> :<C-u>DoxygenOpen<CR>'
    "execute 'autocmd FileType ' . ft . ' nnoremap <buffer> <C-k> :<C-u>DoxygenRegen<CR>'
  endfor
augroup END
```

## Most frecuent options users customize

Enable automated doxyfile generation (optional)

```
" Clone a default Doxyfile into the project (ENABLED BY DEFAULT)
" Check the template here: https://github.com/Zeioth/vim-doxygen-template
g:doxygen_auto_setup = 1

" OPTIONAL: You can provide a custom Doxyfile.
let g:doxygen_clone_config_repo = 'https://github.com/Zeioth/doxygen-vim-template.git'
let g:doxygen_clone_destiny_dir = './doxygen'
let g:doxygen_clone_cmd = 'git clone'
```

Enable automated doc generation on save (optional)
```
" Enabled by default for the languages defined in g:typedoc_include_filetypes
" By default, the docs will be generated on "./doxygen/html/index.html".
let g:doxygen_auto_regen = 1
```

Change the way the documentation is opened (optional)
```
" You can configure how the documentation is open.
let g:doxygen_browser_cmd = 'xdg-open'
let g:doxygen_browser_file = './doxygen/html/index.html'
```

Custom command to generate the doxygen documentation (optional)

```
let g:doxygen_cmd = 'cd ./doxygen/ && doxygen ./Doxyfile'
```

Change the way the root of the project is detected (optional)

```
" By default, we detect the root of the project where the first .git file is found
let g:doxygen_project_root = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
```

## Final notes

Please, note that even though g:doxygen_auto_setup will setup doxygen for you, you are still responsable for adding your doxygen directory to the .gitignore if you don't want it to be pushed by accident.

It is also possible to disable this plugin for a single project. For that, create .nodoxygen file in the project root directory.

## Cool features of this plugin

* Automated doxygen setup for your project. → Creates the doxyfile [from a repository](https://github.com/Zeioth/vim-doxygen-template) (by default), or locally.
* Documentation is automatically generated as you work.
* Shortcut to open the documentation in your browser
* Shortcut to manually generate documentation (if you don't like the auto mode)
* Easy to use doxygen themes
* Fully async

## FAQ

* **Can I have a different Doxyfile per project?** Yes. Even if you have auto setup enabled, the doxygen directory will only be created once. So you can customize the doxyfile for every project individually.

## PRs that will be accepted (Help needed)

* Windows support: It should be functional, but if it isn't, please consider submitting a PR so everyone can benefit from it. → Use the path helpers you will find in 'autoload/doxygen.vim' to make sure all directories defined by default on the global variables defined on 'plugin/doxygen.vim 'work on all operative systems.

## Credits
This project started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!
