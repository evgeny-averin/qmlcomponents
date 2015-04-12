package org.qtproject.eaverin.qtquick3dtest;

import android.os.Bundle;
import android.content.ActivityNotFoundException;
import android.content.Intent;

import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.view.Gravity;

import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;

import android.widget.Button;
import android.widget.RelativeLayout;
import android.widget.LinearLayout;

import android.app.Activity;
import android.media.AudioManager;

import java.util.ArrayList;
import android.util.Log;

public class AdMobQtActivity extends org.qtproject.qt5.android.bindings.QtActivity
{
    protected static final int RESULT_SPEECH = 1;
    private   static final String TAG = "AdMobQtActivity";

    private static AdMobQtActivity _instance;
    private static SpeechRecognizer _sr;
    private static Listener _listener;

    private AudioManager _audio_manager;
    private String _rec_result;

    protected class Listener implements RecognitionListener
    {
        @Override
        public void onReadyForSpeech(Bundle params)
        {
              Log.d(TAG, "onReadyForSpeech");
        }

        @Override
        public void onBeginningOfSpeech()
        {
              Log.d(TAG, "onBeginningOfSpeech");
        }

        @Override
        public void onRmsChanged(float rmsdB)
        {
              Log.d(TAG, "onRmsChanged");
        }

        @Override
        public void onBufferReceived(byte[] buffer)
        {
              Log.d(TAG, "onBufferReceived");
        }

        @Override
        public void onEndOfSpeech()
        {
              Log.d(TAG, "onEndofSpeech");
              AdMobQtActivity.setStreamMute(false);
        }

        @Override
        public void onError(int error)
        {
              Log.d(TAG,  "error " +  error);
              AdMobQtActivity.setRecognitionResult("error");
              AdMobQtActivity.setStreamMute(false);
        }

        @Override
        public void onResults(Bundle results)
        {
              String str = new String();
              Log.d(TAG, "onResults " + results);
              ArrayList data = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
              for (int i = 0; i < data.size(); i++)
              {
                        Log.d(TAG, "result " + data.get(i));
                        str += data.get(i);
              }

              if(data.size() > 0) {
                  String result = new String();
                  result += data.get(0);
                  AdMobQtActivity.setRecognitionResult(result);
              }
        }

        @Override
        public void onPartialResults(Bundle partialResults)
        {
              Log.d(TAG, "onPartialResults");
        }

        @Override
        public void onEvent(int eventType, Bundle params)
        {
              Log.d(TAG, "onEvent " + eventType);
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreate");

        _instance = this;
        _sr = SpeechRecognizer.createSpeechRecognizer(getApplicationContext());
        _listener = new Listener();
        _sr.setRecognitionListener(_listener);

        _audio_manager = (AudioManager)getApplicationContext().getSystemService(getApplicationContext().AUDIO_SERVICE);
    }

    public void recognizeSpeech()
    {
        String languagePref = "de";

        _rec_result = "";
        setStreamMute(true);

        Intent intent = RecognizerIntent.getVoiceDetailsIntent(_instance.getApplicationContext());
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, languagePref);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, languagePref);
        intent.putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, languagePref);
        intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 5000);

        _sr.startListening(intent);
    }

    public String getRecognitionResult()
    {
        return _rec_result;
    }

    public static void post()
    {
        Runnable runnable = new Runnable () {
            public void run() {
                invoke();
            };
        };

        _instance.runOnUiThread(runnable);
    }

    public static void setRecognitionResult(String result)
    {
        _instance._rec_result = result;
        setStreamMute(false);
    }

    public static void setStreamMute(boolean mute)
    {
        _instance._audio_manager.setStreamMute(AudioManager.STREAM_MUSIC, mute);
    }

    private static native void invoke();
}
