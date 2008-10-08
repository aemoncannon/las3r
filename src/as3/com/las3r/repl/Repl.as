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
	import com.las3r.util.ExecHelper;
	import flash.ui.Keyboard;
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.setTimeout;

	public class Repl extends Sprite{

		protected var _width:int;
		protected var _height:int;
		protected var _rt:RT;
		protected var _ui:Sprite;
		protected var _resizeGrip:DragGrip;
		protected var _inputField:TextField;
		protected var _outputField:TextField;
		protected var _inputHistory:Array = [];
		protected var _inputHistoryPos:int = 0;

		public function Repl(w:int, h:int, stage:Stage = null){
			_width = w;
			_height = h;
			_rt = new RT(stage);
			createUI();
			refreshUI();
			_inputField.visible = false;
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_rt.traceFunc = function(str:String):void{
				_outputField.appendText(str);
				_outputField.scrollV = _outputField.maxScrollV;
			}
			init();
		}

		public function init(toEval:String = null):void{
			_rt.traceFunc("Compiling forms:\n");
			_rt.loadStdLib(function(val:*):void{
					if(toEval){
						_rt.evalStr(toEval, function(val:*):void{
								showInput();
							});
					}
					else{
						showInput();
					}
				},
				function(i:int, total:int):void{
					if(i == total){_rt.traceFunc(".\n"); }
					else{ _rt.traceFunc("."); }
				}
			);
		}

		protected function showInput():void{
			refreshUI();
			_inputField.visible = true;
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
			_resizeGrip.addEventListener(DragGrip.DRAGGED, onResizeGripDragged);
			_ui.addChild(_resizeGrip);


			var tf:TextFormat = new TextFormat();
			tf.color = 0xFFFFFF;
			tf.font = "Arial";
			tf.size = 14;
			tf.indent = 3;
			_inputField = new TextField();
			_inputField.defaultTextFormat = tf;
            _inputField.border = true;
            _inputField.borderColor = 0x555555;
            _inputField.background = true;
			_inputField.backgroundColor = 0x222222;
			_inputField.wordWrap = true;
			_inputField.multiline = true;
			_inputField.type = TextFieldType.INPUT;
			_inputField.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void{ e.stopPropagation(); });
			_inputField.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void{ e.stopPropagation(); });
			_inputField.addEventListener(TextEvent.TEXT_INPUT, onInputTextInput);
			_inputField.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown);
            _ui.addChild(_inputField);

			_outputField = new TextField();
			_outputField.defaultTextFormat = tf;
            _outputField.border = true;
            _outputField.borderColor = 0x555555;
            _outputField.background = true;
			_outputField.backgroundColor = 0x222222;
			_outputField.wordWrap = true;
			_outputField.multiline = true;
			_outputField.type = TextFieldType.DYNAMIC;
			_outputField.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void{ e.stopPropagation(); });
			_outputField.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void{ e.stopPropagation(); });
            _ui.addChild(_outputField);
		}

		protected function onResizeGripDragged(e:Event):void{
			_width = _resizeGrip.x + _resizeGrip.width;
			_height = _resizeGrip.y + _resizeGrip.height;
			refreshUI();
			_outputField.scrollV = _outputField.maxScrollV;
		}

		protected function refreshUI():void{
			var pad:int = 5;

			var g:Graphics = _ui.graphics;
			g.clear();
			g.lineStyle(1, 0x333333, 1);
			g.beginFill(0x000000);
			g.drawRect(0, 0, _width, _height);
			g.endFill();
			
			_resizeGrip.x = _width - _resizeGrip.width;
			_resizeGrip.y = _height - _resizeGrip.height;

			var inputHeight:int = 40;
			_inputField.height = inputHeight;
			_inputField.width = _width - _resizeGrip.width - (2 * pad);
			_inputField.x = pad;
			_inputField.y = _height - inputHeight - pad;

			_outputField.height = _height - inputHeight - (3 * pad);
			_outputField.width = _width - (2 * pad);
			_outputField.x = pad;
			_outputField.y = pad;
		}

		protected function onInputTextInput(e:TextEvent):void{
			switch (e.text) {
				case "\n" :
				evalCurrentInput();
				e.stopPropagation();
				e.preventDefault();
				break;
			}
		}

		protected function onInputKeyDown(e:KeyboardEvent):void{
			var key:uint = e.keyCode;
			switch (key) {
				case Keyboard.UP :
 				_inputHistoryPos = _inputHistoryPos - 1 + (_inputHistoryPos == 0 ? _inputHistory.length : 0);
 				_inputField.text = _inputHistory[_inputHistoryPos] || "";
 				break;

				case Keyboard.DOWN :
 				_inputHistoryPos = (_inputHistoryPos + 1) % _inputHistory.length;
 				_inputField.text = _inputHistory[_inputHistoryPos] || "";
 				break;
				
			}
		}


		protected function evalCurrentInput():void{
			var src:String = _inputField.text;
			_inputField.text = "";

			_inputHistory.push(src);
			_inputHistoryPos = _inputHistory.length;

			_rt.evalStr(src, function(val:*):void{ 
					_rt.traceOut(_rt.printToString(val) + "\n"); 
				});
		}


	}
}