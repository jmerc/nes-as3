package views 
{
	import interfaces.INESUI;
	/**
	 * ...
	 * @author John
	 */
	public class DummyUI implements INESUI
	{
		
		public function DummyUI() 
		{
			
		}
		
		/* INTERFACE interfaces.INESUI */
		
		public function updateStatus(value:String):void 
		{
			trace("Status: " + value);
		}
		
		public function writeFrame(buffer:Vector.<uint>):void 
		{
			
		}
		
	}

}