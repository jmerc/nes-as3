package interfaces 
{
	
	/**
	 * ...
	 * @author John
	 */
	public interface IMapper 
	{
		function reset():void;
		
		function load(addr:uint):uint;
		
		function write(addr:uint, value:uint):void;
		
		function clockIrqCounter():void;
		
		function latchAccess(addr:uint):void;
		
		function loadROM():void;
	}
	
}