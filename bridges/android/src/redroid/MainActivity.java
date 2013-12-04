package redroid;

import android.os.Bundle;
import android.app.Activity;

public class MainActivity extends Activity {
	static {
        System.loadLibrary("Red"); 
    }
	private native void doMain();
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        doMain();
    }
    
    @Override
    protected void onPause() {
    	super.onPause();
    } 
}

