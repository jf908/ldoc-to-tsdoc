# ldoc to tsdoc

Convert [ldoc](https://github.com/lunarmodules/ldoc) lua documentation into TypeScript types for use with [TypeScriptToLua](https://typescripttolua.github.io/).

## How to use

> Requires - [ldoc](https://github.com/lunarmodules/ldoc)

Place [config.ld](config.ld) and [ldoc.ltp](ldoc.ltp) in the same directory as your lua files and run:

```sh
lua ./path/to/ldoc.lua .
```

If you just want to use it on one file, you can run

```sh
lua ./path/to/ldoc.lua file.lua
```

## How it works

ldoc is usually used to generate HTML pages from lua but it is possible to configure the template and the file extension of the output so this project uses those config options to generate d.ts files.

## Notes

The conversion may not be perfect since it is limited to what is contained in the ldoc syntax so you may have to modify the types to fully make use of TypeScript's type system. Using this template will give you a good starting point regardless.

By default this template assumes each lua file is exported as a global. You can change it to modules by setting the `as_globals` flag at the top to false.

jsdoc and tsdoc are incredibly similar but tsdoc avoids repetition of types. It should be trivial to modify ldoc.ltp to support jsdoc syntax.
