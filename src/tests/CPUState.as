package tests 
{
	import system.CPU;
	import utils.StringUtils;
	
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
			str += value & CPU.NEGATIVE_FLAG ? "N" : "_" ;
			str += value & CPU.OVERFLOW_FLAG ? "V" : "_" ;
			str += value & CPU.UNUSED_FLAG ? "U" : "_" ;
			str += value & CPU.BREAK_FLAG ? "B" : "_" ;
			str += value & CPU.DECIMAL_FLAG ? "D" : "_" ;
			str += value & CPU.IRQ_FLAG ? "I" : "_" ;
			str += value & CPU.ZERO_FLAG ? "Z" : "_" ;
			str += value & CPU.CARRY_FLAG ? "C" : "_" ;
			return str;
		}
	}
	

}