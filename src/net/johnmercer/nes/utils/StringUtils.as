package net.johnmercer.nes.utils 
{
	/**
	 * ...
	 * @author ...
	 */
	public class StringUtils 
	{		
		public static function hexToStr(value:uint, width:int = 2):String 
		{
			var ret:String;
			if (width == 2)
			{
				ret = (value).toString(16);
			}
			else if (width == 4)
			{
				ret = (value).toString(16);				
			}
			else
			{
				ret = value.toString(16);				
			}
			while( ret.length < width )
				ret="0" + ret;
			return ret.toUpperCase();
		}		
		

		
	}

}