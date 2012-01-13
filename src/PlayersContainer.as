package 
{
  import flash.display.DisplayObject;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.text.TextField;
  import flash.ui.Mouse;
  import flash.system.System;

  import vk.*;
  import gui.*;
  import locale.Loc;
  import player.AudioPlayer;

  /**
   * @author Alexey Kharkov
   */
  public class PlayersContainer extends Sprite 
  {
    internal static const MARGINS:uint = 8;
    internal static const PLAYERS_W:uint = Main.WIDTH - 2 * MARGINS;
    internal static const ELEMS_ON_PAGE:uint = 50;

    public static var curVolume:Number = 0.75;
    private static var curPlayer:AudioPlayer = null;

    private var par:Main = null;
    private var players:Array = null;
    
    private var editBox:* = null;
    private var pagination:* = null;
    private var isEdit:Boolean = false;
    private var editModeChanged:Boolean = false;
    private var editAudio:EditAudio = null;
    private var dashRect:Sprite = null;
    private var moveCursor:MoveCursor = null;
    
    private var was_cont:CacheCont = null;
    private var was_page:uint = 0;
    
    private var onlyLyrics:Boolean = false;

    public var pagH:uint = 100;

    // Dragging helper variables
    private var dragIdx:int = -1;
    private var dragStartY:uint = 0;
    private var minY:uint = 0;
    private var maxY:uint = 0;

    // ----------------------------------------------------------------------- Public methods
    public function PlayersContainer( par:Main ):void
    {
      this.par = par;
      
      //
      editAudio = new EditAudio( this );
      
      //
      dashRect = new Sprite();
      VK.Utils.fillRect( dashRect, 0, 0, PLAYERS_W, AudioPlayer.H - AudioPlayer.Y_DELTA, 0xffffff );
      VK.Utils.dashRect( dashRect, 0, 0, PLAYERS_W, AudioPlayer.H - AudioPlayer.Y_DELTA, 0xd8dfea );
      
      //
      moveCursor = new MoveCursor();
      moveCursor.mouseEnabled = false;
    }
    
    public function get needToRedraw():Boolean // Do we need to redraw players?
    {
      return editModeChanged  ||  players == null  ||  par.cur_cont != was_cont  ||  par.cur_cont.curPage != was_page;
    }
    
    public function showPlayers( own:Boolean, search:Boolean, startY:uint, autoStart:Boolean ):void
    {
      //Dbg.log( "PlayersContainer.showPlayers(),   cur_cont.curPage " + par.cur_cont.curPage );

      was_cont = par.cur_cont;
      was_page = par.cur_cont.curPage;
      editModeChanged = false;

      // Redraw all
      closeEditBox();
      Main.clearLayout( this );
      
      if ( editMode )
      {
        moveCursor.visible = false;
        addChild( moveCursor );
      }
      
      // Create pagination
      pagination = VK.createPagination( par.cur_cont.length, Main.WIDTH - 12, 15, 0, VK.Pagination.RIGHT_ALIGNED, 2, ELEMS_ON_PAGE );
      pagination.curPage = par.cur_cont.curPage;
      
      pagination.addEventListener( Event.CHANGE, onPagination );
      addChild( pagination );

      //
      var xx:uint = MARGINS + (editMode ? 0 : 5);
      var yy:uint = MARGINS + (editMode ? 34 : 44) + (search ? 30 : 0) + startY;
      
      minY = yy;
      
      // Create players
      releasePlayers();
      players = new Array();

      var i1:uint = par.cur_cont.curIdx;
      var i2:uint = i1 + ELEMS_ON_PAGE;
      
      for ( var i:uint = i1; i < i2; ++i )
      {
        if ( i >= par.cur_cont.length )
          break;
        
        if ( par.cur_cont.getAt(i) == null )
          continue;
        
        var descr:* = par.cur_cont.getAt(i);
        var p:AudioPlayer = ( curPlayer != null  &&  curPlayer.aid == descr.aid )
          ? curPlayer
          : new AudioPlayer( this, descr, i - i1, xx, yy, PLAYERS_W, false, editMode, own );
          
        p.y = yy;
        p.idx = i - i1;
        
        addChild( p );
        players.push( p );
        
        yy += p.getHeight();
      }
      
      maxY = yy - AudioPlayer.H;
      
      pagination.height = yy + 1 - (editMode ? 14 : 0);
      pagH = pagination.y + pagination.height;
      
      if ( autoStart  &&  players.length > 0 )
      {
        stopCurPlayer();
        curPlayer = players[0];
        curPlayer.play( true );
      }
    }
    
    public function reCreateEditBox( p:AudioPlayer ):void
    {
      closeEditBox();
      
      editBox = onlyLyrics 
        ? VK.createBox( Loc.cur.viewAudio, p.lyrics, p.y, EditAudio.W, [Loc.cur.close] )
        : VK.createBox( Loc.cur.editAudio, editAudio, p.y, 0, [Loc.cur.editBig, Loc.cur.cancel] );
      
      addChild( editBox );
      editBox.addEventListener( Event.SELECT, onBox );
      
      par.updateHeight( editBox.y + editBox.height + 50 );

      editBox.setVisible( true );
      Main.scrollTo( 60 + editBox.y );
    }
    
    public function onLyrics( s:String ):void
    {
      editAudio.lyrics = s;
      reCreateEditBox( editAudio.getCur() );
    }
    
    public function onLyricsId( lyrics_id:uint ):void
    {
      editAudio.setLyricsId( lyrics_id );
    }
    
    public function get editMode():Boolean
    {
      return isEdit;
    }
    
    public function set editMode( val:Boolean ):void
    {
      if ( val != isEdit )
      {
        stopCurPlayer();
        isEdit = val;
        editModeChanged = true;
      }
    }
    
    // ----------------------------------------------------------------------- Callbacks
    public function onPlayPause( p:AudioPlayer, playing:Boolean ):void
    {
      if ( p != curPlayer )
      {
        stopCurPlayer();
        curPlayer = p;
      }
      
      Main.img.visible = true;
      Main.img.gotoAndStop( playing ? 2 : 1 )
    }

    public function onPlayFinished():void
    {
      var idx:uint = curPlayer.idx + 1;
      curPlayer = null;

      if ( idx < players.length )
      {
        curPlayer = players[idx];
        curPlayer.play( true );
      }
      else
      if ( pagination.curPage < pagination.numPages - 1 )
      {
        Main.scrollTo( 30 );
        par.goToPage( pagination.curPage + 1, true );
      }
    }
    
    public function onArtistSearch( s:String ):void
    {
      par.search( s );
    }
    
    public function onDel( aid:uint, oid:uint ):void
    {
      par.enGui( false );
      par.reset();
      //par.updateCount( -1 );
      par.vkApi.deleteAudio( aid, oid );
    }
    
    public function onRestore( aid:uint, oid:uint ):void
    {
      par.enGui( false );
      par.reset();
      //par.updateCount( +1 );
      par.vkApi.restoreAudio( aid );
    }
    
    public function onAdd( aid:uint, oid:uint ):void
    {
      par.enGui( false );
      par.reset();
      par.vkApi.addAudio( aid, oid );
    }
    
    public function onEdit( p:AudioPlayer, onlyLyrics:Boolean ):void
    {
      this.onlyLyrics = onlyLyrics;
      editAudio.reset( p, editMode );
      
      if ( p.lyrics != null  ||  p.lyrics_id == 0 )
        reCreateEditBox( p );
      else
      if ( p.lyrics_id > 0 )
        par.vkApi.getLyrics( p.lyrics_id );
    }

    // ----------------------------------------------------------------------- Changing cursor methods
    public function changeCursor( b:Boolean ):void
    {
      if ( b  ||  dragIdx >= 0 )
      {
        // Show "Move" cursor
        moveCursor.x = mouseX;
        moveCursor.y = mouseY;
        moveCursor.visible = true;
        setChildIndex( moveCursor, numChildren - 1 );
        moveCursor.startDrag( true );
        Mouse.hide();
      } else
      {
        // Back to standard cursor
        moveCursor.visible = false;
        moveCursor.stopDrag();
        Mouse.show();
      }
    }

    // ----------------------------------------------------------------------- Player draggins methods
    public function onStartDrag( p:AudioPlayer ):void
    {
      dragIdx = p.idx;
      dragStartY = mouseY - p.y;
      
      // Draw dash rectangle
      addChild( dashRect );
      dashRect.x = p.x;
      dashRect.y = minY + p.idx * AudioPlayer.H;
      
      // Move the player on top
      setChildIndex( moveCursor, numChildren - 1 );
      setChildIndex( p, numChildren - 2 );
    }
    
    public function onDrag( p:AudioPlayer ):void
    {
      p.y = mouseY - dragStartY;
      p.y = Math.max( minY, Math.min( maxY, p.y ) );
      reSortPlayers( p );
      
      // Dash rectangle
      dashRect.y = minY + p.idx * AudioPlayer.H;
    }
    
    public function onFinishDrag( p:AudioPlayer ):void
    {
      p.y = minY + p.idx * AudioPlayer.H;
      removeChild( dashRect );
      
      if ( p.idx != dragIdx ) // Is reordered?
      {
        // Reorder
        var new_players:Array = new Array( players.length );
        var new_descr:Array = new Array( players.length );
        var i:uint;
        for ( i = 0; i < players.length; ++i )
        {
          var idx:uint = players[i].idx;
          new_descr[idx] = players[i].getDescr();
          new_players[idx] = players[i];
        }
        
        players = new_players;
        par.cur_cont.addElems( new_descr, par.cur_cont.curIdx );
        
        // Save the changes
        var before:int = 0;
        var after:int = 0;
        
        if ( p.idx > 0 )
          after = players[p.idx - 1].aid;
        //else
        if ( p.idx < players.length - 1 )
          before = players[p.idx + 1].aid;
        
        par.reset();
        par.vkApi.reorderAudio( p.aid, after, before );
      }
      
      dragIdx = -1;
    }
    
    private function reSortPlayers( p0:AudioPlayer ):void
    {
      const h:uint = AudioPlayer.H;
      const y1:uint = p0.y - h / 2;
      const y2:uint = y1 + h;
      
      var cur_idx:uint = 0;
      var yy:uint = minY;
      
      p0.idx = players.length - 1;

      for ( var i:uint = 0; i < players.length; ++i )
      {
        var p:AudioPlayer = players[i];
        if ( p == p0 )
          continue;

        p.y = yy;

        if ( p.y >= y1  &&  p.y <= y2 )
        {
          p0.idx = cur_idx;
          cur_idx ++;
          yy += h;
        }

        p.idx = cur_idx;
        p.y = yy;

        cur_idx ++;
        yy += h;
      }
    }
    
    // ----------------------------------------------------------------------- Private methods
    private function stopCurPlayer():void
    {
      if ( curPlayer != null )
      {
        curPlayer.resetPlayer();
        curPlayer = null;
        Main.img.visible = false;
      }
    }
    
    private function releasePlayers():void
    {
      if ( players == null )
        return;
      
      for ( var i:uint = 0; i < players.length; ++i )
      {
        if ( players[i] != curPlayer )
        {
          players[i].release();
          delete players[i];
        }
      }
      
      players.splice( 0 );
      players = null;
      
      System.gc();
      System.gc();
    }

    private function closeEditBox():void
    {
      if ( editBox )
      {
        if ( editBox.visible )
          editBox.setVisible( false );
        removeChild( editBox );
        editBox = null;
      }
    }

    // ----------------------------------------------------------------------- Event handlers
    private function onPagination( e:Event ):void
    {
      par.goToPage( e.target.curPage );
	  if (Main.wrapper)
	  {
		  Main.wrapper.external.scrollWindow(0);
	  }
    }
    
    private function onBox( e:Event ):void
    {
      if ( e.target.buttonClickedIndex == 0  &&  editMode )
      {
        var p:AudioPlayer = editAudio.updCur();
        var text:String = editAudio.lyrics.replace( /\r/g, "\r\n" );
        par.vkApi.editAudio( p.aid, p.oid, p.artist, p.title, text, editAudio.no_search );
      }
    }

    internal static function onImg( e:* ):void
    {
      if ( curPlayer )
        curPlayer.switchPlaying();
    }
    
  }
}