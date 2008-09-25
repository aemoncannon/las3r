/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/

package com.las3r.repl{

	import com.las3r.runtime.*;
	import com.las3r.repl.ui.*;
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.events.*;

	public class Repl extends Sprite{

		protected var _width:int;
		protected var _height:int;
		protected var _rt:RT;
		protected var _ui:Sprite;
		protected var _resizeGrip:DragGrip;

		public function Repl(w:int, h:int){
			_width = w;
			_height = h;
			_rt = new RT();
			createUI();
			_ui.visible = false;
			_rt.loadStdLib(function(val:*):void{
					refreshUI();
					_ui.visible = true;
				});
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}

		protected function onMouseDown(e:Event):void{
			startDrag();
		}

		protected function onMouseUp(e:Event):void{
			stopDrag();
		}

		protected function createUI():void{
			_ui = new Sprite();
			addChild(_ui);

			_resizeGrip = new DragGrip(10, 10, new Rectangle(100, 100, 1000, 1000));
			_ui.addChild(_resizeGrip);
			_resizeGrip.addEventListener(DragGrip.DRAGGED, onResizeGripDragged);
		}

		protected function onResizeGripDragged(e:Event):void{
			_width = _resizeGrip.x + _resizeGrip.width;
			_height = _resizeGrip.y + _resizeGrip.height;
			refreshUI();
		}

		protected function refreshUI():void{
			var g:Graphics = _ui.graphics;
			g.clear();
			g.lineStyle(1, 0x333333, 1);
			g.beginFill(0x000000);
			g.drawRect(0, 0, _width, _height);
			g.endFill();
			
			_resizeGrip.x = _width - _resizeGrip.width;
			_resizeGrip.y = _height - _resizeGrip.height;
		}


	}
}