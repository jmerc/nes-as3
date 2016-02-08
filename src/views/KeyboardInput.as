package views 
{
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import interfaces.IInput;
	/**
	 * ...
	 * @author John
	 */
	public class KeyboardInput extends Input
	{
		private var _player1:Dictionary;
		private var _player2:Dictionary;
		
		private var _eventReceiver:DisplayObject;
		
		public function KeyboardInput(eventReceiver:DisplayObject, player1:Dictionary = null, player2:Dictionary = null) 
		{
			super();
			
			// Default controller configurations
			if (player1 == null)
			{
				_player1 = new Dictionary();
				_player1[Keyboard.LEFT] = Input.KEY_LEFT;
				_player1[Keyboard.RIGHT] = Input.KEY_RIGHT;
				_player1[Keyboard.UP] = Input.KEY_UP;
				_player1[Keyboard.DOWN] = Input.KEY_DOWN;
				_player1[Keyboard.ENTER] = Input.KEY_START;
				_player1[Keyboard.CONTROL] = Input.KEY_SELECT;
				_player1[Keyboard.A] = Input.KEY_A;
				_player1[Keyboard.S] = Input.KEY_B;
			}
			else
			{
				_player1 = player1;  // TODO: Verification?
			}
			
			if (player2 == null)
			{
				_player2 = new Dictionary();
				_player2[Keyboard.NUMBER_4] = Input.KEY_LEFT;
				_player2[Keyboard.NUMBER_6] = Input.KEY_RIGHT;
				_player2[Keyboard.NUMBER_8] = Input.KEY_UP;
				_player2[Keyboard.NUMBER_2] = Input.KEY_DOWN;
				_player2[Keyboard.NUMBER_1] = Input.KEY_START;
				_player2[Keyboard.NUMBER_3] = Input.KEY_SELECT;
				_player2[Keyboard.NUMBER_7] = Input.KEY_A;
				_player2[Keyboard.NUMBER_9] = Input.KEY_B;
			}
			else
			{
				_player2 = player2;
			}
			
			_eventReceiver = eventReceiver;
			_eventReceiver.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			_eventReceiver.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			if (_player1[e.keyCode] != null)
			{
				keyPress(1, _player1[e.keyCode]);
			}
			else if (_player2[e.keyCode] != null)
			{
				keyPress(2, _player2[e.keyCode]);
			}
		}
		
		private function onKeyUp(e:KeyboardEvent):void
		{
			if (_player1[e.keyCode] != null)
			{
				keyRelease(1, _player1[e.keyCode]);
			}
			else if (_player2[e.keyCode] != null)
			{
				keyRelease(2, _player2[e.keyCode]);
			}
		}
		
		
	}

}