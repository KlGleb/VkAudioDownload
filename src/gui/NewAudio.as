package gui
{
  import flash.display.Sprite;
  import flash.events.*;
  import flash.net.FileFilter;
  import flash.net.FileReference;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLRequestHeader;
  import locale.Loc;

  import vk.VK;

  /**
   * @author Alexey Kharkov
   */
  public class NewAudio extends Sprite
  {
    public static const EVENT_SEARCH:String = "search";
    public static const EVENT_UPLOADED:String = "uploaded";
    
    private static const W:uint = 537;
    private static const H:uint = 330;
    private static const X:uint = 120;
    private static const Y:uint = 57;
    
    private var file:FileReference = null;
    private var uploading:Boolean = false;
    private var rq:URLRequest = null;
    
    private var but_select:* = null;
    private var but_cancel:* = null;
    
    public var serverId:String = null;
    public var audioId:String = null;
    public var hash:String = null;
    
    public function NewAudio( url:String ):void
    {
      rq = new URLRequest();
      rq.url = url;
      rq.method = URLRequestMethod.POST;
      rq.requestHeaders.push( new URLRequestHeader( "Cache-Control", "no-cache" ) );
      
      VK.Utils.fillRect( this, 0, 0, 627, H, 0xf7f7f7 );
      VK.Utils.rect( this, 45, 27, W, H - 45, 0xffffff, 0xcccccc );
      VK.Utils.horLine( this, X, 507, Y + 19, 0xb9c4da );
      
      VK.Utils.fillRect( this, X + 5, Y + 62, 4, 4, 0x758eac );
      VK.Utils.fillRect( this, X + 5, Y + 77, 4, 4, 0x758eac );
      
      addChild( VK.addText( Loc.cur.chooseFile, X, Y, VK.Utils.BLUE_TXT_COL, VK.Utils.TXT_BOLD, 0, 0, 13 ) );
      addChild( VK.addText( Loc.cur.restrict, X, Y + 35, VK.Utils.BLUE_TXT_COL, VK.Utils.TXT_BOLD, 0, 0, 11 ) );

      addChild( VK.addText( Loc.cur.restrict1 + ".", X + 17, Y + 55 ) );
      addChild( VK.addText( Loc.cur.restrict2 + ".", X + 17, Y + 70 ) );
      
      but_select = VK.createRoundButton( Loc.cur.chooseF, 0, Y + 133 );
      but_select.x = Math.round( (627 - but_select.width) / 2 );
      addChild( but_select );
      but_select.addEventListener( MouseEvent.CLICK, onSelectFile );
      
      but_cancel = VK.createRoundButton( Loc.cur.cancel, 0, but_select.y + 11, VK.GRAY_BUTTON );
      but_cancel.x = Math.round( (627 - but_cancel.width) / 2 );
      but_cancel.visible = false;
      addChild( but_cancel );
      but_cancel.addEventListener( MouseEvent.CLICK, cancelHandler );
      
      addChild( VK.addText( Loc.cur.youCanSearch + ",", X, Y + 195 ) );
      var tf1:* = VK.addText( Loc.cur.byUsing, X, Y + 210 );
      addChild( tf1 );
      
      var but2:* = VK.createLinkButton( Loc.cur.audioSearch + ".", tf1.x + tf1.width, tf1.y );
      but2.bold = true;
      addChild( but2 );
      but2.addEventListener( MouseEvent.CLICK, onSearch );
      
      updView();
    }
    
    // ----------------------------------------------------------------------- Private methods
    private function updView( ratio:Number = 0 ):void
    {
      but_select.visible = !uploading;
      but_cancel.visible = uploading;
      
      VK.Utils.rect( this, X + 17, Y + 110, 353, 66, 0xf7f7f7, 0xcccccc );
      if ( uploading )
      {
        const xx:uint = X + 27;
        const yy:uint = Y + 120;
        const w:uint = 333;
        const h:uint = 14;
        
        VK.Utils.rect( this, xx, yy, w, h, 0xffffff, 0xcccccc );
        VK.Utils.rect( this, xx, yy, w * ratio, h, 0x5C7893, 0x36638E );
      }
    }
    
    private function remSpaces( s:String ):String
    {
      return s.slice( 2, s.length - 1 );
    }
    
    private function parseObj( s:String ):*
    {
      s = s.slice( 1, s.length - 1 );
      
      var arr:Array = s.split( "," );
      var obj:Object = new Object();
      for ( var i:* in arr )
      {
        var props:Array = arr[i].split(":");
        var p1:String = remSpaces( props[0] );
        var p2:String = remSpaces( props[1] );
        
        obj[p1] = p2;
      }
      return obj;
    }
    
    public override function get height():Number
    {
      return H;
    }
    
    // ----------------------------------------------------------------------- Event handlers
    private function onSearch( e:MouseEvent ):void
    {
      dispatchEvent( new Event( EVENT_SEARCH ) );
    }
    
    private function onSelectFile( e:MouseEvent ):void
    {
      file = new FileReference();
      file.browse( [ new FileFilter("MP3 Files (*.mp3)", "*.mp3") ] );

      file.addEventListener( Event.SELECT, selectHandler );
      file.addEventListener( ProgressEvent.PROGRESS, progressHandler );
      file.addEventListener( DataEvent.UPLOAD_COMPLETE_DATA,uploadCompleteDataHandler );
      file.addEventListener( Event.CANCEL, cancelHandler );
      
      file.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
      file.addEventListener( SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler );
      file.addEventListener( HTTPStatusEvent.HTTP_STATUS, httpStatusHandler );
    }

    private function selectHandler( e:Event ):void
    {
      // TODO: check this file for valid size!
      
      uploading = true;
      file.upload( rq, "file" );
    }

    private function progressHandler( e:ProgressEvent ):void
    {
      updView( Number(e.bytesLoaded) / e.bytesTotal );
    }

    private function cancelHandler( e:Event ):void
    {
      file.cancel();
      uploading = false;
      updView();
    }

    private function uploadCompleteDataHandler( e:DataEvent ):void
    {
      var d:* = parseObj( e.data );
      serverId = d.server;
      audioId = d.audio;
      hash = d.hash;

      uploading = false;
      updView();
      dispatchEvent( new Event( EVENT_UPLOADED ) );
    }

    private function ioErrorHandler( e:IOErrorEvent ):void
    {
      //Dbg.log( "ioErrorHandler: " + e );
      uploading = false;
      updView();
    }

    private function securityErrorHandler( e:SecurityErrorEvent ):void
    {
      //Dbg.log( "securityErrorHandler: " + e );
      uploading = false;
      updView();
    }

    private function httpStatusHandler( e:HTTPStatusEvent ):void
    {
      //Dbg.log( "httpStatusHandler: " + e );
      uploading = false;
      updView();
    }

  }
}
