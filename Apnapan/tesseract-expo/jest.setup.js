// react-native-gesture-handler ships its own jest setup; without it the
// GestureHandlerRootView cannot install in a test renderer.
require('react-native-gesture-handler/jestSetup');

// Native modules that have no JS implementation under jest-expo are stubbed
// here. Everything with real logic worth testing — the event recorder, the
// game rules, the outbox, speech routing — is plain TypeScript above the
// native seam and is exercised for real, not mocked.
jest.mock('expo-speech', () => ({
  speak: jest.fn(),
  stop: jest.fn(),
  isSpeakingAsync: jest.fn(async () => false),
  getAvailableVoicesAsync: jest.fn(async () => []),
}));

jest.mock('expo-secure-store', () => ({
  getItemAsync: jest.fn(async () => null),
  setItemAsync: jest.fn(async () => undefined),
  deleteItemAsync: jest.fn(async () => undefined),
}));

jest.mock('expo-sensors', () => ({
  DeviceMotion: {
    isAvailableAsync: jest.fn(async () => false),
    addListener: jest.fn(() => ({ remove: jest.fn() })),
    setUpdateInterval: jest.fn(),
  },
}));

jest.mock('expo-notifications', () => ({
  getPermissionsAsync: jest.fn(async () => ({ status: 'undetermined' })),
  requestPermissionsAsync: jest.fn(async () => ({ status: 'denied' })),
  scheduleNotificationAsync: jest.fn(async () => 'id'),
  cancelScheduledNotificationAsync: jest.fn(async () => undefined),
  getAllScheduledNotificationsAsync: jest.fn(async () => []),
  setNotificationHandler: jest.fn(),
  AndroidImportance: { DEFAULT: 3 },
  SchedulableTriggerInputTypes: { DAILY: 'daily' },
}));

// Consumer tests isolate native encryption; cipher tests unmock this seam.
jest.mock('./src/data/storageCipher', () => ({
  sealStorage: jest.fn(async (_address, plaintext) => plaintext),
  openStorage: jest.fn(async (_address, raw) => raw),
  StorageLockedError: class StorageLockedError extends Error {},
}));
