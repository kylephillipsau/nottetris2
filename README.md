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

The page around the game is `web/page/index.html`. On phones and tablets (a touch screen up to 1024 pixels wide) it shows on-screen controls, below the game or either side of it when held sideways; they send the same keys as a keyboard, so they also play player 2 in versus. Every push to `master` publishes the build to GitHub Pages (`.github/workflows/pages.yml`); enable it once under Settings > Pages > Source: GitHub Actions.

## Controls
- Menus: arrow keys, Enter to select, Escape to go back
- Single player: left/right to move, down to drop faster, Z/Y/W and X to rotate, Enter to pause
- Versus: player 1 uses A/D/S and G/H, player 2 uses the arrow keys and numpad 1/2

Key bindings live in `controls.lua`.

## Options
Volume, colour, window scale and fullscreen, plus **Softbody**: the pieces turn to rubber. Each piece is one soft body that bends, squashes and wobbles as a whole, and clearing a line cuts it like the rigid pieces. Floppy pieces squeeze into gaps, which makes the game easier, so pieces get stiffer as it gets harder: with each level in normal mode, and every 10 tiles in stack and versus mode. How stiff, springy and slippery the rubber is, and how fast it stiffens, is set at the top of `softbody.lua`.

## Code layout
- `main.lua` – startup, asset loading, options/highscore files and the screen registry
- `controls.lua` – key bindings
- `game.lua` – pieces, walls, steering and drawing shared by the game modes
- `pieceart.lua` – the pieces' vector art (coloured rectangles in a Mesh per piece kind, recoloured with the colour option). Soft pieces have a design with one outline around the whole piece, and a vertex shader bends their art with the lattice
- `softbody.lua` – the soft body engine behind the Softbody option: each piece is a lattice of particles held in shape by compliant constraints, solved with XPBD in substeps, with contacts and friction, sleeping and cutting along cleared lines
- `gameA.lua` – "normal" mode, including cutting pieces when a line is cleared
- `gameB.lua` – "stack" mode
- `gameBmulti.lua` – versus mode
- `menu.lua`, `failed.lua`, `rocket.lua` – menus, game over and the rocket ending

Each screen file registers the gamestates it handles with `registerscreen`, and `love.update`/`draw`/`keypressed` forward to the current one.

## Tests
`tests/run.sh` plays scripted scenarios for every mode headless (needs `love` and `xvfb-run`) with a fixed clock and random seed, and compares screenshots against `tests/expected`. Run it after changes to check behaviour hasn't changed; `tests/run.sh --update` records a new baseline when a visual change is intended. Screenshots and logs end up in `tests/out/`; `softbend` tiles the frames of a soft piece bending into one image, handy when tuning the rubber.
