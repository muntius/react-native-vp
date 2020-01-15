package com.rnvplibrary.Trimmer;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.CursorLoader;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Base64;

import com.arthenica.mobileffmpeg.FFmpeg;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.rnvplibrary.Events.Events;
import com.rnvplibrary.interfaces.OnCompressVideoListener;
import com.rnvplibrary.utils.VideoEdit;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.util.UUID;
import java.io.FileOutputStream;

import android.os.AsyncTask;

import static com.arthenica.mobileffmpeg.FFmpeg.RETURN_CODE_CANCEL;
import static com.arthenica.mobileffmpeg.FFmpeg.RETURN_CODE_SUCCESS;


public class Trimmer {

    private static final String LOG_TAG = "RNTrimmerManager";


    private static class FfmpegCmdAsyncTaskParams {
        String cmd;
        final String pathToProcessingFile;
        final Promise promise;

        FfmpegCmdAsyncTaskParams(final String cmd, final String pathToProcessingFile, final Promise promise) {
            this.cmd = cmd;
            this.pathToProcessingFile = pathToProcessingFile;
            this.promise = promise;
        }
    }

    private static class FfmpegCmdAsyncTask extends AsyncTask<FfmpegCmdAsyncTaskParams, Void, Void> {

        @Override
        protected Void doInBackground(FfmpegCmdAsyncTaskParams... params) {
            String cmd = params[0].cmd;
            final String pathToProcessingFile = params[0].pathToProcessingFile;
            final Promise promise = params[0].promise;

            try {
                FFmpeg.execute(cmd, ";");
                int rc = FFmpeg.getLastReturnCode();
                String output = FFmpeg.getLastCommandOutput();
                if (rc == RETURN_CODE_SUCCESS) {
                    String filePath = "file://" + pathToProcessingFile;
                    WritableMap event = Arguments.createMap();
                    event.putString("source", filePath);
                    promise.resolve(event);
                } else if (rc == RETURN_CODE_CANCEL) {
                    promise.reject("error while cropping", "error while cropping");
                } else {
//                    Log.i(LOG_TAG, String.format("Command execution failed with rc=%d and output=%s.", rc, output));
                    promise.reject("cropping failed", "error while cropping");
                }

            } catch (Exception e) {
                promise.reject("Catch Erro", "Cropping failed");
            }
            promise.reject("error while cropping", "error while cropping");
            return null;
        }

    }

    public static void getPreviewImages(String path, Promise promise, ReactApplicationContext ctx) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            if (VideoEdit.shouldUseURI(path)) {
                retriever.setDataSource(ctx, Uri.parse(path));
            } else {
                retriever.setDataSource(path);
            }

