package net.johnmercer.nes.tests 
{
	import net.johnmercer.nes.system.CPU;
	import net.johnmercer.nes.utils.StringUtils;
	/**
	 * ...
	 * @author ...
	 */
	public class CPUState 
	{
		public var address:uint;
		public var opcode:uint;
		public var param1:uint;
		public var param2:uint;
		public var A:uint;
		public var X:uint;
		public var Y:uint;
		public var P:uint;
		public var SP:uint;
		public var CYC:uint;
		public var SL:int;
		public var error:Boolean = false;
		public var value:uint;
		
		public function toString():String
		{
			return StringUtils.hexToStr(address, 4) + "  " + 
					StringUtils.hexToStr(opcode) + " " + 
					(param1 == int.MAX_VALUE ? "  ":StringUtils.hexToStr(param1)) + " " + 
					(param2 == int.MAX_VALUE ? "  ":StringUtils.hexToStr(param2)) + "  " +
					StringUtils.hexToStr(A) + "," + StringUtils.hexToStr(X) + "," + 
					StringUtils.hexToStr(Y) + "," + StringUtils.hexToStr(P) + "(" + flagsToStr(P) + ")" + "," +
					StringUtils.hexToStr(SP) + " " + CYC + "," + SL;
		}
		
		private function flagsToStr(value:uint):String
		{
			var str:String = "";
			if (value & CPU.NEGATIVE_FLAG) str += "N";
			if (value & CPU.OVERFLOW_FLAG) str += "V";
			if (value & CPU.UNUSED_FLAG) str += "U";
			if (value & CPU.BREAK_FLAG) str += "B";
			if (value & CPU.DECIMAL_FLAG) str += "D";
			if (value & CPU.IRQ_FLAG) str += "I";
			if (value & CPU.ZERO_FLAG) str += "Z";
			if (value & CPU.CARRY_FLAG) str += "C";
			return str;
		}
	}
	

}