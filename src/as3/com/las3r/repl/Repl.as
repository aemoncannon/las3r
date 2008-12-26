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
	import com.las3r.io.*;
	import com.las3r.errors.*;
	import com.las3r.util.ExecHelper;
	import flash.ui.Keyboard;
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.setTimeout;

	public class Repl extends Sprite{

		public static const INITED:String = "inited";

		protected var _width:int;
		protected var _height:int;
		protected var _rt:RT;
		protected var _ui:Sprite;
		protected var _grabButton:Sprite;
		protected var _closeButton:Sprite;
		protected var _resizeGrip:DragGrip;
		protected var _inputField:TextField;
		protected var _outputField:TextField;
		protected var _grabbedListField:TextField;
		protected var _inputHistory:Array = [];
		protected var _inputHistoryPos:int = 0;
		protected var _grabbedObjectVars:Array = [];
		protected var _grabbedCounter:int = 0;

		public function get rt():RT { return _rt }

		public function Repl(w:int, h:int, stage:Stage = null){
			_width = w;
			_height = h;
			var stdout:OutputStream = new OutputStream(function(str:String):void{
					outputText(str);
				});
			var stderr:OutputStream = new OutputStream(function(str:String):void{
					outputError(str);
				});
			_rt = new RT(stage, stdout, stderr);
			createUI();
			refreshUI();
			_inputField.visible = false;
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_rt.addEventListener(LispError.LISP_ERROR, function(e:LispError):void{
					outputError(e);
					e.stopPropagation();
				});


			try{
				_rt.loadStdLib(function(val:*):void{
						outputText("Ready.\n");
						dispatchEvent(new Event(INITED));
						showInput();
					},
					function(i:int, total:int):void{},
					function(error:*):void{
						outputError(error);
					}
				);
				_rt.evalStr("(ctep)");
			}
			catch(e:LispError){
				// Suppress these.. we're already listening for error events.
			}


		}


		public function evalLibrary(str:String, callback:Function = null):void{
			try{
				_rt.evalStr(str, 
					function(val:*):void{
						outputText(" .\n");
						if(callback != null){ callback(); }
					},
					function(i:int, total:int):void{
						outputText(" .");
					},
					function(error:*):void{
						outputError(error);
					}
				);
			}
			catch(e:LispError){
				// Suppress these.. we're already listening for error events.
			}
		}

		protected function showInput():void{
			refreshUI();
			_inputField.visible = true;
			_grabButton.visible = true;
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
			_inputField.selectable = true;
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

			_grabbedListField = new TextField();
			_grabbedListField.defaultTextFormat = tf;
            _grabbedListField.border = true;
            _grabbedListField.borderColor = 0x555555;
            _grabbedListField.background = true;
			_grabbedListField.backgroundColor = 0x222222;
			_grabbedListField.wordWrap = true;
			_grabbedListField.multiline = true;
			_grabbedListField.type = TextFieldType.DYNAMIC;
			_grabbedListField.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void{ e.stopPropagation(); });
			_grabbedListField.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void{ e.stopPropagation(); });
            _ui.addChild(_grabbedListField);

			_grabButton = new Sprite();
			_grabButton.graphics.beginFill(0x00ff00);
			_grabButton.graphics.drawRect(0, 0, 10, 10);
			_grabButton.graphics.endFill();
			_grabButton.buttonMode = true;
			_ui.addChild(_grabButton);
			_grabButton.addEventListener(MouseEvent.MOUSE_UP, onGrabButtonMouseUp);
			_grabButton.visible = false;

			_closeButton = new Sprite();
			_closeButton.graphics.beginFill(0xff0000);
			_closeButton.graphics.drawRect(0, 0, 10, 10);
			_closeButton.graphics.endFill();
			_closeButton.buttonMode = true;
			_ui.addChild(_closeButton);
			_closeButton.addEventListener(MouseEvent.MOUSE_UP, onCloseButtonMouseUp);
		}

		protected function setOutputTextColor(color:uint):void{
			var tf:TextFormat = new TextFormat();
			tf.color = color;
			tf.font = "Arial";
			tf.size = 14;
			tf.indent = 3;
			_outputField.defaultTextFormat = tf;
		}

		protected function onResizeGripDragged(e:Event):void{
			_width = _resizeGrip.x + _resizeGrip.width;
			_height = _resizeGrip.y + _resizeGrip.height;
			refreshUI();
			_outputField.scrollV = _outputField.maxScrollV;
		}

		protected function refreshUI():void{
			var pad:int = 5;
			var targetsListWidth:int = _width * 0.25;
			var inputHeight:int = 40;

			var g:Graphics = _ui.graphics;
			g.clear();
			g.lineStyle(1, 0x333333, 1);
			g.beginFill(0x000000);
			g.drawRect(0, 0, _width, _height);
			g.endFill();
			
			_resizeGrip.x = _width - _resizeGrip.width;
			_resizeGrip.y = _height - _resizeGrip.height;

			_inputField.height = inputHeight;
			_inputField.width = _width - _resizeGrip.width - (2 * pad);
			_inputField.x = pad;
			_inputField.y = _height - inputHeight - pad;

			_grabbedListField.width = targetsListWidth;
			_grabbedListField.height = _height - inputHeight - (3 * pad);
			_grabbedListField.x = _width - (targetsListWidth + pad);
			_grabbedListField.y = pad;

			_outputField.height = _height - inputHeight - (3 * pad);
			_outputField.width = _width - (3 * pad + targetsListWidth);
			_outputField.x = pad;
			_outputField.y = pad;

			_grabButton.x = _grabbedListField.x;
			_grabButton.y = _grabbedListField.y + _grabbedListField.height - _grabButton.height;

			_closeButton.x = _width - _closeButton.width;
			_closeButton.y = 0;


		}

		protected function refreshGrabbedListField():void{
			_grabbedListField.text = "";
			for each(var grabbed:Var in _grabbedObjectVars){
				_grabbedListField.appendText(grabbed.sym.name + " " + grabbed.get() + "\n");
			}
		}

		protected function haveGrabbed(obj:Object):Boolean{
			return _grabbedObjectVars.filter(function(v:Var, i:int, a:Array):Boolean{ return v.get() == obj; }).length > 0;
		}


		protected function onGrabButtonMouseUp(e:Event):void{
			outputText("Click on the stage to select objects..\n");
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void{
					e.stopPropagation();
					stage.removeEventListener(MouseEvent.MOUSE_DOWN, arguments.callee, true);
					var objs:Array = stage.getObjectsUnderPoint(new Point(stage.mouseX, stage.mouseY));
					objs = objs.concat(objs.map(function(ea:*, a, i):*{ return ea.parent; }));
					var newObjs:Array = objs.filter(function(ea:*, i:int, a:Array):Boolean{ 
							return (!(ea is Bitmap) && !(ea is Shape) && !haveGrabbed(ea)); 
						});
					for each(var o:Object in newObjs){
						var name:String = "$" + _grabbedCounter++;
						_grabbedObjectVars.push(Var.internWithRoot(LispNamespace(_rt.CURRENT_NS.get()), _rt.sym1(name), o, true)); 
					}
					outputText("Grabbed " + newObjs.length + " new objects.\n");
					refreshGrabbedListField();
				},
				true
			);
		}

		protected function onCloseButtonMouseUp(e:Event):void{
			if(parent){
				parent.removeChild(this);
			}
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

			outputText("-> " + src + "\n");

			try{
				_rt.evalStr(src, function(val:*):void{ 
						outputText(_rt.printString(val) + "\n"); 
					}, 
					null,
					function(error:*):void{
						outputError(error);
					}
				);
			}
			catch(e:LispError){
				// Suppress these.. we're already listening for error events.
			}

		}

		protected function outputError(e:*):void{
			var str:String;
			if(e is Error){
				str = e.getStackTrace();
			}
			else{
				str = String(e);
			}
			setOutputTextColor(0xFF3333);
			_outputField.appendText("\n" + str + "\n");
			_outputField.scrollV = _outputField.maxScrollV;
			setOutputTextColor(0xFFFFFF);
		}

		protected function outputText(str:String):void{
			_outputField.appendText(str);
			_outputField.scrollV = _outputField.maxScrollV;
		}


	}
}