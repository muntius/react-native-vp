import crashlytics from '@react-native-firebase/crashlytics';

const REACT_NATIVE_VP_CONTEXT = 'react-native-vp';

const stringifyError = (error) => {
  if (typeof error === 'string') {
    return error;
  }

  try {
    return JSON.stringify(error);
  } catch (_stringifyError) {
    return String(error);
  }
};

export const normalizeReactNativeVpError = (error, operation) => {
  if (error instanceof Error) {
    return error;
  }

  const description = stringifyError(error);
  return new Error(`${REACT_NATIVE_VP_CONTEXT} ${operation}: ${description}`);
};

export const recordReactNativeVpError = (error, operation) => {
  const normalizedError = normalizeReactNativeVpError(error, operation);
  crashlytics().recordError(normalizedError, `${REACT_NATIVE_VP_CONTEXT} ${operation}`);
  return normalizedError;
};
