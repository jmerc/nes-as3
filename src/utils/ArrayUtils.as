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
			var offset:uint;
			var terminus:uint;
			var i:uint;
			if (srcPos < destPos)
			{
				offset = destPos - srcPos;
				terminus = srcPos + length;
				for (i = srcPos; i < terminus; ++i) {
					dest[offset + i] = src[i];
				}
			}
			else
			{
				offset = srcPos - destPos;
				terminus = destPos + length;
				for (i = destPos; i < terminus; ++i) {
					dest[i] = src[offset + i];
				}
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