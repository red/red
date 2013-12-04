package org.redlang.eval;

import android.view.View;
import android.view.View.OnTouchListener;
import android.view.MotionEvent;

public class TouchEvent implements OnTouchListener {
	private native boolean Receive(int faceId, MotionEvent event);
	
	@Override
	public boolean onTouch(View face, MotionEvent event) {return(Receive(face.getId(), event));}
}
