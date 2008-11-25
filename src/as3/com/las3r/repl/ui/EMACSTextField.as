/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/

package com.las3r.repl.ui{

	import flash.ui.Keyboard;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.text.*;

	public class EMACSTextField extends Sprite{

		protected var _mark:int = 0;
		protected var _point:int = 0;
		protected var _field:TextField;

		public function EMACSTextField(){
			super();

			var tf:TextFormat = new TextFormat();
			tf.color = 0xFFFFFF;
			tf.font = "Arial";
			tf.size = 14;
			tf.indent = 3;

			_field = new TextField();
			_field.defaultTextFormat = tf;
            _field.border = true;
            _field.borderColor = 0x555555;
            _field.background = true;
			_field.backgroundColor = 0x222222;
			_field.wordWrap = true;
			_field.multiline = true;
			_field.type = TextFieldType.DYNAMIC;
            addChild(_field);

			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp, true);
			addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		public function get text():String{
			return _field.text;
		}

		public function set text(val:String):void{
			_field.text = val;
		}

		override public function set width(val:Number):void{
			_field.width = val;
		}

		override public function set height(val:Number):void{
			_field.height = val;
		}

		protected function onMouseDown(e:Event):void{
			e.stopPropagation();
		}

		protected function onMouseUp(e:Event):void{
			e.stopPropagation();
		}

		protected function onKeyDown(e:KeyboardEvent):void{
			var key:uint = e.keyCode;
			switch (key) {
				case Keyboard.LEFT :
				backwardChar();
				return;
 				break;

				case Keyboard.RIGHT :
				forwardChar();
				return;
 				break;

				case Keyboard.UP :
				return;
 				break;

				case Keyboard.DOWN :
				return;
 				break;
			}
			insert(String.fromCharCode(e.charCode));
		}

		protected function onKeyUp(e:Event):void{
		}

		protected function onEnterFrame(e:Event):void{
			_field.setSelection(_point, _point + 1);
		}

		public function insert(str:String):void{
			_field.replaceSelectedText(str);
			_point += str.length;
		}

		public function forwardChar():void{
			_point += 1;
		}

		public function backwardChar():void{
			_point -= 1;
		}



	}
}