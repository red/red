
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

class bridge {
     static {
         System.loadLibrary("hello");
     }
     private static native void doMain();

     public static void main(String[] args) {
		 doMain();
     }
}

class events extends WindowAdapter {
	private native void Receive(int ID);

	public void windowClosing		(WindowEvent event) {Receive(event.getID());}
	public void windowActivated		(WindowEvent event) {Receive(event.getID());}
	public void windowDeactivated	(WindowEvent event) {Receive(event.getID());}
	public void windowDeiconified	(WindowEvent event) {Receive(event.getID());}
	public void windowGainedFocus	(WindowEvent event) {Receive(event.getID());}
	public void windowIconified		(WindowEvent event) {Receive(event.getID());}
	public void windowLostFocus		(WindowEvent event) {Receive(event.getID());}
	public void windowOpened		(WindowEvent event) {Receive(event.getID());}
	public void windowStateChanged	(WindowEvent event) {Receive(event.getID());}
}