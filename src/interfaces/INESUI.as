package interfaces 
{
	
	/**
	 * ...
	 * @author John
	 */
	public interface INESUI 
	{
		function updateStatus(value:String):void;
		function writeFrame(buffer:Vector.<uint>):void;
	}
	
}