// @flow

import { NativeModules } from 'react-native';
import { recordReactNativeVpError } from './crashlytics';
import type {
  sourceType,
  arrayType,
  trimOptions,
  previewMaxSize,
  format,
  cropOptions
} from './types';

import { getActualSource, numberToHHMMSS } from '../utils';

const { RNTrimmerManager: TrimmerManager } = NativeModules;

const wrapNativePromise = (operation, executor) => {
  try {
    return executor().catch((error) => {
      throw recordReactNativeVpError(error, operation);
    });
  } catch (error) {
    return Promise.reject(recordReactNativeVpError(error, operation));
  }
};

export class ProcessingManager {
  static trim(source: sourceType, options: trimOptions): Promise<string> {
    if ( options.startTime != null ) {
      options.startTime = numberToHHMMSS({ number: options.startTime })
    }
    if ( options.endTime != null ) {
      options.endTime = numberToHHMMSS({ number: options.endTime })
    }

    const actualSource: string = getActualSource(source);
    const mData = { source: actualSource, ...options };
    return wrapNativePromise('trim', () => TrimmerManager.trim(mData))
      .then((res) => res.source);
  }

  static getPreviewForSecond(
    source: sourceType,
    second: number,
    maximumSize: previewMaxSize,
    format: format
  ): Promise<*> {
    const actualSource: string = getActualSource(source);
    const mData = { source: actualSource, second, format };
    return wrapNativePromise('getPreviewForSecond', () => TrimmerManager.getPreviewImageAtPosition(mData))
      .then((res) => res.image);
  }

  static getVideoInfo(source: sourceType): Promise<*> {
    const actualSource: string = getActualSource(source);
    return wrapNativePromise('getVideoInfo', () => TrimmerManager.getVideoInfo(actualSource));
  }

  static compress(source: sourceType, options: any): Promise<*> {
    const actualSource: string = getActualSource(source);
    return wrapNativePromise('compress', () => TrimmerManager.compress(actualSource, options));
  }

  static boomerang(source: sourceType): Promise<*> {
    const actualSource: string = getActualSource(source);
    return wrapNativePromise('boomerang', () => TrimmerManager.boomerang(actualSource))
      .then((res) => res.source);
  }

  static reverse(source: sourceType): Promise<*> {
    const actualSource: string = getActualSource(source);
    return wrapNativePromise('reverse', () => TrimmerManager.reverse(actualSource))
      .then((res) => res.source);
  }

  static crop(source: sourceType, options: cropOptions): Promise<string> {
    if ( options.startTime != null ) {
      options.startTime = numberToHHMMSS({ number: options.startTime })
    }
    if ( options.endTime != null ) {
      options.endTime = numberToHHMMSS({ number: options.endTime })
    }

    const actualSource: string = getActualSource(source);
    return wrapNativePromise('crop', () => TrimmerManager.crop(actualSource, options))
      .then((res) => res.source);
  }

  static merge(readableFiles: arrayType, cmd: string): Promise<string> {
    return wrapNativePromise('merge', () => TrimmerManager.merge(readableFiles, cmd)).then((res) => res.source);
  }

}
