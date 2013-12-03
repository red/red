package org.redlang.eval;

import android.view.View;
import android.view.View.OnLongClickListener;

public class LongClickEvent implements OnLongClickListener {
	private native boolean Receive(int faceId);
	
	@Override
	public boolean onLongClick(View face) {return(Receive(face.getId()));}
}
