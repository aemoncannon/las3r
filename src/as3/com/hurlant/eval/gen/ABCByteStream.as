package com.hurlant.eval.gen
{
	import com.hurlant.eval.Util;
	
	import flash.utils.ByteArray;
	
    public class ABCByteStream
    {
        private var bytes:ByteArray;
        // If a ByteArray is passed in, then it is used to construct the ABCByteStream, otherwise a new empty ByteArray is used
        function ABCByteStream (b:ByteArray = null) {
        	bytes = (b!=null? b : new ByteArray )
// Tamarin was fixed so this is always set correctly now... I think
            bytes.endian = "littleEndian";
            bytes.position = 0;
        }

        public function get length():uint {
            return bytes.length;
        }

        public function uint8(val:uint):void {
            Util.assert(val < 256);
            bytes.writeByte (val);
        }

        public function uint16(val:uint):void {
            Util.assert(val < 65536);
            //bytes.push(val & 0xFF,
            //           (val >> 8) & 0xFF);
            bytes.writeByte (val & 0xFF);
            bytes.writeByte ((val >> 8) & 0xFF);
        }

        public function int16(val:int):void {
            Util.assert(-32768 <= val && val < 32768);
            //bytes.push(val & 0xFF,
            //           (val >> 8) & 0xFF);
            bytes.writeByte (val & 0xFF);
            bytes.writeByte ((val >> 8) & 0xFF);
        }

        public function int24(val:int):void {
            Util.assert(-16777216 <= val && val < 16777216);
            //bytes.push(val & 0xFF,
            //           (val >> 8) & 0xFF,
            //           (val >> 16) & 0xFF);
            bytes.writeByte (val & 0xFF);
            bytes.writeByte ((val >> 8) & 0xFF);
            bytes.writeByte ((val >> 16) & 0xFF);
        }

        public function uint30(val:uint):void {
            Util.assert(val < 1073741824);
            uint32(val);
        }

        public function int30(val:int):void {
            Util.assert(-1073741824 <= val && val < 1073741824);
            if (val < 0)
                uint32(-val);
            else
                uint32(uint(val));
        }

        public function int32(val:int):void {
            uint32(uint(val));
        }

        public function uint32(val:uint):void {
            if( val < 0x80 ) {
                // 7 bits
                //bytes.push(val & 0x7F);
                bytes.writeByte (val & 0x7F);
            }
            else if ( val < 0x4000 ) {
                // 14 bits
                //bytes.push((val & 0x7F) | 0x80,
                //           (val >> 7) & 0x7F);
                bytes.writeByte ((val & 0x7F) | 0x80);
                bytes.writeByte ((val >> 7) & 0x7F);
            }
            else if ( val < 0x200000 ) {
                // 21 bits
                //bytes.push((val & 0x7F) | 0x80,
                //           ((val >> 7) & 0x7F) | 0x80,
                //           (val >> 14) & 0x7F);
                bytes.writeByte ((val & 0x7F) | 0x80);
                bytes.writeByte (((val >> 7) & 0x7F) | 0x80);
                bytes.writeByte ((val >> 14) & 0x7F);
            }
            else if ( val < 0x10000000 ) {
                // 28 bits
                //bytes.push((val & 0x7F) | 0x80,
                //           ((val >> 7) & 0x7F) | 0x80,
                //           ((val >> 14) & 0x7F) | 0x80,
                //           (val >> 21) & 0x7F);
                bytes.writeByte ((val & 0x7F) | 0x80);
                bytes.writeByte (((val >> 7) & 0x7F) | 0x80);
                bytes.writeByte (((val >> 14) & 0x7F) | 0x80);
                bytes.writeByte ((val >> 21) & 0x7F);
            }
            else {
                // 32 bits
                //bytes.push((val & 0x7F) | 0x80,
                //           ((val >> 7) & 0x7F) | 0x80,
                //           ((val >> 14) & 0x7F) | 0x80,
                //           ((val >> 21) & 0x7F) | 0x80,
                //           (val >> 28) & 0x7F);
                bytes.writeByte ((val & 0x7F) | 0x80);
                bytes.writeByte (((val >> 7) & 0x7F) | 0x80);
                bytes.writeByte (((val >> 14) & 0x7F) | 0x80);
                bytes.writeByte (((val >> 21) & 0x7F) | 0x80);
                bytes.writeByte ((val >> 28) & 0x7F);
            }
        }

        public function float64(val:Number):void {
            bytes.writeDouble (val);
        }

        public function utf8(str:String):void{
            bytes.writeUTFBytes (str);
        }

        public function setInt24(loc:uint, val:uint):void {
            Util.assert(-16777216 <= val && val < 16777216);
            //bytes[loc] = val & 0xFF;
            //bytes[loc+1] = (val >> 8) & 0xFF;
            //bytes[loc+2] = (val >> 16) & 0xFF;
            var orig_pos:uint = bytes.position;
            bytes.position = loc;
            int24 (val);
            bytes.position = bytes.length;
        }

        public function serialize(s:ABCByteStream):void {
            s.byteStream(this);
        }

        public function byteStream(from:ABCByteStream):void {
            bytes.writeBytes (from.bytes);
            //var from_bytes = from.bytes;
            //for ( var i=0, limit=from_bytes.length ; i < limit ; i++ )
            //    bytes.push(from_bytes[i]);
        }

        /* Returns *some* concrete byte-array type, but the concrete
         * type is not part of the API here.  Clients must be adapted
         * to particular environments anyway.
         */
        public function getBytes(): * {
            return bytes;
        }

        public function getArrayOfBytes ():Array {
            var a:Array = [];
            bytes.position = 0;
            while (bytes.bytesAvailable) {
                a.push (bytes.readByte()&0xff);
            }
            return a;
        }
        
        public function readByte() : uint {
            return bytes.readUnsignedByte();
        }
        
        public function readInt():int {
            return bytes.readInt();
        }

        public function readDouble():Number {
            return bytes.readDouble();
        }
        
        public function readUTFBytes(length:uint):String {
            return bytes.readUTFBytes(length);
        }
        
		public function readU32():int {
			var result:int = bytes.readUnsignedByte();
			if (!(result & 0x00000080))
				return result;
			result = result & 0x0000007f | bytes.readUnsignedByte()<<7;
			if (!(result & 0x00004000))
				return result;
			result = result & 0x00003fff | bytes.readUnsignedByte()<<14;
			if (!(result & 0x00200000))
				return result;
			result = result & 0x001fffff | bytes.readUnsignedByte()<<21;
			if (!(result & 0x10000000))
				return result;
			return   result & 0x0fffffff | bytes.readUnsignedByte()<<28;
		}
        
		public function readS24():uint
		{
			var b:uint = bytes.readUnsignedByte();
            var b1:uint = bytes.readUnsignedByte();
            var b2:uint = bytes.readUnsignedByte();
            
			b = b | (b1<<8);
			b = b | (b2<<16);
			return b
		}

        public function get position():uint {
            return bytes.position;
        }
        public function set position(pos:uint):void {
            bytes.position = pos;
        }
        
        public function get bytesAvailable():uint {
            return bytes.bytesAvailable;
        }
    }
}