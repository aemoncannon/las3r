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


package com.las3r.util{

	import com.las3r.runtime.*;
	
	public class Benchmarks{


		public static function justRunThroughLazySeqOnce(rt:RT, seq:ISeq):int{
			var items:ISeq = seq;
			var sum:int = 0;
			for(; items != null; items = items.rest()){
				sum += 1;
			}
			return sum;
		}

		public static function arrayInitAndAccess(rt:RT, array:Array, count:int):int{
			var i:int;
			var val:Object = new Object();
			for(i = 0; i < count; i++){
				array[i] = 10;
			}
			var sum:int;
			for(i = 0; i < count; i++){
				sum += array[i];
			}
			return sum;
		}

		public static function arrayInitAndAccessSeq(rt:RT, array:Array, seq:ISeq, count:int):int{
			var items:ISeq = seq;
			var i:int;
			for(; items != null; items = items.rest()){
				var pair:IVector = IVector(items.first());
				array[i] = 10;
				i++;
			}

			i = 0;
			items = seq;
			var sum:int;
			for(; items != null; items = items.rest()){
				pair = IVector(items.first());
				sum += array[i]
				i++;
			}

			return sum;
		}

	}
	
}