package com.hurlant.eval {
	import flash.display.Loader;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.events.*;
	
	public class ByteLoader {

		private static var loaders:Array = [];
		
		private static var swf_start:Array = 
		[
			0x46, 0x57, 0x53, 0x09, 								// FWS, Version 9
			0xff, 0xff, 0xff, 0xff, 								// File length
			0x78, 0x00, 0x03, 0xe8, 0x00, 0x00, 0x0b, 0xb8, 0x00,	// size [Rect 0 0 8000 6000] 
		 	0x00, 0x0c, 0x01, 0x00, 								// 16bit le frame rate 12, 16bit be frame count 1 
		 	0x44, 0x11,												// Tag type=69 (FileAttributes), length=4  
		 	0x08, 0x00, 0x00, 0x00
		];

		private static var abc_header:Array = 
		[
		 	0x3f, 0x12,												// Tag type=72 (DoABC), length=next.
		 	//0xff, 0xff, 0xff, 0xff 								// ABC length, not included in the copy. 
		];
		
		private static var swf_end:Array =
		// the commented out code tells the player to instance a class "test" as a Sprite.
		[/*0x09, 0x13, 0x01, 0x00, 0x00, 0x00, 0x74, 0x65, 0x73, 0x74, 0x00, */ 
			0x40, 0x00,                                             // Tag type=1 (ShowFrame), length=0
			0x00, 0x00                                              // Tag type=0 (End), length=0 -- ignored by the player, but reuired by the spec (and swfdump).
		];
		
		
		/**
		* Wraps the ABC bytecode inside the simplest possible SWF file, for
		* the purpose of allowing the player VM to load it.
		*  
		* @param bytes: an ABC file
		* @return a SWF file 
		* 
		*/
		public static function wrapInSWF(bytes:Array):ByteArray {
			// wrap our ABC bytecodes in a SWF.
			var out:ByteArray = new ByteArray;
			out.endian = Endian.LITTLE_ENDIAN;
			for (var i:int=0;i<swf_start.length;i++) {
				out.writeByte(swf_start[i]);
			}
			for (i=0;i<bytes.length;i++) {
				var abc:ByteArray = bytes[i];
				for (var j:int=0;j<abc_header.length;j++) {
					out.writeByte(abc_header[j]);
				}
				// set ABC length
				out.writeInt(abc.length);
				out.writeBytes(abc, 0, abc.length);
			}
			for (i=0;i<swf_end.length;i++) {
				out.writeByte(swf_end[i]);
			}
			// set SWF length
			out.position = 4;
			out.writeInt(out.length);
			// reset
			out.position = 0;
			return out;
		}

		/**
		* Load the bytecodes passed into the flash VM, using
		* the current application domain, or a child of it
		*
		* This probably always returns true, even when things fail horribly,
		* due to the Loader logic waiting to parse the bytecodes until the 
		* current script has finished running. 
		* 
		*/
		public static function loadBytes(bytes:*, _callback:Function = null, inplace:Boolean=false):Boolean {
			var callback:Function = _callback || function():void{};
			if (bytes is Array || (getType(bytes) == 2)) {
				if (!(bytes is Array)) {
					bytes = [ bytes ];
				}
				bytes = wrapInSWF(bytes);
			}
			var c:LoaderContext = null;
			if (inplace) {
				c = new LoaderContext(false, ApplicationDomain.currentDomain, null);
				if(Object(c).hasOwnProperty("allowLoadBytesCodeExecution")){
					Object(c).allowLoadBytesCodeExecution = true;
				}
			}
			var l:Loader = new Loader();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{
					l.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);
					loaders.splice(loaders.indexOf(l), 1);
					callback(); 
				});
			l.loadBytes(bytes, c);
			loaders.push(l);
			return true;
		}
		public static function isSWF(data:ByteArray):Boolean {
			var type:int = getType(data);
			return (type&1)==1;
		}
		/**
		* getType.
		* ripped from abcdump.as.
		* 
		* This looks at the array header and decides what it is.
		* 
		* (getType&1)==1 => it's  SWF
		* (getType&2)==2 => it's  ABC
		* (getType&4)==4)=> it's compressed
		*  
		* @param data
		* @return 
		* 
		*/
		public static function getType(data:ByteArray):int {
			data.endian = "littleEndian"
			var version:uint = data.readUnsignedInt()
			switch (version) {
				case 46<<16|14:
				case 46<<16|15:
				case 46<<16|16:
				return 2;
				case 67|87<<8|83<<16|9<<24: // SWC9
				case 67|87<<8|83<<16|8<<24: // SWC8
				case 67|87<<8|83<<16|7<<24: // SWC7
				case 67|87<<8|83<<16|6<<24: // SWC6
				return 5;
				case 70|87<<8|83<<16|9<<24: // SWC9
				case 70|87<<8|83<<16|8<<24: // SWC8
				case 70|87<<8|83<<16|7<<24: // SWC7
				case 70|87<<8|83<<16|6<<24: // SWC6
				case 70|87<<8|83<<16|5<<24: // SWC5
				case 70|87<<8|83<<16|4<<24: // SWC4
				return 1;
				default:
				return 0;
			}
		}
	}
}
