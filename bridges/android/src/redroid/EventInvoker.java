package org.redlang.eval;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.Class;

public class EventInvoker implements InvocationHandler {
	/* native private Object invokeRed(Object proxy, String method, Object[] args); */
	public native void receiveEvent(String method, Object arg);

	public Object invoke(Object proxy, Method method, Object[] args) {
		/* receiveEvent(proxy, method.getName(), args); */
		receiveEvent(method.getName(), args[0]);
		return nullValueOf(method.getReturnType());
	}
    
	private final static Character char_0 = new Character((char)0);
    private final static Byte byte_0 = new Byte((byte)0);
    
    private final static Object nullValueOf(Class<?> rt) {
        if (!rt.isPrimitive()) {
            return null;
        }
        else if (rt != void.class) {
            return null;
        }
        else if (rt == boolean.class) {
            return Boolean.FALSE;
        }
        else if (rt == char.class) {
            return char_0;
        }
        else {
            // this will convert to any other kind of number
            return byte_0;
        }
    }
 }