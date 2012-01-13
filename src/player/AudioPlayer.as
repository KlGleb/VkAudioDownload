package player
{
  import flash.display.DisplayObject;
  import flash.display.MovieClip;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.TextEvent;
  import flash.events.MouseEvent;
  import flash.events.TimerEvent;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.ProgressEvent;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundTransform;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.text.TextField;
  import flash.utils.Timer;
  import gui.DownloadButton;

  import locale.Loc;
  import vk.VK;

  /**
   * @author Alexey Kharkov
   */
  public class AudioPlayer extends Sprite 
  {
    public static const H:uint = 48;
    public static const Y_DELTA:uint = 5;
    
    private static const TIMER_INTERVAL:uint = 100;
    private static const DIST_BETWEEN_LINES:uint = 10;
    
    public var idx:uint = 0;

    //private static var sound:Sound = null;
    private var sound:Sound = null;

    private var par:* = null;
    private var descr:* = null;
    private var song:SoundChannel = null;
    private var timer:Timer = null;
    private var progressLine:ProgressLine = null;
    private var volumeLine:VolumeLine = null;
    private var playing:Boolean = false;
    private var editMode:Boolean = false;
    private var isDeleted:Boolean = false;
    private var loadingStarted:Boolean = false;
    private var img:PlayPauseImg = null;
    private var ww:uint = 0;
    
    private var x1:uint = 0;
    private var x2:uint = 0;
    
    private var bk:Sprite = null;
    private var header:Sprite = null;
    private var lines:Sprite = null;
    
    private var txt_title:TextField = null;
    private var txt_sep:TextField = null;
    private var txt_deleted:TextField = null;
    
    private var but_artist:* = null;
    private var but_edit:* = null;
    private var but_del:* = null;
    private var but_restore:* = null;
    private var but_add:* = null;
    private var but_title:* = null;
	private var but_download:DownloadButton = null;

    public var lyrics:String = null;
    

    public function AudioPlayer( par:*, descr:*, idx:uint, x:uint, y:uint, w:uint, playing:Boolean, editMode:Boolean, own:Boolean ):void 
    {
      this.par = par;
      this.descr = descr;
      this.idx = idx;
      this.x = x;
      this.y = y;
      this.editMode = editMode;
      
      ww = w - 115;
      
      // ----------------- Create GUI
      bk = new Sprite();
      addChild( bk );
      if ( editMode )
      {
        bk.buttonMode = true;
        bk.addEventListener( MouseEvent.MOUSE_OVER, onOver );
        bk.addEventListener( MouseEvent.MOUSE_DOWN, onDown );
      }
      
      img = new PlayPauseImg();
      img.buttonMode = true;
      img.y = 5;
      addChild( img );
      img.addEventListener( MouseEvent.CLICK, onImg );
      
      // Header
      header = new Sprite();
      header.x = 34;
      header.y = 5;
      addChild( header );
      
      // Artist
      but_artist = VK.createLinkButton( descr.artist, 0, 0, 11, (ww + 15) / 2 );
      but_artist.bold = true;
      but_artist.addEventListener( MouseEvent.CLICK, onArtist );
      header.addChild( but_artist );
      
      // Title
      var xx:uint = but_artist.x + but_artist.width;
      txt_sep = VK.addText( "-", xx, but_artist.y );
      xx += header.addChild( txt_sep ).width;
      if ( lyrics_id > 0 )
      {
        // "Lyrics" button
        but_title = VK.createLinkButton( descr.title, xx, but_artist.y, 11, 300 );
        but_title.addEventListener( MouseEvent.CLICK, onShowLyrics );
        header.addChild( but_title );
      } else
      {
        txt_title = VK.addText( descr.title, xx, but_artist.y, 0, VK.Utils.TXT_AUTOSIZE );
        header.addChild( txt_title );
      }
      
      // "Add" button
      if ( !own )
      {
        but_add = VK.createLinkButton( Loc.cur.add, 0, 10 );
        but_add.x = ww + 97 - but_add.width;
        but_add.addEventListener( MouseEvent.CLICK, onButAdd );
        addChild( but_add );
      }
	  
	   //Download button
	   if ( !editMode )
	   {
		   	//but_download = VK.createLinkButton("Скачать", 0, 10);
		   	but_download = new DownloadButton(descr.url, descr.artist + " - " + descr.title);
			but_download.x = ww + 97 - but_download.width;
			but_download.y = 10;
			
			if ( but_add )
			{
				but_download.x = but_add.x - but_download.width - 7;
			}
			addChild(but_download);
			
			if (but_add)
			{
				var sep:Sprite = new Sprite();
				VK.Utils.vertSeparator( sep, 0, 0 );
				sep.x = but_download.x + but_download.width + (but_add.x - (but_download.x + but_download.width)) / 2 - sep.width / 2;
				sep.y = but_download.y + but_download.height / 2 - sep.height / 2 ;
				addChild(sep);
			}
	   }

      
      // Other Buttons
      if ( editMode )
      {
        xx = 0;
        but_edit = VK.createLinkButton( Loc.cur.edit, xx, 15, 10 );
        header.addChild( but_edit );
        but_edit.visible = false;
        but_edit.addEventListener( MouseEvent.CLICK, onButEdit );
        xx += but_edit.width + 6;

        but_del = VK.createLinkButton( Loc.cur.del, xx, but_edit.y, 10 );
        but_del.addEventListener( MouseEvent.CLICK, onButDel );
        but_del.visible = false;
        header.addChild( but_del );
        
        // "This audio is deleted" message and button
        txt_deleted = VK.addText( Loc.cur.deleted + ".", 6, 12 );
        txt_deleted.visible = false;
        addChild( txt_deleted );
        
        but_restore = VK.createLinkButton( Loc.cur.undo + ".", txt_deleted.x + txt_deleted.width, txt_deleted.y );
        but_restore.visible = false;
        but_restore.addEventListener( MouseEvent.CLICK, onButRestore );
        addChild( but_restore );
      }
      
      updateTitleWidth();

      // Duration
      var t1:uint = Math.floor( descr.duration / 60 );
      var t2:uint = descr.duration % 60;
      var s:String = t1 + ":" + ((t2 < 10) ? "0" : "") + t2;
	  var txt_duration:DisplayObject = VK.addText( s, linesW + 32, 5, 0x777777, 0, 0, 0, 10 );
      header.addChild(txt_duration);
      
      // ProgressLine and VolumeLine
      lines = new Sprite();
      lines.x = 34;
      lines.y = 30;
      addChild( lines );
      
      x1 = (editMode ? 12 : 0);
      x2 = x1 + linesW;
      
      // Set up timer
      timer = new Timer( TIMER_INTERVAL );
      timer.addEventListener( TimerEvent.TIMER, onTimer );

      if ( playing )
        play( true );
      else
        resetPlayer();
    }
    
    public function release():void
    {
      timer.stop();
      releaseSong();
      releaseSound();
      loadingStarted = false;
    }
    
    public function resetPlayer():void
    {
      playing = false;
      img.gotoAndStop( 1 );

      timer.stop();
      releaseSong();
      
      if ( progressLine )
      {
        progressLine.pos = 0;
        //progressLine.ratio = 0;
        volumeLine.pos = PlayersContainer.curVolume;
      }
      
      lines.visible = false;
      
      updView();
    }
    
    public function switchPlaying():void
    {
      play( !playing );
    }
    
    public function play( b:Boolean ):void
    {
      playing = b;
      img.gotoAndStop( playing ? 2 : 1 );
      par.onPlayPause( this, playing );
      
      if ( progressLine == null )
        createLines();
      
      lines.visible = true;
      updView();

      progressLine.setPaused( !playing );

      releaseSong();

      if ( playing )
      {
        // Download audio
        if ( !loadingStarted )
        {
          sound = new Sound();
          var rq:URLRequest = new URLRequest( descr.url );
          rq.method = URLRequestMethod.POST;
          sound.load( rq );
          
          sound.addEventListener( IOErrorEvent.IO_ERROR, onError, false, 0, true );
          sound.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true );
          sound.addEventListener( ProgressEvent.PROGRESS, onProgress, false, 0, true );

          loadingStarted = true;
        }
        
        onProgress( null );

        // Start playing
        var pos:Number = curLen * progressLine.pos;
        song = sound.play( pos );
        song.soundTransform = new SoundTransform( volumeLine.pos );
        song.addEventListener( Event.SOUND_COMPLETE, onComplete, false, 0, true );
        
        if ( !timer.running )
        {
          onTimer( null );
          timer.start();
        }
      }
    }
    
    public function getHeight():uint
    {
      return 36 + (isDeleted ? 0 : (editMode ? 12 : 3));
    }
    
    public function get lyrics_id():uint
    {
      return descr.lyrics_id;
    }
    
    public function set lyrics_id( val:uint ):void
    {
      descr.lyrics_id = val;
    }
    
    public function get artist():String
    {
      return descr.artist;
    }
    
    public function set artist( s:String ):void
    {
      descr.artist = s;
      but_artist.label = s;
      
      txt_sep.x = but_artist.x + but_artist.width;
      
      if ( txt_title )
        txt_title.x = txt_sep.x + txt_sep.width;
      else
        but_title.x = txt_sep.x + txt_sep.width;
        
      updateTitleWidth();
    }
    
    public function get title():String
    {
      return descr.title;
    }
    
    public function set title( s:String ):void
    {
      descr.title = s;
      if ( txt_title )
        txt_title.text = s;
      else
        but_title.label = s;
      updateTitleWidth();
    }
    
    public function get aid():uint
    {
      return parseInt( descr.aid );
    }
    
    public function get oid():uint
    {
      return parseInt( descr.owner_id );
    }
    
    public function getDescr():*
    {
      return descr;
    }

    // ----------------------------------------------------------------------- Callbacks for ProgressLine and VolumeLine
    public function onProgressLine():void
    {
      if ( progressLine.pos > 0.999 )
      {
        onComplete( null );
        return;
      }
      
      if ( playing  &&  sound.bytesLoaded > 0 )
      {
        releaseSong();
        var pos:Number = curLen * progressLine.pos;
        song = sound.play( pos );
        song.soundTransform = new SoundTransform( volumeLine.pos );
        song.addEventListener( Event.SOUND_COMPLETE, onComplete, false, 0, true );
      }
    }
    
    public function onVolumeLine():void
    {
      PlayersContainer.curVolume = volumeLine.pos;
      if ( playing )
        song.soundTransform = new SoundTransform( volumeLine.pos );
    }
    
    // ----------------------------------------------------------------------- Private methods
    private function get curLen():Number
    {
      return (sound.bytesLoaded == 0)
        ? sound.length
        : (sound.length * sound.bytesTotal) / sound.bytesLoaded;
    }
    
    private function createLines():void
    {
      // Progress Line
      progressLine = new ProgressLine( this, x1, 0, x2 - x1 );
      lines.addChild( progressLine );

      // Volume Line
      volumeLine = new VolumeLine( this, x2 + DIST_BETWEEN_LINES, 0 );
      lines.addChild( volumeLine );
      
      volumeLine.pos = PlayersContainer.curVolume;
    }
    
    private function updView():void
    {
      bk.graphics.clear();
      header.graphics.clear();

      header.visible = true;
      img.visible = true;
      
      if ( editMode )
      {
        txt_deleted.visible = false;
        but_restore.visible = false;
        
        if ( isDeleted )
        {
          header.visible = false;
          img.visible = false;
          
          txt_deleted.visible = true;
          but_restore.visible = true;
          
          VK.Utils.rect( bk, 0, 5, ww + 115, getHeight() - Y_DELTA, 0xffffff, VK.Utils.BORDER_COL );
        } else
        {
          img.scaleX = 1;
          img.scaleY = 1;
          img.x = 9;
          img.y = 9;
          header.x = 42;
          header.y = 7;
          but_edit.visible = !lines.visible;
          but_del.visible = !lines.visible;
          lines.y = 29;
          
          VK.Utils.rect( bk, 0, 0, ww + 115, H - Y_DELTA, 0xffffff, VK.Utils.BORDER_COL );
          if ( !lines.visible )
            VK.Utils.vertSeparator( header, but_del.x - 5, but_del.y + 4 );
        }
      } else
      {
        img.scaleX = Main.PLAYPAUSE_IMG_SCALE;
        img.scaleY = Main.PLAYPAUSE_IMG_SCALE;
        img.x = 7;
        img.y = 5;
        header.x = 34;
        header.y = 5;
        lines.y = 30;
        if ( !lines.visible )
          VK.Utils.horDashLine( bk, lines.x + x1, lines.x + x2 + DIST_BETWEEN_LINES + VolumeLine.W, lines.y, 0xd8dfea );
      }
    }
    
    private function updateTitleWidth():void
    {
      var xx:uint = but_artist.x + but_artist.width;
      var max_title_w:uint = linesW + 15 - xx;
      
      if ( txt_title )
        VK.Utils.updSz( txt_title, 0, max_title_w );
      else
        but_title.maxWidth = max_title_w;
    }
    
    private function get linesW():uint
    {
      //return ww + 10 - (but_add ? but_add.width + 15 : 0);
	  var btns:Array = [but_download, but_add];
	  var p_x:int = 5000;
	  
	  for each(var btn:* in btns) 
	  {
		 if (btn)
			p_x = Math.min(p_x, btn.x);
	  }
	  
	  return ww - (Main.WIDTH - p_x) + 10;
	  /*
	  if (but_download)
	  {
		  return ww + 10 - ( but_download ? but_download.width + 15 : 0);
	  }else if (but_add)
	  {
		return ww + 10 - (but_add ? but_add.width + 15 : 0); 
	  }else
	  {
		  return ww + 10;  
	  }*/
      
    }
    
    private function releaseSong():void
    {
      if ( song != null )
      {
        song.stop();
        song = null;
      }
    }
    
    private function releaseSound():void
    {
      if ( loadingStarted )
      {
        if ( sound.isBuffering )
          sound.close();
        
        sound = null;
      }
    }
    
    // ----------------------------------------------------------------------- Mouse events handlers
    private function onOver( e:MouseEvent ):void
    {
      if ( e.target == bk )
      {
        addEventListener( MouseEvent.MOUSE_OUT, onOut );
        par.changeCursor( true );
      }
    }
    
    private function onOut( e:MouseEvent ):void
    {
      if ( e.target == bk )
      {
        removeEventListener( MouseEvent.MOUSE_OUT, onOut );
        par.changeCursor( false );
      }
    }

    private function onDown( e:MouseEvent ):void
    {
      Main.STAGE.addEventListener( MouseEvent.MOUSE_UP, onUp );
      Main.STAGE.addEventListener( MouseEvent.MOUSE_MOVE, onMove );
      bk.alpha = 0.8;
      par.onStartDrag( this );
    }

    private function onUp( e:MouseEvent ):void
    {
      Main.STAGE.removeEventListener( MouseEvent.MOUSE_UP, onUp );
      Main.STAGE.removeEventListener( MouseEvent.MOUSE_MOVE, onMove );
      bk.alpha = 1.0;
      par.onFinishDrag( this );
    }
    
    private function onMove( e:MouseEvent ):void
    {
      par.onDrag( this );
    }

    // ----------------------------------------------------------------------- Other events handlers
    private function onImg( e:* ):void
    {
      switchPlaying();
    }
    
    private function onArtist( e:* ):void
    {
      par.onArtistSearch( artist );
    }
    
    private function onComplete( e:Event ):void
    {
      resetPlayer();
      par.onPlayFinished();
    }
    
    private function onTimer( e:TimerEvent ):void
    {
      if ( playing )
        progressLine.pos = (curLen == 0) ? 0 : (song.position / curLen);
    }
    
    private function onProgress( e:ProgressEvent ):void
    {
      progressLine.ratio = Number(sound.bytesLoaded) / sound.bytesTotal;
      progressLine.reDraw();
    }
    
    private static function onError( e:IOErrorEvent ):void
    {
      //Dbg.log( e.text );
    }
    
    private static function onSecurityError( e:SecurityErrorEvent ):void
    {
      //Dbg.log( e.text );
    }
    
    private function onButEdit( e:MouseEvent ):void
    {
      par.onEdit( this, false );
    }
    
    private function onShowLyrics( e:MouseEvent ):void
    {
      par.onEdit( this, true );
    }

    private function onButDel( e:MouseEvent ):void
    {
      bk.buttonMode = false;
      removeEventListener( MouseEvent.MOUSE_DOWN, onDown );
      
      isDeleted = true;
      updView();
      par.onDel( aid, oid );
    }

    private function onButRestore( e:MouseEvent ):void
    {
      bk.buttonMode = true;
      addEventListener( MouseEvent.MOUSE_DOWN, onDown );
      
      isDeleted = false;
      updView();
      par.onRestore( aid, oid );
    }

    private function onButAdd( e:MouseEvent ):void
    {
      but_add.visible = false;
      var tf:* = VK.addText( Loc.cur.added, but_add.x, but_add.y, 0x777777 );
      tf.x = but_add.x + (but_add.width - tf.width) / 2;
      addChild( tf );
      
      par.onAdd( aid, oid );
    }
    
  }
}