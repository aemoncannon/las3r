/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/

package com.cuttlefish.runtime{


	public interface ISet{

		function each(iterator:Function):void;

		function contains(obj:Object):Boolean;

		function union(s:ISet):ISet;

		function intersect(s:ISet):ISet;

		function subtract(s:ISet):ISet;

		function add(o:Object):ISet;

		function remove(o:Object):ISet;

		function count():int;

		function seq():ISeq;

	}
}