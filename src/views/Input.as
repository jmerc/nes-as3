package views 
{
	import interfaces.IInput;
	/**
	 * ...
	 * @author John
	 */
	public class Input implements IInput
	{
		public static const KEY_PRESS:int = 0x41;
		public static const KEY_RELEASE:int = 0x40;
		
		public static const KEY_A:int = 0;
		public static const KEY_B:int = 1;
		public static const KEY_SELECT:int = 2;
		public static const KEY_START:int = 3;
		public static const KEY_UP:int = 4;
		public static const KEY_DOWN:int = 5;
		public static const KEY_LEFT:int = 6;
		public static const KEY_RIGHT:int = 7;
		
		protected var _state1:Array;
		protected var _state2:Array;
		
		public function Input() 
		{
			_state1 = new Array(8);
			for (var i:int = 0; i < _state1.length; i++)
			{
				state1[i] = KEY_RELEASE;
			}
			
			_state2 = new Array(8);
			for (i = 0; i < _state2.length; i++)
			{
				_state2[i] = KEY_RELEASE;
			}
		}
		
		protected function keyPress(controller:uint, key:uint):void
		{
			if (key > 7) { return; }  // Invalid key
			
			if (controller == 1)
			{
				_state1[key] = KEY_PRESS;
			}
			else if (controller == 2)
			{
				_state2[key] = KEY_PRESS;
			}
		}
		
		protected function keyRelease(controller:uint, key:uint):void
		{
			if (key > 7) { return; }  // Invalid Key
			if (controller == 1)
			{
				_state1[key] = KEY_RELEASE;
			}
			else if (controller == 2)
			{
				_state2[key] = KEY_RELEASE;
			}
		}
		
		/* INTERFACE interfaces.IInput */
		
		public function get state1():Array 
		{
			return _state1;
		}
		
		public function get state2():Array 
		{
			return _state2;
		}
		
	}

}