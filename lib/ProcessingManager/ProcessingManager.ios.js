// @flow

import { NativeModules } from 'react-native';
import { getActualSource } from '../utils';
import { recordReactNativeVpError } from './crashlytics';
const { RNVideoTrimmer } = NativeModules;
import type {
  sourceType,
  trimOptions,
  previewMaxSize,
  format,
  compressOptions,
  cropOptions
} from './types';

const wrapNativeCallback = (operation, executor) => new Promise((resolve, reject) => {
  try {
    executor((err, output) => {
      if (err) {
        return reject(recordReactNativeVpError(err, operation));
      }

      return resolve(output);
    });
  } catch (error) {
    return reject(recordReactNativeVpError(error, operation));
  }
});

export class ProcessingManager {
  static trim(source: sourceType, options: trimOptions = {}): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('trim', (callback) => {
      RNVideoTrimmer.trim(actualSource, options, callback);
    });
  }

  static reverse(source: sourceType, options: trimOptions = {}): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('reverse', (callback) => {
      RNVideoTrimmer.reverse(actualSource, options, callback);
    });
  }

  static boomerang(source: sourceType, options: trimOptions = {}): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('boomerang', (callback) => {
      RNVideoTrimmer.boomerang(actualSource, options, callback);
    });
  }

  static getPreviewForSecond(
    source: sourceType,
    forSecond: ?number = 0,
    maximumSize: previewMaxSize,
    format: format
  ): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('getPreviewForSecond', (callback) => {
      RNVideoTrimmer.getPreviewImageAtPosition(actualSource, forSecond, maximumSize, format, callback);
    });
  }

  static getVideoInfo(source: sourceType): Promise<*> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('getVideoInfo', (callback) => {
      RNVideoTrimmer.getAssetInfo(actualSource, callback);
    });
  }

  static compress(source: sourceType, _options: compressOptions): Promise<string> {
    const options = { ..._options };
    const actualSource = getActualSource(source);
    return wrapNativeCallback('compress', (callback) => {
      RNVideoTrimmer.compress(actualSource, options, callback);
    });
  }

  static crop(source: sourceType, options: cropOptions = {}): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('crop', (callback) => {
      RNVideoTrimmer.crop(actualSource, options, callback);
    });
  }

  static isAssetStoredLocally(source: sourceType): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('isAssetStoredLocally', (callback) => {
      RNVideoTrimmer.isAssetStoredLocally(actualSource, callback);
    });
  }

  static saveAssetLocally(source: sourceType): Promise<string> {
    const actualSource: string = getActualSource(source);
    return wrapNativeCallback('saveAssetLocally', (callback) => {
      RNVideoTrimmer.saveAssetLocally(actualSource, callback);
    });
  }
}
