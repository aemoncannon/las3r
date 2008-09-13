package com.hurlant.eval.ast
{
    public class Cls {
        public var name //: NAME;
        public var baseName; //: NAME?;
        public var interfaceNames; //: [NAME];
        public var constructor : Constructor;
        public var classHead: Head;
        public var instanceHead: Head;
        public var classType; //: ObjectType;
        public var instanceType; //: InstanceType;
        function Cls (name,baseName,interfaceNames,constructor,classHead,instanceHead
                     ,classType,instanceType) {
            this.name = name;
            this.baseName = baseName;
            this.interfaceNames = interfaceNames;
            this.constructor = constructor;
            this.classHead = classHead;
            this.instanceHead = instanceHead;
            this.classType = classType;
            this.instanceType = instanceType;
		}
    }
}