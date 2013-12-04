package org.redlang.eval;

import android.view.View;
import android.view.View.OnClickListener;

public class ClickEvent implements OnClickListener {
	private native void Receive(int faceId);
	
	@Override
	public void onClick(View face) {Receive(face.getId());}
}
