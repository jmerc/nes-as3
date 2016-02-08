package utils 
{
	/**
	 * ...
	 * @author John
	 */
	public class ArrayUtils 
	{
		static public function copyArrayElements(src:*, srcPos:uint, dest:*, destPos:uint, length:uint):void
		{
			for (var i:uint = 0; i < length; ++i) {
				dest[destPos + i] = src[srcPos + i];
			}
		}

		static public function copyArray(src:Array):Array
		{
			var dest:Array = new Array(src.length);
			
			for (var i:uint = 0; i < src.length; i++) {
				dest[i] = src[i];
			}
			return dest;
		}
	}

}