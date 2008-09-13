package org.pranaframework.reflection {
	public interface IInvocationHandler {
		function invoke(proxy:*, method:Method, args:Array):*;
	}
}