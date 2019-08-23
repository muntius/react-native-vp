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
}
