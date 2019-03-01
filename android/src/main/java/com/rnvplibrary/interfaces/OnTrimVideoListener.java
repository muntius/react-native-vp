package com.rnvplibrary.interfaces;


import android.net.Uri;

public interface OnTrimVideoListener {
    void onError(final String message);
    void onTrimStarted();
    void getResult(final Uri uri);
    void cancelAction();

}
