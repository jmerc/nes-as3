package utils 
{
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	/**
	 * ...
	 * @author John
	 */
	public class RomLoader 
	{
		private var _fileLoader:URLLoader;
		private var _romData:ByteArray;
		private var _callback:Function;
		
		public function loadFile(fileName:String, callback:Function):void
		{
			_romData = null;
			_callback = callback;
			
			// Read in file
			var fileRequest:URLRequest = new URLRequest(fileName);
			_fileLoader = new URLLoader(fileRequest);
			_fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			_fileLoader.addEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
		}
		
		private function onFileLoaded(e:Event):void
		{
			_fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			var romData:ByteArray = _fileLoader.data;
			
			trace("File Loaded, Size: " + romData.bytesAvailable);
			
			if (_callback != null)
			{
				_callback.apply(null, [romData, ""]);
			}
		}

		private function onFileLoadError(e:Event):void
		{
			_fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			trace("FileLoadError: " + e.type);

			if (_callback != null)
			{
				_callback.apply(null, [null, e.type]);
			}
		}

	}

}