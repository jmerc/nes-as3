package system 
{
	import flash.net.URLLoader;
	import flash.utils.ByteArray;
	import interfaces.IMapper;
	import system.PPU.Tile;
	/**
	 * ...
	 * @author John
	 */
	public class ROM 
	{
		public static const HORIZONTAL_MIRRORING:uint = 0;
		public static const VERTICAL_MIRRORING:uint = 1;
		public static const FOURSCREEN_MIRRORING:uint = 2;
		public static const SINGLESCREEN_MIRRORING:uint = 3;
		public static const SINGLESCREEN_MIRRORING2:uint = 4;
		public static const SINGLESCREEN_MIRRORING3:uint = 5;
		public static const SINGLESCREEN_MIRRORING4:uint = 6;
		public static const CHRROM_MIRRORING:uint = 7;

		
		private var nes:NES;
		
		private var mapperName:Vector.<String>;
    
		private var header:Vector.<uint>;
		public var rom:Vector.<Vector.<uint>>;
		public var vrom:Vector.<Vector.<uint>>;
		public var vromTile:Vector.<Vector.<Tile>>;
		public var romCount:uint;
		public var vromCount:uint;
		private var mirroring:uint;
		public var hasBatteryRam:Boolean;
		private var trainer:Boolean;
		private var fourScreen:Boolean;
		private var mapperType:uint;
		public var valid:Boolean = false;
		
		public function ROM(nes:NES)
		{
			this.nes = nes;
    
			mapperName = new Vector.<String>(92);
			
			for (var i:uint=0;i<92;i++) {
				mapperName[i] = "Unknown Mapper";
			}
			mapperName[ 0] = "Direct Access";
			mapperName[ 1] = "Nintendo MMC1";
			mapperName[ 2] = "UNROM";
			mapperName[ 3] = "CNROM";
			mapperName[ 4] = "Nintendo MMC3";
			mapperName[ 5] = "Nintendo MMC5";
			mapperName[ 6] = "FFE F4xxx";
			mapperName[ 7] = "AOROM";
			mapperName[ 8] = "FFE F3xxx";
			mapperName[ 9] = "Nintendo MMC2";
			mapperName[10] = "Nintendo MMC4";
			mapperName[11] = "Color Dreams Chip";
			mapperName[12] = "FFE F6xxx";
			mapperName[15] = "100-in-1 switch";
			mapperName[16] = "Bandai chip";
			mapperName[17] = "FFE F8xxx";
			mapperName[18] = "Jaleco SS8806 chip";
			mapperName[19] = "Namcot 106 chip";
			mapperName[20] = "Famicom Disk System";
			mapperName[21] = "Konami VRC4a";
			mapperName[22] = "Konami VRC2a";
			mapperName[23] = "Konami VRC2a";
			mapperName[24] = "Konami VRC6";
			mapperName[25] = "Konami VRC4b";
			mapperName[32] = "Irem G-101 chip";
			mapperName[33] = "Taito TC0190/TC0350";
			mapperName[34] = "32kB ROM switch";
			
			mapperName[64] = "Tengen RAMBO-1 chip";
			mapperName[65] = "Irem H-3001 chip";
			mapperName[66] = "GNROM switch";
			mapperName[67] = "SunSoft3 chip";
			mapperName[68] = "SunSoft4 chip";
			mapperName[69] = "SunSoft5 FME-7 chip";
			mapperName[71] = "Camerica chip";
			mapperName[78] = "Irem 74HC161/32-based";
			mapperName[91] = "Pirate HK-SF3 chip";
		}

		public function load(data:ByteArray):void
		{
			var i:uint, j:uint, v:uint;
		
			valid = false;  // false until proven true
			
			if (data.length < 16)
			{
				nes.ui.updateStatus("Not a valid NES ROM (Invalid length).");
				return;
			}
			
			// Load 16 bytes into the header
			header = new Vector.<uint>(16);
			for (i = 0; i < 16; i++)
			{
				header[i] = data.readByte() & 0xFF;
				// TODO: Byte is returned as -128 to 127, is this enough to correctly convert it?
			}
			// Check for sentinel
			if (header[0] != 0x4E || header[1] != 0x45 || header[2] != 0x53 || header[3] != 0x1A)
			{
				nes.ui.updateStatus("Not a valid NES ROM (Invalid Header Tag).");
				return;
			}
			
			
			romCount = header[4];
			vromCount = header[5]*2; // Get the number of 4kB banks, not 8kB
			mirroring = ((header[6] & 1) !== 0 ? 1 : 0);
			hasBatteryRam = (header[6] & 2) !== 0;
			trainer = (header[6] & 4) !== 0;
			fourScreen = (header[6] & 8) !== 0;
			mapperType = (header[6] >> 4) | (header[7] & 0xF0);
			/* TODO
			if (batteryRam)
				loadBatteryRam();*/
			// Check whether byte 8-15 are zero's:
			var foundError:Boolean = false;
			for (i=8; i<16; i++) {
				if (header[i] !== 0) {
					foundError = true;
					break;
				}
			}
			if (foundError) {
				mapperType &= 0xF; // Ignore byte 7
			}
			// Load PRG-ROM banks:
			rom = new Vector.<Vector.<uint>>(romCount);
			var offset:uint = 16;
			for (i=0; i < romCount; i++) {
				rom[i] = new Vector.<uint>(16384);
				data.position = offset;
				for (j=0; j < 16384; j++) {
					if (offset+j >= data.length) {
						break;
					}
					rom[i][j] = data.readByte() & 0xFF;
				}
				offset += 16384;
			}
			// Load CHR-ROM banks:
			vrom = new Vector.<Vector.<uint>>(vromCount);
			for (i=0; i < vromCount; i++) {
				vrom[i] = new Vector.<uint>(4096);
				data.position = offset;
				for (j=0; j < 4096; j++) {
					if (offset+j >= data.length){
						break;
					}
					vrom[i][j] = data.readByte() & 0xFF;
				}
				offset += 4096;
			}
			
			// Create VROM tiles:
			vromTile = new Vector.<Vector.<Tile>>(vromCount);
			for (i=0; i < vromCount; i++) {
				vromTile[i] = new Vector.<Tile>(256);
				for (j=0; j < 256; j++) {
					vromTile[i][j] = new Tile();
				}
			}
			
			// Convert CHR-ROM banks to tiles:
			var tileIndex:uint;
			var leftOver:uint;
			for (v=0; v < vromCount; v++) {
				for (i=0; i < 4096; i++) {
					tileIndex = i >> 4;
					leftOver = i % 16;
					if (leftOver < 8) {
						vromTile[v][tileIndex].setScanline(
							leftOver,
							vrom[v][i],
							vrom[v][i+8]
						);
					}
					else {
						vromTile[v][tileIndex].setScanline(
							leftOver-8,
							vrom[v][i-8],
							vrom[v][i]
						);
					}
				}
			}
			
			valid = true;
		}
		
		
		public function getMirroringType():uint
		{
			if (fourScreen) {
				return FOURSCREEN_MIRRORING;
			}
			if (mirroring === 0) {
				return HORIZONTAL_MIRRORING;
			}
			return VERTICAL_MIRRORING;
		}
		
		private function getMapperName():String
		{
			if (mapperType >= 0 && mapperType < mapperName.length) {
				return mapperName[mapperType];
			}
			return "Unknown Mapper, "+mapperType;
		}
		
		private function mapperSupported():Boolean
		{
			return MapperFactory.mapperSupported(mapperType);
		}
		
		public function createMapper():IMapper
		{
			if (mapperSupported()) {
				return MapperFactory.createMapper(mapperType, nes);
			}
			else {
				nes.ui.updateStatus("This ROM uses a mapper not supported by JSNES: "+getMapperName()+"("+mapperType+")");
				return null;
			}
		}		
			
	}
}