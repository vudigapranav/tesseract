jest.mock('../storage', () => ({ patientKey: (id: string, key: string) => `${id}:${key}` }));
/** A barrel import must fail this test rather than hide behind the global mock. */
jest.mock('expo-notifications', () => {
  throw new Error('Remote push barrel must not load for local reminders');
});
jest.mock('expo-notifications/build/DevicePushTokenAutoRegistration.fx', () => {
  throw new Error('Remote push registration must not load');
});
jest.mock('expo-notifications/build/TokenEmitter', () => {
  throw new Error('Remote token emitter must not load');
});

test('reminders load without evaluating remote push modules', () => {
  const reminders = require('../reminders') as typeof import('../reminders');
  const local = require('../localNotifications') as typeof import('../localNotifications');
  expect(typeof reminders.reconcileSchedule).toBe('function');
  expect(typeof local.scheduleNotificationAsync).toBe('function');
  expect(typeof local.getPermissionsAsync).toBe('function');
  expect(local.SchedulableTriggerInputTypes.DAILY).toBe('daily');
});
