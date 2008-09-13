package com.hurlant.eval.abc
{
	import com.hurlant.eval.gen.ABCByteStream;
	import com.hurlant.eval.gen.AVM2Assembler;
	
	public class Abc
	{
	    // Construct an ABCFile instance from a bytestream representing an abc block.
	    public static function parseAbcFile(b : ABCByteStream) : ABCFile {
			b.position = 0;
			var magic = b.readInt();
	        
			if (magic != (46<<16|16))
				throw new Error("not an abc file.  magic=" + magic.toString(16));
	        
	        var abc : ABCFile = new ABCFile();
	
	        abc.constants = parseCpool(b);
	        
	        var i;
	        var n;
	        // MethodInfos
	        n = b.readU32();
	        for(i = 0; i < n; i++)
	        {
	            abc.addMethod(parseMethodInfo(b));
	        }
	
	        // MetaDataInfos
	        n = b.readU32();
	        for(i = 0; i < n; i++)
	        {
	            abc.addMetadata(parseMetadataInfo(b));
	        }
	
	        // InstanceInfos
	        n = b.readU32();
	        for(i = 0; i < n; i++)
	        {
	            abc.addInstance(parseInstanceInfo(b));
	        }
	        // ClassInfos
	        for(i = 0; i < n; i++)
	        {
	            abc.addClass(parseClassInfo(b));
	        }
	
	        // ScriptInfos
	        n = b.readU32();
	        for(i = 0; i < n; i++)
	        {
	            abc.addScript(parseScriptInfo(b));
	        }
	
	        // MethodBodies
	        n = b.readU32();
	        for(i = 0; i < n; i++)
	        {
	            abc.addMethodBody(parseMethodBody(b));
	        }
	
	
	        return abc;            
	    }
	
	    public static function parseCpool(b : ABCByteStream) : ABCConstantPool {
	        var i:int;
	        var n:int;
	        
	        var pool : ABCConstantPool = new ABCConstantPool;
	        
			// ints
			n = b.readU32();
			for (i=1; i < n; i++)
				pool.int32(b.readU32());
	        
			// uints
			n = b.readU32();
			for (i=1; i < n; i++)
				pool.uint32(uint(b.readU32()));
	        
			// doubles
			n = b.readU32();
			//doubles = [NaN];
			for (i=1; i < n; i++)
				pool.float64(b.readDouble());
	
	        // strings
			n = b.readU32();
			for (i=1; i < n; i++)
				pool.stringUtf8(b.readUTFBytes(b.readU32()));
	        
			// namespaces
			n = b.readU32()
			for (i=1; i < n; i++)
	        {
	            var nskind = b.readByte();
	            var uri = b.readU32();
	            pool.namespace(nskind, uri);
	        }
	        
			// namespace sets
			n = b.readU32();
			for (i=1; i < n; i++)
			{
				var count:int = b.readU32();
				var nsset = [];
				for (var j=0; j < count; j++)
					nsset[j] = b.readU32();
	            pool.namespaceset(nsset);
			}
	        
			// multinames
			n = b.readU32()
			for (i=1; i < n; i++)
	        {
	            var kind = b.readByte();
				switch (kind)
				{
				case AVM2Assembler.CONSTANT_QName:
				case AVM2Assembler.CONSTANT_QNameA:
					pool.QName(b.readU32(), b.readU32(), kind==AVM2Assembler.CONSTANT_QNameA)
					break;
				
				case AVM2Assembler.CONSTANT_RTQName:
				case AVM2Assembler.CONSTANT_RTQNameA:
					pool.RTQName(b.readU32(), kind==AVM2Assembler.CONSTANT_RTQNameA)
					break;
				
				case AVM2Assembler.CONSTANT_RTQNameL:
				case AVM2Assembler.CONSTANT_RTQNameLA:
	                pool.RTQNameL(kind==AVM2Assembler.CONSTANT_RTQNameLA);
					//names[i] = null
					break;
				
				case AVM2Assembler.CONSTANT_Multiname:
				case AVM2Assembler.CONSTANT_MultinameA:
					var name = b.readU32()
	                pool.Multiname(b.readU32(), name, kind==AVM2Assembler.CONSTANT_MultinameA);
					break;
	
				case AVM2Assembler.CONSTANT_MultinameL:
				case AVM2Assembler.CONSTANT_MultinameLA:
					pool.MultinameL(b.readU32(), kind==AVM2Assembler.CONSTANT_MultinameLA)
					break;
					
				}
	        }
	        
	        return pool;
	    }
	
	    public static function parseMethodInfo(b : ABCByteStream) : ABCMethodInfo {
	        
	        var paramcount = b.readU32();
	        var returntype = b.readU32();
	        var params = [];
	        for(var i = 0; i < paramcount; ++i)
	        {
	            params[i] = b.readU32();
	        }
	        
	        var name = b.readU32();
	        var flags = b.readByte();
	        
	        var optionalcount = 0;
	        var optionals = null;
	        if( flags & AVM2Assembler.METHOD_HasOptional )
	        {
	            optionalcount = b.readU32();
	            optionals = [];
	            for(var i = 0; i < optionalcount; ++i )
	            {
	                optionals[i] = [b.readU32(), b.readByte()];
	            }
	        }
	        
	        var paramnames = null;
	        if( flags & AVM2Assembler.METHOD_HasParamNames )
	        {
	            paramnames=[];
	            for(var i = 0; i < paramcount; ++i)
	                paramnames[i] = b.readU32();
	        }    
	        
	        return new ABCMethodInfo(name, params, returntype, flags, optionals, paramnames);
	    }
	    
	    public static function parseMetadataInfo(b : ABCByteStream) : ABCMetadataInfo {
	        var name = b.readU32();
	        var itemcount = b.readU32();
	        
	        var items = [];
	        for( var i = 0; i < itemcount; i++ )
	        {
	            var key = b.readU32();
	            var value = b.readU32();
	            items[i] = { key:key, value:value };
	        }
	        
	        return new ABCMetadataInfo(name, items);
	        
	    }
	    
	    public static function parseInstanceInfo(b : ABCByteStream) : ABCInstanceInfo {
	        var name = b.readU32();
	        var superclass = b.readU32();
	        var flags = b.readByte();
	        var protectedNS = 0;
	        if( flags & 8 ) 
	            protectedNS = b.readU32();
	        
	        var interfacecount = b.readU32();
	        var interfaces = [];
	        for(var i = 0; i < interfacecount; ++i)
	        {
	            interfaces[i] = b.readU32();
	        }
	        var iinit = b.readU32();
	        
	        var instance_info = new ABCInstanceInfo(name, superclass, flags, protectedNS, interfaces);
	        
	        instance_info.setIInit(iinit);
	        
	        parseTraits(instance_info, b);
	        
	        return instance_info;
	    }
	    
	    public static function parseClassInfo(b : ABCByteStream) : ABCClassInfo {
	        var cinit = b.readU32();
	
	        var class_info = new ABCClassInfo();
	        class_info.cinit = cinit;
	        
	        parseTraits(class_info, b);
	        
	        return class_info;
	    }
	    
	    public static function parseScriptInfo(b : ABCByteStream) : ABCScriptInfo {
	        
	        var script = new ABCScriptInfo(b.readU32());
	        parseTraits(script, b);
	        return script;
	    }
	    
	    public static function parseMethodBody(b : ABCByteStream) : ABCMethodBodyInfo {
	        var mb:ABCMethodBodyInfo = new ABCMethodBodyInfo(b.readU32());
	        
	        mb.max_stack = b.readU32();
	        mb.local_count = b.readU32();
	        mb.init_scope_depth = b.readU32();
	        mb.max_scope_depth = b.readU32();
	        
	        var code_len = b.readU32();
	        mb.code = new ABCByteStream;
	        for(var i = 0; i < code_len; ++i)
	        {
	            mb.code.uint8(b.readByte());
	        }
	        
	        var excount = b.readU32();
	        for( var i = 0; i < excount; ++i )
	        {
	            mb.addException(parseException(b));
	        }
	        
	        parseTraits(mb, b);
	        
	        return mb;
	    }
	    
	    public static function parseException(b : ABCByteStream) : ABCException {
	        var start = b.readU32();
	        var end = b.readU32();
	        var target = b.readU32();
	        var typename = b.readU32();
	        var name = b.readU32();
	        
	        // WTF is wrong with this????
	        var ex;
	        ex = new ABCException(start, end, target, typename, name);
	        return ex;
	    }
	    
	    public static function parseTraits(target, b : ABCByteStream) {
	        var traitcount = b.readU32();
	        for(var i =0 ; i < traitcount; ++i)
	        {
	            target.addTrait(parseTrait(b));
	        }
	    }
	
	    public static function parseTrait(b : ABCByteStream) //: ABCTrait should be ABCTrait once inheritance is supported
	    {
	        var name = b.readU32();
	        
	        var tag = b.readByte();
	        var kind = tag&0x04;
	        var attrs = (tag>>4) & 0x04;
	        
	        var trait;
	        
	        switch(kind)
	        {
	            case AVM2Assembler.TRAIT_Slot:
	            case AVM2Assembler.TRAIT_Const:
	                var slotid = b.readU32();
	                var typename = b.readU32();
	                var value = b.readU32();
	                var kind = null;
	                if( value != 0 )
	                    kind = b.readByte();
	                trait = new ABCSlotTrait(name, attrs, kind==AVM2Assembler.TRAIT_Const, slotid, typename, value, kind);
	                break;
	            case AVM2Assembler.TRAIT_Method:
	            case AVM2Assembler.TRAIT_Setter:
	            case AVM2Assembler.TRAIT_Getter:
	                var dispid = b.readU32();
	                var methinfo = b.readU32();
	                trait = new ABCOtherTrait(name, attrs, kind, dispid, methinfo);
	                break;
	            case AVM2Assembler.TRAIT_Class:
	                var slotid = b.readU32();
	                var classinfo = b.readU32();
	                trait = new ABCOtherTrait(name, attrs, kind, slotid, classinfo);
	                break;
	        }
	        
	        if( attrs & AVM2Assembler.ATTR_Metadata )
	        {
	            var metadatacount = b.readU32();
	            for(var i = 0; i < metadatacount; ++i)
	            {
	                trait.addMetadata(b.readU32());
	            }
	        }
	        
	        return trait;
	    }

	}
}