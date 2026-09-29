// Builds the game for the browser: copies the game files into build/game and
// runs love.js on them, producing build/index.html and friends.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

function gitversion() { //short commit of the game source, with + if it has uncommitted changes, so the page title shows which build is running
  try {
    const run = args => execFileSync('git', args, { cwd: root }).toString().trim();
    return run(['rev-parse', '--short', 'HEAD']) + (run(['status', '--porcelain', '--', '.', ':!web']) ? '+' : '');
  } catch (e) {
    return 'unknown';
  }
}

const root = path.resolve(__dirname, '..');
const build = path.join(__dirname, 'build');
const staging = path.join(build, 'game');

const version = gitversion();
fs.rmSync(build, { recursive: true, force: true });
fs.mkdirSync(staging, { recursive: true });

for (const entry of fs.readdirSync(root)) {
  if (entry.endsWith('.lua') || entry === 'graphics' || entry === 'sounds') {
    fs.cpSync(path.join(root, entry), path.join(staging, entry), { recursive: true });
  }
}

// -c (compatibility) builds without threads, so any static web server can host it:
// the threaded build needs cross-origin isolation headers that most hosts don't send.
const lovejs = path.join(__dirname, 'node_modules', 'love.js', 'index.js');
execFileSync(process.execPath, [lovejs, '-c', '-t', 'Not Tetris 2 (' + version + ')', staging, build], { stdio: 'inherit' });
fs.rmSync(staging, { recursive: true, force: true });

// swap love.js' demo page for ours, keeping the loader settings love.js worked out
const generated = fs.readFileSync(path.join(build, 'index.html'), 'utf8');
const setting = name => new RegExp(name + ': (.*?),?\n').exec(generated)[1];
const page = fs.readFileSync(path.join(__dirname, 'page', 'index.html'), 'utf8')
  .replace('{{title}}', 'Not Tetris 2')
  .replace('{{{arguments}}}', setting('arguments'))
  .replace('{{memory}}', setting('INITIAL_MEMORY'))
  .replace('</title>', '</title>\n<meta name="generator" content="nottetris2 ' + version + '">');
fs.writeFileSync(path.join(build, 'index.html'), page);
fs.rmSync(path.join(build, 'theme'), { recursive: true, force: true });
console.log('Built version ' + version + ' in ' + path.relative(process.cwd(), build) + ' - serve it with: npm run serve');
