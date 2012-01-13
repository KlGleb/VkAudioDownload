package gui
{
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import locale.Loc;

  import vk.*;

  /**
   * @author Alexey Kharkov
   */
  public class MsgRect extends Sprite
  {
    public static const EVENT_SETTINGS:String = "sett";
    public static const EVENT_NEW:String = "new";
    
    private var type:uint = 0;
    
    public function MsgRect( type:uint, y:int ):void
    {
      this.type = type;
      this.y = y;
      
      while ( numChildren > 0 )
        removeChildAt( numChildren - 1 );
      
      var s:String = "";
      var xx:uint = 0;
      var yy:uint = 107;
      var ww:uint = 627;

      var but:* = null;
      
      switch ( type )
      {
      case 1:
        s = Loc.cur.needAudioAccess + ".";
        xx = 165;
        yy = 50;
        but = VK.createLinkButton( Loc.cur.openSettings + " »", 243, 80, 12 );
        break;
      case 2:
        s = Loc.cur.noAudio1 + ".";
        xx = 182;
        yy = 50;
        but = VK.createLinkButton( Loc.cur.addTrack, 243, 80, 12 );
        break;
      case 3:
      case 4:
        s = Loc.cur.noAudio2 + ".";
        xx = 210;
        yy = 65;
        break;
      }

      if ( but != null )
      {
        addChild( but );
        but.addEventListener( MouseEvent.CLICK, onBut );
      }
      
      VK.Utils.fillRect( this, 0, 0, ww, 200, VK.Utils.BK_COL );
      VK.Utils.rect( this, 8, 9, ww - 18, 130, 0xffffff, VK.Utils.BORDER_COL );
      
      addChild( VK.addText( s, xx, yy, 0x777777, 0, 0, 0, 12 ) );
    }
    
    // ----------------------------------------------------------------- Mouse events		
    private function onBut( e:MouseEvent ):void
    {
      switch ( type )
      {
      case 1:
        dispatchEvent( new Event( EVENT_SETTINGS ) );
        break;
      case 2:
        dispatchEvent( new Event( EVENT_NEW ) );
        break;
      case 3:
        break;
      }
    }

  }
}