            WritableArray images = Arguments.createArray();
            int duration = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION));
            int resizeWidth = 20;
            int resizeHeight = 20;

            for (int i = 0; i < duration; i += duration / 10) {
                Bitmap frame = retriever.getFrameAtTime(i * 1000);
                if (frame == null) {
                    continue;
                }
                Bitmap currBmp = Bitmap.createScaledBitmap(frame, resizeWidth, resizeHeight, false);

                Bitmap normalizedBmp = Bitmap.createBitmap(currBmp, 0, 0, resizeWidth, resizeHeight);
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                normalizedBmp.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
                byte[] byteArray = byteArrayOutputStream.toByteArray();
                String encoded = "data:image/png;base64," + Base64.encodeToString(byteArray, Base64.DEFAULT);
                images.pushString(encoded);
            }

            WritableMap event = Arguments.createMap();

            event.putArray("images", images);

            promise.resolve(event);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            retriever.release();
        }
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    public static void getVideoInfo(String source, Promise promise, ReactApplicationContext ctx) {
//    MediaMetadataRetriever mmr = new MediaMetadataRetriever();
        MediaMetadataRetriever mmr = new MediaMetadataRetriever();
        String path = getRealPathFromURI(Uri.parse(source), ctx);
        try {
            if (VideoEdit.shouldUseURI(path)) {
                mmr.setDataSource(ctx, Uri.parse(path));
            } else {
                mmr.setDataSource(path);
            }
            int duration = Integer.parseInt(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION));
            int width = Integer.parseInt(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH));
            int height = Integer.parseInt(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT));
            int orientation = Integer.parseInt(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION));
            // METADATA_KEY_FRAMERATE returns a float or int or might not exist
            Integer frameRate = VideoEdit.getIntFromString(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE));
            // METADATA_KEY_VARIANT_BITRATE returns a int or might not exist
            Integer bitrate = VideoEdit.getIntFromString(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE));
            if (orientation == 90 || orientation == 270) {
                width = width + height;
                height = width - height;
                width = width - height;
            }
            WritableMap event = Arguments.createMap();
            WritableMap size = Arguments.createMap();
            size.putInt(Events.WIDTH, width);
            size.putInt(Events.HEIGHT, height);
            event.putMap(Events.SIZE, size);
            event.putInt(Events.DURATION, duration / 1000);
            event.putInt(Events.ORIENTATION, orientation);
            if (frameRate != null) {
                event.putInt(Events.FRAMERATE, frameRate);
            } else {
                event.putNull(Events.FRAMERATE);
            }
            if (bitrate != null) {
                event.putInt(Events.BITRATE, bitrate);
            } else {
                event.putNull(Events.BITRATE);
            }
            promise.resolve(event);

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            mmr.release();
        }
    }

    public static String getRealPathFromURI(Uri contentUri, ReactApplicationContext ctx) {
        if (contentUri.toString().startsWith("file://")) {
            return contentUri.toString();
        }
        String[] proj = {MediaStore.Video.Media.DATA};
        CursorLoader loader = new CursorLoader(ctx, contentUri, proj, null, null, null);
        Cursor cursor = loader.loadInBackground();
        int column_index = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA);
        cursor.moveToFirst();
        String result = cursor.getString(column_index);
        cursor.close();
        return result;
    }

    private static ReadableMap getVideoRequiredMetadata(String source, Context ctx) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            if (VideoEdit.shouldUseURI(source)) {
                retriever.setDataSource(ctx, Uri.parse(source));
            } else {
                retriever.setDataSource(source);
            }

            int width = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH));
            int height = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT));
            int bitrate = Integer.parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE));

            WritableMap videoMetadata = Arguments.createMap();
            videoMetadata.putInt("width", width);
            videoMetadata.putInt("height", height);
            videoMetadata.putInt("bitrate", bitrate);
            return videoMetadata;
        } finally {
            retriever.release();
        }
    }

    static File createTempFile(String extension, final Promise promise, Context ctx) {
        UUID uuid = UUID.randomUUID();
        String imageName = uuid.toString() + "-screenshot";

        File cacheDir = ctx.getCacheDir();
        File tempFile = null;
        try {
            tempFile = File.createTempFile(imageName, "." + extension, cacheDir);
        } catch (IOException e) {
            promise.reject("Failed to create temp file", e.toString());
            return null;
        }

        if (tempFile.exists()) {
            tempFile.delete();
        }

        return tempFile;
    }

    static void getPreviewImageAtPosition(String source, double sec, String format, final Promise promise, ReactApplicationContext ctx) {
        Bitmap bmp = null;
        int orientation = 0;
        MediaMetadataRetriever metadataRetriever = new MediaMetadataRetriever();
        try {
            metadataRetriever.setDataSource(source);
            bmp = metadataRetriever.getFrameAtTime((long) (sec * 1000000));
            if (bmp == null) {
                promise.reject("Failed to get preview at requested position.");
                return;
            }
            // NOTE: FIX ROTATED BITMAP
            orientation = Integer.parseInt(metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION));
        } finally {
            metadataRetriever.release();
        }

        if (orientation != 0) {
            Matrix matrix = new Matrix();
            matrix.postRotate(orientation);
            bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), matrix, true);
        }

        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();

        WritableMap event = Arguments.createMap();

        if (format == null || (format != null && format.equals("base64"))) {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
            byte[] byteArray = byteArrayOutputStream.toByteArray();
            String encoded = Base64.encodeToString(byteArray, Base64.DEFAULT);

            event.putString("image", encoded);
        } else if (format.equals("JPEG")) {
            bmp.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
            byte[] byteArray = byteArrayOutputStream.toByteArray();

            File tempFile = createTempFile("jpeg", promise, ctx);

            try {
                FileOutputStream fos = new FileOutputStream(tempFile.getPath());

                fos.write(byteArray);
                fos.close();
            } catch (java.io.IOException e) {
                promise.reject("Failed to save image", e.toString());
                return;
            }

            WritableMap imageMap = Arguments.createMap();
            imageMap.putString("uri", "file://" + tempFile.getPath());

            event.putMap("image", imageMap);
        } else {
            promise.reject("Wrong format error", "Wrong 'format'. Expected one of 'base64' or 'JPEG'.");
            return;
        }

        promise.resolve(event);
    }

    static void crop(String source, ReadableMap options, final Promise promise, ReactApplicationContext ctx) {

        // Crop
//    int cropWidth = (int)( options.getDouble("cropWidth") );
//    int cropHeight = (int)( options.getDouble("cropHeight") );
        int cropOffsetX = (int) (options.getDouble("cropOffsetX"));
        int cropOffsetY = (int) (options.getDouble("cropOffsetY"));
        int cropWidthSize = (int) (options.getDouble("cropWidthSize"));
        int cropHeightSize = (int) (options.getDouble("cropHeightSize"));
        int cropWidth = cropWidthSize;
        int cropHeight = cropHeightSize;

        //Scale
        int width = options.hasKey("cropWidth") ? (int) (options.getDouble("cropWidth")) : 0;
        int height = options.hasKey("cropHeight") ? (int) (options.getDouble("cropHeight")) : 0;
        String filePath = getRealPathFromURI(Uri.parse(source), ctx);
        final File tempFile = createTempFile("mp4", promise, ctx);
        String startTime = options.hasKey("startTime") ? options.getString("startTime") : "00:00:00";
        String endTime = options.hasKey("endTime") ? options.getString("endTime") : "00:00:01";
        String cropString = "crop=" + Integer.toString(cropWidth) + ":" + Integer.toString(cropHeight) + ":" + Integer.toString(cropOffsetX) + ":" + Integer.toString(cropOffsetY);
        if (width != 0 && height != 0) {
                cropString = cropString + "," + "scale=" + Integer.toString(width / (int) 2.25) + ":" + Integer.toString(height / (int) 2.25);
            }
            String pathToProcessingFile = tempFile.getPath();
            String oneFinal = "-y;-i;" + filePath + ";-ss;" + startTime + ";-to;" + endTime + ";-vf;" + cropString + ";-c:a;aac;-c:v;mpeg4;-r;30;-vb;20M;" + pathToProcessingFile;
            String errorMessageTitle = "Crop error";
            OnCompressVideoListener cb = null;
            FfmpegCmdAsyncTaskParams ffmpegCmdAsyncTaskParams = new FfmpegCmdAsyncTaskParams(oneFinal, pathToProcessingFile, promise);

            FfmpegCmdAsyncTask ffmpegCmdAsyncTask = new FfmpegCmdAsyncTask();
            ffmpegCmdAsyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, ffmpegCmdAsyncTaskParams);
        }

    }