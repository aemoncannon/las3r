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
		public var dispatchFn:IFn;
		public var defaultDispatchVal:Object;
		public var methodTable:IMap;
		public var preferTable:IMap;
		public var methodCache:IMap;
		public var cachedHierarchy:Object;

		// 	static final Var assoc = RT.var("clojure.core", "assoc");
		// 		static final Var dissoc = RT.var("clojure.core", "dissoc");
		// 		static final Var isa = RT.var("clojure.core", "isa?");
		// 		static final Var parents = RT.var("clojure.core", "parents");
		// 		static final Var hierarchy = RT.var("clojure.core", "global-hierarchy");

		public function MultiFn(rt:Runtime, dispatchFn:IFn, defaultDispatchVal:Object){
			this.dispatchFn = dispatchFn;
			this.defaultDispatchVal = defaultDispatchVal;
			this.methodTable = PersistentHashMap.empty();
			this.methodCache = methodTable;
			this.preferTable = PersistentHashMap.empty();
			cachedHierarchy = null;
		}

		public function addMethod(dispatchVal:Object, method:IFn):MultiFn{
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
			preferTable = preferTable.assoc(dispatchValX, RT.conj(IMap(RT.get(preferTable, dispatchValX, PersistentHashSet.EMPTY)),
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
			for(var ps:ISeq = RT.seq(parents.invoke1(x)); ps != null; ps = ps.rest())
			{
				if(prefers(ps.first(), y))
				return true;
			}
			return false;
		}

		private function isA(x:Object, y:Object):Boolean{
			return RT.booleanCast(isa.invoke2(x, y));
		}

		private function dominates(x:Object, y:Object):Boolean{
			return prefers(x, y) || isA(x, y);
		}

		private function resetCache():IMap{
			methodCache = methodTable;
			cachedHierarchy = hierarchy.get();
			return methodCache;
		}

		private function getFn(dispatchVal:Object):IFn{
			if(cachedHierarchy != hierarchy.get())
			resetCache();
			var targetFn:IFn = IFn(methodCache.valAt(dispatchVal));
			if(targetFn != null)
			return targetFn;
			targetFn = findAndCacheBestMethod(dispatchVal);
			if(targetFn != null)
			return targetFn;
			targetFn = IFn(methodTable.valAt(defaultDispatchVal));
			if(targetFn == null)
			throw new Error("IllegalArgumentException: No method for dispatch value: " + dispatchVal);
			return targetFn;
		}

		private function findAndCacheBestMethod(dispatchVal:Object):IFn{
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
				methodCache = methodCache.assoc(dispatchVal, bestEntry.getValue());
				return IFn(bestEntry.getValue());
			}
			else
			{
				resetCache();
				return findAndCacheBestMethod(dispatchVal);
			}
		}

		public function invoke0() :Object{
			return getFn(dispatchFn.invoke0()).invoke0();
		}

		public function invoke1(arg1:Object) :Object{
			return getFn(dispatchFn.invoke1(arg1)).invoke1(arg1);
		}

		public function invoke2(arg1:Object, arg2:Object) :Object{
			return getFn(dispatchFn.invoke2(arg1, arg2)).invoke2(arg1, arg2);
		}

		public function invoke3(arg1:Object, arg2:Object, arg3:Object) :Object{
			return getFn(dispatchFn.invoke3(arg1, arg2, arg3)).invoke3(arg1, arg2, arg3);
		}

		public function invoke4(arg1:Object, arg2:Object, arg3:Object, arg4:Object) :Object{
			return getFn(dispatchFn.invoke4(arg1, arg2, arg3, arg4)).invoke4(arg1, arg2, arg3, arg4);
		}

		public function invoke5(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object) :Object{
			return getFn(dispatchFn.invoke5(arg1, arg2, arg3, arg4, arg5)).invoke5(arg1, arg2, arg3, arg4, arg5);
		}

		public function invoke6(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object) :Object{
			return getFn(dispatchFn.invoke6(arg1, arg2, arg3, arg4, arg5, arg6)).invoke6(arg1, arg2, arg3, arg4, arg5, arg6);
		}

		public function invoke7(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object)
		:Object{
			return getFn(dispatchFn.invoke7(arg1, arg2, arg3, arg4, arg5, arg6, arg7))
			.invoke7(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
		}

		public function invoke8(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object) :Object{
			return getFn(dispatchFn.invoke8(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)).
			invoke8(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
		}

		public function invoke9(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object) :Object{
			return getFn(dispatchFn.invoke9(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)).
			invoke9(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
		}

		public function invoke10(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object) :Object{
			return getFn(dispatchFn.invoke10(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)).
			invoke10(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10);
		}

		public function invoke11(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object) :Object{
			return getFn(dispatchFn.invoke11(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)).
			invoke11(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11);
		}

		public function invoke12(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object) :Object{
			return getFn(dispatchFn.invoke12(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)).
			invoke12(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12);
		}

		public function invoke13(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object) :Object{
			return getFn(dispatchFn.invoke13(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13)).
			invoke13(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13);
		}

		public function invoke14(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object)
		:Object{
			return getFn(
				dispatchFn.invoke14(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)).
			invoke14(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
		}

		public function invoke15(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object) :Object{
			return getFn(
				dispatchFn.invoke15(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15))
			.invoke15(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
		}

		public function invoke16(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object) :Object{
			return getFn(
				dispatchFn.invoke16(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16))
			.invoke16(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16);
		}

		public function invoke17(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object) :Object{
			return getFn(
				dispatchFn.invoke17(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17))
			.invoke17(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17);
		}

		public function invoke18(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object) :Object{
			return getFn(
				dispatchFn.invoke18(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18)).
			invoke18(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18);
		}

		public function invoke19(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object) :Object{
			return getFn(
				dispatchFn.invoke19(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18, arg19)).
			invoke19(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18, arg19);
		}

		public function invoke20(arg1:Object, arg2:Object, arg3:Object, arg4:Object, arg5:Object, arg6:Object, arg7:Object,
            arg8:Object, arg9:Object, arg10:Object, arg11:Object, arg12:Object, arg13:Object, arg14:Object,
            arg15:Object, arg16:Object, arg17:Object, arg18:Object, arg19:Object, arg20:Object)
		:Object{
			return getFn(
				dispatchFn.invoke20(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			        arg15, arg16, arg17, arg18, arg19, arg20)).
			invoke20(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14,
			    arg15, arg16, arg17, arg18, arg19, arg20);
		}


	}

}
