package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.Font;
	import views.Emulator;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Main extends Sprite 
	{
		
		private var _width:Number;
		private var _height:Number;
		
		private var _emulator:Emulator;
		
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			_width = stage.stageWidth;
			_height = stage.stageHeight;
			
			// Draw stage background
			graphics.beginFill(0x000000);
			
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			var _emulator:Emulator = new Emulator(_width, _height);
			
			this.addChild(_emulator);
		}
		
		public override function get width():Number
		{
			return _width;
		}
		
		public override function get height():Number
		{
			return _height;
		}
		
	}
	
}