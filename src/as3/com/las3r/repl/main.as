/*   
*   Copyright (c) Aemon Cannon. All rights reserved.
*   The use and distribution terms for this software are covered by the
*   Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
*   which can be found in the file CPL.TXT at the root of this distribution.
*   By using this software in any fashion, you are agreeing to be bound by
* 	the terms of this license.
*   You must not remove this notice, or any other, from this software.
*/


import flash.display.*;
import flash.events.*;
import flash.external.*;
import flash.utils.*;
import com.hurlant.eval.ByteLoader;
import com.hurlant.eval.Evaluator;
import com.hurlant.eval.Debug;
import com.hurlant.eval.dump.ABCDump;
import com.las3r.jdk.io.*;
import com.las3r.runtime.RT;
import com.las3r.runtime.LispReader;
import com.las3r.runtime.Compiler;

private var _inputHistory:Array = [];
private var _inputHistoryPos:int = 0;
private var _rt:RT;


private function onCreationComplete():void {
	_rt = new RT();
	_rt.loadStdLib();

	_rt.traceFunc = function(str:String):void{
		outputArea.text += str + "\n";
		outputArea.verticalScrollPosition = outputArea.maxVerticalScrollPosition
	}

	_rt.debugFunc = function(str:String):void{
		debugArea.text += str + "\n";
		debugArea.verticalScrollPosition = debugArea.maxVerticalScrollPosition
	}

	replInput.addEventListener(TextEvent.TEXT_INPUT, onReplInputTextInput, true);
	replInput.addEventListener(KeyboardEvent.KEY_DOWN, onReplInputKeyDown, true);
}

private function onReplInputTextInput(e:TextEvent):void{
    switch (e.text) {
        case "\n" :
		onEvalButtonClick(null);
		e.stopPropagation();
		e.preventDefault();
		break;
	}
}

private function onReplInputKeyDown(e:KeyboardEvent):void{
	var key:uint = e.keyCode;
    switch (key) {
        case Keyboard.UP :
 		_inputHistoryPos = _inputHistoryPos - 1 + (_inputHistoryPos == 0 ? _inputHistory.length : 0);
 		replInput.text = _inputHistory[_inputHistoryPos];
 		break;

        case Keyboard.DOWN :
 		_inputHistoryPos = (_inputHistoryPos + 1) % _inputHistory.length;
 		replInput.text = _inputHistory[_inputHistoryPos];
 		break;
	}
}


private function onEvalButtonClick(e:Event):void{
	var src:String = replInput.text;
	replInput.text = "";

	_inputHistory.push(src);
	_inputHistoryPos = _inputHistory.length;

	_rt.evalStr(src, function(val:*):void{ _rt.traceOut(RT.printToString(val)); });

}