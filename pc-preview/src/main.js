const { app, BrowserWindow, ipcMain, nativeTheme } = require('electron');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');

if (process.platform === 'linux') {
  app.commandLine.appendSwitch('enable-features', 'VaapiVideoDecoder,VaapiVideoEncoder');
  app.commandLine.appendSwitch('use-gl', 'desktop');
}

nativeTheme.themeSource = 'dark';

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    fullscreen: false,
    kiosk: false,
    autoHideMenuBar: true,
    backgroundColor: '#0b0f1a',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function run(cmd) {
  return new Promise((resolve) => {
    exec(cmd, { timeout: 5000 }, (err, stdout) => {
      if (err) return resolve(null);
      resolve(stdout.trim());
    });
  });
}

async function detectNvidia() {
  const smi = await run('nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader');
  if (!smi) return null;
  const [name, driver, mem] = smi.split(',').map((s) => s.trim());
  return { name, driver, memoryTotal: mem };
}

ipcMain.handle('get-hw', async () => {
  const cpus = os.cpus() || [];
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const platform = os.platform();
  const release = os.release();
  const arch = os.arch();
  const nvidia = await detectNvidia();
  return {
    cpuModel: cpus[0]?.model || 'Unknown',
    cpuCores: cpus.length,
    arch,
    platform,
    osRelease: release,
    memoryGB: (totalMem / (1024 ** 3)).toFixed(1),
    memoryFreeGB: (freeMem / (1024 ** 3)).toFixed(1),
    nvidia
  };
});

app.on('ready', createWindow);
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
app.on('activate', () => {
  if (mainWindow === null) createWindow();
});

