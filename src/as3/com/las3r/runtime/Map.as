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

	import flash.utils.Dictionary;
	import com.las3r.util.Util;

	public class Map extends PersistentArrayMap{

		public static function createFromMany(...init:Array):Map{
			return createFromArray(init);
		}

		public static function createFromSeq(seq:ISeq):Map{
			var source:Array = [];
			for(var c:ISeq = seq; c != null; c = c.rest()){
				source.push(c.first());
			}
			return createFromArray(source);
		}

		public static function createFromArray(init:Array):Map{
			return new Map(init);
		}

		public function Map(init:Array = null, meta:IMap = null){
			super(init, meta);
		}

	}
}

