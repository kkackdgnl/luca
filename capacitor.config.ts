import { CapacitorConfig } from '@capacitor/cli';
const config: CapacitorConfig = {
  appId: 'com.luca.jarviskr',
  appName: 'JARVIS KR',
  webDir: 'web',
  bundledWebRuntime: false,
  android: {
    path: 'android'
  }
};
export default config;