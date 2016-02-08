package utils 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author ...
	 */
	public class Debug 
	{		
		static public function dumpByteArray(ba:ByteArray, startPos:uint,  len:uint):String
		{
			var position:uint = ba.position;
			ba.position = startPos;
			var str:String = "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n";
			str += "===============================================\n";
			while (ba.position < (startPos + len))
			{
				for (var j:int = 0; j < 16; j++)
				{
					var value:uint = ba.readUnsignedByte();
					if (value < 16)
						str += 0;
					str += value.toString(16);
					str += " ";
				}
				str += "\n";				
			}
			ba.position = position;
			trace(str);
			return str;		
		}
	}

}