# vim-doxygen
Out of the box, this plugin automatically creates a doxyfile for your project, and regenerates the Doxygen documentation on save. It also has keybindings to open the Doxygen documentation quickly when you are coding. All this behaviors can be customized. This project is functional already, but under heavy development. If you find some bug that is not listed below, please submit an issue or PR and I will look into it.

## Documentation
Please use <:h doxygen> on vim to read the [full documentation](https://github.com/Zeioth/vim-doxygen/blob/main/doc/doxygen.txt).

## How to use

Enable automated doxyfile generation

```
" Create a default doxigen config for the current project (ENABLED BY DEFAULT)
g:doxygen_auto_setup = 1

" OPTIONAL: You can provide a custom doxyfile.
let g:doxygen_clone_config_repo = 'https://github.com/Zeioth/doxygenvim-template.git'
let g:doxygen_clone_destiny_dir = './doxygen'
let g:doxygen_clone_cmd = 'git clone'

" Shortcuts to open and generate docs (DISALED BY DEFAULT)
let g:doxygen_shortcut_open = '<C-k>'
let g:doxygen_shortcut_generate = '<C-h>'

" You can configure how the docs are open when using g:doxygen_shortcut_open
let g:doxygen_browser_cmd = 'xdg-open'
let g:doxygen_browser_file = './doxygen/html/index.html'
```

Enable automated doc generation on save
```
" By default, the docs can be accessed on "./doxygen/html/index.html".
" This is defined in Doxyfile
g:doxygen_auto_regen = 1
```

Specify a custom command to generate the doxygen documentation (optional)

```
" Go to a directory and run doxygen'
g:doxygen_cmd = 'cd ./doxygen/ && doxygen ./Doxyfile'
```

Change the way the root of the project is detected (optional)

```
" By default, we detect the root of the project where the first .git file is found
g:doxygen_project_root = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
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

## FAQ

* **Can I have a different Doxyfile per project?** Yes. Even if you have auto setup enabled, the doxygen directory will only be created once. So you can customize the doxyfile for every project individually.

## PRs that will be accepted (Help needed)

* Windows support: It should be functional, but if it isn't, please consider submitting a PR so everyone can benefit from it. → Use the path helpers you will find in 'autoload/doxygen.dim' to make sure all directories defined by default on the global variables defined on 'plugin/doxygen.vim 'work on all operative systems.

## Credits
This project started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!
