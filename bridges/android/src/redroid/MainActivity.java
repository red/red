package org.redlang.eval;

import android.os.Bundle;
import android.app.Activity;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;

public class MainActivity extends Activity {
    static {
        System.loadLibrary("Red");
    }
    public native void doMain(); 
    
    public Object create(String name) throws ClassNotFoundException {
        InvocationHandler handler = new EventInvoker();
        Class<?> cls = Class.forName(name);
        ClassLoader cl = cls.getClassLoader();
        return Proxy.newProxyInstance(cl, new Class[]{cls}, handler);
    }
    
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
