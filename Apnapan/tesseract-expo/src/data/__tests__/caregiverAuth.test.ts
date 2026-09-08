import { availableFactor, type AuthCapability } from '../caregiverAuth';

const cap = (over: Partial<AuthCapability> = {}): AuthCapability => ({
  deviceAuth: false,
  biometricEnrolled: false,
  passcodeSet: false,
  pinSet: false,
  ...over,
});

describe('the caregiver gate fails closed', () => {
  it('offers nothing while capability is still loading', () => {
    // The defect: the old gate rendered a plain Continue button wired to
    // onUnlocked during this window, so the gate was open while loading.
    expect(availableFactor(null)).toBe('loading');
  });

  it('offers nothing when the device has no lock and no PIN', () => {
    // Previously this drew a Continue button. A confirmation button is not
    // authentication.
    expect(availableFactor(cap())).toBe('none');
  });

  it('uses the device passcode even without biometric enrollment', () => {
    // Passcode support and biometric enrollment are different things; the old
    // check collapsed them and refused a passcode-only phone.
    expect(
      availableFactor(cap({ passcodeSet: true, deviceAuth: true })),
    ).toBe('device');
  });

  it('uses biometrics when enrolled', () => {
    expect(
      availableFactor(
        cap({ biometricEnrolled: true, passcodeSet: true, deviceAuth: true }),
      ),
    ).toBe('device');
  });

  it('falls back to the caregiver PIN only when the device offers nothing', () => {
    expect(availableFactor(cap({ pinSet: true }))).toBe('pin');
  });

  it('prefers device authentication over the PIN when both exist', () => {
    expect(
      availableFactor(cap({ deviceAuth: true, passcodeSet: true, pinSet: true })),
    ).toBe('device');
  });
});
