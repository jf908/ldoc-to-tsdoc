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

## Example

<table>
<tr>
<th>example.lua</th>
<th>index.d.ts</th>
</tr>
<tr>
<td>

```lua
--[[-
This is a demonstration module.
]]

--[[- This is a description of the test function.
@tparam number a The first number to add.
@tparam number b The second number to add.
@treturn boolean Whether the test was successful.]]
function test(a, b) end
```

</td>
<td>

```ts
/**
 * This is a demonstration module.
 */
declare module 'example' {
  /**
   * This is a description of the test function.
   * @param a The first number to add.
   * @param b The second number to add.
   * @returns boolean - Whether the test was successful.
   */
  export function test(a: number, b: number): boolean;
}
```

</td>
</table>

## How it works

ldoc is usually used to generate HTML pages from lua but it is possible to configure the template and the file extension of the output so this project uses those config options to generate d.ts files.

## Notes

The conversion may not be perfect since it is limited to what is contained in the ldoc syntax so you may have to modify the types to fully make use of TypeScript's type system. Using this template will give you a good starting point regardless.

By default this template assumes each lua file is a module. You can change it to see files as globals using the `as_globals` flag at the top to false.

jsdoc and tsdoc are incredibly similar but tsdoc avoids repetition of types. It should be trivial to modify ldoc.ltp to support jsdoc syntax.
