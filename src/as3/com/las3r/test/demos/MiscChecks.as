/**
* Copyright (c) Aemon Cannon. All rights reserved.
* The use and distribution terms for this software are covered by the
* Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
* which can be found in the file CPL.TXT at the root of this distribution.
* By using this software in any fashion, you are agreeing to be bound by
* the terms of this license.
* You must not remove this notice, or any other, from this software.
*/

package com.las3r.test.demos{

	import flash.display.*;
	import com.las3r.runtime.*;

	public class MiscChecks extends Sprite{

		public function MiscChecks():void{
			var val:* = null;
			trace("null == false is " + (val == false));
			trace("null == 0 is " + (val == 0));
			trace("null == '' is " + (val == ""));
			trace("null == undefined is " + (val == undefined));

			val = false;
			trace("false == null is " + (val == null));
			trace("false == 0 is " + (val == 0));
			trace("false == '' is " + (val == ""));
			trace("false == undefined is " + (val == undefined));

			trace("Sprite super of DisplayObject " + (Object(Sprite).prototype.isPrototypeOf(Object(DisplayObject).prototype)));
			trace("Sprite super of DisplayObjectContainer " + (Object(Sprite).prototype.isPrototypeOf(Object(DisplayObjectContainer).prototype)));
			trace("DisplayObject super of Sprite " + (Object(DisplayObject).prototype.isPrototypeOf(Object(Sprite).prototype)));
			trace("DisplayObjectContainer super of Sprite " + (Object(DisplayObjectContainer).prototype.isPrototypeOf(Object(Sprite).prototype)));
			trace("Named interface of Symbol " + (Object(Named).prototype.isPrototypeOf(Object(Symbol).prototype)));
			trace("Named interface of Symbol " + (Object(Named).isPrototypeOf(Object(Symbol))));
			trace("Symbol is Named " + (Symbol is Named));
			
			var iface:Class = IList;
			trace("list instance is IList " + ((new List(1)) is iface));

		}

	}

}