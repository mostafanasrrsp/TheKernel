const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('radiate', {
  getHardwareInfo: () => ipcRenderer.invoke('get-hw')
});

