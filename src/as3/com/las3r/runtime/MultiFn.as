/**
*   Copyright (c) Rich Hickey. All rights reserved.
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	 the terms of this license.
*   You must not remove this notice, or any other, from this software.
**/

package com.las3r.runtime{

	public class MultiFn extends AFn{
		public var dispatchFn:Function;
		public var defaultDispatchVal:Object;
		public var methodTable:IMap;
		public var preferTable:IMap;
		public var methodCache:IMap;
		public var cachedHierarchy:Object;

		private var isa:Var;
		private var parents:Var;
		private var hierarchy:Var;

		public function MultiFn(rt:RT, dispatchFn:Function, defaultDispatchVal:Object ){
			isa = Var.internNS(rt.LAS3R_NAMESPACE, rt.sym1("isa?"));
			parents = Var.internNS(rt.LAS3R_NAMESPACE, rt.sym1("parents"));
			hierarchy = Var.internNS(rt.LAS3R_NAMESPACE, rt.sym1("global-hierarchy"));

			this.dispatchFn = dispatchFn;
			this.defaultDispatchVal = defaultDispatchVal;
			this.methodTable = PersistentHashMap.empty();
			this.methodCache = methodTable;
			this.preferTable = PersistentHashMap.empty();
			cachedHierarchy = null;
		}

		public function addMethod(dispatchVal:Object, method:Function):MultiFn{
			methodTable = methodTable.assoc(dispatchVal, method);
			resetCache();
			return this;
		}

		public function removeMethod(dispatchVal:Object):MultiFn{
			methodTable = methodTable.without(dispatchVal);
			resetCache();
			return this;
		}

		public function preferMethod(dispatchValX:Object, dispatchValY:Object):MultiFn{
			if(prefers(dispatchValY, dispatchValX))
			throw new Error("IllegalStateException: Preference conflict: " + dispatchValY + " is already preferred to " + dispatchValX);
			preferTable = preferTable.assoc(dispatchValX, RT.conj(IMap(RT.get(preferTable, dispatchValX, PersistentHashSet.empty())),
	                dispatchValY));
			resetCache();
			return this;
		}

		private function prefers(x:Object, y:Object):Boolean{
			var xprefs:ISet = ISet(preferTable.valAt(x));
			if(xprefs != null && xprefs.contains(y))
			return true;
			for(var ps:ISeq = RT.seq(parents.invoke1(y)); ps != null; ps = ps.rest())
			{
				if(prefers(x, ps.first()))
				return true;
			}
			for(ps = RT.seq(parents.invoke1(x)); ps != null; ps = ps.rest())
			{
				if(prefers(ps.first(), y))
				return true;
			}
			return false;
		}

		private function isA(x:Object, y:Object):Boolean{
			return Boolean(isa.invoke2(x, y));
		}

		private function dominates(x:Object, y:Object):Boolean{
			return prefers(x, y) || isA(x, y);
		}

		private function resetCache():IMap{
			methodCache = methodTable;
			cachedHierarchy = hierarchy.get();
			return methodCache;
		}

		private function getFn(dispatchVal:Object):Function{
			if(cachedHierarchy != hierarchy.get())
			resetCache();
			var targetFn:Function = methodCache.valAt(dispatchVal) as Function;
			if(targetFn != null)
			return targetFn;
			targetFn = findAndCacheBestMethod(dispatchVal);
			if(targetFn != null)
			return targetFn;
			targetFn = methodTable.valAt(defaultDispatchVal) as Function;
			if(targetFn == null)
			throw new Error("IllegalArgumentException: No method for dispatch value: " + dispatchVal);
			return targetFn;
		}

		private function findAndCacheBestMethod(dispatchVal:Object):Function{
			var bestEntry:MapEntry = null;
			for(var s:ISeq = methodTable.seq(); s != null; s = s.rest()){
				var e:MapEntry = MapEntry(s.first());
				if(isA(dispatchVal, e.key))
				{
					if(bestEntry == null || dominates(e.key, bestEntry.key))
					bestEntry = e;
					if(!dominates(bestEntry.key, e.key))
					throw new Error("IllegalArgumentException: Multiple methods match dispatch value: " + dispatchVal + 
						" -> " + e.key + 
						" and " + bestEntry.key + 
						", and neither is preferred");
				}
			}
			if(bestEntry == null)
			return null;
			//ensure basis has stayed stable throughout, else redo
			if(cachedHierarchy == hierarchy.get())
			{
				//place in cache
				methodCache = methodCache.assoc(dispatchVal, bestEntry.value);
				return bestEntry.value as Function;
			}
			else
			{
				resetCache();
				return findAndCacheBestMethod(dispatchVal);
			}
		}

		override public function invoke0() :Object{
			return getFn(dispatchFn())();
		}

		override public function invoke1(arg1:Object) :Object{
			return getFn(dispatchFn(arg1))(arg1);
		}

		override public function invoke2(arg1:Object, arg2:Object) :Object{
			return getFn(dispatchFn(arg1, arg2))(arg1, arg2);
		}

		override public function invoke3(arg1:Object, arg2:Object, arg3:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3))(arg1, arg2, arg3);
		}

		override public function invoke4(arg1:Object, arg2:Object, arg3:Object, arg4:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4))(arg1, arg2, arg3, arg4);
		}

		override public function invoke5(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5))(arg1, arg2, arg3, arg4, arg5);
		}

		override public function invoke6(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6))(arg1, arg2, arg3, arg4, arg5, arg6);
		}

		override public function invoke7(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object)
		:Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
		}

		override public function invoke8(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8))(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
		}

		override public function invoke9(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9))(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
		}

		override public function invoke10(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10);
		}

		override public function invoke11(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11);
		}

		override public function invoke12(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12);
		}

		override public function invoke13(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object) :Object{
			return getFn(dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13);
		}

		override public function invoke14(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object)
		:Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
		}

		override public function invoke15(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object) :Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
		}

		override public function invoke16(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object) :Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16);
		}

		override public function invoke17(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object) :Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17))
			(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17);
		}

		override public function invoke18(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object) :Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18))(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18);
		}

		override public function invoke19(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object) :Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18, arg19))(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18, arg19);
		}

		override public function invoke20(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object, arg20:Object)
		:Object{
			return getFn(
				dispatchFn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18, arg19, arg20))(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18, arg19, arg20);
		}


	}

}
