
import java.awt.Frame;
import java.awt.Label;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

class JNIdemo {
     static {
         System.loadLibrary("JNIdemo");
     }
     private static native void doMain();

     public static void main(String[] args) {
		 doMain();
     }
}

class events extends WindowAdapter {
	private native void Receive(int ID);

	public void windowClosing(WindowEvent event) {
		Receive(event.getID());
	}
}