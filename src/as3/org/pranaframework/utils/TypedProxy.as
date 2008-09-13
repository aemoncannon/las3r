package org.pranaframework.utils {
	import org.pranaframework.reflection.IInvocationHandler;
	
	public class TypedProxy {
		public function TypedProxy() {
		}
		
		public static function newProxyInstance(clazz:Class, handler:IInvocationHandler):* {
			// if the class does not implement any interfaces
			// we can create a typed proxy
			var implementsInterface:Boolean = (ClassUtils.getImplementedInterfaces(clazz).length > 0);
			if (implementsInterface) {
				throw new Error("Cannot create proxies for classes that implement interface(s)");
			}
			
			// TODO add object implementation
			var p:* = {};
			/*p.writeMessage = function():void {
				trace("in p");
			}*/
			
			var p_typed:* = ObjectUtils.toInstance(p, clazz);
			
		}

	}
}