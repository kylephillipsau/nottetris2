# nottetris2

A physics-based Tetris game.

## Requirements
Runs on LÖVE 11.5 (ported from LÖVE 0.7.2)

## Installation
1. Install LÖVE 11.5 from https://love2d.org/
2. Run the game with: `love .`

## Playing in a web browser
The `web/` folder builds the game for browsers with [love.js](https://github.com/Davidobot/love.js) (LÖVE compiled to WebAssembly). It is pinned to a love.js commit that contains LÖVE 11.5, since the npm release is still on 11.4. You need Node.js 18 or newer and git (npm fetches love.js from GitHub).

```
cd web
npm install
npm start
```

Then open http://localhost:8080. `npm start` rebuilds the game from the current source and serves it; run `npm run build` and `npm run serve` separately if you prefer. The output in `web/build/` is a static site that any web server can host.

## Controls
- Menus: arrow keys, Enter to select, Escape to go back
- Single player: left/right to move, down to drop faster, Z/Y/W and X to rotate, Enter to pause
- Versus: player 1 uses A/D/S and G/H, player 2 uses the arrow keys and numpad 1/2

Key bindings live in `controls.lua`.

## Code layout
- `main.lua` – startup, asset loading, options/highscore files and the screen registry
- `controls.lua` – key bindings
- `game.lua` – pieces, walls, steering and drawing shared by the game modes
- `gameA.lua` – "normal" mode, including cutting pieces when a line is cleared
- `gameB.lua` – "stack" mode
- `gameBmulti.lua` – versus mode
- `menu.lua`, `failed.lua`, `rocket.lua` – menus, game over and the rocket ending

Each screen file registers the gamestates it handles with `registerscreen`, and `love.update`/`draw`/`keypressed` forward to the current one.

## Tests
`tests/run.sh` plays scripted scenarios for every mode headless (needs `love` and `xvfb-run`) with a fixed clock and random seed, and compares screenshots against `tests/expected`. Run it after changes to check behaviour hasn't changed; `tests/run.sh --update` records a new baseline when a visual change is intended. Screenshots and logs end up in `tests/out/`.
