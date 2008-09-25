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

	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;

	public class DragGrip extends Sprite{

		public static const DRAGGED:String = "dragged";

		protected var _width:int;
		protected var _height:int;
		protected var _motionRect:Rectangle;

		public function DragGrip(w:int, h:int, motionRect:Rectangle){
			_width = w;
			_height = h;
			_motionRect = motionRect;

			var g:Graphics = graphics;
			g.beginFill(0x333333);
			g.drawRect(0, 0, _width, _height);
			g.endFill();

			buttonMode = true;

			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}

		protected function onMouseDown(e:Event):void{
			startDrag(false, _motionRect);
			addEventListener(Event.ENTER_FRAME, onDrag);
			e.stopPropagation();
		}

		protected function onMouseUp(e:Event):void{
			stopDrag();
			removeEventListener(Event.ENTER_FRAME, onDrag);
			e.stopPropagation();
		}

		protected function onDrag(e:Event):void{
			dispatchEvent(new Event(DRAGGED));
			e.stopPropagation();
		}


	}
}