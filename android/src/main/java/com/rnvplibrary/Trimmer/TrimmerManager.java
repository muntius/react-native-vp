package com.rnvplibrary.Trimmer;

import android.support.annotation.NonNull;
import android.util.Log;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import java.util.Map;

public class TrimmerManager extends ReactContextBaseJavaModule {
  static final String REACT_PACKAGE = "RNTrimmerManager";

  private final ReactApplicationContext reactContext;

  public TrimmerManager(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    loadFfmpeg();
  }

  @Override
  public String getName() {
    return REACT_PACKAGE;
  }

  @ReactMethod
  public void getPreviewImages(String path, Promise promise) {
    Log.d(REACT_PACKAGE, "getPreviewImages: " + path);
    Trimmer.getPreviewImages(path, promise, reactContext);
  }

  @ReactMethod
  public void getVideoInfo(String path, Promise promise) {
    Log.d(REACT_PACKAGE, "getVideoInfo: " + path);
    Trimmer.getVideoInfo(path, promise, reactContext);
  }

  @ReactMethod
  public void trim(ReadableMap options, Promise promise) {
    Log.d(REACT_PACKAGE, options.toString());
    Trimmer.trim(options, promise, reactContext);
  }

  @ReactMethod
  public void compress(String path, ReadableMap options, Promise promise) {
    Log.d(REACT_PACKAGE, "compress video: " + options.toString());
    Trimmer.compress(path, options, promise, null, null, reactContext);
  }

  @ReactMethod
  public void getPreviewImageAtPosition(ReadableMap options, Promise promise) {
    String source = options.getString("source");
    double sec = options.hasKey("second") ? options.getDouble("second") : 0;
    String format = options.hasKey("format") ? options.getString("format") : null;
    Trimmer.getPreviewImageAtPosition(source, sec, format, promise, reactContext);
  }

  @ReactMethod
  public void crop(String path, ReadableMap options, Promise promise) {
    Trimmer.crop(path, options, promise, reactContext);
  }

  @ReactMethod
  public void boomerang(String path, Promise promise) {
    Log.d(REACT_PACKAGE, "boomerang video: " + path);
    Trimmer.boomerang(path, promise, reactContext);
  }

  @ReactMethod
  public void reverse(String path, Promise promise) {
    Log.d(REACT_PACKAGE, "reverse video: " + path);
    Trimmer.reverse(path, promise, reactContext);
  }

  @ReactMethod
  public void merge(ReadableArray videoFiles, String cmd, Promise promise) {
    Log.d(REACT_PACKAGE, "Sending command: " + cmd);
    Trimmer.merge(videoFiles, cmd, promise, reactContext);
  }

  @ReactMethod
  private void loadFfmpeg() {
    Trimmer.loadFfmpeg(reactContext);
  }
}
