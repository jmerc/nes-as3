package net.johnmercer.nes.tests 
{
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
		public var SL:uint;
		public var error:Boolean = false;
		
		public function toString():String
		{
			return StringUtils.hexToStr(address, 4) + "  " + 
					StringUtils.hexToStr(opcode) + " " + 
					(param1 == int.MAX_VALUE ? "  ":StringUtils.hexToStr(param1)) + " " + 
					(param2 == int.MAX_VALUE ? "  ":StringUtils.hexToStr(param2)) + "  " +
					StringUtils.hexToStr(A) + "," + StringUtils.hexToStr(X) + "," + 
					StringUtils.hexToStr(Y) + "," + StringUtils.hexToStr(P) + "," +
					StringUtils.hexToStr(SP) + " " + CYC + "," + SL;
		}
	}
	

}