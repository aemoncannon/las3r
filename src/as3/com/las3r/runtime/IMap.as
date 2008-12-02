/**
* Copyright (c) Rich Hickey. All rights reserved.
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/

package com.las3r.runtime{


	public interface IMap{

		function valAt(key:Object, notFound:Object = null):Object;

		function entryAt(key:Object):MapEntry;

		function assoc(key:Object, val:Object):IMap;

		function without(key:Object):IMap;

		function cons(o:Object):IMap;

		function count():int;

		function seq():ISeq;

		function keys():ISeq;

		function vals():ISeq;

		function each(iterator:Function):void;

		function containsKey(key:Object):Boolean;

	}
}