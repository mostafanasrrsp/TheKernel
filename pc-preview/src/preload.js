const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('radiate', {
  version: 'preview-0.1.0',
});

