package gui {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import vk.VK;
	
	/**
	 * ...
	 * @author Gleb Klimov, http://vk.com/klgleb
	 */
	public class DownloadButton extends Sprite {
		private var _url:String;
		private var _title:String;
		
		private var _btn_download:*;
		
		private var file:FileReference;
		
		public function DownloadButton(url:String, title:String) {
			_url = url;
			_title = title;
			_init();
		}
		
		private function _init(e:* = null):void {
			_btn_download = VK.createLinkButton("Скачать", 0, 0);
			_btn_download.addEventListener(MouseEvent.CLICK, _onDownloadClick);
			addChild(_btn_download);
			
		}
		
		private function _onDownloadClick(e:MouseEvent):void {
			
			_loading = 0;
			
			file = new FileReference();			
			file.addEventListener(ProgressEvent.PROGRESS, _progressHandler);
			file.addEventListener(Event.COMPLETE, _completeHandler);
			file.addEventListener(Event.CANCEL, _onComplete);
			file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _onError);
			file.addEventListener(IOErrorEvent.IO_ERROR, _onError);
			
			file.download(new URLRequest(_url), _title + ".mp3");
		}
		
		private function _onError(e:Event = null):void {
			_loading = 0;
			VK.Utils.rect(this, 0, 0, _btn_download.width, _btn_download.height, 0xFFCBC9, 0xFF7C7C);
			var txt:* = VK.addText("Ошибка", 0, 0, 0x000000);
			txt.x = width / 2 - txt.width / 2;
			addChild(txt);
			
			var t:Timer = new Timer(3000, 1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, 
				function(e:TimerEvent):void {
					if (txt.parent) removeChild(txt);
					txt = null;
					_onComplete();
				}
			);
			
			t.start();
		}
		
		private function _completeHandler(e:Event):void {
			var txt:* = VK.addText("Готово", 0, 0, 0xFFFFFF);
			txt.x = width / 2 - txt.width / 2;
			addChild(txt);
			
			var t:Timer = new Timer(1000, 1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, 
				function(e:TimerEvent):void {
					if (txt.parent) removeChild(txt);
					txt = null;
					_onComplete();
				}
			);
			t.start();
		}
		
		private function _onComplete(e:* = null):void {
			_loading = -1
		}
		
		private function _progressHandler(event:ProgressEvent):void {
			_loading = event.bytesLoaded / event.bytesTotal;
		}
		
		private function set _loading(v:Number):void {
			if (v < 0 ) {
				this.graphics.clear();
				_btn_download.visible = true;
				return;
			} else {
				_btn_download.visible = false;
			}
			v = Math.max(0, Math.min(1, v));
			
			VK.Utils.rect(this, 0, 0, _btn_download.width, _btn_download.height, VK.Utils.ARROW_BG_COL, VK.Utils.BORDER_COL);
			VK.Utils.fillRect(this, 0, 0, _btn_download.width * v, _btn_download.height, VK.Utils.BLUE_TXT_COL);
			
		}
		
	}

}